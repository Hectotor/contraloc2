import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ClientSearch extends StatefulWidget {
  final Function(Map<String, dynamic>) onClientSelected;

  const ClientSearch({
    Key? key,
    required this.onClientSelected,
  }) : super(key: key);

  @override
  State<ClientSearch> createState() => _ClientSearchState();
}

class _ClientSearchState extends State<ClientSearch> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<Map<String, dynamic>> _clients = [];
  List<Map<String, dynamic>> _filteredClients = [];
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadClients();
    
    // Mettre le focus sur le champ de recherche après le build initial
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }
  
  @override
  void dispose() {
    // Libérer les ressources
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadClients() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String adminId = user.uid;
        
        // Vérifier si l'utilisateur est un collaborateur
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        final userData = userDoc.data();
        
        if (userData != null && userData['role'] == 'collaborateur' && userData['adminId'] != null) {
          adminId = userData['adminId'];
        }
        
        // Récupérer tous les contrats qui ont des informations client
        final locationsSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(adminId)
            .collection('locations')
            .get();

        //print('Nombre de documents trouvés: ${locationsSnapshot.docs.length}');
        
        final List<Map<String, dynamic>> clientsList = [];
      // Map pour suivre les clients uniques par nom et prénom
      final Map<String, Map<String, dynamic>> uniqueClients = {};
      
      for (var doc in locationsSnapshot.docs) {
        final data = doc.data();
        
        // Vérifier si ce document contient des informations client avec nom ET prénom
        if (data.containsKey('nom') && data['nom'] != null && data['nom'].toString().trim().isNotEmpty &&
            data.containsKey('prenom') && data['prenom'] != null && data['prenom'].toString().trim().isNotEmpty) {
          // Extraire la date de début si elle existe
          DateTime? dateDebut;
          if (data.containsKey('dateDebut') && data['dateDebut'] != null) {
            try {
              // Essayer de convertir la date de début en DateTime
              if (data['dateDebut'] is Timestamp) {
                dateDebut = (data['dateDebut'] as Timestamp).toDate();
              } else if (data['dateDebut'] is String) {
                dateDebut = DateTime.tryParse(data['dateDebut']);
              }
            } catch (e) {
              print('Erreur lors de la conversion de la date: $e');
            }
          }
          
          // Créer un objet client avec les informations disponibles
          final client = {
            'id': doc.id,
            'nom': data['nom'],
            'prenom': data['prenom'],
            'entreprise': data['entrepriseClient'] ?? '', // Vérifie les deux formats possibles
            'email': data['email'] ?? '',
            'telephone': data['telephone'] ?? '',
            'adresse': data['adresse'] ?? '',
            // Informations du permis de conduire
            'numeroPermis': data['numeroPermis'] ?? '',
            'permisRectoUrl': data['permisRecto'] ?? '', // Utiliser le bon nom de champ
            'permisVersoUrl': data['permisVerso'] ?? '', // Utiliser le bon nom de champ
            'dateDebut': dateDebut, // Stocker la date de début pour le tri
          };
          
          // Créer une clé unique basée sur le nom, prénom et entreprise
          final String entreprise = data['entrepriseClient']?.toString().toLowerCase() ?? '';
          final String uniqueKey = '${data['prenom'].toString().toLowerCase()}_${data['nom'].toString().toLowerCase()}_$entreprise';
          
          // Si ce client n'existe pas encore dans notre map, l'ajouter
          if (!uniqueClients.containsKey(uniqueKey)) {
            uniqueClients[uniqueKey] = client;
          } else {
            // Le client existe déjà, vérifier si nous devons mettre à jour ses informations
            bool shouldUpdate = false;
            
            // Vérifier si la date est plus récente
            if (dateDebut != null && uniqueClients[uniqueKey]!['dateDebut'] != null && 
                dateDebut.isAfter(uniqueClients[uniqueKey]!['dateDebut'])) {
              shouldUpdate = true;
            }
            
            // Vérifier si les informations du client ont été mises à jour
            if (!shouldUpdate) {
              // Vérifier les informations générales du client
              
              // Entreprise
              if (data['entrepriseClient'] != null && data['entrepriseClient'].toString().isNotEmpty && 
                  (uniqueClients[uniqueKey]!['entreprise'] == null || uniqueClients[uniqueKey]!['entreprise'].toString().isEmpty)) {
                shouldUpdate = true;
              }
              
              // Email
              if (!shouldUpdate && data['email'] != null && data['email'].toString().isNotEmpty && 
                  (uniqueClients[uniqueKey]!['email'] == null || uniqueClients[uniqueKey]!['email'].toString().isEmpty)) {
                shouldUpdate = true;
              }
              
              // Téléphone
              if (!shouldUpdate && data['telephone'] != null && data['telephone'].toString().isNotEmpty && 
                  (uniqueClients[uniqueKey]!['telephone'] == null || uniqueClients[uniqueKey]!['telephone'].toString().isEmpty)) {
                shouldUpdate = true;
              }
              
              // Adresse
              if (!shouldUpdate && data['adresse'] != null && data['adresse'].toString().isNotEmpty && 
                  (uniqueClients[uniqueKey]!['adresse'] == null || uniqueClients[uniqueKey]!['adresse'].toString().isEmpty)) {
                shouldUpdate = true;
              }
              
              // Vérifier les informations du permis
              
              // Numéro de permis
              if (!shouldUpdate && data['numeroPermis'] != null && data['numeroPermis'].toString().isNotEmpty && 
                  (uniqueClients[uniqueKey]!['numeroPermis'] == null || uniqueClients[uniqueKey]!['numeroPermis'].toString().isEmpty)) {
                shouldUpdate = true;
              }
              
              // Images du permis - recto
              if (!shouldUpdate && data['permisRecto'] != null && data['permisRecto'].toString().isNotEmpty && 
                  (uniqueClients[uniqueKey]!['permisRectoUrl'] == null || uniqueClients[uniqueKey]!['permisRectoUrl'].toString().isEmpty)) {
                shouldUpdate = true;
              }
              
              // Images du permis - verso
              if (!shouldUpdate && data['permisVerso'] != null && data['permisVerso'].toString().isNotEmpty && 
                  (uniqueClients[uniqueKey]!['permisVersoUrl'] == null || uniqueClients[uniqueKey]!['permisVersoUrl'].toString().isEmpty)) {
                shouldUpdate = true;
              }
            }
            
            // Si nous devons mettre à jour, remplacer le client existant
            if (shouldUpdate) {
              print('Mise à jour du client ${client['prenom']} ${client['nom']} avec des informations plus récentes');
              uniqueClients[uniqueKey] = client;
            }
          }
        }
      }
      
      // Convertir la map en liste
      clientsList.addAll(uniqueClients.values);
        
        print('Nombre total de clients trouvés: ${clientsList.length}');
        
        setState(() {
          _clients = clientsList;
          _filteredClients = clientsList;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors du chargement des clients: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _filterClients(String query) {
  // Toujours montrer tous les clients quand la recherche est vide
  if (query.isEmpty) {
    setState(() {
      _filteredClients = _clients;
    });
    return;
  }

  // Nettoyer la requête en supprimant les espaces en trop et en la mettant en minuscules
  final lowercaseQuery = query.trim().toLowerCase();
  
  // Diviser la requête en mots pour permettre la recherche multi-mots
  final queryWords = lowercaseQuery.split(' ').where((word) => word.isNotEmpty).toList();
  
  setState(() {
    _filteredClients = _clients.where((client) {
      final nom = client['nom'].toString().toLowerCase();
      final prenom = client['prenom'].toString().toLowerCase();
      final entreprise = client['entreprise'].toString().toLowerCase();
      final email = client['email'].toString().toLowerCase();
      final telephone = client['telephone'].toString().toLowerCase();
      
      // Vérifier si tous les mots de la requête sont présents dans au moins un des champs
      return queryWords.every((word) {
        return nom.contains(word) ||
               prenom.contains(word) ||
               entreprise.contains(word) ||
               email.contains(word) ||
               telephone.contains(word);
      });
    }).toList();
  });
  }

  @override
  Widget build(BuildContext context) {
    // Toujours afficher la liste des clients, même si la recherche est vide
    if (_clients.isEmpty && !_isLoading) {
      _loadClients();
    }
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Champ de recherche
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Rechercher un client existant...',
              prefixIcon: const Icon(Icons.search, color: Color(0xFF08004D)),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear, color: Color(0xFF08004D)),
                onPressed: () {
                  _searchController.clear();
                  _filterClients('');
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF08004D)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF08004D), width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF08004D), width: 2),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            ),
            onChanged: _filterClients,
          ),
        ),
        
        // Indicateur de chargement, message d'erreur ou liste de clients
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Center(child: CircularProgressIndicator(color: Color(0xFF08004D))),
          )
        else if (_errorMessage.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              _errorMessage,
              style: const TextStyle(color: Colors.red),
            ),
          )
        else if (_filteredClients.isEmpty)
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              'Aucun client trouvé',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF08004D),
              ),
              textAlign: TextAlign.center,
            ),
          )
        else
          // Liste des clients avec scrolling
          Flexible(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFF08004D)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                physics: const ClampingScrollPhysics(),
                itemCount: _filteredClients.length,
                itemBuilder: (context, index) {
                  final client = _filteredClients[index];
                  return Column(
                    children: [
                      ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        title: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${client['prenom']} ${client['nom']}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Color(0xFF08004D),
                              ),
                            ),
                            if (client['entreprise'] != null && client['entreprise'].toString().isNotEmpty)
                              Text(
                                'Entreprise: (${client['entreprise']})',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF666666),
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                          ],
                        ),
                        onTap: () {
                          widget.onClientSelected(client);
                          Navigator.of(context).pop();
                        },
                      ),
                      if (index < _filteredClients.length - 1)
                        const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
                    ],
                  );
                },
              ),
            ),
          ),
      ],
    );
  }

  // La méthode dispose est déjà définie plus haut dans le code
}

// Widget pour afficher un popup de recherche de client
void showClientSearchDialog({
  required BuildContext context,
  required Function(Map<String, dynamic>) onClientSelected,
}) {
  showDialog(
    context: context,
    builder: (context) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // En-tête avec icône et titre
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF08004D).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person_search, color: Color(0xFF08004D), size: 24),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      "Sélectionner un client",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF08004D),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Contenu principal avec recherche et bouton
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Liste de clients avec hauteur fixe
                  SizedBox(
                    width: double.maxFinite,
                    height: 350,
                    child: ClientSearch(
                      onClientSelected: onClientSelected,
                    ),
                  ),
                  const SizedBox(height: 30),
                  // Bouton Annuler
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF08004D),
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 2,
                    ),
                    child: const Text(
                      "Annuler",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
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
