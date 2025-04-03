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
    bool dialogShown = false;
    
    // Afficher un dialogue de chargement
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
        
        // Fonction pour convertir en double
        double parseDouble(dynamic value) {
          if (value == null) return 0.0;
          if (value is num) return value.toDouble();
          if (value is String) {
            try {
              return double.parse(value.replaceAll(',', '.'));
            } catch (e) {
              return 0.0;
            }
          }
          return 0.0;
        }
        
        // Vérifier si les données de facture sont stockées dans un objet 'facture'
        if (contratDataComplete.containsKey('facture') && contratDataComplete['facture'] is Map) {
          // Utiliser directement l'objet facture
          Map<String, dynamic> factureObj = contratDataComplete['facture'] as Map<String, dynamic>;
          factureData = factureObj;
          print('Données de facture récupérées depuis l\'objet facture: $factureData');
        } else {
          // Préparer les données de la facture à partir des champs directs
          // Essayer d'abord de récupérer les données avec le préfixe 'facture'
          factureData = {
            'facturePrixLocation': parseDouble(contratDataComplete['facturePrixLocation']),
            'factureCaution': parseDouble(contratDataComplete['factureCaution']),
            'factureFraisNettoyageInterieur': parseDouble(contratDataComplete['factureFraisNettoyageInterieur']),
            'factureFraisNettoyageExterieur': parseDouble(contratDataComplete['factureFraisNettoyageExterieur']),
            'factureFraisCarburantManquant': parseDouble(contratDataComplete['factureFraisCarburantManquant']),
            'factureFraisRayuresDommages': parseDouble(contratDataComplete['factureFraisRayuresDommages']),
            'factureFraisAutre': parseDouble(contratDataComplete['factureFraisAutre']),
            'factureFraisKilometrique': parseDouble(contratDataComplete['factureFraisKilometrique']),
            'factureRemise': parseDouble(contratDataComplete['factureRemise']),
            'factureTotalFrais': parseDouble(contratDataComplete['factureTotalFrais']),
            'factureTypePaiement': contratDataComplete['factureTypePaiement'] ?? 'Carte bancaire',
            'dateFacture': contratDataComplete['dateFacture'] ?? Timestamp.now(),
          };
          print('Données de facture récupérées depuis les champs directs: $factureData');
        }
        
        // Vérifier si les données de facture sont disponibles
        bool factureDataExist = false;
        try {
          // Convertir les valeurs en nombres si nécessaire pour la comparaison
          double prixLocation = parseDouble(factureData['facturePrixLocation']);
          double fraisKilometrique = parseDouble(factureData['factureFraisKilometrique']);
          double fraisNettoyageInt = parseDouble(factureData['factureFraisNettoyageInterieur']);
          
          factureDataExist = prixLocation > 0 || fraisKilometrique > 0 || fraisNettoyageInt > 0;
        } catch (e) {
          print('Erreur lors de la vérification des données de facture: $e');
          // Si une erreur se produit, considérer que les données existent pour continuer
          factureDataExist = true;
        }
        
        // Si aucune facture n'a été créée, afficher une facture vide
        if (!factureDataExist) {
          // Afficher un message à l'utilisateur
          if (dialogShown && context.mounted) {
            Navigator.pop(context);
          }
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Aucune facture n'a été créée pour ce contrat. Veuillez d'abord créer une facture."),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 3),
              ),
            );
          }
          return;
        }
      }

      // Récupérer les informations de l'entreprise
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>? ?? {};
      
      // Utiliser les données du contrat en priorité, puis celles de l'utilisateur si non disponibles
      String logoUrl = (contratData['logoUrl'] ?? userData['logoUrl'] ?? '').toString();
      String nomEntreprise = (contratData['nomEntreprise'] ?? userData['nomEntreprise'] ?? 'Mon Entreprise').toString();
      String adresse = (contratData['adresseEntreprise'] ?? userData['adresse'] ?? '').toString();
      String telephone = (contratData['telephoneEntreprise'] ?? userData['telephone'] ?? '').toString();
      String siret = (contratData['siretEntreprise'] ?? userData['siret'] ?? '').toString();

      // Vérifier si le prix est TTC ou HT
      bool isTTC = true; // Par défaut, on affiche les prix TTC
      if (factureData.containsKey('factureTTC')) {
        isTTC = factureData['factureTTC'] ?? true;
      }

      // Générer le PDF de facture
      final pdfPath = await FacturePdfGenerator.generateFacturePdf(
        data: contratData,
        factureData: factureData,
        logoUrl: logoUrl,
        nomEntreprise: nomEntreprise,
        adresse: adresse,
        telephone: telephone,
        siret: siret,
        isTTC: isTTC, // Passer le paramètre isTTC
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
