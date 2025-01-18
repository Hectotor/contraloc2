import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class InfoVehicule extends StatelessWidget {
  final Map<String, dynamic> data;

  const InfoVehicule({Key? key, required this.data}) : super(key: key);

  Future<String?> _getVehiclePhotoUrl(String immatriculation) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final vehiculeDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('vehicules')
        .where('immatriculation', isEqualTo: immatriculation)
        .get();

    if (vehiculeDoc.docs.isNotEmpty) {
      return vehiculeDoc.docs.first.data()['photoVehiculeUrl']
          as String?; // Changé ici de 'photoUrl' à 'photoVehiculeUrl'
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Informations du Véhicule",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Marque: ${data['marque']}"),
                  Text("Modèle: ${data['modele']}"),
                  Text("Immatriculation: ${data['immatriculation']}"),
                ],
              ),
            ),
            FutureBuilder<String?>(
              future: _getVehiclePhotoUrl(data['immatriculation']),
              builder: (context, snapshot) {
                return Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: snapshot.data != null
                        ? Image.network(
                            snapshot.data!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.directions_car,
                                    size: 50, color: Colors.grey),
                          )
                        : const Icon(Icons.directions_car,
                            size: 50, color: Colors.grey),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}
