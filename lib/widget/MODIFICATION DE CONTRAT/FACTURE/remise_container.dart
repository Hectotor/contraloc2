import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class RemiseContainer extends StatefulWidget {
  final TextEditingController remiseController;
  final VoidCallback onRemiseChanged;

  const RemiseContainer({
    super.key,
    required this.remiseController,
    required this.onRemiseChanged,
  });

  @override
  State<RemiseContainer> createState() => _RemiseContainerState();
}

class _RemiseContainerState extends State<RemiseContainer> {
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
                  color: Colors.purple[50],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.discount, color: Colors.purple[700], size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Remise",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF08004D),
                        ),
                      ),
                    ),
                    Icon(
                      _showContent ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      color: Colors.purple[700],
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
                      controller: widget.remiseController,
                      decoration: InputDecoration(
                        labelText: "Montant de la remise",
                        labelStyle: const TextStyle(color: Color(0xFF08004D)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        prefixText: '€',
                        suffixIcon: const Icon(Icons.discount, color: Colors.purple),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\,?\d{0,2}')),
                      ],
                      onChanged: (value) {
                        widget.onRemiseChanged();
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
