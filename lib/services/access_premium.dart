import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AccessPremium {
  /// Vérifie si l'utilisateur (ou son administrateur) a un abonnement premium
  static Future<bool> isPremiumUser() async {
    try {
      // Vérifier si l'utilisateur est connecté
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('❌ Aucun utilisateur connecté');
        return false;
      }

      final uid = user.uid;
      
      // Récupérer les données de l'utilisateur
      final userDocRef = FirebaseFirestore.instance.collection('users').doc(uid);
      final userDoc = await userDocRef.get(GetOptions(source: Source.server));

      if (!userDoc.exists) {
        return false;
      }

      final userData = userDoc.data();
      if (userData == null) {
        return false;
      }

      // Vérifier si c'est un collaborateur
      if (userData['role'] == 'collaborateur') {
        final adminId = userData['adminId'];
        if (adminId == null) {
          print('❌ AdminId non trouvé pour le collaborateur');
          return false;
        }

        // Pour un collaborateur, vérifier le statut premium de l'admin
        final adminAuthDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(adminId)
            .collection('authentification')
            .doc(adminId)
            .get(GetOptions(source: Source.server));

        if (!adminAuthDoc.exists) {
          print('❌ Document auth admin non trouvé');
          return false;
        }

        final adminAuthData = adminAuthDoc.data();
        if (adminAuthData == null) {
          print('❌ Données auth admin null');
          return false;
        }

        // Vérifier tous les champs possibles pour premium et platinum
        final subscriptionId = adminAuthData['subscriptionId'] ?? 'free';
        final cbSubscription = adminAuthData['cb_subscription'] ?? 'free';
        final stripePlanType = adminAuthData['stripePlanType'] ?? 'free';
        
        print('📊 Valeurs d\'abonnement trouvées: subscriptionId=$subscriptionId, cbSubscription=$cbSubscription, stripePlanType=$stripePlanType');
        
        return subscriptionId.toString().contains('premium') ||
               subscriptionId.toString().contains('platinum') ||
               cbSubscription.toString().contains('premium') ||
               cbSubscription.toString().contains('platinum') ||
               stripePlanType.toString().contains('premium') ||
               stripePlanType.toString().contains('platinum');
      }

      // Pour un utilisateur normal, vérifier directement dans sa collection auth
      final authDocRef = userDocRef.collection('authentification').doc(uid);
      final authDoc = await authDocRef.get(GetOptions(source: Source.server));

      if (!authDoc.exists) {
        print('❌ Document auth utilisateur non trouvé');
        return false;
      }

      final authData = authDoc.data();
      if (authData == null) {
        print('❌ Données auth utilisateur null');
        return false;
      }

      // Vérifier tous les champs possibles pour premium et platinum
      final subscriptionId = authData['subscriptionId'] ?? 'free';
      final cbSubscription = authData['cb_subscription'] ?? 'free';
      final stripePlanType = authData['stripePlanType'] ?? 'free';
      
      print('📊 Valeurs d\'abonnement trouvées: subscriptionId=$subscriptionId, cbSubscription=$cbSubscription, stripePlanType=$stripePlanType');
      
      return subscriptionId.toString().contains('premium') ||
             subscriptionId.toString().contains('platinum') ||
             cbSubscription.toString().contains('premium') ||
             cbSubscription.toString().contains('platinum') ||
             stripePlanType.toString().contains('premium') ||
             stripePlanType.toString().contains('platinum');
    } catch (e) {
      print('❌ Erreur lors de la vérification du statut premium: $e');
      return false;
    }
  }
}
