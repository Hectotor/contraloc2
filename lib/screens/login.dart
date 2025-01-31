import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../widget/inscription.dart'; // Import de la page d'inscription
import '../widget/navigation.dart'; // Import de la page de navigation
import '../services/subscription_service.dart'; // Import SubscriptionService

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

    try {
      // Connexion Firebase
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Synchroniser l'ID utilisateur avec RevenueCat
      if (userCredential.user != null) {
        try {
          final customerInfo = await Purchases.getCustomerInfo();
          if (customerInfo.originalAppUserId != userCredential.user!.uid) {
            await Purchases.logOut();
            await Purchases.logIn(userCredential.user!.uid);
          }
          print('✅ ID utilisateur RevenueCat synchronisé après connexion');

          // Mettre à jour Firebase lors de la synchronisation de l'ID utilisateur avec RevenueCat
          await SubscriptionService.updateFirebaseUponPurchase(userCredential.user!.uid);
        } catch (e) {
          print('⚠️ Erreur synchronisation RevenueCat: $e');
          // Continuer malgré l'erreur car l'utilisateur est déjà connecté
        }
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const NavigationPage()),
      );
    } catch (e) {
      _showErrorToast("Erreur : ${_getFriendlyErrorMessage(e.toString())}");
    }
  }

  // Fonction pour afficher des messages d'erreur plus clairs
  String _getFriendlyErrorMessage(String error) {
    if (error.contains('wrong-password')) {
      return "Le mot de passe est incorrect.";
    } else if (error.contains('user-not-found')) {
      return "Aucun utilisateur trouvé avec cet email.";
    } else if (error.contains('invalid-email')) {
      return "L'adresse email n'est pas valide.";
    } else {
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
                    "Bienvenue sur\nContraloc",
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

                  // Bouton Connexion
                  ElevatedButton(
                    onPressed: _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF08004D), // Bleu nuit
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
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
                    child: const Text(
                      "Nouveau Client",
                      style: TextStyle(color: Color(0xFF08004D), fontSize: 18),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!isKeyboardVisible) // Ajouter cette condition
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Column(
                children: const [
                  Text(
                    "Fabriqué en France 🇫🇷",
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
            ),
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
