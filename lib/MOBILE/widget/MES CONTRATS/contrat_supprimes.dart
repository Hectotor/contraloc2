import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:contraloc/MOBILE/widget/MES%20CONTRATS/vehicle_access_manager.dart';
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
    _vehicleAccessManager = VehicleAccessManager.instance;
    _initializeAccess();
    _searchController.text = widget.searchText;
    
    // Vérifier et supprimer les contrats expirés au chargement
    Future.delayed(Duration.zero, () {
      _checkAndDeleteExpiredContracts();
    });
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

  // Méthode pour parser une date au format français (ex: "vendredi 4 juillet 2025 à 18:44")
  // ou au format court (ex: "05/04/2025") ou au format ISO 8601
  DateTime? _parseFrenchDate(String dateStr) {
    try {
      // Vérifier si c'est un format ISO 8601 (yyyy-MM-ddTHH:mm:ss)
      if (dateStr.contains('T') && dateStr.contains('-')) {
        try {
          DateTime date = DateTime.parse(dateStr);
          return date;
        } catch (e) {
          print('Erreur lors du parsing de la date ISO 8601: $e');
        }
      }
      
      // Vérifier si c'est le format court (dd/MM/yyyy)
      if (dateStr.contains('/')) {
        List<String> parts = dateStr.split('/');
        if (parts.length == 3) {
          int jour = int.parse(parts[0]);
          int mois = int.parse(parts[1]);
          int annee = int.parse(parts[2]);
          return DateTime(annee, mois, jour);
        }
      }
      
      // Format long français
      List<String> parts = dateStr.split(' ');
      if (parts.length >= 5) { // Format typique: "vendredi 4 juillet 2025 à 18:44"
        int jour = int.parse(parts[1]);

        // Conversion du mois en numéro
        String moisTexte = parts[2].toLowerCase();
        Map<String, int> moisMap = {
          'janvier': 1, 'février': 2, 'mars': 3, 'avril': 4,
          'mai': 5, 'juin': 6, 'juillet': 7, 'août': 8,
          'septembre': 9, 'octobre': 10, 'novembre': 11, 'décembre': 12
        };
        int mois = moisMap[moisTexte] ?? 1;
        
        int annee = int.parse(parts[3]);
        
        // Extraire l'heure et les minutes
        String heureMinute = parts[5]; // Format: "18:44"
        List<String> heureMinuteParts = heureMinute.split(':');
        int heure = int.parse(heureMinuteParts[0]);
        int minute = int.parse(heureMinuteParts[1]);
        
        return DateTime(annee, mois, jour, heure, minute);
      }
    } catch (e) {
      print('Erreur lors du parsing de la date: $e');
    }
    return null;
  }

  // Méthode pour formater une date au format JJ/MM/AAAA
  String _formatDateToFrench(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return "Non spécifié";
    
    // Si c'est déjà au format JJ/MM/AAAA
    if (timestamp is String) {
      if (timestamp.contains('/') && timestamp.split('/').length == 3) {
        return timestamp; // Déjà au bon format
      }
      
      // Si c'est un format ISO 8601
      if (timestamp.contains('T') && timestamp.contains('-')) {
        try {
          DateTime date = DateTime.parse(timestamp);
          return _formatDateToFrench(date);
        } catch (e) {
          print('Erreur lors du parsing de la date ISO: $e');
        }
      }
      
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
      return _formatDateToFrench(dateTime);
    }
    
    return "Format inconnu";
  }

  // Méthode pour vérifier et supprimer définitivement les contrats dont la date de suppression définitive est dépassée
  Future<void> _checkAndDeleteExpiredContracts() async {
    try {
      final effectiveUserId = _targetUserId ?? FirebaseAuth.instance.currentUser?.uid;
      if (effectiveUserId == null) return;

      // Récupérer tous les contrats marqués comme supprimés
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(effectiveUserId)
          .collection('locations')
          .where('statussupprime', isEqualTo: 'supprimé')
          .get();

      final DateTime now = DateTime.now();
      int deletedCount = 0;
      const int daysBeforeDeletion = 90; // 90 jours avant suppression

      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();
          DateTime? dateSuppressionDefinitive;
          DateTime? dateSuppression;

          // Essayer de parser la date de suppression
          if (data['dateSuppression'] != null) {
            if (data['dateSuppression'] is Timestamp) {
              dateSuppression = (data['dateSuppression'] as Timestamp).toDate();
              print('Date de suppression trouvée: $dateSuppression');
            }
          }

          // Si on a la date de suppression, vérifier qu'elle est ancienne
          if (dateSuppression != null) {
            final daysSinceSuppression = now.difference(dateSuppression).inDays;
            print('Jours depuis la suppression: $daysSinceSuppression');

            // Vérifier si le contrat est marqué comme définitivement supprimé
            if (data['dateSuppressionDefinitive'] != null) {
              if (data['dateSuppressionDefinitive'] is Timestamp) {
                dateSuppressionDefinitive = (data['dateSuppressionDefinitive'] as Timestamp).toDate();
                print('Date de suppression définitive trouvée: $dateSuppressionDefinitive');
              }
            }

            // Si la date est valide et dépassée, ou si le contrat est marqué comme définitivement supprimé
            if ((dateSuppressionDefinitive != null && dateSuppressionDefinitive.isBefore(now)) || 
                (daysSinceSuppression >= daysBeforeDeletion)) {
              
              print('Suppression du contrat ${doc.id}:'
                  '\n  - Date suppression: $dateSuppression'
                  '\n  - Jours depuis suppression: $daysSinceSuppression'
                  '\n  - Date limite: ${now.subtract(Duration(days: daysBeforeDeletion))}');

              // D'abord supprimer les fichiers associés au contrat
              await _deleteContractFiles(effectiveUserId, doc.id, data);
              
              // Ensuite supprimer le document du contrat
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(effectiveUserId)
                  .collection('locations')
                  .doc(doc.id)
                  .delete();
              
              deletedCount++;
              print('Contrat ${doc.id} supprimé définitivement');
            }
          }
        } catch (e) {
          print('Erreur lors de la vérification du contrat ${doc.id}: $e');
        }
      }

      if (deletedCount > 0) {
        print('$deletedCount contrats ont été supprimés définitivement');
        // Rafraîchir la liste des contrats si des suppressions ont été effectuées
        setState(() {});
      }
    } catch (e) {
      print('Erreur lors de la vérification des contrats expirés: $e');
    }
  }

  // Méthode pour supprimer les fichiers de stockage associés à un contrat
  Future<void> _deleteContractFiles(String userId, String contractId, Map<String, dynamic> data) async {
    try {
      final storage = FirebaseStorage.instance;
      final List<String> fieldsToCheck = [
        'photoVehiculeUrl',
        'permisRectoUrl',
        'permisVersoUrl',
        'signatureAller',
        'signatureRetour',
        'pdfUrl',
        'logoUrl',
        'photos',
        'photosUrls'
      ];

      // Vérifier et supprimer chaque fichier potentiel
      for (final field in fieldsToCheck) {
        if (data[field] != null && data[field].toString().isNotEmpty) {
          try {
            // Si c'est une URL complète, extraire le chemin
            String path = data[field];
            if (path.startsWith('https://firebasestorage.googleapis.com')) {
              // Extraire le chemin du stockage de l'URL
              final uri = Uri.parse(path);
              final pathSegments = Uri.decodeFull(uri.path).split('/o/')[1];
              path = pathSegments.replaceAll(new RegExp(r'%2F'), '/'); 
              if (path.contains('?')) {
                path = path.split('?')[0];
              }
              
              // Supprimer le fichier
              await storage.ref(path).delete();
              print('Fichier supprimé: $path');
            } else {
              // Si c'est un chemin direct
              await storage.ref(path).delete();
              print('Fichier supprimé: $path');
            }
          } catch (e) {
            print('Erreur lors de la suppression du fichier ${data[field]}: $e');
          }
        }
      }

      // Vérifier s'il y a des photos dans la liste photosUrls
      if (data['photosUrls'] != null && data['photosUrls'] is List) {
        List<dynamic> photosUrls = data['photosUrls'];
        for (var photoUrl in photosUrls) {
          if (photoUrl != null && photoUrl.toString().isNotEmpty) {
            try {
              String path = photoUrl.toString();
              if (path.startsWith('https://firebasestorage.googleapis.com')) {
                final uri = Uri.parse(path);
                final pathSegments = Uri.decodeFull(uri.path).split('/o/')[1];
                path = pathSegments.replaceAll(new RegExp(r'%2F'), '/'); 
                if (path.contains('?')) {
                  path = path.split('?')[0];
                }
                
                await storage.ref(path).delete();
                print('Photo supprimée: $path');
              } else {
                await storage.ref(path).delete();
                print('Photo supprimée: $path');
              }
            } catch (e) {
              print('Erreur lors de la suppression de la photo $photoUrl: $e');
            }
          }
        }
      }
      
      // Vérifier également le champ 'photos' qui peut être utilisé dans certains cas
      if (data['photos'] != null && data['photos'] is List) {
        List<dynamic> photos = data['photos'];
        for (var photoUrl in photos) {
          if (photoUrl != null && photoUrl.toString().isNotEmpty) {
            try {
              String path = photoUrl.toString();
              if (path.startsWith('https://firebasestorage.googleapis.com')) {
                final uri = Uri.parse(path);
                final pathSegments = Uri.decodeFull(uri.path).split('/o/')[1];
                path = pathSegments.replaceAll(new RegExp(r'%2F'), '/'); 
                if (path.contains('?')) {
                  path = path.split('?')[0];
                }
                
                await storage.ref(path).delete();
                print('Photo supprimée (champ photos): $path');
              } else {
                await storage.ref(path).delete();
                print('Photo supprimée (champ photos): $path');
              }
            } catch (e) {
              print('Erreur lors de la suppression de la photo $photoUrl: $e');
            }
          }
        }
      }

      // Vérifier s'il y a un dossier spécifique pour ce contrat et le supprimer
      try {
        final contractFolder = 'users/$userId/locations/$contractId';
        final result = await storage.ref(contractFolder).listAll();
        
        // Supprimer tous les fichiers dans le dossier
        for (var item in result.items) {
          await item.delete();
          print('Fichier supprimé du dossier: ${item.fullPath}');
        }
        
        // Supprimer les sous-dossiers récursivement
        for (var prefix in result.prefixes) {
          await _deleteFolder(prefix);
        }
      } catch (e) {
        // Ignorer les erreurs si le dossier n'existe pas
        print('Note: Aucun dossier spécifique trouvé ou erreur: $e');
      }
    } catch (e) {
      print('Erreur lors de la suppression des fichiers: $e');
    }
  }

  // Méthode pour supprimer récursivement un dossier dans Firebase Storage
  Future<void> _deleteFolder(Reference folderRef) async {
    try {
      // Lister tous les éléments dans le dossier
      final result = await folderRef.listAll();
      
      // Supprimer tous les fichiers
      for (var item in result.items) {
        await item.delete();
        print('Fichier supprimé: ${item.fullPath}');
      }
      
      // Supprimer récursivement les sous-dossiers
      for (var prefix in result.prefixes) {
        await _deleteFolder(prefix);
      }
    } catch (e) {
      print('Erreur lors de la suppression du dossier ${folderRef.fullPath}: $e');
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
                        dateSuppressionA = _parseFrenchDate(a['dateSuppressionDefinitive'] as String) ?? DateTime.now().add(Duration(days: 90));
                      } else {
                        // Valeur par défaut
                        dateSuppressionA = DateTime.now().add(Duration(days: 90));
                      }
                    } else if (a['datesuppression'] != null) {
                      // Essayer avec le champ 'datesuppression'
                      if (a['datesuppression'] is Timestamp) {
                        dateSuppressionA = (a['datesuppression'] as Timestamp).toDate();
                      } else if (a['datesuppression'] is String) {
                        dateSuppressionA = _parseFrenchDate(a['datesuppression'] as String) ?? DateTime.now().add(Duration(days: 90));
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
                        dateSuppressionB = _parseFrenchDate(b['dateSuppressionDefinitive'] as String) ?? DateTime.now().add(Duration(days: 90));
                      } else {
                        dateSuppressionB = DateTime.now().add(Duration(days: 90));
                      }
                    } else if (b['datesuppression'] != null) {
                      if (b['datesuppression'] is Timestamp) {
                        dateSuppressionB = (b['datesuppression'] as Timestamp).toDate();
                      } else if (b['datesuppression'] is String) {
                        dateSuppressionB = _parseFrenchDate(b['datesuppression'] as String) ?? DateTime.now().add(Duration(days: 90));
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
                      future: _getVehiclePhotoUrl(data['immatriculation'] ?? ''),
                      builder: (context, snapshot) {
                        final photoUrl = snapshot.data ?? '';
                        
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
      if (data['dateSuppressionDefinitive'] != null) {
        // Vérifier si c'est un Timestamp ou une String
        if (data['dateSuppressionDefinitive'] is Timestamp) {
          dateSuppressionDefinitive = (data['dateSuppressionDefinitive'] as Timestamp).toDate();
        } else if (data['dateSuppressionDefinitive'] is String) {
          // Si c'est une String, essayer de la parser
          dateSuppressionDefinitive = _parseFrenchDate(data['dateSuppressionDefinitive'] as String) ?? DateTime.now().add(Duration(days: 90));
        } else {
          // Valeur par défaut
          dateSuppressionDefinitive = DateTime.now().add(Duration(days: 90));
        }
      } else if (data['datesuppression'] != null) {
        // Essayer avec le champ 'datesuppression'
        if (data['datesuppression'] is Timestamp) {
          dateSuppressionDefinitive = (data['datesuppression'] as Timestamp).toDate();
        } else if (data['datesuppression'] is String) {
          dateSuppressionDefinitive = _parseFrenchDate(data['datesuppression'] as String) ?? DateTime.now().add(Duration(days: 90));
        } else {
          dateSuppressionDefinitive = DateTime.now().add(Duration(days: 90));
        }
      } else {
        // Si aucun champ n'est disponible
        dateSuppressionDefinitive = DateTime.now().add(Duration(days: 90));
      }
    } catch (e) {
      print('Erreur de parsing de la date: $e');
      dateSuppressionDefinitive = DateTime.now().add(Duration(days: 90));
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
                          if (data['supprimePar'] != null) ...[  
                            const SizedBox(height: 12),
                            _buildInfoRow("Par", data['supprimePar']),
                          ],
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
          width: 90,
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
            softWrap: true,
            maxLines: 3,
            overflow: TextOverflow.visible,
          ),
        ),
      ],
    );
  }
}
