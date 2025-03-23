import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../screens/add_vehicule.dart';
import '../services/collaborateur_util.dart';

class DeleteVehicule {
  final BuildContext context;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  DeleteVehicule(this.context);

  void navigateToAddVehicule([String? immatriculationId]) async {
    try {
      // Vérifier le statut du collaborateur
      final status = await CollaborateurUtil.checkCollaborateurStatus();
      final userId = status['userId'];
      
      if (userId == null) {
        print("❌ Utilisateur non connecté");
        return;
      }
      
      // Déterminer l'ID à utiliser (admin ou collaborateur)
      final targetId = status['isCollaborateur'] ? status['adminId'] : userId;
      
      if (targetId == null) {
        print("❌ ID cible non disponible");
        return;
      }
      
      // Vérifier les permissions si c'est un collaborateur
      if (status['isCollaborateur']) {
        // Vérifier si le collaborateur a la permission d'écriture
        final hasWritePermission = await CollaborateurUtil.checkCollaborateurPermission('ecriture');
        if (!hasWritePermission) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Vous n'avez pas la permission de modifier les véhicules."),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      }

      Map<String, dynamic>? vehicleData;
      if (immatriculationId != null) {
        final doc = await _firestore
            .collection('users')
            .doc(targetId)
            .collection('vehicules')
            .doc(immatriculationId)
            .get();
        vehicleData = doc.data();
      }
      
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddVehiculeScreen(
              vehicleId: immatriculationId,
              vehicleData: vehicleData,
            ),
          ),
        );
      }
    } catch (e) {
      print("❌ Erreur lors de la navigation: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erreur: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> deleteVehicule(String immatriculationId) async {
    try {
      // Vérifier le statut du collaborateur
      final status = await CollaborateurUtil.checkCollaborateurStatus();
      final userId = status['userId'];
      
      if (userId == null) {
        print("❌ Utilisateur non connecté");
        return;
      }
      
      // Déterminer l'ID à utiliser (admin ou collaborateur)
      final targetId = status['isCollaborateur'] ? status['adminId'] : userId;
      
      if (targetId == null) {
        print("❌ ID cible non disponible");
        return;
      }
      
      // Vérifier les permissions si c'est un collaborateur
      if (status['isCollaborateur']) {
        // Vérifier si le collaborateur a la permission de suppression
        final hasDeletePermission = await CollaborateurUtil.checkCollaborateurPermission('suppression');
        if (!hasDeletePermission) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Vous n'avez pas la permission de supprimer les véhicules."),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      }

      // Afficher un indicateur de chargement
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      // Récupérer d'abord le document du véhicule
      final vehicleDoc = await _firestore
          .collection('users')
          .doc(targetId)
          .collection('vehicules')
          .doc(immatriculationId)
          .get();

      if (!vehicleDoc.exists) {
        // Si le document n'existe pas, essayer de le trouver par l'immatriculation
        final querySnapshot = await _firestore
            .collection('users')
            .doc(targetId)
            .collection('vehicules')
            .where('immatriculation', isEqualTo: immatriculationId)
            .get();

        if (querySnapshot.docs.isEmpty) {
          if (context.mounted) {
            Navigator.pop(context); // Fermer l'indicateur de chargement
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Véhicule non trouvé."),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        // Utiliser le premier document trouvé
        final vehicleData = querySnapshot.docs.first;

        // Supprimer les photos
        final data = vehicleData.data();
        await _deleteVehiclePhotos(data);

        // Supprimer le document
        await vehicleData.reference.delete();
      } else {
        // Supprimer les photos
        final data = vehicleDoc.data();
        if (data != null) {
          await _deleteVehiclePhotos(data);
        }

        // Supprimer le document
        await vehicleDoc.reference.delete();
      }

      if (context.mounted) {
        Navigator.pop(context); // Fermer l'indicateur de chargement
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Véhicule supprimé avec succès !"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Fermer l'indicateur de chargement
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erreur lors de la suppression : $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteVehiclePhotos(Map<String, dynamic> vehicleData) async {
    try {
      if (vehicleData['photoVehiculeUrl'] != null) {
        await _deleteStorageFile(vehicleData['photoVehiculeUrl']);
      }
      if (vehicleData['photoCarteGriseUrl'] != null) {
        await _deleteStorageFile(vehicleData['photoCarteGriseUrl']);
      }
      if (vehicleData['photoAssuranceUrl'] != null) {
        await _deleteStorageFile(vehicleData['photoAssuranceUrl']);
      }
    } catch (e) {
      print('❌ Erreur lors de la suppression des photos: $e');
    }
  }

  Future<void> _deleteStorageFile(String? fileUrl) async {
    try {
      if (fileUrl != null &&
          fileUrl.isNotEmpty &&
          (fileUrl.startsWith('gs://') ||
              fileUrl.startsWith('https://firebasestorage.googleapis.com'))) {
        final ref = _storage.refFromURL(fileUrl);
        await ref.delete();
      }
    } catch (e) {
      print('❌ Erreur lors de la suppression du fichier: $e');
    }
  }

  void showActionDialog(String immatriculationId) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Actions",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF08004D),
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.edit, color: Color(0xFF08004D)),
                title: const Text('Modifier le véhicule'),
                onTap: () {
                  Navigator.pop(context);
                  navigateToAddVehicule(immatriculationId);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text(
                  'Supprimer le véhicule',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmationDialog(immatriculationId);
                },
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[300],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Annuler',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmationDialog(String immatriculationId) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Colors.red,
                size: 60,
              ),
              const SizedBox(height: 20),
              const Text(
                "Confirmation",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF08004D),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Êtes-vous sûr de vouloir supprimer ce véhicule ? Cette action est irréversible.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[300],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Annuler',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        deleteVehicule(immatriculationId);
                      },
                      child: const Text(
                        'Supprimer',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
