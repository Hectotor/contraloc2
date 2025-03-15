import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

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

      // Vérifier si l'utilisateur est un collaborateur
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final userData = userDoc.data();
      String targetUserId = user.uid;

      if (userData != null && userData['role'] == 'collaborateur') {
        final adminId = userData['adminId'];
        final collabId = userData['id']; // Récupérer l'ID du collaborateur
        print('👥 Utilisateur collaborateur détecté');
        print('   - Admin ID: $adminId');
        print('   - Collab ID: $collabId');
        targetUserId = adminId;

        // Vérifier les permissions du collaborateur en utilisant une approche similaire à _getCollaborateurPermissions()
        DocumentSnapshot? collabDoc;
        Map<String, dynamic>? permissions;
        
        // 1. Essayer d'abord avec l'ID du collaborateur
        if (collabId != null) {
          print('🔍 Recherche du document collaborateur avec ID: $collabId');
          final querySnapshot = await FirebaseFirestore.instance
              .collection('users')
              .doc(adminId)
              .collection('authentification')
              .where('id', isEqualTo: collabId)
              .limit(1)
              .get();
              
          if (querySnapshot.docs.isNotEmpty) {
            collabDoc = querySnapshot.docs.first;
            print('✅ Document collaborateur trouvé avec ID');
            
            // ignore: unnecessary_cast
            Map<String, dynamic>? collabData = collabDoc.data() as Map<String, dynamic>?;
            if (collabData != null && collabData['permissions'] != null) {
              permissions = collabData['permissions'];
            }
          } else {
            print('❌ Document collaborateur non trouvé avec ID');
          }
        }
        
        // 2. Si aucun document n'est trouvé avec l'ID, essayer avec l'UID
        if (permissions == null) {
          print('🔍 Recherche du document collaborateur avec UID: ${user.uid}');
          final collabDocByUid = await FirebaseFirestore.instance
              .collection('users')
              .doc(adminId)
              .collection('authentification')
              .doc(user.uid)
              .get();
              
          if (collabDocByUid.exists) {
            collabDoc = collabDocByUid;
            print('✅ Document collaborateur trouvé avec UID');
            
            // ignore: unnecessary_cast
            Map<String, dynamic>? collabData = collabDocByUid.data() as Map<String, dynamic>?;
            if (collabData != null && collabData['permissions'] != null) {
              permissions = collabData['permissions'];
            }
          } else {
            print('❌ Document collaborateur non trouvé même avec UID');
          }
        }
        
        // 3. Vérifier les permissions
        if (permissions != null) {
          print('📋 Permissions collaborateur:');
          print('   - Lecture: ${permissions['lecture'] == true ? "✅" : "❌"}');
          print('   - Écriture: ${permissions['ecriture'] == true ? "✅" : "❌"}');
          print('   - Suppression: ${permissions['suppression'] == true ? "✅" : "❌"}');
          
          if (permissions['suppression'] == true) {
            print('✅ Collaborateur avec permission de suppression');
          } else {
            print('❌ Collaborateur sans permission de suppression');
            if (dialogContext != null && dialogContext!.mounted) {
              Navigator.pop(dialogContext!);
            }
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Vous n'avez pas la permission de supprimer des contrats"),
                  backgroundColor: Colors.red,
                ),
              );
            }
            return;
          }
        } else {
          print('❌ Aucune permission trouvée pour le collaborateur');
          if (dialogContext != null && dialogContext!.mounted) {
            Navigator.pop(dialogContext!);
          }
          if (context.mounted) {
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

      // Récupérer les données du contrat pour les photos
      final contratData = await FirebaseFirestore.instance
          .collection('users')
          .doc(targetUserId)
          .collection('locations')
          .doc(contratId)
          .get();

      // Sauvegarder les URLs des photos
      List<String> photosToDelete = [];
      if (contratData.exists) {
        final data = contratData.data()!;

        // Ajouter les photos standard
        if (data['photos'] != null) {
          photosToDelete.addAll(List<String>.from(data['photos']));
        }

        // Ajouter les photos de retour
        if (data['photosRetourUrls'] != null) {
          photosToDelete.addAll(List<String>.from(data['photosRetourUrls']));
        }

        // Ajouter les photos de permis
        if (data['permisRecto'] != null) {
          photosToDelete.add(data['permisRecto']);
        }
        if (data['permisVerso'] != null) {
          photosToDelete.add(data['permisVerso']);
        }
      }

      // Supprimer d'abord les photos
      await Future.wait(photosToDelete.map((photoUrl) async {
        if (photoUrl.isNotEmpty &&
            photoUrl.startsWith('https://firebasestorage.googleapis.com')) {
          try {
            final ref = FirebaseStorage.instance.refFromURL(photoUrl);
            await ref.delete();
          } catch (e) {
            print('Erreur lors de la suppression de la photo: $e');
          }
        }
      }));

      // Ensuite supprimer le contrat
      await FirebaseFirestore.instance
          .collection('users')
          .doc(targetUserId)
          .collection('locations')
          .doc(contratId)
          .delete();

      // Fermer le dialogue de chargement
      if (dialogContext != null && dialogContext!.mounted) {
        Navigator.pop(dialogContext!);
      }

      // Afficher un message de succès
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Contrat supprimé avec succès'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        
        // Retourner à l'écran précédent après un court délai pour permettre à l'utilisateur de voir le message
        Future.delayed(const Duration(milliseconds: 500), () {
          if (context.mounted) {
            // Utiliser maybePop pour éviter les erreurs si nous sommes déjà à la racine
            Navigator.of(context).maybePop();
          }
        });
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
            content: Text('Erreur lors de la suppression : $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      print('Erreur lors de la suppression : $e');
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
