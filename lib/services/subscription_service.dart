import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'revenue_cat_service.dart';

class SubscriptionService {
  static Future<void> updateSubscriptionStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      print('🔄 Début de mise à jour du statut d\'abonnement...');
      
      // Vérifier le statut dans RevenueCat
      final customerInfo = await RevenueCatService.checkEntitlements();
      if (customerInfo == null || customerInfo.entitlements.active.isEmpty) {
        print('❌ Pas d\'abonnement RevenueCat actif');
        // Mettre à jour le statut comme gratuit si pas d'abonnement
        await updateFirestoreSubscription(
          user.uid,
          'free',
          false,
          1,  // Limite de base pour compte gratuit
          10,  // Limite de contrats pour compte gratuit
        );
        print('✨ Statut mis à jour vers compte gratuit');
        return;
      }

      bool isActive = false;
      String subscriptionId = 'free';
      int numberOfCars = 1;
      int limiteContrat = 10;

      final activeEntitlements = customerInfo.entitlements.active.keys;
      print('📱 Entitlements actifs trouvés: $activeEntitlements');

      // Modification ici: vérifier d'abord si l'utilisateur a un accès pro
      if (activeEntitlements.contains('pro-monthly_access') ||
          activeEntitlements.contains('pro-yearly_access')) {
        print('✨ Accès Pro détecté');
        isActive = true;
        // Modification ici : utiliser exactement la même chaîne que l'entitlement
        subscriptionId =
            'pro-monthly_access'; // Au lieu de RevenueCatService.entitlementProMonthly
        numberOfCars = 5;
        limiteContrat = 10;
      }
      // Ensuite vérifier l'accès premium
      else if (activeEntitlements.contains('premium-monthly_access') ||
          activeEntitlements.contains('premium-yearly_access')) {
        print('✨ Accès Premium détecté');
        isActive = true;
        subscriptionId = activeEntitlements.contains('premium-monthly_access')
            ? RevenueCatService.entitlementPremiumMonthly
            : RevenueCatService.entitlementPremiumYearly;
        numberOfCars = 999;
        limiteContrat = 999;
      }

      print('📱 Mise à jour avec subscriptionId: $subscriptionId');
      print('📱 Statut actif: $isActive');
      print('📱 Nombre de véhicules: $numberOfCars');
      print('📱 Limite de contrats: $limiteContrat');

      await updateFirestoreSubscription(
        user.uid,
        subscriptionId,
        isActive,
        numberOfCars,
        limiteContrat,
      );
      print(
          '✅ Mise à jour Firestore réussie pour l\'abonnement: $subscriptionId');
    } catch (e) {
      print('❌ Erreur mise à jour abonnement: $e');
      throw e; // Rethrow to handle in UI
    }
  }

  static Future<void> updateFirestoreSubscription(
    String userId,
    String subscriptionId,
    bool isActive,
    int numberOfCars,
    int limiteContrat,
  ) async {
    final userDoc = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('authentification')
        .doc(userId);

    final data = {
      'subscriptionId': subscriptionId,
      'isSubscriptionActive': isActive,
      'numberOfCars': numberOfCars,
      'limiteContrat': limiteContrat,
      'lastUpdateDate': FieldValue.serverTimestamp(),
    };

    try {
      await userDoc.set(data, SetOptions(merge: true));
    } catch (e) {
      print('❌ Erreur mise à jour Firestore: $e');
      throw e;
    }
  }

}
