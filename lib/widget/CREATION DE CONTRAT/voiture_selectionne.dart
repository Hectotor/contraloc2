import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  Future<String?> _getVehiclePhotoUrl() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        print("Recherche du véhicule : ${immatriculation}"); // Debug log

        final vehiculeDoc = await firestore
            .collection('users')
            .doc(user.uid)
            .collection('vehicules')
            .where('immatriculation', isEqualTo: immatriculation)
            .get();

        print(
            "Nombre de documents trouvés : ${vehiculeDoc.docs.length}"); // Debug log

        if (vehiculeDoc.docs.isNotEmpty) {
          final data = vehiculeDoc.docs.first.data();
          return data['photoVehiculeUrl'] as String?;
        }
      }
      return null;
    } catch (e) {
      print("Erreur lors de la récupération de la photo : $e"); // Debug log
      return null;
    }
  }

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
          FutureBuilder<String?>(
            future: _getVehiclePhotoUrl(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              }
              if (snapshot.hasError ||
                  !snapshot.hasData ||
                  snapshot.data!.isEmpty) {
                return const Icon(Icons.directions_car,
                    size: 80, color: Colors.grey);
              }
              final photoUrl = snapshot.data!;
              return ClipRRect(
                borderRadius: BorderRadius.circular(10), // Arrondir les bords
                child: Image.network(
                  photoUrl,
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                ),
              );
            },
          ),
      ],
    );
  }
}
