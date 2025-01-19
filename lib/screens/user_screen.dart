import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart'; // Import Firebase Storage
import '../screens/login.dart'; // Import de l'écran de connexion si l'utilisateur se déconnecte
import '../USERS/tampon.dart';
import '../USERS/logo.dart';
import '../USERS/question_user.dart'; // Import the question user screen
import '../USERS/abonnement_screen.dart'; // Add this import
import '../USERS/supprimer_compte.dart'; // Import du fichier supprimer_compte.dart

class UserScreen extends StatefulWidget {
  const UserScreen({Key? key}) : super(key: key);

  @override
  State<UserScreen> createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final _formKey = GlobalKey<FormState>();

  // Contrôleurs pour les champs
  final TextEditingController _nomController = TextEditingController();
  final TextEditingController _prenomController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _telephoneController = TextEditingController();
  final TextEditingController _nomEntrepriseController =
      TextEditingController();
  final TextEditingController _adresseController = TextEditingController();
  final TextEditingController _siretController = TextEditingController();
  XFile? _logo;
  String? _logoUrl; // Add a variable to store the logo URL

  User? currentUser;
  bool _isLoading = false; // Add loading state

  @override
  void initState() {
    super.initState();
    currentUser = _auth.currentUser;
    if (currentUser != null) {
      _loadUserData();
    } else {
      // Identifiant de test
      _nomEntrepriseController.text = "Entreprise Test";
      _nomController.text = "Test";
      _prenomController.text = "Utilisateur";
      _emailController.text = "test@example.com";
      _telephoneController.text = "1234567890";
      _adresseController.text = "123 Rue de Test";
      _siretController.text = "12345678901234";
    }
  }

  // Charger les données utilisateur depuis Firestore
  Future<void> _loadUserData() async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .collection('authentification')
          .doc(currentUser!.uid)
          .get();

      if (!doc.exists) {
        // Initialisation des valeurs par défaut pour un nouvel utilisateur
        await _firestore
            .collection('users')
            .doc(currentUser!.uid)
            .collection('authentification')
            .doc(currentUser!.uid)
            .set({
          'nomEntreprise': '',
          'nom': '',
          'prenom': '',
          'email': currentUser?.email ?? '', // Ajout de l'email
          'telephone': '',
          'adresse': '',
          'siret': '',
          'numberOfCars': 1,
          'limiteContrat': 10,
          'isSubscriptionActive': false,
          'subscriptionId': 'free',
          'subscriptionType': 'monthly',
        });
      } else {
        final data = doc.data()!;

        setState(() {
          _nomEntrepriseController.text = data['nomEntreprise'] ?? '';
          _nomController.text = data['nom'] ?? '';
          _prenomController.text = data['prenom'] ?? '';
          _emailController.text = currentUser?.email ?? '';
          _telephoneController.text = data['telephone'] ?? '';
          _adresseController.text = data['adresse'] ?? '';
          _siretController.text = data['siret'] ?? '';
          _logoUrl = data['logoUrl'] as String?;
        });
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur lors du chargement des données : $e")),
        );
      }
    }
  }

  // Méthode pour mettre à jour les coordonnées utilisateur
  Future<void> _updateUserData() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    String? logoUrl = _logoUrl;
    try {
      if (_logo != null) {
        logoUrl = await _uploadLogoToStorage(File(_logo!.path));
      }

      final Map<String, dynamic> userData = {
        'nomEntreprise': _nomEntrepriseController.text.trim(),
        'nom': _nomController.text.trim(),
        'prenom': _prenomController.text.trim(),
        'email': _emailController.text.trim(),
        'telephone': _telephoneController.text.trim(),
        'adresse': _adresseController.text.trim(),
        'siret': _siretController.text.trim(),
      };

      if (logoUrl != null) {
        userData['logoUrl'] = logoUrl;
        userData['tampon'] = {
          'logoPath': logoUrl,
          'nomEntreprise': _nomEntrepriseController.text.trim(),
          'adresse': _adresseController.text.trim(),
          'telephone': _telephoneController.text.trim(),
          'siret': _siretController.text.trim(),
        };
      }

      // Utiliser update() au lieu de set()
      await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .collection('authentification')
          .doc(currentUser!.uid)
          .update(userData); // Changé de set() à update()

      setState(() {
        _logoUrl = logoUrl;
        _isLoading = false;
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Coordonnées mises à jour avec succès !"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur lors de la mise à jour : $e")),
        );
      }
    }
  }

  // Méthode pour envoyer un email de réinitialisation du mot de passe
  Future<void> _resetPassword() async {
    try {
      await _auth.sendPasswordResetEmail(email: currentUser!.email!);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                "Un email de réinitialisation a été envoyé à votre adresse.")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur : $e")),
      );
    }
  }

  // Méthode pour déconnecter l'utilisateur
  Future<void> _logout() async {
    try {
      await _auth.signOut();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur : $e")),
      );
    }
  }

  // Méthode pour choisir une image de logo

  // Méthode pour uploader le logo sur Firebase Storage
  Future<String?> _uploadLogoToStorage(File imageFile) async {
    if (currentUser == null) {
      print('Erreur: utilisateur non connecté');
      return null;
    }

    try {
      final fileName = '${currentUser!.uid}.jpg';
      final Reference storageRef = FirebaseStorage.instance
          .ref()
          .child('users/${currentUser!.uid}/logo/$fileName');

      await storageRef.putFile(imageFile);
      final downloadUrl = await storageRef.getDownloadURL();
      print("Logo uploadé avec succès : $downloadUrl");
      return downloadUrl;
    } catch (e) {
      print('Erreur upload logo: $e');
      return null;
    }
  }

  // Méthode pour supprimer le logo

  Future<void> _showLogoutConfirmationDialog() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white, // Ajout ici
        title: const Text(
          "Confirmation de déconnexion",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF08004D),
          ),
        ),
        content: const Text(
          "Êtes-vous sûr de vouloir vous déconnecter ?",
          style: TextStyle(
            fontSize: 18,
            color: Colors.black87,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              "Annuler",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF08004D),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              "Se déconnecter",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Ajout ici
      appBar: AppBar(
        title: const Text(
          "Mon Profil",
          style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold), // Couleur du titre en blanc
        ),
        backgroundColor: const Color(0xFF08004D), // Bleu nuit
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.help_outline, color: Colors.white),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const QuestionUser()),
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _showLogoutConfirmationDialog, // Modification ici
          ),
        ],
      ),
      body: Container(
        color: Colors.white, // Ajout ici
        child: Stack(
          children: [
            if (currentUser != null)
              SingleChildScrollView(
                physics:
                    const BouncingScrollPhysics(), // Ajout de l'effet de défilement
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 24.0, // Augmentation du padding vertical
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      LogoWidget(
                        initialLogoUrl: _logoUrl,
                        onLogoChanged: (String? newLogoUrl) async {
                          setState(() {
                            _logoUrl = newLogoUrl;
                          });
                          if (newLogoUrl != null) {
                            final docRef = _firestore
                                .collection('users')
                                .doc(currentUser!.uid)
                                .collection('authentification')
                                .doc(currentUser!.uid);
                            final doc = await docRef.get();
                            if (doc.exists) {
                              await docRef.update({
                                'logoUrl': newLogoUrl,
                              });
                            } else {
                              await docRef.set({
                                'logoUrl': newLogoUrl,
                                // Ajoutez ici d'autres champs nécessaires pour créer le document
                              });
                            }
                          }
                        },
                        currentUser: currentUser,
                      ),
                      const SizedBox(height: 20),
                      _buildTextField(
                          "Nom de l'entreprise", _nomEntrepriseController, true,
                          icon: Icons.business),
                      _buildTextField("Nom", _nomController, true,
                          icon: Icons.person),
                      _buildTextField("Prénom", _prenomController, true,
                          icon: Icons.person_outline),
                      _buildTextField("Email", _emailController, false,
                          isReadOnly: true, icon: Icons.email),
                      _buildTextField("Téléphone", _telephoneController, true,
                          icon: Icons.phone),
                      _buildTextField("Adresse", _adresseController, true,
                          icon: Icons.location_on),
                      _buildTextField("Numéro SIRET", _siretController, false,
                          icon: Icons.business_center),
                      const SizedBox(height: 10),
                      Tampon(
                        logoPath: _logo?.path ?? _logoUrl ?? '',
                        nomEntreprise: _nomEntrepriseController.text,
                        adresse: _adresseController.text,
                        telephone: _telephoneController.text,
                        siret: _siretController.text,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _updateUserData,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F056B), // Bleu nuit
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          "Mettre à jour",
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _resetPassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange, // Couleur différente
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          "Modifier mon mot de passe",
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AbonnementScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          "Gérer mon Abonnement",
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return const SupprimerCompte();
                            },
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          "Supprimer mon compte",
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                      ),
                      const SizedBox(
                          height: 100), // Augmentation de la marge en bas
                      const Text(
                        "Depuis 2020 - Contraloc.fr",
                        style:
                            TextStyle(fontSize: 16, color: Color(0xFF0F056B)),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(
                          height: 5), // Marge supplémentaire tout en bas
                    ],
                  ),
                ),
              )
            else
              const Center(child: CircularProgressIndicator()),
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
      ),
    );
  }

  Widget _buildTextField(
      String label, TextEditingController controller, bool isEditable,
      {bool isReadOnly = false, IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        readOnly: isReadOnly,
        validator: isEditable
            ? (value) =>
                (value == null || value.isEmpty) ? "Ce champ est requis" : null
            : null,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Color(0xFF0F056B)),
          prefixIcon: icon != null
              ? Icon(icon, color: Colors.black.withOpacity(0.5))
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF0F056B)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF0F056B)),
          ),
        ),
      ),
    );
  }
}
