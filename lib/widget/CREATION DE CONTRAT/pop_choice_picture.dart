import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class ImagePickerDialog {
  static Future<File?> showImagePickerDialog(
    BuildContext context, {
    int imageQuality = 70,
    int compressWidth = 800,
    int compressHeight = 800,
    int compressQuality = 85,
  }) async {
    final picker = ImagePicker();
    File? selectedImage;

    await showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
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
                  final pickedFile = await picker.pickImage(
                    source: ImageSource.camera,
                    imageQuality: imageQuality,
                  );
                  if (pickedFile != null) {
                    final compressedImage = await FlutterImageCompress.compressWithFile(
                      pickedFile.path,
                      minWidth: compressWidth,
                      minHeight: compressHeight,
                      quality: compressQuality,
                    );
                    if (compressedImage != null) {
                      selectedImage = File(pickedFile.path);
                    }
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
                    imageQuality: imageQuality,
                  );
                  if (pickedFile != null) {
                    final compressedImage = await FlutterImageCompress.compressWithFile(
                      pickedFile.path,
                      minWidth: compressWidth,
                      minHeight: compressHeight,
                      quality: compressQuality,
                    );
                    if (compressedImage != null) {
                      selectedImage = File(pickedFile.path);
                    }
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
}
