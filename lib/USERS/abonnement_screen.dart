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
  bool _isTransactionPending = false; // New state to track pending transactions

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
    _cancelAllPendingTransactions(); // Nettoie les transactions en attente
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

  void _resetSubscription() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'numberOfCars': 1,
          'isSubscriptionActive': false,
          'subscriptionId': 'free',
        });
        setState(() {
          numberOfCars = 1;
          isSubscriptionActive = false;
          currentPlan = "Gratuit";
        });
      } catch (e) {
        print('Erreur lors de la réinitialisation de l\'abonnement: $e');
      }
    }
  }

  Future<void> _listenToPurchaseUpdated(
      List<PurchaseDetails> purchaseDetailsList) async {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        // Afficher un indicateur de chargement
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Traitement du paiement en cours...')),
          );
        }
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        // Afficher l'erreur et réinitialiser l'abonnement
        print('Erreur lors de l\'achat : ${purchaseDetails.error}');
        await _cancelAllPendingTransactions(); // Annule toutes les transactions en attente
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erreur lors de l\'achat. Transaction annulée.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        _resetSubscription();
      } else if (purchaseDetails.status == PurchaseStatus.canceled) {
        // Annuler la transaction si l'utilisateur l'a annulée
        print('Achat annulé par l\'utilisateur.');
        await _cancelAllPendingTransactions(); // Annule toutes les transactions en attente
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Achat annulé. Aucune transaction en cours.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        _resetSubscription();
      } else if (purchaseDetails.status == PurchaseStatus.purchased) {
        // Vérifier que le paiement est bien validé avant de mettre à jour
        if (purchaseDetails.pendingCompletePurchase) {
          await _inAppPurchase.completePurchase(purchaseDetails);
          // Une fois le paiement complété, mettre à jour l'abonnement
          await _handleSuccessfulPurchase(purchaseDetails);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Abonnement mis à jour avec succès !'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      } else {
        // Réinitialiser l'abonnement si la transaction n'est pas validée
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Transaction non validée, abonnement annulé.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        _resetSubscription();
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

  void _handleSubscription(String plan) async {
    if (_isTransactionPending) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Une transaction est déjà en cours. Veuillez patienter.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Ajout de la confirmation pour passer à un plan inférieur
    if (plan == "Offre Gratuite" ||
        (currentPlan == "Offre Premium" && plan == "Offre Pro")) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 0,
            backgroundColor: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Confirmation',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Êtes-vous sûr de vouloir passer à ${plan} ?\n\nCela réduira les fonctionnalités disponibles.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text(
                          'Annuler',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _switchToLowerPlan(plan);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        child: const Text('Confirmer'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
      return;
    }

    // Continuer avec la logique existante pour les upgrades
    try {
      setState(() {
        _isTransactionPending = true;
      });

      print('Plan sélectionné: $plan');
      print('Mode: ${isMonthly ? "Mensuel" : "Annuel"}');

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

      // Vérifier si le produit existe dans la liste
      final productDetails = _products.firstWhere(
        (product) => product.id == productId,
        orElse: () => throw Exception('Produit non trouvé'),
      );

      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: productDetails,
      );

      final bool pending = await _inAppPurchase.buyNonConsumable(
        purchaseParam: purchaseParam,
      );

      if (!pending && mounted) {
        // Si la transaction n'a pas démarré, on peut réessayer
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Erreur de transaction'),
              content: const Text(
                  'La transaction n\'a pas pu démarrer. Voulez-vous réessayer?'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Annuler'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _handleSubscription(plan); // Réessayer la transaction
                  },
                  child: const Text('Réessayer'),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      print('Erreur lors de l\'achat: $e');
      if (mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Erreur'),
              content: Text('Une erreur est survenue: $e'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      }
    } finally {
      setState(() {
        _isTransactionPending = false;
      });
    }
  }

  Future<void> _switchToLowerPlan(String newPlan) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        int newNumberOfCars = newPlan == "Offre Pro" ? 5 : 1;
        int newLimiteContrat = newPlan == "Offre Pro" ? 10 : 4;

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'numberOfCars': newNumberOfCars,
          'limiteContrat': newLimiteContrat,
          'isSubscriptionActive': true,
          'subscriptionId': 'free',
          'subscriptionType': 'monthly',
          'subscriptionPurchaseDate': DateTime.now().toIso8601String(),
        });

        setState(() {
          numberOfCars = newNumberOfCars;
          isSubscriptionActive = true;
          currentPlan = newPlan;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Votre abonnement a été mis à jour'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors du changement de plan : $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _cancelAllPendingTransactions() async {
    final Stream<List<PurchaseDetails>> purchaseUpdated =
        _inAppPurchase.purchaseStream;

    await for (final purchaseDetailsList in purchaseUpdated) {
      for (final purchase in purchaseDetailsList) {
        if (purchase.pendingCompletePurchase) {
          try {
            await _inAppPurchase.completePurchase(purchase);
            print(
                'Transaction en attente annulée pour : ${purchase.productID}');
          } catch (e) {
            print('Erreur lors de l\'annulation de la transaction : $e');
          }
        }
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
              isTransactionPending: _isTransactionPending,
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
