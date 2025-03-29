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
          1,  
        );
        print('✨ Statut mis à jour vers compte gratuit');
        return;
      }

      bool isActive = false;
      String subscriptionId = 'free';
      int numberOfCars = 1;

      final activeEntitlements = customerInfo.entitlements.active.keys;
      print('📱 Entitlements actifs trouvés: $activeEntitlements');

      // Vérifier d'abord si l'utilisateur a un accès Platinum
      if (activeEntitlements.contains('platinum-monthly_access') ||
          activeEntitlements.contains('platinum-yearly_access') ||
          activeEntitlements.contains('pro-monthly_access') ||
          activeEntitlements.contains('pro-yearly_access')) {
        print('✨ Accès Platinum détecté');
        isActive = true;
        // Utiliser exactement la même chaîne que l'entitlement
        subscriptionId = 'platinum-monthly_access'; 
        numberOfCars = 20; 
      }
      // Ensuite vérifier l'accès premium
      else if (activeEntitlements.contains('premium-monthly_access') ||
          activeEntitlements.contains('premium-yearly_access')) {
        print('✨ Accès Premium détecté');
        isActive = true;
        subscriptionId = activeEntitlements.contains('premium-monthly_access')
            ? RevenueCatService.entitlementPremiumMonthly
            : RevenueCatService.entitlementPremiumYearly;
        numberOfCars = 10; 
      }

      print('📱 Mise à jour avec subscriptionId: $subscriptionId');
      print('📱 Statut actif: $isActive');
      print('📱 Nombre de véhicules: $numberOfCars');

      await updateFirestoreSubscription(
        user.uid,
        subscriptionId,
        isActive,
        numberOfCars,
      );
      print(
          '✅ Mise à jour Firestore réussie pour l\'abonnement: $subscriptionId');
    } catch (e) {
      print('❌ Erreur mise à jour abonnement: $e');
      throw e; 
    }
  }

  static Future<void> updateFirestoreSubscription(
    String userId,
    String subscriptionId,
    bool isActive,
    int numberOfCars,
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
      'lastUpdateDate': FieldValue.serverTimestamp(),
    };

    try {
      await userDoc.set(data, SetOptions(merge: true));
    } catch (e) {
      print('❌ Erreur mise à jour Firestore: $e');
      throw e;
    }
  }

  /// Active l'abonnement gratuit directement dans Firestore
  static Future<void> activateFreeSubscription() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      print('🔄 Activation de l\'abonnement gratuit...');
      
      final userDoc = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('authentification')
          .doc(user.uid);

      final data = {
        'subscriptionId': 'Gratuit',
        'isSubscriptionActive': true,
        'numberOfCars': 1,
        'stripeSubscriptionId': '',
        'stripeStatus': 'active',
        'subscriptionSource': '',  // Pas de source spécifique pour l'offre gratuite
        'lastUpdateDate': FieldValue.serverTimestamp(),
      };

      await userDoc.set(data, SetOptions(merge: true));
      print('✨ Abonnement gratuit activé avec succès');
    } catch (e) {
      print('❌ Erreur lors de l\'activation de l\'abonnement gratuit: $e');
      throw e;
    }
  }
}
