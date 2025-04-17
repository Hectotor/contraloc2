import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart'; // Importer la bibliothèque Intl pour utiliser DateFormat

class RetourLoc extends StatefulWidget {
  final TextEditingController dateFinEffectifController;
  final TextEditingController kilometrageRetourController;
  final TextEditingController pourcentageEssenceRetourController;
  final Map<String, dynamic> data;
  final Future<void> Function(TextEditingController) selectDateTime;
  final DateTime dateDebut;
  final Function(Map<String, dynamic>)? onFraisUpdated;

  const RetourLoc({
    Key? key,
    required this.dateFinEffectifController,
    required this.kilometrageRetourController,
    required this.pourcentageEssenceRetourController,
    required this.data,
    required this.selectDateTime,
    required this.dateDebut,
    this.onFraisUpdated,
  }) : super(key: key);

  @override
  State<RetourLoc> createState() => _RetourLocState();
}

class _RetourLocState extends State<RetourLoc> {
  bool _showContent = true;

  void _handleHeaderTap() {
    setState(() {
      _showContent = !_showContent;
    });
  }

  @override
  void initState() {
    super.initState();
    // Initialiser le contrôleur de date avec la date du jour si vide
    if (widget.dateFinEffectifController.text.isEmpty) {
      final now = DateTime.now();
      widget.dateFinEffectifController.text = DateFormat('EEEE d MMMM yyyy à HH:mm', 'fr_FR').format(now);
    } else if (widget.data['dateFinEffectif'] != null) {
      widget.dateFinEffectifController.text = widget.data['dateFinEffectif'];
    }
    
    // Ne pas initialiser automatiquement le niveau d'essence
    // Laisser vide jusqu'à ce que l'utilisateur le définisse explicitement
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRetourVehiculeSection(context),
      ],
    );
  }

  Widget _buildRetourVehiculeSection(BuildContext context) {
    return Container(
      width: double.infinity,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête de section avec flèche
          GestureDetector(
            onTap: _handleHeaderTap,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange[700]!.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.directions_car_filled_rounded, color: Colors.orange[700], size: 24),
                      const SizedBox(width: 12),
                      Text(
                        "Retour du véhicule",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[700],
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    _showContent ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: Colors.orange[700],
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
          if (_showContent)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDateFinField(context),
                  const SizedBox(height: 20),
                  _buildKilometrageRetourField(context),
                  const SizedBox(height: 20),
                  _buildNiveauEssenceField(context),
                  const SizedBox(height: 20),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDateFinField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Date de fin effective",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: widget.dateFinEffectifController,
          readOnly: true,
          onTap: () async {
            final pickedDate = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: widget.dateDebut, // Date de début comme première date sélectionnable
              lastDate: DateTime(2100),
              locale: const Locale('fr', 'FR'),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.light(
                      primary: Color(0xFF08004D), // Couleur de sélection
                      onPrimary: Colors.white, // Couleur du texte sélectionné
                      surface: Colors.white, // Couleur de fond du calendrier
                      onSurface: Color(0xFF08004D), // Couleur du texte
                    ),
                    dialogBackgroundColor: Colors.white,
                  ),
                  child: child!,
                );
              },
            );
            if (pickedDate != null) {
              final pickedTime = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.now(),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.light(
                        primary: Color(0xFF08004D),
                        onPrimary: Colors.white,
                        surface: Colors.white,
                        onSurface: Color(0xFF08004D),
                      ),
                      dialogBackgroundColor: Colors.white,
                    ),
                    child: child!,
                  );
                },
              );
              if (pickedTime != null) {
                final dateTime = DateTime(
                  pickedDate.year,
                  pickedDate.month,
                  pickedDate.day,
                  pickedTime.hour,
                  pickedTime.minute,
                );
                
                final formattedDateTime =
                    DateFormat('EEEE d MMMM yyyy à HH:mm', 'fr_FR').format(dateTime);
                
                widget.dateFinEffectifController.text = formattedDateTime;
              }
            }
          },
          decoration: InputDecoration(
            hintText: "Sélectionner la date et l'heure de retour",
            prefixIcon: const Icon(Icons.calendar_today, color: Colors.orange),
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF08004D), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          ),
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[800],
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return "Ce champ est requis";
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildKilometrageRetourField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Kilométrage de retour",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: widget.kilometrageRetourController,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
          decoration: InputDecoration(
            hintText: "Entrez le kilométrage actuel",
            prefixIcon: const Icon(Icons.speed, color: Colors.orange),
            suffixIcon: IconButton(
              icon: Icon(Icons.check_circle, color: Colors.orange[200]),
              onPressed: () {
                // Fermer le clavier
                FocusScope.of(context).unfocus();
              },
            ),
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF08004D), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          ),
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[800],
          ),
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              final intValue = int.tryParse(value);
              if (intValue == null) {
                return "Veuillez entrer un nombre valide";
              }
              if (widget.data['kilometrageDepart'] != null &&
                  widget.data['kilometrageDepart'].isNotEmpty &&
                  intValue < int.parse(widget.data['kilometrageDepart'])) {
                return "Ne peut pas être inférieur au kilométrage de départ";
              }
            }
            return null;
          },
        ),
        if (widget.data['kilometrageDepart'] != null && widget.data['kilometrageDepart'].isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8.0, left: 8.0),
            child: Text(
              "Kilométrage de départ: ${widget.data['kilometrageDepart']}",
              style: TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: Colors.grey[600],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildNiveauEssenceField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Niveau d'essence au retour",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.local_gas_station, color: Colors.orange),
                  const SizedBox(width: 10),
                  Text(
                    "Sélectionnez le niveau d'essence",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      "${widget.pourcentageEssenceRetourController.text}%",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[800],
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Slider(
                value: double.tryParse(widget.pourcentageEssenceRetourController.text) ?? 0,
                min: 0,
                max: 100,
                divisions: 10, // 10 divisions pour des valeurs de 10 en 10
                activeColor: Colors.orange[700],
                inactiveColor: Colors.orange[700]!.withOpacity(0.3),
                label: '${(double.tryParse(widget.pourcentageEssenceRetourController.text) ?? 0).toInt()}%',
                onChanged: (double value) {
                  setState(() {
                    // Arrondir à la dizaine la plus proche
                    final roundedValue = (value / 10).round() * 10;
                    widget.pourcentageEssenceRetourController.text = roundedValue.toInt().toString();
                    if (widget.onFraisUpdated != null) {
                      widget.onFraisUpdated!({'pourcentageEssenceRetour': roundedValue.toInt().toString()});
                    }
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }


}
