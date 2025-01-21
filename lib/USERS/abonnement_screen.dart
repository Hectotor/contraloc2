import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart'; // Import RevenueCat
import 'package:ContraLoc/USERS/question_user.dart';
import 'package:ContraLoc/USERS/plan_display.dart';
import 'package:url_launcher/url_launcher.dart'; // Import url_launcher
import 'dart:io'; // Import dart:io for Platform

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

class _AbonnementScreenState extends State<AbonnementScreen> {
  int numberOfCars = 1;
  int limiteContrat = 10;
  bool isSubscriptionActive = false;
  String subscriptionId = 'free';
  int _currentIndex = 0;
  bool isMonthly = true;
  bool _isLoading = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
// Ajoutez ces variables pour sauvegarder l'état précédent
  void _showLoading(bool show) {
    setState(() {
      _isLoading = show;
    });
  }

  @override
  void initState() {
    super.initState();
    _initializeSubscription();
  }

  Future<void> _initializeSubscription() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // 1. Vérifier RevenueCat
      final customerInfo = await Purchases.getCustomerInfo();
      print('🔍 État RevenueCat initial:');
      print('Abonnements: ${customerInfo.activeSubscriptions}');
      print('Entitlements: ${customerInfo.entitlements.all}');

      // 2. Déterminer l'abonnement correspondant au dernier achat
      String currentSubscriptionId = 'free';
      bool hasActiveSubscription = false;

      if (customerInfo.entitlements.all.isNotEmpty) {
        // Récupérer l'entitlement avec la date d'achat la plus récente
        final latestEntitlement = customerInfo.entitlements.all.values.reduce(
          (a, b) {
            final aDate = DateTime.parse(a.latestPurchaseDate);
            final bDate = DateTime.parse(b.latestPurchaseDate);
            return aDate.isAfter(bDate) ? a : b;
          },
        );

        currentSubscriptionId = latestEntitlement.productIdentifier;
        hasActiveSubscription = latestEntitlement.isActive;

        print('✅ Dernier abonnement détecté: $currentSubscriptionId');
      }

      // 3. Mettre à jour Firestore avec l'entitlement du dernier achat
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('authentification')
          .doc(user.uid)
          .set({
        'subscriptionId': currentSubscriptionId,
        'isSubscriptionActive': hasActiveSubscription,
        'numberOfCars': currentSubscriptionId.contains('Premium')
            ? 999
            : (currentSubscriptionId.contains('Pro') ? 5 : 1),
        'limiteContrat': currentSubscriptionId.contains('Premium') ? 999 : 10,
        'subscriptionType':
            currentSubscriptionId.toLowerCase().contains('yearly')
                ? 'yearly'
                : 'monthly',
        'lastSyncDate': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));

      // 4. Mettre à jour l'état local
      setState(() {
        subscriptionId = currentSubscriptionId;
        isSubscriptionActive = hasActiveSubscription;
        isMonthly = !currentSubscriptionId.toLowerCase().contains('yearly');
      });

      print('🎉 Initialisation de l\'abonnement terminée.');
    } catch (e) {
      print('❌ Erreur initialisation: $e');
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _handleSubscription(String plan) async {
    _showLoading(true);
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

  String _getProductId(String plan, bool isMonthly) {
    switch (plan) {
      case "Offre Pro":
      case "Offre Pro Annuel":
        return isMonthly ? 'ProMonthlySubscription' : 'ProYearlySubscription';
      case "Offre Premium":
      case "Offre Premium Annuel":
        return isMonthly
            ? 'PremiumMonthlySubscription'
            : 'PremiumYearlySubscription';
      default:
        return 'free';
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
