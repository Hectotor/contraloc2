import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../screens/add_vehicule.dart';

class DeleteVehicule {
  final BuildContext context;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  DeleteVehicule(this.context);

  void navigateToAddVehicule([String? immatriculationId]) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    Map<String, dynamic>? vehicleData;
    if (immatriculationId != null) {
      // Vérifier si l'utilisateur est un collaborateur
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data();
      final targetUserId = userData != null && userData['role'] == 'collaborateur'
          ? userData['adminId']
          : user.uid;

      print('👤 Données utilisateur: ${userData}');
      print('👥 Utilisateur ${userData?['role']}, utilisation de l\'ID admin: $targetUserId');
      print('🚗 Récupération du véhicule: $immatriculationId dans users/$targetUserId/vehicules');

      final doc = await _firestore
          .collection('users')
          .doc(targetUserId)
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
  }

  Future<void> deleteVehicule(String immatriculationId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
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

      // Vérifier si l'utilisateur est un collaborateur
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data();
      String targetUserId = user.uid;

      if (userData != null && userData['role'] == 'collaborateur') {
        final adminId = userData['adminId'];
        print('👥 Utilisateur collaborateur détecté');
        print('   - Admin ID: $adminId');

        // Vérifier les permissions du collaborateur
        final collabDoc = await _firestore
            .collection('users')
            .doc(adminId)
            .collection('authentification')
            .doc(user.uid)
            .get();

        final collabData = collabDoc.data();
        if (collabData != null && collabData['permissions'] != null) {
          final permissions = collabData['permissions'];
          print('📋 Permissions collaborateur:');
          print('   - Lecture: ${permissions['lecture'] == true ? "✅" : "❌"}');
          print('   - Écriture: ${permissions['ecriture'] == true ? "✅" : "❌"}');
          
          if (permissions['ecriture'] == true) {
            print('✅ Collaborateur avec permission d\'écriture');
            targetUserId = adminId;
          } else {
            print('❌ Collaborateur sans permission d\'écriture');
            if (context.mounted) {
              Navigator.pop(context); // Fermer l'indicateur de chargement
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Vous n'avez pas la permission de supprimer des véhicules"),
                  backgroundColor: Colors.red,
                ),
              );
            }
            return;
          }
        } else {
          print('❌ Aucune permission trouvée pour le collaborateur');
          if (context.mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Permissions non trouvées"),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      } else {
        print('👤 Utilisateur admin');
      }

      print('🚗 Immatriculation à supprimer: $immatriculationId');

      // Récupérer le document du véhicule dans la collection de l'admin
      final vehicleDoc = await _firestore
          .collection('users')
          .doc(targetUserId)
          .collection('vehicules')
          .doc(immatriculationId)
          .get();

      print('📁 Recherche dans: users/$targetUserId/vehicules/$immatriculationId');

      if (!vehicleDoc.exists) {
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

      // Supprimer les photos
      final data = vehicleDoc.data();
      if (data != null) {
        await _deleteVehiclePhotos(data);
      }

      // Supprimer le document
      await vehicleDoc.reference.delete();
      print('✅ Véhicule supprimé avec succès');

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
      print('❌ Erreur lors de la suppression: $e');
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
      print('Erreur lors de la suppression des photos: $e');
    }
  }

  Future<void> _deleteStorageFile(String? fileUrl) async {
    try {
      if (fileUrl != null &&
          fileUrl.isNotEmpty &&
          (fileUrl.startsWith('gs://') ||
              fileUrl.startsWith('https://firebasestorage.googleapis.com'))) {
        final ref = FirebaseStorage.instance.refFromURL(fileUrl);
        await ref.delete();
      }
    } catch (e) {
      print('Erreur lors de la suppression du fichier: $e');
    }
  }

  void showActionDialog(String immatriculationId) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white, // Ajout ici
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
        backgroundColor: Colors.white, // Ajout ici
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.warning_rounded,
                color: Colors.red,
                size: 60,
              ),
              const SizedBox(height: 20),
              const Text(
                "Suppression",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Êtes-vous sûr de vouloir supprimer ce véhicule ?",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        "Annuler",
                        style: TextStyle(
                          color: Color(0xFF08004D),
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        deleteVehicule(immatriculationId);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        "Supprimer",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
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
