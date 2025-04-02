import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../modifier.dart';
import 'package:ContraLoc/widget/MES%20CONTRATS/vehicle_access_manager.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'search_filtre.dart';

class ContratRestitues extends StatefulWidget {
  final String searchText;
  final Function(int)? onContractsCountChanged;

  ContratRestitues({Key? key, required this.searchText, this.onContractsCountChanged}) : super(key: key);

  @override
  _ContratRestituesState createState() => _ContratRestituesState();
}

class _ContratRestituesState extends State<ContratRestitues> {
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

  // Méthode pour obtenir le stream des contrats restitués
  Stream<QuerySnapshot> _getReturnedContractsStream() {
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
              .where('status', isEqualTo: 'restitue')
              .orderBy('dateRestitution', descending: true)
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
            .where('status', isEqualTo: 'restitue')
            .orderBy('dateFinEffectif', descending: true)
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
        .where('status', isEqualTo: 'restitue')
        .orderBy('dateFinEffectif', descending: true)
        .snapshots();
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

  // Méthode pour filtrer les contrats en fonction du texte de recherche
  bool _filterContract(DocumentSnapshot doc, String searchText) {
    // Vérifier si le contrat est marqué comme supprimé
    if (doc.data() is Map<String, dynamic>) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      if (data.containsKey('statussupprime') && data['statussupprime'] == 'supprimé') {
        return false; // Ne pas afficher les contrats supprimés
      }
    }
    
    return SearchFiltre.filterContract(doc, searchText);
  }

  @override
  Widget build(BuildContext context) {
    // Ne pas écraser le texte à chaque reconstruction
    // _searchController.text = widget.searchText;

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
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _getReturnedContractsStream(),
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
                          Icon(Icons.description_outlined, size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          const Text(
                            "Aucun contrat restitué trouvé",
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
                              child: InkWell(
                                borderRadius: BorderRadius.circular(15),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ModifierScreen(
                                        contratId: contrat.id,
                                        data: data,
                                      ),
                                    ),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Row(
                                    children: [
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
                                            const SizedBox(height: 8),
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
                                                  "${data['dateFinEffectif'] ?? ''}",
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
                                      Icon(
                                        Icons.chevron_right,
                                        color: Colors.grey[400],
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
