import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ContraLoc/widget/CREATION DE CONTRAT/create_contrat.dart';

class KilometrageContainer extends StatelessWidget {
  final TextEditingController kilometrageDepartController;
  final TextEditingController kilometrageAutoriseController;
  final BuildContext context;

  const KilometrageContainer({
    super.key,
    required this.kilometrageDepartController,
    required this.kilometrageAutoriseController,
    required this.context,
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
                  Icon(Icons.speed, color: const Color(0xFF08004D), size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Kilométrage",
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
                  CreateContrat.buildTextField(
                    "Kilométrage de départ",
                    kilometrageDepartController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                  ),
                  const SizedBox(height: 15),
                  CreateContrat.buildTextField(
                    "Kilométrage autorisé",
                    kilometrageAutoriseController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
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
