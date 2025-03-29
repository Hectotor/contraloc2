import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import '../USERS/Subscription/revenue_cat_service.dart'; // Import RevenueCat Service
import 'popup_mail_confir.dart'; // Import du widget PopupMailConfirmation

// Définition de UpperCaseTextFormatter
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}

// Définition de CapitalizeFirstLetterFormatter
class CapitalizeFirstLetterFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue;
    
    return TextEditingValue(
      text: newValue.text[0].toUpperCase() + 
            (newValue.text.length > 1 ? newValue.text.substring(1).toLowerCase() : ''),
      selection: newValue.selection,
    );
  }
}

class InscriptionPage extends StatefulWidget {
  const InscriptionPage({Key? key}) : super(key: key);

  @override
  State<InscriptionPage> createState() => _InscriptionPageState();
}

class _InscriptionPageState extends State<InscriptionPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance; // Firestore instance

  // Contrôleurs
  final TextEditingController _nomEntrepriseController =
      TextEditingController();
  final TextEditingController _prenomController = TextEditingController();
  final TextEditingController _nomController = TextEditingController();
  final TextEditingController _adresseController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _telephoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // Ajouter ces variables d'état
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  bool _isLoading = false; // Add loading state

  Future<void> _register() async {
    setState(() {
      _isLoading = true; // Start loading
    });

    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();
    String confirmPassword = _confirmPasswordController.text.trim();

    // Capitaliser la première lettre du prénom et du nom
    String prenom = _prenomController.text.trim();
    String nom = _nomController.text.trim();

    prenom = prenom.isNotEmpty
        ? prenom[0].toUpperCase() + prenom.substring(1).toLowerCase()
        : '';
    nom = nom.isNotEmpty
        ? nom[0].toUpperCase() + nom.substring(1).toLowerCase()
        : '';

    // Check if any field is empty
    if (_nomEntrepriseController.text.trim().isEmpty ||
        prenom.isEmpty ||
        nom.isEmpty ||
        _adresseController.text.trim().isEmpty ||
        email.isEmpty ||
        _telephoneController.text.trim().isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      Fluttertoast.showToast(
          msg:
              "Veuillez remplir tous les champs pour un contrat de location parfait.");
      setState(() {
        _isLoading = false; // Stop loading
      });
      return;
    }

    if (password != confirmPassword) {
      Fluttertoast.showToast(msg: "Les mots de passe ne correspondent pas.");
      setState(() {
        _isLoading = false; // Stop loading
      });
      return;
    }

    if (!_isPasswordValid(password)) {
      Fluttertoast.showToast(
          msg:
              "Le mot de passe doit contenir 8 caractères, 1 majuscule, 1 chiffre, et 1 spécial.");
      setState(() {
        _isLoading = false; // Stop loading
      });
      return;
    }

    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        // Identifier l'utilisateur avec RevenueCat
        await RevenueCatService.login(userCredential.user!.uid);

        // Créer le document utilisateur dans Firestore
        await userCredential.user!.sendEmailVerification();

        // Save user information to Firestore with authentification subcollection
        await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .collection('authentification')
            .doc(userCredential.user!.uid)
            .set({
          'uid': userCredential.user!.uid,
          'role': 'admin',
          'nomEntreprise': _nomEntrepriseController.text
              .trim()
              .toUpperCase(), // Convert to uppercase
          'prenom': prenom, // Utiliser le prénom formaté
          'nom': nom, // Utiliser le nom formaté
          'adresse': _adresseController.text.trim(),
          'email': email,
          'emailVerifie': false,
          'dateCreation': FieldValue.serverTimestamp(),
          'telephone': _telephoneController.text.trim(),
          'subscriptionId': 'free',
          'isSubscriptionActive': false,
          'numberOfCars': 1,
          'limiteContrat': 10,
          // Ajout des nouveaux champs
          'cb_subscription': 'free',
          'cb_nb_car': 1,
          'cb_limite_contrat': 10,
        });

        setState(() {
          _isLoading = false; // Stop loading
        });

        // Afficher le popup de confirmation d'email
        PopupMailConfirmation.afficher(
          context: context,
          onPressed: () {
            Navigator.of(context).pop(); // Ferme le popup
            Navigator.of(context).pop(); // Retourne à l'écran de connexion
          },
        );
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Erreur : ${e.toString()}");
      setState(() {
        _isLoading = false; // Stop loading
      });
    }
  }

  bool _isPasswordValid(String password) {
    final regex = RegExp(
        r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$');
    return regex.hasMatch(password);
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Inscription",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF08004D), // Bleu nuit
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios,
              color: Colors.white), // Flèche blanche
          onPressed: () {
            Navigator.pop(context); // Retour à l'écran précédent
          },
        ),
      ),
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              return Center(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 24.0,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth:
                          constraints.maxWidth > 600 ? 500 : double.infinity,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTextField(
                          "Nom de l'entreprise",
                          _nomEntrepriseController,
                          true,
                          inputFormatters: [UpperCaseTextFormatter()],
                          icon: Icons.business,
                        ),
                        _buildTextField(
                          "Prénom",
                          _prenomController,
                          true,
                          inputFormatters: [CapitalizeFirstLetterFormatter()],
                          icon: Icons.person,
                        ),
                        _buildTextField(
                          "Nom",
                          _nomController,
                          true,
                          inputFormatters: [CapitalizeFirstLetterFormatter()],
                          icon: Icons.person_outline,
                        ),
                        _buildTextField(
                          "Adresse",
                          _adresseController,
                          true,
                          icon: Icons.location_on,
                        ),
                        _buildTextField(
                          "Email",
                          _emailController,
                          true,
                          keyboardType: TextInputType.emailAddress,
                          icon: Icons.email,
                        ),
                        _buildTextField(
                          "Téléphone",
                          _telephoneController,
                          true,
                          keyboardType: TextInputType.phone,
                          icon: Icons.phone,
                        ),
                        _buildPasswordField(
                          "Mot de passe",
                          _passwordController,
                          icon: Icons.lock_outline,
                        ),
                        _buildPasswordField(
                          "Confirmer le mot de passe",
                          _confirmPasswordController,
                          icon: Icons.lock_outline,
                        ),
                        const SizedBox(height: 30),
                        ElevatedButton(
                          onPressed: _register,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color(0xFF0F056B), // Bleu nuit
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text(
                            "S'inscrire",
                            style: TextStyle(color: Colors.white, fontSize: 18),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField(
      String label, TextEditingController controller, bool isEditable,
      {bool isReadOnly = false,
      TextInputType keyboardType = TextInputType.text,
      List<TextInputFormatter>? inputFormatters,
      IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        readOnly: isReadOnly,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        onChanged: (value) {
          if (label == "Email") {
            setState(() {});
          }
        },
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: icon != null
              ? Icon(icon, color: Colors.black.withOpacity(0.5))
              : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          errorText: label == "Email" &&
                  controller.text.isNotEmpty &&
                  !_isValidEmail(controller.text)
              ? "Email non valide"
              : null,
          errorStyle: const TextStyle(color: Colors.red),
        ),
      ),
    );
  }

  Widget _buildPasswordField(String label, TextEditingController controller,
      {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextField(
        controller: controller,
        obscureText:
            label == "Mot de passe" ? !_showPassword : !_showConfirmPassword,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: icon != null
              ? Icon(icon, color: Colors.black.withOpacity(0.5))
              : null,
          suffixIcon: IconButton(
            icon: Icon(
              label == "Mot de passe"
                  ? (_showPassword ? Icons.visibility_off : Icons.visibility)
                  : (_showConfirmPassword
                      ? Icons.visibility_off
                      : Icons.visibility),
              color: const Color(0xFF0F056B),
            ),
            onPressed: () {
              setState(() {
                if (label == "Mot de passe") {
                  _showPassword = !_showPassword;
                } else {
                  _showConfirmPassword = !_showConfirmPassword;
                }
              });
            },
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Color(0xFF0F056B)),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
