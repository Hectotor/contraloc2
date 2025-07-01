import 'dart:io';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ContractEmailService {
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
    try {
      // Récupérer les données de l'utilisateur
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Utilisateur non connecté');
      }
      
      // Vérifier si l'utilisateur est un collaborateur
      String? adminEmail;
      
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        
        if (userDoc.exists && userDoc.data()?['role'] == 'collaborateur') {
          final adminId = userDoc.data()?['adminId'];
          if (adminId != null) {
            print('👥 Collaborateur détecté, utilisation des données de l\'administrateur: $adminId');
            
            // Récupérer les données de l'entreprise depuis l'admin
            final adminDoc = await FirebaseFirestore.instance
                .collection('users')
                .doc(adminId)
                .get();
            
            if (adminDoc.exists) {
              nomEntreprise ??= adminDoc.data()?['nomEntreprise'];
              adresse ??= adminDoc.data()?['adresse'];
              telephone ??= adminDoc.data()?['telephone'];
              logoUrl ??= adminDoc.data()?['logoUrl'];
            }
            
            // Récupérer l'email de l'administrateur
            if (sendCopyToAdmin) {
              try {
                // D'abord essayer de récupérer depuis le document principal de l'admin
                final adminUserDoc = await FirebaseFirestore.instance
                    .collection('users')
                    .doc(adminId)
                    .get();
                
                // Vérifier si l'email est dans le document principal
                adminEmail = adminUserDoc.data()?['email'];
                
                // Si l'email n'est pas trouvé, essayer dans la sous-collection authentification
                if (adminEmail == null) {
                  final adminAuthDoc = await FirebaseFirestore.instance
                      .collection('users')
                      .doc(adminId)
                      .collection('authentification')
                      .doc(adminId)
                      .get();
                  
                  adminEmail = adminAuthDoc.data()?['email'];
                  print('📧 Email administrateur récupéré depuis authentification: $adminEmail');
                }
                
                // Si toujours null, essayer de récupérer l'utilisateur Firebase
                if (adminEmail == null) {
                  try {
                    // Récupérer tous les collaborateurs de l'admin pour trouver son email
                    final adminCollaborateursSnapshot = await FirebaseFirestore.instance
                        .collection('users')
                        .doc(adminId)
                        .collection('collaborateurs')
                        .where('role', isEqualTo: 'admin')
                        .limit(1)
                        .get();
                    
                    if (adminCollaborateursSnapshot.docs.isNotEmpty) {
                      adminEmail = adminCollaborateursSnapshot.docs.first.data()['email'];
                      print('📧 Email administrateur récupéré depuis collaborateurs: $adminEmail');
                    }
                  } catch (e) {
                    print('❌ Erreur lors de la recherche dans collaborateurs: $e');
                  }
                }
                
                print('📧 Email administrateur récupéré: $adminEmail');
              } catch (e) {
                print('❌ Erreur lors de la récupération de l\'email administrateur: $e');
              }
            }
          }
        } else {
          // Si c'est l'admin lui-même, utiliser ses propres données
          if (sendCopyToAdmin) {
            adminEmail = userDoc.data()?['email'] ?? user.email;
            print('📧 Email administrateur (utilisateur actuel): $adminEmail');
            
            // Si toujours null, utiliser l'email de l'utilisateur Firebase
            if (adminEmail == null && user.email != null) {
              adminEmail = user.email;
              print('📧 Utilisation de l\'email Firebase comme fallback: $adminEmail');
            }
          }
          
          // Récupérer les données de l'entreprise
          nomEntreprise ??= userDoc.data()?['nomEntreprise'];
          adresse ??= userDoc.data()?['adresse'];
          telephone ??= userDoc.data()?['telephone'];
          logoUrl ??= userDoc.data()?['logoUrl'];
        }
      } catch (e) {
        print('❌ Erreur lors de la vérification du rôle: $e');
        // Tenter d'utiliser les données de l'utilisateur actuel comme fallback
        if (sendCopyToAdmin && user.email != null) {
          adminEmail = user.email;
          print('📧 Utilisation de l\'email Firebase comme fallback après erreur: $adminEmail');
        }
      }

      // Récupérer les paramètres SMTP depuis admin/smtpSettings
      DocumentSnapshot? adminDoc;
      int maxRetries = 5;
      int currentRetry = 0;
      int baseDelayMs = 500;

      while (currentRetry < maxRetries) {
        try {
          // Tenter de récupérer les paramètres SMTP
          adminDoc = await FirebaseFirestore.instance
              .collection('admin')
              .doc('smtpSettings')
              .get();
          
          // Si on arrive ici, la récupération a réussi
          break;
        } catch (e) {
          currentRetry++;
          if (currentRetry >= maxRetries) {
            print('❌ Erreur récupération paramètres SMTP après $maxRetries tentatives: $e');
            throw Exception('Configuration SMTP non accessible: $e');
          }
          
          // Calcul du délai avec backoff exponentiel
          int delayMs = baseDelayMs * (1 << (currentRetry - 1));
          
          print('🔄 Tentative $currentRetry/$maxRetries échouée. Nouvel essai dans ${delayMs}ms...');
          await Future.delayed(Duration(milliseconds: delayMs));
        }
      }

      if (adminDoc == null || !adminDoc.exists) {
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
              <p>Bonjour ${prenom ?? ''} ${nom ?? ''},</p>
              
              <p>Nous avons le plaisir de vous transmettre votre contrat de location signé en pièce jointe. 📝</p>
              
              <p style="font-weight: bold;">Merci pour votre confiance et bonne route ! 🏎️🚗</p>

              <p style="font-weight: bold; color: #333;">
                <strong>⚠️ L'utilisateur est totalement responsable des contraventions, amendes et procès-verbaux établis en violation du code de la route.</strong>
              </p>

              <p>Si vous pensez avoir reçu cet email par erreur merci de bien vouloir nous contacter au plus vite à l'adresse suivante : contact@contraloc.fr.</p>

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
          // Récupérer l'ID de l'administrateur
          String adminId = user.uid;
          
          // Si c'est un collaborateur, récupérer l'ID de son admin
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
              
          if (userDoc.exists && userDoc.data()?['role'] == 'collaborateur') {
            adminId = userDoc.data()?['adminId'] ?? user.uid;
          }
          
          // Récupérer email_secondaire depuis la sous-collection authentification
          String? emailSecondaire;
          try {
            final adminAuthDoc = await FirebaseFirestore.instance
                .collection('users')
                .doc(adminId)
                .collection('authentification')
                .doc(adminId)
                .get();
                
            if (adminAuthDoc.exists) {
              emailSecondaire = adminAuthDoc.data()?['email_secondaire'];
              if (emailSecondaire != null && emailSecondaire.isNotEmpty) {
                print('📧 Email secondaire administrateur récupéré: $emailSecondaire');
              }
            }
          } catch (e) {
            print('❌ Erreur lors de la récupération de l\'email secondaire: $e');
          }
          
          // Récupérer tous les collaborateurs qui ont receiveContractCopies = true
          List<String> collaborateursEmails = [];
          try {
            // Récupérer directement depuis la collection users principale
            final collaborateursSnapshot = await FirebaseFirestore.instance
                .collection('users')
                .where('adminId', isEqualTo: adminId)
                .where('role', isEqualTo: 'collaborateur')
                .where('receiveContractCopies', isEqualTo: true)
                .get();
            
            for (var collaborateurDoc in collaborateursSnapshot.docs) {
              // Ne pas ajouter l'utilisateur actuel s'il est un collaborateur
              if (collaborateurDoc.id == user.uid) continue;
              
              final collaborateurEmail = collaborateurDoc.data()['email'];
              if (collaborateurEmail != null && collaborateurEmail.isNotEmpty) {
                collaborateursEmails.add(collaborateurEmail);
                print('📧 Collaborateur ajouté en copie: $collaborateurEmail');
              }
            }
          } catch (e) {
            print('❌ Erreur lors de la récupération des collaborateurs: $e');
            print('ℹ️ L\'email sera envoyé sans les collaborateurs en copie');
          }
          
          // Déterminer si le contrat a été créé par un collaborateur
          String collaborateurInfo = '';
          if (nomCollaborateur != null && prenomCollaborateur != null) {
            collaborateurInfo = '<p><strong>Ce contrat a été créé par votre collaborateur: $prenomCollaborateur $nomCollaborateur</strong></p>';
          }
          
          final adminMessage = Message()
            ..from = Address(smtpEmail, nomEntreprise ?? 'Contraloc')
            ..recipients.add(smtpEmail); // Utiliser l'adresse d'envoi comme destinataire technique

          // Ajouter l'administrateur en copie invisible (cci)
          adminMessage.bccRecipients.add(adminEmail);
          print('📧 Administrateur ajouté en copie invisible: $adminEmail');
                      
          // Ajouter l'email secondaire en copie invisible (cci) si disponible
          if (emailSecondaire != null && emailSecondaire.isNotEmpty) {
            adminMessage.bccRecipients.add(emailSecondaire);
            print('📧 Email secondaire ajouté en copie invisible: $emailSecondaire');
          }
          
          // Ajouter les collaborateurs en copie invisible (cci)
          for (var collaborateurEmail in collaborateursEmails) {
            adminMessage.bccRecipients.add(collaborateurEmail);
            print('📧 Collaborateur ajouté en copie invisible: $collaborateurEmail');
          }
          
          adminMessage
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
                  
                  $collaborateurInfo
                  
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
