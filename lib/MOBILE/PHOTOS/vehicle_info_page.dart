import 'package:flutter/material.dart';
import 'vehicle_photo_views.dart';
import 'generate_button.dart';
import 'background_removal_service.dart';
import '../widget/chargement.dart';

/// Page dédiée au formulaire d'informations du véhicule
class VehicleInfoPage extends StatefulWidget {
  const VehicleInfoPage({Key? key}) : super(key: key);

  @override
  State<VehicleInfoPage> createState() => _VehicleInfoPageState();
}

class _VehicleInfoPageState extends State<VehicleInfoPage> {
  final Map<String, String> _selectedImages = {};
  final Map<String, String> _processedImages = {};
  bool _isProcessing = false;
  
  // Méthode pour traiter les images avec remove.bg
  Future<void> _processImages() async {
    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucune image à traiter')),
      );
      return;
    }

    // Afficher un dialogue de chargement
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Chargement(
          message: 'Traitement des images en cours...',
        );
      },
    );

    try {
      // Traiter chaque image
      for (var entry in _selectedImages.entries) {
        final imagePath = entry.value;
        final processedImagePath = await BackgroundRemovalService.removeBackground(imagePath);
        
        if (processedImagePath != null) {
          // Stocker l'image traitée dans la map des images traitées
          setState(() {
            _processedImages[entry.key] = processedImagePath;
          });
        }
      }

      // Fermer le dialogue de chargement
      Navigator.of(context).pop();

      // Afficher un message de succès
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Images traitées avec succès')),
      );
    } catch (e) {
      // Fermer le dialogue de chargement
      Navigator.of(context).pop();

      // Afficher un message d'erreur
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(' '),
        backgroundColor: const Color(0xFF08004D),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Informations du véhicule',
                labelStyle: const TextStyle(
                  color: Color(0xFF08004D),
                  fontWeight: FontWeight.bold,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF08004D)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF08004D), width: 2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Vues du véhicule',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF08004D),
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'Pour un rendu optimal, privilégiez les photos au format horizontal.',
              style: TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: Color(0xFF08004D),
                fontWeight: FontWeight.w300,
              ),
            ),
            const SizedBox(height: 10),
            VehiclePhotoViews(
              onImagesUpdated: (images) {
                setState(() {
                  _selectedImages.clear();
                  _selectedImages.addAll(images);
                  
                  // Nettoyer les images traitées qui n'ont plus d'originales
                  _processedImages.removeWhere((key, value) => !_selectedImages.containsKey(key));
                });
              },
              processedImages: _processedImages,
            ),
            const SizedBox(height: 30),
            Center(
              child: GenerateButton(
                onPressed: _isProcessing ? () {} : () async {
                  await _processImages();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
