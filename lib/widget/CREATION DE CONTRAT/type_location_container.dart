import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TypeLocationContainer extends StatefulWidget {
  final String typeLocation;
  final Function(String) onTypeChanged;
  final TextEditingController prixLocationController;
  final TextEditingController accompteController;

  const TypeLocationContainer({
    super.key,
    required this.typeLocation,
    required this.onTypeChanged,
    required this.prixLocationController,
    required this.accompteController,
  });

  static Widget buildPrixLocationField(TextEditingController controller) {
    return TextField(
      controller: controller,
      readOnly: true, // Make the field read-only
      decoration: InputDecoration(
        labelText: "Prix de la location par jour",
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  static Widget buildAccompteField(TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters: <TextInputFormatter>[
          FilteringTextInputFormatter.digitsOnly,
        ],
        decoration: InputDecoration(
          labelText: "Accompte",
          hintText: "Montant de l'accompte",
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          suffixIcon: IconButton(
            icon: Icon(Icons.check_circle, color: Colors.grey[400]),
            onPressed: () => FocusManager.instance.primaryFocus?.unfocus(),
          ),
        ),
      ),
    );
  }

  @override
  State<TypeLocationContainer> createState() => _TypeLocationContainerState();
}

class _TypeLocationContainerState extends State<TypeLocationContainer> {
  String _selectedType = '';

  @override
  void initState() {
    super.initState();
    _selectedType = widget.typeLocation;
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
                  Icon(Icons.category, color: const Color(0xFF08004D), size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Type de location",
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
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _selectedType = 'Gratuite';
                            });
                            widget.onTypeChanged('Gratuite');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _selectedType == 'Gratuite' ? const Color(0xFF08004D) : Colors.grey[200],
                            foregroundColor: _selectedType == 'Gratuite' ? Colors.white : const Color(0xFF08004D),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            "Gratuite",
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _selectedType = 'Payante';
                            });
                            widget.onTypeChanged('Payante');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _selectedType == 'Payante' ? const Color(0xFF08004D) : Colors.grey[200],
                            foregroundColor: _selectedType == 'Payante' ? Colors.white : const Color(0xFF08004D),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            "Payante",
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (_selectedType == 'Payante')
                    Column(
                      children: [
                        if (widget.prixLocationController.text.isEmpty)
                          const Padding(
                            padding: EdgeInsets.only(top: 8.0),
                            child: Text(
                              "Veuillez configurer le prix de la location dans sa fiche afin qu'il soit affiché correctement.",
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        TypeLocationContainer.buildPrixLocationField(widget.prixLocationController),
                        TypeLocationContainer.buildAccompteField(widget.accompteController),
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
