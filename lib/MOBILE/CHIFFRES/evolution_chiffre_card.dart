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
      elevation: 8,
      shadowColor: const Color(0xFF08004D).withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: const Color(0xFF08004D).withOpacity(0.1), width: 1),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Colors.grey.shade50,
            ],
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titre avec icône
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF08004D).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.trending_up_rounded,
                    color: Color(0xFF08004D),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Évolution du CA',
                  style: TextStyle(
                    fontSize: 20, 
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Graphique
            Container(
              height: 300,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: chiffreParPeriode.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.bar_chart_outlined,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Aucune donnée disponible',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(16),
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: _getMaxValue() * 1.2, // 20% de marge au-dessus
                          barTouchData: BarTouchData(
                            enabled: true,
                            touchTooltipData: BarTouchTooltipData(
                              getTooltipColor: (group) => const Color(0xFF08004D).withOpacity(0.9),
                              tooltipRoundedRadius: 8,
                              tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                return BarTooltipItem(
                                  '${_getMonthName(groupIndex)}\n${NumberFormat.currency(locale: 'fr_FR', symbol: '€').format(rod.toY)}',
                                  const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
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
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        moisAbrev[index],
                                        style: const TextStyle(
                                          color: Color(0xFF08004D),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
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
                                  if (value == 0) {
                                    return const Padding(
                                      padding: EdgeInsets.only(right: 8),
                                      child: Text(
                                        '0€',
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    );
                                  }
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: Text(
                                      NumberFormat.compact(locale: 'fr_FR').format(value) + '€',
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
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
                                color: Colors.grey.shade200,
                                strokeWidth: 1,
                                dashArray: [5, 5],
                              );
                            },
                          ),
                          barGroups: _buildBarGroups(),
                        ),
                      ),
                    ),
            ),
            
            // Légende ou informations supplémentaires
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.grey.shade700),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Chiffre d\'affaire mensuel pour l\'année $anneeSelectionnee',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
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
      final double value = montantParMois[index] ?? 0;
      final double maxValue = _getMaxValue();
      final double percentage = maxValue > 0 ? value / maxValue : 0;
      
      // Degré de couleur en fonction de la valeur
      final Color barColor = ColorTween(
        begin: const Color(0xFF1A237E),
        end: const Color(0xFF3949AB),
      ).lerp(percentage) ?? const Color(0xFF08004D);
      
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: value,
            color: barColor,
            width: 16,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(6),
              topRight: Radius.circular(6),
            ),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: maxValue * 1.1,
              color: Colors.grey.shade100,
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
