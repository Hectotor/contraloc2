import 'package:ContraLoc/services/subscription_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show PlatformException;
import '../services/revenue_cat_service.dart';
import 'question_user.dart';
import 'plan_display.dart';
import 'felicitation.dart';

class AbonnementScreen extends StatefulWidget {
  const AbonnementScreen({Key? key}) : super(key: key);
  @override
  State<AbonnementScreen> createState() => _AbonnementScreenState();
}

class _AbonnementScreenState extends State<AbonnementScreen> {
  bool isMonthly = true;
  bool _isLoading = false;
  String _currentEntitlement = 'free';

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
        } else if (activeEntitlements.contains('pro-monthly_access')) {
          _currentEntitlement = 'pro-monthly_access';
        } else if (activeEntitlements.contains('pro-yearly_access')) {
          _currentEntitlement = 'pro-yearly_access';
        } else {
          _currentEntitlement = 'free';
        }
      });
    }
  }

  Future<void> _processSubscription(String plan) async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final customerInfo =
          await RevenueCatService.purchaseProduct(plan, isMonthly);

      if (customerInfo != null) {
        // Add this line to update Firestore
        await SubscriptionService.updateSubscriptionStatus();

        if (!mounted) return;
        await _checkCurrentEntitlement();
        _showActivationPopup();
      }
    } catch (e) {
      print('❌ Erreur achat: $e');
      if (!mounted) return;
      if (e is PlatformException &&
          e.code == '1' &&
          e.details?['userCancelled'] == true) {
        _showMessage(
          'Annulation', 
          Colors.orange, // Couleur orange pour une annulation
        );
        return; // Sort de la fonction sans autre traitement
      }
      _showMessage('Erreur lors de l\'achat. Veuillez réessayer.', Colors.red);
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _showActivationPopup() {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const FelicitationDialog(),
    );
  }

  void _showMessage(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Ajout du fond blanc
      appBar: AppBar(
        backgroundColor: const Color(0xFF08004D),
        iconTheme: const IconThemeData(
            color: Colors.white), // Ajout pour le bouton retour
        centerTitle: true, // Optionnel : pour centrer le titre
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildToggleButton(true, "Mensuel", Icons.calendar_today),
            _buildToggleButton(false, "Annuel", Icons.calendar_month),
          ],
        ),
      ),
      body: Container(
        color: Colors.white, // Ajout du fond blanc au container principal
        child: Stack(
          children: [
            Column(
              children: [
                // Affichage des plans
                Expanded(
                  child: PlanDisplay(
                    isMonthly: isMonthly,
                    currentEntitlement: _currentEntitlement,
                    onSubscribe: _processSubscription,
                    onPageChanged: (index) {
                      // Gérer le changement de page si nécessaire
                    },
                  ),
                ),

                // Bouton de contact
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
