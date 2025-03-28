import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ChiffreAffaireCard extends StatelessWidget {
  final double chiffrePeriodeSelectionnee;
  final String vehiculePlusRentable;
  final String marqueVehiculePlusRentable;
  final String modeleVehiculePlusRentable;
  final String immatriculationVehiculePlusRentable;
  final double montantVehiculePlusRentable;
  final double pourcentageVehiculePlusRentable;

  const ChiffreAffaireCard({
    Key? key,
    required this.chiffrePeriodeSelectionnee,
    required this.vehiculePlusRentable,
    required this.marqueVehiculePlusRentable,
    required this.modeleVehiculePlusRentable,
    required this.immatriculationVehiculePlusRentable,
    required this.montantVehiculePlusRentable,
    required this.pourcentageVehiculePlusRentable,
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
                      Icons.euro_rounded,
                      color: Color(0xFF08004D),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Chiffre d\'affaire',
                    style: TextStyle(
                      fontSize: 20, 
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF08004D),
                      Colors.blue.shade700,
                    ],
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total période',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatCurrency.format(chiffrePeriodeSelectionnee),
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
              if (vehiculePlusRentable.isNotEmpty)
                _buildVehiculePlusRentableSection(formatCurrency),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVehiculePlusRentableSection(NumberFormat formatCurrency) {
    // Couleurs pour les indicateurs de performance
    final List<Color> performanceColors = [

      Colors.teal.shade400,

    ];
    
    // Choisir une couleur basée sur le pourcentage
    final Color performanceColor = performanceColors[
      (pourcentageVehiculePlusRentable * performanceColors.length).floor() % performanceColors.length
    ];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        const Divider(color: Colors.grey, height: 1),
        const SizedBox(height: 20),
        Row(
          children: [
            Icon(Icons.star, color: Colors.amber, size: 22),
            const SizedBox(width: 8),
            const Text(
              'Véhicule le plus rentable:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                performanceColor.withOpacity(0.1),
              ],
            ),
            border: Border.all(color: performanceColor.withOpacity(0.3), width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: performanceColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.directions_car,
                        color: performanceColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$marqueVehiculePlusRentable $modeleVehiculePlusRentable',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              immatriculationVehiculePlusRentable,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Chiffre d\'affaires',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            formatCurrency.format(montantVehiculePlusRentable),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: performanceColor,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: performanceColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: performanceColor.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.arrow_upward,
                              color: performanceColor,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${(pourcentageVehiculePlusRentable > 1 ? pourcentageVehiculePlusRentable.toStringAsFixed(1) : (pourcentageVehiculePlusRentable * 100).toStringAsFixed(1))}%',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: performanceColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
