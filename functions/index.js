const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");

initializeApp();
const db = getFirestore();

exports.addCollaboratorToUser = onDocumentCreated(
  "users/{adminId}/collaborateurs/{collaboratorId}",
  async (event) => {
    const adminId = event.params.adminId;
    const collaboratorId = event.params.collaboratorId;

    // Vérifier si les données existent
    if (!event.data) {
      console.log("Aucune donnée reçue pour le collaborateur");
      return;
    }

    const collaboratorData = event.data.data();

    // Ajouter les données du collaborateur au document principal du collaborateur
    await db.collection("users").doc(collaboratorId).set(
      {
        adminId: adminId,
        role: "collaborateur",
        ...collaboratorData,
      },
      { merge: true }
    );

    console.log(`Collaborateur ${collaboratorId} ajouté à la collection users`);
  }
);
