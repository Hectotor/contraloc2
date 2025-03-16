import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';

class LogoWidget extends StatefulWidget {
  final String? initialLogoUrl;
  final Function(String?) onLogoChanged;
  final User? currentUser;

  const LogoWidget({
    Key? key,
    this.initialLogoUrl,
    required this.onLogoChanged,
    required this.currentUser,
  }) : super(key: key);

  @override
  State<LogoWidget> createState() => _LogoWidgetState();
}

class _LogoWidgetState extends State<LogoWidget> {
  XFile? _logo;
  String? _logoUrl;

  @override
  void initState() {
    super.initState();
    _logoUrl = widget.initialLogoUrl;
  }

  @override
  void didUpdateWidget(LogoWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialLogoUrl != oldWidget.initialLogoUrl) {
      setState(() {
        _logoUrl = widget.initialLogoUrl;
      });
    }
  }

  Future<void> _pickLogo() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _logo = image;
      });
      final uploadedUrl = await _uploadLogoToStorage(File(image.path));
      if (uploadedUrl != null) {
        setState(() {
          _logoUrl = uploadedUrl;
        });
        widget.onLogoChanged(uploadedUrl);
      }
    }
  }

  Future<String?> _uploadLogoToStorage(File imageFile) async {
    if (widget.currentUser == null) return null;

    try {
      final fileName = '${widget.currentUser!.uid}.jpg';
      final Reference storageRef = FirebaseStorage.instance
          .ref()
          .child('users/${widget.currentUser!.uid}/logos/$fileName');

      await storageRef.putFile(imageFile);
      return await storageRef.getDownloadURL();
    } catch (e) {
      print('Erreur upload logo: $e');
      return null;
    }
  }

  void _removeLogo() {
    setState(() {
      _logo = null;
      _logoUrl = null;
    });
    widget.onLogoChanged(null);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GestureDetector(
          onTap: _pickLogo,
          child: Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey),
              image: _logo != null
                  ? DecorationImage(
                      image: FileImage(File(_logo!.path)),
                      fit: BoxFit.cover,
                    )
                  : _logoUrl != null && _logoUrl!.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(_logoUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
            ),
            child: _logo == null && (_logoUrl == null || _logoUrl!.isEmpty)
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.add_a_photo, size: 50, color: Colors.grey),
                      SizedBox(height: 8),
                      Text(
                        "Ajouter votre logo",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  )
                : null,
          ),
        ),
        if (_logo != null || (_logoUrl != null && _logoUrl!.isNotEmpty))
          Positioned(
            top: 5,
            right: 5,
            child: GestureDetector(
              onTap: _removeLogo,
              child: const Icon(
                Icons.close,
                color: Colors.red,
                size: 20,
              ),
            ),
          ),
      ],
    );
  }
}
