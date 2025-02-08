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

  // Identifiants Stripe
  static const String _proMonthlyStripe = 'prod_RiISy7xcZzgFb5';
  static const String _proYearlyStripe = 'prod_RiIT1QQFJjV5hR';
  static const String _premiumMonthlyStripe = 'prod_RiIVqYAhJGzB0u';
  static const String _premiumYearlyStripe = 'prod_RiIXsD22K4xehY';

  // Getters pour obtenir le bon ID selon la plateforme
  static String get entitlementProMonthly =>
      Platform.isIOS ? _proMonthlyIOS : _proMonthlyAndroid;

  static String get entitlementProYearly =>
      Platform.isIOS ? _proYearlyIOS : _proYearlyAndroid;

  static String get entitlementPremiumMonthly =>
      Platform.isIOS ? _premiumMonthlyIOS : _premiumMonthlyAndroid;

  static String get entitlementPremiumYearly =>
      Platform.isIOS ? _premiumYearlyIOS : _premiumYearlyAndroid;

  // Constantes pour les packages
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
    await Purchases.setLogLevel(LogLevel.verbose);
    final apiKey = Platform.isIOS ? iosApiKey : androidApiKey;
    await Purchases.configure(PurchasesConfiguration(apiKey));
    print('🔑 RevenueCat initialisé avec la clé: ${apiKey.substring(0, 10)}...');
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
      String plan, bool isMonthly, {String? paymentMethod}) async {
    try {
      String productId;

      // Déterminer le bon ID de produit
      if (plan.contains("Premium")) {
        productId = isMonthly 
          ? (paymentMethod == 'card' ? _premiumMonthlyStripe : 
             Platform.isIOS ? _premiumMonthlyIOS : _premiumMonthlyAndroid)
          : (paymentMethod == 'card' ? _premiumYearlyStripe : 
             Platform.isIOS ? _premiumYearlyIOS : _premiumYearlyAndroid);
      } else if (plan.contains("Pro")) {
        productId = isMonthly 
          ? (paymentMethod == 'card' ? _proMonthlyStripe : 
             Platform.isIOS ? _proMonthlyIOS : _proMonthlyAndroid)
          : (paymentMethod == 'card' ? _proYearlyStripe : 
             Platform.isIOS ? _proYearlyIOS : _proYearlyAndroid);
      } else {
        throw Exception('Plan non reconnu: $plan');
      }

      print('🛒 Détails de l\'achat :');
      print('   📦 Plan: $plan');
      print('   🕰️ Durée: ${isMonthly ? "Mensuel" : "Annuel"}');
      print('   💳 Méthode de paiement: $paymentMethod');
      print('   🆔 ID Produit: $productId');
      print('   📱 Plateforme: ${Platform.isIOS ? "iOS" : "Android"}');

      // Récupérer le produit
      final products = await Purchases.getProducts([productId]);
      
      print('🔍 Produits récupérés :');
      for (var product in products) {
        print('   🏷️ Identifiant: ${product.identifier}');
        print('   💰 Prix: ${product.price}');
        print('   📝 Description: ${product.description}');
      }

      if (products.isEmpty) {
        print('❌ ERREUR : Aucun produit trouvé pour l\'ID $productId');
        throw Exception('Produit non trouvé: $productId');
      }

      print('🎯 Tentative d\'achat du produit: ${products.first.identifier}');
      final customerInfo = await Purchases.purchaseProduct(productId);

      print('✅ Achat réussi');
      print('📱 Entitlements actifs: ${customerInfo.entitlements.active.keys}');
      return customerInfo;
    } on PlatformException catch (e) {
      print('❌ ERREUR DE PAIEMENT DÉTAILLÉE :');
      print('   📝 Message: ${e.message}');
      print('   🆔 Code: ${e.code}');
      print('   📦 Détails: ${e.details}');

      // Si l'utilisateur annule l'achat, on retourne null sans erreur
      if (e.details != null && e.details?['userCancelled'] == true) {
        print('ℹ️ Achat annulé par l\'utilisateur');
        return null;
      }
      
      // Pour les autres erreurs, on relance
      rethrow;
    }
  }
}
