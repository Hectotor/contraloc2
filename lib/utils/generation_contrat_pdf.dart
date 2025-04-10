import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/contrat_model.dart';
import '../widget/chargement.dart';
import '../utils/affichage_contrat_pdf.dart';
import '../widget/CREATION DE CONTRAT/mail.dart';
import '../widget/CREATION DE CONTRAT/popup_felicitation.dart';

class GenerationContratPdf {
  static Future<void> genererEtEnvoyerPdf({
    required BuildContext context,
    required String contratId,
    String? nom,
    String? prenom,
    String? adresse,
    String? telephone,
    String? email,
    String? signatureAller,
    String? signatureRetour,
    String? photoVehiculeRetourUrl,
    String? vin,
    required String typeCarburant,
    required String boiteVitesses,
    String? assuranceNom,
    String? assuranceNumero,
    String? franchise,
    String? prixLocation,
    String? accompte,
    String? nettoyageInt,
    String? nettoyageExt,
    String? methodePaiement,
    String? numeroPermis,
    String? immatriculationVehiculeClient,
    String? kilometrageVehiculeClient,
    String? permisRectoUrl,
    String? permisVersoUrl,
    String? photoVehiculeUrl,
    String? dateDebut,
    String? dateFinTheorique,
    String? kilometrageDepart,
    String? typeLocation,
    int? pourcentageEssence,
    String? commentaireAller,
    List<String>? photosUrls,
    String? caution,
    String? carburantManquant,
    String? prixRayures,
    String? kilometrageAutorise,
    String? kilometrageSupp,
    String? nomEntreprise,
    String? logoUrl,
    String? adresseEntreprise,
    String? telephoneEntreprise,
    String? siretEntreprise,
    String? nomCollaborateur,
    String? prenomCollaborateur,
    String? conditions,
    String? dateRetour,
    String? kilometrageRetour,
    String? marque,
    String? modele,
    String? immatriculation,
    String? pourcentageEssenceRetour,
    String? status,
    String? commentaireRetour,
    String? entrepriseClient,
    Timestamp? dateCreation,
  }) async {
    try {
      // Si les contrôleurs ne sont pas fournis, créer des instances par défaut
      // Récupérer les informations du loueur
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Utilisateur non connecté');
      }

      // Récupérer les données principales de l'utilisateur
      final userDataDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get(GetOptions(source: Source.server));

      if (!userDataDoc.exists) {
        throw Exception('❌ Données utilisateur non trouvées');
      }

      final userData = userDataDoc.data()!;
      final adminId = userData['adminId'];
      
      if (adminId == null) {
        throw Exception('❌ ID administrateur non trouvé');
      }

      // Utiliser l'adminId comme cible
      final targetId = adminId;

      // Récupérer les données de l'admin
      final adminData = await FirebaseFirestore.instance
          .collection('users')
          .doc(targetId)
          .get(GetOptions(source: Source.server));

      if (!adminData.exists) {
        throw Exception('❌ Données administrateur non trouvées');
      }

      // Logs détaillés pour comprendre les données brutes
      print('=== Données brutes de l\'admin ===');
      print('Document ID: ${adminData.id}');
      print('Données brutes: ${adminData.data()}');
      print('=== Fin des données brutes ===');

      final adminDataMap = adminData.data()!;
      final nomEntreprise = adminDataMap['nomEntreprise'] ?? 'Non défini';
      final logoUrl = adminDataMap['logoUrl'] ?? 'Non défini';
      final adresseEntreprise = adminDataMap['adresse'] ?? 'Non défini';
      final telephoneEntreprise = adminDataMap['telephone'] ?? 'Non défini';
      final siretEntreprise = adminDataMap['siret'] ?? 'Non défini';

      // Logs pour vérifier les données de l'entreprise
      print('=== Données entreprise ===');
      print('Nom: $nomEntreprise');
      print('Logo: $logoUrl');
      print('Adresse: $adresseEntreprise');
      print('Téléphone: $telephoneEntreprise');
      print('SIRET: $siretEntreprise');
      print('=== Fin des données entreprise ===');

      // Récupérer les informations du collaborateur
      final collaborateurData = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get(GetOptions(source: Source.server));

      final collaborateurDataMap = collaborateurData.data()!;
      final nomCollaborateur = collaborateurDataMap['nom'] ?? '';
      final prenomCollaborateur = collaborateurDataMap['prenom'] ?? '';

      // Fonction pour convertir la date française en format ISO
      DateTime parseFrenchDate(String dateStr) {
        // Extraire les composants de la date française
        final parts = dateStr.split(' ');
        
        // Les composants sont dans l'ordre: [jour, numéro, mois, année, à, heure]
        final day = parts[1];  // Le numéro du jour
        final month = parts[2]; // Le mois
        final year = parts[3];  // L'année
        final time = parts[5];  // L'heure
        
        // Tableau des mois en français
        final months = {
          'janvier': '01',
          'février': '02',
          'mars': '03',
          'avril': '04',
          'mai': '05',
          'juin': '06',
          'juillet': '07',
          'août': '08',
          'septembre': '09',
          'octobre': '10',
          'novembre': '11',
          'décembre': '12'
        };
        
        // Construire la date en format ISO
        final isoDate = '$year-${months[month]}-$day $time';
        
        // Logs de débogage
        print('=== Debug date parsing ===');
        print('Date brute: $dateStr');
        print('Jour: $day, Mois: $month, Année: $year, Heure: $time');
        print('Date ISO: $isoDate');
        
        return DateTime.parse(isoDate);
      }

      // Calculer le statut du contrat
      final now = DateTime.now();
      final dateDebutDateTime = dateDebut != null ? parseFrenchDate(dateDebut) : null;
      
      // Logs pour déboguer
      print('=== Calcul du statut ===');
      print('Date actuelle: $now');
      print('Date de début: $dateDebutDateTime');
      print('Différence en jours: ${dateDebutDateTime != null ? dateDebutDateTime.difference(now).inDays : null}');
      
      final status = dateDebutDateTime != null && dateDebutDateTime.difference(now).inDays > 1 
          ? 'réservé'  // Si la date est dans plus de 24h
          : 'en_cours'; // Sinon, en_cours

      // Créer le contratModel avec le statut calculé
      final contratModel = ContratModel(
        contratId: contratId,
        userId: user.uid,
        adminId: targetId,
        createdBy: user.uid,
        isCollaborateur: true,
        entrepriseClient: entrepriseClient,
        nom: nom,
        prenom: prenom,
        adresse: adresse,
        telephone: telephone,
        email: email,
        numeroPermis: numeroPermis,
        immatriculationVehiculeClient: immatriculationVehiculeClient,
        kilometrageVehiculeClient: kilometrageVehiculeClient,
        permisRectoUrl: permisRectoUrl,
        permisVersoUrl: permisVersoUrl,
        marque: marque,
        modele: modele,
        immatriculation: immatriculation,
        dateDebut: dateDebut,
        dateFinTheorique: dateFinTheorique,
        kilometrageDepart: kilometrageDepart,
        typeLocation: typeLocation,
        pourcentageEssence: pourcentageEssence ?? 50,
        commentaireAller: commentaireAller,
        photosUrls: photosUrls,
        signatureAller: signatureAller,
        vin: vin,
        typeCarburant: typeCarburant,
        boiteVitesses: boiteVitesses,
        assuranceNom: assuranceNom,
        assuranceNumero: assuranceNumero,
        franchise: franchise,
        prixLocation: prixLocation,
        accompte: accompte,
        caution: caution,
        nettoyageInt: nettoyageInt,
        nettoyageExt: nettoyageExt,
        methodePaiement: methodePaiement,
        nomEntreprise: nomEntreprise,
        logoUrl: logoUrl,
        adresseEntreprise: adresseEntreprise,
        telephoneEntreprise: telephoneEntreprise,
        siretEntreprise: siretEntreprise,
        nomCollaborateur: nomCollaborateur,
        prenomCollaborateur: prenomCollaborateur,
        conditions: conditions,
        dateRetour: dateRetour,
        commentaireRetour: commentaireRetour,
        signatureRetour: signatureRetour,
        kilometrageRetour: kilometrageRetour,
        pourcentageEssenceRetour: pourcentageEssenceRetour,
        status: status, // Utiliser le statut calculé
        dateCreation: Timestamp.now(),
      );

      // Vérifier si les données sont correctement passées au contratModel
      print('=== Vérification contratModel ===');
      print('nomEntreprise: ${contratModel.nomEntreprise}');
      print('logoUrl: ${contratModel.logoUrl}');
      print('adresseEntreprise: ${contratModel.adresseEntreprise}');
      print('telephoneEntreprise: ${contratModel.telephoneEntreprise}');
      print('siretEntreprise: ${contratModel.siretEntreprise}');
      print('nomCollaborateur: ${contratModel.nomCollaborateur}');
      print('prenomCollaborateur: ${contratModel.prenomCollaborateur}');
      print('conditions: ${contratModel.conditions}');
      print('=== Fin de la vérification contratModel ===');

      // Afficher le dialogue de chargement
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Chargement(message: 'Génération du contrat...');
        },
      );

      // Sauvegarder le contrat dans Firestore
      final contratData = contratModel.toFirestore();
      
      // Logs pour déboguer
      print('=== Début de la sauvegarde du contrat ===');
      print('User ID: ${user.uid}');
      print('Admin ID: $adminId');
      print('Target ID: $targetId');
      print('Contrat ID: $contratId');
      print('=== Données du contrat ===');
      print(contratData);
      print('=== Structure de sauvegarde ===');
      print('Collection: users/$targetId/locations/$contratId');
      print('=== Fin des logs ===');

      try {
        // Sauvegarder dans la collection locations de l'admin
        await FirebaseFirestore.instance
            .collection('users')
            .doc(targetId)
            .collection('locations')
            .doc(contratId)
            .set(contratData, SetOptions(merge: true));

        print('=== Sauvegarde réussie ===');
        print('Sauvegardé dans: users/$targetId/locations/$contratId');

      } catch (e) {
        print('=== Erreur lors de la sauvegarde ===');
        print('Erreur: $e');
        print('Type de l\'erreur: ${e.runtimeType}');
        print('Message: ${e.toString()}');
        throw Exception('❌ Erreur lors de la sauvegarde du contrat: $e');
      }

      // Si un email est fourni, envoyer le PDF
      if (email != null && email.isNotEmpty) {
        await EmailService.sendEmailWithPdf(
          pdfPath: await AffichageContratPdf.genererEtAfficherContratPdf(
            data: contratData,
            afficherPdf: false,
            contratId: contratId, 
            context: context,
          ),
          context: context,
          email: email,
          marque: marque ?? '',
          modele: modele ?? '',
          immatriculation: immatriculation ?? '',
          prenom: prenom ?? '',
          nom: nom ?? '',
          nomEntreprise: nomEntreprise ?? '',
          adresse: adresseEntreprise,
          telephone: telephoneEntreprise,
          logoUrl: logoUrl ?? '',
          sendCopyToAdmin: true,
          nomCollaborateur: nomCollaborateur,
          prenomCollaborateur: prenomCollaborateur,
        );
      }

      // Fermer le dialogue de chargement
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Afficher le popup de félicitation
      if (context.mounted) {
        await Popup.showSuccess(context, email: email);
      }

    } catch (e) {
      // Fermer le dialogue de chargement
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Afficher un message d'erreur
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la génération du contrat: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
