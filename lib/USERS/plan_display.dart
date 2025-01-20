import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';

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

  const PlanDisplay({
    Key? key,
    required this.isMonthly,
    required this.currentSubscriptionName,
    required this.onSubscribe,
    this.onPageChanged,
    required this.currentIndex,
  }) : super(key: key);

  @override
  State<PlanDisplay> createState() => _PlanDisplayState();
}

class _PlanDisplayState extends State<PlanDisplay> {
  // Déplacer les autres méthodes ici, en remplaçant les références directes aux propriétés
  // par widget.propriété (ex: widget.currentSubscriptionName)

  bool _hasActiveSubscription() {
    // Implement your logic to check if there is an active subscription
    return widget.currentSubscriptionName.isNotEmpty;
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
    // Corrigeons la logique pour déterminer si c'est le plan actif
    bool isActivePlan = widget.currentSubscriptionName == plan.title;

    // Si c'est l'offre gratuite, elle n'est active que si currentSubscriptionName est "Offre Gratuite"
    if (plan.title == "Offre Gratuite") {
      isActivePlan = widget.currentSubscriptionName == "Offre Gratuite";
    }

    // Vérifiez si le plan actuel correspond au type d'abonnement (mensuel ou annuel)
    if (plan.title.contains("Pro") &&
        widget.currentSubscriptionName.contains("Pro")) {
      isActivePlan = (widget.isMonthly && plan.title == "Offre Pro") ||
          (!widget.isMonthly && plan.title == "Offre Pro Annuel");
    } else if (plan.title.contains("Premium") &&
        widget.currentSubscriptionName.contains("Premium")) {
      isActivePlan = (widget.isMonthly && plan.title == "Offre Premium") ||
          (!widget.isMonthly && plan.title == "Offre Premium Annuel");
    }

    return Container(
      padding: const EdgeInsets.all(20),
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
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white, // Changé en blanc
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
          if (plan.title == "Offre Gratuite" && _hasActiveSubscription())
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Veuillez d\'abord annuler votre abonnement actuel',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else
            ElevatedButton(
              onPressed: isActivePlan
                  ? null
                  : () {
                      widget.onSubscribe(plan.title);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isActivePlan ? Colors.grey : const Color(0xFF08004D),
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                isActivePlan ? "Plan actuel" : "Souscrire",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final plans =
        widget.isMonthly ? PlanData.monthlyPlans : PlanData.yearlyPlans;

    return CarouselSlider.builder(
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
    );
  }
}
