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

// Modifier la fonction _getProductId
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
  int limiteContrat = 10; // Ajout de cette ligne
  bool isSubscriptionActive = false;
  String subscriptionId = 'free'; // Remplacer currentPlan par subscriptionId
  int _currentIndex = 0;
  bool isMonthly = true; // Nouvel état pour le type d'abonnement

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  // Remettre les IDs originaux
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
    _loadUserSubscription(); // Cette méthode vérifie déjà l'état de l'abonnement
    _initInAppPurchase();
    finalizePendingTransactions(); // Ajouter cette ligne
    listenToPurchases(); // Ajouter cette ligne
  }

  Future<void> _initInAppPurchase() async {
    final bool available = await _inAppPurchase.isAvailable();
    print('In-App Purchase disponible: $available');
    if (!available) return;

    final ProductDetailsResponse response =
        await _inAppPurchase.queryProductDetails(_kProductIds.toSet());

    print('Produits trouvés: ${response.productDetails.length}');
    print('Produits non trouvés: ${response.notFoundIDs}');

    if (response.notFoundIDs.isNotEmpty) {
      print('IDs de produits non trouvés: ${response.notFoundIDs}');
      return;
    }

    setState(() {
      _products = response.productDetails;
      print('Nombre de produits chargés: ${_products.length}');
    });

    // Afficher les détails des produits
    for (var product in _products) {
      print(
          'Produit chargé - ID: ${product.id}, Titre: ${product.title}, Prix: ${product.price}');
    }

    _inAppPurchase.purchaseStream.listen(_listenToPurchaseUpdated);
  }

  Future<void> _listenToPurchaseUpdated(
      List<PurchaseDetails> purchaseDetailsList) async {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.purchased) {
        await _handleSuccessfulPurchase(purchaseDetails);
        _showMessage('Abonnement activé avec succès!', Colors.green);
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        print('Erreur d\'achat: ${purchaseDetails.error}');
        _showMessage('Erreur lors de l\'achat', Colors.red);
      }
    }
  }

  Future<void> _handleSuccessfulPurchase(PurchaseDetails purchase) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');

      // Ne pas simplifier l'ID, utiliser l'ID complet du produit
      final updateData = {
        'numberOfCars': _getNumberOfCars(purchase.productID),
        'limiteContrat': _getLimiteContrat(purchase.productID),
        'isSubscriptionActive': true,
        'subscriptionId': purchase.productID, // Utiliser l'ID complet
        'subscriptionType': isMonthly ? 'monthly' : 'yearly',
        'subscriptionPurchaseDate': DateTime.now().toIso8601String(),
      };

      print('DEBUG - Updating Firestore with: $updateData');

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update(updateData);

      // Mettre à jour l'état local
      setState(() {
        numberOfCars = updateData['numberOfCars'] as int;
        limiteContrat = updateData['limiteContrat'] as int;
        isSubscriptionActive = true;
        subscriptionId = purchase.productID;
      });
    } catch (e) {
      print('ERROR in _handleSuccessfulPurchase: $e');
      throw e; // Relancer l'erreur pour la gestion en amont
    }
  }

  // Nouvelles méthodes utilitaires
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

            // Vérification de cohérence
            bool shouldBeActive = storedSubscriptionId != 'free';

            // Si les données sont incohérentes, on réinitialise
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
              // Mise à jour normale de l'état
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
          // Initialiser les données par défaut dans Firestore
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
        // En cas d'erreur, on met des valeurs par défaut
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

  String _getPlanDisplayName(String subscriptionId) {
    switch (subscriptionId) {
      case 'ProMonthlySubscription':
      case 'ProYearlySubscription':
        return "Offre Pro";
      case 'PremiumMonthlySubscription':
      case 'PremiumYearlySubscription':
        return "Offre Premium";
      case 'free':
      default:
        return "Offre Gratuite";
    }
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
      print('Début _handleSubscription pour le plan: $plan');

      if (plan == "Offre Gratuite") {
        _showMessage(
          'Utilisez le bouton "Annuler mon abonnement" en bas de l\'écran',
          Colors.orange,
        );
        return;
      }

      String productId = _getProductId(plan, isMonthly);
      print('ProductID généré: $productId');

      // Vérifier si le produit existe dans la liste
      if (_products.isEmpty) {
        print('Erreur: Aucun produit n\'est chargé');
        _showMessage('Produits non disponibles pour le moment', Colors.orange);
        return;
      }

      print('Produits disponibles: ${_products.map((p) => p.id).join(", ")}');

      ProductDetails? productDetails;
      try {
        productDetails = _products.firstWhere(
          (product) => product.id == productId,
        );
        print(
            'Produit trouvé: ${productDetails.id} - ${productDetails.title} - ${productDetails.price}');
      } catch (e) {
        print('Erreur: Produit non trouvé dans la liste');
        _showMessage('Produit non disponible', Colors.orange);
        return;
      }

      print('Tentative d\'achat...');

      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: productDetails,
      );

      try {
        final bool success = await _inAppPurchase.buyNonConsumable(
          purchaseParam: purchaseParam,
        );
        print('Lancement de l\'achat: ${success ? "réussi" : "échoué"}');
      } catch (e) {
        print('Erreur lors du lancement de l\'achat: $e');
        throw e;
      }
    } catch (e) {
      print('Erreur dans _handleSubscription: $e');
      _showMessage('Erreur lors de l\'achat: $e', Colors.red);
    }
  }

  Future<void> _retryLastPurchase() async {
    if (_lastAttemptedPurchase != null) {
      await _handleSubscription(_lastAttemptedPurchase!);
    }
  }

  Future<void> finalizePendingTransactions() async {
    print('Vérification des transactions en attente...');
    try {
      await for (final purchases in _inAppPurchase.purchaseStream.timeout(
        const Duration(seconds: 1),
        onTimeout: (sink) => sink.close(),
      )) {
        for (var purchase in purchases) {
          if (purchase.pendingCompletePurchase) {
            print('Finalisation de la transaction: ${purchase.productID}');
            await _inAppPurchase.completePurchase(purchase);
          }
        }
        break; // On ne vérifie qu'une fois
      }
    } catch (e) {
      print('Erreur lors de la finalisation des transactions: $e');
    }
  }

  void listenToPurchases() {
    _inAppPurchase.purchaseStream.listen((purchases) async {
      print('Nouvelles transactions détectées: ${purchases.length}');

      for (PurchaseDetails purchase in purchases) {
        print(
            'Transaction - ID: ${purchase.productID}, Status: ${purchase.status}');

        if (purchase.pendingCompletePurchase) {
          print('Finalisation de la transaction en attente...');
          await _inAppPurchase.completePurchase(purchase);
          print('Transaction finalisée');
        }

        switch (purchase.status) {
          case PurchaseStatus.purchased:
            print('Transaction réussie');
            await _handleSuccessfulPurchase(purchase);
            break;
          case PurchaseStatus.error:
            print('Erreur transaction: ${purchase.error}');
            break;
          case PurchaseStatus.pending:
            print('Transaction en attente');
            break;
          case PurchaseStatus.restored:
            print('Transaction restaurée');
            break;
          case PurchaseStatus.canceled:
            print('Transaction annulée');
            break;
        }
      }
    });
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
              currentSubscriptionName:
                  _getPlanDisplayName(subscriptionId), // Mis à jour ici
              onSubscribe: _handleSubscription,
              onPageChanged: (index) => setState(() => _currentIndex = index),
              currentIndex: _currentIndex, // Add this line
            ),
          ),
          // Modifier cette condition pour simplement vérifier si ce n'est pas 'free'
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
