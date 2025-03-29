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
    required String immatriculation,
    required BuildContext context,
    String? prenom,
    String? nom,
    String? nomEntreprise,
    String? adresse,
    String? telephone,
    String? logoUrl,
    bool sendCopyToAdmin = true,
  }) async {
    try {
      // Récupérer les données de l'utilisateur
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Utilisateur non connecté');
      }
      
      // Vérifier si l'utilisateur est un collaborateur
      String targetUserId = user.uid;
      bool isCollaborateur = false;
      String? adminEmail;
      
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        
        if (userDoc.exists && userDoc.data()?['role'] == 'collaborateur') {
          isCollaborateur = true;
          final adminId = userDoc.data()?['adminId'];
          if (adminId != null) {
            print('👥 Collaborateur détecté, utilisation des données de l\'administrateur: $adminId');
            targetUserId = adminId;
            
            // Récupérer l'email de l'administrateur
            if (sendCopyToAdmin) {
              try {
                final adminUserDoc = await FirebaseFirestore.instance
                    .collection('users')
                    .doc(adminId)
                    .get();
                adminEmail = adminUserDoc.data()?['email'];
                print('📧 Email administrateur récupéré: $adminEmail');
              } catch (e) {
                print('❌ Erreur lors de la récupération de l\'email administrateur: $e');
              }
            }
          }
        } else if (sendCopyToAdmin) {
          // Si c'est l'admin lui-même, utiliser son propre email
          adminEmail = userDoc.data()?['email'] ?? user.email;
          print('📧 Email administrateur (utilisateur actuel): $adminEmail');
          
          // Si toujours null, utiliser l'email de l'utilisateur Firebase
          if (adminEmail == null && user.email != null) {
            adminEmail = user.email;
            print('📧 Utilisation de l\'email Firebase comme fallback: $adminEmail');
          }
        }
      } catch (e) {
        print('❌ Erreur lors de la vérification du rôle: $e');
        // Continuer avec l'ID de l'utilisateur actuel
        
        // Tenter d'utiliser l'email Firebase comme fallback
        if (sendCopyToAdmin && user.email != null) {
          adminEmail = user.email;
          print('📧 Utilisation de l\'email Firebase comme fallback après erreur: $adminEmail');
        }
      }

      // Essayer d'abord de récupérer depuis le cache pour éviter les erreurs de permission
      try {
        final userData = await FirebaseFirestore.instance
            .collection('users')
            .doc(targetUserId)
            .collection('authentification')
            .doc(targetUserId)
            .get(GetOptions(source: Source.cache));

        if (userData.exists) {
          nomEntreprise = userData.data()?['nomEntreprise'] ?? 'Contraloc';
          adresse = userData.data()?['adresse'] ?? '';
          telephone = userData.data()?['telephone'] ?? '';
          logoUrl = userData.data()?['logoUrl'];
          print('📋 Données entreprise récupérées depuis le cache');
        } else if (!isCollaborateur) {
          // Si les données ne sont pas dans le cache et que l'utilisateur n'est pas un collaborateur,
          // essayer de récupérer depuis le serveur
          final serverData = await FirebaseFirestore.instance
              .collection('users')
              .doc(targetUserId)
              .collection('authentification')
              .doc(targetUserId)
              .get();
              
          if (serverData.exists) {
            nomEntreprise = serverData.data()?['nomEntreprise'] ?? 'Contraloc';
            adresse = serverData.data()?['adresse'] ?? '';
            telephone = serverData.data()?['telephone'] ?? '';
            logoUrl = serverData.data()?['logoUrl'];
            print('🔄 Données entreprise récupérées depuis le serveur');
          }
        } else {
          // Pour les collaborateurs qui n'ont pas accès au cache, utiliser des valeurs par défaut
          print('👥 Collaborateur sans accès au cache, utilisation des valeurs par défaut');
          nomEntreprise = nomEntreprise ?? 'Contraloc';
        }
      } catch (e) {
        print('❌ Erreur récupération données entreprise: $e');
        // En cas d'erreur, utiliser des valeurs par défaut
        nomEntreprise = nomEntreprise ?? 'Contraloc';
      }

      // Récupérer les paramètres SMTP depuis admin/smtpSettings
      DocumentSnapshot adminDoc;
      try {
        // Essayer d'abord depuis le cache
        adminDoc = await FirebaseFirestore.instance
            .collection('admin')
            .doc('smtpSettings')
            .get(GetOptions(source: Source.cache));
            
        if (!adminDoc.exists) {
          // Si pas dans le cache, essayer depuis le serveur
          adminDoc = await FirebaseFirestore.instance
              .collection('admin')
              .doc('smtpSettings')
              .get();
        }
      } catch (e) {
        print('❌ Erreur récupération paramètres SMTP: $e');
        throw Exception('Configuration SMTP non accessible: $e');
      }

      if (!adminDoc.exists) {
        throw Exception('Configuration SMTP non trouvée');
      }

      final smtpData = adminDoc.data() as Map<String, dynamic>;
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

      print('Tentative d\'envoi depuis $smtpEmail via $smtpServer:$smtpPort');
      final message = Message()
        ..from = Address(smtpEmail, nomEntreprise ?? 'Contraloc')
        ..recipients.add(email)
        ..subject = '🚗 Votre contrat de location $marque $modele $immatriculation'
        ..headers = {
          'Message-ID':
              '<${DateTime.now().millisecondsSinceEpoch}@contraloc.fr>',
          'X-Mailer': 'Contraloc Mailer',
          'Return-Path': '<$smtpEmail>',
          'List-Unsubscribe': '<mailto:$smtpEmail>',
          'Feedback-ID': 'contraloc:${DateTime.now().millisecondsSinceEpoch}'
        }
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

      // Envoyer une copie à l'administrateur si demandé et si l'email est disponible
      if (sendCopyToAdmin && adminEmail != null && adminEmail != email) {
        print('📨 Tentative d\'envoi d\'une copie à l\'administrateur: $adminEmail');
        try {
          final adminMessage = Message()
            ..from = Address(smtpEmail, nomEntreprise ?? 'Contraloc')
            ..recipients.add(adminEmail)
            ..subject = '[COPIE] Contrat de location $marque $modele $immatriculation pour $prenom $nom'
            ..headers = {
              'Message-ID':
                  '<${DateTime.now().millisecondsSinceEpoch + 1}@contraloc.fr>',
              'X-Mailer': 'Contraloc Mailer',
              'Return-Path': '<$smtpEmail>',
              'List-Unsubscribe': '<mailto:$smtpEmail>',
              'Feedback-ID': 'contraloc:${DateTime.now().millisecondsSinceEpoch + 1}'
            }
            ..html = '''
              <div style="font-family: Arial, sans-serif; font-size: 14px; color: #333; line-height: 1.6;">
                <div style="background-color: #08004D; color: white; padding: 20px; text-align: center; border-radius: 10px 10px 0 0;">
                  <h1 style="margin: 0; font-size: 24px; color: #FFFFFF;">${nomEntreprise ?? "Contraloc"} - Copie de contrat</h1>
                </div>

                <div style="padding: 20px; background-color: #EFEFEF; border-radius: 0 0 10px 10px;">
                  <p>Bonjour,</p>
                  
                  <p>Voici une copie du contrat de location qui a été envoyé à <strong>$prenom $nom</strong> pour le véhicule <strong>$marque $modele $immatriculation</strong>. 📝</p>
                  
                  <p>Ce message est une copie automatique envoyée à l'administrateur pour archivage.</p>

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

          await send(adminMessage, server);
          print('Copie du contrat envoyée à l\'administrateur: $adminEmail');
        } catch (e) {
          print('Erreur lors de l\'envoi de la copie à l\'administrateur: $e');
          // Ne pas bloquer le processus si l'envoi de la copie échoue
        }
      }

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
