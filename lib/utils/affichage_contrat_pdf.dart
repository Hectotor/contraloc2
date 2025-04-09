import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import '../USERS/contrat_condition.dart';
import '../services/collaborateur_util.dart';
import '../models/contrat_model.dart'; 
import 'pdf.dart';

class AffichageContratPdf {
  /// Génère et affiche un PDF de contrat basé sur les données fournies
  static Future<void> genererEtAfficherContratPdf({
    required BuildContext context,
    required Map<String, dynamic> data,
    required String contratId,
    required TextEditingController nettoyageIntController,
    required TextEditingController nettoyageExtController,
    required TextEditingController pourcentageEssenceRetourController,
    required TextEditingController cautionController,
    String? signatureRetourBase64,
    bool afficherPdf = true, // Nouveau paramètre pour contrôler l'ouverture du PDF
  }) async {
    bool dialogShown = false;
    if (context.mounted) {
      dialogShown = true;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
    }

    try {
      final appDir = await getApplicationDocumentsDirectory();
      final localPdfPath = '${appDir.path}/contrat_$contratId.pdf';
      final localPdfFile = File(localPdfPath);
      
      // Vérifier si le contrat est en cours
      bool isContratEnCours = data['status'] == 'en_cours';
      
      // Si le PDF existe en cache ET que le contrat n'est PAS en cours, utiliser la version cachée
      if (await localPdfFile.exists() && !isContratEnCours) {
        print(' PDF trouvé en cache local, ouverture directe');
        
        if (dialogShown && context.mounted) {
          Navigator.pop(context);
          dialogShown = false;
        }
        
        if (afficherPdf) {
          await OpenFilex.open(localPdfPath);
        }
        return;
      }
      
      // Si le contrat est en cours ou si le PDF n'existe pas en cache, générer un nouveau PDF
      if (isContratEnCours) {
        print(' Contrat en cours, génération d\'un nouveau PDF sans utiliser le cache');
      } else {
        print(' PDF non trouvé en cache local, génération sans appels Firestore...');
      }
      
      final status = await CollaborateurUtil.checkCollaborateurStatus();
      final userId = status['userId'];
      final isCollaborateur = status['isCollaborateur'] == true;
      
      print(' Génération PDF - userId: $userId, isCollaborateur: $isCollaborateur');

      String conditions = data['conditions'] ?? ContratModifier.defaultContract;
      
      // Utiliser la signature de retour fournie ou celle du contrat
      if (signatureRetourBase64 == null || signatureRetourBase64.isEmpty) {
        signatureRetourBase64 = data['signature_retour'] ?? data['signatureRetour'];
      }
      
      print(' Signature de retour récupérée : ${signatureRetourBase64 != null ? 'Présente' : 'Absente'}');
      print(' Conditions personnalisées récupérées : ${conditions != ContratModifier.defaultContract ? 'Personnalisées' : 'Par défaut'}');

      final userData = await CollaborateurUtil.getAuthData();

      // Créer un objet ContratModel à partir des données Firestore
      final contratModel = ContratModel.fromFirestore(data, id: contratId);
      
      // Mettre à jour les valeurs spécifiques au retour du véhicule si nécessaire
      final contratMisAJour = contratModel.copyWith(
        dateRetour: data['dateFinEffectif'],
        kilometrageRetour: data['kilometrageRetour'],
        commentaireRetour: data['commentaireRetour'],
        signatureRetour: signatureRetourBase64,
        pourcentageEssenceRetour: data['pourcentageEssenceRetour'],
        nettoyageInt: nettoyageIntController.text,
        nettoyageExt: nettoyageExtController.text,
        caution: cautionController.text,
        nomEntreprise: data['nomEntreprise'] ?? userData['nomEntreprise'] ?? '',
        logoUrl: data['logoUrl'] ?? userData['logoUrl'] ?? '',
        adresseEntreprise: data['adresseEntreprise'] ?? userData['adresse'] ?? '',
        telephoneEntreprise: data['telephoneEntreprise'] ?? userData['telephone'] ?? '',
        siretEntreprise: data['siretEntreprise'] ?? userData['siret'] ?? '',
      );

      // Générer le PDF en utilisant l'objet ContratModel
      final pdfPath = await generatePdf(
        contratMisAJour,
        nomCollaborateur: data['nomCollaborateur'] != null && data['prenomCollaborateur'] != null
            ? '${data['prenomCollaborateur']} ${data['nomCollaborateur']}'
            : null,
      );
      
      try {
        // Ne sauvegarder en cache que si le contrat n'est PAS en cours
        if (!isContratEnCours) {
          await File(pdfPath).copy(localPdfPath);
          print(' PDF sauvegardé en cache local: $localPdfPath');
        } else {
          print(' Contrat en cours - PDF non sauvegardé en cache');
        }
      } catch (e) {
        print(' Erreur lors de la sauvegarde du PDF en cache local: $e');
      }

      if (dialogShown && context.mounted) {
        Navigator.pop(context);
        dialogShown = false;
      }

      // Ouvrir le PDF uniquement si afficherPdf est true
      if (afficherPdf) {
        await OpenFilex.open(pdfPath);
      }

    } catch (e) {
      print(' Erreur lors de la génération du PDF : $e');
      
      if (dialogShown && context.mounted) {
        Navigator.pop(context);
        dialogShown = false;
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la génération du PDF : $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Vide le cache des PDF de contrats
  static Future<void> viderCachePdf(BuildContext context) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final directory = Directory(appDir.path);
      
      // Lister tous les fichiers du répertoire
      final files = directory.listSync();
      
      // Filtrer pour ne garder que les fichiers PDF
      final pdfFiles = files.where((file) => 
        file.path.toLowerCase().endsWith('.pdf') && 
        file.path.contains('contrat_')
      );
      
      // Supprimer chaque fichier PDF
      for (var file in pdfFiles) {
        await File(file.path).delete();
        print('Suppression du fichier caché: ${file.path}');
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cache des PDF vidé avec succès'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Erreur lors de la suppression du cache: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du vidage du cache: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
