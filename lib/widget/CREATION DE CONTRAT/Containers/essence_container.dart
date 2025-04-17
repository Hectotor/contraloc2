import 'package:flutter/material.dart';

class EssenceContainer extends StatefulWidget {
  final int pourcentageEssence;
  final Function(int) onPourcentageChanged;

  const EssenceContainer({
    super.key,
    required this.pourcentageEssence,
    required this.onPourcentageChanged,
  });

  @override
  State<EssenceContainer> createState() => _EssenceContainerState();
}

class _EssenceContainerState extends State<EssenceContainer> {
  bool _showContent = false;
  double _pourcentage = 0.0;

  @override
  void initState() {
    super.initState();
    _pourcentage = widget.pourcentageEssence.toDouble();
  }

  @override
  Widget build(BuildContext context) {


    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.20),
            blurRadius: 4,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête de la carte avec flèche
            GestureDetector(
              onTap: () {
                setState(() {
                  _showContent = !_showContent;
                });
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF08004D).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(Icons.local_gas_station, color: const Color(0xFF08004D), size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Niveau d'essence",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF08004D),
                        ),
                      ),
                    ),
                    Icon(
                      _showContent ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      color: const Color(0xFF08004D),
                    ),
                  ],
                ),
              ),
            ),
            // Contenu de la carte
            if (_showContent)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Titre et valeur actuelle
                    Row(
                      children: [
                        Text(
                          "Niveau d'essence",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF08004D),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          "${widget.pourcentageEssence}%",
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF08004D),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Slider pour sélectionner le niveau
                    Slider(
                      value: _pourcentage,
                      min: 0,
                      max: 100,
                      divisions: 10, // 10 divisions pour des valeurs de 10 en 10
                      activeColor: const Color(0xFF08004D),
                      inactiveColor: const Color(0xFF08004D).withOpacity(0.3),
                      label: '${_pourcentage.toInt()}%',
                      onChanged: (double value) {
                        setState(() {
                          // Arrondir à la dizaine la plus proche
                          final roundedValue = ((value / 10).round() * 10).toDouble();
                          _pourcentage = roundedValue;
                          widget.onPourcentageChanged(roundedValue.toInt());
                        });
                      },
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
