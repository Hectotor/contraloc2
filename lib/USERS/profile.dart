import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'tampon.dart';
import 'logo.dart';
import 'collaborator/admin_logo_widget.dart';
import 'collaborator/admin_info_widget.dart';
import 'collaborator/admin_tampon_widget.dart';
import 'collaborator/collaborateur_info_widget.dart';
import '../services/collaborateur_util.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final _formKey = GlobalKey<FormState>();

  // Contrôleurs pour les champs
  final TextEditingController _nomController = TextEditingController();
  final TextEditingController _prenomController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _telephoneController = TextEditingController();
  final TextEditingController _nomEntrepriseController = TextEditingController();
  final TextEditingController _adresseController = TextEditingController();
  final TextEditingController _siretController = TextEditingController();
  XFile? _logo;
  String? _logoUrl;

  User? currentUser;
  bool _isLoading = false;
  bool _isUserDataLoaded = false;
  bool _isCollaborateur = false;

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
          try {
            // Essayer d'abord depuis le cache
            try {
              final userDoc = await _firestore
                  .collection('users')
                  .doc(currentUser.uid)
                  .collection('authentification')
                  .doc(currentUser.uid)
                  .get(const GetOptions(source: Source.cache));
              
              if (userDoc.exists) {
                final data = userDoc.data() as Map<String, dynamic>;
                setState(() {
                  _nomController.text = data['nom'] ?? '';
                  _prenomController.text = data['prenom'] ?? '';
                  _emailController.text = data['email'] ?? '';
                  _telephoneController.text = data['telephone'] ?? '';
                  _adresseController.text = data['adresse'] ?? '';
                  _siretController.text = data['siret'] ?? '';
                  _nomEntrepriseController.text = data['nomEntreprise'] ?? '';
                  _logoUrl = data['logoUrl'] as String?;
                  _isUserDataLoaded = true;
                });
                print('✅ Données utilisateur récupérées depuis le cache');
              }
            } catch (cacheError) {
              print('⚠️ Tentative de cache échouée, nouvelle tentative avec le serveur: $cacheError');
              // Si la cache échoue, essayer le serveur
              final userDoc = await _firestore
                  .collection('users')
                  .doc(currentUser.uid)
                  .collection('authentification')
                  .doc(currentUser.uid)
                  .get(const GetOptions(source: Source.server));
              
              if (userDoc.exists) {
                final data = userDoc.data() as Map<String, dynamic>;
                setState(() {
                  _nomController.text = data['nom'] ?? '';
                  _prenomController.text = data['prenom'] ?? '';
                  _emailController.text = data['email'] ?? '';
                  _telephoneController.text = data['telephone'] ?? '';
                  _adresseController.text = data['adresse'] ?? '';
                  _siretController.text = data['siret'] ?? '';
                  _nomEntrepriseController.text = data['nomEntreprise'] ?? '';
                  _logoUrl = data['logoUrl'] as String?;
                  _isUserDataLoaded = true;
                });
                print('✅ Données utilisateur récupérées depuis le serveur');
              }
            }
          } catch (e) {
            print('⚠️ Erreur lors de la récupération des données utilisateur: $e');
          }
        } else {
          // Pour les collaborateurs, marquer simplement les données comme chargées
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
        'logoUrl': finalLogoUrl,
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
        'tampon': tamponData,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Gérer mon profil",
          style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF08004D),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        color: Colors.white,
        child: Stack(
          children: [
            if (currentUser != null)
              SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 24.0,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section Logo
                      Center(
                        child: _isCollaborateur
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
                                      });
                                    }
                                  }
                                },
                                currentUser: currentUser,
                              ),
                      ),
                      const SizedBox(height: 30),

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
                        // Section Informations Entreprise
                        const Padding(
                          padding: EdgeInsets.only(bottom: 16.0),
                          child: Text(
                            "Informations de l'entreprise",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF08004D),
                            ),
                          ),
                        ),
                        _buildTextField(
                            "Nom de l'entreprise", _nomEntrepriseController, true,
                            icon: Icons.business),
                        _buildTextField("Adresse", _adresseController, true,
                            icon: Icons.location_on),
                        _buildTextField("Numéro SIRET", _siretController, false,
                            icon: Icons.business_center),
                        
                        const SizedBox(height: 30),
                        
                        // Section Informations Personnelles
                        const Padding(
                          padding: EdgeInsets.only(bottom: 16.0),
                          child: Text(
                            "Informations personnelles",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF08004D),
                            ),
                          ),
                        ),
                        _buildTextField("Nom", _nomController, true,
                            icon: Icons.person),
                        _buildTextField("Prénom", _prenomController, true,
                            icon: Icons.person_outline),
                        _buildTextField("Email", _emailController, false,
                            isReadOnly: true, icon: Icons.email),
                        _buildTextField("Téléphone", _telephoneController, true,
                            icon: Icons.phone),
                        
                        const SizedBox(height: 30),
                        
                        // Section Tampon
                        const Padding(
                          padding: EdgeInsets.only(bottom: 16.0),
                          child: Text(
                            "Aperçu du tampon",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF08004D),
                            ),
                          ),
                        ),
                        Tampon(
                          logoPath: _logo?.path ?? _logoUrl ?? '',
                          nomEntreprise: _nomEntrepriseController.text,
                          adresse: _adresseController.text,
                          telephone: _telephoneController.text,
                          siret: _siretController.text,
                        ),
                      ],

                      // Afficher le tampon de l'administrateur pour les collaborateurs
                      if (_isCollaborateur)
                        const AdminTamponWidget(),

                      const SizedBox(height: 30),

                      // Bouton de mise à jour uniquement pour les administrateurs
                      if (!_isCollaborateur)
                        ElevatedButton(
                          onPressed: _updateUserData,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF08004D),
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.save, color: Colors.white),
                              SizedBox(width: 10),
                              Text(
                                "Enregistrer les modifications",
                                style: TextStyle(color: Colors.white, fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 50),
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
          labelStyle: const TextStyle(color: Color(0xFF08004D)),
          prefixIcon: icon != null
              ? Icon(icon, color: Colors.black.withOpacity(0.5))
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF08004D)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF08004D)),
          ),
        ),
      ),
    );
  }
}
