import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class UserInfoManager {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Callback pour mettre à jour l'état dans le widget parent
  final Function(String) onPrenomLoaded;
  
  // Constructeur
  UserInfoManager({required this.onPrenomLoaded});
  
  // Méthode pour charger les données utilisateur
  Future<void> loadUserData() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        print('👤 Chargement des données utilisateur...');
        // Vérifier l'état de l'abonnement via RevenueCat
        final customerInfo = await Purchases.getCustomerInfo();
        print(
            '📱 État RevenueCat: ${customerInfo.entitlements.active.length} abonnement(s) actif(s)');

        // Vérifier si l'utilisateur est un collaborateur
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        
        if (userDoc.exists && userDoc.data()?['role'] == 'collaborateur') {
          // C'est un collaborateur, récupérer ses propres données
          print('👥 Utilisateur collaborateur détecté');
          
          // Récupérer l'ID de l'admin pour référence
          final adminId = userDoc.data()?['adminId'];
          if (adminId != null) {
            print('👥 Administrateur associé: $adminId');
          }
          
          // Utiliser les données disponibles dans le document du collaborateur
          String prenom = userDoc.data()?['prenom'] ?? '';
          onPrenomLoaded(prenom);
        } else {
          // C'est un administrateur, continuer normalement
          final userData = await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('authentification')
              .doc(user.uid)
              .get();

          if (userData.exists) {
            String prenom = userData.data()?['prenom'] ?? '';
            onPrenomLoaded(prenom);
          }
        }
      } catch (e) {
        print('❌ Erreur chargement données: $e');
      }
    }
  }
}
