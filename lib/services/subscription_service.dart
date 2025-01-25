import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class SubscriptionService {
  // Ajouter cette nouvelle méthode de standardisation
  static String standardizeSubscriptionId(String originalId) {
    String normalizedId = originalId.toLowerCase();

    // Conversion des IDs iOS
    if (originalId == 'PremiumMonthlySubscription') return 'premium-monthly';
    if (originalId == 'PremiumYearlySubscription') return 'premium-yearly';
    if (originalId == 'ProMonthlySubscription') return 'pro-monthly';
    if (originalId == 'ProYearlySubscription') return 'pro-yearly';

    // Les IDs Android sont déjà standardisés
    if (normalizedId.contains('premium-') || normalizedId.contains('pro-')) {
      return normalizedId;
    }

    return 'free';
  }

  static Future<void> checkAndUpdateSubscription() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final customerInfo = await Purchases.getCustomerInfo();
      print('🔍 Vérification abonnement RevenueCat');

      // Vérifier les entitlements actifs
      final activeEntitlements = customerInfo.entitlements.active;

      // Vérifier l'état actuel dans Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('authentification')
          .doc(user.uid)
          .get();

      final currentFirestoreData = userDoc.data();
      final currentSubscriptionId =
          currentFirestoreData?['subscriptionId'] ?? 'free';

      // Si aucun abonnement actif dans RevenueCat
      if (activeEntitlements.isEmpty) {
        print('ℹ️ Aucun abonnement actif dans RevenueCat');
        if (currentSubscriptionId != 'free') {
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
        }
      }

      if (latestEntitlement != null) {
        final standardizedId =
            standardizeSubscriptionId(latestEntitlement.productIdentifier);
        print('📦 Abonnement RevenueCat trouvé: $standardizedId');

        // Vérifier si une mise à jour est nécessaire
        if (standardizedId != currentSubscriptionId) {
          print(
              '🔄 Mise à jour nécessaire: $currentSubscriptionId -> $standardizedId');
          await _updateFirestoreSubscription(
              latestEntitlement.productIdentifier, true);
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

    print('🔄 Mise à jour Firestore avec ID: $subscriptionId');

    // Standardiser l'ID avant utilisation
    String standardizedId = standardizeSubscriptionId(subscriptionId);
    String normalizedId = standardizedId.toLowerCase();

    // Déterminer le type d'abonnement plus précisément
    bool isPremium = normalizedId.contains('premium');
    bool isPro = normalizedId.contains('pro');
    bool isYearly = normalizedId.contains('yearly');

    // Calculer les limites en fonction du type d'abonnement
    int numberOfCars;
    int limiteContrat;

    // Assurer la cohérence des données
    String planName;
    if (isPremium) {
      planName = isYearly ? "Offre Premium Annuel" : "Offre Premium";
      numberOfCars = 999;
      limiteContrat = 999;
    } else if (isPro) {
      planName = isYearly ? "Offre Pro Annuel" : "Offre Pro";
      numberOfCars = 5;
      limiteContrat = 10;
    } else {
      planName = "Offre Gratuite";
      numberOfCars = 1;
      limiteContrat = 10;
    }

    final data = {
      'subscriptionId': standardizedId, // Utiliser l'ID standardisé
      'lastKnownProductId': subscriptionId, // Garder l'ID original
      'planName': planName, // Ajout de cette ligne
      'isSubscriptionActive': isActive,
      'numberOfCars': numberOfCars,
      'limiteContrat': limiteContrat,
      'subscriptionType': isYearly ? 'yearly' : 'monthly',
      'lastUpdateDate': FieldValue.serverTimestamp(),
      'lastUpdateTimestamp': DateTime.now().millisecondsSinceEpoch,
      'isExpired': !isActive,
      'planType': isPremium ? 'premium' : (isPro ? 'pro' : 'free'),
      'status': isActive ? 'active' : 'expired',
      // Supprimer le champ newProductId s'il existe
      'newProductId': FieldValue.delete(),
    };

    print('📝 Données à mettre à jour: $data');

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
}
