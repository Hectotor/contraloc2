import 'package:ContraLoc/USERS/privacy_policy.dart';
import 'package:ContraLoc/USERS/terms_of_service.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';

class QuestionUser extends StatefulWidget {
  const QuestionUser({Key? key}) : super(key: key);

  @override
  State<QuestionUser> createState() => _QuestionUserState();
}

class _QuestionUserState extends State<QuestionUser> with SingleTickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  bool _isSending = false;
  User? currentUser;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isFormVisible = false;

  @override
  void initState() {
    super.initState();
    currentUser = FirebaseAuth.instance.currentUser;
    
    // Configuration de l'animation
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));
    
    // Démarrer l'animation après le build initial
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animationController.forward();
      Future.delayed(const Duration(milliseconds: 200), () {
        setState(() {
          _isFormVisible = true;
        });
      });
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _sendEmail(String message) async {
    if (message.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Le message ne peut pas être vide."),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
        ),
      );
      return;
    }

    try {
      print('Tentative de récupération des paramètres SMTP depuis Firestore...');
      final adminDoc = await FirebaseFirestore.instance
          .collection('contactSettings')
          .doc('smtpConfig')
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
          .collection('authentification')
          .doc(currentUser?.uid)
          .get();

      if (!userDoc.exists) {
        print('Document utilisateur non trouvé dans authentification');
        return;
      }

      final userData = userDoc.data() ?? {};

      final userName = '${userData['prenom'] ?? ''} ${userData['nom'] ?? ''}';
      final userCompany = userData['nomEntreprise'] ?? '';
      final userEmail = currentUser?.email ?? '';
      final userPhone = userData['telephone'] ?? '';
      final userAddress = userData['adresse'] ?? '';
      final userSiret = userData['siret'] ?? '';

      // Configurer le serveur SMTP
      final smtpServerConfig = SmtpServer(
        'contraloc.fr',
        port: 465,
        username: 'contact@contraloc.fr',
        password: smtpPassword,
        ssl: true,
      );

      // Création de l'email avec un contenu HTML structuré
      final emailMessage = Message()
        ..from = Address('contact@contraloc.fr', 'ContraLoc')
        ..recipients.add('contact@contraloc.fr')
        ..subject = 'Question d\'un utilisateur'
        ..html = '''
          <div style="font-family: Arial, sans-serif; font-size: 14px; color: #333; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #e0e0e0; border-radius: 8px; background-color: #f9f9f9;">
            <div style="text-align: center; margin-bottom: 20px;">
              <h2 style="color: #08004D; margin-bottom: 5px;">Nouvelle question utilisateur</h2>
              <p style="color: #666; font-size: 12px;">Envoyé le ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year} à ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}</p>
            </div>
            
            <div style="background-color: #fff; padding: 15px; border-radius: 8px; border-left: 4px solid #08004D; margin-bottom: 20px;">
              <p style="font-style: italic; color: #555;">
                "$message"
              </p>
            </div>
            
            <div style="background-color: #fff; padding: 15px; border-radius: 8px; margin-bottom: 20px;">
              <h3 style="color: #08004D; font-size: 16px; margin-top: 0;">Coordonnées de l'utilisateur</h3>
              <table style="width: 100%; border-collapse: collapse;">
                <tr>
                  <td style="padding: 8px 0; border-bottom: 1px solid #eee; width: 30%;"><strong>Nom</strong></td>
                  <td style="padding: 8px 0; border-bottom: 1px solid #eee;">$userName</td>
                </tr>
                <tr>
                  <td style="padding: 8px 0; border-bottom: 1px solid #eee;"><strong>Société</strong></td>
                  <td style="padding: 8px 0; border-bottom: 1px solid #eee;">$userCompany</td>
                </tr>
                <tr>
                  <td style="padding: 8px 0; border-bottom: 1px solid #eee;"><strong>Email</strong></td>
                  <td style="padding: 8px 0; border-bottom: 1px solid #eee;">$userEmail</td>
                </tr>
                <tr>
                  <td style="padding: 8px 0; border-bottom: 1px solid #eee;"><strong>Téléphone</strong></td>
                  <td style="padding: 8px 0; border-bottom: 1px solid #eee;">$userPhone</td>
                </tr>
                <tr>
                  <td style="padding: 8px 0; border-bottom: 1px solid #eee;"><strong>Adresse</strong></td>
                  <td style="padding: 8px 0; border-bottom: 1px solid #eee;">$userAddress</td>
                </tr>
                <tr>
                  <td style="padding: 8px 0;"><strong>SIRET</strong></td>
                  <td style="padding: 8px 0;">$userSiret</td>
                </tr>
              </table>
            </div>
            
            <p style="text-align: center; font-size: 12px; color: #999;">
              Ce message a été envoyé depuis l'application ContraLoc.
            </p>
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
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
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
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
        ),
      );
    } catch (e) {
      print('Erreur inconnue : $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur lors de l'envoi du message : $e"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
        ),
      );
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  Future<void> _launchWhatsApp() async {
    final phoneNumber = '0617038890';
    final url = 'https://wa.me/$phoneNumber';

    try {
      final Uri uri = Uri.parse(url);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw 'Impossible d\'ouvrir WhatsApp';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Impossible d'ouvrir WhatsApp."),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
        ),
      );
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Copié dans le presse-papier"),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
      ),
    );
  }

  Future<void> _launchPhone() async {
    final phoneNumber = '0617038890';
    final url = 'tel:$phoneNumber';

    try {
      final Uri uri = Uri.parse(url);
      if (!await launchUrl(uri)) {
        throw 'Impossible d\'appeler ce numéro';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Impossible d'appeler ce numéro."),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
        ),
      );
    }
  }

  Future<void> _launchEmail() async {
    final email = 'contact@contraloc.fr';
    final url = 'mailto:$email';

    try {
      final Uri uri = Uri.parse(url);
      if (!await launchUrl(uri)) {
        throw 'Impossible d\'ouvrir l\'application mail';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Impossible d'ouvrir l'application mail."),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Nous Contacter",
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF08004D),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // En-tête avec logo et titre
                  _buildHeader(),
                  const SizedBox(height: 32),
                  
                  // Options de contact
                  _buildContactOptions(),
                  const SizedBox(height: 32),
                  
                  // Formulaire de message
                  AnimatedOpacity(
                    opacity: _isFormVisible ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeIn,
                    child: _buildMessageForm(),
                  ),
                  const SizedBox(height: 40),
                  
                  // Pied de page
                  _buildFooter(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Hero(
          tag: 'contact_logo',
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.asset(
              'assets/icon/IconContraLoc.png',
              height: 90,
              width: 90,
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          "Besoin d'aide ?",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF08004D),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Notre équipe est à votre disposition",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildContactOptions() {
    return Column(
      children: [
        // Option WhatsApp
        _buildContactCard(
          title: "WhatsApp",
          subtitle: "Réponse rapide via messagerie",
          icon: Icons.chat_bubble_outline,
          iconColor: const Color(0xFF25D366),
          onTap: _launchWhatsApp,
        ),
        const SizedBox(height: 16),
        
        // Option Téléphone
        _buildContactCard(
          title: "Téléphone",
          subtitle: "06 17 03 88 90",
          icon: Icons.phone_outlined,
          iconColor: Colors.blue,
          onTap: _launchPhone,
          onLongPress: () => _copyToClipboard("0617038890"),
        ),
        const SizedBox(height: 16),
        
        // Option Email
        _buildContactCard(
          title: "Email",
          subtitle: "contact@contraloc.fr",
          icon: Icons.email_outlined,
          iconColor: Colors.red,
          onTap: _launchEmail,
          onLongPress: () => _copyToClipboard("contact@contraloc.fr"),
        ),
      ],
    );
  }

  Widget _buildContactCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
    VoidCallback? onLongPress,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF08004D),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (onLongPress != null)
                      Text(
                        "Appuyez longuement pour copier",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[400],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey[400],
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageForm() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Envoyez-nous un message",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF08004D),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Nous vous répondrons dans les plus brefs délais",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _messageController,
            maxLines: 6,
            decoration: InputDecoration(
              hintText: "Comment pouvons-nous vous aider ?",
              hintStyle: TextStyle(color: Colors.grey[400]),
              filled: true,
              fillColor: Colors.grey[50],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey[200]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFF08004D)),
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _isSending ? null : () => _sendEmail(_messageController.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF08004D),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15),
              minimumSize: const Size(double.infinity, 55),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 2,
              disabledBackgroundColor: const Color(0xFF08004D).withOpacity(0.5),
            ),
            child: _isSending
                ? const SizedBox(
                    height: 25,
                    width: 25,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.send, size: 20),
                      SizedBox(width: 8),
                      Text(
                        "Envoyer",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        const Text(
          "ContraLoc",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF08004D),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          "Depuis 2020 - contraloc.fr",
          style: TextStyle(
            fontSize: 14,
            color: Color(0x800F056B),
          ),
        ),
        const SizedBox(height: 20),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 20.0,
          children: [
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TermsOfService(),
                ),
              ),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0x800F056B),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text(
                "Conditions d'utilisation",
                style: TextStyle(fontSize: 14),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PrivacyPolicy(),
                ),
              ),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0x800F056B),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text(
                "Politique de confidentialité",
                style: TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
