import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ContraLoc/services/firestore_service.dart';
import '../modifier.dart';

class CalendarScreen extends StatefulWidget {
  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _selectedDay = DateTime.now();
  List<DocumentSnapshot> _contracts = [];
  Map<DateTime, List<DocumentSnapshot>> _contractsByDay = {};

  @override
  void initState() {
    super.initState();
    _fetchContractsForSelectedDay();
    _fetchAllContracts();
  }

  void _fetchContractsForSelectedDay() async {
    final snapshot = await FirestoreService.getContratsByDate(_selectedDay);
    setState(() {
      _contracts = snapshot.docs;
    });
  }

  void _fetchAllContracts() async {
    final snapshot = await FirestoreService.getAllContrats();
    final contracts = snapshot.docs;
    final Map<DateTime, List<DocumentSnapshot>> contractsByDay = {};

    for (var contract in contracts) {
      final data = contract.data() as Map<String, dynamic>;
      final date = (data['dateCreation'] as Timestamp).toDate();
      final day = DateTime(date.year, date.month, date.day);
      if (contractsByDay[day] == null) {
        contractsByDay[day] = [];
      }
      contractsByDay[day]!.add(contract);
    }

    setState(() {
      _contractsByDay = contractsByDay;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          TableCalendar(
            locale: 'fr_FR',
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _selectedDay,
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
              });
              _fetchContractsForSelectedDay();
            },
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Colors.blueAccent,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Colors.deepOrange,
                shape: BoxShape.circle,
              ),
              markersMaxCount: 1,
              markerDecoration: BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
              ),
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
            eventLoader: (day) {
              return _contractsByDay[day] ?? [];
            },
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: _contracts.length,
            itemBuilder: (context, index) {
              final contract = _contracts[index];
              final data = contract.data() as Map<String, dynamic>;

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ModifierScreen(
                        contratId: contract.id,
                        data: data,
                      ),
                    ),
                  );
                },
                child: Card(
                  elevation: 4,
                  margin: EdgeInsets.symmetric(
                    horizontal: MediaQuery.of(context).size.width * 0.05,
                    vertical: MediaQuery.of(context).size.width * 0.02,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Container(
                          width: MediaQuery.of(context).size.width * 0.2,
                          height: MediaQuery.of(context).size.width * 0.2,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.grey[200],
                            image: data['photoVehiculeUrl'] != null &&
                                    data['photoVehiculeUrl'].isNotEmpty
                                ? DecorationImage(
                                    image:
                                        NetworkImage(data['photoVehiculeUrl']),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: data['photoVehiculeUrl'] == null ||
                                  data['photoVehiculeUrl'].isEmpty
                              ? const Icon(Icons.directions_car,
                                  size: 50, color: Colors.grey)
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "${data['nom'] ?? ''} ${data['prenom'] ?? ''}",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize:
                                      MediaQuery.of(context).size.width * 0.045,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Date de création : ${data['dateDebut'] ?? ''}",
                                style: TextStyle(
                                  fontSize:
                                      MediaQuery.of(context).size.width * 0.035,
                                  color: Colors.grey[600],
                                ),
                              ),
                              Text(
                                "Immatriculation : ${data['immatriculation'] ?? ''}",
                                style: TextStyle(
                                  fontSize:
                                      MediaQuery.of(context).size.width * 0.035,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 18,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
