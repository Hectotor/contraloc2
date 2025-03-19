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
import '../USERS/contrat_condition.dart'; // Correct import for the contrat condition screen
import '../USERS/collab.dart' as collab; // Importer le fichier collab.dart avec un alias
import '../USERS/collaborateur_dashboard.dart'; // Importer le tableau de bord du collaborateur
import '../services/user_data_service.dart'; // Importer le service de données utilisateur

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
  bool isSubscriptionActive = false; // Add subscription state
  String subscriptionId = 'free'; // Add subscription ID state

  bool _isUserDataLoaded = false; // Add a flag to check if user data is loaded
  bool _isCollaborateur = false; // Add a flag to check if the user is a collaborator

  @override
  void initState() {
    super.initState();
    currentUser = _auth.currentUser;
    if (currentUser != null) {
      _loadUserData();
    } 
  }

  // Charger les données utilisateur depuis Firestore
  Future<void> _loadUserData() async {
    if (_isUserDataLoaded) return; // Return if data is already loaded

    try {
      setState(() {
        _isLoading = true;
      });
      
      // Utiliser le service UserDataService pour charger les données
      final UserDataService userDataService = UserDataService();
      final Map<String, dynamic> userData = await userDataService.loadUserData();
      
      // Vérifier si l'utilisateur est un collaborateur
      final bool isCollaborateur = userData['role'] == 'collaborateur';
      
      setState(() {
        // Données de l'abonnement (pour les admins)
        isSubscriptionActive = userData['isSubscriptionActive'] ?? false;
        subscriptionId = userData['subscriptionId'] ?? 'free';

        // Données utilisateur communes
        _nomController.text = userData['nom'] ?? '';
        _prenomController.text = userData['prenom'] ?? '';
        _emailController.text = currentUser?.email ?? '';
        
        // Données entreprise (pour tous)
        _nomEntrepriseController.text = userData['nomEntreprise'] ?? '';
        _telephoneController.text = userData['telephone'] ?? '';
        _adresseController.text = userData['adresse'] ?? '';
        _siretController.text = userData['siret'] ?? '';
        _logoUrl = userData['logoUrl'];
        
        // Marquer les données comme chargées
        _isUserDataLoaded = true;
        _isLoading = false;
        
        // Stocker le rôle de l'utilisateur
        _isCollaborateur = isCollaborateur;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('DEBUG - Error loading user data: $e');
    }
  }

  // Méthode pour mettre à jour les coordonnées utilisateur
  Future<void> _updateUserData() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Déterminer l'URL finale du logo
        String? finalLogoUrl = _logoUrl;

        // Si un nouveau logo a été sélectionné, uploadez-le
        if (_logo != null) {
          final fileName = '${currentUser!.uid}.jpg';
          final Reference storageRef = FirebaseStorage.instance
              .ref()
              .child('users/${currentUser!.uid}/logo/$fileName');

          await storageRef.putFile(File(_logo!.path));
          final downloadUrl = await storageRef.getDownloadURL();
          print("Logo uploadé avec succès : $downloadUrl");
          finalLogoUrl = downloadUrl;
        }

        // Créer un objet avec les données mises à jour
        final Map<String, dynamic> updatedData = {
          'nom': _nomController.text,
          'prenom': _prenomController.text,
          'nomEntreprise': _nomEntrepriseController.text,
          'telephone': _telephoneController.text,
          'adresse': _adresseController.text,
          'siret': _siretController.text,
          'logoUrl': finalLogoUrl,
        };

        // Utiliser le service UserDataService pour mettre à jour les données
        final UserDataService userDataService = UserDataService();
        final bool success = await userDataService.updateUserData(updatedData);

        setState(() {
          _isLoading = false;
        });

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profil mis à jour avec succès'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erreur lors de la mise à jour du profil'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        print('DEBUG - Error updating user data: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
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
      // Suppression de Purchases.logOut() ici, car nous ne voulons pas déconnecter RevenueCat
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

  // Méthode pour afficher la boîte de dialogue de confirmation de déconnexion
  void _showLogoutConfirmationDialog() {
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
                          "Nom de l'entreprise", _nomEntrepriseController, !_isCollaborateur,
                          icon: Icons.business),
                      _buildTextField("Nom", _nomController, true,
                          icon: Icons.person),
                      _buildTextField("Prénom", _prenomController, true,
                          icon: Icons.person_outline),
                      _buildTextField("Email", _emailController, false,
                          isReadOnly: true, icon: Icons.email),
                      _buildTextField("Téléphone", _telephoneController, !_isCollaborateur,
                          icon: Icons.phone),
                      _buildTextField("Adresse", _adresseController, !_isCollaborateur,
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
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.update, color: Colors.white),
                            const SizedBox(width: 10),
                            const Text(
                              "Mettre à jour",
                              style: TextStyle(color: Colors.white, fontSize: 18),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Bouton pour accéder au tableau de bord du collaborateur (visible uniquement pour les collaborateurs)
                      if (_isCollaborateur)
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CollaborateurDashboard(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.dashboard, color: Colors.white),
                              const SizedBox(width: 10),
                              const Text(
                                "Tableau de bord collaborateur",
                                style: TextStyle(color: Colors.white, fontSize: 18),
                              ),
                            ],
                          ),
                        ),
                      
                      const SizedBox(height: 30),
                      
                      // Boutons visibles uniquement pour les administrateurs
                      if (!_isCollaborateur) ...[
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ContratModifier(),
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
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.edit, color: Colors.white),
                              const SizedBox(width: 10),
                              const Text(
                                "Personnaliser le contrat location",
                                style: TextStyle(color: Colors.white, fontSize: 18),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => collab.AddCollaborateurScreen(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.person_add, color: Colors.white),
                              const SizedBox(width: 10),
                              const Text(
                                "Gérer mes collaborateurs",
                                style: TextStyle(color: Colors.white, fontSize: 18),
                              ),
                            ],
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
                            backgroundColor: Colors.green,
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.subscriptions, color: Colors.white),
                              const SizedBox(width: 10),
                              const Text(
                                "Gérer mon Abonnement",
                                style: TextStyle(color: Colors.white, fontSize: 18),
                              ),
                            ],
                          ),
                        ),
                      ],
                      
                      const SizedBox(height: 50),
                      ElevatedButton(
                        onPressed: _resetPassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.lock, color: Colors.white),
                            const SizedBox(width: 10),
                            const Text(
                              "Modifier mon mot de passe",
                              style: TextStyle(color: Colors.white, fontSize: 18),
                            ),
                          ],
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
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.delete, color: Colors.white),
                            const SizedBox(width: 10),
                            const Text(
                              "Supprimer mon compte",
                              style: TextStyle(color: Colors.white, fontSize: 18),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(
                          height: 100), // Augmentation de la marge en bas
                      Padding(
                        padding: const EdgeInsets.only(top: 20, bottom: 10),
                        child: Text(
                          textAlign: TextAlign.center,
                          'Version 1.0.9\nFabriqué en France 🇫🇷\nDepuis 2020 - Contraloc.fr',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ),
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
