import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class SubscriptionService {
  static Future<void> checkAndUpdateSubscription() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Configurer RevenueCat avec l'identifiant unique de l'utilisateur
      await Purchases.configure(
          PurchasesConfiguration("public_api_key")..appUserID = user.uid);

      final customerInfo = await Purchases.getCustomerInfo();
      print('🔍 Vérification abonnement RevenueCat');

      // Vérifier les entitlements actifs
      final activeEntitlements = customerInfo.entitlements.active;

      // Ne pas mettre à jour immédiatement vers "free"
      if (activeEntitlements.isEmpty) {
        print('ℹ️ Aucun abonnement actif dans RevenueCat');
        // Ajouter un délai avant de passer à free pour éviter les flashs
        await Future.delayed(const Duration(seconds: 2));

        // Revérifier les entitlements après le délai
        final recheck = await Purchases.getCustomerInfo();
        if (recheck.entitlements.active.isEmpty) {
          await _updateFirestoreSubscription('free', false);
        }
        return;
      }

      // Trouver l'abonnement actif le plus récent dans RevenueCat
      EntitlementInfo? latestEntitlement;
      DateTime? latestDate;

      for (var entitlement in activeEntitlements.values) {
        final purchaseDate = DateTime.parse(entitlement.latestPurchaseDate);
        if (latestDate == null || purchaseDate.isAfter(latestDate)) {
          latestDate = purchaseDate;
          latestEntitlement = entitlement;
          print('📅 Date achat trouvée: ${purchaseDate.toIso8601String()}');
        }
      }

      if (latestEntitlement != null) {
        final standardizedId = latestEntitlement.productIdentifier;
        print('📦 Dernier abonnement RevenueCat: $standardizedId');
        print('📅 Date du dernier achat: ${latestDate?.toIso8601String()}');

        // Vérifier si une mise à jour est nécessaire
        final currentDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('authentification')
            .doc(user.uid)
            .get();

        final currentData = currentDoc.data();
        final currentSubscriptionId = currentData?['subscriptionId'];

        if (standardizedId != currentSubscriptionId) {
          print(
              '🔄 Mise à jour nécessaire: $currentSubscriptionId -> $standardizedId');
          await _updateFirestoreSubscription(standardizedId, true);
        } else {
          print('✅ Firestore déjà synchronisé avec RevenueCat');
        }
      }
    } catch (e) {
      print('❌ Erreur lors de la vérification RevenueCat: $e');
      // Ne pas mettre à jour Firestore en cas d'erreur pour éviter de perdre des données
    }
  }

  static Future<void> _updateFirestoreSubscription(
      String subscriptionId, bool isActive) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Ne pas mettre à jour vers "free" immédiatement si un changement est en cours
    if (subscriptionId == 'free') {
      // Vérifier l'état actuel dans Firestore
      final currentDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('authentification')
          .doc(user.uid)
          .get();

      final currentData = currentDoc.data();
      final currentSubscriptionId = currentData?['subscriptionId'];

      // Si l'utilisateur a déjà un abonnement actif, attendre confirmation
      if (currentSubscriptionId != null && currentSubscriptionId != 'free') {
        print('⏳ Attente de confirmation du changement d\'abonnement...');
        await Future.delayed(const Duration(seconds: 2));

        // Revérifier RevenueCat
        final customerInfo = await Purchases.getCustomerInfo();
        if (customerInfo.entitlements.active.isNotEmpty) {
          print('🔄 Abonnement toujours actif, annulation du passage à free');
          return;
        }
      }
    }

    // Déterminer le type de plan correctement
    String planType;
    if (subscriptionId.startsWith('premium-')) {
      planType = 'premium';
    } else if (subscriptionId.startsWith('pro-')) {
      planType = 'pro';
    } else {
      planType = 'free';
    }

    final data = {
      'subscriptionId': subscriptionId,
      'lastKnownProductId': subscriptionId,
      'planName': _getPlanName(subscriptionId),
      'planType': planType, // Utiliser le planType déterminé
      'isSubscriptionActive': isActive,
      'isExpired': !isActive,
      'numberOfCars': subscriptionId.startsWith('premium-')
          ? 999
          : (subscriptionId.startsWith('pro-') ? 5 : 1),
      'limiteContrat': subscriptionId.startsWith('premium-') ? 999 : 10,
      'subscriptionType':
          subscriptionId.contains('yearly') ? 'yearly' : 'monthly',
      'lastUpdateDate': FieldValue.serverTimestamp(),
      'lastUpdateTimestamp': DateTime.now().millisecondsSinceEpoch,
      'status': isActive ? 'active' : 'expired',
      'newProductId': FieldValue.delete(),
    };

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('authentification')
          .doc(user.uid)
          .update(data);
      print(
          '✅ Mise à jour Firestore réussie avec le plan: ${data['planType']}');
    } catch (e) {
      print('❌ Erreur mise à jour Firestore: $e');
      rethrow;
    }
  }

  // Nouvelle méthode helper pour déterminer le nom du plan
  static String _getPlanName(String subscriptionId) {
    print('🔍 Getting plan name for subscriptionId: $subscriptionId');

    // Faire correspondre exactement les IDs avec les noms d'affichage
    Map<String, String> planNames = {
      'premium-monthly': 'Offre Premium',
      'premium-yearly': 'Offre Premium Annuel',
      'pro-monthly': 'Offre Pro',
      'pro-yearly': 'Offre Pro Annuel',
      'free': 'Offre Gratuite'
    };

    String planName = planNames[subscriptionId] ?? 'Offre Gratuite';
    print('- Resolved plan name: $planName');
    return planName;
  }

  static Future<void> checkAndUpdateExpiredSubscription() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final customerInfo = await Purchases.getCustomerInfo();
      print('🔍 Vérification des abonnements expirés RevenueCat');

      // Vérifier les entitlements actifs
      final activeEntitlements = customerInfo.entitlements.active;

      if (activeEntitlements.isEmpty) {
        print('ℹ️ Aucun abonnement actif dans RevenueCat');
        await _updateFirestoreSubscription('free', false);
        return;
      }

      // Trouver l'abonnement actif le plus récent dans RevenueCat
      EntitlementInfo? latestEntitlement;
      DateTime? latestDate;

      for (var entitlement in activeEntitlements.values) {
        final purchaseDate = DateTime.parse(entitlement.latestPurchaseDate);
        if (latestDate == null || purchaseDate.isAfter(latestDate)) {
          latestDate = purchaseDate;
          latestEntitlement = entitlement;
          print('📅 Date achat trouvée: ${purchaseDate.toIso8601String()}');
        }
      }

      if (latestEntitlement != null) {
        final standardizedId = latestEntitlement.productIdentifier;
        print('📦 Dernier abonnement RevenueCat: $standardizedId');
        print('📅 Date du dernier achat: ${latestDate?.toIso8601String()}');

        // Vérifier si une mise à jour est nécessaire
        final currentDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('authentification')
            .doc(user.uid)
            .get();

        final currentData = currentDoc.data();
        final currentSubscriptionId = currentData?['subscriptionId'];

        if (standardizedId != currentSubscriptionId) {
          print(
              '🔄 Mise à jour nécessaire: $currentSubscriptionId -> $standardizedId');
          await _updateFirestoreSubscription(standardizedId, true);
        } else {
          print('✅ Firestore déjà synchronisé avec RevenueCat');
        }
      }
    } catch (e) {
      print('❌ Erreur lors de la vérification RevenueCat: $e');
      // Ne pas mettre à jour Firestore en cas d'erreur pour éviter de perdre des données
    }
  }
}

// Classe helper pour la gestion des infos d'abonnement
class SubscriptionInfo {
  final String planType;
  final String planName;
  final int numberOfCars;
  final int limiteContrat;

  SubscriptionInfo({
    required this.planType,
    required this.planName,
    required this.numberOfCars,
    required this.limiteContrat,
  });
}
