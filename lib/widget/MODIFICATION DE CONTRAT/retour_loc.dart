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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête de section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.teal[700]!.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.directions_car_filled_rounded, color: Colors.teal[700], size: 24),
                const SizedBox(width: 12),
                Text(
                  "Retour du véhicule",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal[700],
                  ),
                ),
              ],
            ),
          ),
          // Contenu de la section
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
            prefixIcon: const Icon(Icons.calendar_today, color: Colors.teal),
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
          decoration: InputDecoration(
            hintText: "Entrez le kilométrage actuel",
            prefixIcon: const Icon(Icons.speed, color: Colors.teal),
            suffixIcon: IconButton(
              icon: Icon(Icons.check_circle, color: Colors.teal[200]),
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
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
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
                  Icon(Icons.local_gas_station, color: Colors.teal),
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
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildEssenceOption("0", "Vide"),
                  _buildEssenceOption("1/4", "1/4"),
                  _buildEssenceOption("1/2", "1/2"),
                  _buildEssenceOption("3/4", "3/4"),
                  _buildEssenceOption("1", "Plein"),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEssenceOption(String value, String label) {
    // Convertir la valeur du contrôleur en format comparable
    String currentValue = widget.pourcentageEssenceRetourController.text;
    String valueAsPercentage;
    
    switch (value) {
      case "0": valueAsPercentage = "0"; break;
      case "1/4": valueAsPercentage = "25"; break;
      case "1/2": valueAsPercentage = "50"; break;
      case "3/4": valueAsPercentage = "75"; break;
      case "1": valueAsPercentage = "100"; break;
      default: valueAsPercentage = "0";
    }
    
    bool isSelected = currentValue == valueAsPercentage;
    
    return InkWell(
      onTap: () {
        setState(() {
          // Convertir la valeur sélectionnée en pourcentage
          String percentage;
          switch (value) {
            case "0": percentage = "0"; break;
            case "1/4": percentage = "25"; break;
            case "1/2": percentage = "50"; break;
            case "3/4": percentage = "75"; break;
            case "1": percentage = "100"; break;
            default: percentage = "0";
          }
          
          widget.pourcentageEssenceRetourController.text = percentage;
          // Mettre à jour les données
          if (widget.onFraisUpdated != null) {
            widget.onFraisUpdated!({'pourcentageEssenceRetour': percentage});
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.teal.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.teal : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.teal[700] : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
