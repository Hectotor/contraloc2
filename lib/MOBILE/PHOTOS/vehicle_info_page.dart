import 'package:flutter/material.dart';
import 'vehicle_photo_views.dart';
import 'generate_button.dart';
import 'background_removal_service.dart';

/// Page dédiée au formulaire d'informations du véhicule
class VehicleInfoPage extends StatefulWidget {
  const VehicleInfoPage({Key? key}) : super(key: key);

  @override
  State<VehicleInfoPage> createState() => _VehicleInfoPageState();
}

class _VehicleInfoPageState extends State<VehicleInfoPage> {
  // Map pour stocker les images sélectionnées
  Map<String, String> _vehicleImages = {};
  bool _isProcessing = false;
  
  // Méthode pour mettre à jour les images
  void _updateImages(Map<String, String> images) {
    setState(() {
      _vehicleImages = images;
    });
  }
  
  // Méthode pour traiter les images avec remove.bg
  Future<void> _processImagesWithRemoveBg() async {
    if (_vehicleImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez d\'abord ajouter des photos du véhicule')),
      );
      return;
    }
    
    setState(() {
      _isProcessing = true;
    });
    
    // Afficher le dialogue de traitement
    BackgroundRemovalService.showProcessingDialog(context);
    
    // Traiter chaque image
    Map<String, String> processedImages = {};
    bool hasError = false;
    
    for (var entry in _vehicleImages.entries) {
      final processedImagePath = await BackgroundRemovalService.removeBackground(
        entry.value,
      );
      
      if (processedImagePath != null) {
        processedImages[entry.key] = processedImagePath;
      } else {
        hasError = true;
        break;
      }
    }
    
    // Fermer le dialogue de traitement
    Navigator.of(context).pop();
    
    if (!hasError) {
      setState(() {
        _vehicleImages = processedImages;
        _isProcessing = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Traitement des images réussi ! Arrière-plans remplacés.')),
      );
    } else {
      setState(() {
        _isProcessing = false;
      });
      
      BackgroundRemovalService.showErrorDialog(
        context, 
        'Une erreur est survenue lors du traitement des images. Vérifiez votre clé API remove.bg.',
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
                  VehiclePhotoViews(onImagesUpdated: _updateImages),
                  const SizedBox(height: 30),
                  Center(
                    child: GenerateButton(
                      onPressed: _isProcessing ? () {} : () async {
                        await _processImagesWithRemoveBg();
                      },
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
