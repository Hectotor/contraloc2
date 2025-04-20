import 'package:flutter/material.dart';

class TotalFraisContainer extends StatelessWidget {
  final TextEditingController prixLocationController;
  final TextEditingController fraisKilometriqueController;
  final TextEditingController fraisNettoyageIntController;
  final TextEditingController fraisNettoyageExtController;
  final TextEditingController fraisCarburantController;
  final TextEditingController fraisRayuresController;
  final TextEditingController fraisCasqueController;
  final TextEditingController fraisAutreController;
  final TextEditingController cautionController;
  final TextEditingController remiseController;

  const TotalFraisContainer({
    Key? key,
    required this.prixLocationController,
    required this.fraisKilometriqueController,
    required this.fraisNettoyageIntController,
    required this.fraisNettoyageExtController,
    required this.fraisCarburantController,
    required this.fraisRayuresController,
    required this.fraisCasqueController,
    required this.fraisAutreController,
    required this.cautionController,
    required this.remiseController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.20),
            blurRadius: 4,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.attach_money, color: Colors.green[700], size: 24),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Total des frais',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF08004D),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildTotal(
                    context,
                    'Total des frais',
                    _calculerTotal(),
                  ),
                  const SizedBox(height: 15),
                  _buildTotal(
                    context,
                    'Total à payer',
                    _calculerTotalAPayer(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _parseDouble(String value) {
    if (value.isEmpty) return 0;
    return double.tryParse(value.replaceAll(',', '.')) ?? 0;
  }

  double _calculerTotal() {
    return _parseDouble(prixLocationController.text) +
        _parseDouble(fraisKilometriqueController.text) +
        _parseDouble(fraisNettoyageIntController.text) +
        _parseDouble(fraisNettoyageExtController.text) +
        _parseDouble(fraisCarburantController.text) +
        _parseDouble(fraisRayuresController.text) +
        _parseDouble(fraisCasqueController.text) +
        _parseDouble(fraisAutreController.text) +
        _parseDouble(cautionController.text);
  }

  double _calculerTotalAPayer() {
    final total = _calculerTotal();
    final remise = _parseDouble(remiseController.text);
    return total - remise;
  }

  Widget _buildTotal(BuildContext context, String label, double amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF08004D),
          ),
        ),
        Text(
          '${amount.toStringAsFixed(2)} €',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: amount > 0 ? Colors.green[700] : Colors.red[700],
          ),
        ),
      ],
    );
  }
}
