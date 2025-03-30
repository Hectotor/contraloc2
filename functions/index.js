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
    invoker: 'public'  // Permet les appels non authentifiés
  }, async (req, res) => {
    // Appeler le gestionnaire de webhook
    return stripeWebhookHandler(req, res);
  });
