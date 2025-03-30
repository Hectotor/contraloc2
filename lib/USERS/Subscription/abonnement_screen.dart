import 'package:flutter/material.dart';
import 'revenue_cat_service.dart';
import '../question_user.dart';
import 'plan_display.dart';

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
                    onSubscribe: (plan) {}, 
                    onPageChanged: (index) {
                      // Gérer le changement de page si nécessaire
                    },
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
