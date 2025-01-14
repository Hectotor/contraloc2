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
  int limiteContrat = 10; // Ajout de cette ligne
  bool isSubscriptionActive = false;
  String subscriptionId = 'free'; // Remplacer currentPlan par subscriptionId
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
    try {
      print('Début _handleSuccessfulPurchase');
      print('ProductID: ${purchase.productID}');

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('Erreur: Utilisateur non connecté');
        _showMessage('Erreur: Utilisateur non connecté', Colors.red);
        return;
      }

      // Vérification du statut d'achat
      if (purchase.status != PurchaseStatus.purchased) {
        print('Erreur: Statut d\'achat invalide - ${purchase.status}');
        _showMessage('Erreur: Statut d\'achat invalide', Colors.red);
        return;
      }

      int newNumberOfCars;
      int limiteContrat;

      // Log des détails de l'achat
      print('Traitement de l\'achat: ${purchase.productID}');

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
          print('Erreur: ID de produit invalide - ${purchase.productID}');
          _showMessage('Erreur: Produit non reconnu', Colors.red);
          return;
      }

      // Préparation des données à mettre à jour
      final updateData = {
        'numberOfCars': newNumberOfCars,
        'limiteContrat': limiteContrat,
        'isSubscriptionActive': true,
        'subscriptionId': purchase.productID,
        'subscriptionPurchaseDate': DateTime.now().toIso8601String(),
      };

      print('Mise à jour Firestore avec: $updateData');

      // Mise à jour Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update(updateData);

      print('Mise à jour Firestore réussie');

      // Mise à jour de l'état local
      setState(() {
        numberOfCars = newNumberOfCars;
        isSubscriptionActive = true;
        subscriptionId = purchase.productID;
      });

      _showMessage('Abonnement activé avec succès!', Colors.green);
    } catch (e) {
      print('Erreur dans _handleSuccessfulPurchase: $e');
      _showMessage(
          'Erreur lors de la mise à jour de l\'abonnement: $e', Colors.red);
    }
  }

  Future<void> _loadUserSubscription() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists) {
          final data = doc.data();
          final storedSubscriptionId = data?['subscriptionId'] ?? 'free';
          final storedNumberOfCars = data?['numberOfCars'] ?? 1;

          print('Données brutes Firebase:');
          print('subscriptionId: $storedSubscriptionId');
          print('numberOfCars: $storedNumberOfCars');

          // Met à jour l'état local
          setState(() {
            numberOfCars = storedNumberOfCars;
            isSubscriptionActive = storedSubscriptionId != 'free';
            subscriptionId =
                storedSubscriptionId; // Correction ici : utiliser l'ID stocké directement
          });

          print('État final après chargement:');
          print('subscriptionId: $subscriptionId');
          print('isSubscriptionActive: $isSubscriptionActive');
          print('numberOfCars: $numberOfCars');
        } else {
          setState(() {
            numberOfCars = 1;
            isSubscriptionActive = false;
            subscriptionId = 'free';
          });
        }
      } catch (e) {
        print('Erreur chargement: $e');
        _showMessage('Erreur de chargement des données', Colors.red);
      }
    }
  }

  String _getPlanDisplayName(String subscriptionId) {
    if (subscriptionId.contains('Premium')) return "Offre Premium";
    if (subscriptionId.contains('Pro')) return "Offre Pro";
    return "Offre Gratuite";
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

      // Vérifications préalables
      if (plan == "Offre Gratuite") {
        _showMessage(
          'Utilisez le bouton "Annuler mon abonnement" en bas de l\'écran',
          Colors.orange,
        );
        return;
      }

      if (isSubscriptionActive && subscriptionId != "Offre Gratuite") {
        _showMessage(
          'Veuillez d\'abord annuler votre abonnement actuel',
          Colors.orange,
        );
        return;
      }

      String productId = _getProductId(plan, isMonthly);
      print('ProductID généré: $productId');

      if (productId.isEmpty) {
        _showMessage('Erreur: Produit non trouvé', Colors.red);
        return;
      }

      // Recherche du produit
      final productDetails = _products.firstWhere(
        (product) => product.id == productId,
        orElse: () {
          print('Produit non trouvé dans _products');
          throw Exception('Produit non trouvé');
        },
      );

      print('Produit trouvé: ${productDetails.id}');

      // Lancement de l'achat
      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: productDetails,
      );

      _lastAttemptedPurchase = plan;

      await _inAppPurchase.buyNonConsumable(
        purchaseParam: purchaseParam,
      );

      print('Requête d\'achat envoyée');
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
          if (subscriptionId != 'free')
            AnnulerAbonnement(
              onCancelSuccess: () async {
                try {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    // Forcer un rechargement complet des données
                    await _loadUserSubscription();

                    // Mettre à jour l'état local immédiatement
                    setState(() {
                      isSubscriptionActive = false;
                      subscriptionId = 'free';
                      numberOfCars = 1;
                      limiteContrat = 10; // Ajout de cette ligne
                    });

                    // Afficher le message de succès
                    _showMessage(
                        'Abonnement annulé avec succès', Colors.orange);
                  }
                } catch (e) {
                  print('Erreur lors de la mise à jour de l\'état: $e');
                  _showMessage('Erreur lors de l\'annulation', Colors.red);
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
