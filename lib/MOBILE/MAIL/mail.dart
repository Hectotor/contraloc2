import 'package:flutter/material.dart';
import 'email_service.dart';
import 'cloture_email_service.dart';

class Mail {
  static Future<void> sendEmailWithPdf({
    required String pdfPath,
    required String email,
    required String marque,
    required String modele,
    required String immatriculation,
    required BuildContext context,
    String? prenom,
    String? nom,
    String? nomEntreprise,
    String? adresse,
    String? telephone,
    String? logoUrl,
    bool sendCopyToAdmin = true,
    String? nomCollaborateur,
    String? prenomCollaborateur,
  }) async {
    // Appel à la méthode dans la nouvelle classe ContractEmailService
    await ContractEmailService.sendEmailWithPdf(
      pdfPath: pdfPath,
      email: email,
      marque: marque,
      modele: modele,
      immatriculation: immatriculation,
      context: context,
      prenom: prenom,
      nom: nom,
      nomEntreprise: nomEntreprise,
      adresse: adresse,
      telephone: telephone,
      logoUrl: logoUrl,
      sendCopyToAdmin: sendCopyToAdmin,
      nomCollaborateur: nomCollaborateur,
      prenomCollaborateur: prenomCollaborateur,
    );
  }

  static Future<void> sendClotureEmailWithPdf({
    required String pdfPath,
    required String email,
    required String marque,
    required String modele,
    required String immatriculation,
    required String kilometrageRetour,
    required String dateFinEffectif,
    required String commentaireRetour,
    required BuildContext context,
    String? prenom,
    String? nom,
    String? nomEntreprise,
    String? adresse,
    String? telephone,
    String? logoUrl,
    bool sendCopyToAdmin = true,
    String? nomCollaborateur,
    String? prenomCollaborateur,
  }) async {
    // Appel à la méthode dans la nouvelle classe ClotureEmailService
    await ClotureEmailService.sendClotureEmailWithPdf(
      pdfPath: pdfPath,
      email: email,
      marque: marque,
      modele: modele,
      immatriculation: immatriculation,
      kilometrageRetour: kilometrageRetour,
      dateFinEffectif: dateFinEffectif,
      commentaireRetour: commentaireRetour,
      context: context,
      prenom: prenom,
      nom: nom,
      nomEntreprise: nomEntreprise,
      adresse: adresse,
      telephone: telephone,
      logoUrl: logoUrl,
      sendCopyToAdmin: sendCopyToAdmin,
      nomCollaborateur: nomCollaborateur,
      prenomCollaborateur: prenomCollaborateur,
    );
  }
}
