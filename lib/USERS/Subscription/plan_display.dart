import 'package:ContraLoc/USERS/Subscription/revenue_cat_service.dart';
import 'package:ContraLoc/USERS/Subscription/subscription_service.dart';
import 'package:ContraLoc/USERS/Subscription/subscription_handler.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:ContraLoc/widget/chargement.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  bool hasPremiumSubscription = false;

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
            
            // Vérifier si l'utilisateur a un abonnement premium via cb_subscription
            hasPremiumSubscription = (cb_subscription == 'premium-monthly_access' || 
                                     cb_subscription == 'premium-yearly_access' ||
                                     cb_subscription == 'platinum-monthly_access' ||
                                     cb_subscription == 'platinum-yearly_access');

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

  // Modifier la méthode _handleSubscription pour utiliser SubscriptionHandler
  Future<void> _handleSubscription(String plan) async {
    await SubscriptionHandler.handleSubscription(
      context: context,
      plan: plan,
      hasPremiumSubscription: hasPremiumSubscription,
      setProcessingState: (bool value) {
        setState(() {
          isProcessing = value;
        });
      },
      onSubscribe: (String planTitle) async {
        await widget.onSubscribe(planTitle);
      },
    );
  }
}
