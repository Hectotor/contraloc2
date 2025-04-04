import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import '../USERS/contrat_condition.dart';
import '../services/collaborateur_util.dart';
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
        
        await OpenFilex.open(localPdfPath);
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

      final pdfPath = await generatePdf(
        {
          ...data,
          'nettoyageInt': nettoyageIntController.text,
          'nettoyageExt': nettoyageExtController.text,
          'pourcentageEssenceRetour': pourcentageEssenceRetourController.text,
          'caution': cautionController.text,
          'signatureRetour': signatureRetourBase64 != null && signatureRetourBase64.isNotEmpty ? signatureRetourBase64 : null,
          'conditions': conditions,
          'contratId': contratId,
        },
        data['dateFinEffectif'] ?? '',
        data['kilometrageRetour'] ?? '',
        data['commentaireRetour'] ?? '',
        [],  // photosRetour
        data['nomEntreprise'] ?? userData['nomEntreprise'] ?? '',
        data['logoUrl'] ?? userData['logoUrl'] ?? '',
        data['adresseEntreprise'] ?? userData['adresse'] ?? '',
        data['telephoneEntreprise'] ?? userData['telephone'] ?? '',
        data['siretEntreprise'] ?? userData['siret'] ?? '',
        data['commentaireRetour'] ?? '',
        data['typeCarburant'] ?? '',
        data['boiteVitesses'] ?? '',
        data['vin'] ?? '',
        data['assuranceNom'] ?? '',
        data['assuranceNumero'] ?? '',
        data['franchise'] ?? '',
        data['kilometrageSupp'] ?? '',
        data['rayures'] ?? '',
        data['dateDebut'] ?? '',
        data['dateFinTheorique'] ?? '',
        data['dateFinEffectif'] ?? '',
        data['kilometrageDepart'] ?? '',
        data['kilometrageAutorise'] ?? '',
        (data['pourcentageEssence'] ?? '').toString(),
        data['typeLocation'] ?? '',
        data['prixLocation'] ?? '',
        data['accompte'] ?? '',
        condition: conditions,
        signatureBase64: '',
        signatureRetourBase64: signatureRetourBase64 != null && signatureRetourBase64.isNotEmpty ? signatureRetourBase64 : null,
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

      await OpenFilex.open(pdfPath);

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
