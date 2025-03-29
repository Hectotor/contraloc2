import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async'; // Import Timer
import '../HOME/delete_vehicule.dart';
import '../widget/CREATION DE CONTRAT/client.dart'; // Assurez-vous que ce fichier est correctement importé
import '../services/collaborateur_util.dart'; // Import du nouveau fichier
import '../widget/MES CONTRATS/vehicle_access_manager.dart'; // Import du gestionnaire d'accès aux véhicules
import '../services/connectivity_service.dart'; // Import du service de connectivité
import '../screens/add_vehicule.dart'; // Import pour la redirection vers AddVehiculeScreen
import '../HOME/button_add_vehicle.dart'; // Import pour le bouton personnalisé
import 'package:firebase_auth/firebase_auth.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late DeleteVehicule _deleteVehicule;
  String _prenom = '';
  String _nomEntreprise = ''; // Ajout du nom de l'entreprise
  String _searchQuery = ''; // Variable pour stocker le texte de recherche
  bool _isSearching = false; // Variable pour indiquer si la recherche est active
  bool _showSearchBar = false; // Variable pour afficher/masquer la barre de recherche
  final TextEditingController _searchController = TextEditingController(); // Contrôleur pour le TextField
  bool _isUserDataLoaded = false; // Variable pour suivre si les données utilisateur sont chargées
  late VehicleAccessManager _vehicleAccessManager; // Instance de notre gestionnaire d'accès aux véhicules
  bool _isVehicleManagerInitialized = false; // Variable pour suivre si le gestionnaire est initialisé
  
  // Service de connectivité
  final ConnectivityService _connectivityService = ConnectivityService();

  @override
  void initState() {
    super.initState();
    _deleteVehicule = DeleteVehicule(context);
    
    // Initialiser le gestionnaire d'accès aux véhicules
    _vehicleAccessManager = VehicleAccessManager();
    
    // Charger les données utilisateur et initialiser le gestionnaire de véhicules
    _initializeData();
    _setupSubscriptionCheck();
    
    // Initialiser le service de connectivité
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _connectivityService.initialize(context);
    });
  }
  
  // Méthode pour charger les données utilisateur avec CollaborateurUtil
  Future<void> _loadUserData() async {
    try {
      // Vérifier si l'utilisateur est un collaborateur
      final status = await CollaborateurUtil.checkCollaborateurStatus();
      final isCollaborateur = status['isCollaborateur'] == true;
      
      // Récupérer les données d'authentification (contient le nom de l'entreprise)
      final authData = await CollaborateurUtil.getAuthData();
      String prenom = authData['prenom'] ?? '';
      
      if (isCollaborateur) {
        // Pour un collaborateur, utiliser son prénom depuis son document utilisateur
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          try {
            // Essayer d'abord depuis le cache
            try {
              final userDoc = await FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .get(const GetOptions(source: Source.cache));
              
              if (userDoc.exists && userDoc.data() != null) {
                final userData = userDoc.data()!;
                if (userData.containsKey('prenom') && userData['prenom'] != null) {
                  prenom = userData['prenom'];
                  print('✅ Prénom du collaborateur récupéré depuis le cache: $prenom');
                }
              }
            } catch (cacheError) {
              print('⚠️ Tentative de cache échouée, nouvelle tentative avec le serveur: $cacheError');
              // Si la cache échoue, essayer le serveur
              final userDoc = await FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .get(const GetOptions(source: Source.server));
              
              if (userDoc.exists && userDoc.data() != null) {
                final userData = userDoc.data()!;
                if (userData.containsKey('prenom') && userData['prenom'] != null) {
                  prenom = userData['prenom'];
                  print('✅ Prénom du collaborateur récupéré depuis le serveur: $prenom');
                }
              }
            }
          } catch (e) {
            print('⚠️ Erreur lors de la récupération du prénom du collaborateur: $e');
          }
        }
      }
      
      if (mounted) {
        setState(() {
          _prenom = prenom;
          _nomEntreprise = authData['nomEntreprise'] ?? '';
          _isUserDataLoaded = true;
        });
      }
    } catch (e) {
      print('❌ Erreur lors du chargement des données utilisateur: $e');
      if (mounted) {
        setState(() {
          _prenom = '';
          _nomEntreprise = '';
          _isUserDataLoaded = true; // Marquer comme chargé même en cas d'erreur pour éviter un écran de chargement infini
        });
      }
    }
  }
  
  // Méthode pour initialiser toutes les données nécessaires
  Future<void> _initializeData() async {
    try {
      // Charger les données utilisateur
      await _loadUserData();
      
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
          _isUserDataLoaded = true; // Marquer comme chargé même en cas d'erreur
          _isVehicleManagerInitialized = true;
        });
      }
    }
  }
  
  // Méthode pour initialiser le gestionnaire d'accès aux véhicules
  Future<void> _initializeVehicleAccess() async {
    try {
      print('🔄 Initialisation du gestionnaire d\'accès aux véhicules...');
      await _vehicleAccessManager.initialize();
      print('✅ Gestionnaire d\'accès aux véhicules initialisé avec succès');
      
      // Forcer une mise à jour de l'interface après l'initialisation
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('❌ Erreur lors de l\'initialisation du gestionnaire d\'accès aux véhicules: $e');
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

  @override
  void dispose() {
    _searchController.dispose(); // Libérer les ressources du contrôleur
    _connectivityService.dispose(); // Arrêter le service de connectivité
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, 
      appBar: AppBar(
        automaticallyImplyLeading: false, // Désactive le bouton de retour automatique
        title: _showSearchBar
            ? TextField(
                controller: _searchController,
                autofocus: true,
                cursorColor: Colors.white, 
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Rechercher un véhicule...',
                  hintStyle: const TextStyle(color: Colors.white),
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
                    
                    if (snapshot.hasError) {
                      print(' Erreur dans le stream des véhicules: ${snapshot.error}');
                      return Center(
                        child: Text(
                          'Erreur lors du chargement des véhicules',
                          style: TextStyle(color: Colors.red),
                        ),
                      );
                    }

                    final vehicles = snapshot.data?.docs ?? [];

                    if (vehicles.isEmpty && snapshot.connectionState == ConnectionState.active) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            RichText(
                              textAlign: TextAlign.center,
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: _nomEntreprise.isNotEmpty 
                                        ? "$_nomEntreprise\n \n" 
                                        : "Bonjour $_prenom,\n \n",
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1A237E),
                                    ),
                                  ),
                                  const TextSpan(
                                    text: "Bienvenue sur Contraloc",
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.normal,
                                      color: Color(0xFF1A237E),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              "Commencez par ajouter un véhicule",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFF757575),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

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
                Positioned(
                  bottom: 20,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: CustomActionButton(
                      text: "Ajouter",
                      icon: Icons.add_circle_outline,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AddVehiculeScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
