import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:ContraLoc/widget/MES CONTRATS/vehicle_access_manager.dart';
import 'package:ContraLoc/widget/modifier.dart';

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
      // Ajouter l'ID du document aux données du contrat
      contract['id'] = doc.id;
      
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

  void _showReservationsBottomSheet(BuildContext context, DateTime day) {
    final dateKey = DateTime(day.year, day.month, day.day);
    final reservations = _reservedContracts[dateKey] ?? [];

    if (reservations.isEmpty) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.6, // Hauteur fixe
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Barre de poignée
              Center(
                child: Container(
                  margin: EdgeInsets.only(top: 10),
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              // Titre
              Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Réservations du ${_formatDate(dateKey)}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.grey[600]),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Divider(),
              // Liste des réservations
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: reservations.length,
                  itemBuilder: (context, index) {
                    final reservation = reservations[index];
                    final immatriculation = reservation['immatriculation'] ?? '';
                    
                    return FutureBuilder<String?>(
                      future: _getVehiclePhotoUrl(immatriculation),
                      builder: (context, snapshot) {
                        final photoUrl = snapshot.data;
                        
                        return Card(
                          elevation: 2,
                          margin: EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ModifierScreen(
                                    contratId: reservation['id'] as String,
                                    data: reservation,
                                  ),
                                ),
                              );
                            },
                            child: Padding(
                              padding: EdgeInsets.all(12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Image du véhicule
                                  Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      color: Colors.grey[200],
                                    ),
                                    child: photoUrl != null
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: Image.network(
                                              photoUrl,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) => 
                                                Icon(Icons.directions_car, size: 40, color: Colors.grey[400]),
                                            ),
                                          )
                                        : Icon(Icons.directions_car, size: 40, color: Colors.grey[400]),
                                  ),
                                  SizedBox(width: 16),
                                  // Informations du véhicule et du client
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Nom du client
                                        Text(
                                          '${reservation['nom'] ?? ''} ${reservation['prenom'] ?? ''}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: primaryColor,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        // Informations du véhicule
                                        Row(
                                          children: [
                                            Icon(Icons.directions_car, size: 14, color: Colors.grey[600]),
                                            SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                '${reservation['marque'] ?? ''} ${reservation['modele'] ?? ''}',
                                                style: TextStyle(fontSize: 14),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 2),
                                        // Immatriculation
                                        Row(
                                          children: [
                                            Icon(Icons.pin, size: 14, color: Colors.grey[600]),
                                            SizedBox(width: 4),
                                            Text(
                                              '${reservation['immatriculation'] ?? 'Non spécifié'}',
                                              style: TextStyle(fontSize: 14),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 2),
                                        // Date
                                        Row(
                                          children: [
                                            Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                                            SizedBox(width: 4),
                                            Text(
                                              '${_formatDate(reservation['dateDebut'])}',
                                              style: TextStyle(fontSize: 14),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Icône pour indiquer qu'on peut cliquer
                                  Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
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

                      return Container();
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
            // Afficher le BottomSheet lorsque l'utilisateur clique sur un jour avec des réservations
            if (_reservedContracts[DateTime(selectedDay.year, selectedDay.month, selectedDay.day)] != null) {
              _showReservationsBottomSheet(context, selectedDay);
            }
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

  String _formatDate(dynamic date) {
    if (date == null) return "Date non disponible";
    
    // Si c'est un DateTime, le convertir en format JJ/MM/AAAA
    if (date is DateTime) {
      return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
    }
    
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
