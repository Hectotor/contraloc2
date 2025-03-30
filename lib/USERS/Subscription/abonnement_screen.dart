import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'revenue_cat_service.dart';
import '../question_user.dart';
import 'plan_display.dart';
import 'stripe_payment_handler.dart';

class AbonnementScreen extends StatefulWidget {
  const AbonnementScreen({Key? key}) : super(key: key);
  @override
  State<AbonnementScreen> createState() => _AbonnementScreenState();
}

class _AbonnementScreenState extends State<AbonnementScreen> {
  bool isMonthly = true;
  bool _isLoading = false;
  String _currentEntitlement = '';
  bool _isTestMode = true; // Variable pour le mode test

  @override
  void initState() {
    super.initState();
    _checkCurrentEntitlement();
  }

  Future<void> _checkCurrentEntitlement() async {
    final customerInfo = await RevenueCatService.checkEntitlements();
    if (customerInfo != null && mounted) {
      final activeEntitlements = customerInfo.entitlements.active.keys;
      setState(() {
        if (activeEntitlements.contains('premium-monthly_access')) {
          _currentEntitlement = 'premium-monthly_access';
        } else if (activeEntitlements.contains('premium-yearly_access')) {
          _currentEntitlement = 'premium-yearly_access';
        } else if (activeEntitlements.contains('platinum-monthly_access')) {
          _currentEntitlement = 'platinum-monthly_access';
        } else if (activeEntitlements.contains('platinum-yearly_access')) {
          _currentEntitlement = 'platinum-yearly_access';
        } else {
          _currentEntitlement = 'free';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, 
      appBar: AppBar(
        backgroundColor: const Color(0xFF08004D),
        iconTheme: const IconThemeData(
            color: Colors.white), 
        centerTitle: true, 
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildToggleButton(true, "Mensuelle", Icons.calendar_today),
            _buildToggleButton(false, "Annuelle", Icons.calendar_month),
          ],
        ),
      ),
      body: Container(
        color: Colors.white, 
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: PlanDisplay(
                    isMonthly: isMonthly,
                    currentEntitlement: _currentEntitlement,
                    onSubscribe: (plan) async {
                      // Déterminer l'ID du produit Stripe en fonction du plan et de la période
                      String productId;
                      if (plan.contains('Premium')) {
                        if (isMonthly) {
                          productId = 'prod_RiIVqYAhJGzB0u'; // Premium Mensuel
                        } else {
                          productId = 'prod_RiIXsD22K4xehY'; // Premium Annuel
                        }
                      } else if (plan.contains('Platinum')) {
                        if (isMonthly) {
                          // Utiliser l'ID de test ou de production selon l'environnement
                          // TODO: Ajouter une variable d'environnement pour déterminer si on est en test ou en production
                          bool isTestEnvironment = _isTestMode; // Mettre à false en production
                          
                          if (isTestEnvironment) {
                            productId = 'prod_S27nF635Z0AoFs'; // Platinum Mensuel (test)
                          } else {
                            productId = 'prod_S26yXish2BNayF'; // Platinum Mensuel (production)
                          }
                        } else {
                          productId = 'prod_S26xbnrxhZn6TT'; // Platinum Annuel
                        }
                      } else {
                        // Plan gratuit ou autre
                        return;
                      }
                      
                      print('🔄 Lancement du processus de paiement Stripe pour le plan: $plan');
                      print('🔄 ID du produit: $productId, Mensuel: $isMonthly');
                      
                      try {
                        final user = FirebaseAuth.instance.currentUser;
                        if (user == null) {
                          throw Exception('Utilisateur non connecté');
                        }
                        
                        // Appeler la méthode de paiement Stripe
                        await StripePaymentHandler.purchaseProductWithStripe(
                          context: context,
                          userId: user.uid,
                          productId: productId,
                          plan: plan,
                          isMonthly: isMonthly,
                        );
                      } catch (e) {
                        print('❌ Erreur lors du processus de paiement: $e');
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Erreur: $e')),
                          );
                        }
                      }
                    }, 
                    onPageChanged: (index) {
                      // Gérer le changement de page si nécessaire
                    },
                  ),
                ),

                // Bouton pour basculer entre mode test et production
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Mode: ${_isTestMode ? "Test" : "Production"}', 
                           style: TextStyle(color: _isTestMode ? Colors.orange : Colors.green)),
                      Switch(
                        value: _isTestMode,
                        activeColor: Colors.orange,
                        inactiveThumbColor: Colors.green,
                        onChanged: (value) {
                          setState(() {
                            _isTestMode = value;
                          });
                          // Afficher un message pour confirmer le changement de mode
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Mode ${_isTestMode ? "Test" : "Production"} activé'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.only(bottom: 20.0),
                  child: TextButton.icon(
                    onPressed: () {
                      if (!mounted) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const QuestionUser()),
                      );
                    },
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
                  ),
                ),
              ],
            ),
            if (_isLoading)
              Container(
                color: Colors.black54,
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleButton(bool isMonthlyButton, String text, IconData icon) {
    final bool isSelected = isMonthly == isMonthlyButton;
    return InkWell(
      onTap: () => setState(() => isMonthly = isMonthlyButton),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : const Color(0xFF08004D),
          borderRadius: BorderRadius.horizontal(
            left: Radius.circular(isMonthlyButton ? 12 : 0),
            right: Radius.circular(!isMonthlyButton ? 12 : 0),
          ),
          border: Border.all(
            color: isSelected ? const Color(0xFF08004D) : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF08004D) : Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(
                color: isSelected ? const Color(0xFF08004D) : Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
