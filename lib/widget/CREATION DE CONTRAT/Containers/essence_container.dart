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

  String _getCurrentValue(int percentage) {
    if (percentage <= 0) return "0";
    if (percentage <= 25) return "1/4";
    if (percentage <= 50) return "1/2";
    if (percentage <= 75) return "3/4";
    return "1";
  }

  int _getPercentage(String value) {
    switch (value) {
      case "0": return 0;
      case "1/4": return 25;
      case "1/2": return 50;
      case "3/4": return 75;
      case "1": return 100;
      default: return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentValue = _getCurrentValue(widget.pourcentageEssence);

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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Niveau d'essence au départ :",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildEssenceButton("0", currentValue),
                        _buildEssenceButton("1/4", currentValue),
                        _buildEssenceButton("1/2", currentValue),
                        _buildEssenceButton("3/4", currentValue),
                        _buildEssenceButton("1", currentValue),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEssenceButton(String value, String currentValue) {
    final isSelected = value == currentValue;
    
    return Container(
      width: 40,
      child: ElevatedButton(
        onPressed: () {
          widget.onPourcentageChanged(_getPercentage(value));
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? const Color(0xFF08004D) : Colors.grey[200],
          foregroundColor: isSelected ? Colors.white : const Color(0xFF08004D),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          minimumSize: const Size(0, 0),
        ),
        child: Text(
          value,
          style: const TextStyle(fontSize: 14),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
