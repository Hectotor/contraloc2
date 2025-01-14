import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:ContraLoc/USERS/question_user.dart';
import 'package:ContraLoc/USERS/plan_display.dart'; // Nouvel import
import 'package:ContraLoc/USERS/annuler_abonnement.dart';

class AbonnementScreen extends StatefulWidget {
  const AbonnementScreen({Key? key}) : super(key: key);

  @override
  State<AbonnementScreen> createState() => _AbonnementScreenState();
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

class _AbonnementScreenState extends State<AbonnementScreen> {
  int numberOfCars = 1;
  bool isSubscriptionActive = false;
  String currentPlan = "Gratuit";
  int _currentIndex = 0;
  bool isMonthly = true; // Nouvel état pour le type d'abonnement

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  // Vérifier que les IDs correspondent exactement à ceux de l'App Store/Play Store
  final List<String> _kProductIds = [
    'ProMonthlySubscription',
    'ProYearlySubscription',
    'PremiumMonthlySubscription',
    'PremiumYearlySubscription',
  ];

  List<ProductDetails> _products = [];

  @override
  void initState() {
    super.initState();
    _loadUserSubscription();
    _initInAppPurchase();
  }

  Future<void> _initInAppPurchase() async {
    final bool available = await _inAppPurchase.isAvailable();
    if (!available) return;

    final ProductDetailsResponse response =
        await _inAppPurchase.queryProductDetails(_kProductIds.toSet());

    if (response.notFoundIDs.isNotEmpty) return;

    setState(() => _products = response.productDetails);
    _inAppPurchase.purchaseStream.listen(_listenToPurchaseUpdated);
  }

  Future<void> _listenToPurchaseUpdated(
      List<PurchaseDetails> purchaseDetailsList) async {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      try {
        switch (purchaseDetails.status) {
          case PurchaseStatus.pending:
            _showMessage('Transaction en cours...', Colors.orange);
            break;

          case PurchaseStatus.canceled:
            await _handleCancelledPurchase();
            break;

          case PurchaseStatus.error:
            await _handlePurchaseError(purchaseDetails.error);
            break;

          case PurchaseStatus.purchased:
            await _handleSuccessfulPurchase(purchaseDetails);
            _showMessage('Abonnement activé avec succès !', Colors.green);
            break;

          default:
            break;
        }

        if (purchaseDetails.pendingCompletePurchase) {
          await _inAppPurchase.completePurchase(purchaseDetails);
        }
      } catch (e) {
        _showMessage('Une erreur inattendue est survenue', Colors.red);
        print('Erreur de transaction: $e');
      }
    }
  }

  Future<void> _handleCancelledPurchase() async {
    _showMessage('Transaction annulée', Colors.orange);
    // Réinitialiser l'état si nécessaire
    setState(() {
      // Garder l'état actuel de l'abonnement
    });
  }

  Future<void> _handlePurchaseError(IAPError? error) async {
    String message = 'Erreur lors de la transaction';

    if (error != null) {
      switch (error.code) {
        case 'payment-cancelled':
          message = 'Paiement annulé';
          break;
        case 'store-problem':
          message = 'Problème avec le store. Veuillez réessayer.';
          break;
        case 'purchase-not-allowed':
          message = 'Achat non autorisé';
          break;
        default:
          message = 'Erreur lors de l\'achat. Veuillez réessayer.';
      }
    }

    _showMessage(message, Colors.red);
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

  Future<void> _handleSuccessfulPurchase(PurchaseDetails purchase) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      int newNumberOfCars;
      int limiteContrat;
      final bool isSubscriptionActive = true;

      // Assurez-vous que les IDs correspondent exactement
      switch (purchase.productID) {
        case 'ProMonthlySubscription':
        case 'ProYearlySubscription':
          newNumberOfCars = 5;
          limiteContrat = 10;
          break;
        case 'PremiumMonthlySubscription':
        case 'PremiumYearlySubscription':
          newNumberOfCars = 999;
          limiteContrat = 999;
          break;
        default:
          // Plan gratuit par défaut
          newNumberOfCars = 1;
          limiteContrat = 10;
          return;
      }

      try {
        // Vérification supplémentaire du statut d'achat
        if (purchase.status == PurchaseStatus.purchased) {
          // Mise à jour Firestore avec toutes les informations nécessaires
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .update({
            'numberOfCars': newNumberOfCars,
            'limiteContrat': limiteContrat,
            'isSubscriptionActive': isSubscriptionActive,
            'subscriptionId': purchase.productID,
            'subscriptionPurchaseDate': DateTime.now().toIso8601String(),
            'subscriptionType':
                purchase.productID.contains('Monthly') ? 'monthly' : 'yearly',
          });

          setState(() {
            numberOfCars = newNumberOfCars;
            this.isSubscriptionActive = isSubscriptionActive;
            currentPlan = _getPlanName(newNumberOfCars);
          });

          // Log de debug
          print('Abonnement mis à jour avec succès:');
          print('ID Produit: ${purchase.productID}');
          print('Nombre de voitures: $newNumberOfCars');
          print('Limite de contrats: $limiteContrat');
        }
      } catch (e) {
        print('Erreur lors de la mise à jour de l\'abonnement: $e');
        // ...error handling...
      }
    }
  }

  Future<void> _loadUserSubscription() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        setState(() {
          numberOfCars = doc.data()?['numberOfCars'] ?? 1;
          isSubscriptionActive = doc.data()?['isSubscriptionActive'] ?? false;
          currentPlan = _getPlanName(numberOfCars);
        });
      } else {
        // Si l'utilisateur est nouveau, définir l'offre gratuite comme plan actuel
        setState(() {
          numberOfCars = 1;
          isSubscriptionActive = true;
          currentPlan = "Offre Gratuite";
        });
      }
    }
  }

  String _getPlanName(int cars) {
    if (cars >= 999) return "Offre Premium";
    if (cars >= 5) return "Offre Pro";
    return "Offre Gratuite"; // Modification ici pour correspondre au titre exact dans PlanData
  }

  @override
  void dispose() {
    final Stream<List<PurchaseDetails>> purchaseUpdated =
        _inAppPurchase.purchaseStream;
    purchaseUpdated.drain();
    super.dispose();
  }

  Future<void> _handleSubscription(String plan) async {
    try {
      if (plan == "Offre Gratuite") {
        _showMessage(
          'Utilisez le bouton "Annuler mon abonnement" en bas de l\'écran',
          Colors.orange,
        );
        return;
      }

      if (isSubscriptionActive && currentPlan != "Offre Gratuite") {
        _showMessage(
          'Veuillez d\'abord annuler votre abonnement actuel',
          Colors.orange,
        );
        return;
      }

      String productId = _getProductId(plan, isMonthly);
      if (productId.isEmpty) {
        _showMessage('Erreur: Produit non trouvé', Colors.red);
        return;
      }

      final productDetails = _products.firstWhere(
        (product) => product.id == productId,
        orElse: () => throw Exception('Produit non trouvé'),
      );

      await _inAppPurchase.buyNonConsumable(
        purchaseParam: PurchaseParam(
          productDetails: productDetails,
        ),
      );
    } catch (e) {
      _showMessage('Erreur lors de l\'achat', Colors.red);
    }
  }

  Future<void> _retryLastPurchase() async {
    if (_lastAttemptedPurchase != null) {
      await _handleSubscription(_lastAttemptedPurchase!);
    }
  }

  @override
  Widget build(BuildContext context) {
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
          // Toggle Mensuel/Annuel
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
                vertical: 10, horizontal: 20), // Réduit de 10 à 5
            child: Text(
              "Nos prix sont sans engagement",
              style: TextStyle(
                color: Color(0xFF08004D),
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          // Nouveau widget PlanDisplay
          Expanded(
            child: PlanDisplay(
              isMonthly: isMonthly,
              currentPlan: currentPlan,
              onSubscribe: _handleSubscription,
              onPageChanged: (index) => setState(() => _currentIndex = index),
              currentIndex: _currentIndex, // Add this line
            ),
          ),
          if (isSubscriptionActive && currentPlan != "Offre Gratuite")
            AnnulerAbonnement(
              onCancelSuccess: () {
                setState(() {
                  isSubscriptionActive = false;
                  currentPlan = "Offre Gratuite";
                  numberOfCars = 1;
                });
                _showMessage('Abonnement annulé avec succès', Colors.orange);
              },
              // Modification ici : passer l'ID de l'abonnement actuel
              currentSubscriptionId: _getProductId(
                  currentPlan, isMonthly), // Utilisez la fonction existante
              inAppPurchase: _inAppPurchase,
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
