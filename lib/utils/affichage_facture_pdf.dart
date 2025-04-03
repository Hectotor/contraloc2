import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:open_filex/open_filex.dart';
import 'package:ContraLoc/widget/chargement.dart';
import 'facture_pdf.dart';

class AffichageFacturePdf {
  /// Génère et affiche une facture PDF basée sur les données du contrat
  /// 
  /// Cette méthode récupère les informations de l'entreprise depuis Firestore,
  /// génère un PDF de facture et l'ouvre avec le visualiseur par défaut du système.
  static Future<void> genererEtAfficherFacturePdf({
    required BuildContext context,
    required Map<String, dynamic> contratData,
    required String contratId,
    Map<String, dynamic>? factureData,
  }) async {
    // Afficher un dialogue de chargement
    bool dialogShown = false;
    if (context.mounted) {
      dialogShown = true;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Chargement(
            message: "Préparation de la facture...",
          );
        },
      );
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // Fermer le dialogue de chargement
      if (dialogShown && context.mounted) {
        Navigator.pop(context);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Utilisateur non connecté")),
      );
      return;
    }

    try {
      // Récupérer les informations de l'entreprise depuis Firestore
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      // Récupérer les données du contrat si nécessaire
      if (factureData == null) {
        DocumentSnapshot contratDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('locations')
            .doc(contratId)
            .get();

        Map<String, dynamic> contratDataComplete = contratDoc.data() as Map<String, dynamic>? ?? {};
        
        // Préparer les données de la facture à partir des données du contrat
        factureData = {
          'facturePrixLocation': contratDataComplete['prixLocation'] ?? 0,
          'factureCaution': contratDataComplete['caution'] ?? 0,
          'factureFraisNettoyageInterieur': contratDataComplete['nettoyageInt'] ?? 0,
          'factureFraisNettoyageExterieur': contratDataComplete['nettoyageExt'] ?? 0,
          'factureFraisCarburantManquant': contratDataComplete['fraisCarburantManquant'] ?? 0,
          'factureFraisRayuresDommages': contratDataComplete['fraisRayuresDommages'] ?? 0,
          'factureFraisAutre': contratDataComplete['fraisAutre'] ?? 0,
          'factureRemise': contratDataComplete['remise'] ?? 0,
          'factureTotalFrais': contratDataComplete['totalFrais'] ?? 0,
          'factureTypePaiement': contratDataComplete['typePaiement'] ?? 'Carte bancaire',
          'dateFacture': Timestamp.now(),
        };
      }

      // Récupérer les informations de l'entreprise
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>? ?? {};
      String logoUrl = (userData['logoUrl'] ?? '').toString();
      String nomEntreprise = (userData['nomEntreprise'] ?? 'Mon Entreprise').toString();
      String adresse = (userData['adresse'] ?? '').toString();
      String telephone = (userData['telephone'] ?? '').toString();
      String siret = (userData['siret'] ?? '').toString();
      String? iban = userData['iban'];
      String? bic = userData['bic'];

      // Générer le PDF de facture
      final pdfPath = await FacturePdfGenerator.generateFacturePdf(
        data: contratData,
        factureData: factureData,
        logoUrl: logoUrl,
        nomEntreprise: nomEntreprise,
        adresse: adresse,
        telephone: telephone,
        siret: siret,
        iban: iban,
        bic: bic,
      );

      // Fermer le dialogue de chargement
      if (dialogShown && context.mounted) {
        Navigator.pop(context);
        dialogShown = false;
      }

      // Ouvrir le PDF
      await OpenFilex.open(pdfPath);

    } catch (e) {
      print('Erreur lors de la génération du PDF de facture : $e');
      
      // Fermer le dialogue de chargement en cas d'erreur
      if (dialogShown && context.mounted) {
        Navigator.pop(context);
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la génération de la facture: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
