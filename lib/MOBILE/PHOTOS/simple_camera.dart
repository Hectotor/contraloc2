import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:image/image.dart' as img;

class SimpleCamera extends StatefulWidget {
  final Function(File) onPhotoTaken;

  const SimpleCamera({Key? key, required this.onPhotoTaken}) : super(key: key);

  // Méthode statique pour afficher la caméra dans un dialogue
  static Future<void> show(BuildContext context, Function(File) onPhotoTaken) async {
    return showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(0),
        child: SimpleCamera(onPhotoTaken: onPhotoTaken),
      ),
    );
  }

  @override
  State<SimpleCamera> createState() => _SimpleCameraState();
}

class _SimpleCameraState extends State<SimpleCamera> {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isInitialized = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aucune caméra disponible')),
        );
        return;
      }

      // Utiliser la caméra arrière par défaut
      final backCamera = _cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras.first,
      );

      _controller = CameraController(
        backCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller!.initialize();
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur d\'initialisation de la caméra: $e')),
      );
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    if (_controller == null || !_controller!.value.isInitialized || _isProcessing) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final XFile photo = await _controller!.takePicture();
      final directory = await getTemporaryDirectory();
      final String fileName = path.basename(photo.path);
      final String filePath = path.join(directory.path, fileName);
      
      // Corriger l'orientation de l'image
      final File correctedImage = await _fixImageOrientation(File(photo.path), filePath);
      
      widget.onPhotoTaken(correctedImage);
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la prise de photo: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }
  
  /// Corrige l'orientation de l'image pour qu'elle s'affiche correctement
  Future<File> _fixImageOrientation(File inputImage, String outputPath) async {
    try {
      // Lire l'image avec le package image
      final Uint8List bytes = await inputImage.readAsBytes();
      final img.Image? originalImage = img.decodeImage(bytes);
      
      if (originalImage == null) {
        return inputImage; // Retourner l'image originale si on ne peut pas la décoder
      }
      
      // Rotation de l'image pour corriger l'orientation (270 degrés dans le sens horaire)
      // ce qui équivaut à une rotation de 90 degrés dans le sens anti-horaire
      final img.Image rotatedImage = img.copyRotate(originalImage, angle: 270);
      
      // Enregistrer l'image corrigée
      final File outputFile = File(outputPath);
      await outputFile.writeAsBytes(img.encodeJpg(rotatedImage));
      
      return outputFile;
    } catch (e) {
      print('Erreur lors de la correction de l\'orientation: $e');
      return inputImage; // En cas d'erreur, retourner l'image originale
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized || _controller == null) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: AspectRatio(
              aspectRatio: _controller!.value.aspectRatio,
              child: CameraPreview(_controller!),
            ),
          ),
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Bouton pour fermer la caméra
                FloatingActionButton(
                  heroTag: 'close',
                  backgroundColor: Colors.red,
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Icon(Icons.close, color: Colors.white),
                ),
                // Bouton pour prendre une photo
                FloatingActionButton(
                  heroTag: 'capture',
                  backgroundColor: Colors.white,
                  onPressed: _takePhoto,
                  child: _isProcessing 
                    ? const CircularProgressIndicator()
                    : Transform.rotate(
                        angle: 1.5708, // 90 degrés en radians
                        child: const Icon(Icons.camera_alt, color: Colors.black),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
