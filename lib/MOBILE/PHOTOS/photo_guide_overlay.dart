import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

/// Widget qui affiche un guide de prise de photo en temps réel
/// pour aider l'utilisateur à prendre des photos optimales de véhicules
class PhotoGuideOverlay extends StatefulWidget {
  final String photoType; // "Vue avant", "Vue côté", "Vue arrière", etc.
  final CameraController cameraController;
  final Function(XFile) onPhotoTaken;

  const PhotoGuideOverlay({
    Key? key,
    required this.photoType,
    required this.cameraController,
    required this.onPhotoTaken,
  }) : super(key: key);

  @override
  State<PhotoGuideOverlay> createState() => _PhotoGuideOverlayState();
}

class _PhotoGuideOverlayState extends State<PhotoGuideOverlay> {
  String _currentTip = "";
  bool _isGuideVisible = true;
  bool _isOptimalPosition = false;

  @override
  void initState() {
    super.initState();
    _setTipForPhotoType();
  }

  void _setTipForPhotoType() {
    switch (widget.photoType) {
      case "Vue avant":
        _currentTip = "Cadrez tout l'avant du véhicule dans le rectangle. Tenez-vous à environ 2-3m et légèrement en hauteur.";
        break;
      case "Vue arrière":
        _currentTip = "Cadrez tout l'arrière du véhicule dans le rectangle. Assurez-vous que la plaque d'immatriculation est visible.";
        break;
      case "Vue côté gauche":
        _currentTip = "Positionnez-vous perpendiculairement au véhicule. Tout le côté doit être visible dans le cadre.";
        break;
      case "Vue côté droit":
        _currentTip = "Positionnez-vous perpendiculairement au véhicule. Tout le côté doit être visible dans le cadre.";
        break;
      case "Vue intérieure":
        _currentTip = "Prenez la photo depuis la porte conducteur ouverte. Capturez le tableau de bord et les sièges avant.";
        break;
      default:
        _currentTip = "Cadrez le véhicule entièrement dans le rectangle guide.";
    }
  }

  void _takePhoto() async {
    try {
      final XFile photo = await widget.cameraController.takePicture();
      widget.onPhotoTaken(photo);
    } catch (e) {
      // Gérer l'erreur
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la prise de photo: $e')),
      );
    }
  }

  void _toggleGuide() {
    setState(() {
      _isGuideVisible = !_isGuideVisible;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Prévisualisation de la caméra
        Positioned.fill(
          child: CameraPreview(widget.cameraController),
        ),
        
        // Guide visuel (rectangle)
        if (_isGuideVisible)
          Positioned.fill(
            child: CustomPaint(
              painter: GuideFramePainter(),
            ),
          ),
        
        // Titre de la vue
        Positioned(
          top: 40,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            color: Colors.black.withOpacity(0.5),
            child: Text(
              widget.photoType,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        
        // Conseils de prise de vue
        if (_isGuideVisible)
          Positioned(
            bottom: 100,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _currentTip,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        
        // Bouton pour prendre la photo
        Positioned(
          bottom: 30,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: _takePhoto,
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF08004D),
                      width: 3,
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: const BoxDecoration(
                        color: Color(0xFF08004D),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Bouton pour afficher/masquer le guide
        Positioned(
          top: 40,
          right: 16,
          child: IconButton(
            icon: Icon(
              _isGuideVisible ? Icons.visibility_off : Icons.visibility,
              color: Colors.white,
            ),
            onPressed: _toggleGuide,
          ),
        ),
        
        // Indicateur de position optimale
        if (_isOptimalPosition && _isGuideVisible)
          Positioned(
            top: 100,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.7),
                borderRadius: BorderRadius.circular(20),
              ),
              margin: const EdgeInsets.symmetric(horizontal: 50),
              child: const Text(
                "Position optimale !",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Peintre personnalisé pour dessiner le cadre guide
class GuideFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double frameWidth = size.width * 0.85;
    final double frameHeight = frameWidth / 4 * 3; // Ratio 4:3
    
    final double left = (size.width - frameWidth) / 2;
    final double top = (size.height - frameHeight) / 2;
    
    final Rect frameRect = Rect.fromLTWH(left, top, frameWidth, frameHeight);
    
    // Rectangle semi-transparent autour du cadre
    final Paint overlayPaint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill;
    
    // Dessiner les 4 rectangles autour du cadre pour créer l'effet de masque
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, top), overlayPaint); // Haut
    canvas.drawRect(Rect.fromLTWH(0, top + frameHeight, size.width, size.height - top - frameHeight), overlayPaint); // Bas
    canvas.drawRect(Rect.fromLTWH(0, top, left, frameHeight), overlayPaint); // Gauche
    canvas.drawRect(Rect.fromLTWH(left + frameWidth, top, size.width - left - frameWidth, frameHeight), overlayPaint); // Droite
    
    // Cadre blanc pour le guide
    final Paint framePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    
    canvas.drawRect(frameRect, framePaint);
    
    // Lignes de la règle des tiers
    final Paint thirdLinesPaint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    
    // Lignes verticales
    final double thirdWidth = frameWidth / 3;
    canvas.drawLine(
      Offset(left + thirdWidth, top),
      Offset(left + thirdWidth, top + frameHeight),
      thirdLinesPaint,
    );
    canvas.drawLine(
      Offset(left + thirdWidth * 2, top),
      Offset(left + thirdWidth * 2, top + frameHeight),
      thirdLinesPaint,
    );
    
    // Lignes horizontales
    final double thirdHeight = frameHeight / 3;
    canvas.drawLine(
      Offset(left, top + thirdHeight),
      Offset(left + frameWidth, top + thirdHeight),
      thirdLinesPaint,
    );
    canvas.drawLine(
      Offset(left, top + thirdHeight * 2),
      Offset(left + frameWidth, top + thirdHeight * 2),
      thirdLinesPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

/// Page qui utilise le PhotoGuideOverlay
class VehiclePhotoGuidePage extends StatefulWidget {
  final String photoType;
  final Function(XFile) onPhotoTaken;

  const VehiclePhotoGuidePage({
    Key? key,
    required this.photoType,
    required this.onPhotoTaken,
  }) : super(key: key);

  @override
  State<VehiclePhotoGuidePage> createState() => _VehiclePhotoGuidePageState();
}

class _VehiclePhotoGuidePageState extends State<VehiclePhotoGuidePage> {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isNotEmpty) {
        _cameraController = CameraController(
          _cameras[0], // Utiliser la caméra arrière par défaut
          ResolutionPreset.high,
          enableAudio: false,
        );
        
        await _cameraController!.initialize();
        
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
        }
      }
    } catch (e) {
      // Gérer l'erreur
      print("Erreur lors de l'initialisation de la caméra: $e");
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized || _cameraController == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    return Scaffold(
      body: PhotoGuideOverlay(
        photoType: widget.photoType,
        cameraController: _cameraController!,
        onPhotoTaken: widget.onPhotoTaken,
      ),
    );
  }
}
