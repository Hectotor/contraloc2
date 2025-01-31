import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class SubscriptionService {
  static Future<void> checkAndUpdateSubscription() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final customerInfo = await Purchases.getCustomerInfo();
      print('🔍 Vérification abonnement RevenueCat');

      final activeEntitlements = customerInfo.entitlements.active;

      print('📦 Entitlements actifs: ${activeEntitlements.length}');
      activeEntitlements.forEach((key, value) {
        print('- Entitlement: ${value.identifier}');
        print('- ProductId: ${value.productIdentifier}');
      });

      // Forcer la mise à jour si l'ID est 'offre_contraloc'
      final currentDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('authentification')
          .doc(user.uid)
          .get();

      final currentData = currentDoc.data();
      final currentSubscriptionId = currentData?['subscriptionId'];

      if (currentSubscriptionId == 'offre_contraloc') {
        print('🔄 Conversion offre_contraloc vers pro-monthly');
        await _updateFirestoreSubscription('pro-monthly', true);
        return;
      }

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

  // Simplifié pour utiliser directement les IDs standardisés
  static String standardizeSubscriptionId(String originalId) {
    // Conversion des IDs iOS uniquement
    Map<String, String> iosToStandard = {
      'ProMonthlySubscription': 'pro-monthly',
      'ProYearlySubscription': 'pro-yearly',
      'PremiumMonthlySubscription': 'premium-monthly',
      'PremiumYearlySubscription': 'premium-yearly',
    };

    return iosToStandard[originalId] ?? originalId;
  }

  static Future<void> _updateFirestoreSubscription(
      String subscriptionId, bool isActive) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    print('🔄 Début mise à jour Firestore:');
    print('- ID reçu: $subscriptionId');

    String standardizedId;
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      final activeEntitlements = customerInfo.entitlements.active;

      print('📦 Vérification entitlements:');
      activeEntitlements.forEach((key, value) {
        print('- Entitlement ID: ${value.identifier}');
        print('- Product ID: ${value.productIdentifier}');
      });

      // Déterminer le type basé sur l'entitlement_id pour iOS et Android
      if (activeEntitlements.values.any((e) =>
          e.identifier == 'premium-monthly_access' ||
          e.productIdentifier == 'PremiumMonthlySubscription')) {
        standardizedId = 'premium-monthly';
        print('✨ Détection premium depuis entitlement');
      } else if (activeEntitlements.values.any((e) =>
          e.identifier == 'pro-monthly_access' ||
          e.productIdentifier == 'ProMonthlySubscription')) {
        standardizedId = 'pro-monthly';
        print('✨ Détection pro depuis entitlement');
      } else {
        standardizedId = 'free';
        print('ℹ️ Aucun entitlement reconnu');
      }

      print('- ID standardisé final: $standardizedId');
    } catch (e) {
      print('⚠️ Erreur entitlements: $e');
      standardizedId = 'free';
    }

    final data = {
      'subscriptionId': standardizedId,
      'lastKnownProductId': standardizedId,
      'planName': _getPlanName(standardizedId),
      'planType': standardizedId.startsWith('premium-')
          ? 'premium'
          : standardizedId.startsWith('pro-')
              ? 'pro'
              : 'free',
      'isSubscriptionActive': isActive,
      'isExpired': !isActive,
      'numberOfCars': standardizedId.startsWith('premium-')
          ? 999
          : standardizedId.startsWith('pro-')
              ? 5
              : 1,
      'limiteContrat': standardizedId.startsWith('premium-') ? 999 : 10,
      'subscriptionType':
          standardizedId.contains('yearly') ? 'yearly' : 'monthly',
      'lastUpdateDate': FieldValue.serverTimestamp(),
      'status': 'active',
    };

    print('📝 Données finales pour Firestore:');
    print('- subscriptionId: ${data['subscriptionId']}');
    print('- lastKnownProductId: ${data['lastKnownProductId']}');

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('authentification')
        .doc(user.uid)
        .update(data);

    print(
        '✅ Mise à jour Firestore terminée avec ID: ${data['subscriptionId']}');
  }

  // Mise à jour de la fonction getPlanName pour gérer les IDs simplifiés
  static String _getPlanName(String subscriptionId) {
    // Nettoyer l'ID d'abord
    String cleanId = subscriptionId;
    if (cleanId.contains(':')) {
      cleanId = cleanId.split(':')[1];
    }
    if (cleanId == 'offre_contraloc') {
      cleanId = 'pro-monthly';
    }

    Map<String, String> planNames = {
      'pro-monthly': 'Offre Pro',
      'pro-yearly': 'Offre Pro Annuel',
      'premium-monthly': 'Offre Premium',
      'premium-yearly': 'Offre Premium Annuel',
      'free': 'Offre Gratuite'
    };

    return planNames[cleanId] ?? 'Offre Gratuite';
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
