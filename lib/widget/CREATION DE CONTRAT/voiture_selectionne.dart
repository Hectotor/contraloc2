import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class VoitureSelectionne extends StatelessWidget {
  final String marque;
  final String modele;
  final String immatriculation;
  final FirebaseFirestore firestore;

  const VoitureSelectionne({
    Key? key,
    required this.marque,
    required this.modele,
    required this.immatriculation,
    required this.firestore,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Véhicule sélectionné :",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                "Marque : $marque",
                style: const TextStyle(fontSize: 14),
              ),
              Text(
                "Modèle : $modele",
                style: const TextStyle(fontSize: 14),
              ),
              Text(
                "Immatriculation : $immatriculation",
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
        if (immatriculation.isNotEmpty)
          FutureBuilder<DocumentSnapshot>(
            future: firestore
                .collection('vehicules')
                .where('immatriculation', isEqualTo: immatriculation)
                .get()
                .then((snapshot) => snapshot.docs.first),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              }
              if (snapshot.hasError || !snapshot.hasData) {
                return const Icon(Icons.directions_car,
                    size: 80, color: Colors.grey);
              }
              final data = snapshot.data!.data() as Map<String, dynamic>;
              final photoUrl = data['photoVehiculeUrl'] ?? '';
              return photoUrl.isNotEmpty
                  ? ClipRRect(
                      borderRadius:
                          BorderRadius.circular(10), // Arrondir les bords
                      child: Image.network(
                        photoUrl,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                    )
                  : const Icon(Icons.directions_car,
                      size: 80, color: Colors.grey);
            },
          ),
      ],
    );
  }
}
