import 'package:ContraLoc/USERS/privacy_policy.dart';
import 'package:ContraLoc/USERS/terms_of_service.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:url_launcher/url_launcher.dart'; // Import url_launcher

class QuestionUser extends StatefulWidget {
  const QuestionUser({Key? key}) : super(key: key);

  @override
  State<QuestionUser> createState() => _QuestionUserState();
}

class _QuestionUserState extends State<QuestionUser> {
  final TextEditingController _messageController = TextEditingController();
  bool _isSending = false;
  User? currentUser;

  @override
  void initState() {
    super.initState();
    currentUser = FirebaseAuth.instance.currentUser;
  }

  Future<void> _sendEmail(String message) async {
    if (message.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Le message ne peut pas être vide."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      print(
          'Tentative de récupération des paramètres SMTP depuis Firestore...');
      final adminDoc = await FirebaseFirestore.instance
          .collection('contactSettings') // Nouvelle collection
          .doc('smtpConfig') // Document spécifique
          .get();

      final adminData = adminDoc.data() ?? {};
      print('Données Firestore récupérées : $adminData');

      final smtpEmail = adminData['smtpEmail'] ?? '';
      final smtpPassword = adminData['smtpPassword'] ?? '';
      final smtpServer = adminData['smtpServer'] ?? '';
      final smtpPort = adminData['smtpPort'] is int
          ? adminData['smtpPort']
          : int.tryParse(adminData['smtpPort']?.toString() ?? '465') ?? 465;

      if (smtpEmail.isEmpty || smtpPassword.isEmpty || smtpServer.isEmpty) {
        throw Exception('Configuration SMTP incomplète.');
      }

      print('SMTP Email : $smtpEmail');
      print('SMTP Server : $smtpServer');
      print('SMTP Port : $smtpPort');

      // Récupérer les informations de l'utilisateur depuis Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser?.uid)
          .get();
      final userData = userDoc.data() ?? {};

      final userName = '${userData['prenom'] ?? ''} ${userData['nom'] ?? ''}';
      final userCompany = userData['nomEntreprise'] ?? '';
      final userEmail = currentUser?.email ?? '';
      final userPhone = userData['telephone'] ?? '';
      final userAddress = userData['adresse'] ?? '';
      final userSiret = userData['siret'] ?? '';

      // Configurer le serveur SMTP
      final smtpServerConfig = SmtpServer(
        smtpServer,
        port: smtpPort,
        username: smtpEmail,
        password: smtpPassword,
        ssl: smtpPort == 465,
      );

      // Création de l'email avec un contenu HTML structuré
      final emailMessage = Message()
        ..from = Address(smtpEmail, 'ContraLoc')
        ..recipients.add('contact@contraloc.fr') // Destinataire
        ..subject = 'Question d\'un utilisateur'
        ..html = '''
          <div style="font-family: Arial, sans-serif; font-size: 14px; color: #333;">
            <p><strong>Un utilisateur vous a envoyé une question :</strong></p>
            <p>
              "$message"
            </p>
            <br>
            <p><strong>Coordonnées de l'utilisateur :</strong></p>
            <p>Nom : $userName</p>
            <p>Société : $userCompany</p>
            <p>Email : $userEmail</p>
            <p>Téléphone : $userPhone</p>
            <p>Adresse : $userAddress</p>
            <p>SIRET : $userSiret</p>
            <br>
            <p>Contactez l'équipe pour toute assistance supplémentaire.</p>
          </div>
        ''';

      setState(() {
        _isSending = true;
      });

      print('Tentative d\'envoi de l\'email...');
      final sendReport = await send(emailMessage, smtpServerConfig);
      print('Email envoyé avec succès : $sendReport');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Votre message a été envoyé avec succès."),
          backgroundColor: Colors.green,
        ),
      );

      // Nettoyage du champ texte
      _messageController.clear();
    } on MailerException catch (e) {
      print('Erreur MailerException : $e');
      for (var p in e.problems) {
        print('Problème : ${p.code}: ${p.msg}');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur lors de l'envoi du message : $e"),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      print('Erreur inconnue : $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur lors de l'envoi du message : $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  Future<void> _launchWhatsApp() async {
    final phoneNumber = '0617038890'; // Remplacez par votre numéro WhatsApp
    final url = 'https://wa.me/$phoneNumber';

    if (await canLaunch(url)) {
      await launch(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Impossible d'ouvrir WhatsApp."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Ajout du background color
      appBar: AppBar(
        title: const Text(
          "Poser une Question",
          style: TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF08004D),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: constraints.maxWidth,
                minHeight: constraints.maxHeight,
              ),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(
                        height:
                            30), // Augmente la marge au-dessus du bouton WhatsApp
                    ElevatedButton(
                      onPressed: _launchWhatsApp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/icon/whatsapp_icon.png', // Assurez-vous que cette image existe
                            height: 24,
                            width: 24,
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            "Contactez-nous sur WhatsApp",
                            style: TextStyle(color: Colors.white, fontSize: 18),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Center(
                      child: Text(
                        "Réponse rapide",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Center(
                      child: Text(
                        "Ou envoyez-nous un message",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F056B),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _messageController,
                      maxLines: 8,
                      decoration: InputDecoration(
                        hintText: "Tapez votre message ici...",
                        hintStyle: TextStyle(color: Colors.grey[600]),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Color(0xFF0F056B)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Color(0xFF0F056B)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _isSending
                          ? null
                          : () async {
                              await _sendEmail(_messageController.text);
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F056B),
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSending
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              "Envoyer",
                              style:
                                  TextStyle(color: Colors.white, fontSize: 18),
                            ),
                    ),
                    const SizedBox(height: 60),
                    GestureDetector(
                      onTap: _launchWhatsApp,
                      child: ClipRRect(
                        borderRadius:
                            BorderRadius.circular(30), // Arrondir les coins
                        child: Image.asset(
                          'assets/icon/IconContraLoc.png',
                          height: 100,
                          width: 100,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Contactez-nous",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F056B),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Téléphone: 06 17 03 88 90",
                      style: TextStyle(fontSize: 16, color: Color(0xFF0F056B)),
                      textAlign: TextAlign.center,
                    ),
                    const Text(
                      "Email: contact@contraloc.fr",
                      style: TextStyle(fontSize: 16, color: Color(0xFF0F056B)),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Depuis 2020 - contraloc.fr",
                      style: TextStyle(fontSize: 16, color: Color(0xFF0F056B)),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 20.0, // Add spacing between buttons
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const TermsOfService()),
                            );
                          },
                          child: const Text("Conditions d'utilisation",
                              style: TextStyle(color: Color(0x800F056B))),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const PrivacyPolicy()),
                            );
                          },
                          child: const Text("Politique de confidentialité",
                              style: TextStyle(color: Color(0x800F056B))),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
