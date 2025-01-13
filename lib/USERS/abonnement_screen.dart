import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:ContraLoc/USERS/question_user.dart';
import 'package:ContraLoc/USERS/plan_display.dart'; // Nouvel import

class AbonnementScreen extends StatefulWidget {
  const AbonnementScreen({Key? key}) : super(key: key);

  @override
  State<AbonnementScreen> createState() => _AbonnementScreenState();
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
    if (!available) {
      // Store n'est pas disponible
      return;
    }

    // Écoutez les achats
    final Stream<List<PurchaseDetails>> purchaseUpdated =
        _inAppPurchase.purchaseStream;
    purchaseUpdated.listen((purchaseDetailsList) {
      _listenToPurchaseUpdated(purchaseDetailsList);
    });

    // Chargez les produits
    final ProductDetailsResponse productDetailsResponse =
        await _inAppPurchase.queryProductDetails(_kProductIds.toSet());

    if (productDetailsResponse.error == null) {
      setState(() {
        _products = productDetailsResponse.productDetails;
      });
    }
  }

  Future<void> _listenToPurchaseUpdated(
      List<PurchaseDetails> purchaseDetailsList) async {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      try {
        if (purchaseDetails.status == PurchaseStatus.canceled) {
          // Gestion spécifique de l'annulation
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Transaction annulé'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        } else if (purchaseDetails.status == PurchaseStatus.error) {
          // Gestion améliorée des erreurs
          String errorMessage = 'Une erreur est survenue';

          if (purchaseDetails.error != null) {
            // Extraction du message d'erreur détaillé
            errorMessage = purchaseDetails.error!.message;
            // Nettoyage du message d'erreur pour éviter "Instance of 'SKError'"
            if (errorMessage.contains('Instance of')) {
              errorMessage = 'Transaction annulée';
            }
          }

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMessage),
                backgroundColor: Colors.red,
              ),
            );
          }
        } else if (purchaseDetails.status == PurchaseStatus.purchased) {
          await _handleSuccessfulPurchase(purchaseDetails);
        }

        // Compléter la transaction dans tous les cas
        if (purchaseDetails.pendingCompletePurchase) {
          await _inAppPurchase.completePurchase(purchaseDetails);
        }
      } catch (e) {
        print('Erreur lors du traitement de l\'achat: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erreur lors du traitement de la transaction'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

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
          limiteContrat = 4;
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

  Future<void> _switchToLowerPlan(String plan) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'numberOfCars': 1,
        'limiteContrat': 4,
        'isSubscriptionActive': false,
        'subscriptionId': 'free',
        'subscriptionPurchaseDate': DateTime.now().toIso8601String(),
        'subscriptionType': 'free',
      });

      setState(() {
        numberOfCars = 1;
        isSubscriptionActive = false;
        currentPlan = "Offre Gratuite";
      });
    }
  }

  Future<void> _handleSubscription(String plan) async {
    try {
      // Vérifier si c'est un plan gratuit
      if (plan == "Offre Gratuite") {
        await _switchToLowerPlan(plan);
        return;
      }

      String productId = '';
      if (plan.contains("Pro")) {
        productId =
            isMonthly ? 'ProMonthlySubscription' : 'ProYearlySubscription';
      } else if (plan.contains("Premium")) {
        productId = isMonthly
            ? 'PremiumMonthlySubscription'
            : 'PremiumYearlySubscription';
      }

      if (productId.isEmpty) return;

      final productDetails = _products.firstWhere(
        (product) => product.id == productId,
        orElse: () => throw Exception('Produit non trouvé'),
      );

      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: productDetails,
      );

      await _inAppPurchase.buyNonConsumable(
        purchaseParam: purchaseParam,
      );
    } catch (e) {
      print('Erreur lors de l\'achat: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Impossible de démarrer l\'achat. Veuillez réessayer.'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
          const SizedBox(height: 40),
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
          // Bouton Contact
          _buildContactButton(),
          const SizedBox(height: 10),
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const QuestionUser()),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(
                  Icons.help_outline,
                  color: Color(0xFF08004D),
                  size: 24,
                ),
                SizedBox(width: 12),
                Text(
                  "Des questions ? Contactez-nous",
                  style: TextStyle(
                    color: Color(0xFF08004D),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
