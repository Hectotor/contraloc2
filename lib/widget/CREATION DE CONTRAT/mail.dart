import 'dart:io';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

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
    String? adresse, // Adresse de l'entreprise
    String? telephone, // Numéro de téléphone
    String? logoUrl, // URL du logo
  }) async {
    try {
      // Récupérer les paramètres SMTP depuis Firestore
      final adminDoc = await FirebaseFirestore.instance
          .collection('admin')
          .doc('smtpSettings')
          .get();

      final adminData = adminDoc.data() ?? {};
      final smtpEmail = adminData['smtpEmail'] ?? 'contact@contraloc.fr';
      final smtpPassword = adminData['smtpPassword'] ?? '';
      final smtpServer = adminData['smtpServer'] ?? 'contraloc.fr';
      final smtpPort = 465; // Port SMTP pour SSL

      if (smtpEmail.isEmpty || smtpPassword.isEmpty || smtpServer.isEmpty) {
        throw Exception('Configuration SMTP manquante');
      }

      // Vérifier l'existence du fichier PDF
      if (!File(pdfPath).existsSync()) {
        throw Exception('Le fichier PDF est introuvable');
      }

      // Configurer le serveur SMTP
      final server = SmtpServer(
        smtpServer,
        port: smtpPort,
        username: smtpEmail,
        password: smtpPassword,
        ssl: true, // SSL activé pour le port 465
      );

      // Créer le message e-mail avec contenu HTML
      final message = Message()
        ..from = Address(smtpEmail,
            nomEntreprise ?? 'Contraloc') // Utiliser l'email de l'admin
        ..recipients.add(email)
        ..subject = 'Votre contrat de location $marque $modele'
        ..html = '''
          <div style="font-family: Arial, sans-serif; font-size: 14px; color: #333;">
            <p>${prenom != null && nom != null ? "Bonjour $prenom $nom," : "Bonjour,"}</p>
            
            <p>
              Nous avons le plaisir de vous transmettre, en pièce jointe, votre contrat de location.<br>
              Ce document contient toutes les informations nécessaires relatives à votre accord de location, y compris les détails concernant le véhicule, les modalités de la location et les conditions générales.
            </p>
            
            <p>Nous restons à votre disposition pour toute assistance supplémentaire.</p>
            
            <br>
            <div style="display: flex; align-items: center; text-align: left;">
              ${logoUrl != null ? '<img src="$logoUrl" alt="Logo" style="width: 150px; height: auto; margin-right: 15px;" />' : ''}
              <div>
                <p style="margin: 0; font-weight: bold; font-size: 16px;">${nomEntreprise ?? "Contraloc"}</p>
                ${adresse != null ? '<p style="margin: 0;">$adresse</p>' : ''}
                ${telephone != null ? '<p style="margin: 0;">$telephone</p>' : ''}
              </div>
            </div>
          </div>
        '''
        ..attachments.add(FileAttachment(File(pdfPath)));

      // Envoyer l'email
      final sendReport = await send(message, server);
      print('Rapport d\'envoi : ${sendReport.toString()}');

      // Afficher un message de succès
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
