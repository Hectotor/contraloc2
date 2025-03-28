import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class RepartitionVehiculeCard extends StatelessWidget {
  final Map<String, double> chiffreParVehicule;
  final double chiffreTotal;
  final double chiffrePeriodeSelectionnee;

  const RepartitionVehiculeCard({
    Key? key,
    required this.chiffreParVehicule,
    required this.chiffreTotal,
    required this.chiffrePeriodeSelectionnee,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final formatCurrency = NumberFormat.currency(locale: 'fr_FR', symbol: '€');

    return Card(
      elevation: 8,
      shadowColor: const Color(0xFF08004D).withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: const Color(0xFF08004D).withOpacity(0.3), width: 1),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Colors.white,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF08004D).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.pie_chart_rounded,
                      color: Color(0xFF08004D),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: const Text(
                      'Répartition par véhicule',
                      style: TextStyle(
                        fontSize: 20, 
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
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
                child: chiffreParVehicule.isEmpty
                    ? const Center(
                        child: Text(
                          'Aucune donnée disponible',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.all(16),
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: 40,
                            sections: _buildPieSections(),
                            pieTouchData: PieTouchData(
                              touchCallback: (FlTouchEvent event, pieTouchResponse) {
                                // Interaction avec le graphique
                              },
                            ),
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 20),
              const Divider(color: Colors.grey, height: 1),
              const SizedBox(height: 16),
              const Text(
                'Détails par véhicule',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ..._buildPieChartLegend(formatCurrency),
            ],
          ),
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildPieSections() {
    List<MapEntry<String, double>> sortedEntries = chiffreParVehicule.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    // Limiter à 5 sections pour la lisibilité
    if (sortedEntries.length > 5) {
      double autresMontant = 0;
      for (int i = 5; i < sortedEntries.length; i++) {
        autresMontant += sortedEntries[i].value;
      }
      sortedEntries = sortedEntries.sublist(0, 5);
      if (autresMontant > 0) {
        sortedEntries.add(MapEntry('Autres', autresMontant));
      }
    }
    
    // Générer des couleurs distinctes pour chaque section
    final List<Color> colors = _getOrderedColors(sortedEntries.length);
    
    return List.generate(sortedEntries.length, (index) {
      final entry = sortedEntries[index];
      final percentage = (entry.value / chiffreTotal) * 100;
      
      return PieChartSectionData(
        color: colors[index],
        value: entry.value,
        title: '${percentage.toStringAsFixed(1)}%',
        radius: 110,
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: [
            Shadow(
              color: Colors.black26,
              blurRadius: 2,
              offset: Offset(0, 1),
            ),
          ],
        ),
      );
    });
  }

  List<Widget> _buildPieChartLegend(NumberFormat formatCurrency) {
    List<MapEntry<String, double>> sortedEntries = chiffreParVehicule.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    // Limiter à 5 entrées pour la lisibilité
    if (sortedEntries.length > 5) {
      double autresMontant = 0;
      for (int i = 5; i < sortedEntries.length; i++) {
        autresMontant += sortedEntries[i].value;
      }
      sortedEntries = sortedEntries.sublist(0, 5);
      if (autresMontant > 0) {
        sortedEntries.add(MapEntry('Autres', autresMontant));
      }
    }
    
    // Générer des couleurs distinctes pour chaque entrée
    final List<Color> colors = _getOrderedColors(sortedEntries.length);
    
    return sortedEntries.asMap().entries.map((entry) {
      final index = entry.key;
      final vehicule = entry.value.key;
      final montant = entry.value.value;
      final percentage = (montant / chiffrePeriodeSelectionnee) * 100;
      
      // Extraire l'immatriculation si elle est entre parenthèses
      String vehiculeName = vehicule;
      String immatriculation = '';
      
      final regExp = RegExp(r'(.*)\s*\((.*)\)');
      final match = regExp.firstMatch(vehicule);
      if (match != null && match.groupCount >= 2) {
        vehiculeName = match.group(1)?.trim() ?? vehicule;
        immatriculation = match.group(2)?.trim() ?? '';
      }
      
      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: colors[index].withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: colors[index],
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: colors[index].withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    vehiculeName,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
            if (immatriculation.isNotEmpty) ...[
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 24),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    immatriculation,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 24),
                  child: Text(
                    formatCurrency.format(montant),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colors[index],
                      fontSize: 16,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: colors[index].withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colors[index].withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    '${percentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colors[index],
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }).toList();
  }
  
  // Méthode pour obtenir des couleurs ordonnées (vert pour la plus haute, rouge pour la plus basse)
  List<Color> _getOrderedColors(int count) {
    // Palette de base avec le vert en premier et le rouge en dernier
    final List<Color> baseColors = [
      const Color(0xFF4CAF50),  // Vert (valeur la plus haute)
      const Color(0xFF2196F3),  // Bleu
      const Color(0xFF9C27B0),  // Violet
      const Color(0xFF009688),  // Turquoise
      const Color(0xFFFF9800),  // Orange
      const Color(0xFFF44336),  // Rouge (valeur la plus basse)
    ];
    
    // Si on a besoin de plus de couleurs, on ajoute des couleurs intermédiaires
    if (count > baseColors.length) {
      // Créer un dégradé de couleurs entre le vert et le rouge
      List<Color> extendedColors = [];
      extendedColors.add(baseColors.first); // Vert (toujours en premier)
      
      // Ajouter des couleurs intermédiaires
      if (count > 2) {
        final int intermediateCount = count - 2;
        for (int i = 0; i < intermediateCount; i++) {
          final double t = i / (intermediateCount - 1);
          
          // Utiliser les couleurs de baseColors si disponibles, sinon interpoler
          if (i < baseColors.length - 2) {
            extendedColors.add(baseColors[i + 1]);
          } else {
            // Interpoler entre le bleu et le rouge pour créer des teintes intermédiaires
            final Color startColor = const Color(0xFF2196F3); // Bleu
            final Color endColor = const Color(0xFFFF9800);   // Orange
            
            final int r = _lerpInt(startColor.red, endColor.red, t);
            final int g = _lerpInt(startColor.green, endColor.green, t);
            final int b = _lerpInt(startColor.blue, endColor.blue, t);
            
            extendedColors.add(Color.fromARGB(255, r, g, b));
          }
        }
      }
      
      extendedColors.add(baseColors.last); // Rouge (toujours en dernier)
      return extendedColors;
    } else {
      // Si on a besoin de moins de couleurs que la palette de base
      List<Color> colors = [];
      colors.add(baseColors.first); // Vert (toujours en premier)
      
      // Ajouter des couleurs intermédiaires si nécessaire
      if (count > 2) {
        final step = (baseColors.length - 2) / (count - 2);
        for (int i = 1; i < count - 1; i++) {
          final index = (i * step).round();
          colors.add(baseColors[index]);
        }
      }
      
      if (count > 1) {
        colors.add(baseColors.last); // Rouge (toujours en dernier)
      }
      
      return colors;
    }
  }
  
  // Fonction d'interpolation linéaire pour les entiers
  int _lerpInt(int a, int b, double t) {
    return (a + (b - a) * t).round();
  }
}
