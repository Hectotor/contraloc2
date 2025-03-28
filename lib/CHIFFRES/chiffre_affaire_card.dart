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
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Chiffre d\'affaire',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              formatCurrency.format(chiffrePeriodeSelectionnee),
              style: const TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Color(0xFF08004D),
              ),
            ),
            const SizedBox(height: 8),
            if (vehiculePlusRentable.isNotEmpty)
              _buildVehiculePlusRentableSection(formatCurrency),
          ],
        ),
      ),
    );
  }

  Widget _buildVehiculePlusRentableSection(NumberFormat formatCurrency) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        const Divider(),
        const SizedBox(height: 8),
        const Text(
          'Véhicule le plus rentable:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.directions_car, color: Color(0xFF08004D)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '$marqueVehiculePlusRentable $modeleVehiculePlusRentable',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Immatriculation: $immatriculationVehiculePlusRentable'),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Chiffre d\'affaires:'),
                    Text(
                      formatCurrency.format(montantVehiculePlusRentable),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF08004D),
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Pourcentage du total:'),
                    Text(
                      '${pourcentageVehiculePlusRentable.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
