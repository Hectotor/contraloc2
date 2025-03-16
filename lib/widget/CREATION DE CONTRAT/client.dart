import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../location.dart'; // Import de la page location
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:ContraLoc/USERS/abonnement_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

class ClientPage extends StatefulWidget {
  final String marque;
  final String modele;
  final String immatriculation;
  final String? contratId;

  const ClientPage({
    Key? key,
    required this.marque,
    required this.modele,
    required this.immatriculation,
    this.contratId,
  }) : super(key: key);

  @override
  State<ClientPage> createState() => _ClientPageState();
}

class _ClientPageState extends State<ClientPage> {
  final TextEditingController _nomController = TextEditingController();
  final TextEditingController _prenomController = TextEditingController();
  final TextEditingController _adresseController = TextEditingController();
  final TextEditingController _telephoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _numeroPermisController = TextEditingController();

  File? _permisRecto;
  File? _permisVerso;
  bool isPremiumUser = false; // Nouvelle propriété

  @override
  void initState() {
    super.initState();
    _checkPremiumStatus();
    if (widget.contratId != null) {
      _loadClientData();
    }
  }

  Future<void> _checkPremiumStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('authentification')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data() ?? {};
        final subscriptionId = data['subscriptionId'] ?? 'free';
        final cb_subscription = data['cb_subscription'] ?? 'free';

        setState(() {
          // L'utilisateur est premium si l'un des deux abonnements est premium
          isPremiumUser = subscriptionId == 'premium-monthly_access' ||
              subscriptionId == 'premium-yearly_access' ||
              cb_subscription == 'premium-monthly_access' ||
              cb_subscription == 'premium-yearly_access';
        });
      }
    }
  }

  Future<void> _loadClientData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && widget.contratId != null) {
        final contratDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('locations')
            .doc(widget.contratId)
            .get();

        if (contratDoc.exists) {
          final data = contratDoc.data()!;
          setState(() {
            _nomController.text = data['nom'] ?? '';
            _prenomController.text = data['prenom'] ?? '';
            _adresseController.text = data['adresse'] ?? '';
            _telephoneController.text = data['telephone'] ?? '';
            _emailController.text = data['email'] ?? '';
            _numeroPermisController.text = data['numeroPermis'] ?? '';
          });
        }
      }
    } catch (e) {
      print('Erreur lors du chargement des données client: $e');
    }
  }

  void _showPremiumDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white, // Ajout du fond blanc
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text(
            "Fonctionnalité Premium",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF08004D),
            ),
          ),
          content: const Text(
            "La prise de photos du permis est disponible uniquement avec l'abonnement Premium. Souhaitez-vous découvrir nos offres ?",
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Plus tard",
                style: TextStyle(color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AbonnementScreen(),
                  ),
                );
              },
              child: const Text(
                "Voir les offres",
                style: TextStyle(
                  color: Color(0xFF08004D),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickImage(bool isRecto) async {
    final picker = ImagePicker();
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white, // Ajout du fond blanc
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Choisir une option",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF08004D),
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading:
                    const Icon(Icons.photo_library, color: Color(0xFF08004D)),
                title: const Text('Choisir depuis la galerie'),
                onTap: () async {
                  final pickedFile = await picker.pickImage(
                    source: ImageSource.gallery,
                    imageQuality: 70,
                  );
                  if (pickedFile != null) {
                    final compressedImage =
                        await FlutterImageCompress.compressWithFile(
                      pickedFile.path,
                      minWidth: 800,
                      minHeight: 800,
                      quality: 85,
                    );
                    if (compressedImage != null) {
                      setState(() {
                        if (isRecto) {
                          _permisRecto = File(pickedFile.path);
                        } else {
                          _permisVerso = File(pickedFile.path);
                        }
                      });
                    }
                  }
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading:
                    const Icon(Icons.photo_camera, color: Color(0xFF08004D)),
                title: const Text('Prendre une photo'),
                onTap: () async {
                  final pickedFile = await picker.pickImage(
                    source: ImageSource.camera,
                    imageQuality: 70,
                  );
                  if (pickedFile != null) {
                    final compressedImage =
                        await FlutterImageCompress.compressWithFile(
                      pickedFile.path,
                      minWidth: 800,
                      minHeight: 800,
                      quality: 85,
                    );
                    if (compressedImage != null) {
                      setState(() {
                        if (isRecto) {
                          _permisRecto = File(pickedFile.path);
                        } else {
                          _permisVerso = File(pickedFile.path);
                        }
                      });
                    }
                  }
                  Navigator.of(context).pop();
                },
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF08004D),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    "Annuler",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  void _saveClientInfo() async {
    try {
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LocationPage(
              marque: widget.marque,
              modele: widget.modele,
              immatriculation: widget.immatriculation,
              nom: _nomController.text,
              prenom: _prenomController.text,
              adresse: _adresseController.text,
              telephone: _telephoneController.text,
              email: _emailController.text,
              permisRecto: _permisRecto,
              permisVerso: _permisVerso,
              numeroPermis:
                  _numeroPermisController.text, // Ajout de numeroPermis
              contratId: widget.contratId, // Ajout de contratId
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur lors de l'enregistrement : $e")),
      );
    }
  }

  bool _showPermisFields = false; // Ajouter cette variable d'état

  ElevatedButton buildPhotoButton() {
    return ElevatedButton.icon(
      onPressed: isPremiumUser
          ? () {
              setState(() {
                _showPermisFields = !_showPermisFields;
              });
            }
          : _showPremiumDialog,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green, // Remis en vert pour tous les cas
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      icon: Icon(isPremiumUser ? Icons.add_a_photo : Icons.lock,
          color: Colors.white),
      label: Text(
        isPremiumUser ? "Ajouter photo permis" : "Ajouter photo permis",
        style: const TextStyle(color: Colors.white, fontSize: 18),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Ajout ici
      appBar: AppBar(
        title: const Text(
          "Informations du Client",
          style: TextStyle(color: Colors.white), // Set color to white
        ),
        backgroundColor: const Color(0xFF08004D), // Bleu nuit
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context); // Revenir à la page précédente
          },
        ),
      ),
      body: SingleChildScrollView(
        physics:
            const BouncingScrollPhysics(), // Ajout de l'effet de défilement élastique
        padding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 24.0, // Augmentation du padding vertical général
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTextField("Prénom", _prenomController),
            _buildTextField("Nom", _nomController),
            _buildGooglePlacesInput(),
            _buildTextField("Téléphone", _telephoneController,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(15),
                ]),
            _buildTextField("Email", _emailController,
                keyboardType: TextInputType.emailAddress),
            _buildTextField("N° Permis", _numeroPermisController),
            const SizedBox(height: 20),
            buildPhotoButton(),
            if (_showPermisFields && isPremiumUser) ...[
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildImageUploader(
                      "Permis Recto", _permisRecto, () => _pickImage(true)),
                  _buildImageUploader(
                      "Permis Verso", _permisVerso, () => _pickImage(false)),
                ],
              ),
            ],
            const SizedBox(height: 80), // Augmentation de l'espacement
            ElevatedButton(
              onPressed: _saveClientInfo,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF08004D),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                "Suivant",
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
            ),
            const SizedBox(height: 60), // Marge supplémentaire en bas
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {TextInputType keyboardType = TextInputType.text,
      List<TextInputFormatter>? inputFormatters}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: [
          if (label == "N° Permis") UpperCaseTextFormatter(),
          ...?inputFormatters,
        ],
        textCapitalization:
            (label == "Prénom" || label == "Nom" || label == "Adresse")
                ? TextCapitalization.words
                : TextCapitalization.none, // Ajout de la capitalisation
        onChanged: (value) {
          if (label == "Email") {
            setState(
                () {}); // Déclenche la reconstruction du widget pour mettre à jour l'erreur
          }
        },
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Color(0xFF08004D),
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.grey),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          errorText: label == "Email" &&
                  controller.text.isNotEmpty &&
                  !_isValidEmail(controller.text)
              ? "Email non valide"
              : null,
          errorStyle: const TextStyle(color: Colors.red),
        ),
      ),
    );
  }

  Widget _buildGooglePlacesInput() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextField(
        controller: _adresseController,
        textCapitalization:
            TextCapitalization.words, // Ajout de la capitalisation
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Color(0xFF08004D),
        ),
        decoration: InputDecoration(
          labelText: "Adresse",
          labelStyle: const TextStyle(color: Colors.grey),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildImageUploader(
      String label, File? imageFile, VoidCallback onTap) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = (constraints.maxWidth - 32) / 2;
        final containerWidth = availableWidth.clamp(120.0, 170.0);
        final containerHeight = containerWidth * 1.3;

        return GestureDetector(
          onTap: onTap,
          child: Stack(
            children: [
              Container(
                width: containerWidth,
                height: containerHeight,
                decoration: BoxDecoration(
                  color: Colors.blueGrey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey),
                ),
                child: imageFile != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          imageFile,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.add_photo_alternate,
                            size: 40,
                            color: Color(0xFF08004D),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              label,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ),
                        ],
                      ),
              ),
              if (imageFile != null)
                Positioned(
                  top: 5,
                  right: 5,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        if (label == "Permis Recto") {
                          _permisRecto = null;
                        } else {
                          _permisVerso = null;
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.red,
                        size: 16,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
