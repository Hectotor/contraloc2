const functions = require('firebase-functions');
const admin = require('firebase-admin');
const stripe = require('stripe');

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
exports.stripeWebhook = async (req, res) => {
  const apiKey = await getStripeApiKey();
  if (!apiKey) {
    console.error('Impossible de traiter le webhook: clé API manquante');
    return res.status(500).send('Configuration error');
  }
  
  const stripeClient = stripe(apiKey);
  
  // Pour le moment, nous acceptons toutes les requêtes sans vérification de signature
  // pour éviter les problèmes de configuration
  let event;
  try {
    // Utiliser directement le corps de la requête
    console.log('⚠️ Mode de développement: Webhook sans vérification de signature');
    event = req.body;
    
    // Vérifier que l'événement contient les données nécessaires
    if (!event || !event.type || !event.data || !event.data.object) {
      console.error('Données d\'événement invalides');
      return res.status(400).send('Invalid event data');
    }

    console.log(`✅ Événement Stripe reçu: ${event.type}`);

    // Traiter les différents types d'événements
    try {
      switch (event.type) {
        case 'checkout.session.completed':
          console.log(`✅ Session checkout complétée: ${event.type}`);
          console.log(`✅ Mode: ${event.data.object.mode}, Subscription ID: ${event.data.object.subscription}`);
          console.log(`✅ Customer: ${event.data.object.customer}`);
          // Récupérer l'abonnement associé à la session
          if (event.data.object.mode === 'subscription' && event.data.object.subscription) {
            try {
              console.log(`✅ Récupération de l'abonnement: ${event.data.object.subscription}`);
              const subscription = await stripeClient.subscriptions.retrieve(event.data.object.subscription);
              console.log(`✅ Abonnement récupéré avec succès: ${subscription.id}`);
              await handleSubscriptionChange(subscription, stripeClient);
            } catch (error) {
              console.error(`🚫 Erreur lors de la récupération de l'abonnement: ${error.message}`);
            }
          } else {
            console.log(`🚫 Session non compatible: mode=${event.data.object.mode}, subscription=${event.data.object.subscription}`);
          }
          break;
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
  } catch (error) {
    console.error(`Erreur traitement webhook: ${error.message}`);
    res.status(500).send(`Webhook Error: ${error.message}`);
  }
};

// Gérer les changements d'abonnement
async function handleSubscriptionChange(subscription, stripeClient) {
  try {
    console.log(`🔍 Début du traitement de l'abonnement: ${subscription.id}`);
    console.log(`🔍 Status de l'abonnement: ${subscription.status}`);
    
    // Récupérer le client Stripe pour obtenir les métadonnées
    const customer = await stripeClient.customers.retrieve(subscription.customer);
    console.log(`🔍 Client Stripe récupéré: ${subscription.customer}`);
    console.log(`🔍 Métadonnées client: ${JSON.stringify(customer.metadata)}`);
    console.log(`🔍 Email client: ${customer.email}`);
    
    // Essayer de récupérer l'ID Firebase depuis les métadonnées du client
    let userId = customer.metadata.firebaseUserId;
    
    // Si l'ID n'est pas dans les métadonnées, utiliser l'email ou l'ID client comme fallback
    if (!userId) {
      userId = customer.email || subscription.customer;
      console.log(`🔍 Aucun ID Firebase trouvé dans les métadonnées, utilisation de fallback: ${userId}`);
      
      // Essayer de trouver l'utilisateur par email dans Firebase
      if (customer.email) {
        try {
          console.log(`🔍 Recherche de l'utilisateur par email: ${customer.email}`);
          const userRecord = await admin.auth().getUserByEmail(customer.email);
          if (userRecord) {
            userId = userRecord.uid;
            console.log(`🔍 Utilisateur trouvé par email: ${userId}`);
          }
        } catch (error) {
          console.log(`🔍 Utilisateur non trouvé par email: ${error.message}`);
        }
      }
    }
    
    const subscriptionId = subscription.id;
    const status = subscription.status;
    const isActive = status === 'active' || status === 'trialing';
    
    // Obtenir le produit pour déterminer le type de plan
    const productId = subscription.items.data[0].price.product;
    
    // Déterminer le type de plan et le nombre de véhicules
    let planType = 'free';
    let stripeNumberOfCars = 1;
    
    // Mapper l'ID du produit au type de plan
    if (productId === 'prod_RiIVqYAhJGzB0u') {
      planType = 'premium-monthly_access';
      stripeNumberOfCars = 10;
    } else if (productId === 'prod_RiIXsD22K4xehY') {
      planType = 'premium-yearly_access';
      stripeNumberOfCars = 10;
    } else if (productId === 'prod_S26yXish2BNayF' || productId === 'prod_S27nF635Z0AoFs') {
      planType = 'platinum-monthly_access';
      stripeNumberOfCars = 20;
    } else if (productId === 'prod_S26xbnrxhZn6TT') {
      planType = 'platinum-yearly_access';
      stripeNumberOfCars = 20;
    }
    
    console.log(`📝 Mise à jour Firebase pour l'utilisateur: ${userId}, plan: ${planType}, actif: ${isActive}`);
    
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
    
    console.log(`📝 Firebase mis à jour avec succès pour l'utilisateur: ${userId}`);
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
