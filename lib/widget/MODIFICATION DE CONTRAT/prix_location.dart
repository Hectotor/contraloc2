import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PrixLocationWidget extends StatefulWidget {
  final Map<String, dynamic>? data;
  final String? dateFinEffective;
  final TextEditingController? prixLocationController;

  const PrixLocationWidget({
    Key? key,
    required this.data,
    required this.dateFinEffective,
    this.prixLocationController,
  }) : super(key: key);

  @override
  State<PrixLocationWidget> createState() => _PrixLocationWidgetState();
}

class _PrixLocationWidgetState extends State<PrixLocationWidget> {
  final _prixLocationController = TextEditingController();
  final _dateDebutController = TextEditingController();
  final _dateFinController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _dateDebutController.text = widget.data?['dateDebut'] ?? '';
    _dateFinController.text = widget.dateFinEffective ?? '';
    _prixLocationController.text = widget.data?['prixLocation'] ?? '';
  }

  @override
  void dispose() {
    _prixLocationController.dispose();
    _dateDebutController.dispose();
    _dateFinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Champ de date de début
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: TextFormField(
            controller: _dateDebutController,
            decoration: InputDecoration(
              labelText: "Date de début",
              labelStyle: const TextStyle(color: Color(0xFF08004D)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            readOnly: true,
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
        ),

        // Champ de date de fin effective
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: TextFormField(
            controller: _dateFinController,
            decoration: InputDecoration(
              labelText: "Date de fin effective",
              labelStyle: const TextStyle(color: Color(0xFF08004D)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            readOnly: true,
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
        ),

        // Champ du prix de location initial
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: TextFormField(
            controller: _prixLocationController,
            decoration: InputDecoration(
              labelText: "Prix de location initial",
              labelStyle: const TextStyle(color: Color(0xFF08004D)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              prefixText: '€',
            ),
            readOnly: true,
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
        ),

        // Prix de location total
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: TextFormField(
            controller: widget.prixLocationController ?? _prixLocationController,
            decoration: InputDecoration(
              labelText: "Prix de location total",
              labelStyle: const TextStyle(color: Color(0xFF08004D)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              prefixText: '€',
              helperText: "Calculé automatiquement, mais modifiable",
              helperStyle: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
            ),
            enabled: true,
            readOnly: false,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\,?\d{0,2}')),
            ],
          ),
        ),
      ],
    );
  }
}
