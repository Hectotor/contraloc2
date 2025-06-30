const functions = require('firebase-functions');
const admin = require('firebase-admin');

// Fonction pour mettre à jour le document principal du collaborateur lorsque ses informations sont modifiées
exports.updateCollaboratorUserDocument = functions.firestore
  .onDocumentUpdated('/users/{adminId}/collaborateurs/{collaboratorId}', async (event) => {
    try {
      const beforeData = event.data.before.data();
      const afterData = event.data.after.data();
      const collaboratorId = event.params.collaboratorId;
      
      // Vérifier si les données ont changé
      if (JSON.stringify(beforeData) === JSON.stringify(afterData)) {
        console.log('Aucun changement détecté pour le collaborateur', collaboratorId);
        return { success: true, noChanges: true };
      }
      
      console.log(`Mise à jour du document principal pour le collaborateur ${collaboratorId}`);
      
      // Préparer les données à mettre à jour
      const updateData = {};
      
      // Mettre à jour uniquement les champs qui ont changé
      if (beforeData.email !== afterData.email) updateData.email = afterData.email;
      if (beforeData.nom !== afterData.nom) updateData.nom = afterData.nom;
      if (beforeData.prenom !== afterData.prenom) updateData.prenom = afterData.prenom;
      
      // Gérer le cas spécial pour receiveContractCopies qui peut ne pas exister dans beforeData
      const beforeReceiveContractCopies = beforeData.receiveContractCopies !== undefined ? beforeData.receiveContractCopies : false;
      const afterReceiveContractCopies = afterData.receiveContractCopies !== undefined ? afterData.receiveContractCopies : false;
      
      if (beforeReceiveContractCopies !== afterReceiveContractCopies) {
        updateData.receiveContractCopies = afterReceiveContractCopies;
      }
      
      // Si aucun changement à appliquer, sortir
      if (Object.keys(updateData).length === 0) {
        console.log('Aucun changement pertinent à appliquer au document principal');
        return { success: true, noRelevantChanges: true };
      }
      
      // Mettre à jour le document principal du collaborateur
      await admin.firestore().collection('users').doc(collaboratorId).update(updateData);
      
      console.log(`Document principal du collaborateur ${collaboratorId} mis à jour avec succès`);
      return { success: true };
    } catch (error) {
      console.error(`Erreur lors de la mise à jour du document principal du collaborateur: ${error}`);
      return { success: false, error: error.message };
    }
  });
