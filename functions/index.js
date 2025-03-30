const functions = require('firebase-functions');
const admin = require('firebase-admin');

// Initialiser Firebase Admin
if (admin.apps.length === 0) {
  admin.initializeApp();
}

// Importer la fonction stripeWebhook depuis stripe_webhook.js
const stripeWebhookHandler = require('./stripe_webhook').stripeWebhook;

// Exporter la fonction stripeWebhook avec l'option pour permettre les requêtes non authentifiées
exports.stripeWebhook = functions
  .https
  .onRequest({
    invoker: 'public',  // Permet les appels non authentifiés
    rawBody: true       // Expose le corps brut de la requête pour la vérification de signature Stripe
  }, async (req, res) => {
    // Ajouter un log pour vérifier si rawBody est disponible
    console.log(`rawBody disponible: ${req.rawBody ? 'Oui' : 'Non'}`);
    if (req.rawBody) {
      console.log(`Longueur de rawBody: ${req.rawBody.length}`);
    }
    
    // Appeler le gestionnaire de webhook
    return stripeWebhookHandler(req, res);
  });
