import 'package:ContraLoc/widget/CREATION%20DE%20CONTRAT/client.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ContraLoc/services/firestore_service.dart';
import 'package:intl/intl.dart'; // Ajoutez cette ligne en haut de votre fichier


class CalendarScreen extends StatelessWidget {
  final Map<String, String?> _photoUrlCache = {}; // Add a cache for photo URLs

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirestoreService.getReservedContrats('réservé'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(child: Text("Erreur de chargement des contrats."));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              "Aucun contrat réservé trouvé.",
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          );
        }

        final contrats = snapshot.data!.docs;

        return ListView.builder(
          itemCount: contrats.length,
          itemBuilder: (context, index) {
            final contrat = contrats[index];
            final data = contrat.data() as Map<String, dynamic>;

            return FutureBuilder<String?>(
              future: _getVehiclePhotoUrl(
                  contrat['userId'], data['immatriculation']),
              builder: (context, snapshot) {
                final photoUrl = snapshot.data;

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ClientPage(
                          marque: data['marque'],
                          modele: data['modele'],
                          immatriculation: data['immatriculation'],
                          contratId: contrat.id,
                        ),
                      ),
                    );
                  },
                  child: Card(
                    elevation: 4,
                    margin: EdgeInsets.symmetric(
                      horizontal: MediaQuery.of(context).size.width * 0.05,
                      vertical: MediaQuery.of(context).size.width * 0.02,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Container(
                            width: MediaQuery.of(context).size.width * 0.2,
                            height: MediaQuery.of(context).size.width * 0.2,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.grey[200],
                            ),
                            child: (photoUrl != null && photoUrl.isNotEmpty)
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(12), // Arrondi des bords
                                    child: Image.network(
                                      photoUrl,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : ClipRRect(
                                    borderRadius: BorderRadius.circular(12), // Arrondi des bords
                                    child: const Icon(Icons.directions_car, size: 50, color: Colors.grey),
                                  ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "${data['nom'] ?? ''} ${data['prenom'] ?? ''}",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize:
                                        MediaQuery.of(context).size.width *
                                            0.045,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "Date de réservation : ${data['dateReservation'] != null ? DateFormat('EEEE d MMMM yyyy à HH:mm', 'fr_FR').format((data['dateReservation'] as Timestamp).toDate()) : ''}",
                                  style: TextStyle(
                                    fontSize: MediaQuery.of(context).size.width * 0.035,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                Text(
                                  "Date de fin théorique : ${data['dateFinTheorique'] }",
                                  style: TextStyle(
                                    fontSize: MediaQuery.of(context).size.width * 0.035,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                Text(
                                  "Immatriculation : ${data['immatriculation'] ?? ''}",
                                  style: TextStyle(
                                    fontSize:
                                        MediaQuery.of(context).size.width *
                                            0.035,
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
      },
    );
  }

  Future<String?> _getVehiclePhotoUrl(String userId, String immatriculation) async {
    final cacheKey = '$userId-$immatriculation';
    if (_photoUrlCache.containsKey(cacheKey)) {
      return _photoUrlCache[cacheKey];
    }

    final vehiculeDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('vehicules')
        .where('immatriculation', isEqualTo: immatriculation)
        .get();

    if (vehiculeDoc.docs.isNotEmpty) {
      final photoUrl = vehiculeDoc.docs.first.data()['photoVehiculeUrl'] as String?;
      _photoUrlCache[cacheKey] = photoUrl; // Cache the photo URL
      return photoUrl;
    }
    return null;
  }
}
