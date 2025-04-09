import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FraisKilometrageSuppContainer extends StatefulWidget {
  final TextEditingController fraisKilometriqueController;
  final VoidCallback onFraisKilometriqueChanged;

  const FraisKilometrageSuppContainer({
    super.key,
    required this.fraisKilometriqueController,
    required this.onFraisKilometriqueChanged,
  });

  @override
  State<FraisKilometrageSuppContainer> createState() => _FraisKilometrageSuppContainerState();
}

class _FraisKilometrageSuppContainerState extends State<FraisKilometrageSuppContainer> {
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
                  color: Colors.teal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(Icons.directions_car, color: Colors.teal, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Frais km supplémentaires",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                        ),
                      ),
                    ),
                    Icon(
                      _showContent ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      color: Colors.teal,
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
                    TextFormField(
                      controller: widget.fraisKilometriqueController,
                      decoration: const InputDecoration(
                        labelText: "Frais kilométriques supplémentaires",
                        labelStyle: TextStyle(color: Colors.teal),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        prefixText: '€',
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\,?\d{0,2}')),
                      ],
                      onChanged: (value) {
                        widget.onFraisKilometriqueChanged();
                      },
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
