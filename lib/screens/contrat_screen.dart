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
  
  // Système de cache pour les contrats
  final Map<String, List<DocumentSnapshot>> _contractsCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  final Duration _cacheDuration = Duration(minutes: 5); // Durée de validité du cache
  
  // Clés de cache pour les différents types de contrats
  static const String _activeContractsKey = 'active_contracts';
  static const String _returnedContractsKey = 'returned_contracts';
  static const String _calendarContractsKey = 'calendar_contracts';
  static const String _deletedContractsKey = 'deleted_contracts';
  
  // Méthode pour invalider le cache
  void _invalidateCache() {
    _contractsCache.clear();
    _cacheTimestamps.clear();
  }
  
  // Méthode pour récupérer les contrats par catégorie
  Future<List<DocumentSnapshot>> _getContractsByCategory(String categoryKey) async {
    if (_cacheTimestamps[categoryKey] != null &&
        DateTime.now().difference(_cacheTimestamps[categoryKey]!) < _cacheDuration) {
      // Récupérer les données du cache
      final cachedContracts = _contractsCache[categoryKey];
      if (cachedContracts != null) {
        return cachedContracts;
      }
    }
    
    final effectiveUserId = _targetUserId ?? FirebaseAuth.instance.currentUser?.uid;
    if (effectiveUserId == null) return [];
    
    try {
      QuerySnapshot querySnapshot;
      switch (categoryKey) {
        case _activeContractsKey:
          querySnapshot = await FirebaseFirestore.instance
              .collection('users')
              .doc(effectiveUserId)
              .collection('locations')
              .where('status', isEqualTo: 'en_cours')
              .get();
          break;
        case _returnedContractsKey:
          querySnapshot = await FirebaseFirestore.instance
              .collection('users')
              .doc(effectiveUserId)
              .collection('locations')
              .where('status', isEqualTo: 'restitue')
              .get();
          break;
        case _calendarContractsKey:
          querySnapshot = await FirebaseFirestore.instance
              .collection('users')
              .doc(effectiveUserId)
              .collection('locations')
              .where('status', isEqualTo: 'réservé')
              .get();
          break;
        case _deletedContractsKey:
          querySnapshot = await FirebaseFirestore.instance
              .collection('users')
              .doc(effectiveUserId)
              .collection('locations')
              .where('statussupprime', isEqualTo: 'supprimé')
              .get();
          break;
        default:
          return [];
      }
      
      // Stocker les données en cache
      _contractsCache[categoryKey] = querySnapshot.docs;
      _cacheTimestamps[categoryKey] = DateTime.now();
      
      return querySnapshot.docs;
    } catch (e) {
      print('Erreur lors de la récupération des contrats: $e');
      return [];
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
        
        // Invalider le cache après la suppression des contrats
        _invalidateCache();
      }
    } catch (e) {
      print('Erreur lors de la suppression des contrats expirés: $e');
    }
  }
  
  // Méthode pour charger les compteurs de contrats
  Future<void> _loadContractCounts() async {
    if (!_isInitialized) return;
    
    final effectiveUserId = _targetUserId ?? FirebaseAuth.instance.currentUser?.uid;
    if (effectiveUserId == null) return;
    
    try {
      // Récupérer les contrats par catégorie
      final activeContracts = await _getContractsByCategory(_activeContractsKey);
      final returnedContracts = await _getContractsByCategory(_returnedContractsKey);
      final calendarContracts = await _getContractsByCategory(_calendarContractsKey);
      final deletedContracts = await _getContractsByCategory(_deletedContractsKey);
      
      // Compter localement les contrats par catégorie
      int activeCount = activeContracts.length;
      int returnedCount = returnedContracts.length;
      int calendarCount = calendarContracts.length;
      int deletedCount = deletedContracts.length;
      
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
