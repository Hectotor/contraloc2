import 'dart:io';

import 'package:ContraLoc/services/revenue_cat_service.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/services.dart';
import 'dart:async';

import 'package:purchases_flutter/purchases_flutter.dart';

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

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
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
    // Déterminer si le plan est actif en fonction de l'entitlement
    bool isActivePlan = false;
    if (plan.title == "Offre Premium" || plan.title == "Offre Premium Annuel") {
      isActivePlan = widget.currentEntitlement == 'premium-monthly_access' ||
                    widget.currentEntitlement == 'premium-yearly_access';
    } else if (plan.title == "Offre Pro" || plan.title == "Offre Pro Annuel") {
      isActivePlan = widget.currentEntitlement == 'pro-monthly_access' ||
                    widget.currentEntitlement == 'pro-yearly_access';
    } else if (plan.title == "Offre Gratuite") {
      isActivePlan = widget.currentEntitlement == 'free';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 0),
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

    return Column(
      children: [
        Expanded(
          child: AbsorbPointer(
            absorbing: isProcessing, // Simplification ici
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

  Widget _buildPaymentDialog(String plan) {
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
                if (Platform.isIOS) ...[
                  _buildPaymentButton(
                    icon: Icons.apple,
                    title: "Apple Pay",
                    onTap: () => _processPayment(plan, 'apple_pay'),
                  ),
                ] else if (Platform.isAndroid) ...[
                  _buildPaymentButton(
                    icon: Icons.payment,
                    title: "Google Pay",
                    onTap: () => _processPayment(plan, 'google_pay'),
                  ),
                ],
                const SizedBox(height: 12),
                _buildPaymentButton(
                  icon: Icons.credit_card,
                  title: "Carte bancaire",
                  onTap: () => _processPayment(plan, 'card'),
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
                    "Annuler",
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isProcessing)
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _processPayment(String plan, String method) async {
    if (!mounted) return;

    // Afficher un dialogue de chargement
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xFF08004D)),
                    strokeWidth: 3,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Traitement en cours...",
                    style: TextStyle(
                      color: Color(0xFF08004D),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    try {
      setState(() => isProcessing = true);

      // Fermer le popup de méthode de paiement
      Navigator.of(context).pop();

      if (method == 'apple_pay' && Platform.isIOS) {
        final canUseApplePay = await Purchases.canMakePayments();
        if (!canUseApplePay) {
          throw PlatformException(
            code: 'apple_pay_not_available',
            message: 'Apple Pay n\'est pas disponible sur cet appareil',
          );
        }
      }

      final customerInfo = await RevenueCatService.purchaseProduct(
        plan, 
        widget.isMonthly, 
        paymentMethod: method
      );

      // Fermer le dialogue de chargement
      if (mounted) Navigator.of(context).pop();

      if (mounted && customerInfo != null) {
        widget.onSubscribe(plan);
      }
    } catch (e) {
      // Fermer le dialogue de chargement en cas d'erreur
      if (mounted) Navigator.of(context).pop();

      print('❌ Erreur paiement: $e');
      if (mounted) {
        _showError(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => isProcessing = false);
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    Navigator.of(context).pop(); // Utiliser Navigator.of(context)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
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
