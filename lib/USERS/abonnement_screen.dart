import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:ContraLoc/USERS/question_user.dart';

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

  void _cancelSubscription() async {
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
        print('Erreur lors de l\'annulation de l\'abonnement: $e');
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
        // Afficher l'erreur
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erreur lors du paiement'),
              backgroundColor: Colors.red,
            ),
          );
        }
        _resetSubscription();
        _cancelSubscription(); // Annuler la souscription en cas d'erreur
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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Transaction non validée, abonnement annulé.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        _resetSubscription();
        _cancelSubscription(); // Annuler la souscription si non validée
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
      }
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

  String _getPlanName(int cars) {
    if (cars >= 999) return "Premium";
    if (cars >= 5) return "Pro";
    return "Gratuit";
  }

  Widget _buildPlanCard(
    String title,
    String price,
    List<Map<String, dynamic>> features, {
    required bool isActive,
    required VoidCallback onSubscribe,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 15,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF08004D),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            price,
            style: const TextStyle(
              fontSize: 20,
              color: Color(0xFFFFC300),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: features
                  .map((feature) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Icon(
                              feature['isAvailable']
                                  ? Icons.check
                                  : Icons.close,
                              color: feature['isAvailable']
                                  ? Colors.green
                                  : Colors.red,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                feature['text'],
                                style: TextStyle(
                                  color: feature['isAvailable']
                                      ? Colors.black
                                      : Colors.grey,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: isActive ? null : onSubscribe,
            style: ElevatedButton.styleFrom(
              backgroundColor: isActive ? Colors.grey : const Color(0xFF08004D),
              minimumSize: const Size(double.infinity, 45),
            ),
            child: Text(
              isActive ? "Plan actuel" : "Souscrire",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    final Stream<List<PurchaseDetails>> purchaseUpdated =
        _inAppPurchase.purchaseStream;
    purchaseUpdated.drain();
    super.dispose();
  }

  void _handleSubscription(String plan) async {
    try {
      // Debug log pour voir quelle offre est sélectionnée
      print('Plan sélectionné: $plan');
      print('Mode: ${isMonthly ? "Mensuel" : "Annuel"}');

      ProductDetails? productDetails;
      String productId = '';

      // Simplification de la logique de sélection du produit
      if (plan.contains("Pro")) {
        productId =
            isMonthly ? 'ProMonthlySubscription' : 'ProYearlySubscription';
      } else if (plan.contains("Premium")) {
        productId = isMonthly
            ? 'PremiumMonthlySubscription'
            : 'PremiumYearlySubscription';
      }

      if (productId.isEmpty) return;

      try {
        productDetails = _products.firstWhere(
          (product) => product.id == productId,
        );

        final PurchaseParam purchaseParam = PurchaseParam(
          productDetails: productDetails,
        );

        await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
      } catch (e) {
        print('Erreur spécifique lors de l\'achat: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Veuillez réessayer dans quelques instants'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      print('Erreur générale: $e');
      // ...error handling...
    }
  }

  @override
  Widget build(BuildContext context) {
    final monthlyPlans = [
      {
        "title": "Offre Gratuite",
        "price": "0€/mois",
        "features": [
          {"text": "1 voiture", "isAvailable": true},
          {
            "text": "4 contrats/mois",
            "isAvailable": true
          }, // Mise à jour du texte
          {"text": "États des lieux sans photos", "isAvailable": true},
          {"text": "Prise de photos", "isAvailable": false},
        ],
      },
      {
        "title": "Offre Pro",
        "price": "9.99€/mois",
        "features": [
          {"text": "5 voitures", "isAvailable": true},
          {
            "text": "10 contrats/mois",
            "isAvailable": true
          }, // Mise à jour du texte
          {"text": "États des lieux simplifiés", "isAvailable": true},
          {"text": "Prise de photos", "isAvailable": false},
        ],
      },
      {
        "title": "Offre Premium",
        "price": "19.99€/mois",
        "features": [
          {"text": "Voitures illimitées", "isAvailable": true},
          {
            "text": "Contrats illimités",
            "isAvailable": true
          }, // Mise à jour du texte
          {"text": "États des lieux simplifiés", "isAvailable": true},
          {"text": "Prise de photos", "isAvailable": true},
        ],
      },
    ];

    final yearlyPlans = [
      {
        "title": "Offre Gratuite",
        "price": "0€/an",
        "features": [
          {"text": "1 voiture", "isAvailable": true},
          {"text": "4 contrats/mois", "isAvailable": true},
          {"text": "États des lieux simplifiés", "isAvailable": true},
          {"text": "Prise de photos", "isAvailable": false},
        ],
      },
      {
        "title": "Offre Pro",
        "price": "119.99€/an",
        "features": [
          {"text": "5 voitures", "isAvailable": true},
          {"text": "10 contrats/mois", "isAvailable": true},
          {"text": "États des lieux simplifiés", "isAvailable": true},
          {"text": "Prise de photos", "isAvailable": false},
        ],
      },
      {
        "title": "Offre Premium",
        "price": "239.99€/an",
        "features": [
          {"text": "Voitures illimitées", "isAvailable": true},
          {"text": "Contrats illimités", "isAvailable": true},
          {"text": "États des lieux simplifiés", "isAvailable": true},
          {"text": "Prise de photos", "isAvailable": true},
        ],
      },
    ];

    final plans = isMonthly ? monthlyPlans : yearlyPlans;

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
        iconTheme:
            const IconThemeData(color: Colors.white), // Bouton retour en blanc
        backgroundColor: const Color(0xFF08004D),
      ),
      backgroundColor: Colors.grey[50], // Ajout de la couleur de fond
      body: Column(
        children: [
          const SizedBox(height: 20),
          // Remplacement du ToggleButtons par un nouveau design
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
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => isMonthly = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color:
                            isMonthly ? const Color(0xFF08004D) : Colors.white,
                        borderRadius: const BorderRadius.horizontal(
                          left: Radius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 20,
                            color: isMonthly ? Colors.white : Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Mensuel",
                            style: TextStyle(
                              color: isMonthly ? Colors.white : Colors.grey,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => isMonthly = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color:
                            !isMonthly ? const Color(0xFF08004D) : Colors.white,
                        borderRadius: const BorderRadius.horizontal(
                          right: Radius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.calendar_month,
                            size: 20,
                            color: !isMonthly ? Colors.white : Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Annuel",
                            style: TextStyle(
                              color: !isMonthly ? Colors.white : Colors.grey,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 80),
          CarouselSlider.builder(
            itemCount: plans.length,
            options: CarouselOptions(
              height: 400,
              enlargeCenterPage: true,
              onPageChanged: (index, reason) {
                setState(() {
                  _currentIndex = index;
                });
              },
            ),
            itemBuilder: (context, index, realIndex) {
              final plan = plans[index];
              return _buildPlanCard(
                plan["title"] as String,
                plan["price"] as String,
                plan["features"] as List<Map<String, dynamic>>,
                isActive: currentPlan ==
                    _getPlanName(index == 0
                        ? 1
                        : index == 1
                            ? 5
                            : 9999),
                onSubscribe: () => _handleSubscription(plan["title"] as String),
              );
            },
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: plans.asMap().entries.map((entry) {
              return Container(
                width: 12,
                height: 12,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentIndex == entry.key
                      ? const Color(0xFF08004D)
                      : Colors.grey.shade300,
                ),
              );
            }).toList(),
          ),
          const Spacer(),
          Container(
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
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const QuestionUser(),
                    ),
                  );
                },
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.help_outline,
                        color: Color(0xFF08004D),
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "Des questions ? Contactez-nous",
                        style: TextStyle(
                          color: const Color(0xFF08004D),
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
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
