import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../navigation.dart'; // Ajouter cet import

class SuppContrat {
  static Future<void> deleteContract(
      BuildContext context, String contratId) async {
    BuildContext? dialogContext;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) {
        dialogContext = ctx;
        return WillPopScope(
          onWillPop: () async => false,
          child: Center(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Suppression en cours...'),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("Utilisateur non connecté");

      // Récupérer les données du contrat pour les photos
      final contratData = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('locations')
          .doc(contratId)
          .get();

      // Sauvegarder les URLs des photos
      List<String> photosToDelete = [];
      if (contratData.exists) {
        final data = contratData.data();
        if (data != null) {
          photosToDelete.addAll(List<String>.from(data['photos'] ?? []));
          if (data['permisRecto'] != null)
            photosToDelete.add(data['permisRecto']);
          if (data['permisVerso'] != null)
            photosToDelete.add(data['permisVerso']);
        }
      }

      // Supprimer d'abord le contrat
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('locations')
          .doc(contratId)
          .delete();

      // Fermer le dialogue et afficher le succès
      if (dialogContext != null && dialogContext?.mounted == true) {
        Navigator.pop(dialogContext!);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Le contrat a été supprimé avec succès'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }

      // Navigation
      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const NavigationPage(initialTab: 1),
          ),
        );
      }

      // Supprimer les photos en arrière-plan
      _deletePhotosLater(photosToDelete);
    } catch (e) {
      // Fermer le dialogue en cas d'erreur
      if (dialogContext != null && Navigator.canPop(dialogContext!)) {
        Navigator.pop(dialogContext!);
      }

      // Afficher une alerte en cas d'erreur
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la suppression : $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      print('Erreur lors de la suppression : $e');
    }
  }

  // Nouvelle méthode pour supprimer les photos en arrière-plan
  static Future<void> _deletePhotosLater(List<String> photoUrls) async {
    for (String photoUrl in photoUrls) {
      if (photoUrl.isNotEmpty &&
          photoUrl.startsWith('https://firebasestorage.googleapis.com')) {
        try {
          await FirebaseStorage.instance.refFromURL(photoUrl).delete();
        } catch (e) {
          print('Erreur lors de la suppression de la photo: $e');
        }
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
