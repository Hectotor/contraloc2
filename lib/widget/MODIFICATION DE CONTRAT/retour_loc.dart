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
    // Initialiser le contrôleur de date avec la date du jour si vide
    if (widget.dateFinEffectifController.text.isEmpty) {
      final now = DateTime.now();
      widget.dateFinEffectifController.text = DateFormat('EEEE d MMMM yyyy à HH:mm', 'fr_FR').format(now);
    } else if (widget.data['dateFinEffectif'] != null) {
      widget.dateFinEffectifController.text = widget.data['dateFinEffectif'];
    }
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
                // Bouton de facturation intégré et plus discret
                InkWell(
                  onTap: () async {
                    // Mettre à jour les données avec le kilométrage de retour actuel
                    if (widget.kilometrageRetourController.text.isNotEmpty) {
                      widget.data['kilometrageRetour'] = widget.kilometrageRetourController.text;
                    }
                    
                    // Récupérer les valeurs de kilométrage
                    double kilometrageInitial = double.tryParse(widget.data['kilometrageDepart'] ?? '0') ?? 0;
                    double kilometrageActuel = double.tryParse(widget.kilometrageRetourController.text) ?? 0;
                    double tarifKilometrique = double.tryParse(widget.data['tarifKilometrique'] ?? '0') ?? 0;
                    
                    // Récupérer la date de fin effective
                    String dateFinEffective = widget.dateFinEffectifController.text;
                    
                    // Afficher la page de la facture et attendre le résultat
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FactureScreen(
                          data: widget.data,
                          onFraisUpdated: widget.onFraisUpdated ?? (frais) {},
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
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.teal.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long, color: Colors.teal[700], size: 20),
                        const SizedBox(width: 10),
                        Text(
                          "Facturer la location",
                          style: TextStyle(
                            color: Colors.teal[700],
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
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
}
