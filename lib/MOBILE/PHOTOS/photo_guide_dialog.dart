import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

/// Un dialogue simple qui affiche des conseils pour prendre une bonne photo
/// directement pendant la prise de photo
class PhotoGuideDialog {
  static Future<void> show(
    BuildContext context,
    String photoType,
    Function(XFile) onPhotoTaken,
    {bool forceLandscape = false}
  ) async {
    // Déterminer les conseils en fonction du type de photo
    String tips = _getTipsForPhotoType(photoType);
    
    // Créer un overlay pour afficher les conseils pendant la prise de photo
    final OverlayState overlayState = Overlay.of(context);
    final OverlayEntry overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 10,
        left: 10,
        right: 10,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      photoType,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    // Bouton pour fermer l'overlay
                    GestureDetector(
                      onTap: () {
                        // L'overlay sera fermé automatiquement
                      },
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  tips,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    
    // Ajouter l'overlay au contexte actuel
    overlayState.insert(overlayEntry);
    
    // Lancer la caméra sans changer l'orientation
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      
      // Supprimer l'overlay
      overlayEntry.remove();
      
      if (image != null && context.mounted) {
        onPhotoTaken(image);
      }
    } catch (e) {
      // Supprimer l'overlay
      overlayEntry.remove();
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la prise de photo: $e')),
        );
      }
    }
  }

  /// Retourne les conseils adaptés au type de photo
  static String _getTipsForPhotoType(String photoType) {
    switch (photoType) {
      case 'Vue avant plein centre':
        return '• Positionnez-vous face au véhicule\n'
            '• Tenez-vous à environ 2-3 mètres\n'
            '• Assurez-vous que tout l\'avant du véhicule est visible\n'
            '• Évitez les reflets du soleil sur la carrosserie';
      
      case 'Vue arrière plein centre':
        return '• Positionnez-vous derrière le véhicule\n'
            '• Tenez-vous à environ 2-3 mètres\n'
            '• Assurez-vous que la plaque d\'immatriculation est visible\n'
            '• Capturez tous les feux arrière';
      
      case 'Vue latérale gauche':
      case 'Vue latérale droite':
        return '• Positionnez-vous perpendiculairement au véhicule\n'
            '• Tenez-vous à environ 3-4 mètres\n'
            '• Capturez toute la longueur du véhicule\n'
            '• Assurez-vous que les roues sont bien visibles';
      
      case 'Avant ¾ gauche':
      case 'Avant ¾ droit':
        return '• Positionnez-vous à environ 45° par rapport à l\'avant\n'
            '• Tenez-vous à environ 3 mètres\n'
            '• Capturez l\'avant et le côté du véhicule\n'
            '• Cette vue met en valeur la forme du véhicule';
      
      case 'Arrière ¾ gauche':
      case 'Arrière ¾ droit':
        return '• Positionnez-vous à environ 45° par rapport à l\'arrière\n'
            '• Tenez-vous à environ 3 mètres\n'
            '• Capturez l\'arrière et le côté du véhicule\n'
            '• Assurez-vous que les feux arrière sont visibles';
      
      default:
        return '• Tenez votre téléphone horizontalement\n'
            '• Assurez-vous que l\'éclairage est suffisant\n'
            '• Évitez les ombres importantes\n'
            '• Gardez l\'appareil stable pour éviter les flous';
    }
  }
}
