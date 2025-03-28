import 'package:flutter/material.dart';

class PopupFiltre extends StatelessWidget {
  final Map<String, bool> filtresCalcul;
  final Function(Map<String, bool>) onFiltresChanged;
  final VoidCallback onApply;

  const PopupFiltre({
    Key? key,
    required this.filtresCalcul,
    required this.onFiltresChanged,
    required this.onApply,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Filtres de calcul', style: TextStyle(color: Color(0xFF08004D))),
      content: StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sélectionnez les éléments à inclure dans le calcul du chiffre d\'affaire:',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 10),
                _buildFilterCheckbox('Prix de location', 'prixLocation', setState),
                _buildFilterCheckbox('Coût km supplémentaires', 'coutKmSupplementaires', setState),
                _buildFilterCheckbox('Frais nettoyage intérieur', 'fraisNettoyageInterieur', setState),
                _buildFilterCheckbox('Frais nettoyage extérieur', 'fraisNettoyageExterieur', setState),
                _buildFilterCheckbox('Frais carburant manquant', 'fraisCarburantManquant', setState),
                _buildFilterCheckbox('Frais rayures/dommages', 'fraisRayuresDommages', setState),
                _buildFilterCheckbox('Caution', 'caution', setState),
              ],
            ),
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Annuler', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            onApply();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF08004D),
          ),
          child: const Text('Appliquer', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  Widget _buildFilterCheckbox(String label, String key, StateSetter setState) {
    return CheckboxListTile(
      title: Text(label),
      value: filtresCalcul[key],
      onChanged: (bool? value) {
        setState(() {
          filtresCalcul[key] = value ?? true;
          onFiltresChanged(filtresCalcul);
        });
      },
      controlAffinity: ListTileControlAffinity.leading,
      dense: true,
    );
  }
}

/// Fonction utilitaire pour afficher le popup de filtres
void afficherFiltresDialog({
  required BuildContext context,
  required Map<String, bool> filtresCalcul,
  required Function(Map<String, bool>) onFiltresChanged,
  required VoidCallback onApply,
}) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return PopupFiltre(
        filtresCalcul: filtresCalcul,
        onFiltresChanged: onFiltresChanged,
        onApply: onApply,
      );
    },
  );
}
