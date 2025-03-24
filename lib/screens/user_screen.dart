import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart'; // Import Firebase Storage
import '../USERS/tampon.dart';
import '../USERS/logo.dart';
import '../USERS/admin_logo_widget.dart'; // Import du nouveau widget pour le logo admin
import '../USERS/admin_info_widget.dart'; // Import du nouveau widget pour les infos admin
import '../USERS/admin_tampon_widget.dart'; // Import du nouveau widget pour le tampon admin
import '../USERS/popup_deconnexion.dart'; // Import de la classe PopupDeconnexion
import '../USERS/collaborateur_info_widget.dart'; // Import du widget pour les infos du collaborateur
import '../USERS/question_user.dart'; // Import the question user screen
import '../USERS/abonnement_screen.dart'; // Add this import
import '../USERS/supprimer_compte.dart'; // Import du fichier supprimer_compte.dart
import '../USERS/contrat_condition.dart'; // Correct import for the contrat condition screen
import '../USERS/collaborator/collaborator.dart'; // Importer le nouveau fichier
import '../services/collaborateur_util.dart'; // Importer le fichier CollaborateurUtil

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
  bool _isCollaborateur = false; // Add a flag to check if user is collaborator

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
    // Si les données sont déjà chargées, ne pas les recharger
    if (_isUserDataLoaded) return;
    
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        // Vérifier si l'utilisateur est un collaborateur
        final collaborateurStatus = await CollaborateurUtil.checkCollaborateurStatus();
        final isCollaborateur = collaborateurStatus['isCollaborateur'] == true;
        
        setState(() {
          _isCollaborateur = isCollaborateur;
        });
        
        if (!isCollaborateur) {
          // Chargement normal pour un administrateur
          final userDoc = await _firestore
              .collection('users')
              .doc(currentUser.uid)
              .collection('authentification')
              .doc(currentUser.uid)
              .get();

          if (userDoc.exists) {
            final data = userDoc.data() as Map<String, dynamic>;
            setState(() {
              _nomController.text = data['nom'] ?? '';
              _prenomController.text = data['prenom'] ?? '';
              _emailController.text = data['email'] ?? '';
              _telephoneController.text = data['telephone'] ?? '';
              _adresseController.text = data['adresse'] ?? '';
              _siretController.text = data['siret'] ?? '';
              _logoUrl = data['logoUrl'] as String?;
              _isUserDataLoaded = true; // Set the flag to true after loading data
            });
          }
        } else {
          // Pour les collaborateurs, marquer simplement les données comme chargées
          // car le widget CollaborateurInfoWidget se charge de les récupérer
          setState(() {
            _isUserDataLoaded = true;
          });
        }
      }
    } catch (e) {
      print('DEBUG - Error loading user data: $e');
    }
  }

  // Méthode pour mettre à jour les coordonnées utilisateur
  Future<void> _updateUserData() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Utilisez le logoUrl existant si aucun nouveau logo n'est sélectionné
      String? finalLogoUrl = _logoUrl;

      // Si un nouveau logo a été sélectionné, uploadez-le
      if (_logo != null) {
        finalLogoUrl = await _uploadLogoToStorage(File(_logo!.path));
      }

      // Créer l'objet tampon avec le logo actuel
      final Map<String, dynamic> tamponData = {
        'logoUrl': finalLogoUrl, // Utilisez le logo final ici
        'nomEntreprise': _nomEntrepriseController.text.trim(),
        'adresse': _adresseController.text.trim(),
        'telephone': _telephoneController.text.trim(),
        'siret': _siretController.text.trim(),
      };

      // Créer l'objet de données utilisateur complet
      final Map<String, dynamic> userData = {
        'nomEntreprise': _nomEntrepriseController.text.trim(),
        'nom': _nomController.text.trim(),
        'prenom': _prenomController.text.trim(),
        'email': _emailController.text.trim(),
        'telephone': _telephoneController.text.trim(),
        'adresse': _adresseController.text.trim(),
        'siret': _siretController.text.trim(),
        'logoUrl': finalLogoUrl,
        'tampon': tamponData, // Ajouter les données du tampon
        'lastUpdateDate': FieldValue.serverTimestamp(),
      };

      // Mettre à jour Firestore
      await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .collection('authentification')
          .doc(currentUser!.uid)
          .update(userData);

      setState(() {
        _logoUrl = finalLogoUrl;
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
            onPressed: () => PopupDeconnexion.showLogoutConfirmationDialog(context),
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
                      _isCollaborateur 
                      ? const AdminLogoWidget() 
                      : LogoWidget(
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
                      
                      // Afficher les informations de l'administrateur pour les collaborateurs
                      if (_isCollaborateur)
                        const AdminInfoWidget(
                          showTitle: true,
                          padding: EdgeInsets.only(bottom: 20),
                        ),
                        
                      // Afficher les informations personnelles du collaborateur
                      if (_isCollaborateur)
                        const CollaborateurInfoWidget(
                          showTitle: true,
                          padding: EdgeInsets.symmetric(vertical: 20),
                        ),
                      
                      // Afficher les champs de texte modifiables uniquement pour les administrateurs
                      if (!_isCollaborateur) ...[
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
                      ],
                      
                      const SizedBox(height: 10),
                      
                      // Afficher le tampon uniquement pour les administrateurs
                      if (!_isCollaborateur)
                        Tampon(
                          logoPath: _logo?.path ?? _logoUrl ?? '',
                          nomEntreprise: _nomEntrepriseController.text,
                          adresse: _adresseController.text,
                          telephone: _telephoneController.text,
                          siret: _siretController.text,
                        ),
                      
                      // Afficher le tampon de l'administrateur pour les collaborateurs
                      if (_isCollaborateur)
                        const AdminTamponWidget(),
                      
                      const SizedBox(height: 20),
                      
                      // Bouton de mise à jour uniquement pour les administrateurs
                      if (!_isCollaborateur)
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
                      
                      const SizedBox(height: 50),
                      
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
                                builder: (context) => CollaboratorPage(
                                  adminId: currentUser!.uid,), // Naviguer vers l'écran d'ajout de collaborateur
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
                                "Ajouter un collaborateur",
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
                          'Version 1.0.9\nFabriqué en France \nDepuis 2020 - Contraloc.fr',
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
