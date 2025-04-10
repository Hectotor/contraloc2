import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

Future<XFile?> showImagePickerDialog(
    BuildContext context, String imageType) async {
  final ImagePicker picker = ImagePicker();
  XFile? selectedImage;

  await showDialog(
    context: context,
    builder: (context) => Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      backgroundColor: Colors.white, // Ajout du fond blanc ici
      child: Padding(
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
                final XFile? image =
                    await picker.pickImage(source: ImageSource.camera);
                if (image != null) {
                  selectedImage = image;
                  print("Image sélectionnée pour $imageType : ${image.path}");
                }
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.photo_library, color: Color(0xFF08004D)),
              title: const Text('Choisir depuis la galerie'),
              onTap: () async {
                final XFile? image =
                    await picker.pickImage(source: ImageSource.gallery);
                if (image != null) {
                  selectedImage = image;
                  print("Image sélectionnée pour $imageType : ${image.path}");
                }
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    ),
  );

  return selectedImage;
}
