import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FraisAdditionnelsContainer extends StatefulWidget {
  final TextEditingController fraisNettoyageIntController;
  final TextEditingController fraisNettoyageExtController;
  final TextEditingController fraisCarburantController;
  final TextEditingController fraisRayuresController;
  final TextEditingController fraisCasqueController;
  final TextEditingController fraisAutreController;
  final VoidCallback onFraisChanged;

  const FraisAdditionnelsContainer({
    super.key,
    required this.fraisNettoyageIntController,
    required this.fraisNettoyageExtController,
    required this.fraisCarburantController,
    required this.fraisRayuresController,
    required this.fraisCasqueController,
    required this.fraisAutreController,
    required this.onFraisChanged,
  });

  @override
  State<FraisAdditionnelsContainer> createState() => _FraisAdditionnelsContainerState();
}

class _FraisAdditionnelsContainerState extends State<FraisAdditionnelsContainer> {
  bool _showContent = false;

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
            // En-tête de la carte avec flèche
            GestureDetector(
              onTap: () {
                setState(() {
                  _showContent = !_showContent;
                });
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(Icons.attach_money, color: Colors.red, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Frais additionnels",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ),
                    Icon(
                      _showContent ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      color: Colors.red,
                    ),
                  ],
                ),
              ),
            ),
            // Contenu de la carte
            if (_showContent)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTextField("Frais nettoyage intérieur", widget.fraisNettoyageIntController),
                    const SizedBox(height: 15),
                    _buildTextField("Frais nettoyage extérieur", widget.fraisNettoyageExtController),
                    const SizedBox(height: 15),
                    _buildTextField("Frais carburant manquant", widget.fraisCarburantController),
                    const SizedBox(height: 15),
                    _buildTextField("Frais rayures/dommages", widget.fraisRayuresController),
                    const SizedBox(height: 15),
                    _buildTextField("Frais location casque", widget.fraisCasqueController),
                    const SizedBox(height: 15),
                    _buildTextField("Frais autres", widget.fraisAutreController),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.red),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        suffixText: '€',  
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\,?\d{0,2}')),
      ],
      onChanged: (value) {
        widget.onFraisChanged();
      },
    );
  }
}
