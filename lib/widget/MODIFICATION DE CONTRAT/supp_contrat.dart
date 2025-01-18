import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../navigation.dart'; // Ajouter cet import

class SuppContrat {
  static Future<void> deleteContract(
      BuildContext context, String contratId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("Utilisateur non connecté");
      }

      // Show loading indicator
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      // Récupérer les données du contrat avant de le supprimer
      final contratData = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('locations')
          .doc(contratId)
          .get();

      if (contratData.exists) {
        // Supprimer les photos du Storage
        final data = contratData.data();
        if (data != null) {
          // Supprimer les photos du véhicule
          final List<String> photos = List<String>.from(data['photos'] ?? []);
          for (String photoUrl in photos) {
            try {
              await FirebaseStorage.instance.refFromURL(photoUrl).delete();
            } catch (e) {
              print('Erreur lors de la suppression de la photo: $e');
            }
          }

          // Supprimer les photos du permis
          if (data['permisRecto'] != null) {
            try {
              await FirebaseStorage.instance
                  .refFromURL(data['permisRecto'])
                  .delete();
            } catch (e) {
              print('Erreur lors de la suppression du permis recto: $e');
            }
          }
          if (data['permisVerso'] != null) {
            try {
              await FirebaseStorage.instance
                  .refFromURL(data['permisVerso'])
                  .delete();
            } catch (e) {
              print('Erreur lors de la suppression du permis verso: $e');
            }
          }
        }
      }

      // Supprime le contrat de location dans la collection de l'utilisateur
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('locations')
          .doc(contratId)
          .delete();

      if (context.mounted) {
        Navigator.of(context).pop(); // Remove loading indicator
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Le contrat a été supprimé avec succès"),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        // Remplacer la navigation simple par une redirection vers NavigationPage
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                const NavigationPage(initialTab: 1), // Tab 1 pour les contrats
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // Remove loading indicator
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erreur lors de la suppression : ${e.toString()}"),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (context.mounted) {
        Navigator.of(context).pop(); // Ensure loading indicator is removed
      }
    }
  }

  static void showDeleteConfirmationDialog(
      BuildContext context, String contratId) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text(
          "Supprimer le contrat",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "Êtes-vous sûr de vouloir supprimer ce contrat ? Cette action est irréversible.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Annuler",
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              deleteContract(context, contratId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text("Supprimer"),
          ),
        ],
      ),
    );
  }
}
