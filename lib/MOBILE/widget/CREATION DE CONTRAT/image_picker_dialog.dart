import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ImagePickerDialog {
  static Future<void> show(BuildContext context, bool isRecto, 
      Function(XFile) onImageSelected) async {
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
              ListTile(
                leading: const Icon(Icons.photo_camera, color: Color(0xFF08004D)),
                title: const Text('Prendre une photo'),
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
