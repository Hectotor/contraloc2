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
  
  // Couleur principale pour ce composant (vert)
  final Color primaryColor = Color(0xFF1B5E20); // Vert foncé

  @override
  void initState() {
    super.initState();
    _vehicleAccessManager = VehicleAccessManager.instance;
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
              .get(const GetOptions(source: Source.server));

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
            .orderBy('dateRestitution', descending: true)
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
        .orderBy('dateRestitution', descending: true)
        .snapshots();
  }

  Future<String?> _getVehiclePhotoUrl(String immatriculation) async {
    final cacheKey = immatriculation;
    if (_photoUrlCache.containsKey(cacheKey)) {
      return _photoUrlCache[cacheKey];
    }

    try {
      // Récupérer les données du véhicule directement depuis le serveur et le cache
      final String effectiveUserId = _targetUserId ?? FirebaseAuth.instance.currentUser?.uid ?? '';
      if (effectiveUserId.isEmpty) {
        return null;
      }
      
      // Requête directe qui récupère depuis le serveur et met à jour le cache
      final query = FirebaseFirestore.instance
          .collection('users')
          .doc(effectiveUserId)
          .collection('vehicules')
          .where('immatriculation', isEqualTo: immatriculation);
      
      final QuerySnapshot snapshot = await query.get(const GetOptions(source: Source.server));
      
      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data() as Map<String, dynamic>?;
        String? photoUrl;
        
        if (data != null) {
          if (data.containsKey('photoUrls') && data['photoUrls'] is List && (data['photoUrls'] as List).isNotEmpty) {
            photoUrl = (data['photoUrls'] as List).first.toString();
          } else if (data.containsKey('photoVehiculeUrl')) {
            photoUrl = data['photoVehiculeUrl'] as String?;
          }
        }

        _photoUrlCache[cacheKey] = photoUrl;
        return photoUrl;
      }

      _photoUrlCache[cacheKey] = null;
      return null;
    } catch (e) {
      print("Erreur lors de la récupération de la photo du véhicule: $e");
      _photoUrlCache[cacheKey] = null;
      return null;
    }
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

  // Fonction pour formater les dates Timestamp en String
  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return "Non spécifié";
    
    // Format spécifique pour les dates de début qui sont au format "mercredi 2 avril 2025 à 20:39"
    if (timestamp is String) {
      try {
        // Découper la chaîne pour en extraire les composants
        List<String> parts = timestamp.split(' ');
        if (parts.length >= 4) { // Format typique: "mercredi 2 avril 2025 à 20:39"
          String jour = parts[1].padLeft(2, '0'); // Le jour

          // Conversion du mois en numéro
          String moisTexte = parts[2].toLowerCase();
          Map<String, String> moisMap = {
            'janvier': '01', 'février': '02', 'mars': '03', 'avril': '04',
            'mai': '05', 'juin': '06', 'juillet': '07', 'août': '08',
            'septembre': '09', 'octobre': '10', 'novembre': '11', 'décembre': '12'
          };
          String mois = moisMap[moisTexte] ?? '01';
          
          String annee = parts[3]; // L'année
        
          return "$jour/$mois/$annee";
        }
      } catch (e) {
        return timestamp; // En cas d'erreur, retourner la chaîne originale
      }
      return timestamp;
    }
    
    if (timestamp is Timestamp) {
      DateTime dateTime = timestamp.toDate();
      
      // Format JJ/MM/AAAA pour toutes les dates
      return "${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}";
    }
    
    return "Format inconnu";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Barre de recherche améliorée
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 10,
                    spreadRadius: 1,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Rechercher un contrat restitué...',
                  prefixIcon: Icon(Icons.search, color: primaryColor.withOpacity(0.6)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 15),
                ),
                onChanged: (value) {
                  setState(() {});
                },
              ),
            ),
          ),
          // Liste des contrats
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getReturnedContractsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1B5E20)),
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
                        Icon(Icons.check_circle_outline, size: 48, color: Colors.grey[400]),
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

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                          child: _buildContractCard(context, contrat.id, data, photoUrl),
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
    );
  }

  Widget _buildContractCard(BuildContext context, String contratId, Map<String, dynamic> data, String? photoUrl) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.20),
            blurRadius: 4,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ModifierScreen(
                  contratId: contratId,
                  data: data,
                ),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête de la carte
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: primaryColor, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "${data['nom'] ?? ''} ${data['prenom'] ?? ''}",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              // Contenu de la carte
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Photo du véhicule
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey[100],
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 6,
                            spreadRadius: 1,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: (photoUrl != null && photoUrl.isNotEmpty)
                          ? Image.network(
                              photoUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Center(
                                child: Icon(
                                  Icons.directions_car,
                                  size: 40,
                                  color: primaryColor,
                                ),
                              ),
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                    color: primaryColor,
                                  ),
                                );
                              },
                            )
                          : Center(
                              child: Icon(
                                Icons.directions_car,
                                size: 40,
                                color: primaryColor,
                              ),
                            ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Informations du contrat
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow("Restitué", _formatTimestamp(data['dateRestitution'])),
                          const SizedBox(height: 12),
                          _buildInfoRow("Début", _formatTimestamp(data['dateDebut'])),
                          const SizedBox(height: 12),
                          _buildInfoRow("Véhicule", data['immatriculation'] ?? "Non spécifié"),
                          if (data['marque'] != null && data['modele'] != null) ...[  
                            const SizedBox(height: 12),
                            _buildInfoRow("Modèle", "${data['marque']} ${data['modele']}"),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 70,
          child: Text(
            "$label :",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: primaryColor,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[800],
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
