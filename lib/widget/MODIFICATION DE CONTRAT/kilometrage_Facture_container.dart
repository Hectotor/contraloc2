import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class KilometrageFactureContainer extends StatelessWidget {
  final TextEditingController fraisKilometriqueController;
  final VoidCallback? onFraisKilometriqueChanged;

  const KilometrageFactureContainer({
    Key? key,
    required this.fraisKilometriqueController,
    this.onFraisKilometriqueChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: fraisKilometriqueController,
        decoration: InputDecoration(
          labelText: "Frais kilométriques",
          labelStyle: const TextStyle(color: Color(0xFF08004D)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          prefixText: '€',
        ),
        enabled: true,
        readOnly: false,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\,?\d{0,2}')),
        ],
        onChanged: (value) {
          if (onFraisKilometriqueChanged != null) {
            onFraisKilometriqueChanged!();
          }
        },
      ),
    );
  }
}
