import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:ContraLoc/widget/chargement.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ContraLoc/USERS/Subscription/stripe_service.dart';

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

  /// Force la réinitialisation de RevenueCat, même si déjà initialisé
  /// Utile lors de la reconnexion après déconnexion
  static Future<void> forceReInitialize() async {
    try {
      _isInitialized = false; // Force la réinitialisation
      
      // Récupérer les clés API depuis Firestore
      final apiKeys = await _fetchRevenueCatKeys();
      
      // Réinitialiser RevenueCat
      await initialize(
        androidApiKey: apiKeys['android']!,
        iosApiKey: apiKeys['ios']!,
      );
      
      print(' RevenueCat réinitialisé avec succès');
    } catch (e) {
      print(' Erreur lors de la réinitialisation de RevenueCat: $e');
      throw Exception('Impossible de réinitialiser RevenueCat: $e');
    }
  }

  /// Vérifie si RevenueCat est initialisé, sinon lance une exception
  static Future<void> ensureInitialized() async {
    if (!_isInitialized) {
      throw Exception('RevenueCat n\'est pas initialisé. Appelez initialize() d\'abord.');
    }
  }

  static Future<void> login(String userId) async {
    try {
      // Vérifier si RevenueCat est initialisé, sinon le réinitialiser
      if (!_isInitialized) {
        print(' RevenueCat n\'est pas initialisé, tentative de réinitialisation...');
        await forceReInitialize();
      }
      
      // Connecter l'utilisateur
      await Purchases.logIn(userId);
      print(' RevenueCat login réussi pour: $userId');
    } catch (e) {
      print(' Erreur RevenueCat login: $e');
      // Ne pas relancer certaines erreurs non critiques pour éviter de bloquer l'application
      if (e.toString().contains('RevenueCat n\'est pas initialisé')) {
        print(' Tentative de réinitialisation forcée de RevenueCat...');
        try {
          await forceReInitialize();
          await Purchases.logIn(userId);
          print(' RevenueCat login réussi après réinitialisation forcée pour: $userId');
        } catch (reinitError) {
          print(' Erreur lors de la réinitialisation forcée: $reinitError');
          // Ne pas bloquer la connexion même si RevenueCat échoue
        }
      } else if (!e.toString().contains('already logged in')) {
        // Relancer les erreurs qui ne sont pas des erreurs de "déjà connecté"
        rethrow;
      }
    }
  }
  
  // Méthode privée pour récupérer les clés API RevenueCat
  static Future<Map<String, String>> _fetchRevenueCatKeys() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('api_keys')
          .doc('revenuecat')
          .get();

      final data = snapshot.data();
      if (data == null) throw Exception('Clés API RevenueCat introuvables.');

      return {
        'android': data['android_api_key'] ?? '',
        'ios': data['ios_api_key'] ?? '',
      };
    } catch (e) {
      print(' Erreur lors de la récupération des clés RevenueCat: $e');
      throw Exception('Impossible de récupérer les clés RevenueCat: $e');
    }
  }

  static Future<void> logout() async {
    try {
      // Si RevenueCat n'est pas initialisé, on ne peut pas faire de logout
      // mais on peut quand même réinitialiser l'état
      if (!_isInitialized) {
        resetInitializationState();
        print(' RevenueCat état réinitialisé (déjà non initialisé)');
        return;
      }
      
      // Déconnecter l'utilisateur de RevenueCat
      await Purchases.logOut();
      
      // Réinitialiser l'état pour la prochaine connexion
      resetInitializationState();
      
      print(' RevenueCat logout réussi');
    } catch (e) {
      print(' Erreur RevenueCat logout: $e');
      // Réinitialiser l'état même en cas d'erreur
      resetInitializationState();
      // Ne pas relancer l'erreur pour éviter de bloquer la déconnexion
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
      
      // Mettre à jour Firestore avec les détails de l'abonnement
      final userId = await Purchases.appUserID;
      if (userId.isNotEmpty) {
        await updateFirebaseFromRevenueCat(userId, customerInfo);
      }
      
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

  /// Ouvre les paramètres d'abonnement de l'appareil
  static Future<void> openSubscriptionManagementScreen() async {
    try {
      // Récupérer les informations du client
      final customerInfo = await Purchases.getCustomerInfo();
      
      // Vérifier si l'URL de gestion est disponible
      final managementURL = customerInfo.managementURL;
      
      if (managementURL != null && managementURL.isNotEmpty) {
        // Ouvrir l'URL de gestion dans le navigateur
        if (await canLaunch(managementURL)) {
          await launch(managementURL);
          print('📊 URL de gestion des abonnements ouverte: $managementURL');
        } else {
          print('❌ Impossible d\'ouvrir l\'URL de gestion: $managementURL');
        }
      } else {
        print('❌ Aucune URL de gestion disponible');
      }
    } catch (e) {
      print('❌ Erreur lors de l\'ouverture des paramètres d\'abonnement: $e');
    }
  }

  // Méthode pour effectuer un paiement par carte bancaire via Stripe
  static Future<CustomerInfo?> purchaseProductWithStripe(
    String plan, 
    bool isMonthly,
    BuildContext context
  ) async {
    try {
      // Afficher le dialogue de chargement
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) => const Chargement(),
      );

      // Obtenir l'utilisateur actuel
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Utilisateur non connecté');
      }

      // Déterminer l'ID du produit Stripe en fonction du plan
      String productId;
      if (plan.contains("Premium")) {
        productId = isMonthly ? 'prod_RiIVqYAhJGzB0u' : 'prod_RiIXsD22K4xehY';
      } else { // Platinum
        productId = isMonthly ? 'prod_S26yXish2BNayF' : 'prod_S26xbnrxhZn6TT';
      }

      print('🔄 Création du client Stripe...');
      // Créer ou récupérer le client Stripe
      final customerId = await StripeService.createCustomer(user.email ?? '', user.displayName ?? 'Utilisateur');
      if (customerId == null) {
        throw Exception('Impossible de créer le client Stripe');
      }

      print('🔄 Création de la session de paiement...');
      // URLs de redirection
      final successUrl = 'https://contraloc.com/success';
      final cancelUrl = 'https://contraloc.com/cancel';

      // Créer la session de paiement
      final sessionUrl = await StripeService.createSubscriptionCheckoutSession(
        customerId,
        productId,
        successUrl,
        cancelUrl,
      );

      if (sessionUrl == null) {
        throw Exception('Impossible de créer la session de paiement');
      }

      // Fermer le dialogue de chargement
      Navigator.of(context).pop();

      print('🔄 Ouverture de l\'URL de paiement: $sessionUrl');
      // Ouvrir l'URL de paiement dans le navigateur
      final Uri url = Uri.parse(sessionUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Impossible d\'ouvrir l\'URL de paiement');
      }

      // Comme le paiement se fait dans un navigateur externe, nous ne pouvons pas
      // savoir immédiatement si le paiement a réussi. Nous retournons null pour l'instant.
      // La mise à jour du statut de l'abonnement sera gérée par le webhook Stripe.
      return null;
    } catch (e) {
      print('❌ Erreur lors du paiement par carte bancaire: $e');
      // Fermer le dialogue de chargement s'il est ouvert
      Navigator.of(context).pop();
      rethrow;
    }
  }

  // Mettre à jour Firestore avec les informations de RevenueCat
  static Future<void> updateFirebaseFromRevenueCat(String userId, CustomerInfo customerInfo) async {
    try {
      // Déterminer le type d'abonnement et le nombre de véhicules
      String planType = 'free';
      int numberOfCars = 1;
      
      // Vérifier si l'utilisateur a un abonnement Platinum
      if (hasPlatinumAccess(customerInfo)) {
        planType = isYearlyPlan(customerInfo) ? 'platinum-yearly_access' : 'platinum-monthly_access';
        numberOfCars = 20;
      }
      // Sinon, vérifier si l'utilisateur a un abonnement Premium
      else if (hasPremiumAccess(customerInfo)) {
        planType = isYearlyPlan(customerInfo) ? 'premium-yearly_access' : 'premium-monthly_access';
        numberOfCars = 10;
      }
      
      // Mettre à jour Firestore
      await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('authentification')
        .doc(userId)
        .set({
          'subscriptionId': planType,
          'isSubscriptionActive': true,
          'numberOfCars': numberOfCars,
          'stripeSubscriptionId': '',  // Pas de Stripe ID pour RevenueCat
          'stripeStatus': 'active',    // On considère comme actif
          'subscriptionSource': 'revenueCat',  // Identifier la source comme RevenueCat
          'lastUpdateDate': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      
      print(' Firebase mis à jour avec succès depuis RevenueCat');
    } catch (e) {
      print(' Erreur mise à jour Firebase depuis RevenueCat: $e');
      throw e;
    }
  }
}
