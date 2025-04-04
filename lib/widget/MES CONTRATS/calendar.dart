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
  String? _targetUserId;
  bool _isInitialized = false;
  final Map<String, String?> _photoUrlCache = {};
  
  // Calendrier
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;
  
  // Contrats réservés
  Map<DateTime, List<Map<String, dynamic>>> _reservedContracts = {};
  List<Map<String, dynamic>> _selectedDayContracts = [];
  
  @override
  void initState() {
    super.initState();
    _vehicleAccessManager = VehicleAccessManager();
    _initializeAccess();
  }
  
  Future<void> _initializeAccess() async {
    await _vehicleAccessManager.initialize();
    _targetUserId = _vehicleAccessManager.getTargetUserId();
    _isInitialized = true;
    _loadReservedContracts();
    if (mounted) {
      setState(() {});
    }
  }
  
  void _loadReservedContracts() {
    _getReservedContractsStream().listen((snapshot) {
      _processContracts(snapshot);
    });
  }
  
  void _processContracts(QuerySnapshot snapshot) {
    final contracts = <DateTime, List<Map<String, dynamic>>>{};
    
    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      
      // Récupérer les dates de début et fin
      final dateDebut = _parseTimestamp(data['dateDebut']);
      final dateFin = _parseTimestamp(data['dateFin']);
      
      if (dateDebut != null) {
        // Pour chaque jour entre dateDebut et dateFin
        DateTime currentDate = DateTime(dateDebut.year, dateDebut.month, dateDebut.day);
        final endDate = dateFin != null 
            ? DateTime(dateFin.year, dateFin.month, dateFin.day)
            : currentDate;
            
        while (currentDate.isBefore(endDate) || currentDate.isAtSameMomentAs(endDate)) {
          final dateKey = DateTime(currentDate.year, currentDate.month, currentDate.day);
          
          if (!contracts.containsKey(dateKey)) {
            contracts[dateKey] = [];
          }
          
          contracts[dateKey]!.add({
            'id': doc.id,
            'immatriculation': data['immatriculation'] ?? 'Inconnu',
            'marque': data['marque'] ?? 'Inconnu',
            'modele': data['modele'] ?? 'Inconnu',
            'nomClient': data['nomClient'] ?? 'Inconnu',
            'prenomClient': data['prenomClient'] ?? 'Inconnu',
            'dateDebut': data['dateDebut'],
            'dateFin': data['dateFin'],
            'status': data['status'] ?? 'réservé',
          });
          
          // Passer au jour suivant
          currentDate = currentDate.add(const Duration(days: 1));
        }
      }
    }
    
    setState(() {
      _reservedContracts = contracts;
      _updateSelectedDayContracts();
    });
    
    // Mettre à jour le compteur d'événements si nécessaire
    int totalEvents = 0;
    _reservedContracts.forEach((_, events) {
      totalEvents += events.length;
    });
    widget.onEventsCountChanged?.call(totalEvents);
  }
  
  void _updateSelectedDayContracts() {
    final selectedDate = DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day);
    _selectedDayContracts = _reservedContracts[selectedDate] ?? [];
  }
  
  DateTime? _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return null;
    
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    } else if (timestamp is String) {
      // Essayer de parser une date au format français
      try {
        final dateFormat = DateFormat('EEEE d MMMM yyyy à HH:mm', 'fr_FR');
        return dateFormat.parse(timestamp);
      } catch (e) {
        try {
          // Essayer le format court
          final dateFormat = DateFormat('dd/MM/yyyy');
          return dateFormat.parse(timestamp);
        } catch (e) {
          return null;
        }
      }
    }
    return null;
  }
  
  Stream<QuerySnapshot> _getReservedContractsStream() {
    if (!_isInitialized) {
      return Stream.fromFuture(
        Future(() async {
          await _initializeAccess();
          
          final effectiveUserId = _targetUserId ?? FirebaseAuth.instance.currentUser?.uid;
          if (effectiveUserId == null) {
            return FirebaseFirestore.instance.collection('empty').limit(0).get();
          }
          
          final snapshot = await FirebaseFirestore.instance
              .collection('users')
              .doc(effectiveUserId)
              .collection('locations')
              .where('status', isEqualTo: 'réservé')
              .get();
              
          return snapshot;
        })
      ).asyncExpand((snapshot) {
        final effectiveUserId = _targetUserId ?? FirebaseAuth.instance.currentUser?.uid;
        if (effectiveUserId == null) {
          return Stream.empty();
        }
        
        return FirebaseFirestore.instance
            .collection('users')
            .doc(effectiveUserId)
            .collection('locations')
            .where('status', isEqualTo: 'réservé')
            .snapshots();
      });
    }
    
    final effectiveUserId = _targetUserId ?? FirebaseAuth.instance.currentUser?.uid;
    if (effectiveUserId == null) {
      return Stream.empty();
    }
    
    return FirebaseFirestore.instance
        .collection('users')
        .doc(effectiveUserId)
        .collection('locations')
        .where('status', isEqualTo: 'réservé')
        .snapshots();
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
        // Essayer de parser une date au format français
        final dateFormat = DateFormat('EEEE d MMMM yyyy à HH:mm', 'fr_FR');
        final date = dateFormat.parse(timestamp);
        return DateFormat('dd/MM/yyyy').format(date);
      } catch (e) {
        try {
          // Essayer le format court
          final dateFormat = DateFormat('dd/MM/yyyy');
          final date = dateFormat.parse(timestamp);
          return DateFormat('dd/MM/yyyy').format(date);
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
