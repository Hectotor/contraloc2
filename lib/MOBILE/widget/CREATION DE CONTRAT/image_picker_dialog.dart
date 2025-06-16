import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../PHOTOS/photo_guide_dialog.dart';
import '../../PHOTOS/vehicle_info_page.dart';

class ImagePickerDialog {
  static Future<void> show(BuildContext context, bool isRecto, 
      Function(XFile) onImageSelected) async {
    // Vérifier si nous sommes sur la page VehicleInfoPage
    bool isVehicleInfoPage = false;
    
    // Vérifier le contexte pour déterminer si nous sommes sur VehicleInfoPage
    Navigator.of(context).popUntil((route) {
      if (route.settings.name == '/vehicle_info') {
        isVehicleInfoPage = true;
      }
      // Ne pas réellement fermer les pages, juste vérifier
      return true;
    });
    
    // Alternative: vérifier si un widget parent est VehicleInfoPage
    BuildContext? testContext = context;
    while (testContext != null) {
      if (testContext.widget is VehicleInfoPage || 
          testContext.widget.runtimeType.toString().contains('VehicleInfoPage')) {
        isVehicleInfoPage = true;
        break;
      }
      testContext = testContext.findAncestorStateOfType<State<VehicleInfoPage>>()?.
          context;
    }
    final picker = ImagePicker();
    
    await showDialog(
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
              // N'afficher l'option de photo standard que si on n'est PAS sur VehicleInfoPage
              if (!isVehicleInfoPage)
                ListTile(
                  leading: const Icon(Icons.photo_camera, color: Color(0xFF08004D)),
                  title: const Text('Prendre une photo standard'),
                  onTap: () async {
                    Navigator.of(context).pop();
                    try {
                      final image = await picker.pickImage(
                        source: ImageSource.camera,
                        imageQuality: 50,
                      );
                      if (image != null) {
                        onImageSelected(image);
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Erreur lors de la capture: $e')),
                      );
                    }
                  },
                ),
              // N'afficher l'option de photo guidée que sur la page VehicleInfoPage
              if (isVehicleInfoPage)
                ListTile(
                  leading: const Icon(Icons.auto_awesome, color: Color(0xFF08004D)),
                  title: const Text('Prendre une photo guidée'),
                  subtitle: const Text('Avec assistance pour un cadrage optimal'),
                  onTap: () async {
                    Navigator.of(context).pop();
                    
                    // Déterminer le type de photo en fonction de isRecto
                    // Cette logique peut être adaptée selon vos besoins
                    String photoType = isRecto 
                        ? "Vue avant plein centre" 
                        : "Vue latérale gauche";
                    
                    // Afficher le guide photo puis prendre la photo
                    PhotoGuideDialog.show(
                      context,
                      photoType,
                      (XFile photo) {
                        // Traiter la photo prise
                        onImageSelected(photo);
                      },
                    );
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Color(0xFF08004D)),
                title: const Text('Choisir depuis la galerie'),
                onTap: () async {
                  Navigator.of(context).pop();
                  try {
                    final image = await picker.pickImage(
                      source: ImageSource.gallery,
                      imageQuality: 50,
                    );
                    if (image != null) {
                      onImageSelected(image);
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erreur lors du choix: $e')),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
