import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
// Import de access_premium.dart supprimé car non utilisé
import '../image_picker_dialog.dart';
// Import de premium_dialog.dart supprimé car non utilisé
// Import de firebase_auth.dart supprimé car non utilisé

class PermisInfoContainer extends StatefulWidget {
  final TextEditingController numeroPermisController;
  final Function(File?) onRectoImageSelected;
  final Function(File?) onVersoImageSelected;
  final File? permisRecto;
  final File? permisVerso;
  final String? permisRectoUrl;
  final String? permisVersoUrl;

  const PermisInfoContainer({
    Key? key,
    required this.numeroPermisController,
    required this.onRectoImageSelected,
    required this.onVersoImageSelected,
    this.permisRecto,
    this.permisVerso,
    this.permisRectoUrl,
    this.permisVersoUrl,
  }) : super(key: key);

  @override
  State<PermisInfoContainer> createState() => _PermisInfoContainerState();
}

class _PermisInfoContainerState extends State<PermisInfoContainer> {
  bool _showContent = false;
  // Variable _isPremiumUser supprimée car tous les utilisateurs peuvent prendre des photos
  File? _rectoImage;
  File? _versoImage;

  @override
  void initState() {
    super.initState();
    _showContent = false;
    // _initializeSubscription() supprimée car non utilisée
  }

  // Méthode _initializeSubscription supprimée car non utilisée

  // Méthode _checkPremiumStatus supprimée car non utilisée

  void _handleHeaderTap() {
    setState(() {
      _showContent = !_showContent;
    });
  }

  // Méthode _showPremiumDialog supprimée car non utilisée

  // Sélectionner une image
  Future<void> _selectImage(XFile image, bool isRecto) async {
    try {
      setState(() {
        if (isRecto) {
          _rectoImage = File(image.path);
          widget.onRectoImageSelected(_rectoImage);
        } else {
          _versoImage = File(image.path);
          widget.onVersoImageSelected(_versoImage);
        }
      });
    } catch (e) {
      print("Erreur lors de la sélection de l'image: $e");
    }
  }

  // Supprimer une image
  void _removeImage(bool isRecto) {
    setState(() {
      if (isRecto) {
        _rectoImage = null;
        widget.onRectoImageSelected(null);
      } else {
        _versoImage = null;
        widget.onVersoImageSelected(null);
      }
    });
  }

  // Afficher la boîte de dialogue pour choisir la source de l'image
  Future<void> _showImagePickerDialog(bool isRecto) async {
    // Tous les utilisateurs peuvent prendre des photos, pas besoin de vérifier le statut premium
    ImagePickerDialog.show(
      context,
      isRecto,
      (image) => _selectImage(image, isRecto),
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
              onTap: _handleHeaderTap,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF08004D).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
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
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        labelText: "Numéro de permis",
                        labelStyle: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF08004D),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF08004D)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF08004D), width: 1),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF08004D), width: 2),
                        ),
                      ),
                      textCapitalization: TextCapitalization.characters,
                      onChanged: (value) {
                        if (widget.numeroPermisController.text != value.toUpperCase()) {
                          widget.numeroPermisController.value = TextEditingValue(
                            text: value.toUpperCase(),
                            selection: TextSelection.collapsed(offset: value.length),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Champs permis recto/verso
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Permis recto
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
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
                              height: 150,
                              child: Stack(
                                children: [
                                  if (_rectoImage != null)
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.file(
                                        _rectoImage!,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: double.infinity,
                                      ),
                                    )
                                  else if (widget.permisRectoUrl != null && widget.permisRectoUrl!.isNotEmpty)
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        widget.permisRectoUrl!,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: double.infinity,
                                        errorBuilder: (context, error, stackTrace) {
                                          print('Erreur de chargement de l\'image recto: $error');
                                          return Center(
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(Icons.error, size: 40, color: Colors.red[300]),
                                                SizedBox(height: 8),
                                                Text('Erreur image', style: TextStyle(color: Colors.red[300])),
                                              ],
                                            ),
                                          );
                                        },
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
                                  if (_rectoImage != null || (widget.permisRectoUrl != null && widget.permisRectoUrl!.isNotEmpty))
                                    Positioned(
                                      right: 0,
                                      bottom: 0,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.6),
                                          borderRadius: const BorderRadius.only(
                                            topLeft: Radius.circular(12),
                                            bottomRight: Radius.circular(12),
                                          ),
                                        ),
                                        padding: const EdgeInsets.all(8),
                                        child: IconButton(
                                          icon: const Icon(
                                            Icons.delete,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                          onPressed: () {
                                            _removeImage(true);
                                          },
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Permis verso
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
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
                              height: 150,
                              child: Stack(
                                children: [
                                  if (_versoImage != null)
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.file(
                                        _versoImage!,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: double.infinity,
                                      ),
                                    )
                                  else if (widget.permisVersoUrl != null && widget.permisVersoUrl!.isNotEmpty)
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        widget.permisVersoUrl!,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: double.infinity,
                                        errorBuilder: (context, error, stackTrace) {
                                          print('Erreur de chargement de l\'image verso: $error');
                                          return Center(
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(Icons.error, size: 40, color: Colors.red[300]),
                                                SizedBox(height: 8),
                                                Text('Erreur image', style: TextStyle(color: Colors.red[300])),
                                              ],
                                            ),
                                          );
                                        },
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
                                  if (_versoImage != null || (widget.permisVersoUrl != null && widget.permisVersoUrl!.isNotEmpty))
                                    Positioned(
                                      right: 0,
                                      bottom: 0,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.6),
                                          borderRadius: const BorderRadius.only(
                                            topLeft: Radius.circular(12),
                                            bottomRight: Radius.circular(12),
                                          ),
                                        ),
                                        padding: const EdgeInsets.all(8),
                                        child: IconButton(
                                          icon: const Icon(
                                            Icons.delete,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                          onPressed: () {
                                            _removeImage(false);
                                          },
                                        ),
                                      ),
                                    ),
                                ],
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
