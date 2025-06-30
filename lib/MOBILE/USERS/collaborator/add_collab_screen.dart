import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class AddCollaborateurScreen extends StatefulWidget {
  final bool isEditing;
  final String? collaboratorId;
  final Map<String, dynamic>? collaboratorData;

  const AddCollaborateurScreen({
    Key? key, 
    this.isEditing = false, 
    this.collaboratorId, 
    this.collaboratorData
  }) : super(key: key);

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
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _passwordRequired = true; // Pas requis en mode édition
  bool _receiveContractCopies = false; // Option pour recevoir des copies des contrats

  // Fonction pour capitaliser la première lettre de chaque mot
  String capitalizeWords(String input) {
    if (input.isEmpty) return input;
    return input.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  @override
  void initState() {
    super.initState();
    
    // Si on est en mode édition, pré-remplir les champs avec les données du collaborateur
    if (widget.isEditing && widget.collaboratorData != null) {
      _emailController.text = widget.collaboratorData!['email'] ?? '';
      _nomController.text = widget.collaboratorData!['nom'] ?? '';
      _prenomController.text = widget.collaboratorData!['prenom'] ?? '';
      _receiveContractCopies = widget.collaboratorData!['receiveContractCopies'] ?? false;
      _passwordRequired = false; // Mot de passe pas requis en mode édition
    }
  }

  Future<void> _createCollaborator(String email, String password) async {
    try {
      // Stocker les informations de l'administrateur
      final User? adminUser = FirebaseAuth.instance.currentUser;
      if (adminUser == null) {
        throw Exception("L'administrateur n'est pas connecté");
      }
      final String adminId = adminUser.uid;
      final String adminEmail = adminUser.email ?? "";

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
            password: "",
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
          'nom': capitalizeWords(_nomController.text.trim()),
          'prenom': capitalizeWords(_prenomController.text.trim()),
          'adminId': adminId,
          'role': 'collaborateur',
          'receiveContractCopies': _receiveContractCopies,
          'permissions': {
            'lecture': true,
            'ecriture': true,
            'suppression': true,
          },
          'emailVerifie': false,
          'dateCreation': FieldValue.serverTimestamp(),
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

  Future<void> _updateCollaborator() async {
    try {
      // Récupérer l'UID du collaborateur
      final String collaboratorId = widget.collaboratorId!;

      // Mettre à jour les informations du collaborateur dans Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .collection('collaborateurs')
          .doc(collaboratorId)
          .update({
        'email': _emailController.text.trim(),
        'nom': capitalizeWords(_nomController.text.trim()),
        'prenom': capitalizeWords(_prenomController.text.trim()),
        'receiveContractCopies': _receiveContractCopies,
      });

      print('Collaborateur mis à jour avec succès : $collaboratorId');

      // Informer l'administrateur que le collaborateur a été mis à jour avec succès
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Collaborateur mis à jour avec succès !'),
          backgroundColor: Color(0xFF08004D),
          behavior: SnackBarBehavior.floating,
        ),
      );
      
      // Revenir à l'écran précédent après la mise à jour réussie
      Navigator.pop(context);
    } catch (e) {
      print('Erreur lors de la mise à jour du collaborateur : $e');
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          widget.isEditing ? 'Modifier le collaborateur' : 'Ajouter un collaborateur',
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
                  widget.isEditing
                  ? Container() // Pas de champ de mot de passe en mode édition
                  : TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Mot de passe',
                      hintText: 'Entrez un mot de passe',
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
                      if (!_passwordRequired) return null;
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer un mot de passe';
                      }
                      if (value.length < 6) {
                        return 'Le mot de passe doit contenir au moins 6 caractères';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Champ Confirmation Mot de passe
                  widget.isEditing
                  ? Container() // Pas de champ de confirmation en mode édition
                  : TextFormField(
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
                      if (!_passwordRequired) return null;
                      if (value == null || value.isEmpty) {
                        return 'Veuillez confirmer le mot de passe';
                      }
                      if (value != _passwordController.text) {
                        return 'Les mots de passe ne correspondent pas';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  
                  // Option pour recevoir des copies des contrats par email
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFDDDDDD)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.email_outlined, color: Color(0xFF08004D)),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Envoyer une copie des contrats par email',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF08004D),
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _receiveContractCopies = true;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _receiveContractCopies ? const Color(0xFF08004D) : Colors.transparent,
                                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(4)),
                                  border: Border.all(color: const Color(0xFF08004D)),
                                ),
                                child: Text(
                                  'Oui',
                                  style: TextStyle(
                                    color: _receiveContractCopies ? Colors.white : const Color(0xFF08004D),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _receiveContractCopies = false;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: !_receiveContractCopies ? const Color(0xFF08004D) : Colors.transparent,
                                  borderRadius: const BorderRadius.horizontal(right: Radius.circular(4)),
                                  border: Border.all(color: const Color(0xFF08004D)),
                                ),
                                child: Text(
                                  'Non',
                                  style: TextStyle(
                                    color: !_receiveContractCopies ? Colors.white : const Color(0xFF08004D),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
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
                          
                          if (widget.isEditing && widget.collaboratorId != null) {
                            // Mettre à jour les informations du collaborateur
                            await _updateCollaborator();
                          } else {
                            // Créer un nouveau collaborateur
                            await _createCollaborator(_emailController.text.trim(), _passwordController.text.trim());
                          }
                          
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
                          : Text(
                              widget.isEditing ? 'Mettre à jour le collaborateur' : 'Ajouter le collaborateur',
                              style: const TextStyle(
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
