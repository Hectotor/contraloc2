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
          'cb_subscription': 'free',
          'cb_nb_car': 1,
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
          style: TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF08004D), // Bleu nuit
        elevation: 0, // Supprime l'ombre
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios,
              color: Colors.white), // Flèche blanche
          onPressed: () {
            Navigator.pop(context); // Retour à l'écran précédent
          },
        ),
      ),
      backgroundColor: Colors.grey[50],
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 24.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // En-tête
                  _buildHeader(),
                  const SizedBox(height: 24),
                  
                  // Section des informations personnelles
                  _buildPersonalInfoSection(),
                  const SizedBox(height: 24),
                  
                  // Section des informations de connexion
                  _buildLoginInfoSection(),
                  const SizedBox(height: 30),
                  
                  // Bouton d'inscription
                  _buildRegisterButton(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
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

  // En-tête avec titre
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
            "Créez votre compte",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF08004D),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Remplissez le formulaire pour accéder à toutes les fonctionnalités",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  // Section des informations personnelles
  Widget _buildPersonalInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 16),
          child: Text(
            "Informations professionnelles",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
        ),
        _buildInputCard(
          title: "Nom de l'entreprise",
          icon: Icons.business,
          color: Colors.blue[700]!,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextField(
                "Nom de l'entreprise",
                _nomEntrepriseController,
                true,
                inputFormatters: [UpperCaseTextFormatter()],
              ),
              const SizedBox(height: 16),
              _buildTextField(
                "Prénom",
                _prenomController,
                true,
                inputFormatters: [CapitalizeFirstLetterFormatter()],
              ),
              const SizedBox(height: 16),
              _buildTextField(
                "Nom",
                _nomController,
                true,
                inputFormatters: [CapitalizeFirstLetterFormatter()],
              ),
              const SizedBox(height: 16),
              _buildTextField(
                "Adresse",
                _adresseController,
                true,
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                "Téléphone",
                _telephoneController,
                true,
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Section des informations de connexion
  Widget _buildLoginInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 16),
          child: Text(
            "Informations de connexion",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
        ),
        _buildInputCard(
          title: "Email",
          icon: Icons.email,
          color: Colors.red[700]!,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextField(
                "Email",
                _emailController,
                true,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              _buildPasswordField(
                "Mot de passe",
                _passwordController,
              ),
              const SizedBox(height: 16),
              _buildPasswordField(
                "Confirmer le mot de passe",
                _confirmPasswordController,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Bouton d'inscription
  Widget _buildRegisterButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _register,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF08004D),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 3,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text(
              "S'inscrire",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.person_add, size: 20),
          ],
        ),
      ),
    );
  }

  // Carte pour les champs de saisie
  Widget _buildInputCard({
    required String title,
    required IconData icon,
    required Color color,
    required Widget child,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
      String label, TextEditingController controller, bool isEditable,
      {bool isReadOnly = false,
      TextInputType keyboardType = TextInputType.text,
      List<TextInputFormatter>? inputFormatters,
      int? maxLines,
      int? minLines}) {
    return TextFormField(
      controller: controller,
      readOnly: isReadOnly,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLines: maxLines ?? 1,
      minLines: minLines ?? 1,
      onChanged: (value) {
        if (label == "Email") {
          setState(() {});
        }
      },
      style: const TextStyle(
        fontSize: 16,
        color: Color(0xFF333333),
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Colors.grey[600],
          fontSize: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF08004D), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        filled: true,
        fillColor: Colors.white,
        errorText: label == "Email" &&
                controller.text.isNotEmpty &&
                !_isValidEmail(controller.text)
            ? "Email non valide"
            : null,
        errorStyle: const TextStyle(color: Colors.red),
      ),
    );
  }

  Widget _buildPasswordField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      obscureText:
          label == "Mot de passe" ? !_showPassword : !_showConfirmPassword,
      style: const TextStyle(
        fontSize: 16,
        color: Color(0xFF333333),
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Colors.grey[600],
          fontSize: 14,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            label == "Mot de passe"
                ? (_showPassword ? Icons.visibility_off : Icons.visibility)
                : (_showConfirmPassword
                    ? Icons.visibility_off
                    : Icons.visibility),
            color: const Color(0xFF08004D),
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
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF08004D), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}
