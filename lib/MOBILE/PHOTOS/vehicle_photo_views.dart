import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../widget/CREATION DE CONTRAT/image_picker_dialog.dart';
import 'vehicle_photos_gallery.dart';

/// Widget pour afficher les différentes vues de photo du véhicule
class VehiclePhotoViews extends StatefulWidget {
  final Function(Map<String, String>)? onImagesUpdated;
  final Map<String, String> processedImages;

  const VehiclePhotoViews({
    Key? key, 
    this.onImagesUpdated,
    this.processedImages = const {},
  }) : super(key: key);

  @override
  State<VehiclePhotoViews> createState() => _VehiclePhotoViewsState();
}

class _VehiclePhotoViewsState extends State<VehiclePhotoViews> {
  // Map pour stocker les chemins des images sélectionnées (originales)
  final Map<String, String> _selectedImages = {};
  
  // Map pour suivre quel mode d'affichage est actif pour chaque image
  final Map<String, bool> _showProcessed = {};
  
  @override
  void initState() {
    super.initState();
  }
  
  @override
  void didUpdateWidget(VehiclePhotoViews oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Vérifier si de nouvelles images traitées sont disponibles
    for (var entry in widget.processedImages.entries) {
      if (_selectedImages.containsKey(entry.key)) {
        // Activer automatiquement l'affichage des images traitées
        _showProcessed[entry.key] = true;
      }
    }
  }
  
  /// Ouvre la galerie de photos en plein écran
  void _openGallery(String currentTitle) {
    if (_selectedImages.isEmpty) return;
    
    // Trouver l'index de la vue actuelle dans la liste des photos
    final photosList = _selectedImages.entries.toList();
    final currentIndex = photosList.indexWhere((entry) => entry.key == currentTitle);
    
    if (currentIndex >= 0) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VehiclePhotosGallery(
            photos: _selectedImages,
            initialIndex: currentIndex,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildPhotoViewBlock(context, 'Vue avant plein centre'),
          _buildPhotoViewBlock(context, 'Avant ¾ gauche'),
          _buildPhotoViewBlock(context, 'Vue latérale gauche'),
          _buildPhotoViewBlock(context, 'Arrière ¾ gauche'),
          _buildPhotoViewBlock(context, 'Vue arrière plein centre'),
          _buildPhotoViewBlock(context, 'Arrière ¾ droit'),
          _buildPhotoViewBlock(context, 'Vue latérale droite'),
          _buildPhotoViewBlock(context, 'Avant ¾ droit'),

        ],
      ),
    );
  }

  /// Construit un bloc pour une vue spécifique
  Widget _buildPhotoViewBlock(BuildContext context, String title) {
    final hasImage = _selectedImages.containsKey(title);
    
    return GestureDetector(
      onTap: () {
        // Ouvrir le dialogue de sélection d'image
        ImagePickerDialog.show(
          context, 
          false, // isRecto n'est pas pertinent ici
          (XFile image) {
            setState(() {
              _selectedImages[title] = image.path;
              if (widget.onImagesUpdated != null) {
                widget.onImagesUpdated!(_selectedImages);
              }
            });
            print('Image sélectionnée pour $title: ${image.path}');
          },
        );
      },
      child: AspectRatio(
        aspectRatio: 4 / 3, // Format 4:3
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          decoration: BoxDecoration(
            color: const Color(0xFF08004D).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF08004D),
              width: 1,
            ),
          ),
          padding: hasImage ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: 20.0),
          child: hasImage
            ? _buildImagePreview(title)
            : Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const Icon(
                  Icons.camera_alt,
                  color: Color(0xFF08004D),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF08004D),
                  ),
                ),
              ],
            ),
        ),
      ),
    );
  }
  
  /// Construit l'aperçu de l'image sélectionnée
  Widget _buildImagePreview(String title) {
    final hasImage = _selectedImages.containsKey(title);
    final hasProcessedImage = widget.processedImages.containsKey(title);
    final showProcessed = _showProcessed[title] ?? false;
    
    // Déterminer quel chemin d'image utiliser
    String? imagePath;
    if (hasImage) {
      if (showProcessed && hasProcessedImage) {
        imagePath = widget.processedImages[title];
      } else {
        imagePath = _selectedImages[title];
      }
    }
    
    return Stack(
      children: [
        // Image ou espace vide
        Positioned.fill(
          child: hasImage
              ? Image.file(
                  File(imagePath!),
                  fit: BoxFit.cover,
                )
              : Container(
                  color: Colors.grey[200],
                ),
        ),
        // Bouton de suppression
        if (hasImage)
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedImages.remove(title);
                  _showProcessed.remove(title);
                  // Notifier le parent des changements
                  if (widget.onImagesUpdated != null) {
                    widget.onImagesUpdated!(_selectedImages);
                  }
                });
              },
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Color(0xFF08004D),
                  size: 20,
                ),
              ),
            ),
          ),
        
        // Bouton pour basculer entre original et traité
        if (hasImage && hasProcessedImage)
          Positioned(
            bottom: 8,
            left: 8,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _showProcessed[title] = !(_showProcessed[title] ?? false);
                });
              },
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.7),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.auto_fix_high,
                  color: showProcessed ? Colors.amber : Color(0xFF08004D),
                  size: 20,
                ),
              ),
            ),
          ),
        
        // Bouton pour ouvrir la galerie
        if (hasImage)
          Positioned(
            top: 60, // Positionné en dessous de la croix
            right: 8,
            child: GestureDetector(
              onTap: () => _openGallery(title),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.remove_red_eye,
                  color: Color(0xFF08004D),
                  size: 20,
                ),
              ),
            ),
          ),
          
        // Indicateur de version traitée
        if (hasImage && hasProcessedImage && showProcessed)
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Traitée',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        // Overlay semi-transparent avec le titre
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(11),
                bottomRight: Radius.circular(11),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                // Bouton pour changer l'image
                IconButton(
                  icon: const Icon(
                    Icons.edit,
                    color: Colors.white,
                    size: 20,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    // Ouvrir à nouveau le dialogue de sélection d'image
                    ImagePickerDialog.show(
                      context, 
                      false,
                      (XFile image) {
                        setState(() {
                          _selectedImages[title] = image.path;
                        });
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
