import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ContraLoc/services/firestore_service.dart';
import '../modifier.dart';

class ContratEnCours extends StatelessWidget {
  final String searchText;

  const ContratEnCours({Key? key, required this.searchText}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirestoreService.getContrats('en_cours'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          print(
              "Erreur de chargement des contrats en cours : ${snapshot.error}");
          return const Center(
              child: Text("Erreur de chargement des contrats."));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              "Aucun contrat en cours trouvé.",
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          );
        }

        final contrats = snapshot.data!.docs;

        final filteredContrats = contrats.where((contrat) {
          final data = contrat.data() as Map<String, dynamic>;
          final clientName =
              "${data['nom'] ?? ''} ${data['prenom'] ?? ''}".toLowerCase();
          final dateDebut = data['dateDebut'] ?? '';
          final immatriculation = data['immatriculation']?.toLowerCase() ?? '';
          return clientName.contains(searchText.toLowerCase()) ||
              dateDebut.toString().contains(searchText.toLowerCase()) ||
              immatriculation.contains(searchText.toLowerCase());
        }).toList();

        return ListView.builder(
          itemCount: filteredContrats.length,
          itemBuilder: (context, index) {
            final contrat = filteredContrats[index];
            final data = contrat.data() as Map<String, dynamic>;

            return GestureDetector(
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
              child: Card(
                elevation: 4, // Ombre sous la carte
                margin: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width * 0.05,
                  vertical: MediaQuery.of(context).size.width * 0.02,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      // Image ou icône du véhicule
                      Container(
                        width: MediaQuery.of(context).size.width * 0.2,
                        height: MediaQuery.of(context).size.width * 0.2,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey[200],
                          image: data['photoVehiculeUrl'] != null &&
                                  data['photoVehiculeUrl'].isNotEmpty
                              ? DecorationImage(
                                  image: NetworkImage(data['photoVehiculeUrl']),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: data['photoVehiculeUrl'] == null ||
                                data['photoVehiculeUrl'].isEmpty
                            ? const Icon(Icons.directions_car,
                                size: 50, color: Colors.grey)
                            : null,
                      ),
                      const SizedBox(
                          width: 16), // Espacement entre image et texte
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${data['nom'] ?? ''} ${data['prenom'] ?? ''}",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize:
                                    MediaQuery.of(context).size.width * 0.045,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Date de début : ${data['dateDebut'] ?? ''}",
                              style: TextStyle(
                                fontSize:
                                    MediaQuery.of(context).size.width * 0.035,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              "Immatriculation : ${data['immatriculation'] ?? ''}",
                              style: TextStyle(
                                fontSize:
                                    MediaQuery.of(context).size.width * 0.035,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 18,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
