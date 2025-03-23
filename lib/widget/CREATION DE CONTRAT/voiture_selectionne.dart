import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../services/collaborateur_util.dart';

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
      // Utiliser CollaborateurUtil pour vérifier le statut du collaborateur
      final status = await CollaborateurUtil.checkCollaborateurStatus();
      final userId = status['userId'];
      
      if (userId == null) {
        print("❌ Utilisateur non connecté");
        return null;
      }
      
      // Déterminer l'ID à utiliser (admin ou collaborateur)
      final targetId = status['isCollaborateur'] ? status['adminId'] : userId;
      
      if (targetId == null) {
        print("❌ ID cible non disponible");
        return null;
      }
      
      print("🔍 Recherche du véhicule pour ${status['isCollaborateur'] ? 'collaborateur' : 'admin'} avec ID: $targetId");
      
      // Utiliser l'ID approprié pour accéder à la collection de véhicules
      final vehiculeDoc = await firestore
          .collection('users')
          .doc(targetId)
          .collection('vehicules')
          .where('immatriculation', isEqualTo: immatriculation)
          .get();

      if (vehiculeDoc.docs.isNotEmpty) {
        final data = vehiculeDoc.docs.first.data();
        return data['photoVehiculeUrl'] as String?;
      }
      
      return null;
    } catch (e) {
      print("❌ Erreur lors de la récupération de la photo : $e"); 
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
                borderRadius: BorderRadius.circular(10), 
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
