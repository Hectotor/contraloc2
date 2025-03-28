import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PeriodeTab extends StatelessWidget {
  final String selectedMonth;
  final String selectedYear;
  final List<String> years;
  final Function(String) onMonthChanged;
  final Function(String) onYearChanged;
  final double chiffrePeriodeSelectionnee;
  final VoidCallback? onFilterPressed;

  const PeriodeTab({
    Key? key,
    required this.selectedMonth,
    required this.selectedYear,
    required this.years,
    required this.onMonthChanged,
    required this.onYearChanged,
    required this.chiffrePeriodeSelectionnee,
    this.onFilterPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Sélecteurs de mois et d'année
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Sélecteur de mois
              const Text('Mois: ', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: selectedMonth,
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    onMonthChanged(newValue);
                  }
                },
                items: ['Tous', 'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin', 'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
              const SizedBox(width: 16),
              // Sélecteur d'année
              const Text('Année: ', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: selectedYear,
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    onYearChanged(newValue);
                  }
                },
                items: years.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
              if (onFilterPressed != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.filter_list, color: Color(0xFF08004D)),
                  onPressed: onFilterPressed,
                  tooltip: 'Filtres de calcul',
                ),
              ],
            ],
          ),
        ),
        // Affichage du chiffre d'affaires pour la période sélectionnée
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF08004D), Color(0xFF1A237E)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.shade900.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total période',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    NumberFormat.currency(locale: 'fr_FR', symbol: '€').format(chiffrePeriodeSelectionnee),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
