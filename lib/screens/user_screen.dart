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
import '../USERS/collaborateurs_screen.dart.dart'; // Import du fichier collaborateurs.dart
import '../USERS/add_collaborator_screen.dart'; // Import du fichier add_collaborator_screen.dart

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

  // Ajouter un champ pour stocker le rôle
  String _userRole = '';

  @override
  void initState() {
    super.initState();
    currentUser = _auth.currentUser;
    if (currentUser != null) {
      _loadUserRole();
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
    if (_isUserDataLoaded) {
      print('📝 Données déjà chargées, pas besoin de recharger');
      return;
    }

    try {
      print('🔄 Début du chargement des données utilisateur');
      
      // Récupérer le document principal de l'utilisateur
      final userDoc = await _firestore.collection('users').doc(currentUser!.uid).get();
      if (!userDoc.exists) {
        print('❌ Document utilisateur non trouvé');
        return;
      }

      final userData = userDoc.data()!;
      final String role = userData['role'] ?? '';
      print('👤 Rôle utilisateur: $role');

      if (role == 'collaborateur') {
        final String adminId = userData['adminId'] ?? '';
        final String collaborateurId = userData['id'] ?? ''; // Utiliser l'ID unique du collaborateur
        print('🔍 Chargement des données collaborateur (Admin ID: $adminId, Collab ID: $collaborateurId)');
        
        final collabDoc = await _firestore
            .collection('users')
            .doc(adminId)
            .collection('authentification')
            .doc(collaborateurId) // Utiliser l'ID unique du collaborateur
            .get();

        if (collabDoc.exists) {
          final collabData = collabDoc.data()!;
          print('📄 Données collaborateur trouvées, mise à jour de l\'interface');
          setState(() {
            _logoUrl = collabData['logoUrl'];
            _nomEntrepriseController.text = collabData['nomEntreprise'] ?? '';
            _telephoneController.text = collabData['telephone'] ?? '';
            _adresseController.text = collabData['adresse'] ?? '';
            _siretController.text = collabData['siret'] ?? '';
            _nomController.text = collabData['nom'] ?? '';
            _prenomController.text = collabData['prenom'] ?? '';
            _emailController.text = currentUser?.email ?? '';
            _isUserDataLoaded = true;
          });
          print('✅ Interface mise à jour avec les données collaborateur');
          print('📊 Données chargées: Entreprise=${_nomEntrepriseController.text}, Nom=${_nomController.text}, Prénom=${_prenomController.text}');
        } else {
          print('❌ Document collaborateur non trouvé dans la collection authentification');
          print('🔍 Chemins vérifiés:');
          print('- Document principal: /users/${currentUser!.uid}');
          print('- Document auth: /users/$adminId/authentification/$collaborateurId');
        }
      } else {
        print('🔍 Chargement des données administrateur');
        setState(() {
          _logoUrl = userData['logoUrl'];
          _nomEntrepriseController.text = userData['nomEntreprise'] ?? '';
          _nomController.text = userData['nom'] ?? '';
          _prenomController.text = userData['prenom'] ?? '';
          _emailController.text = currentUser?.email ?? '';
          _telephoneController.text = userData['telephone'] ?? '';
          _adresseController.text = userData['adresse'] ?? '';
          _siretController.text = userData['siret'] ?? '';
          _isUserDataLoaded = true;
        });
        print('✅ Interface mise à jour avec les données administrateur');
        print('📊 Données chargées: Entreprise=${_nomEntrepriseController.text}, Nom=${_nomController.text}, Prénom=${_prenomController.text}');
      }
    } catch (e) {
      print('❌ Erreur lors du chargement des données: $e');
    }
  }

  // Méthode pour mettre à jour les coordonnées utilisateur
  Future<void> _updateUserData() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      print('🔄 Début de la mise à jour des données utilisateur');
      
      // Récupérer le rôle de l'utilisateur
      final userDoc = await _firestore.collection('users').doc(currentUser!.uid).get();
      if (!userDoc.exists) {
        throw Exception('Document utilisateur non trouvé');
      }

      final userData = userDoc.data()!;
      final String role = userData['role'] ?? '';
      print('👤 Rôle utilisateur: $role');

      String? finalLogoUrl = _logoUrl;
      if (_logo != null) {
        finalLogoUrl = await _uploadLogoToStorage(File(_logo!.path));
      }

      if (role == 'collaborateur') {
        print('📝 Mise à jour des données collaborateur');
        final String adminId = userData['adminId'];
        final String collaborateurId = userData['id'];
        print('🔍 Mise à jour pour Admin ID: $adminId, Collab ID: $collaborateurId');
        
        // Pour un collaborateur, uniquement mettre à jour nom et prénom
        await _firestore
            .collection('users')
            .doc(adminId)
            .collection('authentification')
            .doc(collaborateurId)
            .update({
              'nom': _nomController.text.trim(),
              'prenom': _prenomController.text.trim(),
              'lastUpdateDate': FieldValue.serverTimestamp(),
            });

        // Mise à jour du document principal du collaborateur
        await _firestore
            .collection('users')
            .doc(currentUser!.uid)
            .update({
              'adminId': adminId,
              'role': 'collaborateur',
              'id': collaborateurId
            });

        print('✅ Données collaborateur mises à jour aux deux endroits');

      } else {
        print('📝 Mise à jour des données administrateur');
        // Pour un admin, mettre à jour toutes les informations
        final Map<String, dynamic> tamponData = {
          'logoUrl': finalLogoUrl,
          'nomEntreprise': _nomEntrepriseController.text.trim(),
          'adresse': _adresseController.text.trim(),
          'telephone': _telephoneController.text.trim(),
          'siret': _siretController.text.trim(),
        };

        final Map<String, dynamic> adminData = {
          'nomEntreprise': _nomEntrepriseController.text.trim(),
          'nom': _nomController.text.trim(),
          'prenom': _prenomController.text.trim(),
          'email': _emailController.text.trim(),
          'telephone': _telephoneController.text.trim(),
          'adresse': _adresseController.text.trim(),
          'siret': _siretController.text.trim(),
          'logoUrl': finalLogoUrl,
          'tampon': tamponData,
          'lastUpdateDate': FieldValue.serverTimestamp(),
        };

        await _firestore
            .collection('users')
            .doc(currentUser!.uid)
            .update(adminData);

        print('✅ Données administrateur mises à jour');
      }

      setState(() {
        _logoUrl = finalLogoUrl;
        _isLoading = false;
        _isUserDataLoaded = false; // Forcer le rechargement des données
      });

      // Recharger les données pour s'assurer de la synchronisation
      await _loadUserData();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Coordonnées mises à jour avec succès !"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('❌ Erreur lors de la mise à jour: $e');
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
      // Suppression de Purchases.logOut() ici, car nous ne voulons pas déconnecter RevenueCat
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
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

  // Nouvelle méthode pour charger le rôle de l'utilisateur
  Future<void> _loadUserRole() async {
    try {
      final userDoc = await _firestore.collection('users').doc(currentUser!.uid).get();
      if (userDoc.exists) {
        setState(() {
          _userRole = userDoc.data()?['role'] ?? '';
        });
      }
    } catch (e) {
      print('❌ Erreur lors du chargement du rôle: $e');
    }
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
              MaterialPageRoute(builder: (context) => QuestionUser()),
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
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CollaborateursScreen(),
                            ),
                          );
                        },
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
                            const Icon(Icons.group, color: Colors.white),
                            const SizedBox(width: 10),
                            const Text(
                              "Mes Collaborateurs",
                              style: TextStyle(color: Colors.white, fontSize: 18),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 50),
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
                              builder: (context) => AbonnementScreen(),
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
                      const SizedBox(height: 50),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddCollaboratorScreen(),
                            ),
                          );
                        },
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
                            const Icon(Icons.group_add, color: Colors.white),
                            const SizedBox(width: 10),
                            const Text(
                              "Ajouter un Collaborateur",
                              style: TextStyle(color: Colors.white, fontSize: 18),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
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
    
    // Désactiver les champs d'entreprise pour les collaborateurs
    if (_userRole == 'collaborateur' && (
        label == "Nom de l'entreprise" || 
        label == "Téléphone" || 
        label == "Adresse" || 
        label == "Numéro SIRET")) {
      isEditable = false;
      isReadOnly = true;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        enabled: isEditable,
        readOnly: isReadOnly,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: icon != null ? Icon(icon) : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF08004D)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF08004D)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF08004D), width: 2),
          ),
        ),
        style: const TextStyle(fontSize: 16),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Ce champ est requis';
          }
          return null;
        },
      ),
    );
  }
}