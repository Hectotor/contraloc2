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
  List<Map<String, dynamic>> _clients = [];
  List<Map<String, dynamic>> _filteredClients = [];
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadClients();
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
            'permisRectoUrl': data['permisRectoUrl'] ?? '',
            'permisVersoUrl': data['permisVersoUrl'] ?? '',
          };
          
          // Créer une clé unique basée sur le nom et prénom
          final String uniqueKey = '${data['prenom'].toString().toLowerCase()}_${data['nom'].toString().toLowerCase()}';
          
          // Si ce client n'existe pas encore dans notre map, l'ajouter
          if (!uniqueClients.containsKey(uniqueKey)) {
            uniqueClients[uniqueKey] = client;
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

    final lowercaseQuery = query.toLowerCase();
    
    setState(() {
      _filteredClients = _clients.where((client) {
        final nom = client['nom'].toString().toLowerCase();
        final prenom = client['prenom'].toString().toLowerCase();
        final entreprise = client['entreprise'].toString().toLowerCase();
        final email = client['email'].toString().toLowerCase();
        final telephone = client['telephone'].toString().toLowerCase();
        
        return nom.contains(lowercaseQuery) ||
               prenom.contains(lowercaseQuery) ||
               entreprise.contains(lowercaseQuery) ||
               email.contains(lowercaseQuery) ||
               telephone.contains(lowercaseQuery);
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
              margin: const EdgeInsets.symmetric(horizontal: 5),
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
                        title: Text(
                          '${client['prenom']} ${client['nom']}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF08004D),
                          ),
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
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
