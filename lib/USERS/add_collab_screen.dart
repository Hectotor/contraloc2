import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class AddCollaborateurScreen extends StatefulWidget {
  const AddCollaborateurScreen({Key? key}) : super(key: key);

  @override
  _AddCollaborateurScreenState createState() => _AddCollaborateurScreenState();
}

class _AddCollaborateurScreenState extends State<AddCollaborateurScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _adminPasswordController = TextEditingController(); // Ajout du contrôleur pour le mot de passe de l'administrateur
  bool _isLoading = false;

  Future<void> _createCollaborator(String email, String password) async {
    try {
      // Stocker les informations de l'administrateur
      final User? adminUser = FirebaseAuth.instance.currentUser;
      if (adminUser == null) {
        throw Exception("L'administrateur n'est pas connecté");
      }
      final String adminId = adminUser.uid;
      final String adminEmail = adminUser.email ?? "";
      String? adminPassword = _adminPasswordController.text;

      // Créer une instance temporaire de Firebase
      FirebaseApp tempApp = await Firebase.initializeApp(
        name: 'tempApp', 
        options: Firebase.app().options
      );

      try {
        // Créer un nouvel utilisateur avec l'email et le mot de passe en utilisant l'instance temporaire
        UserCredential userCredential = await FirebaseAuth.instanceFor(app: tempApp)
            .createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        // Récupérer l'UID du nouvel utilisateur
        String collaboratorId = userCredential.user!.uid;

        // Déconnecter le collaborateur de l'instance temporaire
        await FirebaseAuth.instanceFor(app: tempApp).signOut();

        // Vérifier si l'administrateur est toujours connecté
        if (FirebaseAuth.instance.currentUser == null || 
            FirebaseAuth.instance.currentUser!.uid != adminId) {
          print("Reconnexion de l'administrateur...");
          // Reconnecter l'administrateur si nécessaire
          await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: adminEmail,
            password: adminPassword,
          );
        }

        // Ajouter le collaborateur à Firestore (collection collaborateurs de l'admin)
        await FirebaseFirestore.instance
            .collection('users')
            .doc(adminId)
            .collection('collaborateurs')
            .doc(collaboratorId)
            .set({
          'uid': collaboratorId,
          'email': email,
          'adminId': adminId,
          'role': 'collaborateur',
          'permissions': {
            'lecture': true,
            'ecriture': false,
            'suppression': false,
          },
          'emailVerifie': false,
          'dateCreation': FieldValue.serverTimestamp(),
        });

        print('Collaborateur ajouté avec succès : $collaboratorId');

        // Informer l'administrateur que le collaborateur a été ajouté avec succès
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Collaborateur ajouté avec succès !')),
        );
      } finally {
        // Suppression de l'application temporaire
        await tempApp.delete();
      }
    } catch (e) {
      print('Erreur lors de l\'ajout du collaborateur : $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Collaborateur",
          style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold), // Couleur du titre en blanc
        ),
        backgroundColor: const Color(0xFF0F056B),
                leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email du collaborateur',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un email';
                  }
                  if (!value.contains('@')) {
                    return 'Veuillez entrer un email valide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Mot de passe du collaborateur',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un mot de passe';
                  }
                  if (value.length < 8) {
                    return 'Veuillez entrer un mot de passe d\'au moins 8 caractères';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _adminPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Mot de passe de l\'administrateur',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer le mot de passe de l\'administrateur';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : () async {
                  if (_formKey.currentState!.validate()) {
                    setState(() {
                      _isLoading = true;
                    });
                    await _createCollaborator(_emailController.text.trim(), _passwordController.text.trim());
                    setState(() {
                      _isLoading = false;
                    });
                  }
                },
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Créer le collaborateur'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
