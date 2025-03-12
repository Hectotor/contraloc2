import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HeritageCollabService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Synchronise tous les collaborateurs d'un admin
  static Future<void> synchroniserTousCollaborateurs() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('❌ Utilisateur non connecté');
        return;
      }

      // Vérifier si l'utilisateur est un admin
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data();
      
      if (userData == null || userData['role'] == 'collaborateur') {
        print('❌ L\'utilisateur n\'est pas un admin');
        return;
      }

      print('🔄 Début de la synchronisation de tous les collaborateurs');

      // Récupérer tous les collaborateurs de l'admin
      final collaborateursQuery = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('authentification')
          .where('role', isEqualTo: 'collaborateur')
          .get();

      // Synchroniser chaque collaborateur
      for (var collabDoc in collaborateursQuery.docs) {
        await synchroniserDonneesAdmin(collabDoc.id, user.uid, collabDoc.data()['uid']);
      }

      print('✅ Synchronisation terminée pour ${collaborateursQuery.docs.length} collaborateur(s)');
    } catch (e) {
      print('❌ Erreur lors de la synchronisation globale: $e');
      throw e;
    }
  }

  static Future<void> synchroniserDonneesAdmin(String collaborateurId, String adminId, String collaborateurUid) async {
    try {
      print('👥 Début de la synchronisation des données admin vers collaborateur');
      
      // 1. Récupérer les données de l'admin
      final adminDoc = await _firestore
          .collection('users')
          .doc(adminId)
          .collection('authentification')
          .doc(adminId)
          .get();

      final adminData = adminDoc.data();
      if (adminData == null) {
        print('❌ Données admin non trouvées');
        return;
      }

      // 2. Mettre à jour le document principal du collaborateur
      await _firestore
          .collection('users')
          .doc(collaborateurUid)
          .set({
            'adminId': adminId,
            'role': 'collaborateur',
            'id': collaborateurId
          }, SetOptions(merge: true));

      // 3. Mettre à jour le document du collaborateur dans la collection authentification de l'admin
      final collabData = {
        // Structure selon les MEMORIES
        'id': collaborateurId,
        'role': 'collaborateur',
        'uid': collaborateurUid,
        'adminId': adminId,
        'dateCreation': FieldValue.serverTimestamp(),
        
        // Permissions selon les MEMORIES
        'permissions': {
          'lecture': true,
          'ecriture': true,
          'suppression': true
        },

        // Hériter les limites de l'admin
        'cb_limite_contrat': adminData['cb_limite_contrat'],
        'cb_nb_car': adminData['cb_nb_car'],
        'cb_subscription': adminData['cb_subscription'],
        
        // Informations de l'entreprise
        'adresse': adminData['adresse'],
        'nomEntreprise': adminData['nomEntreprise'],
        'siret': adminData['siret'],
        'telephone': adminData['telephone'],
        'logoUrl': adminData['logoUrl'],
        
        // Tampon
        'tampon': adminData['tampon'] ?? {
          'adresse': adminData['adresse'],
          'nomEntreprise': adminData['nomEntreprise'],
          'siret': adminData['siret'],
          'telephone': adminData['telephone'],
          'logoUrl': adminData['logoUrl'],
        },
      };

      await _firestore
          .collection('users')
          .doc(adminId)
          .collection('authentification')
          .doc(collaborateurId)
          .set(collabData, SetOptions(merge: true));

      print('✅ Synchronisation réussie des données admin vers collaborateur');
    } catch (e) {
      print('❌ Erreur lors de la synchronisation: $e');
      throw e;
    }
  }
}
