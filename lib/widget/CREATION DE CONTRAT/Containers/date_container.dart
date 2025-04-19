import 'package:flutter/material.dart';
import 'package:contraloc/widget/CREATION DE CONTRAT/create_contrat.dart';
import 'package:intl/intl.dart'; // Add this line

class DateContainer extends StatefulWidget {
  final TextEditingController dateDebutController;
  final TextEditingController dateFinTheoriqueController;
  final Future<void> Function(TextEditingController) selectDateTime;

  const DateContainer({
    super.key,
    required this.dateDebutController,
    required this.dateFinTheoriqueController,
    required this.selectDateTime,
  });

  @override
  State<DateContainer> createState() => _DateContainerState();
}

class _DateContainerState extends State<DateContainer> {
  bool _showContent = true;

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
                    Icon(Icons.calendar_today, color: const Color(0xFF08004D), size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Période de location",
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
                    CreateContrat.buildDateField(
                      "Date de début",
                      widget.dateDebutController,
                      true,
                      context,
                      widget.selectDateTime,
                    ),
                    if (widget.dateDebutController.text.isNotEmpty) ...[
                      Center(
                        child: (() {
                          String dateText = widget.dateDebutController.text;
                          try {
                            final now = DateTime.now();
                            final parsedDate = DateFormat('EEEE d MMMM yyyy à HH:mm', 'fr_FR').parse(dateText);
                            
                            final dateWithCurrentYear = DateTime(
                              now.year,
                              parsedDate.month,
                              parsedDate.day,
                              parsedDate.hour,
                              parsedDate.minute,
                            );
                            
                            final dateToCompare = dateWithCurrentYear.isBefore(now) && 
                                                 parsedDate.month < now.month ? 
                                                 DateTime(now.year + 1, parsedDate.month, parsedDate.day, 
                                                         parsedDate.hour, parsedDate.minute) : 
                                                 dateWithCurrentYear;
                            
                            if (dateToCompare.isAfter(now) && 
                                !(dateToCompare.year == now.year && 
                                  dateToCompare.month == now.month && 
                                  dateToCompare.day == now.day)) {
                              return Text(
                                textAlign: TextAlign.center,
                                'Véhicule réservé pour le:$dateText',
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.w900,
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          } catch (e) {
                            return const SizedBox.shrink();
                          }
                        }()),
                      ),const SizedBox(height: 15),
                    ],
                    
                    CreateContrat.buildDateField(
                      "Date de fin théorique",
                      widget.dateFinTheoriqueController,
                      false,
                      context,
                      widget.selectDateTime,
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
