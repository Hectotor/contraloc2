import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../modifier.dart';
import 'package:ContraLoc/widget/MES%20CONTRATS/vehicle_access_manager.dart';
import 'package:ContraLoc/widget/MES%20CONTRATS/contract_access_manager.dart';

class ContratEnCours extends StatefulWidget {
  final String searchText;

  ContratEnCours({Key? key, required this.searchText}) : super(key: key);

  @override
  _ContratEnCoursState createState() => _ContratEnCoursState();
}

class _ContratEnCoursState extends State<ContratEnCours> {
  final Map<String, String?> _photoUrlCache = {};
  final _searchController = TextEditingController();
  late VehicleAccessManager _vehicleAccessManager;
  late ContractAccessManager _contractAccessManager;
  
  @override
  void initState() {
    super.initState();
    _vehicleAccessManager = VehicleAccessManager();
    _contractAccessManager = ContractAccessManager();
    _initializeAccess();
  }
  
  // Méthode pour initialiser les gestionnaires d'accès
  Future<void> _initializeAccess() async {
    await _vehicleAccessManager.initialize();
    await _contractAccessManager.initialize();
    if (mounted) {
      setState(() {});
    }
  }

  Future<String?> _getVehiclePhotoUrl(String userId, String immatriculation) async {
    final cacheKey = '$userId-$immatriculation';
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

  @override
  Widget build(BuildContext context) {
    return Container(
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
                  hintText: "Rechercher par nom, immatriculation...",
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF08004D)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                onChanged: (value) => setState(() {}),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _contractAccessManager.getActiveContractsStream(),
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
                          "Aucun contrat en cours trouvé",
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
                  final data = contrat.data() as Map<String, dynamic>;
                  final clientName = "${data['nom'] ?? ''} ${data['prenom'] ?? ''}".toLowerCase();
                  final dateDebut = data['dateDebut'] ?? '';
                  final immatriculation = data['immatriculation']?.toLowerCase() ?? '';
                  final searchText = _searchController.text.toLowerCase();
                  
                  return clientName.contains(searchText) ||
                      dateDebut.toString().contains(searchText) ||
                      immatriculation.contains(searchText);
                }).toList();

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: filteredContrats.length,
                  itemBuilder: (context, index) {
                    final contrat = filteredContrats[index];
                    final data = contrat.data() as Map<String, dynamic>;

                    return FutureBuilder<String?>(
                      future: _getVehiclePhotoUrl(contrat['userId'], data['immatriculation']),
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
                                          Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Icon(Icons.calendar_today, 
                                                size: 16,
                                                color: Color(0xFF08004D),
                                              ),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      "Date de début",
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        color: Colors.grey[700],
                                                      ),
                                                    ),
                                                    Text(
                                                      "${data['dateDebut'] ?? ''}",
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
    );
  }
}
