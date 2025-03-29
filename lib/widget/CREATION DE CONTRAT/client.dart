import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../location.dart'; // Import de la page location
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:ContraLoc/USERS/Subscription/abonnement_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ContraLoc/services/collaborateur_util.dart'; // Import de l'utilitaire collaborateur
import 'popup_vehicule_client.dart';

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
  final TextEditingController _prenomController = TextEditingController();
  final TextEditingController _nomController = TextEditingController();
  final TextEditingController _adresseController = TextEditingController();
  final TextEditingController _telephoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _numeroPermisController = TextEditingController();
  final TextEditingController _immatriculationVehiculeClientController = TextEditingController();
  final TextEditingController _kilometrageVehiculeClientController = TextEditingController();

  File? _permisRecto;
  File? _permisVerso;
  bool _showPermisFields = false;
  bool isPremiumUser = false; // Nouvelle propriété

  @override
  void initState() {
    super.initState();
    _initializeSubscription(); // Initialiser et vérifier le statut d'abonnement
    if (widget.contratId != null) {
      _loadClientData();
    }
  }

  // Méthode pour initialiser et vérifier le statut d'abonnement
  Future<void> _initializeSubscription() async {
    // Vérifier le statut premium via CollaborateurUtil
    final isPremium = await CollaborateurUtil.isPremiumUser();
    
    if (mounted) {
      setState(() {
        isPremiumUser = isPremium;
      });
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
            _immatriculationVehiculeClientController.text = data['immatriculationClient'] ?? '';
            _kilometrageVehiculeClientController.text = data['kilometrageClient'] ?? '';
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

  Future<void> _selectImage(ImageSource source, bool isRecto) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 70,
      );
      if (pickedFile != null) {
        final compressedImage = await FlutterImageCompress.compressWithFile(
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
      } else {
        print('Aucune image sélectionnée'); // Log d'erreur
      }
    } catch (e) {
      print('Erreur lors de la sélection de l\'image : $e');
    }
  }

  Future<void> _showImagePickerDialog(bool isRecto) async {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
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
                  leading: const Icon(Icons.photo_camera, color: Color(0xFF08004D)),
                  title: const Text('Prendre une photo'),
                  onTap: () async {
                    await _selectImage(ImageSource.camera, isRecto);
                    Navigator.of(context).pop();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library, color: Color(0xFF08004D)),
                  title: const Text('Choisir depuis la galerie'),
                  onTap: () async {
                    await _selectImage(ImageSource.gallery, isRecto);
                    Navigator.of(context).pop();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(bool isRecto) async {
    try {
      await _showImagePickerDialog(isRecto);
    } catch (e) {
      print('Erreur lors de la sélection de l\'image : $e');
    }
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
              numeroPermis:_numeroPermisController.text,
              immatriculationVehiculeClient: _immatriculationVehiculeClientController.text, // Ajout de numeroPermis
              kilometrageVehiculeClient: _kilometrageVehiculeClientController.text, // Ajout de kilometrage
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

  void _showVehicleDialog() {
    showVehiculeClientDialog(
      context: context,
      immatriculationVehiculeClient: _immatriculationVehiculeClientController.text,
      kilometrageVehiculeClient: _kilometrageVehiculeClientController.text,
      onSave: (immatriculation, kilometrage) {
        setState(() {
          _immatriculationVehiculeClientController.text = immatriculation;
          _kilometrageVehiculeClientController.text = kilometrage;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF08004D),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text("Client"),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Form section
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Informations personnelles",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF08004D),
                    ),
                  ),
                  const SizedBox(height: 16),
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
                  

                  const Text(
                    "Informations du permis",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF08004D),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildTextField("N° Permis", _numeroPermisController),
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
                  
                  const SizedBox(height: 30),
                  ElevatedButton.icon(
                    onPressed: _showVehicleDialog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF000000),
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 2,
                    ),
                    icon: const Icon(
                      Icons.directions_car,
                      color: Colors.white,
                      size: 24,
                    ),
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "Véhicule client",
                          style: TextStyle(
                            color: Colors.white, 
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_immatriculationVehiculeClientController.text.isNotEmpty || 
                            _kilometrageVehiculeClientController.text.isNotEmpty)
                          const Padding(
                            padding: EdgeInsets.only(left: 30),
                            child: Icon(
                              Icons.check_circle,
                              color: Colors.white,
                              size: 25,
                            ),
                          ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: _saveClientInfo,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF08004D),
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 2,
                    ),
                    child: const Text(
                      "Suivant",
                      style: TextStyle(
                        color: Colors.white, 
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
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
