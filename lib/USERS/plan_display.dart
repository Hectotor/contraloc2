import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

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
  State<PlanDisplay> createState() => _PlanDisplayState();
}

class _PlanDisplayState extends State<PlanDisplay> {
  bool isProcessing = false;
  DateTime? _lastPaymentTime;
  Timer? _timer;
  int _remainingMinutes = 60; // Changé de 30 à 60
  int _remainingSeconds = 0;
  static const int lockDurationMinutes =
      60; // Changé de 65 à 60 pour correspondre au timer
  static const String LAST_PAYMENT_KEY = 'last_payment_timestamp';
  String? _previousLastSyncDate;

  @override
  void initState() {
    super.initState();
    _loadLastPaymentTime();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(PlanDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Vérifier si l'abonnement a changé
    if (widget.subscriptionId != oldWidget.subscriptionId) {
      _checkAndResetActivation();
    }
    // Si lastSyncDate a changé, on réinitialise tout
    if (widget.lastSyncDate != _previousLastSyncDate &&
        widget.lastSyncDate != null) {
      _previousLastSyncDate = widget.lastSyncDate;
      _resetAllState();
    }
  }

  Future<void> _checkAndResetActivation() async {
    // Si l'ID d'abonnement n'est plus 'free', cela signifie que l'activation est terminée
    if (widget.subscriptionId != 'free') {
      // Arrêter le timer
      _timer?.cancel();
      // Réinitialiser le timestamp
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(LAST_PAYMENT_KEY);

      if (mounted) {
        setState(() {
          _lastPaymentTime = null;
          _remainingMinutes = 0;
          _remainingSeconds = 0;
        });
      }
    }
  }

  Future<void> _loadLastPaymentTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(LAST_PAYMENT_KEY);
    if (timestamp != null) {
      setState(() {
        _lastPaymentTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
        _startTimer();
      });
    }
  }

  Future<void> _saveLastPaymentTime(DateTime time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(LAST_PAYMENT_KEY, time.millisecondsSinceEpoch);
    _startTimer(); // Démarrer le timer après la sauvegarde
  }

  void _startTimer() {
    _timer?.cancel();
    final endTime =
        _lastPaymentTime!.add(const Duration(minutes: 60)); // Changé de 30 à 60

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;

      final remaining = endTime.difference(DateTime.now());
      if (remaining.isNegative) {
        timer.cancel();
        setState(() {
          _remainingMinutes = 0;
          _remainingSeconds = 0;
        });
        return;
      }

      setState(() {
        _remainingMinutes = remaining.inMinutes;
        _remainingSeconds = remaining.inSeconds % 60;
      });
    });
  }

  bool get _isButtonsLocked {
    if (_lastPaymentTime == null) return false;
    if (widget.subscriptionId != 'free') return false;
    final difference = DateTime.now().difference(_lastPaymentTime!);
    return difference.inMinutes <
        lockDurationMinutes; // Maintenant synchronisé avec le timer de 60 minutes
  }

  bool get _showProcessingMessage {
    if (_lastPaymentTime == null) return false;
    // Ajouter une vérification supplémentaire pour l'état de l'abonnement
    if (widget.subscriptionId != 'free') return false;
    final difference = DateTime.now().difference(_lastPaymentTime!);
    return difference.inMinutes < 60; // Changé de 30 à 60
  }

  void _resetAllState() {
    _timer?.cancel();
    SharedPreferences.getInstance().then((prefs) {
      prefs.remove(LAST_PAYMENT_KEY);
    });

    if (mounted) {
      setState(() {
        _lastPaymentTime = null;
        _remainingMinutes = 0;
        _remainingSeconds = 0;
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
    bool isActivePlan = widget.currentSubscriptionName == plan.title;

    return Container(
      // Remplacé Stack par Container
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
              onPressed: (isActivePlan || isProcessing || _isButtonsLocked)
                  ? null
                  : () {
                      setState(() {
                        isProcessing = true;
                      });
                      widget.onSubscribe(plan.title).then((_) {
                        final now = DateTime.now();
                        setState(() {
                          if (mounted) {
                            isProcessing = false;
                            _lastPaymentTime = now;
                          }
                        });
                        _saveLastPaymentTime(now); // Sauvegarder le timestamp
                      }).catchError((_) {
                        setState(() {
                          if (mounted) {
                            isProcessing = false;
                          }
                        });
                      });
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: isActivePlan
                    ? const Color(0xFFE53935) // Rouge pour l'offre actuelle
                    : const Color(0xFF08004D),
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                isActivePlan
                    ? "Offre actuelle"
                    : "Choisir cette offre", // Supprimé la condition _isButtonsLocked
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

    return Column(
      children: [
        if (_showProcessingMessage)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.orange[800]!,
                  Colors.orange[600]!,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.access_time,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "En cours d'activation...",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Temps restant : $_remainingMinutes:${_remainingSeconds.toString().padLeft(2, '0')}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        Expanded(
          child: AbsorbPointer(
            absorbing: isProcessing,
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
      ],
    );
  }
}
