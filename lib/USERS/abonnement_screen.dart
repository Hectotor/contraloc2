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
  List<ProductDetails> _products = [];
  List<String> _kProductIds = [
    'pro_monthly_subscription', // Définissez ces IDs dans votre console Play/App Store
    'pro_yearly_subscription',
    'premium_monthly_subscription',
    'premium_yearly_subscription',
  ];

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
      }
    }
  }

  Future<void> _handleSuccessfulPurchase(PurchaseDetails purchase) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      int newNumberOfCars;
      final bool isSubscriptionActive = true;

      // Déterminer le type d'abonnement basé sur l'ID du produit
      switch (purchase.productID) {
        case 'pro_monthly_subscription':
        case 'pro_yearly_subscription':
          newNumberOfCars = 5;
          break;
        case 'premium_monthly_subscription':
        case 'premium_yearly_subscription':
          newNumberOfCars = 999;
          break;
        default:
          newNumberOfCars = 1;
          return; // Sortir si l'ID du produit n'est pas reconnu
      }

      // Mise à jour dans Firestore uniquement après validation du paiement
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'numberOfCars': newNumberOfCars,
        'isSubscriptionActive': isSubscriptionActive,
        'subscriptionId': purchase.productID,
        'subscriptionPurchaseDate': DateTime.now().toIso8601String(),
      });

      // Mise à jour de l'état local seulement après la mise à jour Firestore
      setState(() {
        numberOfCars = newNumberOfCars;
        this.isSubscriptionActive = isSubscriptionActive;
        currentPlan = _getPlanName(newNumberOfCars);
      });
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

  String _getPlanName(int cars) {
    if (cars <= 1) return "Gratuit";
    if (cars <= 5) return "Pro";
    return "Premium";
  }

  Widget _buildPlanCard(
      String title, String price, List<Map<String, dynamic>> features,
      {bool isActive = false, VoidCallback? onSubscribe}) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(8),
      color: Colors.white, // Ajout du fond blanc
      shape: RoundedRectangleBorder(
        // Ajout d'une bordure arrondie
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        height: 300, // Hauteur fixe pour la carte
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize:
              MainAxisSize.min, // Important : forcer la taille minimale
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
                backgroundColor:
                    isActive ? Colors.grey : const Color(0xFF08004D),
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
      ),
    );
  }

  void _handleSubscription(String plan) async {
    try {
      ProductDetails? productDetails;
      String productId = '';

      // Déterminer l'ID du produit en fonction du plan et du type d'abonnement
      if (isMonthly) {
        if (plan.contains("Pro")) {
          productId = 'pro_monthly_subscription';
        } else if (plan.contains("Premium")) {
          productId = 'premium_monthly_subscription';
        }
      } else {
        if (plan.contains("Pro")) {
          productId = 'pro_yearly_subscription';
        } else if (plan.contains("Premium")) {
          productId = 'premium_yearly_subscription';
        }
      }

      // Chercher le produit correspondant
      if (productId.isNotEmpty) {
        try {
          productDetails = _products.firstWhere(
            (product) => product.id == productId,
          );

          // Si on trouve le produit, on lance l'achat
          final PurchaseParam purchaseParam = PurchaseParam(
            productDetails: productDetails,
          );
          await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
        } catch (e) {
          // Si le produit n'est pas trouvé, afficher une erreur
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Produit non disponible pour le moment'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Une erreur est survenue lors de l\'achat'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
          {"text": "4 contrats/mois", "isAvailable": true},
          {"text": "États des lieux sans photos", "isAvailable": true},
          {"text": "Prise de photos", "isAvailable": false},
        ],
      },
      {
        "title": "Offre Pro",
        "price": "9.99€/mois",
        "features": [
          {"text": "5 voitures", "isAvailable": true},
          {"text": "10 contrats/mois", "isAvailable": true},
          {"text": "États des lieux simplifiés", "isAvailable": true},
          {"text": "Prise de photos", "isAvailable": false},
        ],
      },
      {
        "title": "Offre Premium",
        "price": "19.99€/mois",
        "features": [
          {"text": "Voitures illimitées", "isAvailable": true},
          {"text": "Contrats illimités", "isAvailable": true},
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
          ToggleButtons(
            isSelected: [isMonthly, !isMonthly],
            onPressed: (index) {
              setState(() {
                isMonthly = index == 0;
              });
            },
            children: const [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text("Mensuel"),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text("Annuel"),
              ),
            ],
          ),
          const SizedBox(height: 20),
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
