import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

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
      
      final File savedImage = File(photo.path);
      final File copiedImage = await savedImage.copy(filePath);
      
      widget.onPhotoTaken(copiedImage);
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
