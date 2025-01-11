import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../screens/add_vehicule.dart';

class DeleteVehicule {
  final BuildContext context;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  DeleteVehicule(this.context);

  void navigateToAddVehicule([String? vehicleId]) async {
    Map<String, dynamic>? vehicleData;
    if (vehicleId != null) {
      final doc = await _firestore.collection('vehicules').doc(vehicleId).get();
      vehicleData = doc.data();
    }
    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddVehiculeScreen(
            vehicleId: vehicleId,
            vehicleData: vehicleData,
          ),
        ),
      );
    }
  }

  Future<void> deleteVehicule(String vehicleId) async {
    try {
      await _firestore.collection('vehicules').doc(vehicleId).delete();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Véhicule supprimé avec succès !"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur lors de la suppression : $e")),
        );
      }
    }
  }

  void showActionDialog(String vehicleId) {
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
                  navigateToAddVehicule(vehicleId);
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
                  _showDeleteConfirmationDialog(vehicleId);
                },
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF08004D),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    "Annuler",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
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

  void _showDeleteConfirmationDialog(String vehicleId) {
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
                        deleteVehicule(vehicleId);
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
                        style: TextStyle(fontSize: 16),
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
