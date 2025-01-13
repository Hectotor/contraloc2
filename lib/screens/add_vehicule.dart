import 'package:ContraLoc/USERS/abonnement_screen.dart';

import '../widget/CREATION DE CONTRAT/client.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path_provider/path_provider.dart';
import '../widget/enregistrer_vehicule.dart';
import '../widget/add_pho_car_atte.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter/cupertino.dart';

class AddVehiculeScreen extends StatefulWidget {
  final String? vehicleId;
  final Map<String, dynamic>? vehicleData;

  const AddVehiculeScreen({Key? key, this.vehicleId, this.vehicleData})
      : super(key: key);

  @override
  State<AddVehiculeScreen> createState() => _AddVehiculeScreenState();
}

class _AddVehiculeScreenState extends State<AddVehiculeScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final TextEditingController _marqueController = TextEditingController();
  final TextEditingController _modeleController = TextEditingController();
  final TextEditingController _immatriculationController =
      TextEditingController();
  final TextEditingController _vinController = TextEditingController();
  final TextEditingController _prixLocationController = TextEditingController();
  final TextEditingController _franchiseController = TextEditingController();
  final TextEditingController _kilometrageSuppController =
      TextEditingController();
  final TextEditingController _rayuresController = TextEditingController();
  final TextEditingController _assuranceNomController = TextEditingController();
  final TextEditingController _assuranceNumeroController =
      TextEditingController(); // New field
  final TextEditingController _entretienDateController =
      TextEditingController();

  String _typeCarburant = "Essence"; // Initialize with a valid value
  String _boiteVitesses = "Manuelle"; // Initialize with a valid value

  XFile? _carPhoto;
  XFile? _carteGrisePhoto;
  XFile? _assurancePhoto;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.vehicleData != null) {
      _marqueController.text = widget.vehicleData!['marque'] ?? '';
      _modeleController.text = widget.vehicleData!['modele'] ?? '';
      _immatriculationController.text =
          widget.vehicleData!['immatriculation'] ?? '';
      _vinController.text = widget.vehicleData!['vin'] ?? '';
      _prixLocationController.text = widget.vehicleData!['prixLocation'] ?? '';
      _franchiseController.text = widget.vehicleData!['franchise'] ?? '';
      _kilometrageSuppController.text =
          widget.vehicleData!['kilometrageSupp'] ?? '';
      _rayuresController.text = widget.vehicleData!['rayures'] ?? '';
      _assuranceNomController.text = widget.vehicleData!['assuranceNom'] ?? '';
      _assuranceNumeroController.text =
          widget.vehicleData!['assuranceNumero'] ?? '';
      _entretienDateController.text =
          widget.vehicleData!['entretienDate'] ?? '';
      _typeCarburant = widget.vehicleData!['typeCarburant'] ?? 'Essence';
      _boiteVitesses = widget.vehicleData!['boiteVitesses'] ?? 'Manuelle';
      // Load images if available
      if (widget.vehicleData!['photoVehiculeUrl'] != null &&
          widget.vehicleData!['photoVehiculeUrl'].isNotEmpty) {
        _carPhoto = XFile(widget.vehicleData!['photoVehiculeUrl']);
      }
      if (widget.vehicleData!['photoCarteGriseUrl'] != null &&
          widget.vehicleData!['photoCarteGriseUrl'].isNotEmpty) {
        _carteGrisePhoto = XFile(widget.vehicleData!['photoCarteGriseUrl']);
      }
      if (widget.vehicleData!['photoAssuranceUrl'] != null &&
          widget.vehicleData!['photoAssuranceUrl'].isNotEmpty) {
        _assurancePhoto = XFile(widget.vehicleData!['photoAssuranceUrl']);
      }
    }
  }

  Future<void> _pickImage(String imageType) async {
    final XFile? selectedImage =
        await showImagePickerDialog(context, imageType);
    if (selectedImage != null) {
      setState(() {
        if (imageType == 'car') {
          _carPhoto = selectedImage;
        } else if (imageType == 'carteGrise') {
          _carteGrisePhoto = selectedImage;
        } else if (imageType == 'assurance') {
          _assurancePhoto = selectedImage;
        }
      });
    }
  }

  Future<String?> _uploadImageToStorage(File imageFile, String folder) async {
    try {
      // Compresser l'image
      final compressedImage = await FlutterImageCompress.compressWithFile(
        imageFile.absolute.path,
        minWidth: 800,
        minHeight: 800,
        quality: 85,
      );

      if (compressedImage == null) {
        print('Erreur lors de la compression de l\'image');
        return null;
      }

      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference storageRef =
          FirebaseStorage.instance.ref().child('$folder/$fileName');

      // Créer un fichier temporaire pour l'image compressée
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/$fileName');
      await tempFile.writeAsBytes(compressedImage);

      await storageRef.putFile(tempFile);
      final downloadUrl = await storageRef.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Erreur upload image: $e');
      return null;
    }
  }

  Future<int> _getUserSubscriptionLimit() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      return doc.data()?['numberOfCars'] ?? 1;
    }
    return 1;
  }

  Future<int> _getUserVehicleCount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('vehicules')
          .where('userId', isEqualTo: user.uid)
          .get();
      return querySnapshot.docs.length;
    }
    return 0;
  }

  Future<void> _saveVehicule() async {
    if (!_formKey.currentState!.validate()) {
      print("Validation échouée. Certains champs requis sont manquants.");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Veuillez remplir tous les champs requis")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (widget.vehicleId == null) {
        // Only check subscription limit for new vehicles
        final subscriptionLimit = await _getUserSubscriptionLimit();
        final vehicleCount = await _getUserVehicleCount();

        if (vehicleCount >= subscriptionLimit) {
          setState(() {
            _isLoading = false;
          });
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 0,
                backgroundColor: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Limite d'abonnement atteinte",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF08004D),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "Votre abonnement ne permet pas d'accéder à plus de véhicules. Vous pouvez soit mettre à jour votre abonnement, soit supprimer des véhicules.",
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.black87,
                        ),
                        //textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (context) => const AbonnementScreen()),
                          );
                        },
                        child: const Text(
                          "Mettre à jour l'abonnement",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF08004D),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
          return;
        }
      }

      print("Début de l'enregistrement du véhicule...");

      String? photoVoitureUrl;
      String? photoCarteGriseUrl;
      String? photoAssuranceUrl;

      // Si on a de nouvelles photos, on les upload
      if (_carPhoto != null) {
        if (!_carPhoto!.path.startsWith('http')) {
          photoVoitureUrl = await _uploadImageToStorage(
              File(_carPhoto!.path), 'vehicules/photos');
        } else {
          photoVoitureUrl = _carPhoto!.path;
        }
      }

      if (_carteGrisePhoto != null) {
        if (!_carteGrisePhoto!.path.startsWith('http')) {
          photoCarteGriseUrl = await _uploadImageToStorage(
              File(_carteGrisePhoto!.path), 'vehicules/documents');
        } else {
          photoCarteGriseUrl = _carteGrisePhoto!.path;
        }
      }

      if (_assurancePhoto != null) {
        if (!_assurancePhoto!.path.startsWith('http')) {
          photoAssuranceUrl = await _uploadImageToStorage(
              File(_assurancePhoto!.path), 'vehicules/assurances');
        } else {
          photoAssuranceUrl = _assurancePhoto!.path;
        }
      }

      final newVehicle = {
        'userId': _auth.currentUser?.uid,
        'marque': _marqueController.text,
        'modele': _modeleController.text,
        'immatriculation': _immatriculationController.text,
        'vin': _vinController.text,
        'typeCarburant': _typeCarburant,
        'boiteVitesses': _boiteVitesses,
        'prixLocation': _prixLocationController.text,
        'franchise': _franchiseController.text,
        'kilometrageSupp': _kilometrageSuppController.text,
        'rayures': _rayuresController.text,
        'assuranceNom': _assuranceNomController.text,
        'assuranceNumero': _assuranceNumeroController.text,
        'entretienDate': _entretienDateController.text,
        // Conserver les URLs existantes si pas de nouvelles photos
        'photoVehiculeUrl':
            photoVoitureUrl ?? widget.vehicleData?['photoVehiculeUrl'] ?? '',
        'photoCarteGriseUrl': photoCarteGriseUrl ??
            widget.vehicleData?['photoCarteGriseUrl'] ??
            '',
        'photoAssuranceUrl':
            photoAssuranceUrl ?? widget.vehicleData?['photoAssuranceUrl'] ?? '',
      };

      if (widget.vehicleId == null) {
        print("Ajout d'un nouveau véhicule...");
        await _firestore.collection('vehicules').add(newVehicle);
        print("Véhicule ajouté avec succès.");
      } else {
        print("Mise à jour d'un véhicule existant...");
        await _firestore
            .collection('vehicules')
            .doc(widget.vehicleId)
            .update(newVehicle);
        print("Véhicule mis à jour avec succès.");
      }

      print("Affichage du popup de confirmation...");
      showEnregistrementPopup(context);
    } catch (e) {
      print("Erreur lors de l'enregistrement du véhicule : $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur lors de l'enregistrement : $e")),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Ajout ici
      appBar: AppBar(
        title: Text(
          widget.vehicleId != null ? "Modifier" : "Ajouter un véhicule",
          style: const TextStyle(
              color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF08004D),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle("Informations générales"),
                  _buildTextField("Marque", _marqueController,
                      isRequired: true),
                  _buildTextField("Modèle", _modeleController,
                      isRequired: true),
                  _buildTextField("Immatriculation", _immatriculationController,
                      isRequired: true),
                  _buildDropdown(
                      "Type de carburant",
                      ["Essence", "Diesel", "Hybride", "Électrique"],
                      _typeCarburant,
                      (value) => setState(() => _typeCarburant = value!)),
                  _buildSectionTitle("Informations techniques"),
                  _buildTextField("Numéro de série (VIN)", _vinController),
                  _buildDropdown(
                      "Type de boîte de vitesses",
                      ["Manuelle", "Automatique", "Semi-automatique"],
                      _boiteVitesses,
                      (value) => setState(() => _boiteVitesses = value!)),
                  _buildSectionTitle("Informations de location"),
                  _buildTextField(
                      "Prix de location par jour (€)", _prixLocationController),
                  _buildTextField(
                      "Montant de la franchise (€)", _franchiseController),
                  _buildTextField("Montant kilométrage supplémentaire (€)",
                      _kilometrageSuppController),
                  _buildTextField(
                      "Montant rayures par élément (€)", _rayuresController),
                  _buildSectionTitle("Assurance et maintenance"),
                  _buildTextField(
                      "Nom de l'assurance", _assuranceNomController),
                  _buildTextField("N° téléphone l'assurance",
                      _assuranceNumeroController), // New field
                  _buildTextField(
                      "Date du prochain entretien", _entretienDateController),
                  _buildSectionTitle("Ajouter des images"),
                  _buildImagePicker("Photo de la voiture", _carPhoto,
                      () => _pickImage('car')),
                  _buildImagePicker("Carte grise", _carteGrisePhoto,
                      () => _pickImage('carteGrise')),
                  _buildImagePicker("Attestation d'assurance", _assurancePhoto,
                      () => _pickImage('assurance')),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _saveVehicule,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF08004D),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text("Enregistrer",
                        style: TextStyle(color: Colors.white, fontSize: 20)),
                  ),
                  const SizedBox(height: 40), // Ajout de la marge en bas
                ],
              ),
            ),
          ),
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
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {bool isRequired = false}) {
    // Vérifier si le champ doit être numérique
    bool isNumericField = [
      "Prix de location par jour (€)",
      "Montant de la franchise (€)",
      "Montant kilométrage supplémentaire (€)",
      "Montant rayures par élément (€)",
      "Numéro de l'assurance"
    ].contains(label);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        keyboardType:
            isNumericField ? TextInputType.number : TextInputType.text,
        inputFormatters: [
          if (isNumericField)
            FilteringTextInputFormatter.allow(RegExp(r'[0-9]'))
          else if (label == "Marque" ||
              label == "Modèle" ||
              label == "Immatriculation" ||
              label == "Numéro de série (VIN)")
            UpperCaseTextFormatter()
        ],
        validator: (value) {
          if (isRequired && (value == null || value.isEmpty)) {
            return "Ce champ est requis";
          }
          if (isNumericField && value != null && value.isNotEmpty) {
            if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
              return "Veuillez entrer uniquement des chiffres";
            }
          }
          return null;
        },
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Color(0xFF08004D)),
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

  Widget _buildDropdown(String label, List<String> items, String value,
      void Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: DropdownButtonFormField<String>(
        value: value,
        items: items
            .map((item) => DropdownMenuItem(
                  value: item,
                  child: Text(item),
                ))
            .toList(),
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Color(0xFF08004D)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF08004D)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF08004D)),
          ),
        ),
        dropdownColor: Colors.white,
        iconEnabledColor: const Color(0xFF08004D),
      ),
    );
  }

  Widget _buildImagePicker(String label, XFile? image, VoidCallback onPick) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 16, color: Color(0xFF08004D))),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: onPick,
            child: Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF08004D)),
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey[200],
              ),
              child: image != null
                  ? image.path.startsWith('http')
                      ? Image.network(
                          image.path,
                          fit: BoxFit.cover,
                        )
                      : Image.file(
                          File(image.path),
                          fit: BoxFit.cover,
                        )
                  : const Icon(Icons.add_a_photo,
                      size: 50, color: Color(0xFF08004D)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Text(
        title,
        style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF08004D)),
      ),
    );
  }
}
