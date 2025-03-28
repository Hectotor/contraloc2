import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/collaborateur_util.dart';

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
      // Vérifier le statut du collaborateur
      final status = await CollaborateurUtil.checkCollaborateurStatus();
      final userId = status['userId'];
      final isCollaborateur = status['isCollaborateur'] == true;
      final adminId = status['adminId'];
      
      if (userId == null) throw Exception("Utilisateur non connecté");
      
      // Vérifier les permissions de suppression pour les collaborateurs
      if (isCollaborateur) {
        final hasDeletePermission = await CollaborateurUtil.checkCollaborateurPermission('suppression');
        if (!hasDeletePermission) {
          // Fermer le dialogue de chargement
          if (dialogContext != null && dialogContext!.mounted) {
            Navigator.pop(dialogContext!);
          }
          
          // Afficher un message d'erreur
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Vous n\'avez pas les permissions nécessaires pour supprimer ce contrat.'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 3),
              ),
            );
          }
          return;
        }
      }
      
      // Déterminer l'ID à utiliser (admin pour les collaborateurs)
      final targetId = isCollaborateur ? adminId : userId;

      // Récupérer les données du contrat
      final contratDoc = await CollaborateurUtil.getDocument(
        collection: 'users',
        docId: targetId!,
        subCollection: 'locations',
        subDocId: contratId,
        useAdminId: isCollaborateur,
      );

      // Au lieu de supprimer le contrat, marquer comme "supprimé"
      if (contratDoc.exists) {
        // Mettre à jour le document avec le statut "supprimé"
        await FirebaseFirestore.instance
            .collection('users')
            .doc(targetId)
            .collection('locations')
            .doc(contratId)
            .update({
              'statussupprime': 'supprimé',
              'dateSuppression': DateTime.now().toIso8601String(),
              // Calculer la date de suppression définitive (90 jours plus tard)
              'dateSuppressionDefinitive': DateTime.now().add(const Duration(days: 90)).toIso8601String(),
            });

        // Fermer le dialogue de chargement
        if (dialogContext != null && dialogContext!.mounted) {
          Navigator.pop(dialogContext!);
        }

        // Retourner à l'écran précédent
        if (context.mounted) {
          Navigator.pop(context);
          
          // Afficher un message de confirmation
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Le contrat a été marqué pour suppression et sera définitivement supprimé dans 90 jours.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
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
