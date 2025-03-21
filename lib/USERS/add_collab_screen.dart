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
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _nomController = TextEditingController();
  final TextEditingController _prenomController = TextEditingController();
  final TextEditingController _adminPasswordController = TextEditingController(); // Ajout du contrôleur pour le mot de passe de l'administrateur
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _obscureAdminPassword = true;

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
          'nom': _nomController.text.trim(),
          'prenom': _prenomController.text.trim(),
          'adminId': adminId,
          'role': 'collaborateur',
          'permissions': {
            'lecture': true,
            'ecriture': true,
            'suppression': true,
          },
          'emailVerifie': false,
          'dateCreation': FieldValue.serverTimestamp(),
        });

        // Ajouter les informations dans la collection users pour le collaborateur
        await FirebaseFirestore.instance
            .collection('users')
            .doc(collaboratorId)
            .set({
          'adminId': adminId,
          'role': 'collaborateur',
        });

        print('Collaborateur ajouté avec succès : $collaboratorId');

        // Informer l'administrateur que le collaborateur a été ajouté avec succès
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Collaborateur ajouté avec succès !'),
            backgroundColor: Color(0xFF08004D),
            behavior: SnackBarBehavior.floating,
          ),
        );
        
        // Revenir à l'écran précédent après l'ajout réussi
        Navigator.pop(context);
      } finally {
        // Suppression de l'application temporaire
        await tempApp.delete();
      }
    } catch (e) {
      print('Erreur lors de l\'ajout du collaborateur : $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur : $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Ajouter un collaborateur",
          style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF08004D),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  // Section d'information
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Color(0xFF08004D), size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                "Information",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF08004D),
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                "Le collaborateur aura accès à votre liste de véhicules et pourra consulter, modifier et gérer les contrats.",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF555555),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),
                  
                  // Titre de section
                  const Text(
                    "Informations du collaborateur",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF08004D),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Champ Prénom
                  TextFormField(
                    controller: _prenomController,
                    keyboardType: TextInputType.name,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: 'Prénom',
                      hintText: 'Prénom du collaborateur',
                      prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF08004D)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFF08004D), width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer le prénom';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Champ Nom
                  TextFormField(
                    controller: _nomController,
                    keyboardType: TextInputType.name,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: 'Nom',
                      hintText: 'Nom du collaborateur',
                      prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF08004D)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFF08004D), width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer le nom';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Champ Email
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      hintText: 'exemple@email.com',
                      prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF08004D)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFF08004D), width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
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
                  const SizedBox(height: 16),
                  
                  // Champ Mot de passe
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Mot de passe',
                      hintText: 'Minimum 8 caractères, 1 caractère spécial',
                      prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF08004D)),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          color: const Color(0xFF08004D),
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFF08004D), width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer un mot de passe';
                      }
                      if (value.length < 8) {
                        return 'Veuillez entrer un mot de passe d\'au moins 8 caractères';
                      }
                      if (!RegExp(r'^(?=.*[!@#\$%\^&\*])').hasMatch(value)) {
                        return 'Le mot de passe doit contenir au moins 1 caractère spécial';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Champ Confirmation Mot de passe
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    decoration: InputDecoration(
                      labelText: 'Confirmer le mot de passe',
                      hintText: 'Répétez le mot de passe',
                      prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF08004D)),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                          color: const Color(0xFF08004D),
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFF08004D), width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez confirmer le mot de passe';
                      }
                      if (value != _passwordController.text) {
                        return 'Les mots de passe ne correspondent pas';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 30),
                  
                  // Titre de section
                  const Text(
                    "Confirmation administrateur",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF08004D),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Veuillez entrer votre mot de passe pour confirmer cette action",
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF555555),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Champ Mot de passe admin
                  TextFormField(
                    controller: _adminPasswordController,
                    obscureText: _obscureAdminPassword,
                    decoration: InputDecoration(
                      labelText: 'Votre mot de passe',
                      prefixIcon: const Icon(Icons.admin_panel_settings_outlined, color: Color(0xFF08004D)),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureAdminPassword ? Icons.visibility_off : Icons.visibility,
                          color: const Color(0xFF08004D),
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureAdminPassword = !_obscureAdminPassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFF08004D), width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer votre mot de passe';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 40),
                  
                  // Bouton de soumission
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF08004D),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text(
                              'Ajouter le collaborateur',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
