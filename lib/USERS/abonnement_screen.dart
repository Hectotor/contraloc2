import 'package:ContraLoc/USERS/felicitation.dart';
import 'package:ContraLoc/services/subscription_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart'; // Import RevenueCat
import 'package:purchases_flutter/models/entitlement_info_wrapper.dart'; // Import Entitlement
import 'package:ContraLoc/USERS/question_user.dart';
import 'package:ContraLoc/USERS/plan_display.dart';
import 'package:url_launcher/url_launcher.dart'; // Import url_launcher
import 'dart:io'; // Import dart:io for Platform
import 'dart:async'; // Import StreamSubscription

class AbonnementScreen extends StatefulWidget {
  const AbonnementScreen({Key? key}) : super(key: key);
  @override
  State<AbonnementScreen> createState() => _AbonnementScreenState();
}

String _getPlanDisplayName(String subscriptionId) {
  print('🔍 Getting plan name for subscriptionId: $subscriptionId');

  // Normaliser l'ID d'abonnement pour gérer tous les formats possibles
  String normalizedId = subscriptionId
      .toLowerCase()
      .replaceAll('subscription', '')
      .replaceAll('_', '-')
      .trim();

  // Faire correspondre exactement les IDs avec les noms d'affichage
  Map<String, String> planNames = {
    'promonthly': 'Offre Pro',
    'proyearly': 'Offre Pro Annuel',
    'premiummonthly': 'Offre Premium',
    'premiumyearly': 'Offre Premium Annuel',
    'pro-monthly': 'Offre Pro',
    'pro-yearly': 'Offre Pro Annuel',
    'premium-monthly': 'Offre Premium',
    'premium-yearly': 'Offre Premium Annuel',
    'free': 'Offre Gratuite'
  };

  String planName = planNames[normalizedId] ?? 'Offre Gratuite';
  print('- Normalized ID: $normalizedId');
  print('- Resolved plan name: $planName');
  return planName;
}

// Mappage des identifiants d'abonnement (standardisé)
const Map<String, String> subscriptionIdMappingIOS = {
  'ProMonthlySubscription': 'pro-monthly',
  'ProYearlySubscription': 'pro-yearly',
  'PremiumMonthlySubscription': 'premium-monthly',
  'PremiumYearlySubscription': 'premium-yearly',
};

const Map<String, String> subscriptionIdMappingAndroid = {
  'offre_contraloc:pro-monthly': 'pro-monthly',
  'offre_contraloc:pro-yearly': 'pro-yearly',
  'offre_contraloc:premium-monthly': 'premium-monthly',
  'offre_contraloc:premium-yearly': 'premium-yearly',
};

// Fonction pour obtenir l'identifiant mappé
String getMappedSubscriptionId(String originalId) {
  if (Platform.isIOS) {
    return subscriptionIdMappingIOS[originalId] ?? originalId;
  } else if (Platform.isAndroid) {
    return subscriptionIdMappingAndroid[originalId] ?? originalId;
  }
  return originalId;
}

class _AbonnementScreenState extends State<AbonnementScreen> {
  int numberOfCars = 1;
  int limiteContrat = 10;
  bool isSubscriptionActive = false;
  String subscriptionId = 'free';
  int _currentIndex = 0;
  bool isMonthly = true;
  bool _isLoading = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription? _subscriptionStream; // Add this line
  String? lastSyncDate;

  // Ajouter une constante pour les délais
  static const Duration _timeoutDuration = Duration(seconds: 30);

  void _showLoading(bool show) {
    setState(() {
      _isLoading = show;
    });
  }

  @override
  void initState() {
    super.initState();
    SubscriptionService.checkAndUpdateSubscription();
    _setupListeners();
  }

  void _setupListeners() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Écouter les changements Firestore
    _subscriptionStream = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('authentification')
        .doc(user.uid)
        .snapshots()
        .listen(_updateStateFromFirestore);

    // Écouter les changements RevenueCat
    Purchases.addCustomerInfoUpdateListener(_handleRevenueCatUpdate);
  }

  void _updateStateFromFirestore(DocumentSnapshot snapshot) {
    if (!mounted || !snapshot.exists) return;

    final data = snapshot.data() as Map<String, dynamic>;
    final newLastSyncDate = data['lastSyncDate']?.toString();
    final newSubscriptionId = data['subscriptionId'] ?? 'free';

    print('📱 État Firestore reçu:');
    print('- subscriptionId: $newSubscriptionId');
    print('- lastSyncDate: $newLastSyncDate');
    print('- isActive: ${data['isSubscriptionActive']}');

    setState(() {
      subscriptionId = newSubscriptionId;
      lastSyncDate = newLastSyncDate;
      isSubscriptionActive = data['isSubscriptionActive'] ?? false;
      numberOfCars = data['numberOfCars'] ?? 1;
      limiteContrat = data['limiteContrat'] ?? 10;
      isMonthly = (data['subscriptionType'] ?? 'monthly') == 'monthly';
    });
  }

  void _handleRevenueCatUpdate(CustomerInfo customerInfo) async {
    if (!mounted) return;

    try {
      final activeEntitlements = customerInfo.entitlements.active;

      // Éviter les mises à jour trop rapides
      if (activeEntitlements.isEmpty) {
        // Attendre un peu avant de confirmer qu'il n'y a vraiment pas d'abonnement
        await Future.delayed(const Duration(seconds: 2));
        final recheck = await Purchases.getCustomerInfo();
        if (recheck.entitlements.active.isNotEmpty) {
          return; // Annuler la mise à jour si un abonnement est trouvé
        }
      }

      print('🔄 Mise à jour RevenueCat reçue');

      // Obtenir l'état actuel de Firestore
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final userDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('authentification')
          .doc(user.uid)
          .get();

      final currentSubscriptionId = userDoc.data()?['subscriptionId'] ?? 'free';

      if (activeEntitlements.isEmpty) {
        print('ℹ️ Aucun abonnement actif dans RevenueCat');
        if (currentSubscriptionId != 'free') {
          await _updateSubscriptionInFirestore('free', false);
        }
        return;
      }

      // Trouver l'abonnement le plus récent
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
        final mappedId =
            getMappedSubscriptionId(latestEntitlement.productIdentifier);
        print('📦 Dernier abonnement actif: $mappedId');

        if (mappedId != currentSubscriptionId) {
          print('🔄 Mise à jour Firestore nécessaire');
          await _updateSubscriptionInFirestore(mappedId, true);
        }
      } else {
        // Si aucun abonnement actif n'est trouvé, mettre à jour Firebase pour refléter l'expiration
        await _updateSubscriptionInFirestore('free', false);
      }
    } catch (e) {
      print('❌ Erreur lors de la mise à jour RevenueCat: $e');
    }
  }

  @override
  void dispose() {
    _subscriptionStream?.cancel();
    Purchases.removeCustomerInfoUpdateListener(_handleRevenueCatUpdate);
    super.dispose();
  }

  // Removed unused _initializeSubscription method

  Future<void> _updateSubscriptionInFirestore(
      String subscriptionId, bool isActive) async {
    // Ajouter une vérification de connexion
    if (!mounted) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final data = {
        'subscriptionId': getMappedSubscriptionId(subscriptionId),
        'isSubscriptionActive': isActive,
        'numberOfCars': subscriptionId.contains('premium-')
            ? 999
            : (subscriptionId.contains('pro-') ? 5 : 1),
        'limiteContrat': subscriptionId.contains('premium-') ? 999 : 10,
        'subscriptionType': subscriptionId.toLowerCase().contains('yearly')
            ? 'yearly'
            : 'monthly',
        'lastUpdateDate': FieldValue.serverTimestamp(),
        'planName': _getPlanDisplayName(subscriptionId), // Ajout important ici
      };

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('authentification')
          .doc(user.uid)
          .update(data);

      // Mettre à jour l'état local immédiatement
      setState(() {
        this.subscriptionId = getMappedSubscriptionId(subscriptionId);
        isSubscriptionActive = isActive;
      });
    } catch (e) {
      print('❌ Erreur mise à jour Firestore: $e');
      // Ajouter une réessai automatique
      await Future.delayed(const Duration(seconds: 2));
      return _updateSubscriptionInFirestore(subscriptionId, isActive);
    }
  }

  Future<void> _handleSubscription(String plan) async {
    _lastAttemptedPurchase =
        plan; // Ajouter cette ligne pour mémoriser la dernière tentative
    _showLoading(true);

    try {
      // Ajouter un timeout
      return await Future.any([
        _processSubscription(plan),
        Future.delayed(_timeoutDuration)
            .then((_) => throw Exception('Délai d\'attente dépassé')),
      ]);
    } catch (e) {
      // ...existing error handling...
    }
  }

  Future<void> _processSubscription(String plan) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showLoading(false);
      return;
    }

    try {
      if (plan == "Offre Gratuite") return;

      print('🔄 Début du processus d\'abonnement pour: $plan');

      // 1. Obtenir les offres RevenueCat
      final offerings = await Purchases.getOfferings();
      if (offerings.current == null) {
        throw Exception('Aucune offre disponible');
      }

      // 2. Déterminer l'ID du produit
      String productId = _getProductId(plan, isMonthly);
      print('🎯 ID Produit recherché: $productId');
      print('📅 Type abonnement: ${isMonthly ? "Mensuel" : "Annuel"}');

      // Debug des packages disponibles
      print('📦 Packages disponibles:');
      offerings.current!.availablePackages.forEach((pkg) {
        print('- ${pkg.storeProduct.identifier}');
      });

      // 3. Trouver le package
      final package = offerings.current!.availablePackages.firstWhere(
        (pkg) => pkg.storeProduct.identifier == productId,
        orElse: () {
          print('❌ Package non trouvé pour ID: $productId');
          throw Exception('Package non trouvé');
        },
      );

      // 4. Effectuer l'achat
      print(
          '💳 Tentative d\'achat du package: ${package.storeProduct.identifier}');
      final purchaseResult = await Purchases.purchasePackage(package);

      // 5. Vérifier et mettre à jour Firestore
      if (purchaseResult.entitlements.active.isNotEmpty) {
        print('✅ Achat réussi! Mise à jour Firestore...');

        // Préparer les données de mise à jour
        final updateData = {
          'subscriptionId': productId,
          'isSubscriptionActive': true,
          'planName': plan,
          'purchaseDate': FieldValue.serverTimestamp(),
        };

        print('📝 Données à mettre à jour: $updateData');

        // Mise à jour Firestore avec retry
        bool updated = false;
        int attempts = 0;
        while (!updated && attempts < 3) {
          try {
            await _firestore
                .collection('users')
                .doc(user.uid)
                .collection('authentification')
                .doc(user.uid)
                .update(updateData);
            updated = true;
            print('✅ Mise à jour Firestore réussie!');
          } catch (e) {
            attempts++;
            print('❌ Tentative $attempts échouée: $e');
            await Future.delayed(const Duration(seconds: 1));
          }
        }

        if (!updated) {
          throw Exception(
              'Échec de la mise à jour Firestore après 3 tentatives');
        }

        // Mettre à jour l'état local
        setState(() {
          subscriptionId = productId;
          isSubscriptionActive = true;
          _isLoading = false;
        });

        // Afficher uniquement le popup de confirmation
        _showActivationPopup();

        // Call the new method to update Firebase upon successful purchase
        await SubscriptionService.updateFirebaseUponPurchase(productId);
      } else {
        throw Exception('Échec de l\'activation de l\'abonnement');
      }
    } catch (e) {
      print('❌ ERREUR PROCESSUS: $e');
      _showLoading(false);

      // Vérifier si c'est une annulation volontaire
      if (e is PlatformException &&
          e.code == '1' &&
          e.details?['userCancelled'] == true) {
        _showMessage(
          'Achat annulé',
          Colors.orange, // Couleur orange pour une annulation
        );
        return; // Sort de la fonction sans autre traitement
      }

      // Pour les autres erreurs
      _showMessage(
          'Erreur lors de l\'activation. Veuillez réessayer.', Colors.red);
    }
  }

  // Ajouter cette nouvelle méthode
  void _showActivationPopup() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => const FelicitationDialog(),
    );
  }

  // Removed unused _buildActivationDialog method

  String _getProductId(String plan, bool isMonthly) {
    // Déterminer d'abord l'ID standardisé
    String standardId;
    if (plan.contains("Premium")) {
      standardId = isMonthly ? 'premium-monthly' : 'premium-yearly';
    } else if (plan.contains("Pro")) {
      standardId = isMonthly ? 'pro-monthly' : 'pro-yearly';
    } else {
      return 'free';
    }

    // Convertir vers le format spécifique à la plateforme
    if (Platform.isIOS) {
      // Conversion vers format iOS
      return '${standardId.split('-').map((part) => part.substring(0, 1).toUpperCase() + part.substring(1)).join('').replaceAll('-', '')}Subscription';
    } else {
      // Pour Android, ajouter le préfixe offre_contraloc:
      return 'offre_contraloc:$standardId';
    }
  }

  void _showMessage(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
        action: message.contains('Erreur')
            ? SnackBarAction(
                label: 'Réessayer',
                textColor: Colors.white,
                onPressed: () => _retryLastPurchase(),
              )
            : null,
      ),
    );
  }

  String? _lastAttemptedPurchase;
  void _retryLastPurchase() {
    if (_lastAttemptedPurchase != null) {
      _handleSubscription(_lastAttemptedPurchase!);
    }
  }

  Future<void> _openManageSubscription() async {
    String url;
    if (Platform.isIOS) {
      url = 'https://apps.apple.com/account/subscriptions';
    } else if (Platform.isAndroid) {
      url = 'https://play.google.com/store/account/subscriptions';
    } else {
      // Handle other platforms or show an error message
      throw 'Platform not supported';
    }
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    print('🏗️ Construction avec subscriptionId: $subscriptionId');

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Mon abonnement",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: const Color(0xFF08004D),
      ),
      backgroundColor: Colors.grey[50],
      body: Stack(
        children: [
          Column(
            children: [
              const SizedBox(height: 15), // Réduit de 25 à 15
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    _buildToggleButton(true, "Mensuel", Icons.calendar_today),
                    _buildToggleButton(false, "Annuel", Icons.calendar_month),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(
                    vertical: 5, horizontal: 20), // Réduit de 10 à 5
                child: Text(
                  "Nos prix sont sans engagement",
                  style: TextStyle(
                    color: Color(0xFF08004D),
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              Expanded(
                child: PlanDisplay(
                  isMonthly: isMonthly,
                  currentSubscriptionName: _getPlanDisplayName(subscriptionId),
                  subscriptionId: subscriptionId,
                  lastSyncDate: lastSyncDate, // Ajouter ce paramètre
                  onSubscribe: _handleSubscription,
                  onPageChanged: (index) =>
                      setState(() => _currentIndex = index),
                  currentIndex: _currentIndex,
                ),
              ),
              if (subscriptionId != 'free')
                ElevatedButton(
                  onPressed: _isLoading ? null : _openManageSubscription,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Colors.white, // Set background color to white
                    foregroundColor: const Color(
                        0xFF08004D), // Set text color to match the theme
                  ),
                  child: const Text('Gérer mon abonnement'),
                ),
              _buildContactButton(),
              const SizedBox(height: 30),
            ],
          ),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Traitement en cours...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildToggleButton(bool isMonthlyButton, String text, IconData icon) {
    final bool isSelected = isMonthly == isMonthlyButton;
    return Expanded(
      child: GestureDetector(
        onTap: _isLoading
            ? null
            : () => setState(() => isMonthly = isMonthlyButton),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF08004D) : Colors.white,
            borderRadius: BorderRadius.horizontal(
              left: Radius.circular(isMonthlyButton ? 12 : 0),
              right: Radius.circular(!isMonthlyButton ? 12 : 0),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 20, color: isSelected ? Colors.white : Colors.grey),
              const SizedBox(width: 8),
              Text(
                text,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactButton() {
    return TextButton.icon(
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const QuestionUser()),
      ),
      icon: const Icon(
        Icons.help_outline,
        color: Color(0xFF08004D),
        size: 24,
      ),
      label: const Text(
        "Des questions ? Contactez-nous",
        style: TextStyle(
          color: Color(0xFF08004D),
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
