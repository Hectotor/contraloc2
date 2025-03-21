const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");

initializeApp();
const db = getFirestore();

// La Cloud Function addCollaboratorToUser a été supprimée car elle n'est plus nécessaire
// Les données des collaborateurs sont maintenant uniquement stockées dans la sous-collection
// de l'administrateur (users/{adminId}/collaborateurs/{collaboratorId})
