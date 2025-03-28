import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;

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
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Répartition par véhicule',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: chiffreParVehicule.isEmpty
                  ? const Center(child: Text('Aucune donnée disponible'))
                  : PieChart(
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
            const SizedBox(height: 16),
            // Légende du graphique
            ..._buildPieChartLegend(),
          ],
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
    final List<Color> colors = _generateDistinctColors(sortedEntries.length);
    
    return List.generate(sortedEntries.length, (index) {
      final entry = sortedEntries[index];
      final percentage = (entry.value / chiffreTotal) * 100;
      
      return PieChartSectionData(
        color: colors[index],
        value: entry.value,
        title: '${percentage.toStringAsFixed(1)}%',
        radius: 100,
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    });
  }

  List<Widget> _buildPieChartLegend() {
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
    final List<Color> colors = _generateDistinctColors(sortedEntries.length);
    
    return sortedEntries.asMap().entries.map((entry) {
      final index = entry.key;
      final vehicule = entry.value.key;
      final montant = entry.value.value;
      final percentage = (montant / chiffrePeriodeSelectionnee) * 100;
      
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: colors[index],
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                vehicule,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              NumberFormat.currency(locale: 'fr_FR', symbol: '€').format(montant),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF08004D),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${percentage.toStringAsFixed(1)}%',
              style: const TextStyle(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
  
  // Méthode pour générer des couleurs distinctes
  List<Color> _generateDistinctColors(int count) {
    // Palette de base avec des couleurs de la marque
    final List<Color> baseColors = [
      const Color(0xFF08004D), // Bleu foncé
      const Color(0xFF1A237E), // Indigo
      const Color(0xFF303F9F), // Bleu
      const Color(0xFF3949AB), // Bleu clair
      const Color(0xFF5C6BC0), // Bleu-violet
      const Color(0xFF7986CB), // Bleu lavande
    ];
    
    // Si on a besoin de moins de couleurs que la palette de base
    if (count <= baseColors.length) {
      return baseColors.sublist(0, count);
    }
    
    // Si on a besoin de plus de couleurs, on génère des couleurs supplémentaires
    List<Color> colors = List.from(baseColors);
    
    // Générer des couleurs supplémentaires en variant la teinte
    final random = math.Random(42); // Seed fixe pour la cohérence
    
    while (colors.length < count) {
      // Générer une nouvelle couleur avec une teinte aléatoire mais dans la gamme des bleus/violets
      final hue = 220.0 + random.nextDouble() * 60; // Entre 220 (bleu) et 280 (violet)
      final saturation = 0.6 + random.nextDouble() * 0.4; // Entre 0.6 et 1.0
      final brightness = 0.6 + random.nextDouble() * 0.3; // Entre 0.6 et 0.9
      
      final color = HSVColor.fromAHSV(1.0, hue, saturation, brightness).toColor();
      
      // Vérifier que la couleur est suffisamment différente des autres
      bool isDifferentEnough = true;
      for (final existingColor in colors) {
        final colorDistance = _calculateColorDistance(color, existingColor);
        if (colorDistance < 50) { // Seuil de différence
          isDifferentEnough = false;
          break;
        }
      }
      
      if (isDifferentEnough) {
        colors.add(color);
      }
    }
    
    return colors;
  }
  
  // Calcule la "distance" entre deux couleurs (différence perceptuelle)
  double _calculateColorDistance(Color a, Color b) {
    final rDiff = (a.red - b.red).abs();
    final gDiff = (a.green - b.green).abs();
    final bDiff = (a.blue - b.blue).abs();
    
    // Formule de distance euclidienne pondérée (perception humaine)
    return math.sqrt(rDiff * rDiff * 0.299 + gDiff * gDiff * 0.587 + bDiff * bDiff * 0.114);
  }
}
