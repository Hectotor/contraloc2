import 'dart:io';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EmailService {
  static Future<void> sendEmailWithPdf({
    required String pdfPath,
    required String email,
    required String marque,
    required String modele,
    required BuildContext context,
    String? prenom,
    String? nom,
    String? nomEntreprise,
    String? adresse,
    String? telephone,
    String? logoUrl,
  }) async {
    try {
      // Récupérer les données de l'utilisateur
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userData = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('authentification')
            .doc(user.uid)
            .get();

        if (userData.exists) {
          nomEntreprise = userData.data()?['nomEntreprise'] ?? 'Contraloc';
          adresse = userData.data()?['adresse'] ?? '';
          telephone = userData.data()?['telephone'] ?? '';
          logoUrl = userData.data()?['logoUrl'];
        }
      }

      // Récupérer les paramètres SMTP depuis admin/smtpSettings
      final adminDoc = await FirebaseFirestore.instance
          .collection('admin')
          .doc('smtpSettings')
          .get();

      if (!adminDoc.exists) {
        throw Exception('Configuration SMTP non trouvée');
      }

      final smtpData = adminDoc.data() ?? {};
      final smtpEmail = smtpData['smtpEmail'] ?? '';
      final smtpPassword = smtpData['smtpPassword'] ?? '';
      final smtpServer = smtpData['smtpServer'] ?? '';
      final smtpPort = smtpData['smtpPort'] ?? 465;

      if (smtpEmail.isEmpty || smtpPassword.isEmpty || smtpServer.isEmpty) {
        throw Exception('Configuration SMTP incomplète');
      }

      // Vérifier que le fichier PDF existe
      if (!File(pdfPath).existsSync()) {
        throw Exception('Le fichier PDF est introuvable');
      }

      final server = SmtpServer(
        smtpServer,
        port: smtpPort,
        username: smtpEmail,
        password: smtpPassword,
        ssl: true,
      );

      final message = Message()
        ..from = Address(smtpEmail, nomEntreprise ?? 'Contraloc')
        ..recipients.add(email)
        ..subject = '🚗 Votre contrat de location $marque $modele'
        ..html = '''
          <div style="font-family: Arial, sans-serif; font-size: 14px; color: #333; line-height: 1.6;">
            <div style="background-color: #08004D; color: white; padding: 20px; text-align: center; border-radius: 10px 10px 0 0;">
              <h1 style="margin: 0; font-size: 24px; color: #FFFFFF;">${nomEntreprise ?? "Contraloc"}</h1>
            </div>

            <div style="padding: 20px; background-color: #EFEFEF; border-radius: 0 0 10px 10px;">
              <p>${prenom != null && nom != null ? "Bonjour <strong>$prenom $nom</strong>," : "Bonjour,"}</p>
              
              <p>Nous avons le plaisir de vous transmettre votre contrat de location signé en pièce jointe. 📝</p>
              
              <p style="font-size: 16px; font-weight: bold;">
                Merci pour votre confiance et bonne route ! 🏎️🚗
              </p>

              <p style="font-size: 16px; font-weight: bold; color: #333;">
                ⚠️ L'utilisateur est totalement responsable des contraventions, amendes et procès-verbaux établis en violation du code de la route.
              </p>

              <p>Si vous pensez avoir reçu cet email par erreur merci de bien vouloir nous contacter au plus à l'adresse suivante : contact@contraloc.fr.</p>

              <p>À bientôt,</p>

              <br>
              <div style="display: flex; align-items: center;">
                ${logoUrl != null ? '<img src="$logoUrl" alt="Logo" style="width: 70px; height: auto; margin-right: 15px;" />' : ''}
                <div>
                  <p style="margin: 0; font-weight: bold; font-size: 16px; color: #08004D;">${nomEntreprise ?? "Contraloc"}</p>
                  ${adresse != null ? '<p style="margin: 0; color #555;">Adresse: $adresse</p>' : ''}
                  ${telephone != null ? '<p style="margin: 0; color: #555;">Téléphone : $telephone</p>' : ''}
                </div>
              </div>
              <p style="text-align: center; font-size: 12px; color: #777; margin-top: 20px;">contraloc.fr</p>
            </div>
          </div>
        '''
        ..attachments.add(FileAttachment(File(pdfPath)));

      final sendReport = await send(message, server);
      print('Rapport d\'envoi : ${sendReport.toString()}');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contrat envoyé par email avec succès')),
        );
      }
    } on SocketException catch (e) {
      print('Erreur réseau : $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Problème de connexion réseau')),
        );
      }
    } catch (e) {
      print('Erreur inconnue : $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l\'envoi de l\'email : $e')),
        );
      }
    }
  }
}
