import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class EvolutionChiffreCard extends StatelessWidget {
  final Map<String, double> chiffreParPeriode;
  final int anneeSelectionnee;

  const EvolutionChiffreCard({
    Key? key,
    required this.chiffreParPeriode,
    required this.anneeSelectionnee,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Évolution du chiffre d\'affaire',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: chiffreParPeriode.isEmpty
                  ? const Center(child: Text('Aucune donnée disponible'))
                  : BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: _getMaxValue() * 1.2, // 20% de marge au-dessus
                        barTouchData: BarTouchData(
                          touchTooltipData: BarTouchTooltipData(
                            getTooltipColor: (group) => Colors.grey.shade800,
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              return BarTooltipItem(
                                '${_getMonthName(groupIndex)}\n${NumberFormat.currency(locale: 'fr_FR', symbol: '€').format(rod.toY)}',
                                const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            },
                          ),
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 30,
                              getTitlesWidget: (value, meta) {
                                const moisAbrev = ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];
                                final index = value.toInt();
                                if (index >= 0 && index < moisAbrev.length) {
                                  return Text(
                                    moisAbrev[index],
                                    style: const TextStyle(
                                      color: Color(0xFF08004D),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  );
                                }
                                return const Text('');
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 60,
                              getTitlesWidget: (value, meta) {
                                if (value == 0) return const Text('0€');
                                return Text(
                                  NumberFormat.compact(locale: 'fr_FR').format(value) + '€',
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                );
                              },
                            ),
                          ),
                          topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        borderData: FlBorderData(
                          show: false,
                        ),
                        gridData: FlGridData(
                          show: true,
                          horizontalInterval: _getMaxValue() / 5,
                          getDrawingHorizontalLine: (value) {
                            return FlLine(
                              color: Colors.grey.shade300,
                              strokeWidth: 1,
                              dashArray: [5, 5],
                            );
                          },
                        ),
                        barGroups: _buildBarGroups(),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  List<BarChartGroupData> _buildBarGroups() {
    // Préparer les données par mois
    final Map<int, double> montantParMois = {};
    
    // Initialiser tous les mois à 0
    for (int i = 0; i < 12; i++) {
      montantParMois[i] = 0;
    }
    
    // Remplir avec les données disponibles
    chiffreParPeriode.forEach((key, value) {
      try {
        // Essayer de parser la date (format attendu: YYYY-MM)
        final parts = key.split('-');
        if (parts.length >= 2) {
          final year = int.parse(parts[0]);
          final month = int.parse(parts[1]) - 1; // 0-indexed
          
          // Ne prendre en compte que les données de l'année sélectionnée
          if (year == anneeSelectionnee && month >= 0 && month < 12) {
            montantParMois[month] = (montantParMois[month] ?? 0) + value;
          }
        }
      } catch (e) {
        // Ignorer les erreurs de parsing
      }
    });
    
    // Créer les groupes de barres
    return List.generate(12, (index) {
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: montantParMois[index] ?? 0,
            color: const Color(0xFF08004D),
            width: 16,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
        ],
      );
    });
  }

  double _getMaxValue() {
    if (chiffreParPeriode.isEmpty) return 1000;
    
    double maxValue = 0;
    final Map<int, double> montantParMois = {};
    
    // Remplir avec les données disponibles
    chiffreParPeriode.forEach((key, value) {
      try {
        final parts = key.split('-');
        if (parts.length >= 2) {
          final year = int.parse(parts[0]);
          final month = int.parse(parts[1]) - 1;
          
          if (year == anneeSelectionnee && month >= 0 && month < 12) {
            montantParMois[month] = (montantParMois[month] ?? 0) + value;
            if (montantParMois[month]! > maxValue) {
              maxValue = montantParMois[month]!;
            }
          }
        }
      } catch (e) {
        // Ignorer les erreurs de parsing
      }
    });
    
    return maxValue > 0 ? maxValue : 1000;
  }

  String _getMonthName(int monthIndex) {
    const monthNames = [
      'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
    ];
    
    if (monthIndex >= 0 && monthIndex < monthNames.length) {
      return monthNames[monthIndex];
    }
    return '';
  }
}
