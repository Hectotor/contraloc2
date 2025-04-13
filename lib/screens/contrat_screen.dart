import 'package:flutter/material.dart';
import '../widget/MES CONTRATS/contrat_encours.dart' as contrat_encours;
import '../widget/MES CONTRATS/contrat_restitues.dart' as contrat_restitues;
import '../widget/MES CONTRATS/calendar.dart' as calendar_screen;
import '../widget/MES CONTRATS/contrat_supprimes.dart' as contrat_supprimes;
import '../widget/MES CONTRATS/contrat_summary.dart' as contrat_summary;

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
    _tabController = TabController(length: 5, vsync: this);

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
          isScrollable: true,
          tabs: [
            Tab(
              child: Container(
                alignment: Alignment.center,
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'En cours',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                ),
              ),
            ),
            Tab(
              child: Container(
                alignment: Alignment.center,
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Restitués',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                ),
              ),
            ),
            Tab(
              child: Container(
                alignment: Alignment.center,
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Calendrier',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                ),
              ),
            ),
            Tab(
              child: Container(
                alignment: Alignment.center,
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Supprimés',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                ),
              ),
            ),
            Tab(
              child: Container(
                alignment: Alignment.center,
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Résumé',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ],
          indicatorSize: TabBarIndicatorSize.tab,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
        ),
      ),
      body: Column(
        children: [
          // TabBar pour la navigation entre les onglets
          Expanded(
            child: TabBarView(
              controller: _tabController,
              physics: const BouncingScrollPhysics(),
              children: [
                // Contrats en cours
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: contrat_encours.ContratEnCours(
                    searchText: '',
                  ),
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    return SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(1.0, 0.0),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeInOut,
                      )),
                      child: child,
                    );
                  },
                ),
                
                // Contrats restitués
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: contrat_restitues.ContratRestitues(
                    searchText: '',
                  ),
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    return SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(1.0, 0.0),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeInOut,
                      )),
                      child: child,
                    );
                  },
                ),
                
                // Calendrier
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: calendar_screen.CalendarScreen(),
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    return SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(1.0, 0.0),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeInOut,
                      )),
                      child: child,
                    );
                  },
                ),
                
                // Contrats supprimés
                contrat_supprimes.ContratSupprimes(
                  searchText: '',
                ),
                
                // Résumé des contrats
                contrat_summary.ContratSummary(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: widget.bottomNavigationBar,
    );
  }
}
