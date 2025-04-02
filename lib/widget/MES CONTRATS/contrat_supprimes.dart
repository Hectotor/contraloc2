import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import '../modifier.dart'; // Suppression de l'import pour la modification
import 'package:ContraLoc/widget/MES%20CONTRATS/vehicle_access_manager.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'search_filtre.dart';

class ContratSupprimes extends StatefulWidget {
  final String searchText;
  final Function(int)? onContractsCountChanged;

  ContratSupprimes({Key? key, required this.searchText, this.onContractsCountChanged}) : super(key: key);

  @override
  _ContratSupprimesState createState() => _ContratSupprimesState();
}

class _ContratSupprimesState extends State<ContratSupprimes> {
  final Map<String, String?> _photoUrlCache = {};
  final _searchController = TextEditingController();
  late VehicleAccessManager _vehicleAccessManager;
  String? _targetUserId;
  bool _isInitialized = false;
  
  @override
  void initState() {
    super.initState();
    _vehicleAccessManager = VehicleAccessManager();
    _initializeAccess();
    _searchController.text = widget.searchText;
  }
  
  // Méthode pour initialiser les gestionnaires d'accès
  Future<void> _initializeAccess() async {
    await _vehicleAccessManager.initialize();
    _targetUserId = _vehicleAccessManager.getTargetUserId();
    _isInitialized = true;
    if (mounted) {
      setState(() {});
    }
  }

  // Méthode pour obtenir le stream des contrats supprimés
  Stream<QuerySnapshot> _getDeletedContractsStream() {
    if (!_isInitialized) {
      return Stream.fromFuture(
        Future(() async {
          await _initializeAccess();
          
          final effectiveUserId = _targetUserId ?? FirebaseAuth.instance.currentUser?.uid;
          if (effectiveUserId == null) {
            return FirebaseFirestore.instance.collection('empty').limit(0).get();
          }
          
          final snapshot = await FirebaseFirestore.instance
              .collection('users')
              .doc(effectiveUserId)
              .collection('locations')
              .where('statussupprime', isEqualTo: 'supprimé')
              .orderBy('dateCreation', descending: true)
              .get();
              
          return snapshot;
        })
      ).asyncExpand((snapshot) {
        final effectiveUserId = _targetUserId ?? FirebaseAuth.instance.currentUser?.uid;
        if (effectiveUserId == null) {
          return Stream.empty();
        }
        
        return FirebaseFirestore.instance
            .collection('users')
            .doc(effectiveUserId)
            .collection('locations')
            .where('statussupprime', isEqualTo: 'supprimé')
            .snapshots();
      });
    }
    
    final effectiveUserId = _targetUserId ?? FirebaseAuth.instance.currentUser?.uid;
    if (effectiveUserId == null) {
      return Stream.empty();
    }
    
    return FirebaseFirestore.instance
        .collection('users')
        .doc(effectiveUserId)
        .collection('locations')
        .where('statussupprime', isEqualTo: 'supprimé')
        .snapshots();
  }

  // Méthode pour filtrer les contrats en fonction du texte de recherche
  bool _filterContract(DocumentSnapshot doc, String searchText) {
    return SearchFiltre.filterContract(doc, searchText);
  }

  Future<String?> _getVehiclePhotoUrl(String immatriculation) async {
    final cacheKey = immatriculation;
    if (_photoUrlCache.containsKey(cacheKey)) {
      return _photoUrlCache[cacheKey];
    }

    // Utiliser le gestionnaire d'accès aux véhicules pour récupérer le véhicule par immatriculation
    final vehiculeDoc = await _vehicleAccessManager.getVehicleByImmatriculation(immatriculation);

    if (vehiculeDoc.docs.isNotEmpty) {
      // Accéder aux données de manière sûre
      final data = vehiculeDoc.docs.first.data();
      String? photoUrl;
      
      if (data != null && data is Map<String, dynamic>) {
        photoUrl = data['photoVehiculeUrl'] as String?;
      }
      
      _photoUrlCache[cacheKey] = photoUrl;
      return photoUrl;
    }
    return null;
  }

  // Méthode pour restaurer un contrat supprimé
  Future<void> _restoreContract(String contractId) async {
    try {
      // Récupérer l'ID utilisateur effectif
      final effectiveUserId = _targetUserId ?? FirebaseAuth.instance.currentUser?.uid;
      if (effectiveUserId == null) return;

      // Mettre à jour le document dans Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(effectiveUserId)
          .collection('locations')
          .doc(contractId)
          .update({
        'statussupprime': null,
        'dateSuppression': null,
        'dateSuppressionDefinitive': null
      });

      // Afficher un message de succès
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Le contrat a été restauré avec succès'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('Erreur lors de la restauration du contrat: $e');
      // Afficher un message d'erreur
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la restauration du contrat'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF08004D).withOpacity(0.05), Colors.white],
          ),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.all(16),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Rechercher un contrat...',
                    prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  onChanged: (value) {
                    setState(() {});
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                '(Appui long pour restaurer)',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _getDeletedContractsStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF08004D)),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                          const SizedBox(height: 16),
                          const Text(
                            "Erreur de chargement des contrats",
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.delete_outline, size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          const Text(
                            "Aucun contrat supprimé trouvé",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final contrats = snapshot.data!.docs;

                  final filteredContrats = contrats.where((contrat) {
                    return _filterContract(contrat, _searchController.text);
                  }).toList();

                  if (widget.onContractsCountChanged != null) {
                    widget.onContractsCountChanged!(filteredContrats.length);
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: filteredContrats.length,
                    itemBuilder: (context, index) {
                      final contrat = filteredContrats[index];
                      final data = contrat.data() as Map<String, dynamic>;

                      return FutureBuilder<String?>(
                        future: _getVehiclePhotoUrl(data['immatriculation']),
                        builder: (context, snapshot) {
                          final photoUrl = snapshot.data;

                          return Container(
                            margin: EdgeInsets.symmetric(
                              horizontal: MediaQuery.of(context).size.width * 0.05,
                              vertical: 8,
                            ),
                            child: Material(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15),
                              elevation: 2,
                              shadowColor: Colors.black.withOpacity(0.1),
                              child: GestureDetector(
                                onLongPress: () {
                                  // Afficher le popup de confirmation
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return Dialog(
                                        backgroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(24),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(16),
                                                decoration: BoxDecoration(
                                                  color: Colors.blue[50],
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(
                                                  Icons.restore_rounded,
                                                  color: Colors.blue[400],
                                                  size: 48,
                                                ),
                                              ),
                                              const SizedBox(height: 24),
                                              const Text(
                                                'Restaurer le contrat ?',
                                                style: TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF08004D),
                                                ),
                                              ),
                                              const SizedBox(height: 16),
                                              const Text(
                                                'Le contrat sera à nouveau disponible dans vos contrats actifs.',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                              const SizedBox(height: 24),
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: TextButton(
                                                      onPressed: () => Navigator.pop(context),
                                                      style: TextButton.styleFrom(
                                                        backgroundColor: Colors.grey[100],
                                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius: BorderRadius.circular(12),
                                                        ),
                                                      ),
                                                      child: const Text(
                                                        'Annuler',
                                                        style: TextStyle(
                                                          fontSize: 16,
                                                          color: Color(0xFF08004D),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 16),
                                                  Expanded(
                                                    child: ElevatedButton(
                                                      onPressed: () {
                                                        // Restaurer le contrat
                                                        _restoreContract(contrat.id);
                                                        Navigator.pop(context);
                                                      },
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor: Color(0xFF08004D),
                                                        foregroundColor: Colors.white,
                                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                                        elevation: 0,
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius: BorderRadius.circular(12),
                                                        ),
                                                      ),
                                                      child: const Text(
                                                        'Restaurer',
                                                        style: TextStyle(
                                                          fontSize: 16,
                                                          fontWeight: FontWeight.w600,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Row(
                                    children: [
                                      Column(
                                        children: [
                                          Builder(builder: (context) {
                                            // Calcul du nombre de jours restants
                                            final now = DateTime.now();
                                            DateTime dateSuppressionDefinitive;
                                            
                                            try {
                                              if (data['dateSuppressionDefinitive'] is Timestamp) {
                                                // Si c'est un Timestamp
                                                dateSuppressionDefinitive = (data['dateSuppressionDefinitive'] as Timestamp).toDate();
                                              } else if (data['dateSuppressionDefinitive'] is String) {
                                                // Si c'est une chaine de caractères
                                                dateSuppressionDefinitive = DateTime.parse(data['dateSuppressionDefinitive'] as String);
                                              } else {
                                                // Valeur par défaut si le champ est null ou d'un autre type
                                                dateSuppressionDefinitive = now.add(Duration(days: 90));
                                              }
                                            } catch (e) {
                                              // En cas d'erreur de parsing, utiliser une valeur par défaut
                                              print('Erreur de parsing de la date: $e');
                                              dateSuppressionDefinitive = now.add(Duration(days: 90));
                                            }
                                            
                                            final difference = dateSuppressionDefinitive.difference(now);
                                            final daysRemaining = difference.inDays;
                                            
                                            return Container(
                                              margin: EdgeInsets.only(bottom: 8),
                                              child: Text(
                                                "J-$daysRemaining",
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.red,
                                                ),
                                              ),
                                            );
                                          }),
                                          Container(
                                            width: MediaQuery.of(context).size.width * 0.2,
                                            height: MediaQuery.of(context).size.width * 0.2,
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(12),
                                              color: Colors.grey[100],
                                            ),
                                            child: (photoUrl != null && photoUrl.isNotEmpty)
                                                ? ClipRRect(
                                                    borderRadius: BorderRadius.circular(12),
                                                    child: Image.network(
                                                      photoUrl,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  )
                                                : const Center(
                                                    child: Icon(
                                                      Icons.directions_car,
                                                      size: 40,
                                                      color: Color(0xFF08004D),
                                                    ),
                                                  ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "${data['nom'] ?? ''} ${data['prenom'] ?? ''}",
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                color: Color(0xFF08004D),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Icon(Icons.calendar_today, 
                                                      size: 16,
                                                      color: Color(0xFF08004D),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      "Date de début",
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        color: Colors.grey[700],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Text(
                                                  "${data['dateDebut'] ?? ''}",
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w500,
                                                    color: Colors.grey[900],
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Row(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Icon(Icons.event_available, 
                                                      size: 16,
                                                      color: Color(0xFF08004D),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      "Date de restitution",
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        color: Colors.grey[700],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Text(
                                                  "${data['dateFinEffectif'] ?? 'Non restitué'}",
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w500,
                                                    color: Colors.grey[900],
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Icon(Icons.directions_car_filled_outlined,
                                                  size: 16,
                                                  color: Color(0xFF08004D),
                                                ),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    "${data['marque'] ?? ''} ${data['modele'] ?? ''}",
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.w500,
                                                      color: Colors.grey[900],
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Icon(Icons.directions_car_filled, 
                                                  size: 16,
                                                  color: Color(0xFF08004D),
                                                ),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        "Immatriculation",
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                          color: Colors.grey[700],
                                                        ),
                                                      ),
                                                      Text(
                                                        "${data['immatriculation'] ?? ''}",
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                          fontWeight: FontWeight.w500,
                                                          color: Colors.grey[900],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
