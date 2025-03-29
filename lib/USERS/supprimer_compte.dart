import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../SCREENS/login.dart'; // Import de l'écran de connexion
import '../widget/chargement.dart'; // Import de l'écran de chargement

class SupprimerCompte extends StatelessWidget {
  const SupprimerCompte({Key? key}) : super(key: key);

  Future<void> _deleteAccount(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        // Delete user photos from Firebase Storage
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('authentification')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          final userData = userDoc.data();
          if (userData != null) {
            if (userData['logoUrl'] != null) {
              final logoUrl = userData['logoUrl'];
              final logoRef = FirebaseStorage.instance.refFromURL(logoUrl);
              await logoRef.delete();
            }

            // Delete vehicle photos
            final vehicleDocs = await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .collection('vehicules')
                .get();

            for (var vehicleDoc in vehicleDocs.docs) {
              final vehicleData = vehicleDoc.data();
              if (vehicleData['photoVehiculeUrl'] != null) {
                final photoUrl = vehicleData['photoVehiculeUrl'];
                final photoRef = FirebaseStorage.instance.refFromURL(photoUrl);
                await photoRef.delete();
              }
              if (vehicleData['photoCarteGriseUrl'] != null) {
                final carteGriseUrl = vehicleData['photoCarteGriseUrl'];
                final carteGriseRef =
                    FirebaseStorage.instance.refFromURL(carteGriseUrl);
                await carteGriseRef.delete();
              }
              if (vehicleData['photoAssuranceUrl'] != null) {
                final assuranceUrl = vehicleData['photoAssuranceUrl'];
                final assuranceRef =
                    FirebaseStorage.instance.refFromURL(assuranceUrl);
                await assuranceRef.delete();
              }
            }

            // Delete driving license photos
            if (userData['photoPermisUrl'] != null) {
              final permisUrl = userData['photoPermisUrl'];
              final permisRef = FirebaseStorage.instance.refFromURL(permisUrl);
              await permisRef.delete();
            }
          }
        }

        // Supprimer les données utilisateur de Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .delete();
        // Supprimer le compte utilisateur
        await user.delete();
        // Déconnecter l'utilisateur et rediriger vers la page de connexion
        await FirebaseAuth.instance.signOut();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => Chargement()),
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Erreur lors de la suppression du compte : $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
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
              Icons.warning_rounded,
              color: Colors.red,
              size: 60,
            ),
            const SizedBox(height: 20),
            const Text(
              "Suppression du compte",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Êtes-vous sûr de vouloir supprimer votre compte ? Cette action est irréversible et toutes vos données seront perdues.",
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
                    onPressed: () => _deleteAccount(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      "Supprimer",
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
