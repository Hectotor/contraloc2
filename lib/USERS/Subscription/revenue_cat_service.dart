import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:ContraLoc/widget/chargement.dart';

class RevenueCatService {
  // Identifiants iOS
  static const String _platinumMonthlyIOS = 'PlatinumMonthlySubscription';
  static const String _platinumYearlyIOS = 'PlatinumYearlySubscription';
  static const String _premiumMonthlyIOS = 'PremiumMonthlySubscription';
  static const String _premiumYearlyIOS = 'PremiumYearlySubscription';

  // Identifiants Android
  static const String _platinumMonthlyAndroid = 'offre_contraloc:platinum-monthly';
  static const String _platinumYearlyAndroid = 'offre_contraloc:platinum-yearly';
  static const String _premiumMonthlyAndroid = 'offre_contraloc:premium-monthly';
  static const String _premiumYearlyAndroid = 'offre_contraloc:premium-yearly';

  // Mapping complet des identifiants
  static final Map<String, String> subscriptionIdMapping = {
    // iOS Mappings
    'PremiumMonthlySubscription': 'premium-monthly_access',
    'PremiumYearlySubscription': 'premium-yearly_access',
    'PlatinumMonthlySubscription': 'platinum-monthly_access',
    'PlatinumYearlySubscription': 'platinum-yearly_access',
    
    // Android Mappings
    'offre_contraloc:premium-monthly': 'premium-monthly_access',
    'offre_contraloc:premium-yearly': 'premium-yearly_access',
    'offre_contraloc:platinum-monthly': 'platinum-monthly_access',
    'offre_contraloc:platinum-yearly': 'platinum-yearly_access',
  };

  // Méthode de mapping générique
  static String mapSubscriptionId(String originalId) {
    return subscriptionIdMapping[originalId] ?? originalId;
  }

  // Méthode pour obtenir l'ID de produit correct
  static String getProductId(String plan, bool isMonthly) {
    print(' Sélection du produit :');
    print('   Plan: $plan');
    print('   Durée: ${isMonthly ? "Mensuelle" : "Annuelle"}');

    if (Platform.isAndroid) {
      if (plan.contains("Premium")) {
        return isMonthly 
          ? _premiumMonthlyAndroid 
          : _premiumYearlyAndroid;
      } else if (plan.contains("Platinum")) {
        return isMonthly 
          ? _platinumMonthlyAndroid 
          : _platinumYearlyAndroid;
      }
    } else {
      if (plan.contains("Premium")) {
        return isMonthly 
          ? _premiumMonthlyIOS 
          : _premiumYearlyIOS;
      } else if (plan.contains("Platinum")) {
        return isMonthly 
          ? _platinumMonthlyIOS 
          : _platinumYearlyIOS;
      }
    }

    print(' Aucun produit trouvé pour le plan: $plan');
    return 'free';
  }

  // Méthode de débogage pour lister les produits
  static Future<void> debugListProducts() async {
    try {
      print(' Débogage des produits disponibles');
      
      // Liste de tous les IDs de produits
      final allProductIds = [
        _platinumMonthlyIOS, _platinumYearlyIOS, 
        _premiumMonthlyIOS, _premiumYearlyIOS,
        _platinumMonthlyAndroid, _platinumYearlyAndroid,
        _premiumMonthlyAndroid, _premiumYearlyAndroid
      ];

      print(' IDs de produits recherchés : $allProductIds');
      
      final products = await Purchases.getProducts(allProductIds);
      
      if (products.isEmpty) {
        print(' Aucun produit trouvé !');
        return;
      }

      print(' Nombre de produits trouvés : ${products.length}');
      
      for (var product in products) {
        print(' Identifiant: ${product.identifier}');
        print(' Prix: ${product.price}');
        print(' Description: ${product.description}');
        print(' Mapped Entitlement: ${mapSubscriptionId(product.identifier)}');
        print('---');
      }

      // Vérification des offres
      final offerings = await Purchases.getOfferings();
      print(' Offerings disponibles : ${offerings.all.keys}');
      
      offerings.all.forEach((key, offering) {
        print('- Offering: $key');
        offering.availablePackages.forEach((package) {
          print('  Package: ${package.identifier}');
          print('  Product ID: ${package.storeProduct.identifier}');
        });
      });

    } catch (e) {
      print(' Erreur lors de la récupération des produits : $e');
    }
  }

  // Méthode inverse pour obtenir l'ID original
  static String? getOriginalId(String mappedId) {
    return subscriptionIdMapping.keys.firstWhere(
      (key) => subscriptionIdMapping[key] == mappedId, 
      orElse: () => mappedId
    );
  }

  // Getters pour obtenir le bon ID selon la plateforme
  static String get entitlementPlatinumMonthly {
    if (Platform.isIOS) return mapSubscriptionId(_platinumMonthlyIOS);
    return mapSubscriptionId(_platinumMonthlyAndroid);
  }

  static String get entitlementPlatinumYearly {
    if (Platform.isIOS) return mapSubscriptionId(_platinumYearlyIOS);
    return mapSubscriptionId(_platinumYearlyAndroid);
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
  static const String PACKAGE_PLATINUM_YEARLY = 'platinum_yearly';
  static const String PACKAGE_PLATINUM_MONTHLY = 'platinum_monthly';

  // Identifiants des produits par plateforme
  static final Map<String, String> productIds = {
    // iOS Products
    'ios_platinum_monthly': _platinumMonthlyIOS,
    'ios_platinum_yearly': _platinumYearlyIOS,
    'ios_premium_monthly': _premiumMonthlyIOS,
    'ios_premium_yearly': _premiumYearlyIOS,
    
    // Android Products
    'android_platinum_monthly': _platinumMonthlyAndroid,
    'android_platinum_yearly': _platinumYearlyAndroid,
    'android_premium_monthly': _premiumMonthlyAndroid,
    'android_premium_yearly': _premiumYearlyAndroid,
  };

  static bool _isInitialized = false;

  static Future<void> initialize({
    required String androidApiKey,
    required String iosApiKey,
  }) async {
    if (_isInitialized) {
      print(' RevenueCat déjà initialisé');
      return;
    }

    try {
      await Purchases.setLogLevel(LogLevel.verbose);
      
      // Configuration par plateforme
      if (Platform.isAndroid) {
        await Purchases.configure(
          PurchasesConfiguration(androidApiKey)
        );
      } else if (Platform.isIOS) {
        await Purchases.configure(
          PurchasesConfiguration(iosApiKey)
        );
      }
      
      _isInitialized = true;
      print(' RevenueCat initialisé avec succès');
    } catch (e) {
      print(' ❌ Erreur lors de l\'initialisation de RevenueCat: $e');
      rethrow;
    }
  }

  /// Réinitialise l'état d'initialisation de RevenueCat
  /// À appeler après une déconnexion complète
  static void resetInitializationState() {
    _isInitialized = false;
    print(' RevenueCat état d\'initialisation réinitialisé');
  }

  static Future<void> ensureInitialized() async {
    if (!_isInitialized) {
      throw Exception('RevenueCat n\'est pas initialisé. Appelez initialize() d\'abord.');
    }
  }

  static Future<void> login(String userId) async {
    await ensureInitialized();
    try {
      await Purchases.logIn(userId);
      print(' RevenueCat login réussi pour: $userId');
    } catch (e) {
      print(' Erreur RevenueCat login: $e');
      rethrow;
    }
  }

  static Future<void> logout() async {
    await ensureInitialized();
    try {
      await Purchases.logOut();
      print(' RevenueCat logout réussi');
    } catch (e) {
      print(' Erreur RevenueCat logout: $e');
      rethrow;
    }
  }

  static Future<CustomerInfo?> checkEntitlements() async {
    await ensureInitialized();
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      final activeEntitlements = customerInfo.entitlements.active.keys;

      print(' État RevenueCat: ${activeEntitlements.length} abonnement(s) actif(s)');
      print(' Entitlements actifs: $activeEntitlements');

      // Si plusieurs abonnements sont actifs, prioriser Platinum sur Premium
      if (activeEntitlements.length > 1) {
        // Créer une copie de customerInfo avec uniquement l'abonnement prioritaire
        if (hasPlatinumAccess(customerInfo)) {
          // Garder uniquement l'abonnement Platinum
          customerInfo.entitlements.active.removeWhere(
            (key, _) => !key.contains('platinum'),
          );
        } else if (hasPremiumAccess(customerInfo)) {
          // Garder uniquement l'abonnement Premium
          customerInfo.entitlements.active.removeWhere(
            (key, _) => !key.contains('premium'),
          );
        }
        print(' Après priorisation: ${customerInfo.entitlements.active.keys}');
      }

      return customerInfo;
    } catch (e) {
      print(' Erreur vérification entitlements: $e');
      return null;
    }
  }

  static bool hasPlatinumAccess(CustomerInfo customerInfo) {
    return customerInfo.entitlements.active.keys
      .map(mapSubscriptionId)
      .any((id) => id.contains('platinum-'));
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
    await ensureInitialized();
    try {
      // Obtenir l'ID de produit correct
      final productId = getProductId(plan, isMonthly);
      
      print(' Détails de l\'achat :');
      print('   Plan: $plan');
      print('   Durée: ${isMonthly ? "Mensuel" : "Annuel"}');
      print('   ID Produit: $productId');
      print('   ID Entitlement: ${mapSubscriptionId(productId)}');

      // Récupérer les offres
      final offerings = await Purchases.getOfferings();
      
      // Trouver le package correspondant
      Package? package;
      for (var offering in offerings.all.values) {
        try {
          package = offering.availablePackages.firstWhere(
            (pkg) => pkg.storeProduct.identifier == productId
          );
          break;
        } catch (e) {
          // Aucun package correspondant dans cet offering
          print(' Aucun package trouvé dans cet offering');
          continue;
        }
      }

      if (package == null) {
        print(' Aucun package trouvé pour l\'ID : $productId');
        throw Exception('Package non trouvé');
      }

      // Effectuer l'achat avec le package non nullable
      final customerInfo = await Purchases.purchasePackage(package);
      
      print(' Achat réussi');
      print(' Entitlements actifs: ${customerInfo.entitlements.active.keys}');
      
      return customerInfo;
    } on PlatformException catch (e) {
      // Gestion spécifique de l'annulation par l'utilisateur
      if (e.details?['userCancelled'] == true) {
        print(' Achat annulé par l\'utilisateur');
        return null;
      }

      // Autres erreurs de plateforme
      print(' Erreur de plateforme lors de l\'achat : ${e.message}');
      print('   Code d\'erreur: ${e.code}');
      print('   Détails: ${e.details}');
      
      rethrow;
    } catch (e) {
      // Gestion des autres types d'erreurs
      print(' Erreur lors de l\'achat : $e');
      rethrow;
    }
  }

  static Future<CustomerInfo?> processSubscription(
    BuildContext context, {
    required String plan,
    required bool isMonthly,
  }) async {
    await ensureInitialized();
    try {
      // Afficher le dialogue de chargement personnalisé
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) => const Chargement(),
      );

      // Effectuer l'achat de l'abonnement
      final customerInfo = await purchaseProduct(plan, isMonthly);

      // Fermer le dialogue de chargement
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
      // Fermer le dialogue de chargement en cas d'erreur
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
