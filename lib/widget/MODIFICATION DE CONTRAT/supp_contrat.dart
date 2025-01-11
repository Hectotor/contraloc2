import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SuppContrat {
  static Future<void> deleteContract(
      BuildContext context, String contratId) async {
    try {
      // Supprime le contrat de location
      await FirebaseFirestore.instance
          .collection('locations')
          .doc(contratId)
          .delete();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Le contrat a été supprimé avec succès"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erreur lors de la suppression : $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  static void showDeleteConfirmationDialog(
      BuildContext context, String contratId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Supprimer le contrat"),
        content: const Text("Êtes-vous sûr de vouloir supprimer ce contrat ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Ferme le dialogue
              deleteContract(
                  context, contratId); // Appelle la fonction de suppression
            },
            child: const Text(
              "Supprimer",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
