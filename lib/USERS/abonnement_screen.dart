import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
//import 'paiement.dart'; // Ajouter cet import
import 'package:in_app_purchase/in_app_purchase.dart'; // Ajouter cet import

class AbonnementScreen extends StatefulWidget {
  const AbonnementScreen({Key? key}) : super(key: key);

  @override
  State<AbonnementScreen> createState() => _AbonnementScreenState();
}

class _AbonnementScreenState extends State<AbonnementScreen> {
  int numberOfCars = 1;
  bool isAnnual = false; // Changé de true à false pour commencer en mensuel
  bool isSubscriptionActive = false;

  // Ajouter ces variables
  final InAppPurchase _iap = InAppPurchase.instance;
  List<ProductDetails> _products = [];
  bool _isLoading = false;
  late StreamSubscription<List<PurchaseDetails>> _subscription;

  // Ajouter cette variable pour stocker temporairement le nombre de voitures

  @override
  void initState() {
    super.initState();
    _checkSubscriptionStatus();
    _initStore(); // Ajouter l'initialisation du store
// Initialiser avec la valeur actuelle

    // Ajouter le listener pour les achats
    final Stream<List<PurchaseDetails>> purchaseUpdated =
        InAppPurchase.instance.purchaseStream;
    _subscription = purchaseUpdated.listen((purchaseDetailsList) {
      _listenToPurchaseUpdated(purchaseDetailsList);
    }, onDone: () {
      _subscription.cancel();
    }, onError: (error) {
      print('Erreur stream achat: $error');
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  Future<void> _initStore() async {
    final isAvailable = await _iap.isAvailable();
    if (!isAvailable) {
      print('IAP not available');
      return;
    }

    const Set<String> ids = {
      'contraloc.premium.2cars.monthly',
      'contraloc.premium.2cars.yearly',
      'contraloc.premium.3cars.monthly',
      'contraloc.premium.3cars.yearly',
      'contraloc.premium.4cars.monthly',
      'contraloc.premium.4cars.yearly',
      'contraloc.premium.5cars.monthly',
      'contraloc.premium.5cars.yearly',
      'contraloc.premium.6cars.monthly',
      'contraloc.premium.6cars.yearly',
      'contraloc.premium.7cars.monthly',
      'contraloc.premium.7cars.yearly',
      'contraloc.premium.8cars.monthly',
      'contraloc.premium.8cars.yearly',
      'contraloc.premium.9cars.monthly',
      'contraloc.premium.9cars.yearly',
      'contraloc.premium.10cars.monthly',
      'contraloc.premium.10cars.yearly',
      'contraloc.premium.11cars.monthly',
      'contraloc.premium.11cars.yearly',
      'contraloc.premium.12cars.monthly',
      'contraloc.premium.12cars.yearly',
      'contraloc.premium.13cars.monthly',
      'contraloc.premium.13cars.yearly',
      'contraloc.premium.14cars.monthly',
      'contraloc.premium.14cars.yearly',
      'contraloc.premium.15cars.monthly',
      'contraloc.premium.15cars.yearly',
      'contraloc.premium.unlimited.monthly',
      'contraloc.premium.unlimited.yearly',
      'contraloc-premium-2cars-monthly',
      'contraloc-premium-2cars-year',
      'contraloc-premium-3cars-monthly',
      'contraloc-premium-3cars-yearly',
      'contraloc-premium-4cars-monthly',
      'contraloc-premium-4cars-yearly',
      'contraloc-premium-5cars-monthly',
      'contraloc-premium-5cars-yearly',
      'contraloc-premium-6cars-monthly',
      'contraloc-premium-6cars-yearly',
      'contraloc-premium-7cars-monthly',
      'contraloc-premium-7cars-yearly',
      'contraloc-premium-8cars-monthly',
      'contraloc-premium-8cars-yearly',
      'contraloc-premium-9cars-monthly',
      'contraloc-premium-9cars-yearly',
      'contraloc-premium-10cars-monthly',
      'contraloc-premium-10cars-yearly',
      'contraloc-premium-11cars-monthly',
      'contraloc-premium-11cars-yearly',
      'contraloc-premium-12cars-monthly',
      'contraloc-premium-12cars-yearly',
      'contraloc-premium-13cars-monthly',
      'contraloc-premium-13cars-yearly',
      'contraloc-premium-14cars-monthly',
      'contraloc-premium-14cars-yearly',
      'contraloc-premium-15cars-monthly',
      'contraloc-premium-15cars-yearly',
      'contraloc-premium-unlimited-monthly',
      'contraloc-premium-unlimited-yearly',
    };

    final response = await _iap.queryProductDetails(ids);
    setState(() {
      _products = response.productDetails;
    });
    // Ajouter ce debug print
    print('Produits disponibles: ${_products.map((p) => p.id).toList()}');
  }

  Future<void> _checkSubscriptionStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      setState(() {
        isSubscriptionActive = doc.data()?['isSubscriptionActive'] ?? false;
        numberOfCars = doc.data()?['numberOfCars'] ??
            1; // Mettre à jour le nombre de voitures
      });
    }
  }

  double getPrice() {
    if (numberOfCars <= 1) return 0.0; // 1 voiture est gratuite
    if (numberOfCars >= 16) return 84.99; // Prix fixe pour 16+ voitures
    if (numberOfCars == 2) return 19.99; // 2 voitures = prix de base
    return 19.99 +
        (numberOfCars - 2) * 3.0; // Prix pour voitures supplémentaires
  }

  String getCarDisplay() {
    if (numberOfCars >= 16) {
      return "Voitures illimitées";
    }
    return "$numberOfCars voitures";
  }

  String getFormattedPrice() {
    double price = getPrice();
    if (numberOfCars <= 1) {
      return "\u20AC0.00 / ${isAnnual ? 'an' : 'mois'}";
    }

    if (isAnnual) {
      // Calculer sur 11 mois au lieu de 12 (1 mois offert)
      double annualPrice = price * 11;
      // Arrondir au prix supérieur se terminant par 9.99
      int basePrice = annualPrice.ceil();
      annualPrice = ((basePrice + 9) ~/ 10 * 10) - 0.01;
      return "\u20AC${annualPrice.toStringAsFixed(2)} / an";
    } else {
      return "\u20AC${price.toStringAsFixed(2)} / mois";
    }
  }

  Future<void> _listenToPurchaseUpdated(
      List<PurchaseDetails> purchaseDetailsList) async {
    for (final purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        setState(() {
          _isLoading = true;
        });
      } else {
        if (purchaseDetails.status == PurchaseStatus.error) {
          setState(() {
            _isLoading = false;
          });
          _handleError(purchaseDetails.error!);
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
            purchaseDetails.status == PurchaseStatus.restored) {
          await _verifyPurchase(purchaseDetails);
        }
        if (purchaseDetails.pendingCompletePurchase) {
          await InAppPurchase.instance.completePurchase(purchaseDetails);
        }
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _handleError(IAPError error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Erreur de paiement: ${error.message}")),
    );
  }

  Future<void> _verifyPurchase(PurchaseDetails purchaseDetails) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final isValid = await _validatePurchase(purchaseDetails);
      if (isValid) {
        // Mise à jour de Firestore uniquement après validation du paiement
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'isSubscriptionActive': true,
          'numberOfCars': numberOfCars,
          'isAnnual': isAnnual,
          'subscriptionPrice': getPrice(),
          'purchaseToken': purchaseDetails.purchaseID,
        });
        setState(() {
          isSubscriptionActive = true;
        });
        _showSuccessDialog();
      } else {
        _handleError(IAPError(
          source: 'verifyPurchase',
          code: 'invalid_purchase',
          message: 'La vérification de l\'achat a échoué.',
        ));
      }
    }
  }

  // Ajouter cette méthode pour valider l'achat
  Future<bool> _validatePurchase(PurchaseDetails purchaseDetails) async {
    // Implémentez la logique de validation de l'achat ici
    // Par exemple, vous pouvez vérifier le reçu avec votre serveur
    // ou utiliser une API de validation d'achat
    return true; // Retourner true si l'achat est valide, sinon false
  }

  // Ajouter cette méthode pour afficher le popup de succès
  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            "Abonnement effectif",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF08004D),
            ),
          ),
          content: const Text(
            "Votre abonnement est effectif dès à présent.",
            style: TextStyle(
              fontSize: 18,
              color: Colors.black87,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                "OK",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF08004D),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handlePayment() async {
    if (numberOfCars <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                "L'offre gratuite est limitée à 1 voiture. Pour ajouter plus de voitures, veuillez souscrire à un abonnement.")),
      );
      return;
    }

    if (_products.isEmpty || _isLoading) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text("Erreur: Produit non disponible ou paiement en cours")),
      );
      return;
    }

    try {
      String? productId;
      String? androidProductId; // Ajout pour Android
      if (numberOfCars == 2) {
        productId = isAnnual
            ? 'contraloc.premium.2cars.yearly'
            : 'contraloc.premium.2cars.monthly';
        androidProductId = isAnnual
            ? 'contraloc-premium-2cars-year'
            : 'contraloc-premium-2cars-monthly';
      } else if (numberOfCars == 3) {
        productId = isAnnual
            ? 'contraloc.premium.3cars.yearly'
            : 'contraloc.premium.3cars.monthly';
        androidProductId = isAnnual
            ? 'contraloc-premium-3cars-yearly'
            : 'contraloc-premium-3cars-monthly';
      } else if (numberOfCars == 4) {
        productId = isAnnual
            ? 'contraloc.premium.4cars.yearly'
            : 'contraloc.premium.4cars.monthly';
        androidProductId = isAnnual
            ? 'contraloc-premium-4cars-yearly'
            : 'contraloc-premium-4cars-monthly';
      } else if (numberOfCars == 5) {
        productId = isAnnual
            ? 'contraloc.premium.5cars.yearly'
            : 'contraloc.premium.5cars.monthly';
        androidProductId = isAnnual
            ? 'contraloc-premium-5cars-yearly'
            : 'contraloc-premium-5cars-monthly';
      } else if (numberOfCars == 6) {
        productId = isAnnual
            ? 'contraloc.premium.6cars.yearly'
            : 'contraloc.premium.6cars.monthly';
        androidProductId = isAnnual
            ? 'contraloc-premium-6cars-yearly'
            : 'contraloc-premium-6cars-monthly';
      } else if (numberOfCars == 7) {
        productId = isAnnual
            ? 'contraloc.premium.7cars.yearly'
            : 'contraloc.premium.7cars.monthly';
        androidProductId = isAnnual
            ? 'contraloc-premium-7cars-yearly'
            : 'contraloc-premium-7cars-monthly';
      } else if (numberOfCars == 8) {
        productId = isAnnual
            ? 'contraloc.premium.8cars.yearly'
            : 'contraloc.premium.8cars.monthly';
        androidProductId = isAnnual
            ? 'contraloc-premium-8cars-yearly'
            : 'contraloc-premium-8cars-monthly';
      } else if (numberOfCars == 9) {
        productId = isAnnual
            ? 'contraloc.premium.9cars.yearly'
            : 'contraloc.premium.9cars.monthly';
        androidProductId = isAnnual
            ? 'contraloc-premium-9cars-yearly'
            : 'contraloc-premium-9cars-monthly';
      } else if (numberOfCars == 10) {
        productId = isAnnual
            ? 'contraloc.premium.10cars.yearly'
            : 'contraloc.premium.10cars.monthly';
        androidProductId = isAnnual
            ? 'contraloc-premium-10cars-yearly'
            : 'contraloc-premium-10cars-monthly';
      } else if (numberOfCars == 11) {
        productId = isAnnual
            ? 'contraloc.premium.11cars.yearly'
            : 'contraloc.premium.11cars.monthly';
        androidProductId = isAnnual
            ? 'contraloc-premium-11cars-yearly'
            : 'contraloc-premium-11cars-monthly';
      } else if (numberOfCars == 12) {
        productId = isAnnual
            ? 'contraloc.premium.12cars.yearly'
            : 'contraloc.premium.12cars.monthly';
        androidProductId = isAnnual
            ? 'contraloc-premium-12cars-yearly'
            : 'contraloc-premium-12cars-monthly';
      } else if (numberOfCars == 13) {
        productId = isAnnual
            ? 'contraloc.premium.13cars.yearly'
            : 'contraloc.premium.13cars.monthly';
        androidProductId = isAnnual
            ? 'contraloc-premium-13cars-yearly'
            : 'contraloc-premium-13cars-monthly';
      } else if (numberOfCars == 14) {
        productId = isAnnual
            ? 'contraloc.premium.14cars.yearly'
            : 'contraloc.premium.14cars.monthly';
        androidProductId = isAnnual
            ? 'contraloc-premium-14cars-yearly'
            : 'contraloc-premium-14cars-monthly';
      } else if (numberOfCars == 15) {
        productId = isAnnual
            ? 'contraloc.premium.15cars.yearly'
            : 'contraloc.premium.15cars.monthly';
        androidProductId = isAnnual
            ? 'contraloc-premium-15cars-yearly'
            : 'contraloc-premium-15cars-monthly';
      } else if (numberOfCars > 15) {
        productId = isAnnual
            ? 'contraloc.premium.unlimited.yearly'
            : 'contraloc.premium.unlimited.monthly';
        androidProductId = isAnnual
            ? 'contraloc-premium-unlimited-yearly'
            : 'contraloc-premium-unlimited-monthly';
      }

      if (productId == null) {
        throw Exception(
            'Produit non trouvé pour le nombre de voitures: $numberOfCars');
      }

      // Modification ici pour essayer d'abord l'ID Android puis l'ID iOS
      ProductDetails? product;
      try {
        product = _products.firstWhere((p) => p.id == androidProductId);
      } catch (e) {
        print('Produit Android non trouvé, essai avec iOS: $productId');
        try {
          product = _products.firstWhere((p) => p.id == productId);
        } catch (e) {
          print('Aucun produit trouvé pour: $productId ou $androidProductId');
          if (_products.isNotEmpty) {
            product = _products.first;
          } else {
            throw Exception('Aucun produit disponible');
          }
        }
      }

      print('Tentative d\'achat du produit: ${product.id}');

      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: product,
      );

      await _iap.buyNonConsumable(purchaseParam: purchaseParam);
      // Supprimer la mise à jour de l'état et de Firestore ici
      // La mise à jour se fera dans _verifyPurchase après confirmation du paiement
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur: $e")),
      );
    }
  }

  Future<void> _cancelSubscription() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'isSubscriptionActive': false,
        'numberOfCars': 1, // Réinitialiser à 1 voiture gratuite
        'isAnnual': false,
        'subscriptionPrice': 0.0,
      });
      setState(() {
        isSubscriptionActive = false;
        numberOfCars = 1;
        isAnnual = false;
      });
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
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF08004D),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isSubscriptionActive) ...[
                Card(
                  color: Colors.blue[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      "Pour changer d'offre, veuillez d'abord vous désabonner de votre abonnement actuel.",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.blue[900],
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
              // Offre de base
              Card(
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Offre de base",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "0 €",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFFC300),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text("- Contrat limit\u00e9 \u00e0 15"),
                      const Text("- 6 photos max par voiture"),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Offre premium
              Card(
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Offre premium",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "\u00c0 partir de 19.99 € / mois",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFFC300),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text("- Contrat illimit\u00e9"),
                      const Text("- Photos illimit\u00e9es"),
                      const Text("- Support prioritaire"),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Calcul dynamique
              Card(
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text(
                        "Calcul de votre abonnement",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        getFormattedPrice(),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF08004D),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            onPressed: isSubscriptionActive || numberOfCars <= 1
                                ? null
                                : () {
                                    setState(() {
                                      numberOfCars--;
                                    });
                                  },
                            icon: const Icon(Icons.remove_circle, size: 30),
                            color: Colors.red,
                            disabledColor: Colors.grey,
                          ),
                          const SizedBox(width: 20),
                          Text(
                            getCarDisplay(),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 20),
                          IconButton(
                            onPressed:
                                isSubscriptionActive || numberOfCars >= 16
                                    ? null
                                    : () {
                                        setState(() {
                                          numberOfCars++;
                                        });
                                      },
                            icon: const Icon(Icons.add_circle, size: 30),
                            color:
                                numberOfCars >= 16 ? Colors.grey : Colors.green,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Mensuel",
                            style: TextStyle(fontSize: 16),
                          ),
                          Switch(
                            value: isAnnual,
                            onChanged: (value) {
                              setState(() {
                                isAnnual = value;
                              });
                            },
                            activeColor: const Color(0xFF08004D),
                          ),
                          const Text(
                            "Annuel",
                            style: TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Payez au juste prix : vous ne paierez que pour le nombre de véhicules que vous possédez, ni plus, ni moins.",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF08004D),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "• Première voiture GRATUITE\n"
                "• 19.99€/mois à partir de 2 voitures\n"
                "• +3€/mois par voiture supplémentaire\n"
                "• 1 mois OFFERT avec l'abonnement annuel",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 50),
              ElevatedButton(
                onPressed: numberOfCars <= 1
                    ? null
                    : _handlePayment, // Désactiver le bouton pour 1 voiture
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  backgroundColor: const Color(0xFF08004D),
                  elevation: 5,
                  // Ajout de la couleur désactivée
                  disabledBackgroundColor: Colors.grey,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        numberOfCars <= 1
                            ? "Version gratuite active"
                            : "Valider mon abonnement",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
              if (isSubscriptionActive) ...[
                const SizedBox(height: 20),
                FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('users')
                      .doc(FirebaseAuth.instance.currentUser?.uid)
                      .get(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    }
                    final userData =
                        snapshot.data?.data() as Map<String, dynamic>?;
                    final userNumberOfCars = userData?['numberOfCars'] ?? 1;
                    return Text(
                      "Vous êtes actuellement inscrit à un abonnement de $userNumberOfCars voiture${userNumberOfCars > 1 ? 's' : ''}.",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF08004D),
                      ),
                      textAlign: TextAlign.center,
                    );
                  },
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _cancelSubscription,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    backgroundColor: Colors.red,
                    elevation: 5,
                  ),
                  child: const Text(
                    "Se désabonner",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
