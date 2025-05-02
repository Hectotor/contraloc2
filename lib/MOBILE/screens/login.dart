import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../USERS/Subscription/revenue_cat_service.dart';
import '../widget/inscription.dart'; // Import de la page d'inscription
import '../widget/navigation.dart'; // Import de la page de navigation
import '../utils/welcome_mail.dart'; // Ajout de l'import pour WelcomeMail
import '../widget/chargement.dart'; // Import du widget de chargement
import '../widget/popup_mail_nonverifie.dart'; // Nouveau popup pour email non vérifié

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _showPassword = false; // Ajout de la variable pour gérer la visibilité
  String? _errorMessage; // Nouvelle variable pour stocker le message d'erreur
  bool _isLoading = false; // Nouvelle variable pour gérer l'état de chargement

  // Méthode pour valider l'email
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    return emailRegex.hasMatch(email);
  }

  // Méthode pour se connecter
  void _login() async {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    // Validation des champs
    if (email.isEmpty || password.isEmpty) {
      _showErrorToast("Veuillez remplir tous les champs.");
      return;
    }

    if (!_isValidEmail(email)) {
      _showErrorToast("Veuillez entrer une adresse email valide.");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Connexion Firebase
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Identifier l'utilisateur avec RevenueCat
      if (userCredential.user != null) {
        // Force la réinitialisation de RevenueCat avant de tenter de se connecter
        try {
          await RevenueCatService.forceReInitialize();
          await RevenueCatService.login(userCredential.user!.uid);
          print(' RevenueCat login réussi après réinitialisation forcée');
        } catch (revenueCatError) {
          print(' Erreur RevenueCat (non bloquante): $revenueCatError');
          // Continuer même si RevenueCat échoue
        }
        
        // Récupérer les données de l'utilisateur pour l'email de bienvenue
        final userData = await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .collection('authentification')
            .doc(userCredential.user!.uid)
            .get();

        if (userData.exists) {
          String? prenom = userData.data()?['prenom'];
          String? nom = userData.data()?['nom'];
          bool welcomeEmailSent = userData.data()?['welcomeEmailSent'] ?? false;
          
          // Envoyer l'email de bienvenue seulement si ce n'est pas déjà fait
          if (!welcomeEmailSent && mounted) {
            await WelcomeMail.sendWelcomeEmail(
              email: email,
              context: context,
              prenom: prenom,
              nom: nom,
            );

            // Marquer l'email comme envoyé
            await FirebaseFirestore.instance
                .collection('users')
                .doc(userCredential.user!.uid)
                .collection('authentification')
                .doc(userCredential.user!.uid)
                .update({'welcomeEmailSent': true});
          }
        }

        // Synchroniser l'ID utilisateur avec RevenueCat
        try {
          final customerInfo = await Purchases.getCustomerInfo();
          if (customerInfo.originalAppUserId != userCredential.user!.uid) {
            await Purchases.logOut();
            await Purchases.logIn(userCredential.user!.uid);
          }
          print('✅ ID utilisateur RevenueCat synchronisé après connexion');
        } catch (e) {
          print('⚠️ Erreur synchronisation RevenueCat: $e');
          // Continuer malgré l'erreur car l'utilisateur est déjà connecté
        }

        // Vérification du champ emailVerifie dans Firestore
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).get();
        final emailVerifie = userDoc.data()?['emailVerifie'] ?? false;

        if (emailVerifie == true) {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const NavigationPage()),
            );
          }
        } else {
          // Afficher le nouveau popup email non vérifié avec bouton de renvoi
          PopupMailNonVerifie.afficher(
            context: context,
            onResendEmail: () async {
              final user = FirebaseAuth.instance.currentUser;
              await user?.sendEmailVerification();
            },
          );
        }
      }
    } on FirebaseAuthException catch (e) {

      // Extraire le code d'erreur Firebase
      String errorMessage = _getFriendlyErrorMessage(e.code);
      
      // Définir le message d'erreur (sans afficher de toast)
      setState(() {
        _errorMessage = errorMessage;
      });
    } catch (e) {
      print('❌ Erreur de connexion: $e');
      
      // Extraire le code d'erreur Firebase
      String errorMessage;
      errorMessage = _getFriendlyErrorMessage(e.toString());
      
      // Définir le message d'erreur (sans afficher de toast)
      setState(() {
        _errorMessage = errorMessage;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Fonction pour afficher des messages d'erreur plus clairs
  String _getFriendlyErrorMessage(String error) {
    print('🔍 Analyse du code d\'erreur: "$error"');
    
    // Cas spécifiques pour les erreurs Firebase
    switch (error) {
      case 'wrong-password':
        return "Le mot de passe est incorrect. Veuillez réessayer.";
      case 'user-not-found':
        return "Aucun utilisateur trouvé avec cet email. Veuillez vérifier votre email et votre mot de passe.";
      case 'invalid-email':
        return "L'adresse email n'est pas valide. Veuillez vérifier votre email.";
      case 'too-many-requests':
        return "Trop de tentatives échouées. Veuillez réessayer plus tard.";
      case 'user-disabled':
        return "Ce compte a été désactivé. Veuillez contacter le support.";
      case 'operation-not-allowed':
        return "La connexion avec email et mot de passe n'est pas activée.";
      case 'network-request-failed':
        return "Problème de connexion réseau. Vérifiez votre connexion internet.";
      case 'invalid-credential':
        return "Identifiants invalides. Veuillez vérifier votre email et votre mot de passe.";
      case 'account-exists-with-different-credential':
        return "Un compte existe déjà avec une autre méthode de connexion.";
      case 'weak-password':
        return "Le mot de passe est trop faible. Utilisez au moins 6 caractères.";
      case 'email-already-in-use':
        return "Cette adresse email est déjà utilisée par un autre compte.";
      default:
        return "Une erreur est survenue. Veuillez réessayer.";
    }
  }

  // Méthode pour réinitialiser le mot de passe
  void _resetPassword() async {
    String email = _emailController.text.trim();

    if (email.isEmpty) {
      _showErrorToast("Veuillez entrer votre email.");
      return;
    }

    if (!_isValidEmail(email)) {
      _showErrorToast("Veuillez entrer une adresse email valide.");
      return;
    }

    try {
      await _auth.sendPasswordResetEmail(email: email);
      Fluttertoast.showToast(
        msg: "Un email de réinitialisation a été envoyé.",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.green,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    } catch (e) {
      _showErrorToast("Erreur : ${_getFriendlyErrorMessage(e.toString())}");
    }
  }

  void _showErrorToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.redAccent,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Titre de bienvenue
                  const Text(
                    "Bienvenue sur\nContraLoc",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF08004D), // Bleu nuit
                    ),
                  ),
                  const SizedBox(height: 50),
                  const Text(
                    "Dématérialisez tous vos contrats de location en un clin d'œil.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Champ Email
                  _buildTextField(
                    label: "Email",
                    controller: _emailController,
                    icon: Icons.email,
                    inputType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 20),

                  // Champ Mot de passe
                  _buildTextField(
                    label: "Mot de passe",
                    controller: _passwordController,
                    icon: Icons.lock,
                    isPassword: true,
                  ),
                  const SizedBox(height: 10),

                  // Mot de passe oublié
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: _resetPassword,
                      child: const Text(
                        "Mot de passe oublié ?",
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Afficher le message d'erreur si nécessaire
                  if (_errorMessage != null)
                    Text(_errorMessage ?? '', style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 10),

                  // Bouton Connexion
                  ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF08004D), // Bleu nuit
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            "Connexion",
                            style: TextStyle(color: Colors.white, fontSize: 18),
                          ),
                  ),
                  const SizedBox(height: 10),

                  // Bouton Nouveau Client
                  OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const InscriptionPage()),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF08004D)),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_add, color: Color(0xFF08004D)),
                        SizedBox(width: 10),
                        Text(
                          "Nouveau Utilisateur",
                          style: TextStyle(color: Color(0xFF08004D), fontSize: 18),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 100),

                  // Texte de bas de page (déplacé ici pour être scrollable)
                  if (!isKeyboardVisible && !_isLoading)
                    Column(
                      children: const [
                        Text(
                          "Fabriqué en France ",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          "Depuis 2020 - Contraloc.fr",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            const Chargement(),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType inputType = TextInputType.text,
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: inputType,
      obscureText: isPassword && !_showPassword, // Modification ici
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF08004D)),
        suffixIcon:
            isPassword // Ajout du bouton pour afficher/masquer le mot de passe
                ? IconButton(
                    icon: Icon(
                      _showPassword ? Icons.visibility_off : Icons.visibility,
                      color: const Color(0xFF08004D),
                    ),
                    onPressed: () {
                      setState(() {
                        _showPassword = !_showPassword;
                      });
                    },
                  )
                : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
