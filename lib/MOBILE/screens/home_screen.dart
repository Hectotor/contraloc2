import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:contraloc/MOBILE/widget/MES%20CONTRATS/vehicle_access_manager.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:contraloc/MOBILE/services/sync_queue_service.dart';
import '../HOME/delete_vehicule.dart';
import '../widget/CREATION DE CONTRAT/client.dart'; 
import '../services/auth_util.dart'; 
import '../services/connectivity_service.dart'; 
import '../HOME/button_add_vehicle.dart'; 
import '../HOME/vehicle_list_view.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late DeleteVehicule _deleteVehicule;
  String _prenom = '';
  String _nomEntreprise = ''; 
  String _searchQuery = ''; 
  bool _isSearching = false; 
  bool _showSearchBar = false; 
  final TextEditingController _searchController = TextEditingController(); 
  bool _isUserDataLoaded = false; 
  late VehicleAccessManager _vehicleAccessManager; 
  bool _isVehicleManagerInitialized = false; 
  
  // Service de connectivité
  final ConnectivityService _connectivityService = ConnectivityService();

  @override
  void initState() {
    super.initState();
    _deleteVehicule = DeleteVehicule(context);
    
    // Initialiser le gestionnaire d'accès aux véhicules
    _vehicleAccessManager = VehicleAccessManager.instance;
    
    // Charger les données utilisateur et initialiser le gestionnaire de véhicules
    _initializeData();
    _setupSubscriptionCheck();
    _setupSyncQueue();
    
    // Initialiser le service de connectivité
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _connectivityService.initialize(context);
    });
  }
  
  // Méthode pour charger les données utilisateur avec CollaborateurUtil
  Future<void> _loadUserData() async {
    try {
      // Récupérer les données d'authentification
      final authData = await AuthUtil.getAuthData();
      final isCollaborateur = authData['isCollaborateur'] ?? false;
      final adminId = authData['adminId'];
      final userId = FirebaseAuth.instance.currentUser?.uid;

      if (userId == null) {
        throw Exception('Utilisateur non authentifié');
      }

      // Si c'est un admin, utiliser son propre ID
      if (!isCollaborateur) {
        final adminDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('authentification')
            .doc(userId)
            .get();

        if (!adminDoc.exists) {
          throw Exception('Administrateur non trouvé');
        }

        final Map<String, dynamic>? adminData = adminDoc.data();
        if (mounted) {
          setState(() {
            _prenom = adminData?['prenom'] ?? '';
            _nomEntreprise = adminData?['nomEntreprise'] ?? '';
            _isUserDataLoaded = true;
          });
        }
      } else {
        // Si c'est un collaborateur, charger les données de l'admin et son propre prénom
        // 1. Essayer d'abord le document principal de l'admin
        final adminDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(adminId)
            .get();

        // 2. Si le document principal n'existe pas, essayer la sous-collection authentification
        if (!adminDoc.exists) {
          print('\ud83d\udc41 Document principal de l\'admin non trouvé, vérification dans authentification');
          
          final adminAuthDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(adminId)
              .collection('authentification')
              .doc(adminId)
              .get();
          
          if (!adminAuthDoc.exists) {
            print('\u274c Admin non trouvé ni dans le document principal ni dans authentification');
            throw Exception('Administrateur non trouvé');
          }
          
          // Utiliser les données de la sous-collection authentification
          print('\u2705 Document authentification de l\'admin trouvé');
          final Map<String, dynamic>? adminData = adminAuthDoc.data();
          String? nomEntreprise = adminData?['nomEntreprise'] as String?;

          // Charger le prénom du collaborateur
          final collaborateurDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get();
          
          // Si le document principal du collaborateur n'existe pas, vérifier dans authentification
          String? prenom;
          if (collaborateurDoc.exists) {
            prenom = (collaborateurDoc.data() ?? {})['prenom'] as String?;
          } else {
            print('\ud83d\udc41 Document collaborateur non trouvé, vérification dans authentification');
            
            final collabAuthDoc = await FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .collection('authentification')
                .doc(userId)
                .get();
                
            prenom = collabAuthDoc.exists ? (collabAuthDoc.data() ?? {})['prenom'] as String? : null;
          }

          if (mounted) {
            setState(() {
              _prenom = prenom ?? '';
              _nomEntreprise = nomEntreprise ?? '';
              _isUserDataLoaded = true;
            });
          }
          return;
        }

        // Si le document principal de l'admin existe, l'utiliser
        print('\u2705 Document principal de l\'admin trouvé');
        final Map<String, dynamic>? adminData = adminDoc.data();
        String? nomEntreprise = adminData?['nomEntreprise'] as String?;

        // Charger le prénom du collaborateur
        final collaborateurDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();

        String? prenom = collaborateurDoc.exists 
            ? (collaborateurDoc.data() ?? {})['prenom'] as String? 
            : null;

        if (mounted) {
          setState(() {
            _prenom = prenom ?? '';
            _nomEntreprise = nomEntreprise ?? '';
            _isUserDataLoaded = true;
          });
        }
      }
    } catch (e) {
      print(' Erreur lors du chargement des données utilisateur: $e');
      if (mounted) {
        setState(() {
          _prenom = '';
          _nomEntreprise = '';
          _isUserDataLoaded = true; 
        });
      }
    }
  }
  
  // Méthode pour initialiser toutes les données nécessaires
  Future<void> _initializeData() async {
    try {
      // Vérifier si l'utilisateur est authentifié
      if (FirebaseAuth.instance.currentUser == null) {
        print(' Attente de l\'authentification...');
        return; // Attendre que l'utilisateur soit authentifié
      }

      // Charger les données utilisateur
      await _loadUserData();
      
      // Ne continuer que si les données utilisateur ont été chargées avec succès
      if (!_isUserDataLoaded) {
        print('\u274c Données utilisateur non chargées, annulation de l\'initialisation');
        return;
      }
      
      // Initialiser le gestionnaire d'accès aux véhicules
      await _initializeVehicleAccess();
      
      // Mettre à jour l'état
      if (mounted) {
        setState(() {
          _isVehicleManagerInitialized = true;
        });
      }
    } catch (e) {
      print(' Erreur lors de l\'initialisation des données: $e');
      if (mounted) {
        setState(() {
          _isUserDataLoaded = true; 
          _isVehicleManagerInitialized = true;
        });
      }
    }
  }
  
  // Méthode pour initialiser le gestionnaire d'accès aux véhicules
  Future<void> _initializeVehicleAccess() async {
    try {
      print(' Réinitialisation du gestionnaire d\'accès aux véhicules si nécessaire');
      // Réinitialiser le gestionnaire s'il a été fermé précédemment
      // Cela permet de réutiliser le gestionnaire après une déconnexion/reconnexion
      await _vehicleAccessManager.reset();
      
      print(' Gestionnaire d\'accès aux véhicules réinitialisé avec succès');
      
      // Forcer une mise à jour de l'interface après l'initialisation
      if (mounted) {
        setState(() {
          _isVehicleManagerInitialized = true;
        });
      }
    } catch (e) {
      print(' Erreur lors de la réinitialisation du gestionnaire d\'accès aux véhicules: $e');
      // Même en cas d'erreur, on marque comme initialisé pour éviter un écran de chargement infini
      if (mounted) {
        setState(() {
          _isVehicleManagerInitialized = true;
        });
      }
    }
  }

  // Variable pour suivre si la vérification des abonnements a déjà été configurée
  static bool _subscriptionCheckSetup = false;

  void _setupSubscriptionCheck() {
    // Ne configurer la vérification qu'une seule fois
    if (!_subscriptionCheckSetup) {
      // Vérification toutes les 24 heures
      Timer.periodic(const Duration(hours: 24), (_) {
        // Ici, vous pouvez ajouter le code pour vérifier l'abonnement
        // Par exemple: _checkSubscriptionStatus();
      });
      _subscriptionCheckSetup = true;
    }
  }

  // Variable pour suivre si le traitement de la file d'attente est configuré
  static bool _syncQueueSetup = false;
  
  // Méthode pour initialiser le traitement de la file d'attente
  void _setupSyncQueue() {
    // Ne configurer le traitement qu'une seule fois
    if (!_syncQueueSetup) {
      // Traiter la file au démarrage
      SyncQueueService().processQueue();
      
      // Traiter la file périodiquement toutes les 15 minutes
      Timer.periodic(const Duration(minutes: 15), (_) {
        SyncQueueService().processQueue();
      });
      
      // Vérifier la connectivité périodiquement toutes les 30 secondes
      // et traiter la file si la connexion est disponible
      Timer.periodic(const Duration(seconds: 30), (_) async {
        bool isConnected = await _connectivityService.checkConnectivity();
        if (isConnected) {
          SyncQueueService().processQueue();
        }
      });
      
      _syncQueueSetup = true;
      print('u2705 Traitement de la file d\'attente configuré');
    }
  }

  @override
  void dispose() {
    _searchController.dispose(); 
    _connectivityService.dispose(); 
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, 
      appBar: AppBar(
        automaticallyImplyLeading: false, 
        title: _showSearchBar
            ? TextField(
                controller: _searchController,
                autofocus: true,
                cursorColor: Colors.white, 
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  hintText: 'Rechercher un véhicule...',
                  hintStyle: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.normal),
                  border: InputBorder.none,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () {
                      setState(() {
                        _showSearchBar = false;
                        _searchQuery = '';
                        _isSearching = false;
                        _searchController.clear();
                      });
                    },
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                    _isSearching = value.isNotEmpty;
                  });
                },
              )
            : Text(
                "Bonjour $_prenom",
                style: const TextStyle(
                    color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
              ),
        backgroundColor: const Color(0xFF08004D),
        centerTitle: false,
        elevation: 0,
        actions: [
          if (!_showSearchBar)
            IconButton(
              icon: const Icon(Icons.search, color: Colors.white),
              onPressed: () {
                setState(() {
                  _showSearchBar = true;
                  _searchController.text = _searchQuery;
                });
              },
            ),
        ],
      ),
      body: !_isUserDataLoaded || !_isVehicleManagerInitialized 
          ? const Center(child: CircularProgressIndicator()) 
          : Stack(
              children: [
                StreamBuilder<QuerySnapshot>(
                  stream: _vehicleAccessManager.getVehiclesStream(), 
                  builder: (context, snapshot) {
                    // Gérer les différents états de connexion
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text("Chargement de vos véhicules...", 
                                style: TextStyle(color: Color(0xFF1A237E)))
                          ],
                        )
                      );
                    }
                    
                    // Vérifier les conditions pour afficher le widget VehicleListView
                    if (snapshot.hasError || 
                        (snapshot.data?.docs.isEmpty ?? true) && 
                        snapshot.connectionState == ConnectionState.active) {
                      // Retourner le widget VehicleListView pour gérer les états d'erreur et vide
                      return VehicleListView(
                        snapshot: snapshot,
                        nomEntreprise: _nomEntreprise,
                        prenom: _prenom,
                      );
                    }
                    
                    final vehicles = snapshot.data?.docs ?? [];

                    List<QueryDocumentSnapshot> filteredVehicles = vehicles;
                    if (_isSearching && _searchQuery.isNotEmpty) {
                      filteredVehicles = vehicles.where((vehicle) {
                        final data = vehicle.data() as Map<String, dynamic>;
                        final marque = (data['marque'] ?? '').toString().toLowerCase();
                        final modele = (data['modele'] ?? '').toString().toLowerCase();
                        final immatriculation = (data['immatriculation'] ?? '').toString().toLowerCase();
                        
                        return marque.contains(_searchQuery) || 
                               modele.contains(_searchQuery) || 
                               immatriculation.contains(_searchQuery);
                      }).toList();
                    }

                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          child: Column(
                            children: [
                              const SizedBox(height: 5),
                              const Text(
                                "(Appuie long pour modifier)",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: GridView.builder(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                              childAspectRatio: 3 / 4,
                            ),
                            padding: const EdgeInsets.all(12.0),
                            itemCount: filteredVehicles.length,
                            itemBuilder: (context, index) {
                              final vehicle = filteredVehicles[index];
                              final data = vehicle.data() as Map<String, dynamic>;

                              return GestureDetector(
                                onTap: () async {
                                  final doc = await _vehicleAccessManager.getVehicleDocument(vehicle.id);

                                  if (!mounted) return;

                                  if (doc.exists) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ClientPage(
                                          marque: data['marque'] ?? '',
                                          modele: data['modele'] ?? '',
                                          immatriculation:
                                              data['immatriculation'] ?? '',
                                        ),
                                      ),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text("Ce véhicule n'existe plus."),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                },
                                onLongPress: () =>
                                    _deleteVehicule.showActionDialog(vehicle.id),
                                child: Card(
                                  elevation: 5,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  color: Colors.white, 
                                  child: Column(
                                    children: [
                                      Expanded(
                                        child: ClipRRect(
                                          borderRadius: const BorderRadius.only(
                                            topLeft: Radius.circular(16),
                                            topRight: Radius.circular(16),
                                          ),
                                          child: data['photoVehiculeUrl'] != null &&
                                                  data['photoVehiculeUrl'].isNotEmpty
                                              ? Image.network(
                                                  data['photoVehiculeUrl'],
                                                  width: double.infinity,
                                                  height: double.infinity,
                                                  fit: BoxFit.cover,
                                                  loadingBuilder:
                                                      (context, child, loadingProgress) {
                                                    if (loadingProgress == null)
                                                      return child;
                                                    return const Center(
                                                      child: CircularProgressIndicator(),
                                                    );
                                                  },
                                                  errorBuilder:
                                                      (context, error, stackTrace) {
                                                    return const Center(
                                                      child: Icon(
                                                        Icons.error,
                                                        color: Colors.red,
                                                        size: 50,
                                                      ),
                                                    );
                                                  },
                                                )
                                              : const Center(
                                                  child: Icon(
                                                    Icons.directions_car_filled_rounded,
                                                    size: 90,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                        ),
                                      ),
                                      const Divider(
                                        color: Colors.black12,
                                        height: 1,
                                        thickness: 1,
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Column(
                                          children: [
                                            Text(
                                              "${data['marque']} ${data['modele']}",
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                color: Color(0xFF1A237E),
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              "${data['immatriculation']}",
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
                // Pilule bleue "Ajouter" centrée en bas
                const PositionedAddButton(),
              ],
            ),
    );
  }
}
