import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WelcomeMail {
  static Future<void> sendWelcomeEmail({
    required String email,
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

      // Récupérer les paramètres SMTP depuis contactSettings
      final adminDoc = await FirebaseFirestore.instance
          .collection('contactSettings')
          .doc('smtpConfig')
          .get();

      if (!adminDoc.exists) {
        throw Exception('Configuration SMTP non trouvée');
      }

      final adminData = adminDoc.data() ?? {};
      final smtpEmail = adminData['smtpEmail'] ?? '';
      final smtpPassword = adminData['smtpPassword'] ?? '';
      final smtpServer = adminData['smtpServer'] ?? '';

      if (smtpEmail.isEmpty || smtpPassword.isEmpty || smtpServer.isEmpty) {
        throw Exception('Configuration SMTP incomplète');
      }

      final server = SmtpServer(
        'contraloc.fr',
        port: 465,
        username: 'contact@contraloc.fr',
        password: smtpPassword,
        ssl: true,
      );

      final message = Message()
        ..from = Address('contact@contraloc.fr', 'ContraLoc')
        ..recipients.add(email)
        ..subject = '📩 Bienvenue sur ContraLoc – Gérez vos locations en toute simplicité !'
        ..html = '''
          <div style="font-family: Arial, sans-serif; font-size: 14px; color: #333; line-height: 1.6;">
            <div style="background-color: #08004D; color: white; padding: 20px; text-align: center; border-radius: 10px 10px 0 0;">
              <h1 style="margin: 0; font-size: 24px; color: #FFFFFF;">${nomEntreprise ?? "Contraloc"}</h1>
            </div>

            <div style="padding: 20px; background-color: #EFEFEF; border-radius: 0 0 10px 10px;">
              <p>Bonjour <strong>$prenom $nom</strong>,</p>
              
              <p>Nous sommes ravis de vous accueillir sur <strong>ContraLoc</strong>, votre solution digitale dédiée à la gestion des <strong>véhicules de courtoisie</strong> et <strong>véhicules de location</strong> depuis <strong>2020</strong>.</p>
              
              <p>Depuis plus de 5 ans, nous accompagnons les professionnels avec une plateforme intuitive et sécurisée, et déjà <strong>plus de 8 000 contrats</strong> ont été générés avec succès !</p>
              
              <p>Avec <strong>ContraLoc</strong>, vous pouvez :</p>
              <ul style="list-style-type: none; padding-left: 0;">
                <li>🚗 <strong>Ajouter et gérer</strong> facilement votre flotte de véhicules</li>
                <li>✍️ <strong>Créer et signer</strong> vos contrats en ligne en quelques clics</li>
                <li>📊 <strong>Suivre vos locations</strong> en temps réel, sans paperasse ni stress</li>
                <li>👥 <strong>Ajouter des collaborateurs</strong> pour une gestion d'équipe optimisée</li>
              </ul>
              
              <p>Nous sommes à votre disposition pour vous accompagner et répondre à toutes vos questions.</p>
              
              <p>📞 <strong>Besoin d'aide ?</strong> Contactez-nous, nous serons ravis de vous assister !</p>
              
              <p>🚀 <strong>Bienvenue à bord de ContraLoc !</strong></p>
              
              <p>Et n'oubliez pas : Avec ContraLoc, plus besoin de passer la seconde… votre gestion de location est déjà sur les rails ! 🚗💨</p>
              
              <br>
              <div style="display: flex; align-items: center;">
                <div>
                  <p style="margin: 0; font-weight: bold;">L'équipe ContraLoc</p>
                  <p style="margin: 0;">+33 6 17 03 88 90</p>
                  <p style="margin: 0;">contact@contraloc.fr</p>
                </div>
              </div>
              <p style="text-align: center; font-size: 12px; color: #777; margin-top: 20px;">contraloc.fr</p>
            </div>
          </div>
        ''';

      final sendReport = await send(message, server);
      print('Rapport d\'envoi : ${sendReport.toString()}');

    } catch (e) {
      print('Erreur lors de l\'envoi de l\'email : $e');
    }       
  }
}
