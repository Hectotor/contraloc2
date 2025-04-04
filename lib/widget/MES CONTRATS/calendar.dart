import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:ContraLoc/widget/MES%20CONTRATS/vehicle_access_manager.dart';

class CalendarScreen extends StatefulWidget {
  final Function(int)? onEventsCountChanged;

  CalendarScreen({Key? key, this.onEventsCountChanged}) : super(key: key);

  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  // Initialisation avec la date et l'heure françaises
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  Map<DateTime, List<Map<String, dynamic>>> _reservedContracts = {};
  List<Map<String, dynamic>> _selectedDayContracts = [];
  CalendarFormat _calendarFormat = CalendarFormat.month;
  final Map<String, String?> _photoUrlCache = {};
  
  // Gestionnaire d'accès aux véhicules
  late VehicleAccessManager _vehicleAccessManager;
  String? _targetUserId;

  // Couleur principale pour ce composant (bleu foncé)
  final Color primaryColor = Color(0xFF08004D);

  @override
  void initState() {
    super.initState();
    _vehicleAccessManager = VehicleAccessManager();
    _initializeAccess();
    _getContracts();
  }

  // Méthode pour initialiser les gestionnaires d'accès
  Future<void> _initializeAccess() async {
    try {
      await _vehicleAccessManager.initialize();
      _targetUserId = _vehicleAccessManager.getTargetUserId();
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      // Erreur silencieuse
    }
  }

  Future<void> _getContracts() async {
    try {
      final effectiveUserId = _targetUserId ?? FirebaseAuth.instance.currentUser?.uid;
      if (effectiveUserId == null) {
        return;
      }
      
      // Chargement initial des données
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(effectiveUserId)
          .collection('locations')
          .where('status', isEqualTo: 'réservé')
          .get();
      
      _processContracts(snapshot);
      
      // Mise en place d'un écouteur pour les mises à jour
      FirebaseFirestore.instance
          .collection('users')
          .doc(effectiveUserId)
          .collection('locations')
          .where('status', isEqualTo: 'réservé')
          .snapshots()
          .listen((snapshot) {
            _processContracts(snapshot);
          });
    } catch (e) {
      // Erreur silencieuse
    }
  }

  void _processContracts(QuerySnapshot snapshot) {
    _reservedContracts.clear();
    
    for (var doc in snapshot.docs) {
      final contract = doc.data() as Map<String, dynamic>;
      
      final dateDebut = _parseDate(contract['dateDebut']);
      
      // On ne prend en compte que la date de début
      if (dateDebut != null) {
        final dateKey = DateTime(dateDebut.year, dateDebut.month, dateDebut.day);
        if (!_reservedContracts.containsKey(dateKey)) {
          _reservedContracts[dateKey] = [];
        }
        _reservedContracts[dateKey]!.add(contract);
      }
    }
    
    setState(() {
      // Mettre à jour les contrats pour la date sélectionnée
      _updateSelectedDayContracts();
    });
  }

  DateTime? _parseDate(dynamic timestamp) {
    if (timestamp == null) return null;
    
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    } else if (timestamp is String) {
      try {
        return DateFormat('EEEE d MMMM yyyy à HH:mm', 'fr_FR').parse(timestamp);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  void _updateSelectedDayContracts() {
    final selectedDate = DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day);
    setState(() {
      _selectedDayContracts = _reservedContracts[selectedDate] ?? [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Calendrier
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildCalendar(),
          ),
          
          // Liste des véhicules réservés
          Expanded(
            child: _selectedDayContracts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_available, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          "Aucune réservation pour cette date",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    itemCount: _selectedDayContracts.length,
                    itemBuilder: (context, index) {
                      final contract = _selectedDayContracts[index];
                      return FutureBuilder<String?>(
                        future: _getVehiclePhotoUrl(contract['immatriculation']),
                        builder: (context, snapshot) {
                          final photoUrl = snapshot.data;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: _buildReservedVehicleCard(context, contract, photoUrl),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    return Card(
      margin: EdgeInsets.all(8.0),
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: TableCalendar(
          locale: 'fr_FR',  // Utilisation de la locale française
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          calendarFormat: _calendarFormat,
          eventLoader: (day) {
            final dateKey = DateTime(day.year, day.month, day.day);
            return _reservedContracts[dateKey] ?? [];
          },
          selectedDayPredicate: (day) {
            return isSameDay(_selectedDay, day);
          },
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
              _updateSelectedDayContracts();
            });
          },
          onFormatChanged: (format) {
            setState(() {
              _calendarFormat = format;
            });
          },
          onPageChanged: (focusedDay) {
            _focusedDay = focusedDay;
          },
          calendarStyle: CalendarStyle(
            markersMaxCount: 3,
            markerDecoration: BoxDecoration(
              color: primaryColor,
              shape: BoxShape.circle,
            ),
            selectedDecoration: BoxDecoration(
              color: primaryColor,
              shape: BoxShape.circle,
            ),
            todayDecoration: BoxDecoration(
              color: primaryColor.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            weekendTextStyle: TextStyle(color: primaryColor),
          ),
          headerStyle: HeaderStyle(
            formatButtonVisible: true,
            formatButtonDecoration: BoxDecoration(
              color: Colors.orange,
              borderRadius: BorderRadius.circular(16),
            ),
            formatButtonTextStyle: TextStyle(color: Colors.white),
            titleCentered: true,
            titleTextStyle: TextStyle(
              color: primaryColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            leftChevronIcon: Icon(Icons.chevron_left, color: Colors.orange),
            rightChevronIcon: Icon(Icons.chevron_right, color: Colors.orange),
            titleTextFormatter: (date, locale) => DateFormat.yMMMM(locale).format(date),
          ),
          daysOfWeekStyle: DaysOfWeekStyle(
            weekdayStyle: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
            weekendStyle: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
          ),
          calendarBuilders: CalendarBuilders(
            markerBuilder: (context, date, events) {
              if (events.isEmpty) return null;
              return Positioned(
                right: 1,
                bottom: 1,
                child: Container(
                  padding: EdgeInsets.all(4.0),
                  decoration: BoxDecoration(
                    shape: BoxShape.rectangle,

                    color: Colors.orange,

                  ),
                  child: Text(
                    '${events.length}',
                    style: TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
              );
            },
          ),
          startingDayOfWeek: StartingDayOfWeek.monday,  // Semaine commençant le lundi (format français)
          availableCalendarFormats: const {
            CalendarFormat.month: 'Mois',  // Traduction en français
          },
        ),
      ),
    );
  }

  Widget _buildReservedVehicleCard(BuildContext context, Map<String, dynamic> contract, String? photoUrl) {
    return Container(
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
          // En-tête de la carte
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.orange, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "${contract['nom'] ?? ''} ${contract['prenom'] ?? ''}",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          // Contenu de la carte
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Photo du véhicule
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey[100],
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 6,
                        spreadRadius: 1,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: (photoUrl != null && photoUrl.isNotEmpty)
                      ? Image.network(
                          photoUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Center(
                            child: Icon(
                              Icons.directions_car,
                              size: 40,
                              color: Colors.orange,
                            ),
                          ),
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                                color: primaryColor,
                              ),
                            );
                          },
                        )
                      : Center(
                          child: Icon(
                            Icons.directions_car,
                            size: 40,
                            color: Colors.orange,
                          ),
                        ),
                  ),
                ),
                const SizedBox(width: 16),
                // Informations du contrat
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow("Début", _formatDate(contract['dateDebut'])),
                      const SizedBox(height: 12),
                      _buildInfoRow("Véhicule", contract['immatriculation'] ?? "Non spécifié"),
                      if (contract['marque'] != null && contract['modele'] != null) ...[  
                        const SizedBox(height: 12),
                        _buildInfoRow("Modèle", "${contract['marque']} ${contract['modele']}"),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 70,
          child: Text(
            "$label :",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.orange,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[800],
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return "Non spécifié";
    
    try {
      if (date is String) {
        // Format court JJ/MM/AAAA
        final parts = date.split(' ');
        if (parts.length >= 3) {
          final day = parts[1];
          final month = _getMonthNumber(parts[2]);
          final year = parts[3];
          return "$day/$month/$year";
        }
        return date;
      }
      return "Format inconnu";
    } catch (e) {
      return "Erreur de format";
    }
  }

  int _getMonthNumber(String month) {
    const months = {
      'janvier': 1, 'février': 2, 'mars': 3, 'avril': 4, 'mai': 5, 'juin': 6,
      'juillet': 7, 'août': 8, 'septembre': 9, 'octobre': 10, 'novembre': 11, 'décembre': 12
    };
    return months[month.toLowerCase()] ?? 0;
  }

  Future<String?> _getVehiclePhotoUrl(String immatriculation) async {
    final cacheKey = immatriculation;
    if (_photoUrlCache.containsKey(cacheKey)) {
      return _photoUrlCache[cacheKey];
    }

    try {
      // Utiliser le gestionnaire d'accès aux véhicules pour récupérer le véhicule par immatriculation
      final vehiculeDoc = await _vehicleAccessManager.getVehicleByImmatriculation(immatriculation);

      if (vehiculeDoc.docs.isNotEmpty) {
        // Accéder aux données de manière sûre
        final data = vehiculeDoc.docs.first.data();
        String? photoUrl;

        if (data != null && data is Map<String, dynamic>) {
          if (data.containsKey('photoUrls') && data['photoUrls'] is List && (data['photoUrls'] as List).isNotEmpty) {
            photoUrl = (data['photoUrls'] as List).first.toString();
          } else if (data.containsKey('photoVehiculeUrl')) {
            photoUrl = data['photoVehiculeUrl'] as String?;
          }
        }

        _photoUrlCache[cacheKey] = photoUrl;
        return photoUrl;
      }

      _photoUrlCache[cacheKey] = null;
      return null;
    } catch (e) {
      _photoUrlCache[cacheKey] = null;
      return null;
    }
  }
}
