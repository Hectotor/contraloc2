import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../modifier.dart';
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
  
  // Couleur principale pour ce composant (rouge)
  final Color primaryColor = Colors.red[800]!;

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
                  hintText: 'Rechercher un contrat supprimé...',
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
          // Information sur l'appui long
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
          // Liste des contrats
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getDeletedContractsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
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

                // Filtrer les contrats selon le texte de recherche
                final filteredContrats = contrats.where((contrat) {
                  return _filterContract(contrat, _searchController.text);
                }).toList();

                // Trier les contrats par nombre de jours restants (du plus petit au plus grand)
                filteredContrats.sort((a, b) {
                  DateTime dateSuppressionA;
                  DateTime dateSuppressionB;
                  
                  try {
                    // Essayer de récupérer la date de suppression
                    if (a['dateSuppressionDefinitive'] != null) {
                      // Vérifier si c'est un Timestamp ou une String
                      if (a['dateSuppressionDefinitive'] is Timestamp) {
                        dateSuppressionA = (a['dateSuppressionDefinitive'] as Timestamp).toDate();
                      } else if (a['dateSuppressionDefinitive'] is String) {
                        // Si c'est une String, essayer de la parser
                        dateSuppressionA = DateTime.parse(a['dateSuppressionDefinitive'] as String);
                      } else {
                        // Valeur par défaut
                        dateSuppressionA = DateTime.now().add(Duration(days: 90));
                      }
                    } else if (a['datesuppression'] != null) {
                      // Essayer avec le champ 'datesuppression'
                      if (a['datesuppression'] is Timestamp) {
                        dateSuppressionA = (a['datesuppression'] as Timestamp).toDate();
                      } else if (a['datesuppression'] is String) {
                        dateSuppressionA = DateTime.parse(a['datesuppression']);
                      } else {
                        dateSuppressionA = DateTime.now().add(Duration(days: 90));
                      }
                    } else {
                      // Si aucun champ n'est disponible
                      dateSuppressionA = DateTime.now().add(Duration(days: 90));
                    }
                    
                    // Même chose pour le document B
                    if (b['dateSuppressionDefinitive'] != null) {
                      if (b['dateSuppressionDefinitive'] is Timestamp) {
                        dateSuppressionB = (b['dateSuppressionDefinitive'] as Timestamp).toDate();
                      } else if (b['dateSuppressionDefinitive'] is String) {
                        dateSuppressionB = DateTime.parse(b['dateSuppressionDefinitive']);
                      } else {
                        dateSuppressionB = DateTime.now().add(Duration(days: 90));
                      }
                    } else if (b['datesuppression'] != null) {
                      if (b['datesuppression'] is Timestamp) {
                        dateSuppressionB = (b['datesuppression'] as Timestamp).toDate();
                      } else if (b['datesuppression'] is String) {
                        dateSuppressionB = DateTime.parse(b['datesuppression']);
                      } else {
                        dateSuppressionB = DateTime.now().add(Duration(days: 90));
                      }
                    } else {
                      dateSuppressionB = DateTime.now().add(Duration(days: 90));
                    }
                  } catch (e) {
                    // En cas d'erreur, utiliser des valeurs par défaut
                    print('Erreur lors du tri des contrats supprimés: $e');
                    return 0; // Garder l'ordre d'origine
                  }
                  
                  // Calculer les jours restants
                  final joursRestantsA = dateSuppressionA.difference(DateTime.now()).inDays;
                  final joursRestantsB = dateSuppressionB.difference(DateTime.now()).inDays;
                  
                  // Trier du plus petit au plus grand nombre de jours
                  return joursRestantsA.compareTo(joursRestantsB);
                });

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
    // Calcul du nombre de jours restants
    final now = DateTime.now();
    DateTime dateSuppressionDefinitive;
    
    try {
      if (data['dateSuppressionDefinitive'] is Timestamp) {
        dateSuppressionDefinitive = (data['dateSuppressionDefinitive'] as Timestamp).toDate();
      } else if (data['dateSuppressionDefinitive'] is String) {
        dateSuppressionDefinitive = DateTime.parse(data['dateSuppressionDefinitive'] as String);
      } else {
        dateSuppressionDefinitive = now.add(Duration(days: 90));
      }
    } catch (e) {
      print('Erreur de parsing de la date: $e');
      dateSuppressionDefinitive = now.add(Duration(days: 90));
    }
    
    final difference = dateSuppressionDefinitive.difference(now);
    final daysRemaining = difference.inDays;

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
                            color: Colors.red[50],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.restore_rounded,
                            color: primaryColor,
                            size: 48,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Restaurer le contrat ?',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
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
                                child: Text(
                                  'Annuler',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: primaryColor,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  // Restaurer le contrat
                                  _restoreContract(contratId);
                                  Navigator.pop(context);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête de la carte avec indicateur de jours restants
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
                    Icon(Icons.delete, color: primaryColor, size: 24),
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
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "J-$daysRemaining",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
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
                          _buildInfoRow("Supprimé", _formatTimestamp(data['dateSuppression'])),
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
}
