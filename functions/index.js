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

// Fonction pour créer automatiquement un document utilisateur pour les collaborateurs
exports.createCollaboratorUserDocument = functions.firestore
  .onDocumentCreated('/users/{adminId}/collaborateurs/{collaboratorId}', async (event) => {
    try {
      const snapshot = event.data;
      if (!snapshot) {
        console.log('Pas de données disponibles');
        return { success: false, error: 'Pas de données disponibles' };
      }
      
      const collaboratorData = snapshot.data();
      const { adminId, uid } = collaboratorData;
      
      // Vérifier si le document utilisateur existe déjà
      const userDoc = await admin.firestore().collection('users').doc(uid).get();
      
      if (!userDoc.exists) {
        console.log(`Création du document utilisateur pour le collaborateur ${uid}`);
        
        // Créer le document utilisateur pour le collaborateur
        await admin.firestore().collection('users').doc(uid).set({
          role: 'collaborateur',
          adminId: adminId,
          email: collaboratorData.email,
          nom: collaboratorData.nom,
          prenom: collaboratorData.prenom,
          permissions: collaboratorData.permissions,
          emailVerifie: false,
          dateCreation: admin.firestore.FieldValue.serverTimestamp(),
        });
        
        console.log(`Document utilisateur créé avec succès pour le collaborateur ${uid}`);
        return { success: true };
      } else {
        console.log(`Le document utilisateur pour le collaborateur ${uid} existe déjà`);
        return { success: true, alreadyExists: true };
      }
    } catch (error) {
      console.error(`Erreur lors de la création du document utilisateur: ${error}`);
      return { success: false, error: error.message };
    }
  });
