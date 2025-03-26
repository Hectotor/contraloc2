import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart'; // Importer la bibliothèque Intl pour utiliser DateFormat
import 'frais_supplementaires.dart'; // Importer le popup des frais supplémentaires

class RetourLoc extends StatefulWidget {
  final TextEditingController dateFinEffectifController;
  final TextEditingController kilometrageRetourController;
  final Map<String, dynamic> data;
  final Future<void> Function(TextEditingController) selectDateTime;
  final DateTime dateDebut;
  final Function(Map<String, dynamic>)? onFraisUpdated;

  const RetourLoc({
    Key? key,
    required this.dateFinEffectifController,
    required this.kilometrageRetourController,
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
    // Initialiser le contrôleur de date avec la date du jour une seule fois
    if (widget.dateFinEffectifController.text.isEmpty) {
      widget.dateFinEffectifController.text = DateFormat('EEEE d MMMM yyyy à HH:mm', 'fr_FR').format(DateTime.now());
    }
  }

  // Méthode pour gérer la mise à jour des frais
  void _handleFraisUpdated(Map<String, dynamic> frais) {
    // Utiliser Future.microtask pour éviter les appels à setState pendant la construction
    Future.microtask(() {
      // Transmettre les frais mis à jour au composant parent
      if (widget.onFraisUpdated != null) {
        widget.onFraisUpdated!(frais);
      }
      
      setState(() {
        // Mettre à jour les données locales si nécessaire
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Retour du véhicule",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
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
            labelText: "Date de fin",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return "Ce champ est requis";
            }
            return null;
          },
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: widget.kilometrageRetourController,
          decoration: InputDecoration(
            labelText: "Kilométrage de retour",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            suffixIcon: IconButton(
              icon: const Icon(Icons.check_circle),
              onPressed: () {
                // Fermer le clavier
                FocusScope.of(context).unfocus();
              },
            ),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
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
        const SizedBox(height: 10),
        // Bouton pour afficher le popup des frais supplémentaires
        ElevatedButton.icon(
          onPressed: () async {
            // Afficher le popup des frais supplémentaires
            await showFraisSupplementairesDialog(
              context,
              widget.data,
              _handleFraisUpdated,
            );
          },
          icon: const Icon(Icons.attach_money, color: Colors.white),
          label: const Text(
            "Calculer les frais supplémentaires",
            style: TextStyle(color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF08004D),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }
}

// Fonction pour afficher le popup des frais supplémentaires
Future<void> showFraisSupplementairesDialog(
  BuildContext context,
  Map<String, dynamic> data,
  Function(Map<String, dynamic>) onFraisUpdated,
) async {
  await showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: FraisSupplementaires(
          data: data,
          onFraisUpdated: onFraisUpdated,
        ),
      );
    },
  );
}
