import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class RetourLoc extends StatelessWidget {
  final TextEditingController dateFinEffectifController;
  final TextEditingController kilometrageRetourController;
  final Map<String, dynamic> data;
  final Future<void> Function(TextEditingController) selectDateTime;

  const RetourLoc({
    Key? key,
    required this.dateFinEffectifController,
    required this.kilometrageRetourController,
    required this.data,
    required this.selectDateTime,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Retour du véhicule",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: dateFinEffectifController,
          readOnly: true,
          onTap: () => selectDateTime(dateFinEffectifController),
          decoration: InputDecoration(
            labelText: "Date de fin",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return "Ce champ est requis";
            }
            return null;
          },
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: kilometrageRetourController,
          decoration: InputDecoration(
            labelText: "Kilométrage de retour",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            suffixIcon: IconButton(
              icon: const Icon(Icons.check_circle),
              onPressed: () {
                // Fermer le clavier
                FocusScope.of(context).unfocus();
              },
            ),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              final intValue = int.tryParse(value);
              if (intValue == null) {
                return "Veuillez entrer un nombre valide";
              }
              if (data['kilometrageDepart'] != null &&
                  data['kilometrageDepart'].isNotEmpty &&
                  intValue < int.parse(data['kilometrageDepart'])) {
                return "Le kilométrage de retour ne peut pas être inférieur au kilométrage de départ";
              }
            }
            return null;
          },
        ),
      ],
    );
  }
}
