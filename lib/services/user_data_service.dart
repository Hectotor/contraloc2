import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../services/heritage_collab.dart';

class UserDataService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<Map<String, dynamic>> initializeUserData() async {
    final user = _auth.currentUser;
    if (user == null) {
      return {'prenom': '', 'canWrite': false};
    }

    try {
      print('👤 Chargement des données utilisateur...');
      
      // Vérifier l'état de l'abonnement via RevenueCat
      final customerInfo = await Purchases.getCustomerInfo();
      print('📱 État RevenueCat: ${customerInfo.entitlements.active.length} abonnement(s) actif(s)');

      // Vérifier le rôle de l'utilisateur
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data();

      String prenom = '';
      bool canWrite = true;

      if (userData != null && userData['role'] == 'collaborateur') {
        print('👥 Utilisateur identifié comme collaborateur');
        final adminId = userData['adminId'] as String;

        // Charger les données du collaborateur
        final collaboratorData = await _firestore
            .collection('users')
            .doc(adminId)
            .collection('authentification')
            .where('uid', isEqualTo: user.uid)
            .limit(1)
            .get();

        if (collaboratorData.docs.isNotEmpty) {
          final collabDoc = collaboratorData.docs.first;
          final collabId = collabDoc.id;

          // Synchroniser les données avec l'admin
          await HeritageCollabService.synchroniserDonneesAdmin(
            collabId,
            adminId,
            user.uid
          );

          final collabData = collabDoc.data();
          prenom = collabData['prenom'] ?? '';
          canWrite = collabData['permissions']?['ecriture'] ?? false;
        }
      } else {
        print('👤 Utilisateur identifié comme admin');
        final adminData = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('authentification')
            .doc(user.uid)
            .get();

        if (adminData.exists) {
          prenom = adminData.data()?['prenom'] ?? '';
        }
      }

      return {
        'prenom': prenom,
        'canWrite': canWrite,
      };
    } catch (e) {
      print('❌ Erreur lors de l\'initialisation: $e');
      return {'prenom': '', 'canWrite': false};
    }
  }
}
