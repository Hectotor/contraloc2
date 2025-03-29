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
  final Map<String, double> chiffreParVehicule;
  final Map<String, Map<String, dynamic>> detailsVehicules;

  const PeriodeTab({
    Key? key,
    required this.selectedMonth,
    required this.selectedYear,
    required this.years,
    required this.onMonthChanged,
    required this.onYearChanged,
    required this.chiffrePeriodeSelectionnee,
    required this.chiffreParVehicule,
    required this.detailsVehicules,
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
        // Classement des véhicules par chiffre d'affaires
        Expanded(
          child: _buildVehiculeRanking(),
        ),
      ],
    );
  }

  Widget _buildVehiculeRanking() {
    // Trier les véhicules par chiffre d'affaires décroissant
    final sortedVehicules = chiffreParVehicule.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (sortedVehicules.isEmpty) {
      return const Center(
        child: Text(
          'Aucune donnée disponible pour cette période',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF08004D).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.emoji_events_rounded,
                    color: Color(0xFF08004D),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Classement des véhicules',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: sortedVehicules.length,
              itemBuilder: (context, index) {
                final vehicule = sortedVehicules[index];
                final vehiculeInfo = vehicule.key;
                final chiffre = vehicule.value;
                final details = detailsVehicules[vehiculeInfo];
                final rank = index + 1;

                // Couleurs pour les 3 premiers
                Color rankColor;
                Color rankBgColor;
                IconData? medalIcon;

                switch (rank) {
                  case 1:
                    rankColor = Colors.amber.shade800;
                    rankBgColor = Colors.amber.shade100;
                    medalIcon = Icons.looks_one;
                    break;
                  case 2:
                    rankColor = Colors.blueGrey.shade600;
                    rankBgColor = Colors.blueGrey.shade100;
                    medalIcon = Icons.looks_two;
                    break;
                  case 3:
                    rankColor = Colors.brown.shade600;
                    rankBgColor = Colors.brown.shade100;
                    medalIcon = Icons.looks_3;
                    break;
                  default:
                    rankColor = Colors.grey.shade700;
                    rankBgColor = Colors.grey.shade100;
                    medalIcon = null;
                }

                return Card(
                  elevation: rank <= 3 ? 4 : 2,
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: rank <= 3
                        ? BorderSide(color: rankColor.withOpacity(0.5), width: 1)
                        : BorderSide.none,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: rank <= 3
                          ? LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white,
                                rankBgColor.withOpacity(0.2),
                              ],
                            )
                          : null,
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: rankBgColor,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: medalIcon != null
                              ? Icon(medalIcon, color: rankColor, size: 24)
                              : Text(
                                  '$rank',
                                  style: TextStyle(
                                    color: rankColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                        ),
                      ),
                      title: Text(
                        vehiculeInfo.replaceAll(RegExp(r'\(.*?\)'), '').trim(),
                        style: TextStyle(
                          fontWeight: rank <= 3 ? FontWeight.bold : FontWeight.normal,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Text(
                        details != null 
                            ? 'Immatriculation: ${details['immatriculation'] ?? 'Non disponible'}'
                            : vehiculeInfo.contains('(') && vehiculeInfo.contains(')') 
                                ? 'Immatriculation: ${vehiculeInfo.substring(vehiculeInfo.lastIndexOf('(') + 1, vehiculeInfo.lastIndexOf(')'))}'
                                : 'Immatriculation: Non disponible',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: Text(
                        NumberFormat.currency(locale: 'fr_FR', symbol: '€').format(chiffre),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: rank <= 3 ? rankColor : Colors.black87,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
