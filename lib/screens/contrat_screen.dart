import 'package:flutter/material.dart';
import '../widget/MES CONTRATS/contrat_encours.dart' as contrat_encours;
import '../widget/MES CONTRATS/contrat_restitues.dart' as contrat_restitues;
import '../widget/MES CONTRATS/calendar.dart' as calendar_screen;
import '../widget/MES CONTRATS/contrat_supprimes.dart' as contrat_supprimes;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widget/MES CONTRATS/vehicle_access_manager.dart' as vehicle_access_manager;

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
  late vehicle_access_manager.VehicleAccessManager _vehicleAccessManager;
  String? _targetUserId;
  bool _isInitialized = false;
  
  // Compteurs pour chaque type de contrat
  int _activeContractsCount = 0;
  int _returnedContractsCount = 0;
  int _calendarEventsCount = 0;
  int _deletedContractsCount = 0;
  
  // Méthode pour mettre à jour le compteur de contrats en cours
  void _updateActiveContractsCount(int count) {
    // Utiliser Future.microtask pour éviter d'appeler setState pendant la phase de build
    if (_activeContractsCount != count) {
      Future.microtask(() {
        if (mounted) {
          setState(() {
            _activeContractsCount = count;
          });
        }
      });
    }
  }
  
  // Méthode pour mettre à jour le compteur de contrats restitués
  void _updateReturnedContractsCount(int count) {
    if (_returnedContractsCount != count) {
      Future.microtask(() {
        if (mounted) {
          setState(() {
            _returnedContractsCount = count;
          });
        }
      });
    }
  }

  // Méthode pour mettre à jour le compteur d'événements du calendrier
  void _updateCalendarEventsCount(int count) {
    if (_calendarEventsCount != count) {
      Future.microtask(() {
        if (mounted) {
          setState(() {
            _calendarEventsCount = count;
          });
        }
      });
    }
  }

  // Méthode pour mettre à jour le compteur de contrats supprimés
  void _updateDeletedContractsCount(int count) {
    if (_deletedContractsCount != count) {
      Future.microtask(() {
        if (mounted) {
          setState(() {
            _deletedContractsCount = count;
          });
        }
      });
    }
  }
  
  // Méthode pour initialiser l'accès et charger les compteurs
  Future<void> _initializeAccess() async {
    try {
      await _vehicleAccessManager.initialize();
      _targetUserId = await _vehicleAccessManager.getTargetUserId();
      _isInitialized = true;
      
      // Vérifier et supprimer les contrats expirés (après 90 jours)
      await _checkAndDeleteExpiredContracts();
    } catch (e) {
      print("Erreur lors de l'initialisation de l'accès: $e");
    }
  }

  // Méthode pour vérifier et supprimer les contrats expirés
  Future<void> _checkAndDeleteExpiredContracts() async {
    if (!_isInitialized) return;
    
    final effectiveUserId = _targetUserId ?? FirebaseAuth.instance.currentUser?.uid;
    if (effectiveUserId == null) return;
    
    try {
      final now = DateTime.now();
      final dateLimit = now.subtract(const Duration(days: 90));
      
      // Récupérer d'abord tous les contrats restitués
      final contractsQuery = await FirebaseFirestore.instance
          .collection('users')
          .doc(effectiveUserId)
          .collection('locations')
          .where('status', isEqualTo: 'restitue')
          .get();
      
      // Filtrer localement ceux qui sont expirés (plus de 90 jours)
      final expiredContracts = contractsQuery.docs.where((doc) {
        final data = doc.data();
        if (data.containsKey('dateRestitution')) {
          final dateRestitution = data['dateRestitution'] as Timestamp?;
          if (dateRestitution != null) {
            return dateRestitution.toDate().isBefore(dateLimit);
          }
        }
        return false;
      }).toList();
      
      if (expiredContracts.isNotEmpty) {
        // Batch pour supprimer les contrats expirés
        final batch = FirebaseFirestore.instance.batch();
        
        for (var doc in expiredContracts) {
          batch.update(doc.reference, {'statussupprime': 'supprimé'});
        }
        
        await batch.commit();
        print('${expiredContracts.length} contrats expirés ont été marqués comme supprimés');
      }
    } catch (e) {
      print('Erreur lors de la suppression des contrats expirés: $e');
    }
  }
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    
    // Set the initial tab based on the showRestitues parameter
    if (widget.showRestitues) {
      _tabController.index = 1; // Restitués tab
    }
    
    // Initialiser le gestionnaire d'accès aux véhicules
    _vehicleAccessManager = vehicle_access_manager.VehicleAccessManager();
    _initializeAccess();
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
          isScrollable: true,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    margin: const EdgeInsets.only(right: 4),
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Color(0xFF08004D), width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          spreadRadius: 1,
                          blurRadius: 2,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    constraints: BoxConstraints(minWidth: 16, minHeight: 16),
                    alignment: Alignment.center,
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: Text(
                        '$_activeContractsCount',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF08004D),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const Text('En cours'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    margin: const EdgeInsets.only(right: 4),
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Color(0xFF08004D), width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          spreadRadius: 1,
                          blurRadius: 2,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    constraints: BoxConstraints(minWidth: 16, minHeight: 16),
                    alignment: Alignment.center,
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: Text(
                        '$_returnedContractsCount',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF08004D),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const Text('Restitués'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    margin: const EdgeInsets.only(right: 4),
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Color(0xFF08004D), width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          spreadRadius: 1,
                          blurRadius: 2,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    constraints: BoxConstraints(minWidth: 16, minHeight: 16),
                    alignment: Alignment.center,
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: Text(
                        '$_calendarEventsCount',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF08004D),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const Text('Réservés'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    margin: const EdgeInsets.only(right: 4),
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Color(0xFF08004D), width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          spreadRadius: 1,
                          blurRadius: 2,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    constraints: BoxConstraints(minWidth: 16, minHeight: 16),
                    alignment: Alignment.center,
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: Text(
                        '$_deletedContractsCount',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF08004D),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const Text('Supprimés'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Widgets invisibles pour charger les données initiales
          Offstage(
            offstage: true,
            child: SizedBox(
              height: 0,
              width: 0,
              child: contrat_encours.ContratEnCours(
                searchText: '',
                onContractsCountChanged: _updateActiveContractsCount,
              ),
            ),
          ),
          Offstage(
            offstage: true,
            child: SizedBox(
              height: 0,
              width: 0,
              child: contrat_restitues.ContratRestitues(
                searchText: '',
                onContractsCountChanged: _updateReturnedContractsCount,
              ),
            ),
          ),
          Offstage(
            offstage: true,
            child: SizedBox(
              height: 0,
              width: 0,
              child: calendar_screen.CalendarScreen(
                onEventsCountChanged: _updateCalendarEventsCount,
              ),
            ),
          ),
          Offstage(
            offstage: true,
            child: SizedBox(
              height: 0,
              width: 0,
              child: contrat_supprimes.ContratSupprimes(
                searchText: '',
                onContractsCountChanged: _updateDeletedContractsCount,
              ),
            ),
          ),
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
                    onContractsCountChanged: _updateActiveContractsCount,
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
                    onContractsCountChanged: _updateReturnedContractsCount,
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
                  child: calendar_screen.CalendarScreen(
                    onEventsCountChanged: _updateCalendarEventsCount,
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
                
                // Contrats supprimés
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: contrat_supprimes.ContratSupprimes(
                    searchText: '',
                    onContractsCountChanged: _updateDeletedContractsCount,
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
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: widget.bottomNavigationBar,
    );
  }
}
