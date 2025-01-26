const functions = require('firebase-functions');
const admin = require('firebase-admin');
const axios = require('axios');

admin.initializeApp();

exports.updateSubscription = functions.https.onCall(async (data, context) => {
  const userId = context.auth.uid;
  const subscriptionId = data.subscriptionId;

  // Utiliser la clé API secrète pour faire un appel sécurisé à RevenueCat
  const apiKey = functions.config().revenuecat.secret_api_key;

  try {
    const response = await axios.post('https://api.revenuecat.com/v1/subscribers', {
      app_user_id: userId,
      subscription_id: subscriptionId,
    }, {
      headers: {
        'Authorization': `Bearer ${apiKey}`,
      },
    });

    return { success: true, data: response.data };
  } catch (error) {
    console.error('Erreur lors de la mise à jour de l\'abonnement:', error);
    throw new functions.https.HttpsError('internal', 'Erreur lors de la mise à jour de l\'abonnement');
  }
});
