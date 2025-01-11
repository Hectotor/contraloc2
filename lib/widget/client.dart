import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../widget/location.dart'; // Import de la page location
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

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

  const ClientPage({
    Key? key,
    required this.marque,
    required this.modele,
    required this.immatriculation,
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
// Firestore instance

  File? _permisRecto;
  File? _permisVerso;

  Future<void> _pickImage(bool isRecto) async {
    final picker = ImagePicker();
    showDialog(
      context: context,
      builder: (context) => Dialog(
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
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _showPermisFields = !_showPermisFields;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.add_a_photo, color: Colors.white),
              label: const Text(
                "Ajouter photo permis",
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
            if (_showPermisFields) ...[
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
        decoration: InputDecoration(
          labelText: label,
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
        decoration: InputDecoration(
          labelText: "Adresse",
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
