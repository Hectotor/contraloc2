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
  
  // Méthode pour initialiser l'accès et charger les compteurs
  Future<void> _initializeAccess() async {
    await _vehicleAccessManager.initialize();
    _targetUserId = _vehicleAccessManager.getTargetUserId();
    _isInitialized = true;
    
    // Vérifier et supprimer les contrats expirés (après 90 jours)
    await _checkAndDeleteExpiredContracts();
    
    // Charger les compteurs
    _loadContractCounts();
  }
  
  // Méthode pour vérifier et supprimer les contrats expirés
  Future<void> _checkAndDeleteExpiredContracts() async {
    if (!_isInitialized) return;
    
    final effectiveUserId = _targetUserId ?? FirebaseAuth.instance.currentUser?.uid;
    if (effectiveUserId == null) return;
    
    try {
      final now = DateTime.now();
      final contractsToDelete = await FirebaseFirestore.instance
          .collection('users')
          .doc(effectiveUserId)
          .collection('locations')
          .where('statussupprime', isEqualTo: 'supprimé')
          .where('dateSuppressionDefinitive', isLessThan: now)
          .get();
      
      for (var doc in contractsToDelete.docs) {
        await doc.reference.delete();
        print('Contrat ${doc.id} supprimé définitivement (90 jours écoulés)');
      }
    } catch (e) {
      print('Erreur lors de la vérification des contrats expirés: $e');
    }
  }
  
  // Méthode pour charger les compteurs de contrats
  Future<void> _loadContractCounts() async {
    if (!_isInitialized) return;
    
    final effectiveUserId = _targetUserId ?? FirebaseAuth.instance.currentUser?.uid;
    if (effectiveUserId == null) return;
    
    try {
      // Faire une seule requête pour récupérer tous les contrats
      final allContractsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(effectiveUserId)
          .collection('locations')
          .get();
      
      // Compter localement les contrats par catégorie
      int activeCount = 0;
      int returnedCount = 0;
      int calendarCount = 0;
      int deletedCount = 0;
      
      for (var doc in allContractsSnapshot.docs) {
        final data = doc.data();
        
        // Vérifier si le contrat est marqué comme supprimé
        if (data['statussupprime'] == 'supprimé') {
          deletedCount++;
          continue; // Passer au contrat suivant car il est supprimé
        }
        
        // Compter selon le statut
        switch (data['status']) {
          case 'en_cours':
            activeCount++;
            break;
          case 'restitue':
            returnedCount++;
            break;
          case 'réservé':
            calendarCount++;
            break;
            
        }
      }
      
      if (mounted) {
        setState(() {
          _activeContractsCount = activeCount;
          _returnedContractsCount = returnedCount;
          _calendarEventsCount = calendarCount;
          _deletedContractsCount = deletedCount;
        });
      }
    } catch (e) {
      print('Erreur lors du chargement des compteurs: $e');
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
      body: TabBarView(
        controller: _tabController,
        physics: const BouncingScrollPhysics(),
        children: [
          // Contrats en cours
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: contrat_encours.ContratEnCours(searchText: ''),
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
            child: contrat_restitues.ContratRestitues(searchText: ''),
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
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: contrat_supprimes.ContratSupprimes(searchText: ''),
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
      bottomNavigationBar: widget.bottomNavigationBar,
    );
  }
}
