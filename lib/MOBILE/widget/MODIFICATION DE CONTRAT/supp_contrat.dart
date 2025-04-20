import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:contraloc/MOBILE/services/auth_util.dart';
import 'package:intl/intl.dart'; // Importer la bibliothèque Intl pour la mise en forme des dates

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
                    Text('Marquage pour suppression en cours...'),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    try {
      // Récupérer les données d'authentification
      final authData = await AuthUtil.getAuthData();
      final adminId = authData['adminId'];
      
      if (adminId == null) {
        throw Exception("Impossible de récupérer l'ID de l'admin");
      }

      // Utiliser l'ID de l'admin pour la suppression
      final targetId = adminId;

      // Récupérer les informations de l'utilisateur qui effectue la suppression
      String supprimePar = "Utilisateur inconnu";
      try {
        // Récupérer le document de l'utilisateur actuel
        final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .get();
            
        if (userDoc.exists && userDoc.data() != null) {
          final userData = userDoc.data()!;
          // Construire le nom complet de l'utilisateur
          String? prenom = userData['prenom'] as String?;
          String? nom = userData['nom'] as String?;
          
          if (prenom != null && nom != null) {
            supprimePar = "$prenom $nom";
          } else if (userData['email'] != null) {
            supprimePar = userData['email'] as String;
          }
        }
      } catch (e) {
        print('Erreur lors de la récupération des informations utilisateur: $e');
        // Continuer avec la valeur par défaut si une erreur se produit
      }

      // Récupérer les données du contrat
      final contratDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(targetId)
          .collection('locations')
          .doc(contratId)
          .get();

      // Au lieu de supprimer le contrat, marquer comme "supprimé"
      if (contratDoc.exists) {
        // Date actuelle pour l'horodatage
        final DateTime maintenant = DateTime.now();
        final String dateSuppressionStr = DateFormat('dd/MM/yyyy', 'fr_FR').format(maintenant);

        // Mettre à jour le document avec le statut "supprimé"
        await FirebaseFirestore.instance
            .collection('users')
            .doc(targetId)
            .collection('locations')
            .doc(contratId)
            .set({
              'statussupprime': 'supprimé',
              'dateSuppression': dateSuppressionStr,
              'supprimePar': supprimePar,
              'dateSuppressionDefinitive': DateFormat('dd/MM/yyyy', 'fr_FR')
                  .format(maintenant.add(const Duration(days: 90))),
            }, SetOptions(merge: true));

        // Fermer le dialogue de chargement
        if (dialogContext != null && dialogContext!.mounted) {
          Navigator.pop(dialogContext!);
        }

        // Retourner à l'écran précédent
        if (context.mounted) {
          Navigator.pop(context);
          
          // Afficher un message de confirmation
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Le contrat a été marqué pour suppression par $supprimePar et sera définitivement supprimé dans 90 jours.'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      } else {
        throw Exception("Le contrat n'existe pas");
      }
    } catch (e) {
      // Fermer le dialogue de chargement en cas d'erreur
      if (dialogContext != null && dialogContext!.mounted) {
        Navigator.pop(dialogContext!);
      }

      // Vérifier si le contexte est toujours valide avant d'afficher l'erreur
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du marquage pour suppression : $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      print('Erreur lors du marquage pour suppression : $e');
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
          "Êtes-vous sûr de vouloir supprimer ce contrat ? Il sera marqué comme supprimé et définitivement effacé dans 90 jours.",
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
