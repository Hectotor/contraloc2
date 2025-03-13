import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:firebase_core/firebase_core.dart';  // Ajout de l'import pour Firebase Core

class AddCollaboratorScreen extends StatefulWidget {
  @override
  _AddCollaboratorScreenState createState() => _AddCollaboratorScreenState();
}

class _AddCollaboratorScreenState extends State<AddCollaboratorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  bool _canRead = true;
  bool _canWrite = true;  // Donner la permission d'écriture par défaut
  bool _canDelete = true;  // Donner la permission de suppression par défaut
  bool _showPassword = false;  // Pour contrôler la visibilité du mot de passe

  Future<void> _addCollaborator() async {
    if (!_formKey.currentState!.validate()) return;

    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();
    String nom = _nomController.text.trim();
    String prenom = _prenomController.text.trim();

    try {
      print('🔄 Début de la création du compte collaborateur...');
      
      // Sauvegarder l'admin actuel
      final adminUser = FirebaseAuth.instance.currentUser;
      if (adminUser == null) {
        print('❌ Erreur: Admin non connecté');
        Fluttertoast.showToast(msg: "Vous devez être connecté");
        return;
      }
      String adminId = adminUser.uid;
      print('👤 Admin ID: $adminId');

      // Créer une nouvelle instance Firebase pour le collaborateur
      FirebaseApp collaboratorApp = await Firebase.initializeApp(
        name: 'collaboratorApp',
        options: Firebase.app().options
      );
      
      // Créer le compte collaborateur avec la nouvelle instance
      FirebaseAuth collaboratorAuth = FirebaseAuth.instanceFor(app: collaboratorApp);
      print('🔑 Création du compte collaborateur...');
      UserCredential userCredential = await collaboratorAuth.createUserWithEmailAndPassword(
        email: email,
        password: password
      );
      print('✅ Compte Firebase Auth créé avec succès');
      print('👥 Collaborateur UID: ${userCredential.user!.uid}');

      // Envoyer l'email de vérification
      await userCredential.user?.sendEmailVerification();
      print('📧 Email de vérification envoyé');

      // Générer un ID unique pour le collaborateur
      String collaboratorId = 'C${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
      print('🔑 ID Collaborateur généré: $collaboratorId');

      // Créer le document du collaborateur dans la collection de l'admin
      print('📝 Création du document collaborateur dans la collection admin...');
      await FirebaseFirestore.instance
          .collection('users')
          .doc(adminId)
          .collection('authentification')
          .doc(collaboratorId)
          .set({
        'id': collaboratorId,
        'email': email,
        'nom': nom,
        'prenom': prenom,
        'role': 'collaborateur',
        'emailVerifie': false,
        'permissions': {
          'lecture': _canRead,
          'ecriture': _canWrite,
          'suppression': _canDelete,
        },
        'dateCreation': FieldValue.serverTimestamp(),
        'adminId': adminId,
        'uid': userCredential.user!.uid,
      });
      print('✅ Document collaborateur créé dans la collection admin');

      // Créer un document pour le collaborateur avec la référence à son admin
      // Utiliser la même instance Firebase que celle qui a créé le compte
      print('📝 Création du document principal du collaborateur...');
      final collaboratorFirestore = FirebaseFirestore.instanceFor(app: collaboratorApp);
      await collaboratorFirestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
        'adminId': adminId,
        'role': 'collaborateur',
        'id': collaboratorId,
      });
      print('✅ Document principal du collaborateur créé');

      // Supprimer l'app temporaire
      await collaboratorApp.delete();
      print('🗑️ Application temporaire supprimée');

      Fluttertoast.showToast(msg: "Collaborateur ajouté avec succès");
      print('🎉 Processus de création du collaborateur terminé avec succès');
      Navigator.pop(context);
    } catch (e) {
      print('❌ Erreur lors de la création du compte : $e');
      Fluttertoast.showToast(msg: "Erreur lors de la création du compte : $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter un collaborateur'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nomController,
                decoration: const InputDecoration(
                  labelText: 'Nom',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un nom';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _prenomController,
                decoration: const InputDecoration(
                  labelText: 'Prénom',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un prénom';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Mot de passe',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showPassword ? Icons.visibility : Icons.visibility_off,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _showPassword = !_showPassword;
                      });
                    },
                  ),
                ),
                obscureText: !_showPassword,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un mot de passe';
                  }
                  if (value.length < 6) {
                    return 'Le mot de passe doit contenir au moins 6 caractères';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              Text('Permissions:', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              CheckboxListTile(
                title: const Text('Lecture'),
                value: _canRead,
                onChanged: (value) => setState(() => _canRead = value ?? true),
              ),
              CheckboxListTile(
                title: const Text('Écriture'),
                value: _canWrite,
                onChanged: (value) => setState(() => _canWrite = value ?? true),
              ),
              CheckboxListTile(
                title: const Text('Suppression'),
                value: _canDelete,
                onChanged: (value) => setState(() => _canDelete = value ?? true),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _addCollaborator,
                child: const Text('Inviter le collaborateur'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nomController.dispose();
    _prenomController.dispose();
    super.dispose();
  }
}