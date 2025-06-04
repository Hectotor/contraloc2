import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
// Import supprimé car plus nécessaire après la suppression des vérifications premium
import 'package:flutter/services.dart';
// Import supprimé car plus nécessaire après la suppression des vérifications premium
// Import supprimé car plus nécessaire après la suppression des vérifications premium

class EtatCommentaireContainer extends StatefulWidget {
  final List<File> photos;
  final Function(File) onAddPhoto;
  final Function(File) onRemovePhoto;
  final TextEditingController commentaireController;

  const EtatCommentaireContainer({
    super.key,
    required this.photos,
    required this.onAddPhoto,
    required this.onRemovePhoto,
    required this.commentaireController,
  });

  @override
  State<EtatCommentaireContainer> createState() => _EtatCommentaireContainerState();
}

class _EtatCommentaireContainerState extends State<EtatCommentaireContainer> {
  // Variable isPremiumUser supprimée car tous les utilisateurs peuvent prendre des photos
  bool isLoading = true;
  bool _showContent = false;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _showContent = false;
    _pageController = PageController();
    
    // Définit isLoading à false après un court délai (anciennement dans _checkPremiumStatus)
    Future.delayed(Duration(milliseconds: 100)).then((_) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.photos.isNotEmpty) {
        _pageController.jumpToPage(widget.photos.length - 1);
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant EtatCommentaireContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.photos.length != oldWidget.photos.length && widget.photos.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _pageController.jumpToPage(widget.photos.length - 1);
      });
    }
  }

  // Méthode _checkPremiumStatus supprimée car elle n'est plus nécessaire

  // Méthode _showPremiumDialog supprimée car elle n'est plus utilisée

  Future<void> _pickImage() async {
    if (widget.photos.length >= 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Vous ne pouvez ajouter que 10 photos maximum.")),
      );
      return;
    }

    final picker = ImagePicker();
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
                  final pickedFile = await picker.pickImage(
                    source: ImageSource.camera,
                    imageQuality: 70,
                  );
                  if (pickedFile != null) {
                    widget.onAddPhoto(File(pickedFile.path));
                  }
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Color(0xFF08004D)),
                title: const Text('Choisir depuis la galerie'),
                onTap: () async {
                  final pickedFile = await picker.pickImage(
                    source: ImageSource.gallery,
                    imageQuality: 70,
                  );
                  if (pickedFile != null) {
                    widget.onAddPhoto(File(pickedFile.path));
                  }
                  Navigator.of(context).pop();
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
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(Icons.directions_car, color: const Color(0xFF08004D), size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "État du véhicule",
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
                    // Section photos
                    const Text(
                      "Photos de l'état du véhicule :",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (widget.photos.length < 10) ...[
                      Container(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: isLoading ? null : _pickImage,
                          icon: const Icon(Icons.add_a_photo, color: Color(0xFF08004D)),
                          label: const Text('Ajouter une photo', style: TextStyle(color: Color(0xFF08004D))),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF08004D),
                            side: const BorderSide(color: Color(0xFF08004D), width: 2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            minimumSize: const Size(double.infinity, 40),
                          ),
                        ),
                      ),
                    ],
                    if (widget.photos.isNotEmpty) _buildPhotoScroll(),
                     const SizedBox(height: 15),
                    // Section commentaire
                    const Text(
                      "Commentaire :",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: widget.commentaireController,
                      maxLines: 4,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\s\.\,\-\!\?\(\)]')),
                        TextInputFormatter.withFunction((oldValue, newValue) {
                          if (newValue.text.isEmpty) {
                            return newValue;
                          }
                          if (newValue.text.length == 1) {
                            return TextEditingValue(
                              text: newValue.text.toUpperCase(),
                              selection: TextSelection.collapsed(offset: 1),
                            );
                          }
                          return newValue;
                        }),
                      ],
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        hintText: "Ajoutez un commentaire sur l'état du véhicule...",
                        suffixIcon: IconButton(
                          icon: Icon(Icons.check_circle, color: Colors.grey[400]),
                          onPressed: () => FocusManager.instance.primaryFocus?.unfocus(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
  

  Widget _buildPhotoScroll() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "${widget.photos.length} photo${widget.photos.length > 1 ? 's' : ''} (${widget.photos.length}/10)",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 250,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: widget.photos.length,
            itemBuilder: (context, index) {
              return Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        widget.photos[index],
                        width: 200,
                        height: 234,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: GestureDetector(
                      onTap: () {
                        widget.onRemovePhoto(widget.photos[index]);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              spreadRadius: 1,
                              blurRadius: 3,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
