const functions = require('firebase-functions');
const admin = require('firebase-admin');
const stripe = require('stripe');

// Suppression de l'initialisation ici car elle est déjà faite dans index.js
// admin.initializeApp();

// Fonction pour récupérer la clé API Stripe depuis Firestore
async function getStripeApiKey() {
  try {
    const doc = await admin.firestore()
      .collection('api_key_stripe')
      .doc('api')
      .get();
    
    if (doc.exists) {
      return doc.data()._apiKey;
    } else {
      console.error('Clé API Stripe non trouvée dans Firestore');
      return null;
    }
  } catch (error) {
    console.error(`Erreur lors de la récupération de la clé API Stripe: ${error.message}`);
    return null;
  }
}

// Point d'entrée pour le webhook Stripe
exports.stripeWebhook = functions.https.onRequest(async (req, res) => {
  const apiKey = await getStripeApiKey();
  if (!apiKey) {
    console.error('Impossible de traiter le webhook: clé API manquante');
    return res.status(500).send('Configuration error');
  }
  
  const stripeClient = stripe(apiKey);
  
  // Vérifier que la requête provient bien de Stripe
  let event;
  try {
    const signature = req.headers['stripe-signature'];
    
    // Récupérer le secret du webhook depuis les variables d'environnement
    const endpointSecret = functions.config().stripe?.webhook_secret;
    
    if (endpointSecret) {
      // Vérifier la signature avec le secret
      event = stripeClient.webhooks.constructEvent(req.rawBody, signature, endpointSecret);
      console.log(`✅ Événement Stripe authentifié: ${event.type}`);
    } else {
      // Si pas de secret configuré, utiliser directement le corps de la requête (moins sécurisé)
      console.log('⚠️ Attention: Webhook sans vérification de signature');
      event = req.body;
    }
  } catch (err) {
    console.error(`❌ Erreur de signature webhook: ${err.message}`);
    return res.status(400).send(`Webhook Error: ${err.message}`);
  }

  // Traiter les différents types d'événements
  try {
    switch (event.type) {
      case 'customer.subscription.created':
      case 'customer.subscription.updated':
      case 'customer.subscription.deleted':
        await handleSubscriptionChange(event.data.object, stripeClient);
        break;
      case 'invoice.payment_succeeded':
        await handleInvoicePaymentSucceeded(event.data.object, stripeClient);
        break;
      case 'invoice.payment_failed':
        await handleInvoicePaymentFailed(event.data.object, stripeClient);
        break;
      default:
        console.log(`Événement non géré: ${event.type}`);
    }

    res.status(200).send('Webhook processed');
  } catch (error) {
    console.error(`Erreur traitement webhook: ${error.message}`);
    res.status(500).send(`Webhook Error: ${error.message}`);
  }
});

// Gérer les changements d'abonnement
async function handleSubscriptionChange(subscription, stripeClient) {
  try {
    // Récupérer le client Stripe pour obtenir les métadonnées
    const customer = await stripeClient.customers.retrieve(subscription.customer);
    console.log(`Client Stripe récupéré: ${JSON.stringify(customer.metadata)}`);
    
    // Essayer de récupérer l'ID Firebase depuis les métadonnées du client
    let userId = customer.metadata.firebaseUserId;
    
    // Si l'ID n'est pas dans les métadonnées, utiliser l'email ou l'ID client comme fallback
    if (!userId) {
      userId = customer.email || subscription.customer;
      console.log(`Aucun ID Firebase trouvé dans les métadonnées, utilisation de fallback: ${userId}`);
    }
    
    const subscriptionId = subscription.id;
    const status = subscription.status;
    const isActive = status === 'active' || status === 'trialing';
    
    // Obtenir le produit pour déterminer le type de plan
    const productId = subscription.items.data[0].price.product;
    
    // Déterminer le type de plan et le nombre de véhicules
    let planType = 'free';
    let numberOfCars = 1;
    let stripeNumberOfCars = 1;
    
    // Mapper l'ID du produit au type de plan
    if (productId === 'prod_RiIVqYAhJGzB0u') {
      planType = 'premium-monthly_access';
      stripeNumberOfCars = 10;
    } else if (productId === 'prod_RiIXsD22K4xehY') {
      planType = 'premium-yearly_access';
      stripeNumberOfCars = 10;
    } else if (productId === 'prod_S27nF635Z0AoFs' || productId === 'prod_S26yXish2BNayF') {
      planType = 'platinum-monthly_access';
      stripeNumberOfCars = 20;
    } else if (productId === 'prod_S26xbnrxhZn6TT') {
      planType = 'platinum-yearly_access';
      stripeNumberOfCars = 20;
    }
    
    console.log(`Mise à jour Firebase pour l'utilisateur: ${userId}, plan: ${planType}, actif: ${isActive}`);
    
    // Mettre à jour Firestore avec tous les champs nécessaires
    await admin.firestore()
      .collection('users')
      .doc(userId)
      .collection('authentification')
      .doc(userId)
      .set({
        'stripePlanType': planType,
        'isStripeSubscriptionActive': isActive,
        'stripeNumberOfCars': stripeNumberOfCars,
        'stripeSubscriptionId': subscriptionId,
        'stripeStatus': status,
        'lastStripeUpdateDate': admin.firestore.FieldValue.serverTimestamp(),
      }, {merge: true});
    
    console.log(`Firebase mis à jour avec succès pour l'utilisateur: ${userId}`);
  } catch (error) {
    console.error(`Erreur mise à jour abonnement: ${error.message}`);
    throw error;
  }
}

// Gérer les paiements réussis
async function handleInvoicePaymentSucceeded(invoice, stripeClient) {
  if (invoice.subscription) {
    // C'est un paiement d'abonnement
    const subscription = await stripeClient.subscriptions.retrieve(invoice.subscription);
    await handleSubscriptionChange(subscription, stripeClient);
  }
}

// Gérer les échecs de paiement
async function handleInvoicePaymentFailed(invoice, stripeClient) {
  if (invoice.subscription) {
    // C'est un échec de paiement d'abonnement
    const subscription = await stripeClient.subscriptions.retrieve(invoice.subscription);
    await handleSubscriptionChange(subscription, stripeClient);
  }
}
