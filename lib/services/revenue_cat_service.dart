import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'dart:io';

class RevenueCatService {
  // Identifiants iOS
  static const String _proMonthlyIOS = 'ProMonthlySubscription';
  static const String _proYearlyIOS = 'ProYearlySubscription';
  static const String _premiumMonthlyIOS = 'PremiumMonthlySubscription';
  static const String _premiumYearlyIOS = 'PremiumYearlySubscription';

  // Identifiants Android
  static const String _proMonthlyAndroid = 'offre_contraloc:pro-monthly';
  static const String _proYearlyAndroid = 'offre_contraloc:pro-yearly';
  static const String _premiumMonthlyAndroid =
      'offre_contraloc:premium-monthly';
  static const String _premiumYearlyAndroid = 'offre_contraloc:premium-yearly';

  // Getters pour obtenir le bon ID selon la plateforme
  static String get entitlementProMonthly =>
      Platform.isIOS ? _proMonthlyIOS : _proMonthlyAndroid;

  static String get entitlementProYearly =>
      Platform.isIOS ? _proYearlyIOS : _proYearlyAndroid;

  static String get entitlementPremiumMonthly =>
      Platform.isIOS ? _premiumMonthlyIOS : _premiumMonthlyAndroid;

  static String get entitlementPremiumYearly =>
      Platform.isIOS ? _premiumYearlyIOS : _premiumYearlyAndroid;

  // Constantes pour l'offering et les packages
  static const String OFFERING_ID = 'default'; // Changed from 'OFFRE'
  static const String PACKAGE_PREMIUM_YEARLY = 'premium_yearly';
  static const String PACKAGE_PREMIUM_MONTHLY = 'premium_monthly';
  static const String PACKAGE_PRO_YEARLY = 'pro_yearly';
  static const String PACKAGE_PRO_MONTHLY = 'pro_monthly';

  // Identifiants des produits par plateforme
  static final Map<String, String> productIds = Platform.isIOS
      ? {
          PACKAGE_PRO_MONTHLY: _proMonthlyIOS,
          PACKAGE_PRO_YEARLY: _proYearlyIOS,
          PACKAGE_PREMIUM_MONTHLY: _premiumMonthlyIOS,
          PACKAGE_PREMIUM_YEARLY: _premiumYearlyIOS,
        }
      : {
          PACKAGE_PRO_MONTHLY: _proMonthlyAndroid,
          PACKAGE_PRO_YEARLY: _proYearlyAndroid,
          PACKAGE_PREMIUM_MONTHLY: _premiumMonthlyAndroid,
          PACKAGE_PREMIUM_YEARLY: _premiumYearlyAndroid,
        };

  static Future<void> initialize({
    required String androidApiKey,
    required String iosApiKey,
  }) async {
    await Purchases.setLogLevel(LogLevel.debug);
    final apiKey = Platform.isIOS ? iosApiKey : androidApiKey;
    await Purchases.configure(PurchasesConfiguration(apiKey));
  }

  static Future<void> login(String userId) async {
    try {
      await Purchases.logIn(userId);
      print('✅ RevenueCat login réussi pour: $userId');
    } catch (e) {
      print('❌ Erreur RevenueCat login: $e');
    }
  }

  static Future<void> logout() async {
    try {
      await Purchases.logOut();
      print('✅ RevenueCat logout réussi');
    } catch (e) {
      print('❌ Erreur RevenueCat logout: $e');
    }
  }

  static Future<CustomerInfo?> checkEntitlements() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      final activeEntitlements = customerInfo.entitlements.active.keys;

      print(
          '📱 État RevenueCat: ${activeEntitlements.length} abonnement(s) actif(s)');
      print('📱 Entitlements actifs: $activeEntitlements');

      // Si plusieurs abonnements sont actifs, prioriser Premium sur Pro
      if (activeEntitlements.length > 1) {
        // Créer une copie de customerInfo avec uniquement l'abonnement prioritaire
        if (hasPremiumAccess(customerInfo)) {
          // Garder uniquement l'abonnement Premium
          customerInfo.entitlements.active.removeWhere(
            (key, _) => !key.contains('premium'),
          );
        } else if (hasProAccess(customerInfo)) {
          // Garder uniquement l'abonnement Pro
          customerInfo.entitlements.active.removeWhere(
            (key, _) => !key.contains('pro'),
          );
        }
        print(
            '📱 Après priorisation: ${customerInfo.entitlements.active.keys}');
      }

      return customerInfo;
    } catch (e) {
      print('❌ Erreur vérification entitlements: $e');
      return null;
    }
  }

  static bool hasProAccess(CustomerInfo customerInfo) {
    return customerInfo.entitlements.active
            .containsKey(entitlementProMonthly) ||
        customerInfo.entitlements.active.containsKey(entitlementProYearly);
  }

  static bool hasPremiumAccess(CustomerInfo customerInfo) {
    return customerInfo.entitlements.active
            .containsKey(entitlementPremiumMonthly) ||
        customerInfo.entitlements.active.containsKey(entitlementPremiumYearly);
  }

  static bool isYearlyPlan(CustomerInfo customerInfo) {
    return customerInfo.entitlements.active.containsKey(entitlementProYearly) ||
        customerInfo.entitlements.active.containsKey(entitlementPremiumYearly);
  }

  static Future<CustomerInfo?> purchaseProduct(
      String plan, bool isMonthly) async {
    try {
      String productId;

      // Déterminer le bon ID de produit
      if (plan.contains("Premium")) {
        productId =
            isMonthly ? entitlementPremiumMonthly : entitlementPremiumYearly;
      } else if (plan.contains("Pro")) {
        productId = isMonthly ? entitlementProMonthly : entitlementProYearly;
      } else {
        throw Exception('Plan non reconnu: $plan');
      }

      print('🛒 Tentative d\'achat du produit: $productId');
      print('📱 Plateforme: ${Platform.isIOS ? "iOS" : "Android"}');

      // Récupérer le produit
      final products = await Purchases.getProducts([productId]);
      if (products.isEmpty) {
        throw Exception('Produit non trouvé: $productId');
      }

      // Achat direct du produit
      print('🎯 Achat du produit: ${products.first.identifier}');
      final customerInfo = await Purchases.purchaseProduct(productId);

      print('✅ Achat réussi');
      print('📱 Entitlements actifs: ${customerInfo.entitlements.active.keys}');
      return customerInfo;
    } on PlatformException catch (e) {
      // Si l'utilisateur annule l'achat, on retourne null sans erreur
      if (e.details != null && e.details?['userCancelled'] == true) {
        print('ℹ️ Achat annulé par l\'utilisateur');
        return null;
      }
      // Pour les autres erreurs, on affiche l'erreur et on la relance
      print('❌ Erreur lors de l\'achat: ${e.message}');
      rethrow;
    }
  }
}
