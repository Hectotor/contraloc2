import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../services/collaborateur_util.dart';
import 'package:flutter/services.dart';
import '../widget/take_picture.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../ajouter_vehicule/enregistrer_vehicule.dart';
import '../ajouter_vehicule/check_vehicle_limit.dart';

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

  const AddVehiculeScreen({
    Key? key,
    this.vehicleId,
    this.vehicleData,
  }) : super(key: key);

  @override
  _AddVehiculeScreenState createState() => _AddVehiculeScreenState();
}

class _AddVehiculeScreenState extends State<AddVehiculeScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  bool _isLoading = false;
  bool _showTechnicalInfo = false;
  bool _showLocationInfo = false;
  bool _showSupplementaryFees = false;
  bool _showInsuranceMaintenance = false;
  bool _showGeneralInfo = true;
  bool _showDocuments = false;

  // Contrôleurs pour les champs de texte
  final TextEditingController _marqueController = TextEditingController();
  final TextEditingController _modeleController = TextEditingController();
  final TextEditingController _immatriculationController = TextEditingController();
  final TextEditingController _vinController = TextEditingController();
  final TextEditingController _prixLocationController = TextEditingController();
  final TextEditingController _cautionController = TextEditingController();
  final TextEditingController _franchiseController = TextEditingController();
  final TextEditingController _kilometrageSuppController = TextEditingController();
  final TextEditingController _rayuresController = TextEditingController();
  final TextEditingController _assuranceNomController = TextEditingController();
  final TextEditingController _assuranceNumeroController = TextEditingController();
  final TextEditingController _entretienDateController = TextEditingController();
  final TextEditingController _entretienKilometrageController = TextEditingController(); // Nouveau contrôleur pour le kilométrage d'entretien
  final TextEditingController _entretienNotesController = TextEditingController(); // Nouveau contrôleur pour les notes d'entretien
  final TextEditingController _carburantManquantController = TextEditingController();
  final TextEditingController _nettoyageIntController = TextEditingController();
  final TextEditingController _nettoyageExtController = TextEditingController();

  String _typeCarburant = "Essence"; 
  String _boiteVitesses = "Manuelle"; 

  // Variables pour les images
  XFile? _carPhoto;
  XFile? _carteGrisePhoto;
  XFile? _assurancePhoto;

  @override
  void initState() {
    super.initState();
    _showTechnicalInfo = false;
    _showLocationInfo = false;
    _showSupplementaryFees = false;
    _showInsuranceMaintenance = false;
    _showDocuments = false;
    _showGeneralInfo = true;
    if (widget.vehicleData != null) {
      _loadVehicleData();
    }
  }

  void _loadVehicleData() {
    final data = widget.vehicleData!;
    _marqueController.text = data['marque'] ?? '';
    _modeleController.text = data['modele'] ?? '';
    _immatriculationController.text = data['immatriculation'] ?? '';
    _vinController.text = data['vin'] ?? '';
    _prixLocationController.text = data['prixLocation'] ?? '';
    _cautionController.text = data['caution'] ?? '';
    _franchiseController.text = data['franchise'] ?? '';
    _kilometrageSuppController.text = data['kilometrageSupp'] ?? '';
    _rayuresController.text = data['rayures'] ?? '';
    _assuranceNomController.text = data['assuranceNom'] ?? '';
    _assuranceNumeroController.text = data['assuranceNumero'] ?? '';
    _entretienDateController.text = data['entretienDate'] ?? '';
    _entretienKilometrageController.text = data['entretienKilometrage'] ?? ''; // Initialiser avec les données existantes
    _entretienNotesController.text = data['entretienNotes'] ?? ''; // Initialiser avec les données existantes
    _typeCarburant = data['typeCarburant'] ?? 'Essence';
    _boiteVitesses = data['boiteVitesses'] ?? 'Manuelle';
    _nettoyageIntController.text = data['nettoyageInt'] ?? '';
    _nettoyageExtController.text = data['nettoyageExt'] ?? '';
    _carburantManquantController.text = data['carburantManquant'] ?? '';

    if (data['photoVehiculeUrl'] != null && data['photoVehiculeUrl'].isNotEmpty) {
      _carPhoto = XFile(data['photoVehiculeUrl']);
    }
    if (data['photoCarteGriseUrl'] != null && data['photoCarteGriseUrl'].isNotEmpty) {
      _carteGrisePhoto = XFile(data['photoCarteGriseUrl']);
    }
    if (data['photoAssuranceUrl'] != null && data['photoAssuranceUrl'].isNotEmpty) {
      _assurancePhoto = XFile(data['photoAssuranceUrl']);
    }
  }

  Future<void> _pickImage(String imageType) async {
    // Utilisation de la fonction globale showImagePickerDialog du fichier take_picture.dart
    final XFile? selectedImage = await showImagePickerDialog(context, imageType);
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

  Future<String?> _uploadImageToStorage(File imageFile, String imageType) async {
    try {
      // Vérifier le statut du collaborateur
      final status = await CollaborateurUtil.checkCollaborateurStatus();
      final userId = status['userId'];
      
      if (userId == null) {
        print("🔴 Erreur: Utilisateur non connecté");
        throw Exception("Utilisateur non connecté");
      }
      
      // Déterminer l'ID à utiliser (admin ou collaborateur)
      final targetId = status['isCollaborateur'] ? status['adminId'] : userId;
      
      if (targetId == null) {
        print("🔴 Erreur: ID cible non disponible");
        throw Exception("ID cible non disponible");
      }
      
      print("📝 Téléchargement d'image par ${status['isCollaborateur'] ? 'collaborateur' : 'admin'}");
      print("📝 userId: $userId, targetId (adminId): $targetId");
      
      // Vérifier les permissions d'écriture pour les collaborateurs
      if (status['isCollaborateur'] == true) {
        final hasWritePermission = await CollaborateurUtil.checkCollaborateurPermission('ecriture');
        print("🔑 Permission d'écriture pour le collaborateur: ${hasWritePermission ? 'OUI' : 'NON'}");
        
        if (!hasWritePermission) {
          print("🔴 Erreur: Permission d'écriture refusée pour ce collaborateur");
          throw Exception("Permission d'écriture refusée pour ce collaborateur");
        }
      }
      
      // Compresser l'image avant de la télécharger
      final Uint8List imageBytes = await imageFile.readAsBytes();
      final Uint8List compressedBytes = await FlutterImageCompress.compressWithList(
        imageBytes,
        minHeight: 1024, // Hauteur maximale
        minWidth: 1024,  // Largeur maximale
        quality: 70,     // Qualité de compression (0-100)
      );
      
      final fileName = '${imageType}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final immatriculation = _immatriculationController.text.isEmpty 
          ? 'temp_${DateTime.now().millisecondsSinceEpoch}' 
          : _immatriculationController.text;
      
      // Toujours stocker dans le dossier de l'administrateur
      // Cela garantit que les collaborateurs peuvent accéder aux fichiers avec les bonnes permissions
      final String storagePath = 'users/${targetId}/vehicules/${immatriculation}/${fileName}';
      print("📁 Chemin de stockage: $storagePath");
          
      final storageRef = _storage.ref().child(storagePath);
      
      // Préparer les métadonnées
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'uploaded_by': userId,
          'owner': targetId,
          'timestamp': DateTime.now().toString(),
          'collaborator': status['isCollaborateur'] == true ? 'true' : 'false'
        }
      );
      print("📋 Métadonnées: ${metadata.customMetadata}");

      // Télécharger les données compressées
      print("⏳ Début du téléchargement...");
      final uploadTask = storageRef.putData(compressedBytes, metadata);
      
      // Surveiller la progression du téléchargement
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
        print("📊 Progression: ${progress.toStringAsFixed(1)}%");
      });
      
      await uploadTask.timeout(const Duration(seconds: 60));
      print("✅ Téléchargement terminé avec succès");

      // Obtenir l'URL de téléchargement
      return await storageRef.getDownloadURL();
    } catch (e) {
      print('🔴 Erreur détaillée lors du téléchargement de l\'image: $e');
      if (e.toString().contains('unauthorized')) {
        print('🔐 Problème d\'autorisation: Vérifiez les règles de sécurité Firebase Storage');
        print('🔐 Vérifiez que le collaborateur a la permission "ecriture" dans la collection "authentification"');
      }
      rethrow;
    }
  }

  Future<void> _saveVehicule() async {
    if (!_formKey.currentState!.validate()) {
      print("Validation échouée. Certains champs requis sont manquants.");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez remplir tous les champs requis")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Vérifier le statut du collaborateur
      final status = await CollaborateurUtil.checkCollaborateurStatus();
      final userId = status['userId'];
      
      if (userId == null) {
        throw Exception("Utilisateur non connecté");
      }
      
      // Déterminer l'ID à utiliser (admin ou collaborateur)
      final targetId = status['isCollaborateur'] ? status['adminId'] : userId;
      
      if (targetId == null) {
        throw Exception("ID cible non disponible");
      }
      
      // Vérifier les permissions si c'est un collaborateur
      if (status['isCollaborateur']) {
        // Vérifier si le collaborateur a la permission d'écriture
        final hasWritePermission = await CollaborateurUtil.checkCollaborateurPermission('ecriture');
        if (!hasWritePermission) {
          throw Exception("Vous n'avez pas la permission de modifier les véhicules");
        }
      }

      if (widget.vehicleId == null && _immatriculationController.text.isEmpty) {
        throw Exception("L'immatriculation est requise");
      }

      // Vérifier si un véhicule avec cette immatriculation existe déjà
      if (widget.vehicleId == null) {
        final existingDoc = await _firestore
            .collection('users')
            .doc(targetId)
            .collection('vehicules')
            .where('immatriculation', isEqualTo: _immatriculationController.text)
            .get();

        if (existingDoc.docs.isNotEmpty) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Un véhicule avec cette immatriculation existe déjà")),
            );
          }
          setState(() => _isLoading = false);
          return;
        }

        // Vérifier la limite de véhicules pour les nouveaux véhicules uniquement
        print("🚗 Vérification de la limite de véhicules...");
        final vehicleLimitChecker = VehicleLimitChecker(context);
        final canAddVehicle = await vehicleLimitChecker.checkVehicleLimit();
        
        if (!canAddVehicle) {
          print("⚠️ Limite de véhicules atteinte. Impossible d'ajouter un nouveau véhicule.");
          setState(() => _isLoading = false);
          return;
        }
        print("👍 Limite de véhicules OK. Poursuite de l'enregistrement.");

        final docId = _immatriculationController.text;
        final vehicleRef = await _getVehicleDocRef(docId);

        final vehicleData = await _prepareVehicleData();
        await vehicleRef.set(vehicleData);

        if (context.mounted) {
          showEnregistrementPopup(context);
        }
      } else {
        final docId = widget.vehicleId ?? _immatriculationController.text;
        final vehicleRef = await _getVehicleDocRef(docId);

        final vehicleData = await _prepareVehicleData();
        await vehicleRef.set(vehicleData, SetOptions(merge: true));
        
        if (context.mounted) {
          showEnregistrementPopup(context);
        }
      }
    } catch (e) {
      print("Erreur lors de l'enregistrement du véhicule : $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Impossible d'enregistrer le véhicule: $e")),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<Map<String, dynamic>> _prepareVehicleData() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User not authenticated");

    String? photoVoitureUrl;
    String? photoCarteGriseUrl;
    String? photoAssuranceUrl;

    // Upload des images si elles ont été sélectionnées
    if (_carPhoto != null && !_carPhoto!.path.startsWith('http')) {
      photoVoitureUrl = await _uploadImageToStorage(File(_carPhoto!.path), 'vehicule');
    } else {
      photoVoitureUrl = widget.vehicleData?['photoVehiculeUrl'];
    }

    if (_carteGrisePhoto != null && !_carteGrisePhoto!.path.startsWith('http')) {
      photoCarteGriseUrl = await _uploadImageToStorage(File(_carteGrisePhoto!.path), 'carte_grise');
    } else {
      photoCarteGriseUrl = widget.vehicleData?['photoCarteGriseUrl'];
    }

    if (_assurancePhoto != null && !_assurancePhoto!.path.startsWith('http')) {
      photoAssuranceUrl = await _uploadImageToStorage(File(_assurancePhoto!.path), 'assurance');
    } else {
      photoAssuranceUrl = widget.vehicleData?['photoAssuranceUrl'];
    }

    // Préparer les données du véhicule
    Map<String, dynamic> vehicleData = {
      'userId': user.uid,
      'marque': _marqueController.text,
      'modele': _modeleController.text,
      'immatriculation': _immatriculationController.text,
      'vin': _vinController.text,
      'typeCarburant': _typeCarburant,
      'boiteVitesses': _boiteVitesses,
      'prixLocation': _prixLocationController.text,
      'caution': _cautionController.text,
      'franchise': _franchiseController.text,
      'kilometrageSupp': _kilometrageSuppController.text,
      'rayures': _rayuresController.text, // Ajout de rayures pour cohérence avec le PDF
      'assuranceNom': _assuranceNomController.text,
      'assuranceNumero': _assuranceNumeroController.text,
      'entretienDate': _entretienDateController.text,
      'entretienKilometrage': _entretienKilometrageController.text,
      'entretienNotes': _entretienNotesController.text, // Ajouter les notes d'entretien
      'nettoyageInt': _nettoyageIntController.text,
      'nettoyageExt': _nettoyageExtController.text,
      'carburantManquant': _carburantManquantController.text,
      'dateCreation': widget.vehicleData != null && widget.vehicleData!['dateCreation'] != null
          ? widget.vehicleData!['dateCreation']
          : FieldValue.serverTimestamp(),
      'dateModification': FieldValue.serverTimestamp(),
      'photoVehiculeUrl': photoVoitureUrl ?? '',
      'photoCarteGriseUrl': photoCarteGriseUrl ?? '',
      'photoAssuranceUrl': photoAssuranceUrl ?? '',
    };
    
    return vehicleData;
  }

  Future<DocumentReference> _getVehicleDocRef(String docId) async {
    // Vérifier le statut du collaborateur
    final status = await CollaborateurUtil.checkCollaborateurStatus();
    final userId = status['userId'];
    
    if (userId == null) {
      throw Exception("Utilisateur non connecté");
    }
    
    // Déterminer l'ID à utiliser (admin ou collaborateur)
    final targetId = status['isCollaborateur'] ? status['adminId'] : userId;
    
    if (targetId == null) {
      throw Exception("ID cible non disponible");
    }
    
    return _firestore
        .collection('users')
        .doc(targetId)
        .collection('vehicules')
        .doc(docId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          widget.vehicleId != null ? "Modifier le véhicule" : "Ajouter un véhicule",
          style: const TextStyle(
              color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF08004D),
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // En-tête avec description
                    _buildHeader(),
                    const SizedBox(height: 24),
                    
                    // Section informations générales
                    _buildSection(
                      title: "Informations générales",
                      icon: Icons.info_outline,
                      color: const Color(0xFF1A237E),
                      isGeneralInfo: true,
                      children: [
                        _buildTextField("Marque", _marqueController, isRequired: true),
                        _buildTextField("Modèle", _modeleController, isRequired: true),
                        _buildTextField("Immatriculation", _immatriculationController, isRequired: true),
                        _buildDropdown(
                          "Type de boîte de vitesses",
                          ["Manuelle", "Automatique", "Semi-automatique"],
                          _boiteVitesses,
                          (value) => setState(() => _boiteVitesses = value!)),
                        _buildDropdown(
                          "Type de carburant",
                          ["Essence", "Diesel", "Hybride", "Électrique"],
                          _typeCarburant,
                          (value) => setState(() => _typeCarburant = value!)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Section informations techniques
                    _buildSection(
                      title: "Informations techniques",
                      icon: Icons.build_outlined,
                      color: Colors.orange[700]!,
                      isTechnicalInfo: true,
                      children: [
                        _buildTextField("Numéro de série (VIN)", _vinController),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Section informations de location
                    _buildSection(
                      title: "Informations de location",
                      icon: Icons.euro_outlined,
                      color: Colors.green[700]!,
                      isLocationInfo: true,
                      children: [
                        _buildTextField(
                          "Prix de location par jour (€)",
                          _prixLocationController,
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[\d,\.]')),
                          ],
                        ),
                        _buildTextField(
                          "Caution (€)",
                          _cautionController,
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[\d,\.]')),
                          ],
                        ),
                        _buildTextField(
                          "Franchise (€)",
                          _franchiseController,
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[\d,\.]')),
                          ],
                        ),
                        _buildTextField(
                          "Kilométrage supplémentaire (€)",
                          _kilometrageSuppController,
                          isRequired: true,
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[\d,\.]')),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Section frais supplémentaires
                    _buildSection(
                      title: "Frais supplémentaires",
                      icon: Icons.attach_money_outlined,
                      color: Colors.red[700]!,
                      isSupplementaryFees: true,
                      children: [
                        _buildTextField(
                          "Carburant manquant (€)",
                          _carburantManquantController,
                          isRequired: true,
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[\d,\.]')),
                          ],
                        ),
                        _buildTextField(
                          "Frais de nettoyage intérieur (€)",
                          _nettoyageIntController,
                          isRequired: true,
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[\d,\.]')),
                          ],
                        ),
                        _buildTextField(
                          "Frais de nettoyage extérieur (€)",
                          _nettoyageExtController,
                          isRequired: true,
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[\d,\.]')),
                          ],
                        ),
                        _buildTextField(
                          "Rayures par élément (€)",
                          _rayuresController,
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[\d,\.]')),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Section assurance et maintenance
                    _buildSection(
                      title: "Assurance et maintenance",
                      icon: Icons.security_outlined,
                      color: Colors.blue[700]!,
                      isInsuranceMaintenance: true,
                      children: [
                        _buildTextField("Nom de l'assurance", _assuranceNomController),
                        _buildTextField("N° téléphone l'assurance", _assuranceNumeroController),
                        _buildTextField("Date du prochain entretien", _entretienDateController),
                        _buildTextField("Kilométrage du prochain entretien", _entretienKilometrageController),
                        _buildNotesField("Notes d'entretien", _entretienNotesController),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Section images
                    _buildSection(
                      title: "Documents et photos",
                      icon: Icons.photo_camera_outlined,
                      color: Colors.purple[700]!,
                      isDocuments: true,
                      children: [
                        _buildImagePicker("Photo de la voiture", _carPhoto, () => _pickImage('car')),
                        _buildImagePicker("Carte grise", _carteGrisePhoto, () => _pickImage('carteGrise')),
                        _buildImagePicker("Attestation d'assurance", _assurancePhoto, () => _pickImage('assurance')),
                      ],
                    ),
                    const SizedBox(height: 32),
                    
                    // Bouton d'enregistrement
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 40),
                      child: ElevatedButton(
                        onPressed: _saveVehicule,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF08004D),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: Text(
                          widget.vehicleId != null ? "Mettre à jour" : "Enregistrer le véhicule",
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
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

  // Widget d'en-tête avec description
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.vehicleId != null ? "Modification du véhicule" : "Nouveau véhicule",
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF08004D),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.vehicleId != null 
                ? "Mettez à jour les informations de votre véhicule"
                : "Remplissez les informations pour ajouter un nouveau véhicule",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  // Méthode pour construire une section avec titre et contenu
  Widget _buildSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
    bool isTechnicalInfo = false,
    bool isLocationInfo = false,
    bool isSupplementaryFees = false,
    bool isInsuranceMaintenance = false,
    bool isDocuments = false,
    bool isGeneralInfo = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                if (isTechnicalInfo) {
                  _showTechnicalInfo = !_showTechnicalInfo;
                } else if (isLocationInfo) {
                  _showLocationInfo = !_showLocationInfo;
                } else if (isSupplementaryFees) {
                  _showSupplementaryFees = !_showSupplementaryFees;
                } else if (isInsuranceMaintenance) {
                  _showInsuranceMaintenance = !_showInsuranceMaintenance;
                } else if (isDocuments) {
                  _showDocuments = !_showDocuments;
                } else if (isGeneralInfo) {
                  _showGeneralInfo = !_showGeneralInfo;
                }
              });
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(icon, color: color, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                  Icon(
                    isTechnicalInfo ? (_showTechnicalInfo ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down) :
                    isLocationInfo ? (_showLocationInfo ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down) :
                    isSupplementaryFees ? (_showSupplementaryFees ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down) :
                    isInsuranceMaintenance ? (_showInsuranceMaintenance ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down) :
                    isDocuments ? (_showDocuments ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down) :
                    (_showGeneralInfo ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down),
                    color: color,
                  ),
                ],
              ),
            ),
          ),
          if (isTechnicalInfo && _showTechnicalInfo ||
              isLocationInfo && _showLocationInfo ||
              isSupplementaryFees && _showSupplementaryFees ||
              isInsuranceMaintenance && _showInsuranceMaintenance ||
              isDocuments && _showDocuments ||
              isGeneralInfo && _showGeneralInfo)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {bool isRequired = false,
      TextInputType? keyboardType,
      List<TextInputFormatter>? inputFormatters}) {
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
      "Frais de nettoyage extérieur (€)",
      "Kilométrage du prochain entretien"
    ].contains(label)) {
      keyboardType = keyboardType ?? TextInputType.number;
      suffixIcon = IconButton(
        icon: Icon(Icons.check_circle,
            color: Colors.grey[400]), 
        onPressed: () {
          FocusScope.of(context).unfocus();
        },
      );
    }

    if (label == "N° téléphone l'assurance") {
      keyboardType = TextInputType.phone;
    }

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
                color: Colors.grey[400]), 
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        textCapitalization: TextCapitalization
            .characters, 
        inputFormatters: inputFormatters ??
            [
              if (keyboardType != TextInputType.number &&
                  keyboardType != TextInputType.phone &&
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

  Widget _buildNotesField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 16, color: Color(0xFF08004D))),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            maxLines: 5, // Permet d'avoir plusieurs lignes
            decoration: InputDecoration(
              hintText: 'Entrez vos notes concernant l\'entretien',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF08004D)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF08004D), width: 2),
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ],
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
}
