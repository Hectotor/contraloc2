import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:flutter/material.dart';
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
  static const String _premiumMonthlyAndroid = 'offre_contraloc:premium-monthly';
  static const String _premiumYearlyAndroid = 'offre_contraloc:premium-yearly';

  // Mapping complet des identifiants
  static final Map<String, String> subscriptionIdMapping = {
    // iOS Mappings
    'PremiumMonthlySubscription': 'premium-monthly_access',
    'PremiumYearlySubscription': 'premium-yearly_access',
    'ProMonthlySubscription': 'pro-monthly_access',
    'ProYearlySubscription': 'pro-yearly_access',
    
    // Android Mappings
    'offre_contraloc:premium-monthly': 'premium-monthly_access',
    'offre_contraloc:premium-yearly': 'premium-yearly_access',
    'offre_contraloc:pro-monthly': 'pro-monthly_access',
    'offre_contraloc:pro-yearly': 'pro-yearly_access',
  };

  // Méthode de mapping générique
  static String mapSubscriptionId(String originalId) {
    return subscriptionIdMapping[originalId] ?? originalId;
  }

  // Méthode inverse pour obtenir l'ID original
  static String? getOriginalId(String mappedId) {
    return subscriptionIdMapping.keys.firstWhere(
      (key) => subscriptionIdMapping[key] == mappedId, 
      orElse: () => mappedId
    );
  }

  // Getters pour obtenir le bon ID selon la plateforme
  static String get entitlementProMonthly {
    if (Platform.isIOS) return mapSubscriptionId(_proMonthlyIOS);
    return mapSubscriptionId(_proMonthlyAndroid);
  }

  static String get entitlementProYearly {
    if (Platform.isIOS) return mapSubscriptionId(_proYearlyIOS);
    return mapSubscriptionId(_proYearlyAndroid);
  }

  static String get entitlementPremiumMonthly {
    if (Platform.isIOS) return mapSubscriptionId(_premiumMonthlyIOS);
    return mapSubscriptionId(_premiumMonthlyAndroid);
  }

  static String get entitlementPremiumYearly {
    if (Platform.isIOS) return mapSubscriptionId(_premiumYearlyIOS);
    return mapSubscriptionId(_premiumYearlyAndroid);
  }

  // Constantes pour les packages
  static const String PACKAGE_PREMIUM_YEARLY = 'premium_yearly';
  static const String PACKAGE_PREMIUM_MONTHLY = 'premium_monthly';
  static const String PACKAGE_PRO_YEARLY = 'pro_yearly';
  static const String PACKAGE_PRO_MONTHLY = 'pro_monthly';

  // Identifiants des produits par plateforme
  static final Map<String, String> productIds = {
    // iOS Products
    'ios_pro_monthly': _proMonthlyIOS,
    'ios_pro_yearly': _proYearlyIOS,
    'ios_premium_monthly': _premiumMonthlyIOS,
    'ios_premium_yearly': _premiumYearlyIOS,
    
    // Android Products
    'android_pro_monthly': _proMonthlyAndroid,
    'android_pro_yearly': _proYearlyAndroid,
    'android_premium_monthly': _premiumMonthlyAndroid,
    'android_premium_yearly': _premiumYearlyAndroid,
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

      print('📱 État RevenueCat: ${activeEntitlements.length} abonnement(s) actif(s)');
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
        print('📱 Après priorisation: ${customerInfo.entitlements.active.keys}');
      }

      return customerInfo;
    } catch (e) {
      print('❌ Erreur vérification entitlements: $e');
      return null;
    }
  }

  static bool hasProAccess(CustomerInfo customerInfo) {
    return customerInfo.entitlements.active.keys
      .map(mapSubscriptionId)
      .any((id) => id.contains('pro-'));
  }

  static bool hasPremiumAccess(CustomerInfo customerInfo) {
    return customerInfo.entitlements.active.keys
      .map(mapSubscriptionId)
      .any((id) => id.contains('premium-'));
  }

  static bool isYearlyPlan(CustomerInfo customerInfo) {
    return customerInfo.entitlements.active.keys
      .map(mapSubscriptionId)
      .any((id) => id.contains('yearly'));
  }

  static Future<CustomerInfo?> purchaseProduct(
    String plan, 
    bool isMonthly
  ) async {
    try {
      String productId;

      // Déterminer le bon ID de produit avec mapping
      if (plan.contains("Premium")) {
        productId = isMonthly 
          ? (Platform.isIOS ? _premiumMonthlyIOS : _premiumMonthlyAndroid)
          : (Platform.isIOS ? _premiumYearlyIOS : _premiumYearlyAndroid);
      } else if (plan.contains("Pro")) {
        productId = isMonthly 
          ? (Platform.isIOS ? _proMonthlyIOS : _proMonthlyAndroid)
          : (Platform.isIOS ? _proYearlyIOS : _proYearlyAndroid);
      } else {
        throw Exception('Plan non reconnu: $plan');
      }

      // Log avec ID mappé
      print('🛒 Détails de l\'achat :');
      print('   📦 Plan: $plan');
      print('   🕰️ Durée: ${isMonthly ? "Mensuel" : "Annuel"}');
      print('   🆔 ID Produit Original: $productId');
      print('   🔄 ID Produit Mappé: ${mapSubscriptionId(productId)}');

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
      print('📱 Entitlements mappés: ${
        customerInfo.entitlements.active.keys.map(mapSubscriptionId).toSet()
      }');

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

  static Future<CustomerInfo?> processSubscription(
    BuildContext context, {
    required String plan,
    required bool isMonthly,
  }) async {
    try {
      // Montrer un indicateur de chargement
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      );

      // Effectuer l'achat de l'abonnement
      final customerInfo = await purchaseProduct(plan, isMonthly);

      // Fermer le chargement
      Navigator.of(context).pop();

      // Si l'achat est réussi, afficher le popup de félicitations
      if (customerInfo != null) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle_outline, 
                      color: Colors.green, 
                      size: 80,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Félicitations !', 
                      style: TextStyle(
                        fontSize: 24, 
                        fontWeight: FontWeight.bold,
                        color: Colors.black87
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Votre abonnement ${plan.toLowerCase()} ${isMonthly ? 'mensuel' : 'annuel'} a été activé avec succès.',
                      style: TextStyle(
                        fontSize: 16, 
                        color: Colors.black54
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                      ),
                      child: const Text(
                        'Continuer', 
                        style: TextStyle(
                          fontSize: 16, 
                          color: Colors.white
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }

      return customerInfo;
    } catch (e) {
      // Fermer le chargement en cas d'erreur
      Navigator.of(context).pop();

      // Afficher un message d'erreur
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Erreur'),
            content: Text('Une erreur est survenue lors de l\'abonnement : $e'),
            actions: [
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );

      return null;
    }
  }
}
