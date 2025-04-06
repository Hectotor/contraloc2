import 'package:flutter/material.dart';
import 'package:ContraLoc/widget/CREATION DE CONTRAT/create_contrat.dart';

class DateContainer extends StatelessWidget {
  final TextEditingController dateDebutController;
  final TextEditingController dateFinTheoriqueController;
  final BuildContext context;
  final Future<void> Function(TextEditingController) selectDateTime;

  const DateContainer({
    super.key,
    required this.dateDebutController,
    required this.dateFinTheoriqueController,
    required this.context,
    required this.selectDateTime,
  });

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
            // En-tête de la carte
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF08004D).withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, color: const Color(0xFF08004D), size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Période de location",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF08004D),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Contenu de la carte
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CreateContrat.buildDateField(
                    "Date de début",
                    dateDebutController,
                    true,
                    context,
                    selectDateTime,
                  ),
                  const SizedBox(height: 15),
                  CreateContrat.buildDateField(
                    "Date de fin théorique",
                    dateFinTheoriqueController,
                    false,
                    context,
                    selectDateTime,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
