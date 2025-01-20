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

  void _showLoading(bool show) {
    setState(() {
      _isLoading = show;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadUserSubscription();
    _initRevenueCat();
    _setupPurchasesListener();
    _verifyOfferings();
  }

  void _setupPurchasesListener() {
    Purchases.addCustomerInfoUpdateListener((customerInfo) async {
      print('🔔 Mise à jour RevenueCat détectée!');
      print('📦 Abonnements actifs: ${customerInfo.activeSubscriptions}');
      print('✨ Entitlements actifs: ${customerInfo.entitlements.active}');

      if (customerInfo.entitlements.active.isNotEmpty) {
        print('📝 Mise à jour Firestore...');
        await _updateSubscriptionStatus(customerInfo);
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _initRevenueCat() async {
    try {
      // Ajoutez ces logs de débogage
      print('Début initialisation RevenueCat');
      print('Configuration actuelle:');
      final offerings = await Purchases.getOfferings();
      print('Offres disponibles: ${offerings.current?.availablePackages}');

      await Purchases
          .syncPurchases(); // Synchroniser les achats avant de récupérer CustomerInfo
      CustomerInfo updatedCustomerInfo =
          await Purchases.getCustomerInfo(); // Obtenir CustomerInfo mis à jour
      _updateSubscriptionStatus(
          updatedCustomerInfo); // Mettre à jour le statut de l'abonnement avec des données à jour
    } catch (e) {
      print('Erreur lors de l\'initialisation de RevenueCat: $e');
    }
  }

  Future<void> _verifyOfferings() async {
    try {
      // Force une synchronisation avec RevenueCat
      await Purchases.syncPurchases();

      final customerInfo = await Purchases.getCustomerInfo();
      print('Debug - État actuel RevenueCat:');
      print('Active Subscriptions: ${customerInfo.activeSubscriptions}');
      print('Active Entitlements: ${customerInfo.entitlements.active}');
      print('Latest ExpirationDate: ${customerInfo.latestExpirationDate}');

      if (customerInfo.activeSubscriptions.isNotEmpty) {
        print('Abonnement actif trouvé, mise à jour de Firestore...');
        await _updateSubscriptionStatus(customerInfo);
      }
    } catch (e) {
      print('Erreur lors de la vérification des offres: $e');
    }
  }

// Modifie la fonction _updateSubscriptionStatus pour mieux gérer la synchronisation
  Future<void> _updateSubscriptionStatus(CustomerInfo customerInfo) async {
    print('Début de _updateSubscriptionStatus');

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Affichez les informations de CustomerInfo pour vérifier ce que RevenueCat renvoie
    print('CustomerInfo: ${customerInfo.toJson()}');

    // Vérifier les Entitlements actifs
    if (customerInfo.entitlements.active.isNotEmpty) {
      // Déterminer le niveau d'accès
      bool hasFreeAccess =
          customerInfo.entitlements.active['free_access'] != null;
      bool hasPremiumAccess =
          customerInfo.entitlements.active['premium_access'] != null;
      bool hasProAccess =
          customerInfo.entitlements.active['pro_access'] != null;

      print('Debug - hasFreeAccess: $hasFreeAccess');
      print('Debug - hasPremiumAccess: $hasPremiumAccess');
      print('Debug - hasProAccess: $hasProAccess');

      String subscription;
      if (hasPremiumAccess) {
        subscription = customerInfo
            .entitlements.active['premium_access']!.productIdentifier;
      } else if (hasProAccess) {
        subscription =
            customerInfo.entitlements.active['pro_access']!.productIdentifier;
      } else {
        subscription = hasFreeAccess ? 'free_access' : 'free';
      }

      print('Debug - Nouveau subscriptionId: $subscription');

      // Mettre à jour les données utilisateur selon le niveau d'accès
      final updateData = {
        'numberOfCars': hasPremiumAccess
            ? 999
            : (hasProAccess ? 5 : 1), // Passe à 999 voitures pour Premium
        'limiteContrat': hasPremiumAccess
            ? 999
            : (hasProAccess ? 10 : 10), // Passe à illimité (999) pour Premium
        'isSubscriptionActive': true, // Devient true
        'subscriptionId':
            subscription, // Devient 'PremiumMonthlySubscription' ou 'PremiumYearlySubscription'
        'subscriptionType': subscription.toLowerCase().contains('yearly')
            ? 'yearly'
            : 'monthly',
        'subscriptionPurchaseDate': DateTime.now().toIso8601String(),
        'subscriptionExpirationDate': customerInfo.latestExpirationDate,
      };

      try {
        // Met à jour Firestore
        final docRef = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('authentification')
            .doc(user.uid);

        await docRef.set(updateData, SetOptions(merge: true));

        // Met à jour l'état local
        setState(() {
          isSubscriptionActive = true;
          subscriptionId = subscription;
          numberOfCars = updateData['numberOfCars'] as int;
          limiteContrat = updateData['limiteContrat'] as int;
          isMonthly = !subscription.toLowerCase().contains('yearly');
        });

        print('Debug - État mis à jour:');
        print('isSubscriptionActive: $isSubscriptionActive');
        print('subscriptionId: $subscriptionId');
      } catch (e) {
        print('Erreur mise à jour Firestore: $e');
        throw e;
      }
    } else {
      // Pas d'abonnement actif - réinitialise à l'offre gratuite
      await _resetToFreeSubscription(user.uid);
    }
  }

// Nouvelle fonction pour réinitialiser à l'offre gratuite
  Future<void> _resetToFreeSubscription(String uid) async {
    final freeData = {
      'numberOfCars': 1,
      'limiteContrat': 10,
      'isSubscriptionActive': false,
      'subscriptionId': 'free',
      'subscriptionType': 'monthly',
    };

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('authentification')
          .doc(uid)
          .set(freeData, SetOptions(merge: true));

      setState(() {
        isSubscriptionActive = false;
        subscriptionId = 'free';
        numberOfCars = 1;
        limiteContrat = 10;
        isMonthly = true;
      });
    } catch (e) {
      print('Erreur réinitialisation abonnement gratuit: $e');
    }
  }

// Modifiez la fonction _handleSubscription comme ceci :
  Future<void> _handleSubscription(String plan) async {
    _showLoading(true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showLoading(false);
      return;
    }

    try {
      if (plan == "Offre Gratuite") return;

      // 1. Récupérer l'ID du produit
      String productId = _getProductId(plan, isMonthly);
      print('Tentative d\'achat du produit: $productId');

      // 2. Récupérer les offres
      final offerings = await Purchases.getOfferings();
      if (offerings.current == null) throw Exception('Aucune offre disponible');

      // 3. Trouver le package
      final package = offerings.current!.availablePackages.firstWhere(
        (pkg) => pkg.storeProduct.identifier == productId,
        orElse: () => throw Exception('Package non trouvé'),
      );

      // 4. Tenter l'achat
      print('Début de l\'achat...');
      await Purchases.purchasePackage(package);

      // 5. La mise à jour de Firestore sera gérée par le listener
      print('Achat réussi, en attente de la mise à jour du listener...');

      _showMessage('Abonnement en cours d\'activation...', Colors.green);
    } on PlatformException catch (e) {
      if (e.code == '1' || e.code == 'payment_cancelled') {
        _showMessage('Achat annulé', Colors.orange);
      } else {
        _showMessage('Erreur: ${e.message}', Colors.red);
      }
    } catch (e) {
      print('ERREUR: $e');
      _showMessage('Erreur lors de l\'achat', Colors.red);
    } finally {
      _showLoading(false);
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
            .collection('authentification')
            .doc(user.uid)
            .get();

        if (!doc.exists) {
          // Initialisation correcte pour un nouvel utilisateur
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('authentification')
              .doc(user.uid)
              .set({
            'isSubscriptionActive': false, // Assurez-vous que c'est false
            'subscriptionId': 'free', // Assurez-vous que c'est 'free'
            'numberOfCars': 1,
            'limiteContrat': 10,
            'subscriptionType': 'monthly',
            'subscriptionPurchaseDate': null,
            'subscriptionExpirationDate': null
          }, SetOptions(merge: true));

          // Mise à jour de l'état local
          setState(() {
            isSubscriptionActive = false;
            subscriptionId = 'free';
            numberOfCars = 1;
            limiteContrat = 10;
            isMonthly = true;
          });
          return; // Sortir après l'initialisation
        }

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
