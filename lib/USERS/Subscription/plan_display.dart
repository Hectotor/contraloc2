import 'dart:io';
import 'package:ContraLoc/USERS/Subscription/revenue_cat_service.dart';
import 'package:ContraLoc/USERS/Subscription/subscription_service.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ContraLoc/widget/chargement.dart';

class PlanData {
  final String title;
  final String price;
  final List<Map<String, dynamic>> features;

  PlanData({
    required this.title,
    required this.price,
    required this.features,
  });

  static List<PlanData> monthlyPlans = [
    PlanData(
      title: "Offre Gratuite",
      price: "0€/mois",
      features: [
        {"text": "1 voiture", "isAvailable": true},
        {"text": "Contrats illimités", "isAvailable": true},
        {"text": "États des lieux simplifiés", "isAvailable": true},
        {"text": "Suivi chiffres d'affaires", "isAvailable": true},
        {"text": "Prise de photos", "isAvailable": false},
        {"text": "Modification des conditions du contrat", "isAvailable": false},
        {"text": "Ajouter des collaborateurs", "isAvailable": false},
      ],
    ),
    PlanData(
      title: "Offre Premium Mensuelle",
      price: "19.99€/mois",
      features: [
        {"text": "10 voitures", "isAvailable": true},
        {"text": "Contrats illimités", "isAvailable": true},
        {"text": "États des lieux simplifiés", "isAvailable": true},
        {"text": "Suivi chiffres d'affaires", "isAvailable": true},
        {"text": "Prise de photos", "isAvailable": true},
        {"text": "Modification des conditions du contrat", "isAvailable": true},
        {"text": "Ajouter des collaborateurs", "isAvailable": false},
      ],
    ),
    PlanData(
      title: "Offre Platinum Mensuelle",
      price: "39.99€/mois",
      features: [
        {"text": "20 voitures", "isAvailable": true},
        {"text": "Contrats illimités", "isAvailable": true},
        {"text": "États des lieux simplifiés", "isAvailable": true},
        {"text": "Suivi chiffres d'affaires", "isAvailable": true},
        {"text": "Prise de photos", "isAvailable": true},
        {"text": "Modification des conditions du contrat", "isAvailable": true},
        {"text": "Ajouter des collaborateurs", "isAvailable": true},
      ],
    ),
  ];

  static List<PlanData> yearlyPlans = [
    PlanData(
      title: "Offre Gratuite",
      price: "0€/an",
      features: [
        {"text": "1 voiture", "isAvailable": true},
        {"text": "Contrats illimités", "isAvailable": true},
        {"text": "États des lieux simplifiés", "isAvailable": true},
        {"text": "Suivi chiffres d'affaires", "isAvailable": true},
        {"text": "Prise de photos", "isAvailable": false},
        {"text": "Modification des conditions du contrat", "isAvailable": false},
        {"text": "Ajouter des collaborateurs", "isAvailable": false},
      ],
    ),
    PlanData(
      title: "Offre Premium Annuelle",
      price: "239.99€/an",
      features: [
        {"text": "10 voitures", "isAvailable": true},
        {"text": "Contrats illimités", "isAvailable": true},
        {"text": "États des lieux simplifiés", "isAvailable": true},
        {"text": "Suivi chiffres d'affaires", "isAvailable": true},
        {"text": "Prise de photos", "isAvailable": true},
        {"text": "Modification des conditions du contrat", "isAvailable": true},
        {"text": "Ajouter des collaborateurs", "isAvailable": false},
      ],
    ),
    PlanData(
      title: "Offre Platinum Annuelle",
      price: "479.99€/an",
      features: [
        {"text": "20 voitures", "isAvailable": true},
        {"text": "Contrats illimités", "isAvailable": true},
        {"text": "États des lieux simplifiés", "isAvailable": true},
        {"text": "Suivi chiffres d'affaires", "isAvailable": true},
        {"text": "Prise de photos", "isAvailable": true},
        {"text": "Modification des conditions du contrat", "isAvailable": true},
        {"text": "Ajouter des collaborateurs", "isAvailable": true},
      ],
    ),
  ];
}

class PlanDisplay extends StatefulWidget {
  final bool isMonthly;
  final String currentEntitlement;
  final Function(String) onSubscribe;
  final ValueChanged<int>? onPageChanged;

  const PlanDisplay({
    Key? key,
    required this.isMonthly,
    required this.currentEntitlement,
    required this.onSubscribe,
    this.onPageChanged,
  }) : super(key: key);

  @override
  State<PlanDisplay> createState() => PlanDisplayState();
}

class PlanDisplayState extends State<PlanDisplay> {
  bool isProcessing = false;
  Map<String, bool> activePlans = {};

  @override
  void initState() {
    super.initState();
    _checkActivePlans();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _checkActivePlans() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('authentification')
            .doc(user.uid)
            .get();

        if (userDoc.exists && mounted) {
          String? cb_subscription = userDoc.data()?['cb_subscription'];
          String? subscription_id = userDoc.data()?['subscriptionId'];
          print(' Firebase cb_subscription: $cb_subscription');
          print(' Firebase subscriptionId: $subscription_id');

          setState(() {
            // Reset all plans to false first
            activePlans.clear();
            activePlans["Offre Premium Mensuelle"] = false;
            activePlans["Offre Premium Annuelle"] = false;
            activePlans["Offre Gratuite"] = false;
            activePlans["Offre Platinum Mensuelle"] = false;
            activePlans["Offre Platinum Annuelle"] = false;

            // On prend l'abonnement le plus élevé entre les deux sources
            bool isPremiumMonthly = cb_subscription == 'premium-monthly_access' || subscription_id == 'premium-monthly_access';
            bool isPremiumYearly = cb_subscription == 'premium-yearly_access' || subscription_id == 'premium-yearly_access';
            bool isPlatinumMonthly = cb_subscription == 'platinum-monthly_access' || subscription_id == 'platinum-monthly_access';
            bool isPlatinumYearly = cb_subscription == 'platinum-yearly_access' || subscription_id == 'platinum-yearly_access';

            // Set only the active plan to true
            if (isPlatinumMonthly) {
              activePlans["Offre Platinum Mensuelle"] = true;
            } 
            else if (isPlatinumYearly) {
              activePlans["Offre Platinum Annuelle"] = true;
            }
            else if (isPremiumMonthly) {
              activePlans["Offre Premium Mensuelle"] = true;
            } 
            else if (isPremiumYearly) {
              activePlans["Offre Premium Annuelle"] = true;
            }
            else {
              activePlans["Offre Gratuite"] = true;
            }
          });
        }
      } catch (e) {
        print('Erreur lors de la vérification des plans: $e');
      }
    }
  }

  Widget _buildFeatureRow(Map<String, dynamic> feature) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            feature['isAvailable'] ? Icons.check : Icons.close,
            color: feature['isAvailable'] ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              feature['text'],
              style: TextStyle(
                color: feature['isAvailable'] ? Colors.black : Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(PlanData plan) {
    bool isActivePlan = activePlans[plan.title] ?? false;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 3,
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: Colors.white,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  plan.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF08004D),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  plan.price,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFFC300),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView(
              children: plan.features.map(_buildFeatureRow).toList(),
            ),
          ),
          const SizedBox(height: 24),
          if (plan.title == "Offre Gratuite" && !isActivePlan)
            Text(
              '',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
                fontStyle: FontStyle.italic,
              ),
            )
          else
            ElevatedButton(
              onPressed: isActivePlan
                  ? null
                  : () async {
                      await _handleSubscription(plan.title);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: isActivePlan
                    ? const Color(0xFFE53935)
                    : const Color(0xFF08004D),
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                isActivePlan ? "Offre actuelle" : "Choisir cette offre",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          const SizedBox(height: 30), // Augmenté de 16 à 30
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final plans =
        widget.isMonthly ? PlanData.monthlyPlans : PlanData.yearlyPlans;

    return Column(
      children: [
        Expanded(
          child: AbsorbPointer(
            absorbing: isProcessing, // Simplification ici
            child: CarouselSlider.builder(
              itemCount: plans.length,
              options: CarouselOptions(
                height: 600,
                enlargeCenterPage: true,
                onPageChanged: (index, reason) {
                  if (widget.onPageChanged != null) {
                    widget.onPageChanged!(index);
                  }
                },
              ),
              itemBuilder: (context, index, realIndex) {
                final plan = plans[index];
                return _buildPlanCard(plan); // On passe seulement le plan
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentButton({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF08004D)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF08004D)),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF08004D),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleStripePayment(String planTitle, bool isMonthly) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // S'assurer que l'utilisateur est identifié dans RevenueCat
      await RevenueCatService.login(user.uid);
      
      // Construire l'URL Stripe avec les metadata utilisateur
      String baseUrl;
      if (planTitle.contains("Premium") && !planTitle.contains("Platinum")) {
        baseUrl = isMonthly
            ? "https://buy.stripe.com/9AQ7wl1pKc8J41O28b"  // Premium mensuel
            : "https://buy.stripe.com/aEUcQFb0kc8Jbug5kk";  // Premium annuel
      } else if (planTitle.contains("Platinum")) {
        baseUrl = isMonthly
            ? "https://buy.stripe.com/28o9EtgkEa0BaqcfZ0"  // Platinum mensuel
            : "https://buy.stripe.com/6oE4k92tOdcN8i4145";      // Platinum annuel
      } else {
        // Offre gratuite ou autre
        baseUrl = "https://buy.stripe.com/9AQ7wl1pKc8J41O28b";  // Redirection vers Premium mensuel par défaut
      }

      // Créer l'URL avec les paramètres
      final uri = Uri.parse(baseUrl).replace(
        queryParameters: {
          'client_reference_id': user.uid,
          'prefilled_email': user.email,  // Ajouter l'email si disponible
        },
      );

      // Ouvrir le lien dans le navigateur externe
      if (!await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
        webViewConfiguration: const WebViewConfiguration(
          enableJavaScript: true,
          enableDomStorage: true,
        ),
      )) {
        print('❌ Erreur lors de l\'ouverture du lien: ${uri.toString()}');
      } else {
        print('✅ Lien Stripe ouvert: ${uri.toString()}');
        
        // Vérifier périodiquement le statut de l'abonnement
        Timer.periodic(Duration(seconds: 5), (timer) async {
          await _checkActivePlans();
          
          // Arrêter la vérification après 5 minutes
          if (timer.tick >= 60) {
            timer.cancel();
          }
        });
      }
    } catch (e) {
      print('❌ Exception lors de l\'ouverture du lien: $e');
    }
  }

  Widget _buildPaymentDialog(String plan) {
    bool isMonthly = !plan.toLowerCase().contains("annuel");
    
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  spreadRadius: 5,
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.payment_rounded,
                  size: 48,
                  color: Color(0xFF08004D),
                ),
                const SizedBox(height: 24),
                const Text(
                  "Choisissez votre moyen de paiement",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF08004D),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Pour ${plan.toLowerCase()}",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 32),
                /*if (Platform.isIOS)
                  _buildPaymentButton(
                    icon: Icons.apple,
                    title: "Apple Pay",
                    onTap: () async {
                      try {
                        final canUseApplePay = await Purchases.canMakePayments();
                        if (!canUseApplePay) {
                          throw PlatformException(
                            code: 'apple_pay_not_available',
                            message: 'Apple Pay n\'est pas disponible sur cet appareil',
                          );
                        }
                        Navigator.pop(context);
                        await _processPayment(plan);
                      } catch (e) {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Erreur'),
                            content: Text(e.toString()),
                            actions: [
                              TextButton(
                                child: const Text('OK'),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ],
                          ),
                        );
                      }
                    },
                  ),
                if (Platform.isAndroid)
                  _buildPaymentButton(
                    icon: Icons.payment,
                    title: "Google Pay",
                    onTap: () async {
                      try {
                        final canUseGooglePay = await Purchases.canMakePayments();
                        if (!canUseGooglePay) {
                          throw PlatformException(
                            code: 'google_pay_not_available',
                            message: 'Google Pay n\'est pas disponible sur cet appareil',
                          );
                        }
                        Navigator.pop(context);
                        await _processPayment(plan);
                      } catch (e) {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Erreur'),
                            content: Text(e.toString()),
                            actions: [
                              TextButton(
                                child: const Text('OK'),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ],
                          ),
                        );
                      }
                    },
                  ),*/
                _buildPaymentButton(
                  icon: Icons.credit_card,
                  title: "Carte bancaire",
                  onTap: () {
                    Navigator.pop(context);
                    _handleStripePayment(plan, isMonthly);
                  },
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Annuler',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _processPayment(String plan) async {
    try {
      // Afficher le dialogue de chargement personnalisé
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) => const Chargement(),
      );

      final customerInfo = await RevenueCatService.purchaseProduct(
        plan, 
        !plan.toLowerCase().contains("annuel")
      );

      // Fermer le dialogue de chargement
      Navigator.of(context).pop();

      if (customerInfo != null) {
        // D'abord mettre à jour les données dans Firestore
        print('👤 Mise à jour du statut dans Firestore...');
        await SubscriptionService.updateSubscriptionStatus();
        print('✅ Firestore mis à jour');

        // Ensuite vérifier les plans pour l'affichage
        print('🔄 Actualisation de l\'affichage...');
        await _checkActivePlans();
        print('✅ Affichage actualisé');

        // Afficher le dialogue de succès
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      color: Colors.green,
                      size: 80,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Félicitations !',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Votre abonnement a été activé avec succès.',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 12,
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text(
                        'Continuer',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }
    } catch (e) {
      // Fermer l'indicateur de chargement s'il est affiché
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      // Afficher l'erreur
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Erreur'),
            content: Text('Une erreur est survenue lors du paiement : $e'),
            actions: [
              TextButton(
                child: const Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          );
        },
      );
    }
  }


  // Modifier la méthode _handleSubscription pour afficher le dialogue
  Future<void> _handleSubscription(String plan) async {
    if (plan == "Offre Gratuite") {
      await widget.onSubscribe(plan);
      return;
    }

    await showDialog(
      context: context,
      builder: (context) => _buildPaymentDialog(plan),
    );
  }
}
