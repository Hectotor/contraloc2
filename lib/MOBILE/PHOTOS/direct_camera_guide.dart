import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Une simulation d'écran de caméra avec guides visuels en temps réel
/// Cette classe simule ce que ferait le plugin camera
/// Pour une implémentation réelle, il faudrait installer le plugin camera
class DirectCameraGuide extends StatefulWidget {
  final String photoType;
  final Function(String) onPhotoTaken;

  const DirectCameraGuide({
    Key? key,
    required this.photoType,
    required this.onPhotoTaken,
  }) : super(key: key);

  /// Affiche l'écran de caméra simple
  static Future<void> show(
    BuildContext context,
    String photoType,
    Function(String) onPhotoTaken,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DirectCameraGuide(
          photoType: photoType,
          onPhotoTaken: onPhotoTaken,
        ),
      ),
    );
  }

  @override
  State<DirectCameraGuide> createState() => _DirectCameraGuideState();
}

class _DirectCameraGuideState extends State<DirectCameraGuide> {
  bool _isCapturing = false;
  bool _isAligned = true;
  bool _isCameraInitialized = false;
  
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  
  // Données d'orientation
  double _roll = 0.0;
  double _pitch = 0.0;
  StreamSubscription? _accelerometerSubscription;

  @override
  void initState() {
    super.initState();
    // Forcer l'orientation paysage pour cet écran
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);
    // Initialiser la caméra
    _initializeCamera();
    
    // Écouter les données d'orientation
    _accelerometerSubscription = accelerometerEvents.listen((AccelerometerEvent event) {
      if (mounted) {
        setState(() {
          // Calculer l'orientation (roll et pitch)
          _roll = event.y;
          _pitch = event.x;
          
          // Vérifier si l'appareil est correctement aligné
          // (tolère une légère inclinaison de ±0.3 radians)
          _isAligned = (_roll.abs() < 0.3 && _pitch.abs() < 0.3);
        });
      }
    });
  }
  
  // Initialiser la caméra
  Future<void> _initializeCamera() async {
    try {
      // Obtenir la liste des caméras disponibles
      _cameras = await availableCameras();
      
      if (_cameras != null && _cameras!.isNotEmpty) {
        // Utiliser la caméra arrière par défaut
        final CameraDescription camera = _cameras!.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.back,
          orElse: () => _cameras!.first,
        );
        
        // Créer et initialiser le contrôleur
        _controller = CameraController(
          camera,
          ResolutionPreset.high,
          enableAudio: false,
          imageFormatGroup: ImageFormatGroup.jpeg,
        );
        
        await _controller!.initialize();
        
        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
          });
        }
      }
    } catch (e) {
      print('Erreur lors de l\'initialisation de la caméra: $e');
    }
  }

  @override
  void dispose() {
    // Libérer les ressources
    _controller?.dispose();
    _accelerometerSubscription?.cancel();
    
    // Rétablir l'orientation automatique
    SystemChrome.setPreferredOrientations([]);
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: OrientationBuilder(
        builder: (context, orientation) {
          // Vérifier que nous sommes bien en mode paysage
          final isLandscape = orientation == Orientation.landscape;
          
          return Stack(
            children: [
              // Aperçu de la caméra en temps réel avec format 4:3
              Positioned.fill(
                child: _isCameraInitialized && _controller != null && _controller!.value.isInitialized
                  ? Center(
                      child: Container(
                        color: Colors.black,
                        child: AspectRatio(
                          aspectRatio: isLandscape ? 4.0 / 3.0 : 3.0 / 4.0,
                          child: CameraPreview(_controller!),
                        ),
                      ),
                    )
                  : Container(
                      color: Colors.black,
                      child: Center(
                        child: Text(
                          _isCameraInitialized ? 'Préparation de la caméra...' : 'Initialisation de la caméra...',
                          style: const TextStyle(color: Colors.white54),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
              ),
              
              // Message indiquant d'utiliser le mode paysage si nécessaire
              if (!isLandscape)
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.black.withOpacity(0.7),
                    child: const Text(
                      'Veuillez tourner votre appareil en mode paysage',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              
              // Indicateur d'orientation (niveau à bulle visuel)
              Positioned(
                top: 20,
                left: 20,
                child: RotationTransition(
                  turns: AlwaysStoppedAnimation(_roll / (2 * 3.14159)),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _isAligned ? Colors.green.withOpacity(0.7) : Colors.red.withOpacity(0.7),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_upward,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),

              // Guides visuels superposés
              Positioned.fill(
                child: _buildOverlays(),
              ),

              // Indicateur d'alignement
              Positioned(
                top: 60,
                left: 0,
                right: 0,
                child: Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _isAligned 
                          ? Colors.green.withOpacity(0.7) 
                          : Colors.red.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _isAligned 
                          ? 'Bien aligné ✓' 
                          : 'Ajustez l\'angle ✗',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),

              // Conseils spécifiques au type de photo
              Positioned(
                bottom: 120,
                left: 20,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _getTipsForPhotoType(),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

              // Bouton de capture
              Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: _isCapturing || !_isAligned ? null : _capturePhoto,
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _isAligned ? Colors.white : Colors.white38,
                          width: 4,
                        ),
                        color: _isAligned ? Colors.white24 : Colors.black38,
                      ),
                      child: _isCapturing
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            )
                          : Icon(
                              Icons.camera_alt,
                              color: _isAligned ? Colors.white : Colors.white38,
                              size: 30,
                            ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOverlays() {
    return Stack(
      children: [
        // Cadre de guidage avec règle des tiers
        Positioned.fill(
          child: CustomPaint(
            painter: GridPainter(),
          ),
        ),
        
        // Guide spécifique au type de photo
        Positioned.fill(
          child: CustomPaint(
            painter: PhotoTypeGuidePainter(widget.photoType),
          ),
        ),
        
        // Niveau à bulle horizontal
        Positioned(
          top: 100,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              width: 200,
              height: 30,
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Stack(
                children: [
                  // Indicateur de niveau
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                    left: _isAligned ? 85 : (_roll > 0 ? 120 : 50),
                    top: 5,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: _isAligned ? Colors.green : Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        
        // Flèches directionnelles pour guider l'utilisateur
        Positioned(
          top: MediaQuery.of(context).size.height / 2 - 100,
          left: 20,
          child: _buildDirectionArrow(Icons.arrow_back, _roll < -0.1),
        ),
        Positioned(
          top: MediaQuery.of(context).size.height / 2 - 100,
          right: 20,
          child: _buildDirectionArrow(Icons.arrow_forward, _roll > 0.1),
        ),
        Positioned(
          top: MediaQuery.of(context).size.height / 2 - 150,
          left: MediaQuery.of(context).size.width / 2 - 25,
          child: _buildDirectionArrow(Icons.arrow_upward, _pitch < -0.1),
        ),
        Positioned(
          top: MediaQuery.of(context).size.height / 2 - 50,
          left: MediaQuery.of(context).size.width / 2 - 25,
          child: _buildDirectionArrow(Icons.arrow_downward, _pitch > 0.1),
        ),
        
        // Conseils spécifiques au type de photo
        Positioned(
          bottom: 100,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _getPhotoTypeInstructions(),
                style: const TextStyle(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDirectionArrow(IconData icon, bool show) {
    return Visibility(
      visible: show,
      child: Icon(
        icon,
        color: Colors.white,
        size: 30,
      ),
    );
  }

  String _getPhotoTypeInstructions() {
    switch (widget.photoType) {
      case 'Vue avant plein centre':
        return 'Positionnez-vous face au véhicule. Assurez-vous que tout l\'avant est visible.';
      
      case 'Vue arrière plein centre':
        return 'Positionnez-vous derrière le véhicule. Assurez-vous que la plaque est visible.';
      
      case 'Vue latérale gauche':
      case 'Vue latérale droite':
        return 'Positionnez-vous perpendiculairement au véhicule. Capturez toute la longueur.';
      
      case 'Avant ¾ gauche':
      case 'Avant ¾ droit':
        return 'Positionnez-vous à 45° par rapport à l\'avant. Capturez l\'avant et le côté.';
      
      case 'Arrière ¾ gauche':
      case 'Arrière ¾ droit':
        return 'Positionnez-vous à 45° par rapport à l\'arrière. Capturez l\'arrière et le côté.';
      
      default:
        return 'Tenez votre téléphone horizontalement. Assurez-vous que l\'éclairage est suffisant.';
    }
  }

  String _getTipsForPhotoType() {
    switch (widget.photoType) {
      case 'Vue avant plein centre':
        return 'Positionnez-vous face au véhicule. Assurez-vous que tout l\'avant est visible.';
      
      case 'Vue arrière plein centre':
        return 'Positionnez-vous derrière le véhicule. Assurez-vous que la plaque est visible.';
      
      case 'Vue latérale gauche':
      case 'Vue latérale droite':
        return 'Positionnez-vous perpendiculairement au véhicule. Capturez toute la longueur.';
      
      case 'Avant ¾ gauche':
      case 'Avant ¾ droit':
        return 'Positionnez-vous à 45° par rapport à l\'avant. Capturez l\'avant et le côté.';
      
      case 'Arrière ¾ gauche':
      case 'Arrière ¾ droit':
        return 'Positionnez-vous à 45° par rapport à l\'arrière. Capturez l\'arrière et le côté.';
      
      default:
        return 'Tenez votre téléphone horizontalement. Assurez-vous que l\'éclairage est suffisant.';
    }
  }

  Future<void> _capturePhoto() async {
    if (_isCapturing || !_isCameraInitialized || _controller == null || !_controller!.value.isInitialized) return;

    setState(() {
      _isCapturing = true;
    });

    try {
      // Prendre la photo avec la caméra
      final XFile photo = await _controller!.takePicture();
      
      if (mounted) {
        // Passer le chemin de la photo au callback
        widget.onPhotoTaken(photo.path);
        Navigator.of(context).pop();
      }
    } catch (e) {
      print('Erreur lors de la prise de photo: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la prise de photo: $e')),
        );
        setState(() {
          _isCapturing = false;
        });
      }
    }
  }
}

/// Painter pour dessiner la grille de règle des tiers
class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white30
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Dessiner la grille des tiers (règle des tiers)
    final double w = size.width;
    final double h = size.height;

    // Lignes verticales
    canvas.drawLine(Offset(w / 3, 0), Offset(w / 3, h), paint);
    canvas.drawLine(Offset(2 * w / 3, 0), Offset(2 * w / 3, h), paint);

    // Lignes horizontales
    canvas.drawLine(Offset(0, h / 3), Offset(w, h / 3), paint);
    canvas.drawLine(Offset(0, 2 * h / 3), Offset(w, 2 * h / 3), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class PhotoTypeGuidePainter extends CustomPainter {
  final String photoType;
  
  PhotoTypeGuidePainter(this.photoType);
  
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    
    // Peinture pour les lignes guides
    final Paint linePaint = Paint()
      ..color = Colors.yellow.withOpacity(0.7)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    
    // Peinture pour le cercle de focus
    final Paint circlePaint = Paint()
      ..color = Colors.yellow.withOpacity(0.4)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;
    
    // Peinture pour le rectangle de focus (vues latérales)
    final Paint rectPaint = Paint()
      ..color = Colors.yellow.withOpacity(0.4)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;
    
    switch (photoType) {
      case 'Vue avant plein centre':
        // Cercle au centre
        canvas.drawCircle(Offset(w * 0.5, h * 0.5), 40, circlePaint);
        // Ligne verticale centrale
        canvas.drawLine(Offset(w * 0.5, 0), Offset(w * 0.5, h), linePaint);
        break;
        
      case 'Avant ¾ gauche':
        // Cercle à ~60% x / 50% y
        canvas.drawCircle(Offset(w * 0.6, h * 0.5), 40, circlePaint);
        // Diagonale haut gauche vers bas droit
        canvas.drawLine(Offset(0, 0), Offset(w, h), linePaint);
        break;
        
      case 'Vue latérale gauche':
        // Rectangle couvrant 90% largeur
        final Rect rect = Rect.fromLTWH(w * 0.05, h * 0.25, w * 0.9, h * 0.5);
        canvas.drawRect(rect, rectPaint);
        // Lignes horizontales parallèles
        canvas.drawLine(Offset(0, h * 0.25), Offset(w, h * 0.25), linePaint);
        canvas.drawLine(Offset(0, h * 0.75), Offset(w, h * 0.75), linePaint);
        break;
        
      case 'Arrière ¾ gauche':
        // Cercle à ~60% x / 50% y
        canvas.drawCircle(Offset(w * 0.6, h * 0.5), 40, circlePaint);
        // Diagonale bas gauche vers haut droit
        canvas.drawLine(Offset(0, h), Offset(w, 0), linePaint);
        break;
        
      case 'Vue arrière plein centre':
        // Cercle au centre
        canvas.drawCircle(Offset(w * 0.5, h * 0.5), 40, circlePaint);
        // Ligne verticale centrale
        canvas.drawLine(Offset(w * 0.5, 0), Offset(w * 0.5, h), linePaint);
        break;
        
      case 'Arrière ¾ droit':
        // Cercle à ~40% x / 50% y
        canvas.drawCircle(Offset(w * 0.4, h * 0.5), 40, circlePaint);
        // Diagonale haut droit vers bas gauche
        canvas.drawLine(Offset(w, 0), Offset(0, h), linePaint);
        break;
        
      case 'Vue latérale droite':
        // Rectangle couvrant 90% largeur
        final Rect rect = Rect.fromLTWH(w * 0.05, h * 0.25, w * 0.9, h * 0.5);
        canvas.drawRect(rect, rectPaint);
        // Lignes horizontales parallèles
        canvas.drawLine(Offset(0, h * 0.25), Offset(w, h * 0.25), linePaint);
        canvas.drawLine(Offset(0, h * 0.75), Offset(w, h * 0.75), linePaint);
        break;
        
      default:
        // Guide générique
        canvas.drawCircle(Offset(w * 0.5, h * 0.5), 40, circlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
