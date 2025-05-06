import 'package:flutter/material.dart';

class LieuxPopup extends StatefulWidget {
  final Function(String, String) onLieuxSelected;
  final String? lieuDepartInitial;
  final String? lieuArriveeInitial;

  const LieuxPopup({
    Key? key,
    required this.onLieuxSelected,
    this.lieuDepartInitial,
    this.lieuArriveeInitial,
  }) : super(key: key);

  @override
  State<LieuxPopup> createState() => _LieuxPopupState();
}

class _LieuxPopupState extends State<LieuxPopup> {
  final TextEditingController _lieuDepartController = TextEditingController();
  final TextEditingController _lieuArriveeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _lieuDepartController.text = widget.lieuDepartInitial ?? '';
    _lieuArriveeController.text = widget.lieuArriveeInitial ?? '';
  }

  @override
  void dispose() {
    _lieuDepartController.dispose();
    _lieuArriveeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF08004D).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: Color(0xFF08004D), size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Sélection des lieux",
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
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _lieuDepartController,
                    decoration: InputDecoration(
                      labelText: 'Lieu de départ',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _lieuArriveeController,
                    decoration: InputDecoration(
                      labelText: 'Lieu d\'arrivée',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  
                  // Valider button
                  ElevatedButton(
                    onPressed: _validateAndClose,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF08004D),
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 2,
                    ),
                    child: const Text(
                      "Valider",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _validateAndClose() {
    if (_lieuDepartController.text.isNotEmpty && _lieuArriveeController.text.isNotEmpty) {
      widget.onLieuxSelected(
        _lieuDepartController.text.trim(),
        _lieuArriveeController.text.trim(),
      );
      Navigator.of(context).pop();
    }
  }
}
