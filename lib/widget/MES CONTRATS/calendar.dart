import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:ContraLoc/widget/MES%20CONTRATS/vehicle_access_manager.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CalendarScreen extends StatefulWidget {
  final Function(int)? onEventsCountChanged;

  CalendarScreen({Key? key, this.onEventsCountChanged}) : super(key: key);

  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late VehicleAccessManager _vehicleAccessManager;
  bool _isInitialized = false;
  String? _targetUserId;
  Stream<QuerySnapshot>? _contractsStream;
  Map<DateTime, List<Map<String, dynamic>>> _reservedContracts = {};
  List<Map<String, dynamic>> _selectedDayContracts = [];
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;
  final Map<String, String?> _photoUrlCache = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _focusedDay = DateTime.now();
    _calendarFormat = CalendarFormat.month;
    _initializeAccess();
    print('CalendarScreen initState');
  }

  Future<void> _initializeAccess() async {
    print('Initialisation du calendrier');
    try {
      final effectiveUserId = _targetUserId ?? FirebaseAuth.instance.currentUser?.uid;
      if (effectiveUserId == null) {
        print('Aucun utilisateur connecté');
        return;
      }
      
      _targetUserId = effectiveUserId;
      _isInitialized = true;
      
      // Initialisation du stream des contrats
      _contractsStream = FirebaseFirestore.instance
          .collection('users')
          .doc(effectiveUserId)
          .collection('locations')
          .where('status', isEqualTo: 'réservé')
          .snapshots();
      
      // Chargement initial des données
      final snapshot = await _contractsStream!.first;
      _processContracts(snapshot);
      
      print('Données initiales chargées');
    } catch (e) {
      print('Erreur lors de l\'initialisation: $e');
    }
  }

  Stream<QuerySnapshot> _getReservedContractsStream() {
    if (!_isInitialized) {
      print('Calendrier non initialisé, initialisation en cours...');
      _initializeAccess();
      return Stream.empty();
    }
    
    if (_contractsStream == null) {
      print('Stream des contrats non initialisé');
      return Stream.empty();
    }
    
    print('Stream des contrats actif');
    return _contractsStream!;
  }

  void _processContracts(QuerySnapshot snapshot) {
    print('Traitement des contrats (${snapshot.docs.length} contrats)');
    _reservedContracts.clear();
    
    for (var doc in snapshot.docs) {
      final contract = doc.data() as Map<String, dynamic>;
      print('Contrat: ${contract['immatriculation']} - ${contract['dateDebut']}');
      
      final dateDebut = _parseDate(contract['dateDebut']);
      
      // On ne prend en compte que la date de début
      if (dateDebut != null) {
        print('Date valide: $dateDebut');
        final dateKey = DateTime(dateDebut.year, dateDebut.month, dateDebut.day);
        if (!_reservedContracts.containsKey(dateKey)) {
          _reservedContracts[dateKey] = [];
        }
        _reservedContracts[dateKey]!.add(contract);
        print('Ajout du contrat pour la date: ${dateDebut.day}/${dateDebut.month}/${dateDebut.year}');
      } else {
        print('Date invalide: ${contract['dateDebut']}');
      }
    }
    
    setState(() {
      print('Mise à jour de l\'interface');
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
        print('Erreur de parsing de la date: $e');
        return null;
      }
    }
    return null;
  }

  void _updateSelectedDayContracts() {
    print('Mise à jour des contrats pour la date sélectionnée: ${_selectedDay.toString()}');
    final selectedDate = DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day);
    setState(() {
      _selectedDayContracts = _reservedContracts[selectedDate] ?? [];
      print('Nombre de contrats trouvés pour cette date: ${_selectedDayContracts.length}');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF08004D).withOpacity(0.05), Colors.white],
          ),
        ),
        child: Column(
          children: [
            _buildCalendar(),
            Expanded(
              child: _buildReservedVehiclesList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendar() {
    return Card(
      margin: const EdgeInsets.all(8.0),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: TableCalendar(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          calendarFormat: _calendarFormat,
          selectedDayPredicate: (day) {
            return isSameDay(_selectedDay, day);
          },
          eventLoader: (day) {
            final dateKey = DateTime(day.year, day.month, day.day);
            return _reservedContracts[dateKey] ?? [];
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
            markerDecoration: const BoxDecoration(
              color: Color(0xFF08004D),
              shape: BoxShape.circle,
            ),
            selectedDecoration: const BoxDecoration(
              color: Color(0xFF08004D),
              shape: BoxShape.circle,
            ),
            todayDecoration: BoxDecoration(
              color: Color(0xFF08004D).withOpacity(0.5),
              shape: BoxShape.circle,
            ),
          ),
          headerStyle: HeaderStyle(
            formatButtonTextStyle: const TextStyle(color: Colors.white),
            formatButtonDecoration: BoxDecoration(
              color: Color(0xFF08004D),
              borderRadius: BorderRadius.circular(20.0),
            ),
            titleCentered: true,
            titleTextStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF08004D),
            ),
            formatButtonVisible: true,
            formatButtonShowsNext: true,
            titleTextFormatter: (date, format) => DateFormat.yMMMM('fr_FR').format(date),
          ),
          daysOfWeekStyle: DaysOfWeekStyle(
            weekdayStyle: TextStyle(color: Color(0xFF08004D)),
            weekendStyle: TextStyle(color: Color(0xFF08004D)),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey[300]!),
              ),
            ),
          ),
          calendarBuilders: CalendarBuilders(
            dowBuilder: (context, day) {
              final weekday = day.weekday;
              final dayText = DateFormat.E('fr_FR').format(day);
              return Center(
                child: Text(
                  dayText,
                  style: TextStyle(
                    color: weekday == 6 || weekday == 7
                        ? Colors.red
                        : Color(0xFF08004D),
                  ),
                ),
              );
            },
            markerBuilder: (context, date, events) {
              if (events.isEmpty) {
                return null; // Ne rien afficher s'il n'y a pas d'événements
              }
              
              return Positioned(
                right: 1,
                bottom: 1,
                child: Container(
                  padding: EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Color(0xFF08004D),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${events.length}',
                    style: TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
              );
            },
          ),
          startingDayOfWeek: StartingDayOfWeek.monday,
          availableCalendarFormats: const {
            CalendarFormat.month: 'Mois',
          },
        ),
      ),
    );
  }

  Widget _buildReservedVehiclesList() {
    if (_selectedDayContracts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun véhicule réservé pour le\n${DateFormat('dd/MM/yyyy').format(_selectedDay)}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: _selectedDayContracts.length,
      itemBuilder: (context, index) {
        final contract = _selectedDayContracts[index];
        return _buildVehicleCard(contract);
      },
    );
  }

  Widget _buildVehicleCard(Map<String, dynamic> contract) {
    final String immatriculation = contract['immatriculation'] ?? 'Inconnu';
    final String marque = contract['marque'] ?? 'Inconnu';
    final String modele = contract['modele'] ?? 'Inconnu';
    final String nomClient = contract['nomClient'] ?? 'Inconnu';
    final String prenomClient = contract['prenomClient'] ?? 'Inconnu';
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                FutureBuilder<String?>(
                  future: _getVehiclePhotoUrl(immatriculation),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return _buildPlaceholderIcon();
                    }
                    
                    if (snapshot.hasData && snapshot.data != null) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          snapshot.data!,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildPlaceholderIcon(),
                        ),
                      );
                    }
                    
                    return _buildPlaceholderIcon();
                  },
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$marque $modele',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF08004D),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        immatriculation,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow(Icons.person, '$prenomClient $nomClient'),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.calendar_today,
              'Du ${_formatDate(contract['dateDebut'])} au ${_formatDate(contract['dateFin'])}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderIcon() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        Icons.directions_car,
        size: 40,
        color: Colors.grey[400],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[800],
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Date inconnue';
    
    if (timestamp is Timestamp) {
      return DateFormat('dd/MM/yyyy').format(timestamp.toDate());
    } else if (timestamp is String) {
      try {
        return DateFormat('dd/MM/yyyy').format(DateFormat('EEEE d MMMM yyyy à HH:mm', 'fr_FR').parse(timestamp));
      } catch (e) {
        try {
          return DateFormat('dd/MM/yyyy').format(DateFormat('dd/MM/yyyy').parse(timestamp));
        } catch (e) {
          return timestamp;
        }
      }
    }
    return 'Date inconnue';
  }

  Future<String?> _getVehiclePhotoUrl(String immatriculation) async {
    final cacheKey = immatriculation;
    if (_photoUrlCache.containsKey(cacheKey)) {
      return _photoUrlCache[cacheKey];
    }

    final vehiculeDoc = await _vehicleAccessManager.getVehicleByImmatriculation(immatriculation);

    if (vehiculeDoc.docs.isNotEmpty) {
      final data = vehiculeDoc.docs.first.data();
      String? photoUrl;
      
      if (data != null && data is Map<String, dynamic>) {
        photoUrl = data['photoVehiculeUrl'] as String?;
      }
      
      _photoUrlCache[cacheKey] = photoUrl;
      return photoUrl;
    }
    return null;
  }
}
