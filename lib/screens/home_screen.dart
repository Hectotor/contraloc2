import 'package:ContraLoc/USERS/abonnement_screen.dart';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'dart:async'; // Import Timer
import '../widget/delete_vehicule.dart';
import '../widget/CREATION DE CONTRAT/client.dart'; // Assurez-vous que ce fichier est correctement importé
import '../utils/animation.dart';
import '../services/heritage_collab.dart'; // Import du nouveau service


class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late DeleteVehicule _deleteVehicule;
  String _prenom = '';
  bool _isUserDataLoaded = false; // Add a flag to check if user data is loaded

  @override
  void initState() {
    super.initState();
    _deleteVehicule = DeleteVehicule(context);
    _loadUserData();
    _setupSubscriptionCheck();
    _checkWritePermission();
  }

  void _setupSubscriptionCheck() {
    print('🔄 Initialisation de la vérification des abonnements');
    // Vérification initiale au démarrage

    // Vérification toutes les 24 heures
    Timer.periodic(const Duration(hours: 24), (_) {});
  }

  Future<void> _loadUserData() async {
    if (_isUserDataLoaded) return;

    final user = _auth.currentUser;
    if (user != null) {
      try {
        print('👤 Chargement des données utilisateur...');
        // Vérifier l'état de l'abonnement via RevenueCat
        final customerInfo = await Purchases.getCustomerInfo();
        print('📱 État RevenueCat: ${customerInfo.entitlements.active.length} abonnement(s) actif(s)');

        // Vérifier si l'utilisateur est un collaborateur
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        final userData = userDoc.data();

        if (userData != null && userData['role'] == 'collaborateur') {
          print('👥 Utilisateur identifié comme collaborateur');
          final adminId = userData['adminId'];

          // Charger les données du collaborateur depuis le document de l'admin
          final collaboratorData = await _firestore
              .collection('users')
              .doc(adminId)
              .collection('authentification')
              .where('uid', isEqualTo: user.uid)
              .limit(1)
              .get();

          if (collaboratorData.docs.isNotEmpty) {
            final collabDoc = collaboratorData.docs.first;
            final collabId = collabDoc.id;  // C'est l'ID unique (lettre + 5 chiffres)

            // Synchroniser les données avec l'admin en passant le uid
            await HeritageCollabService.synchroniserDonneesAdmin(
              collabId,
              adminId,
              user.uid  // uid du collaborateur
            );

            if (mounted) {
              setState(() {
                _prenom = collabDoc.data()['prenom'] ?? '';
                _isUserDataLoaded = true;
              });
            }
          }
        } else {
          print('👤 Utilisateur identifié comme admin');
          // Pour les admins, charger depuis leur propre collection
          final adminData = await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('authentification')
              .doc(user.uid)
              .get();

          if (adminData.exists && mounted) {
            setState(() {
              _prenom = adminData.data()?['prenom'] ?? '';
              _isUserDataLoaded = true;
            });
          }
        }
      } catch (e) {
        print('❌ Erreur chargement données: $e');
      }
    }
  }

  Future<void> _checkWritePermission() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data();

      if (userData != null && userData['role'] == 'collaborateur') {
        print('👥 Vérification des permissions du collaborateur');

        if (mounted) {
          setState(() {
            // _canAddVehicle = canWrite;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            // _canAddVehicle = true; // Les admins peuvent toujours ajouter des véhicules
          });
        }
      }
    } catch (e) {
      print('❌ Erreur vérification permissions: $e');
    }
  }

  Future<bool> _checkMonthlyContractLimit() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        // Vérifier si l'utilisateur est un collaborateur
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        final userData = userDoc.data();

        String targetUserId = user.uid;

        if (userData != null && userData['role'] == 'collaborateur') {
          targetUserId = userData['adminId'];
        }

        // Récupérer la limite de contrats de l'utilisateur (admin ou collaborateur)
        final limitDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(targetUserId)
            .collection('authentification')
            .doc(userData?['id'] ?? targetUserId)
            .get();

        final cb_limite_contrat = limitDoc.data()?['cb_limite_contrat'] ?? 10;
        
        int limiteContrat = 10; // Limite par défaut
        
        if (cb_limite_contrat == 999) {
          limiteContrat = 999;
        } else {
          final limiteContratTemp = limitDoc.data()?['limiteContrat'] ?? 10;
          if (limiteContratTemp == 999) {
            limiteContrat = 999;
          }
        }

        // Calculer le début et la fin du mois en cours
        final now = DateTime.now();
        final startOfMonth = DateTime(now.year, now.month, 1);
        final endOfMonth = DateTime(now.year, now.month + 1, 0);

        // Compter les contrats créés ce mois-ci
        final querySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(targetUserId)
            .collection('locations')
            .where('dateCreation', isGreaterThanOrEqualTo: startOfMonth)
            .where('dateCreation', isLessThanOrEqualTo: endOfMonth)
            .get();

        final nombreContratsMois = querySnapshot.docs.length;
        print('📊 Nombre de contrats ce mois: $nombreContratsMois sur $limiteContrat autorisés');

        return nombreContratsMois < limiteContrat;
      } catch (e) {
        print('❌ Erreur vérification limite contrats: $e');
        return false;
      }
    }
    return false;
  }

  void _showLimitReachedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text(
            "Limite mensuelle atteinte",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF08004D),
            ),
          ),
          content: const Text(
            "Vous avez atteint votre limite de contrats pour ce mois. Passez à un abonnement supérieur pour créer plus de contrats.",
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Plus tard",
                style: TextStyle(color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AbonnementScreen(),
                  ),
                );
              },
              child: const Text(
                "Voir les abonnements",
                style: TextStyle(
                  color: Color(0xFF08004D),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Stream<QuerySnapshot> _getVehiclesStream() async* {
    final user = _auth.currentUser;
    if (user == null) {
      yield* Stream.empty();
      return;
    }

    // Récupérer les données de l'utilisateur
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final userData = userDoc.data();

    if (userData != null && userData['role'] == 'collaborateur') {
      print('👥 Chargement des véhicules depuis le compte admin');
      yield* _firestore
          .collection('users')
          .doc(userData['adminId'])
          .collection('vehicules')
          .snapshots();
    } else {
      print('👤 Chargement des véhicules depuis le compte utilisateur');
      yield* _firestore
          .collection('users')
          .doc(user.uid)
          .collection('vehicules')
          .snapshots();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Modification ici
      appBar: AppBar(
        title: const Text(
          "Mes véhicules",
          style: TextStyle(
              color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF08004D), // Bleu nuit plus foncé
        centerTitle: true,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _getVehiclesStream(),
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

          return Column(
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: Column(
                  children: [
                    SizedBox(height: 5),
                    Text(
                      "(Appuie long pour modifier)",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
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
                  itemCount: vehicles.length,
                  itemBuilder: (context, index) {
                    final vehicle = vehicles[index];
                    final data = vehicle.data() as Map<String, dynamic>;

                    return GestureDetector(
                      onTap: () async {
                        final canCreateContract =
                            await _checkMonthlyContractLimit();

                        if (!canCreateContract) {
                          _showLimitReachedDialog();
                          return;
                        }

                        // Modification ici : vérifier dans la bonne collection selon le rôle
                        final user = FirebaseAuth.instance.currentUser;
                        if (user != null) {
                          final userDoc = await _firestore.collection('users').doc(user.uid).get();
                          final userData = userDoc.data();
                          
                          String targetUserId = user.uid;
                          if (userData != null && userData['role'] == 'collaborateur') {
                            targetUserId = userData['adminId'];
                          }

                          final doc = await FirebaseFirestore.instance
                              .collection('users')
                              .doc(targetUserId)
                              .collection('vehicules')
                              .doc(vehicle.id)
                              .get();

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
      floatingActionButton: null,
    );
  }
}
