import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore

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
        {"text": "10 contrats/mois", "isAvailable": true},
        {"text": "États des lieux sans photos", "isAvailable": true},
        {"text": "Prise de photos", "isAvailable": false},
      ],
    ),
    PlanData(
      title: "Offre Pro",
      price: "9.99€/mois",
      features: [
        {"text": "5 voitures", "isAvailable": true},
        {"text": "10 contrats/mois", "isAvailable": true},
        {"text": "États des lieux simplifiés", "isAvailable": true},
        {"text": "Prise de photos", "isAvailable": false},
      ],
    ),
    PlanData(
      title: "Offre Premium",
      price: "19.99€/mois",
      features: [
        {"text": "Voitures illimitées", "isAvailable": true},
        {"text": "Contrats illimités", "isAvailable": true},
        {"text": "États des lieux simplifiés", "isAvailable": true},
        {"text": "Prise de photos", "isAvailable": true},
        {"text": "Modification des conditions du contrat", "isAvailable": true},
      ],
    ),
  ];

  static List<PlanData> yearlyPlans = [
    // Version annuelle des plans avec les mêmes features mais prix différents
    PlanData(
      title: "Offre Gratuite",
      price: "0€/an",
      features: [
        {"text": "1 voiture", "isAvailable": true},
        {"text": "10 contrats/mois", "isAvailable": true},
        {"text": "États des lieux simplifiés", "isAvailable": true},
        {"text": "Prise de photos", "isAvailable": false},
      ],
    ),
    PlanData(
      title: "Offre Pro Annuel", // Assurez-vous que le titre correspond
      price: "119.99€/an",
      features: [
        {"text": "5 voitures", "isAvailable": true},
        {"text": "10 contrats/mois", "isAvailable": true},
        {"text": "États des lieux simplifiés", "isAvailable": true},
        {"text": "Prise de photos", "isAvailable": false},
      ],
    ),
    PlanData(
      title: "Offre Premium Annuel", // Assurez-vous que le titre correspond
      price: "239.99€/an",
      features: [
        {"text": "Voitures illimitées", "isAvailable": true},
        {"text": "Contrats illimités", "isAvailable": true},
        {"text": "États des lieux simplifiés", "isAvailable": true},
        {"text": "Prise de photos", "isAvailable": true},
        {"text": "Modification des conditions du contrat", "isAvailable": true},
      ],
    ),
  ];
}

// Remplacer "class PlanDisplay extends StatelessWidget" par:
class PlanDisplay extends StatefulWidget {
  final bool isMonthly;
  final String currentSubscriptionName;
  final Function(String) onSubscribe;
  final ValueChanged<int>? onPageChanged;
  final int currentIndex;
  final String subscriptionId; // Ajouter ce paramètre
  final String? lastSyncDate; // Ajouter ce paramètre

  const PlanDisplay({
    Key? key,
    required this.isMonthly,
    required this.currentSubscriptionName,
    required this.onSubscribe,
    this.onPageChanged,
    required this.currentIndex,
    required this.subscriptionId, // Ajouter ce paramètre
    this.lastSyncDate, // Ajouter ce paramètre
  }) : super(key: key);

  @override
  State<PlanDisplay> createState() =>
      PlanDisplayState(); // Enlever l'underscore
}

class PlanDisplayState extends State<PlanDisplay> {
  bool isProcessing = false;
  String? _previousLastSyncDate;
  // Suppression de showActivationMessage

  @override
  void initState() {
    super.initState();
    // Suppression de _loadActivationStartTime
  }

  @override
  void didUpdateWidget(PlanDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.subscriptionId != oldWidget.subscriptionId) {
      _checkAndResetActivation();
    }
    if (widget.lastSyncDate != _previousLastSyncDate &&
        widget.lastSyncDate != null) {
      _previousLastSyncDate = widget.lastSyncDate;
      _resetAllState();
    }
    // Vérifier si la synchronisation est terminée
    if (widget.lastSyncDate != _previousLastSyncDate) {
      _previousLastSyncDate = widget.lastSyncDate;
      if (mounted) {
        setState(() {
          isProcessing = false;
        });
      }
    }
  }

  @override
  void dispose() {
    // Suppression de _activationTimer?.cancel()
    super.dispose();
  }

  Future<void> _checkAndResetActivation() async {
    if (widget.subscriptionId != 'free') {
      if (mounted) {
        setState(() {
          isProcessing = false;
        });
      }
    }
  }

  void _resetAllState() {
    if (mounted) {
      setState(() {
        isProcessing = false;
      });
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

  Widget _buildPlanCard(PlanData plan, bool isActive) {
    // Comparer le nom du plan avec le planName actuel de l'utilisateur
    bool isActivePlan = widget.subscriptionId == 'free'
        ? plan.title == "Offre Gratuite"
        : plan.title == widget.currentSubscriptionName;

    // Debug pour vérification
    print('Plan: ${plan.title}');
    print('Current subscription name: ${widget.currentSubscriptionName}');
    print('Is active: $isActivePlan');

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 20, vertical: 0), // Augmenter le padding vertical
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 15,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
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
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF08004D),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  plan.price,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFFC300),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: plan.features.map(_buildFeatureRow).toList(),
            ),
          ),
          const SizedBox(height: 16),
          if (plan.title == "Offre Gratuite" && !isActivePlan)
            Text(
              'Veuillez utiliser le bouton\n"Gérer mon abonnement"',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
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

    // Supprimer les logs de débogage ici
    return Column(
      children: [
        Expanded(
          child: AbsorbPointer(
            absorbing: isProcessing &&
                widget.subscriptionId != 'free', // Modification ici
            child: CarouselSlider.builder(
              itemCount: plans.length,
              options: CarouselOptions(
                height: 400,
                enlargeCenterPage: true,
                onPageChanged: (index, reason) {
                  if (widget.onPageChanged != null) {
                    widget.onPageChanged!(index);
                  }
                },
              ),
              itemBuilder: (context, index, realIndex) {
                final plan = plans[index];
                final isActive = widget.currentSubscriptionName == plan.title;
                return _buildPlanCard(plan, isActive);
              },
            ),
          ),
        ),
        // Suppression de showActivationMessage
      ],
    );
  }

  Future<void> _handleSubscription(String plan) async {
    setState(() {
      isProcessing = true;
    });

    try {
      await widget.onSubscribe(plan);
      if (plan != "Offre Gratuite" && mounted) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          // Attendre que Firestore soit mis à jour
          await Future.delayed(const Duration(seconds: 2));

          final doc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('authentification')
              .doc(user.uid)
              .get();

          if (doc.exists) {
            final data = doc.data();
            if (data?['lastKnownProductId'] != null) {
              // Suppression de showActivationMessage
              await _updateActivationStartTimeInFirestore();
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isProcessing = false;
          // Suppression de showActivationMessage
        });
      }
    }
  }

  // Suppression de startActivationTimer

  // Suppression de _loadActivationStartTime

  Future<void> _updateActivationStartTimeInFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('authentification')
        .doc(user.uid)
        .update({
      // Suppression de 'activationStartTime'
    });
  }
}
