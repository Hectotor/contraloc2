import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart'; // Import RevenueCat
import 'package:ContraLoc/USERS/question_user.dart';
import 'package:ContraLoc/USERS/plan_display.dart';
import 'package:ContraLoc/USERS/annuler_abonnement.dart';

class AbonnementScreen extends StatefulWidget {
  const AbonnementScreen({Key? key}) : super(key: key);

  @override
  State<AbonnementScreen> createState() => _AbonnementScreenState();
}

String _getPlanDisplayName(String subscriptionId) {
  switch (subscriptionId) {
    case 'ProMonthlySubscription':
    case 'ProYearlySubscription':
      return 'Offre Pro';
    case 'PremiumMonthlySubscription':
    case 'PremiumYearlySubscription':
      return 'Offre Premium';
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

  @override
  void initState() {
    super.initState();
    _loadUserSubscription();
    _initRevenueCat();
  }

  Future<void> _initRevenueCat() async {
    try {
      CustomerInfo customerInfo = await Purchases.getCustomerInfo();
      _updateSubscriptionStatus(customerInfo);
    } catch (e) {
      print('Erreur lors de l\'initialisation de RevenueCat: $e');
    }
  }

  Future<void> _updateSubscriptionStatus(CustomerInfo customerInfo) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final entitlements = customerInfo.entitlements.active;
    if (entitlements.isNotEmpty) {
      final entitlement = entitlements.values.first;
      final productIdentifier = entitlement.productIdentifier;

      final updateData = {
        'numberOfCars': _getNumberOfCars(productIdentifier),
        'limiteContrat': _getLimiteContrat(productIdentifier),
        'isSubscriptionActive': true,
        'subscriptionId': productIdentifier,
        'subscriptionType': isMonthly ? 'monthly' : 'yearly',
        'subscriptionPurchaseDate': DateTime.now().toIso8601String(),
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update(updateData);

      setState(() {
        numberOfCars = updateData['numberOfCars'] as int;
        limiteContrat = updateData['limiteContrat'] as int;
        isSubscriptionActive = true;
        subscriptionId = productIdentifier;
      });
    }
  }

  Future<void> _handleSubscription(String plan) async {
    try {
      print('Début _handleSubscription pour le plan: $plan');

      if (plan == "Offre Gratuite") {
        _showMessage(
          'Utilisez le bouton "Annuler mon abonnement" en bas de l\'écran',
          Colors.orange,
        );
        return;
      }

      Offerings offerings = await Purchases.getOfferings();
      if (offerings.current == null) {
        _showMessage('Offres non disponibles pour le moment', Colors.orange);
        return;
      }

      Package package = offerings.current!.availablePackages.firstWhere(
        (pkg) => pkg.storeProduct.identifier == _getProductId(plan, isMonthly),
      );

      CustomerInfo customerInfo = await Purchases.purchasePackage(package);
      _updateSubscriptionStatus(customerInfo);
      _showMessage('Abonnement activé avec succès!', Colors.green);
    } catch (e) {
      if (e is PlatformException && e.code == '1') {
        // L'utilisateur a annulé l'achat
        _showMessage('Achat annulé.', Colors.orange);
      } else {
        print('Erreur dans _handleSubscription: $e');
        _showMessage('Erreur lors de l\'achat.', Colors.red);
      }
    }
  }

  Future<void> _loadUserSubscription() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        print('Début de la vérification de l\'abonnement...');

        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists) {
          final data = doc.data();
          if (data != null) {
            final storedSubscriptionId = data['subscriptionId'] ?? 'free';
            final isActive = data['isSubscriptionActive'] ?? false;
            final storedSubscriptionType =
                data['subscriptionType'] ?? 'monthly';

            print('Données trouvées dans Firestore:');
            print('storedSubscriptionId: $storedSubscriptionId');
            print('isSubscriptionActive: $isActive');

            bool shouldBeActive = storedSubscriptionId != 'free';

            if (!shouldBeActive && isActive) {
              print('Incohérence détectée - Réinitialisation des données');
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .update({
                'isSubscriptionActive': false,
                'subscriptionId': 'free',
                'numberOfCars': 1,
                'limiteContrat': 10,
                'subscriptionType': 'monthly'
              });

              setState(() {
                isSubscriptionActive = false;
                subscriptionId = 'free';
                numberOfCars = 1;
                limiteContrat = 10;
                isMonthly = true;
              });
            } else {
              setState(() {
                isSubscriptionActive = shouldBeActive && isActive;
                subscriptionId = storedSubscriptionId;
                numberOfCars = data['numberOfCars'] ?? 1;
                limiteContrat = data['limiteContrat'] ?? 10;
                isMonthly = storedSubscriptionType == 'monthly';
              });
            }

            print('État mis à jour:');
            print('subscriptionId: $subscriptionId');
            print('isSubscriptionActive: $isSubscriptionActive');
            print('numberOfCars: $numberOfCars');
          }
        } else {
          print('Document utilisateur non trouvé - Initialisation par défaut');
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({
            'isSubscriptionActive': false,
            'subscriptionId': 'free',
            'numberOfCars': 1,
            'limiteContrat': 10,
            'subscriptionType': 'monthly'
          });

          setState(() {
            isSubscriptionActive = false;
            subscriptionId = 'free';
            numberOfCars = 1;
            limiteContrat = 10;
            isMonthly = true;
          });
        }
      } catch (e) {
        print('Erreur lors de la vérification de l\'abonnement: $e');
        setState(() {
          isSubscriptionActive = false;
          subscriptionId = 'free';
          numberOfCars = 1;
          limiteContrat = 10;
          isMonthly = true;
        });
      }
    }
  }

  String _getProductId(String plan, bool isMonthly) {
    switch (plan) {
      case "Offre Pro":
        return isMonthly ? 'ProMonthlySubscription' : 'ProYearlySubscription';
      case "Offre Premium":
        return isMonthly
            ? 'PremiumMonthlySubscription'
            : 'PremiumYearlySubscription';
      default:
        return '';
    }
  }

  int _getNumberOfCars(String subscriptionId) {
    if (subscriptionId.contains('PremiumMonthly') ||
        subscriptionId.contains('PremiumYearly')) {
      return 999;
    } else if (subscriptionId.contains('ProMonthly') ||
        subscriptionId.contains('ProYearly')) {
      return 5;
    }
    return 1;
  }

  int _getLimiteContrat(String subscriptionId) {
    if (subscriptionId.contains('PremiumMonthly') ||
        subscriptionId.contains('PremiumYearly')) {
      return 999;
    } else if (subscriptionId.contains('ProMonthly') ||
        subscriptionId.contains('ProYearly')) {
      return 10;
    }
    return 10;
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
      body: Column(
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
              onPageChanged: (index) => setState(() => _currentIndex = index),
              currentIndex: _currentIndex,
            ),
          ),
          if (subscriptionId != 'free')
            AnnulerAbonnement(
              onCancelSuccess: () async {
                final user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  setState(() {
                    isSubscriptionActive = false;
                    subscriptionId = 'free';
                    numberOfCars = 1;
                    limiteContrat = 10;
                  });
                  await _loadUserSubscription(); // Recharger les données après l'annulation
                }
              },
              currentSubscriptionId: subscriptionId,
            ),
          _buildContactButton(),
          const SizedBox(height: 30),
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
