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
    return StatefulBuilder(
      builder: (context, setState) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 8,
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Filtres',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF08004D),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 8),
                
                // Description
                const Text(
                  'Sélectionnez les éléments à inclure:',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                
                // Toggle All Button
                _buildToggleAllButton(setState),
                const SizedBox(height: 16),
                
                // Filter List
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildFilterItem('Prix de location', 'facturePrixLocation', Icons.attach_money, setState),
                        _buildFilterItem('Coût km supplémentaires', 'factureCoutKmSupplementaires', Icons.directions_car, setState),
                        _buildFilterItem('Frais nettoyage intérieur', 'factureFraisNettoyageInterieur', Icons.cleaning_services, setState),
                        _buildFilterItem('Frais nettoyage extérieur', 'factureFraisNettoyageExterieur', Icons.water_drop, setState),
                        _buildFilterItem('Frais carburant manquant', 'factureFraisCarburantManquant', Icons.local_gas_station, setState),
                        _buildFilterItem('Frais rayures/dommages', 'factureFraisRayuresDommages', Icons.build, setState),
                        _buildFilterItem('Frais autres', 'factureFraisAutre', Icons.more_horiz, setState),
                        _buildFilterItem('Caution', 'factureCaution', Icons.security, setState),
                      ],
                    ),
                  ),
                ),
                
                // Actions
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Annuler'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        onApply();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF08004D),
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      child: const Text('Appliquer'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildToggleAllButton(StateSetter setState) {
    bool allChecked = filtresCalcul.values.every((value) => value == true);
    bool allUnchecked = filtresCalcul.values.every((value) => value == false);
    
    return Card(
      elevation: 0,
      color: Colors.grey.shade100,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          setState(() {
            bool newValue = allUnchecked ? true : false;
            filtresCalcul.forEach((key, _) => filtresCalcul[key] = newValue);
            onFiltresChanged(filtresCalcul);
          });
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Checkbox(
                value: allChecked,
                activeColor: const Color(0xFF08004D),
                onChanged: (bool? value) {
                  setState(() {
                    bool newValue = value ?? false;
                    filtresCalcul.forEach((key, _) => filtresCalcul[key] = newValue);
                    onFiltresChanged(filtresCalcul);
                  });
                },
              ),
              Text(
                allUnchecked ? 'Tout cocher' : 'Tout décocher',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              Icon(
                allUnchecked ? Icons.check_box_outline_blank : Icons.check_box,
                color: const Color(0xFF08004D),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterItem(String label, String key, IconData icon, StateSetter setState) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: filtresCalcul[key] == true ? Colors.blue.shade50 : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: filtresCalcul[key] == true ? const Color(0xFF08004D).withOpacity(0.3) : Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          setState(() {
            filtresCalcul[key] = !(filtresCalcul[key] ?? false);
            onFiltresChanged(filtresCalcul);
          });
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(icon, size: 20, color: const Color(0xFF08004D)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontWeight: filtresCalcul[key] == true ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
              ),
              Checkbox(
                value: filtresCalcul[key],
                activeColor: const Color(0xFF08004D),
                onChanged: (bool? value) {
                  setState(() {
                    filtresCalcul[key] = value ?? false;
                    onFiltresChanged(filtresCalcul);
                  });
                },
              ),
            ],
          ),
        ),
      ),
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
