import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async'; // Import Timer
import '../widget/delete_vehicule.dart';
import '../widget/CREATION DE CONTRAT/client.dart'; // Assurez-vous que ce fichier est correctement importé
import '../utils/animation.dart';
import '../HOME/info_user.dart'; // Import du nouveau fichier
import '../HOME/contract_limit_manager.dart'; // Import du gestionnaire de limite de contrats
import '../HOME/popup_limite_contrat.dart'; // Import du popup de limite de contrats
import '../widget/MES CONTRATS/vehicle_access_manager.dart'; // Import du gestionnaire d'accès aux véhicules

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late DeleteVehicule _deleteVehicule;
  String _prenom = '';
  String _searchQuery = ''; // Variable pour stocker le texte de recherche
  bool _isSearching = false; // Variable pour indiquer si la recherche est active
  bool _showSearchBar = false; // Variable pour afficher/masquer la barre de recherche
  final TextEditingController _searchController = TextEditingController(); // Contrôleur pour le TextField
  late UserInfoManager _userInfoManager; // Instance de notre gestionnaire d'informations utilisateur
  bool _isUserDataLoaded = false; // Variable pour suivre si les données utilisateur sont chargées
  late ContractLimitManager _contractLimitManager; // Instance de notre gestionnaire de limite de contrats
  late VehicleAccessManager _vehicleAccessManager; // Instance de notre gestionnaire d'accès aux véhicules

  @override
  void initState() {
    super.initState();
    _deleteVehicule = DeleteVehicule(context);
    // Initialiser le gestionnaire d'informations utilisateur
    _userInfoManager = UserInfoManager(
      onPrenomLoaded: (prenom) {
        setState(() {
          _prenom = prenom;
          _isUserDataLoaded = true;
        });
      }
    );
    
    // Charger les données utilisateur
    _userInfoManager.loadUserData();
    _setupSubscriptionCheck();
    _contractLimitManager = ContractLimitManager(); // Initialiser le gestionnaire de limite de contrats
    _vehicleAccessManager = VehicleAccessManager(); // Initialiser le gestionnaire d'accès aux véhicules
    
    // Initialiser le gestionnaire d'accès aux véhicules (asynchrone)
    _initializeVehicleAccess();
  }
  
  // Méthode pour initialiser le gestionnaire d'accès aux véhicules
  Future<void> _initializeVehicleAccess() async {
    await _vehicleAccessManager.initialize();
    // Forcer une mise à jour de l'interface après l'initialisation
    if (mounted) {
      setState(() {});
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Modification ici
      appBar: AppBar(
        title: _showSearchBar
            ? TextField(
                controller: _searchController,
                autofocus: true,
                cursorColor: Colors.white, // Définir la couleur du curseur en blanc
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
            : const Text(
                "Mes véhicules",
                style: TextStyle(
                    color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
              ),
        backgroundColor: const Color(0xFF08004D), // Bleu nuit plus foncé
        centerTitle: true,
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
      body: !_isUserDataLoaded 
          ? const Center(child: CircularProgressIndicator()) 
          : StreamBuilder<QuerySnapshot>(
        stream: _vehicleAccessManager.getVehiclesStream(), // Utiliser le stream fourni par VehicleAccessManager
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final vehicles = snapshot.data?.docs ?? [];

          if (vehicles.isEmpty) {
            return Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: "Bonjour $_prenom,\n \n",
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
                    ],
                  ),
                ),
                const Positioned(
                  bottom: 120,
                  left: 0,
                  right: 0,
                  child: Text(
                    "Commencez par ajouter un véhicule",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF757575),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 35,
                  right: MediaQuery.of(context).size.width / 3.1,
                  child: const ArrowAnimation(),
                ),
              ],
            );
          }

          // Filtrer les véhicules si une recherche est active
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
                        final canCreateContract = await _contractLimitManager.checkMonthlyContractLimit();

                        if (!canCreateContract) {
                          PopupLimiteContrat.showLimitReachedDialog(context);
                          return;
                        }

                        // Utiliser le gestionnaire d'accès aux véhicules pour récupérer le document
                        final doc = await _vehicleAccessManager.getVehicleDocument(vehicle.id);

                        // Vérifier si le widget est toujours monté avant de naviguer
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
                        color: Colors.white, // Set background color to white
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
      // Suppression du floatingActionButton
    );
  }
}
