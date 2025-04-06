import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import 'package:ContraLoc/USERS/Subscription/abonnement_screen.dart';


class PermisInfoContainer extends StatefulWidget {
  final TextEditingController numeroPermisController;
  final Function(File?) onRectoImageSelected;
  final Function(File?) onVersoImageSelected;
  final File? permisRecto;
  final File? permisVerso;
  final String? permisRectoUrl;
  final String? permisVersoUrl;
  final bool isPremiumUser;

  const PermisInfoContainer({
    Key? key,
    required this.numeroPermisController,
    required this.onRectoImageSelected,
    required this.onVersoImageSelected,
    this.permisRecto,
    this.permisVerso,
    this.permisRectoUrl,
    this.permisVersoUrl,
    required this.isPremiumUser,
  }) : super(key: key);

  @override
  State<PermisInfoContainer> createState() => _PermisInfoContainerState();
}

class _PermisInfoContainerState extends State<PermisInfoContainer> {
  bool _showPermisFieldsVisible = false;
  bool _showContent = true;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _showContent = false;
    // Si des images de permis sont déjà définies, afficher les champs
    if (widget.permisRecto != null || widget.permisVerso != null ||
        widget.permisRectoUrl != null || widget.permisVersoUrl != null) {
      _showPermisFieldsVisible = true;
    }
  }

  // Afficher la boîte de dialogue premium
  void _showPremiumDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Fonctionnalité Premium"),
          content: const Text(
              "Cette fonctionnalité est réservée aux utilisateurs premium. Veuillez mettre à niveau votre abonnement pour y accéder."),
          actions: [
            TextButton(
              child: const Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text("S'abonner"),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AbonnementScreen(),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }



  // Sélectionner une image
  Future<void> _selectImage(ImageSource source, bool isRecto) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 70,
      );
      
      if (image != null) {
        final File imageFile = File(image.path);
        if (isRecto) {
          widget.onRectoImageSelected(imageFile);
        } else {
          widget.onVersoImageSelected(imageFile);
        }
        setState(() {});
      }
    } catch (e) {
      print("Erreur lors de la sélection de l'image: $e");
    }
  }

  // Supprimer une image
  void _removeImage(bool isRecto) {
    if (isRecto) {
      widget.onRectoImageSelected(null); // Utiliser null au lieu d'un fichier vide
    } else {
      widget.onVersoImageSelected(null); // Utiliser null au lieu d'un fichier vide
    }
    setState(() {}); // Forcer la mise à jour de l'UI après la suppression
  }

  // Afficher la boîte de dialogue pour choisir la source de l'image
  void _showImagePickerDialog(bool isRecto) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        backgroundColor: Colors.white, 
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Choisir une option",
                style: const TextStyle(
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
                  Navigator.of(context).pop(); // Fermer le dialog avant de sélectionner l'image
                  await _selectImage(ImageSource.camera, isRecto);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Color(0xFF08004D)),
                title: const Text('Choisir depuis la galerie'),
                onTap: () async {
                  Navigator.of(context).pop(); // Fermer le dialog avant de sélectionner l'image
                  await _selectImage(ImageSource.gallery, isRecto);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.20),
            blurRadius: 4,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête de la carte avec flèche
            GestureDetector(
              onTap: () {
                setState(() {
                  _showContent = !_showContent;
                });
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF08004D).withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.perm_identity, color: const Color(0xFF08004D), size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Informations permis",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF08004D),
                        ),
                      ),
                    ),
                    Icon(
                      _showContent ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      color: const Color(0xFF08004D),
                    ),
                  ],
                ),
              ),
            ),
            // Contenu de la carte
            if (_showContent)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Champ numéro de permis
                    TextField(
                      controller: widget.numeroPermisController,
                      decoration: InputDecoration(
                        labelText: "Numéro de permis",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Champs permis recto/verso
                    if (_showPermisFieldsVisible)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Permis recto
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                if (!widget.isPremiumUser) {
                                  _showPremiumDialog();
                                  return;
                                }
                                _showImagePickerDialog(true);
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 8),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.grey[300]!,
                                    width: 1,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: AspectRatio(
                                  aspectRatio: 1, // Format carré
                                  child: Stack(
                                    children: [
                                      if (widget.permisRecto != null)
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: Image.file(
                                            widget.permisRecto!,
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                            height: double.infinity,
                                          ),
                                        )
                                      else if (widget.permisRectoUrl != null)
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: Image.network(
                                            widget.permisRectoUrl!,
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                            height: double.infinity,
                                            loadingBuilder: (context, child, loadingProgress) {
                                              if (loadingProgress == null) return child;
                                              return Center(
                                                child: CircularProgressIndicator(
                                                  value: loadingProgress.expectedTotalBytes != null
                                                      ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                                      : null,
                                                ),
                                              );
                                            },
                                          ),
                                        )
                                      else
                                        Center(
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              const Icon(
                                                Icons.add_a_photo,
                                                size: 40,
                                                color: Colors.grey,
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                "Recto",
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      if (widget.permisRecto != null || widget.permisRectoUrl != null)
                                        Positioned(
                                          right: 0,
                                          top: 0,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.red,
                                              borderRadius: BorderRadius.circular(100),
                                            ),
                                            padding: const EdgeInsets.all(4),
                                            child: InkWell(
                                              onTap: () => _removeImage(true),
                                              child: const Icon(
                                                Icons.close,
                                                size: 18,
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
                          // Permis verso
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                if (!widget.isPremiumUser) {
                                  _showPremiumDialog();
                                  return;
                                }
                                _showImagePickerDialog(false);
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 8),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.grey[300]!,
                                    width: 1,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: AspectRatio(
                                  aspectRatio: 1, // Format carré
                                  child: Stack(
                                    children: [
                                      if (widget.permisVerso != null)
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: Image.file(
                                            widget.permisVerso!,
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                            height: double.infinity,
                                          ),
                                        )
                                      else if (widget.permisVersoUrl != null)
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: Image.network(
                                            widget.permisVersoUrl!,
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                            height: double.infinity,
                                            loadingBuilder: (context, child, loadingProgress) {
                                              if (loadingProgress == null) return child;
                                              return Center(
                                                child: CircularProgressIndicator(
                                                  value: loadingProgress.expectedTotalBytes != null
                                                      ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                                      : null,
                                                ),
                                              );
                                            },
                                          ),
                                        )
                                      else
                                        Center(
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              const Icon(
                                                Icons.add_a_photo,
                                                size: 40,
                                                color: Colors.grey,
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                "Verso",
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      if (widget.permisVerso != null || widget.permisVersoUrl != null)
                                        Positioned(
                                          right: 0,
                                          top: 0,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.red,
                                              borderRadius: BorderRadius.circular(100),
                                            ),
                                            padding: const EdgeInsets.all(4),
                                            child: InkWell(
                                              onTap: () => _removeImage(false),
                                              child: const Icon(
                                                Icons.close,
                                                size: 18,
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
                        ],
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    // Convertir le texte en majuscules
    final String upperCaseText = newValue.text.toUpperCase();
    
    // Si le texte n'a pas changé après conversion, retourner la valeur telle quelle
    if (upperCaseText == newValue.text) {
      return newValue;
    }
    
    // Calculer le décalage de la sélection si nécessaire
    final int selectionOffset = newValue.selection.baseOffset;
    
    return TextEditingValue(
      text: upperCaseText,
      selection: TextSelection.collapsed(offset: selectionOffset),
    );
  }
}
