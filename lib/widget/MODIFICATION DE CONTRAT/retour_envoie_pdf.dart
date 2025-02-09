import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/pdf.dart';
import '../CREATION DE CONTRAT/mail.dart';
import '../MES CONTRATS/contrat_condition.dart';

class RetourEnvoiePdf {
  static Future<void> genererEtEnvoyerPdfCloture({
    required BuildContext context,
    required Map<String, dynamic> contratData,
    required String contratId,
    required String dateFinEffectif,
    required String kilometrageRetour,
    required String commentaireRetour,
    required List<File> photosRetour,
    String? signatureRetourBase64,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Utilisateur non connecté")),
      );
      return;
    }

    try {
      // Récupérer les informations du client
      DocumentSnapshot clientDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('authentification')
          .doc(user.uid)
          .get();

      // Récupérer la signature du contrat
      DocumentSnapshot contratDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('locations')
          .doc(contratId)
          .get();

      // Utiliser des valeurs par défaut sécurisées
      Map<String, dynamic> clientData = clientDoc.data() as Map<String, dynamic>? ?? {};
      Map<String, dynamic> contratDataComplete = contratDoc.data() as Map<String, dynamic>? ?? {};

      String? clientEmail = clientData['email'] as String?;
      clientEmail ??= '';
      String nomEntreprise = (clientData['nomEntreprise'] ?? 'Contraloc').toString();
      String adresse = (clientData['adresse'] ?? '').toString();
      String telephone = (clientData['telephone'] ?? '').toString();
      String logoUrl = (clientData['logoUrl'] ?? '').toString();
      String siret = (clientData['siret'] ?? '').toString();
      
      // Récupérer la signature
      String? signatureBase64;
      if (contratDataComplete.containsKey('signature') && 
          contratDataComplete['signature'] is Map) {
        signatureBase64 = contratDataComplete['signature']['base64'];
      }

      // Log pour le débogage
      print('Signature récupérée : ${signatureBase64 != null ? 'Présente' : 'Absente'}');

      // Récupérer la signature aller
      String? signatureAllerBase64;
      
      // Essayer de récupérer la signature aller
      if (contratData.containsKey('signature_aller') && 
          contratData['signature_aller'] is String) {
        signatureAllerBase64 = contratData['signature_aller'];
      } else if (contratData.containsKey('signature') && 
                 contratData['signature'] is Map && 
                 contratData['signature']['base64'] is String) {
        signatureAllerBase64 = contratData['signature']['base64'];
      }

      // Fallback sur signatureBase64
      signatureAllerBase64 ??= signatureBase64;

      // FORCER signatureBase64
      signatureBase64 = signatureAllerBase64;

      print('📝 Signature aller récupérée : ${signatureAllerBase64 != null ? 'Présente (${signatureAllerBase64.length} caractères)' : 'Absente'}');

      // Utiliser la signature de retour si fournie
      signatureRetourBase64 ??= contratData['signature_retour'];

      print('📝 Signature retour : ${signatureRetourBase64 != null ? 'Présente (${signatureRetourBase64.length} caractères)' : 'Absente'}');

      // Récupérer les données du véhicule
      final vehicleDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('vehicules')
          .where('immatriculation', isEqualTo: contratData['immatriculation'])
          .get();

      final vehicleData = vehicleDoc.docs.isNotEmpty 
          ? vehicleDoc.docs.first.data() 
          : {};

      // Générer le PDF de clôture
      final pdfPath = await generatePdf(
        {
          'nom': (contratData['nom'] ?? '').toString(),
          'prenom': (contratData['prenom'] ?? '').toString(),
          'adresse': (contratData['adresse'] ?? '').toString(),
          'telephone': (contratData['telephone'] ?? '').toString(),
          'email': (contratData['email'] ?? '').toString(),
          'numeroPermis': (contratData['numeroPermis'] ?? '').toString(),
          'marque': (contratData['marque'] ?? '').toString(),
          'modele': (contratData['modele'] ?? '').toString(),
          'immatriculation': (contratData['immatriculation'] ?? '').toString(),
          'commentaire': (contratData['commentaire'] ?? '').toString(),
          'photos': contratData['photos'] ?? [],
          'signatureAller': signatureAllerBase64,
          'signatureBase64': signatureBase64,
          'signatureRetour': signatureRetourBase64,
          
          // Nouveaux champs ajoutés
          'nettoyageInt': (contratData['nettoyageInt'] ?? '').toString(),
          'nettoyageExt': (contratData['nettoyageExt'] ?? '').toString(),
          'carburantManquant': (contratData['carburantManquant'] ?? '').toString(),
          'caution': (contratData['caution'] ?? '').toString(),
          
          // Champs supplémentaires
          'pourcentageEssence': (contratData['pourcentageEssence'] ?? '0').toString(),
          'typeLocation': (contratData['typeLocation'] ?? '').toString(),
          'conditions': (contratData['conditions'] ?? ContratModifier.defaultContract).toString(),
        },
        dateFinEffectif,
        kilometrageRetour,
        commentaireRetour,
        photosRetour,
        nomEntreprise,
        logoUrl,
        adresse,
        telephone,
        siret,
        commentaireRetour,
        (vehicleData['typeCarburant'] ?? contratData['typeCarburant'] ?? '').toString(),
        (vehicleData['boiteVitesses'] ?? contratData['boiteVitesses'] ?? '').toString(),
        (vehicleData['vin'] ?? contratData['vin'] ?? '').toString(),
        (vehicleData['assuranceNom'] ?? contratData['assuranceNom'] ?? '').toString(),
        (vehicleData['assuranceNumero'] ?? contratData['assuranceNumero'] ?? '').toString(),
        (vehicleData['franchise'] ?? contratData['franchise'] ?? '').toString(),
        (vehicleData['kilometrageSupp'] ?? contratData['kilometrageSupp'] ?? '').toString(),
        (vehicleData['rayures'] ?? contratData['rayures'] ?? '').toString(),
        (contratData['dateDebut'] ?? '').toString(),
        (contratData['dateFinTheorique'] ?? '').toString(),
        dateFinEffectif,
        (contratData['kilometrageDepart'] ?? '').toString(),
        (contratData['pourcentageEssence'] ?? '0').toString(),
        (contratData['typeLocation'] ?? '').toString(),
        (vehicleData['prixLocation'] ?? contratData['prixLocation'] ?? '').toString(),
        condition: (contratData['conditions'] ?? ContratModifier.defaultContract).toString(),
        signatureBase64: signatureBase64,
        signatureRetourBase64: signatureRetourBase64,
      );

      // Vérifier si un email est disponible avant d'envoyer
      if ((contratData['email'] ?? '').toString().isEmpty) {
        throw Exception("Aucun email client n'a été trouvé");
      }

      // Envoyer le PDF par email
      await EmailService.sendEmailWithPdf(
        pdfPath: pdfPath,
        email: (contratData['email'] ?? '').toString(),
        marque: (contratData['marque'] ?? '').toString(),
        modele: (contratData['modele'] ?? '').toString(),
        context: context,
        prenom: (contratData['prenom'] ?? '').toString(),
        nom: (contratData['nom'] ?? '').toString(),
        nomEntreprise: nomEntreprise,
        adresse: adresse,
        telephone: telephone,
        logoUrl: logoUrl,
      );

      // Mise à jour du statut du contrat
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('locations')
          .doc(contratId)
          .update({
        'status': 'restitue',
        'dateRestitution': FieldValue.serverTimestamp(),
        'pdfClotureSent': true,
      });

      // Afficher un message de succès
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Contrat clôturé et PDF envoyé avec succès !"),
          backgroundColor: Colors.green,
        ),
      );

    } catch (e) {
      // Gestion des erreurs
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur lors de l'envoi du PDF : $e"),
          backgroundColor: Colors.red,
        ),
      );
      
      // Log de l'erreur pour le débogage
      print("Erreur détaillée : $e");
    }
  }
}
