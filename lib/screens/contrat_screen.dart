import 'package:flutter/material.dart';
import '../widget/MES CONTRATS/contrat_encours.dart';
import '../widget/MES CONTRATS/contrat_restitues.dart';
import '../widget/MES CONTRATS/calendar.dart';

class ContratScreen extends StatefulWidget {
  final bool showSuccessMessage;
  final bool showRestitues;
  final BottomNavigationBar? bottomNavigationBar;

  const ContratScreen({
    Key? key,
    this.showSuccessMessage = false,
    this.showRestitues = false,
    this.bottomNavigationBar,
  }) : super(key: key);

  @override
  State<ContratScreen> createState() => _ContratScreenState();
}

class _ContratScreenState extends State<ContratScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Set the initial tab based on the showRestitues parameter
    if (widget.showRestitues) {
      _tabController.index = 1; // Restitués tab
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFF08004D),
        elevation: 0,
        toolbarHeight: kToolbarHeight,
        title: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorSize: TabBarIndicatorSize.label,
          tabs: const [
            Tab(text: 'En cours'),
            Tab(text: 'Restitués'),
            Tab(text: 'Calendrier'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: En cours
          ContratEnCours(
            searchText: "",
          ),
          
          // Tab 2: Restitués
          ContratRestitues(
            searchText: "",
          ),
          
          // Tab 3: Calendrier
          CalendarScreen(),
        ],
      ),
      bottomNavigationBar: widget.bottomNavigationBar,
    );
  }
}
