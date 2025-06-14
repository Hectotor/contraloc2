import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../widget/CREATION DE CONTRAT/image_picker_dialog.dart';

/// Widget pour afficher les différentes vues de photo du véhicule
class VehiclePhotoViews extends StatelessWidget {
  const VehiclePhotoViews({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildPhotoViewBlock(context, 'Avant ¾ gauche'),
          _buildPhotoViewBlock(context, 'Avant ¾ droit'),
          _buildPhotoViewBlock(context, 'Arrière ¾ gauche'),
          _buildPhotoViewBlock(context, 'Arrière ¾ droit'),
          _buildPhotoViewBlock(context, 'Vue latérale gauche'),
          _buildPhotoViewBlock(context, 'Vue latérale droite'),
          _buildPhotoViewBlock(context, 'Vue arrière plein centre'),
          _buildPhotoViewBlock(context, 'Vue avant plein centre'),
        ],
      ),
    );
  }

  /// Construit un bloc pour une vue spécifique
  Widget _buildPhotoViewBlock(BuildContext context, String title) {
    return GestureDetector(
      onTap: () {
        // Ouvrir le dialogue de sélection d'image
        ImagePickerDialog.show(
          context, 
          false, // isRecto n'est pas pertinent ici
          (XFile image) {
            // Traiter l'image sélectionnée
            print('Image sélectionnée pour $title: ${image.path}');
            // Ici vous pourriez ajouter du code pour afficher l'image dans le bloc
            // ou la sauvegarder dans une base de données
          },
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        height: 250,
        decoration: BoxDecoration(
          color: const Color(0xFF08004D).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF08004D),
            width: 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Row(
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
    );
  }
}
