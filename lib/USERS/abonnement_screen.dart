import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart'; // Import RevenueCat
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
  switch (subscriptionId) {
    case 'ProMonthlySubscription':
      return 'Offre Pro';
    case 'ProYearlySubscription':
      return 'Offre Pro Annuel';
    case 'PremiumMonthlySubscription':
      return 'Offre Premium';
    case 'PremiumYearlySubscription':
      return 'Offre Premium Annuel';
    default:
      return 'Offre Gratuite';
  }
}

// Mappage des identifiants d'abonnement
const Map<String, String> subscriptionIdMapping = {
  'ProMonthlySubscription': 'pro-monthly',
  'ProYearlySubscription': 'pro-yearly',
  'PremiumMonthlySubscription': 'premium-monthly',
  'PremiumYearlySubscription': 'premium-yearly',
};

// Fonction pour obtenir l'identifiant mappé
String getMappedSubscriptionId(String originalId) {
  return subscriptionIdMapping[originalId] ?? originalId;
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
    _initializeSubscription();
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
    setState(() {
      subscriptionId = data['subscriptionId'] ?? 'free';
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
// Si l'utilisateur n'a aucun abonnement actif
      if (activeEntitlements.isEmpty) {
        // Mettre à jour Firestore pour indiquer que l'utilisateur n'a pas d'abonnement actif
        await _updateSubscriptionInFirestore('free', false);
        // Retourner immédiatement
        return;
      }

      final latestEntitlement = activeEntitlements.values.reduce((a, b) {
        final aDate = DateTime.parse(a.latestPurchaseDate);
        final bDate = DateTime.parse(b.latestPurchaseDate);
        return aDate.isAfter(bDate) ? a : b;
      });

      await _updateSubscriptionInFirestore(
        getMappedSubscriptionId(latestEntitlement.productIdentifier),
        true,
      );
    } catch (e) {
      print('❌ Erreur mise à jour RevenueCat: $e');
    }
  }

  @override
  void dispose() {
    _subscriptionStream?.cancel();
    Purchases.removeCustomerInfoUpdateListener(_handleRevenueCatUpdate);
    super.dispose();
  }

  Future<void> _initializeSubscription() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final customerInfo = await Purchases.getCustomerInfo();
      print('🔍 État RevenueCat initial:');
      print('Abonnements: ${customerInfo.activeSubscriptions}');
      print('Entitlements: ${customerInfo.entitlements.all}');

      final activeEntitlements = customerInfo.entitlements.active;
      if (activeEntitlements.isEmpty) {
        print('ℹ️ Aucun abonnement actif trouvé.');
        return;
      }

      var latestEntitlement = activeEntitlements.values.reduce((a, b) {
        final aDate = DateTime.parse(a.latestPurchaseDate);
        final bDate = DateTime.parse(b.latestPurchaseDate);
        return aDate.isAfter(bDate) ? a : b;
      });

      if (!latestEntitlement.isActive) return;

      final currentSubscriptionId = latestEntitlement.productIdentifier;
      await _updateSubscriptionInFirestore(currentSubscriptionId, true);

      setState(() {
        subscriptionId = currentSubscriptionId;
        isSubscriptionActive = true;
        isMonthly = !currentSubscriptionId.toLowerCase().contains('yearly');
      });

      print('🎉 Mise à jour de l\'abonnement terminée.');
    } catch (e) {
      print('❌ Erreur initialisation: $e');
      _showMessage('Erreur lors de l\'initialisation', Colors.red);
    }
  }

  Future<void> _updateSubscriptionInFirestore(
      String subscriptionId, bool isActive) async {
    // Ajouter une vérification de connexion
    if (!mounted) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('authentification')
          .doc(user.uid)
          .update({
        'subscriptionId': getMappedSubscriptionId(subscriptionId),
        'isSubscriptionActive': isActive,
        'numberOfCars': subscriptionId.contains('Premium')
            ? 999
            : (subscriptionId.contains('Pro') ? 5 : 1),
        'limiteContrat': subscriptionId.contains('Premium') ? 999 : 10,
        'subscriptionType': subscriptionId.toLowerCase().contains('yearly')
            ? 'yearly'
            : 'monthly',
        'lastUpdateDate': FieldValue.serverTimestamp(),
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

      // 1. Vérifier l'abonnement actuel
      final currentInfo = await Purchases.getCustomerInfo();
      String productId = _getProductId(plan, isMonthly);

      print('📱 État actuel: ${currentInfo.activeSubscriptions}');
      print('🎯 Changement vers: $productId');

      // 2. Obtenir les offres
      final offerings = await Purchases.getOfferings();
      if (offerings.current == null) {
        throw Exception('Aucune offre disponible');
      }

      // Log available packages
      print('🔍 Available Packages:');
      for (var pkg in offerings.current!.availablePackages) {
        print('Package ID: ${pkg.storeProduct.identifier}');
      }

      // 3. Trouver le package
      final package = offerings.current!.availablePackages.firstWhere(
        (pkg) => pkg.storeProduct.identifier == productId,
        orElse: () {
          print('❌ Package with ID $productId not found.');
          throw Exception('Package non trouvé');
        },
      );

      // 4. Désactiver l'ancien abonnement
      if (currentInfo.activeSubscriptions.isNotEmpty) {
        print('📝 Désactivation de l\'ancien abonnement...');
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('authentification')
            .doc(user.uid)
            .update({
          'isSubscriptionActive': false,
          'subscriptionId': 'free',
        });
      }

      // 5. Effectuer le nouvel achat
      print('💳 Achat du nouvel abonnement...');
      final purchaseResult = await Purchases.purchasePackage(package);

      // 6. Vérifier le résultat
      print('🎉 Purchase Result: ${purchaseResult.entitlements.active}');
      if (purchaseResult.entitlements.active.isNotEmpty) {
        String newSubscriptionId = purchaseResult.activeSubscriptions.first;
        print('✅ Nouvel abonnement actif: $newSubscriptionId');

        // 7. Mettre à jour Firestore
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('authentification')
            .doc(user.uid)
            .update({
          'subscriptionId': newSubscriptionId,
          'isSubscriptionActive': true,
          'numberOfCars': plan.contains("Premium") ? 999 : 5,
          'limiteContrat': plan.contains("Premium") ? 999 : 10,
          'subscriptionType': isMonthly ? 'monthly' : 'yearly',
          'lastUpdateDate': FieldValue.serverTimestamp(),
        });

        setState(() {
          subscriptionId = newSubscriptionId;
          isSubscriptionActive = true;
        });

        _showMessage('Abonnement modifié avec succès!', Colors.green);

        // Afficher le popup de confirmation
        showDialog(
          context: context,
          builder: (BuildContext context) => _buildActivationDialog(),
        );
      } else {
        throw Exception('Aucun abonnement actif trouvé après l\'achat.');
      }
    } catch (e) {
      print('❌ ERREUR: $e');
      _showMessage(
          e is PlatformException && e.code == '1'
              ? 'Changement annulé'
              : 'Erreur lors du changement',
          Colors.red);
    } finally {
      _showLoading(false);
    }
  }

  Widget _buildActivationDialog() {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icône animée ou image
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF08004D).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.workspace_premium,
                color: Color(0xFF08004D),
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            // Titre
            const Text(
              "Félicitations ! 🎉",
              style: TextStyle(
                color: Color(0xFF08004D),
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // Message
            const Text(
              "Votre abonnement est en cours d'activation.\nCela ne prendra que quelques minutes.\nMerci pour votre confiance !✨",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            // Bouton OK
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF08004D),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Compris !",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getProductId(String plan, bool isMonthly) {
    String productId;
    switch (plan) {
      case "Offre Pro":
      case "Offre Pro Annuel":
        productId =
            isMonthly ? 'ProMonthlySubscription' : 'ProYearlySubscription';
        break;
      case "Offre Premium":
      case "Offre Premium Annuel":
        productId = isMonthly
            ? 'PremiumMonthlySubscription'
            : 'PremiumYearlySubscription';
        break;
      default:
        productId = 'free';
    }
    return getMappedSubscriptionId(productId);
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
    print('Debug - État actuel:');
    print('isSubscriptionActive: $isSubscriptionActive');
    print('subscriptionId: $subscriptionId');
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
              const SizedBox(height: 25),
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
                padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
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
                  onSubscribe: _handleSubscription,
                  onPageChanged: (index) =>
                      setState(() => _currentIndex = index),
                  currentIndex: _currentIndex,
                ),
              ),
              if (subscriptionId != 'free')
                ElevatedButton(
                  onPressed: _openManageSubscription,
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
        onTap: () => setState(() => isMonthly = isMonthlyButton),
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
