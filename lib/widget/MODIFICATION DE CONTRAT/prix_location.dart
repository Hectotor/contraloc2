import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PrixLocationWidget extends StatefulWidget {
  final Map<String, dynamic>? data;
  final TextEditingController? prixLocationController;

  const PrixLocationWidget({
    Key? key,
    required this.data,
    this.prixLocationController,
  }) : super(key: key);

  @override
  State<PrixLocationWidget> createState() => _PrixLocationWidgetState();
}

class _PrixLocationWidgetState extends State<PrixLocationWidget> {
  final _prixLocationController = TextEditingController();
  bool _showContent = false;

  @override
  void initState() {
    super.initState();
    if (widget.data != null) {
      _prixLocationController.text = widget.data!['prixLocation']?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _prixLocationController.dispose();
    super.dispose();
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool readOnly = false, String? prefixText}) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF08004D)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        prefixText: prefixText,
      ),
      style: TextStyle(
        fontSize: 16,
        color: Colors.grey[600],
      ),
      keyboardType: prefixText != null ? TextInputType.number : null,
      inputFormatters: prefixText != null ? [
        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
      ] : null,
    );
  }

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
                  color: const Color(0xFF08004D).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(Icons.attach_money, color: const Color(0xFF08004D), size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Prix de location",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF08004D),
                        ),
                      ),
                    ),
                    Icon(
                      _showContent ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      color: const Color(0xFF08004D),
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
                    _buildTextField("Prix de la location", _prixLocationController, prefixText: '€'),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
