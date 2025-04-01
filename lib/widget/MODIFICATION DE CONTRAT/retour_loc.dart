import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart'; // Importer la bibliothèque Intl pour utiliser DateFormat
import 'facture.dart'; // Importer la nouvelle page FactureScreen

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
      final now = DateTime.now();
      widget.dateFinEffectifController.text = DateFormat('EEEE d MMMM yyyy à HH:mm', 'fr_FR').format(now);
    } 
  }

  // Méthode pour gérer la mise à jour des frais
  void _handleFraisUpdated(Map<String, dynamic> frais) {
    // Utiliser Future.microtask pour éviter les appels à setState pendant la construction
    Future.microtask(() {
      // Mettre à jour les données locales avec les frais
      setState(() {
        // Mettre à jour les données du widget avec les frais temporaires
        widget.data.addAll(frais);
      });
      
      // Transmettre les frais mis à jour au composant parent
      if (widget.onFraisUpdated != null) {
        widget.onFraisUpdated!(frais);
      }
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
        // Bouton pour afficher la page de la facture
        ElevatedButton.icon(
          onPressed: () async {
            // Mettre à jour les données avec le kilométrage de retour actuel
            if (widget.kilometrageRetourController.text.isNotEmpty) {
              widget.data['kilometrageRetour'] = widget.kilometrageRetourController.text;
            }
            
            // Récupérer les valeurs de kilométrage
            double kilometrageInitial = double.tryParse(widget.data['kilometrageDepart'] ?? '0') ?? 0;
            double kilometrageActuel = double.tryParse(widget.kilometrageRetourController.text) ?? 0;
            double tarifKilometrique = double.tryParse(widget.data['kilometrageSupp'] ?? '0') ?? 0;
            
            // Récupérer la date de fin effective
            String dateFinEffective = widget.dateFinEffectifController.text;
            
            // Afficher la page de la facture et attendre le résultat
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FactureScreen(
                  data: widget.data,
                  onFraisUpdated: _handleFraisUpdated,
                  kilometrageInitial: kilometrageInitial,
                  kilometrageActuel: kilometrageActuel,
                  tarifKilometrique: tarifKilometrique,
                  dateFinEffective: dateFinEffective,
                ),
              ),
            );
            
            // Mettre à jour l'interface si des données ont été renvoyées
            if (result != null && result is Map<String, dynamic>) {
              setState(() {
                // Mettre à jour les données locales avec les données de la facture
                widget.data.addAll(result);
                
                // Mettre à jour le contrôleur de kilométrage de retour si nécessaire
                if (result['kilometrageRetour'] != null) {
                  widget.kilometrageRetourController.text = result['kilometrageRetour'].toString();
                }
              });
              
              // Transmettre les données mises à jour au parent
              if (widget.onFraisUpdated != null) {
                widget.onFraisUpdated!(result);
              }
            }
          },
          icon: const Icon(Icons.receipt_long, color: Colors.white),
          label: const Text(
            "Facturer la location",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF08004D),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 30),
            minimumSize: const Size(double.infinity, 56), // Prend toute la largeur disponible
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 4,
            shadowColor: const Color(0x8008004D),
          ),
        ),
      ],
    );
  }
}
