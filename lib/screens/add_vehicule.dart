import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path_provider/path_provider.dart';
import '../ajouter_vehicule/enregistrer_vehicule.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter/cupertino.dart';
import '../ajouter_vehicule/check_vehicle_limit.dart';
import '../widget/CREATION DE CONTRAT/pop_choice_picture.dart';
import '../widget/chargement.dart';

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
  final TextEditingController _cautionController = TextEditingController();
  final TextEditingController _franchiseController = TextEditingController();
  final TextEditingController _kilometrageSuppController =
      TextEditingController();
  final TextEditingController _rayuresController = TextEditingController();
  final TextEditingController _assuranceNomController = TextEditingController();
  final TextEditingController _assuranceNumeroController =
      TextEditingController(); // New field
  final TextEditingController _entretienDateController =
      TextEditingController();
  final TextEditingController _entretienCommentaireController =
      TextEditingController();
  final TextEditingController _carburantManquantController =
      TextEditingController();
  final TextEditingController _nettoyageIntController = TextEditingController();
  final TextEditingController _nettoyageExtController = TextEditingController();

  String _typeCarburant = "Essence"; // Initialize with a valid value
  String _boiteVitesses = "Manuelle"; // Initialize with a valid value

  XFile? _carPhoto;
  XFile? _carteGrisePhoto;
  XFile? _assurancePhoto;
  bool _isLoading = false;
  final Dio dio = Dio();

  Future<bool> _checkCollaboratorPermissions() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      // Vérifier si l'utilisateur est un collaborateur
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data();

      if (userData != null && userData['role'] == 'collaborateur') {
        final String adminId = userData['adminId'];

        // Récupérer les données du collaborateur dans la sous-collection authentification
        final collaboratorDoc = await _firestore
            .collection('users')
            .doc(adminId)
            .collection('authentification')
            .doc(user.uid)
            .get();
        
        if (!collaboratorDoc.exists) {
          print('⚠️ Document collaborateur manquant, création...');
          // Créer le document du collaborateur avec toutes les permissions
          await _firestore
              .collection('users')
              .doc(adminId)
              .collection('authentification')
              .doc(user.uid) .set({
            'id': user.uid,
            'role': 'collaborateur',
            'adminId': adminId,
            'permissions': {
              'lecture': true,
              'ecriture': true,
              'suppression': true
            },
            // Hériter les limites de l'admin selon les MEMORIES
            'limiteContrat': userData['limiteContrat'] ?? 10,
            'numberOfCars': userData['numberOfCars'] ?? 1,
            'subscriptionId': userData['subscriptionId'],
            'cb_limite_contrat': userData['cb_limite_contrat'] ?? 10,
            'cb_nb_car': userData['cb_nb_car'] ?? 1,
            'cb_subscription': userData['cb_subscription'],
            'dateCreation': FieldValue.serverTimestamp(),
          });
          print('✅ Document collaborateur créé avec succès');
          return true;
        }

        final permissions = collaboratorDoc.data()?['permissions'] ?? {};
        final bool canWrite = permissions['ecriture'] ?? false;

        if (!canWrite) {
          print('⚠️ Permissions manquantes, ajout des permissions...');
          // Donner toutes les permissions au collaborateur et mettre à jour les limites
          await _firestore
              .collection('users')
              .doc(adminId)
              .collection('authentification')
              .doc(user.uid).set({
            'permissions': {
              'lecture': true,
              'ecriture': true,
              'suppression': true
            },
            // Hériter les limites de l'admin selon les MEMORIES
            'limiteContrat': userData['limiteContrat'] ?? 10,
            'numberOfCars': userData['numberOfCars'] ?? 1,
            'subscriptionId': userData['subscriptionId'],
            'cb_limite_contrat': userData['cb_limite_contrat'] ?? 10,
            'cb_nb_car': userData['cb_nb_car'] ?? 1,
            'cb_subscription': userData['cb_subscription'],
          }, SetOptions(merge: true));
          print('✅ Permissions et limites ajoutées avec succès');
          return true;
        }
        return true;
      }
      return true; // Si ce n'est pas un collaborateur, autoriser l'accès
    } catch (e) {
      print('❌ Erreur vérification permissions: $e');
      return false;
    }
  }

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
      _cautionController.text = widget.vehicleData!['caution'] ?? '';
      _franchiseController.text = widget.vehicleData!['franchise'] ?? '';
      _kilometrageSuppController.text =
          widget.vehicleData!['kilometrageSupp'] ?? '';
      _rayuresController.text = widget.vehicleData!['rayures'] ?? '';
      _assuranceNomController.text = widget.vehicleData!['assuranceNom'] ?? '';
      _assuranceNumeroController.text =
          widget.vehicleData!['assuranceNumero'] ?? '';
      _entretienDateController.text =
          widget.vehicleData!['entretienDate'] ?? '';
      _entretienCommentaireController.text =
          widget.vehicleData!['entretienCommentaire'] ?? '';
      _typeCarburant = widget.vehicleData!['typeCarburant'] ?? 'Essence';
      _boiteVitesses = widget.vehicleData!['boiteVitesses'] ?? 'Manuelle';
      _nettoyageIntController.text = widget.vehicleData!['nettoyageInt'] ?? '';
      _nettoyageExtController.text = widget.vehicleData!['nettoyageExt'] ?? '';
      _carburantManquantController.text =
          widget.vehicleData!['carburantManquant'] ?? '';
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
    final File? selectedImage = await ImagePickerDialog.showImagePickerDialog(
      context,
      imageQuality: 70,
      compressWidth: 800,
      compressHeight: 800,
      compressQuality: 85,
    );
    if (selectedImage != null) {
      setState(() {
        if (imageType == 'car') {
          _carPhoto = XFile(selectedImage.path);
        } else if (imageType == 'carteGrise') {
          _carteGrisePhoto = XFile(selectedImage.path);
        } else if (imageType == 'assurance') {
          _assurancePhoto = XFile(selectedImage.path);
        }
      });
    }
  }

  Future<String> _getTargetUserId() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User not authenticated");

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final userData = userDoc.data();

    if (userData != null && userData['role'] == 'collaborateur') {
      print(' Sauvegarde dans le compte admin');
      return userData['adminId'];
    } else {
      print(' Sauvegarde dans le compte utilisateur');
      return user.uid;
    }
  }

  Future<String?> _uploadImageToStorage(File imageFile, String imageType) async {
    try {
      final compressedImage = await FlutterImageCompress.compressWithFile(
        imageFile.absolute.path,
        minWidth: 800,
        minHeight: 800,
        quality: 85,
      );

      if (compressedImage == null) {
        throw Exception('Image compression failed');
      }

      final targetUserId = await _getTargetUserId();
      final fileName = '${imageType}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Vérifier si c'est un collaborateur
      final user = _auth.currentUser;
      if (user == null) throw Exception("User not authenticated");
      
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data();
      final isCollaborateur = userData != null && userData['role'] == 'collaborateur';

      print('Utilisateur actuel : ${user.uid}');
      print('Rôle de l\'utilisateur : ${userData?['role']}');
      print('ID de l\'admin : ${userData?['adminId']}');

      // Construire le chemin de stockage en utilisant l'ID du collaborateur pour sa sous-collection
      final storagePath = isCollaborateur
          ? 'users/$targetUserId/authentification/${user.uid}/vehicules/${_immatriculationController.text}/$fileName'
          : 'users/$targetUserId/vehicules/${_immatriculationController.text}/$fileName';

      print('📁 Upload vers: $storagePath');
      final storageRef = FirebaseStorage.instance.ref().child(storagePath);

      // Create temporary file for compressed image
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/$fileName');
      await tempFile.writeAsBytes(compressedImage);

      final uploadTask = storageRef.putFile(tempFile);
      await uploadTask.timeout(const Duration(seconds: 30));

      return await storageRef.getDownloadURL();
    } catch (e) {
      print(' Erreur upload image: $e');
      rethrow;
    }
  }

  Future<void> _moveStorageFiles(String oldImmat, String newImmat) async {
    try {
      final targetUserId = await _getTargetUserId();

      // Vérifier si c'est un collaborateur
      final user = _auth.currentUser;
      if (user == null) throw Exception("User not authenticated");
      
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data();
      final isCollaborateur = userData != null && userData['role'] == 'collaborateur';

      // Structure des URLs des photos
      final oldPhotos = {
        'vehicule': widget.vehicleData?['photoVehiculeUrl'],
        'carte_grise': widget.vehicleData?['photoCarteGriseUrl'],
        'assurance': widget.vehicleData?['photoAssuranceUrl'],
      };

      Map<String, String> newUrls = {};

      // Construire le chemin de base en utilisant l'ID du collaborateur pour sa sous-collection
      final basePath = isCollaborateur
          ? 'users/$targetUserId/authentification/${user.uid}/vehicules'
          : 'users/$targetUserId/vehicules';

      for (var entry in oldPhotos.entries) {
        String? oldUrl = entry.value;
        if (oldUrl != null && oldUrl.isNotEmpty) {
          // Créer un nouveau nom de fichier
          final fileName = '${entry.key}_${DateTime.now().millisecondsSinceEpoch}.jpg';

          // Télécharger l'image depuis l'URL
          final response = await dio.get(oldUrl,
              options: Options(responseType: ResponseType.bytes));
          final imageBytes = response.data;

          print('📁 Déplacement du fichier vers: $basePath/$newImmat/$fileName');

          // Créer une nouvelle référence dans le storage
          final newRef = FirebaseStorage.instance
              .ref()
              .child('$basePath/$newImmat/$fileName');

          // Upload the new file
          await newRef.putData(imageBytes);
          final newUrl = await newRef.getDownloadURL();
          newUrls[entry.key] = newUrl;

          // Delete the old file if it exists
          if (oldUrl.contains('firebase')) {
            try {
              final oldRef = FirebaseStorage.instance
                  .ref()
                  .child('$basePath/$oldImmat/${entry.key}');
              await oldRef.delete();
              print('📁 Fichier supprimé avec succès: $oldRef');
            } catch (e) {
              print('Warning: Could not delete old file: $e');
            }
          }
        }
      }

      // Update the vehicle document with new URLs
      if (newUrls.isNotEmpty) {
        await _firestore
            .collection('users')
            .doc(targetUserId)
            .collection('vehicules')
            .doc(widget.vehicleId)
            .update({
          if (newUrls['vehicule'] != null)
            'photoVehiculeUrl': newUrls['vehicule'],
          if (newUrls['carte_grise'] != null)
            'photoCarteGriseUrl': newUrls['carte_grise'],
          if (newUrls['assurance'] != null)
            'photoAssuranceUrl': newUrls['assurance'],
        });
      }
    } catch (e) {
      print(' Erreur déplacement fichiers: $e');
      rethrow;
    }
  }

  Future<void> _saveVehicule() async {
    // Vérifier les permissions si c'est un collaborateur
    final hasPermission = await _checkCollaboratorPermissions();
    if (!hasPermission) return;

    // Vérifier la limite de véhicules avant de sauvegarder
    final vehicleLimitChecker = VehicleLimitChecker(context);
    final canAddVehicle = await vehicleLimitChecker.checkVehicleLimit(isUpdating: widget.vehicleId != null);
    if (!canAddVehicle) return;

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final targetUserId = await _getTargetUserId();

      // Upload images if they exist
      String? photoVehiculeUrl;
      String? photoCarteGriseUrl;
      String? photoAssuranceUrl;

      if (_carPhoto != null) {
        photoVehiculeUrl = await _uploadImageToStorage(File(_carPhoto!.path), 'car');
      }
      if (_carteGrisePhoto != null) {
        photoCarteGriseUrl = await _uploadImageToStorage(File(_carteGrisePhoto!.path), 'carteGrise');
      }
      if (_assurancePhoto != null) {
        photoAssuranceUrl = await _uploadImageToStorage(File(_assurancePhoto!.path), 'assurance');
      }

      final vehicleData = {
        'marque': _marqueController.text,
        'modele': _modeleController.text,
        'immatriculation': _immatriculationController.text,
        'vin': _vinController.text,
        'prixLocation': _prixLocationController.text,
        'caution': _cautionController.text,
        'franchise': _franchiseController.text,
        'kilometrageSupp': _kilometrageSuppController.text,
        'rayures': _rayuresController.text,
        'assuranceNom': _assuranceNomController.text,
        'assuranceNumero': _assuranceNumeroController.text,
        'entretienDate': _entretienDateController.text,
        'entretienCommentaire': _entretienCommentaireController.text,
        'typeCarburant': _typeCarburant,
        'boiteVitesses': _boiteVitesses,
        'nettoyageInt': _nettoyageIntController.text,
        'nettoyageExt': _nettoyageExtController.text,
        'carburantManquant': _carburantManquantController.text,
        'dateCreation': FieldValue.serverTimestamp(),
      };

      if (photoVehiculeUrl != null) {
        vehicleData['photoVehiculeUrl'] = photoVehiculeUrl;
      }
      if (photoCarteGriseUrl != null) {
        vehicleData['photoCarteGriseUrl'] = photoCarteGriseUrl;
      }
      if (photoAssuranceUrl != null) {
        vehicleData['photoAssuranceUrl'] = photoAssuranceUrl;
      }

      if (widget.vehicleId != null) {
        // Update existing vehicle
        if (_immatriculationController.text != widget.vehicleData!['immatriculation']) {
          await _moveStorageFiles(
              widget.vehicleData!['immatriculation'], _immatriculationController.text);
        }
      }

      // Vérifier si c'est un collaborateur
      final user = _auth.currentUser;
      if (user == null) throw Exception("User not authenticated");
      
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data();
      
      // Ajouter l'ID du collaborateur aux données du véhicule si c'est un collaborateur
      if (userData != null && userData['role'] == 'collaborateur') {
        vehicleData['collaborateurId'] = user.uid;
      }

      print('👤 Utilisateur: ${user.uid}');
      print('🔑 Rôle: ${userData?['role']}');
      print('👥 Admin ID: ${userData?['adminId']}');

      // Toujours sauvegarder dans la collection vehicules de l'admin
      final vehiculesRef = _firestore
          .collection('users')
          .doc(targetUserId)
          .collection('vehicules');

      print('📁 Collection path: ${vehiculesRef.path}');
      print('🚗 Immatriculation: ${_immatriculationController.text}');
      print('📄 Données du véhicule: $vehicleData');

      // Save vehicle
      if (widget.vehicleId != null) {
        // Update
        await vehiculesRef.doc(widget.vehicleId).update(vehicleData);
        print('✅ Véhicule mis à jour avec succès');
      } else {
        // Add new
        try {
          await vehiculesRef.doc(_immatriculationController.text).set(vehicleData);
          print('✅ Nouveau véhicule ajouté avec succès dans ${vehiculesRef.path}/${_immatriculationController.text}');
        } catch (e) {
          print('❌ Erreur lors de l\'ajout du véhicule: $e');
          rethrow;
        }
      }
      
      showEnregistrementPopup(context);
    } catch (e) {
      print(' Erreur sauvegarde véhicule: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
                    "Prix de location par jour (€)",
                    _prixLocationController,
                    keyboardType:
                        TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[\d,\.]')),
                    ],
                  ),
                  _buildTextField(
                    "Caution (€)",
                    _cautionController,
                    keyboardType:
                        TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[\d,\.]')),
                    ],
                  ),
                  _buildTextField(
                    "Franchise (€)",
                    _franchiseController,
                    keyboardType:
                        TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[\d,\.]')),
                    ],
                  ),
                  _buildTextField(
                    "Kilométrage supplémentaire (€)",
                    _kilometrageSuppController,
                    isRequired: true,
                    keyboardType:
                        TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[\d,\.]')),
                    ],
                  ),
                  _buildTextField(
                    "Carburant manquant (€)",
                    _carburantManquantController,
                    isRequired: true,
                    keyboardType:
                        TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[\d,\.]')),
                    ],
                  ),
                  _buildTextField(
                    "Frais de nettoyage intérieur (€)",
                    _nettoyageIntController,
                    isRequired: true,
                    keyboardType:
                        TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[\d,\.]')),
                    ],
                  ),
                  _buildTextField(
                    "Frais de nettoyage extérieur (€)",
                    _nettoyageExtController,
                    isRequired: true,
                    keyboardType:
                        TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[\d,\.]')),
                    ],
                  ),
                  _buildTextField(
                    "Rayures par élément (€)",
                    _rayuresController,
                    keyboardType:
                        TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[\d,\.]')),
                    ],
                  ),
                  _buildSectionTitle("Assurance et maintenance"),
                  _buildTextField(
                      "Nom de l'assurance", _assuranceNomController),
                  _buildTextField("N° téléphone l'assurance",
                      _assuranceNumeroController), // New field
                  _buildTextField(
                      "Date du prochain entretien", _entretienDateController),
                  _buildTextField(
                      "Commentaire sur l'entretien", _entretienCommentaireController,
                      keyboardType: TextInputType.multiline,
                      maxLines: 3),
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
                    ),
                    child: Text(
                      'Enregistrer',
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40), // Ajout de la marge en bas
                ],
              ),
            ),
          ),
          if (_isLoading)
            const Chargement(message: "Enregistrement du véhicule en cours..."),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {bool isRequired = false,
      TextInputType? keyboardType,
      List<TextInputFormatter>? inputFormatters,
      int? maxLines}) {
    // Déterminer le type de clavier et les icônes spécifiques
    Widget? suffixIcon;

    if ([
      "Prix de location par jour (€)",
      "Caution (€)",
      "Franchise (€)",
      "Kilométrage supplémentaire (€)",
      "Rayures par élément (€)",
      "N° téléphone l'assurance",
      "Carburant manquant (€)",
      "Frais de nettoyage intérieur (€)",
      "Frais de nettoyage extérieur (€)"
    ].contains(label)) {
      keyboardType = keyboardType ?? TextInputType.number;
      suffixIcon = IconButton(
        icon: Icon(Icons.check_circle,
            color: Colors.grey[400]), // Couleur plus claire
        onPressed: () {
          FocusScope.of(context).unfocus();
        },
      );
    }

    // Configuration spéciale pour le numéro de téléphone de l'assurance
    if (label == "N° téléphone l'assurance") {
      keyboardType = TextInputType.phone;
    }

    // Configuration spéciale pour la date d'entretien
    if (label == "Date du prochain entretien") {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: TextFormField(
          controller: controller,
          readOnly: true,
          onTap: () async {
            final pickedDate = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime.now(),
              lastDate: DateTime(2100),
              locale: const Locale('fr', 'FR'),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.light(
                      primary: Color(0xFF08004D),
                      onPrimary: Colors.white,
                      surface: Colors.white,
                      onSurface: Color(0xFF08004D),
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (pickedDate != null) {
              setState(() {
                controller.text = pickedDate.toLocal().toString().split(' ')[0];
              });
            }
          },
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(color: Color(0xFF08004D)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            suffixIcon: Icon(Icons.calendar_today,
                color: Colors.grey[400]), // Couleur plus claire
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines ?? 1,
        textCapitalization: TextCapitalization
            .sentences, // Majuscule uniquement au début des phrases pour les commentaires
        inputFormatters: inputFormatters ??
            [
              // Ne pas appliquer le formateur pour les champs numériques et commentaires
              if (keyboardType != TextInputType.number &&
                  keyboardType != TextInputType.phone &&
                  keyboardType != TextInputType.multiline &&
                  label != "Date du prochain entretien")
                UpperCaseTextFormatter(),
            ],
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Color(0xFF08004D)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          suffixIcon: suffixIcon,
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
              ),
              child: ClipRRect(
                // Ajout du ClipRRect pour arrondir l'image
                borderRadius: BorderRadius.circular(12),
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
                        size: 50, color: Color.fromARGB(152, 8, 0, 77)),
              ),
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
