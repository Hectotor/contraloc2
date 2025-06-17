import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Guide de caméra intelligent avec assistance en temps réel
class SmartCameraGuide extends StatefulWidget {
  final String photoType;
  final Function(String) onPhotoTaken;
  final VoidCallback? onCancel;

  const SmartCameraGuide({
    Key? key,
    required this.photoType,
    required this.onPhotoTaken,
    this.onCancel,
  }) : super(key: key);

  /// Lance l'interface de prise de photo guidée
  static Future<void> show(
    BuildContext context,
    String photoType,
    Function(String) onPhotoTaken, {
    VoidCallback? onCancel,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SmartCameraGuide(
          photoType: photoType,
          onPhotoTaken: onPhotoTaken,
          onCancel: onCancel,
        ),
      ),
    );
  }

  @override
  State<SmartCameraGuide> createState() => _SmartCameraGuideState();
}

class _SmartCameraGuideState extends State<SmartCameraGuide>
    with TickerProviderStateMixin {
  // État de la caméra
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isCapturing = false;
  double _currentZoom = 1.0; // Zoom standard 1x
  
  // Données d'orientation et d'alignement
  double _roll = 0.0;
  double _pitch = 0.0;
  bool _isAligned = false;
  bool _isStable = false;
  
  // Abonnements aux capteurs
  StreamSubscription? _accelerometerSubscription;
  StreamSubscription? _gyroscopeSubscription;
  
  // Animations
  late AnimationController _pulseController;
  late AnimationController _levelController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _levelAnimation;
  
  // Configuration flash
  FlashMode _flashMode = FlashMode.off;
  
  // Historique de stabilité
  List<double> _stabilityHistory = [];
  Timer? _stabilityTimer;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeCamera();
    _startSensorListening();
    _setupStabilityCheck();
    _lockOrientation();
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _levelController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _levelAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _levelController, curve: Curves.elasticOut),
    );
    
    _pulseController.repeat(reverse: true);
  }

  void _lockOrientation() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      
      if (_cameras != null && _cameras!.isNotEmpty) {
        final camera = _cameras!.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.back,
          orElse: () => _cameras!.first,
        );
        
        _controller = CameraController(
          camera,
          ResolutionPreset.high,
          enableAudio: false,
          imageFormatGroup: ImageFormatGroup.jpeg,
        );
        
        await _controller!.initialize();
        await _controller!.lockCaptureOrientation(DeviceOrientation.landscapeRight);
        
        // Initialisation du zoom standard 1x
        _currentZoom = 1.0;
        await _controller!.setZoomLevel(_currentZoom);
        
        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
          });
        }
      }
    } catch (e) {
      debugPrint('Erreur initialisation caméra: $e');
      _showError('Impossible d\'accéder à la caméra');
    }
  }

  void _startSensorListening() {
    // Accéléromètre pour l'orientation
    _accelerometerSubscription = accelerometerEvents.listen((event) {
      if (mounted) {
        setState(() {
          _roll = event.y;
          _pitch = event.x;
          _updateAlignment();
        });
      }
    });
    
    // Gyroscope pour la stabilité
    _gyroscopeSubscription = gyroscopeEvents.listen((event) {
      if (mounted) {
        final movement = math.sqrt(
          event.x * event.x + event.y * event.y + event.z * event.z
        );
        _stabilityHistory.add(movement);
        if (_stabilityHistory.length > 10) {
          _stabilityHistory.removeAt(0);
        }
      }
    });
  }

  void _setupStabilityCheck() {
    _stabilityTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (_stabilityHistory.isNotEmpty) {
        final avgMovement = _stabilityHistory.reduce((a, b) => a + b) / 
                           _stabilityHistory.length;
        final wasStable = _isStable;
        _isStable = avgMovement < 0.5;
        
        if (!wasStable && _isStable && _isAligned) {
          _levelController.forward();
          HapticFeedback.lightImpact();
        }
      }
    });
  }

  void _updateAlignment() {
    const tolerance = 0.3;
    final wasAligned = _isAligned;
    _isAligned = (_roll.abs() < tolerance && _pitch.abs() < tolerance);
    
    if (!wasAligned && _isAligned) {
      HapticFeedback.selectionClick();
    }
  }

  @override
  void dispose() {
    _restoreOrientation();
    _controller?.dispose();
    _accelerometerSubscription?.cancel();
    _gyroscopeSubscription?.cancel();
    _stabilityTimer?.cancel();
    _pulseController.dispose();
    _levelController.dispose();
    super.dispose();
  }

  void _restoreOrientation() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([]);
  }

  
  Future<void> _capturePhoto() async {
    if (!_canCapture()) return;

    setState(() => _isCapturing = true);
    HapticFeedback.mediumImpact();

    try {
      await _controller!.setFlashMode(_flashMode);
      final photo = await _controller!.takePicture();
      
      if (mounted) {
        widget.onPhotoTaken(photo.path);
        Navigator.of(context).pop();
      }
    } catch (e) {
      debugPrint('Erreur capture: $e');
      _showError('Erreur lors de la prise de photo');
    } finally {
      if (mounted) {
        setState(() => _isCapturing = false);
      }
    }
  }

  bool _canCapture() {
    return _isCameraInitialized && 
           _controller != null && 
           _controller!.value.isInitialized && 
           !_isCapturing &&
           _isAligned &&
           _isStable;
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: OrientationBuilder(
        builder: (context, orientation) {
          final isLandscape = orientation == Orientation.landscape;
          
          return Stack(
            children: [
              // Aperçu caméra
              _buildCameraPreview(),
              
              // Message orientation si nécessaire
              if (!isLandscape) _buildOrientationMessage(),
              
              // Interface utilisateur
              _buildTopBar(),
              _buildBottomBar(),
              _buildAlignmentIndicators(),
              _buildPhotoGuides(),
              _buildInstructions(),
              
              // Bouton de capture hors cadre (comme un appareil photo classique)
              _buildOutsideCaptureButton(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCameraPreview() {
    if (!_isCameraInitialized || 
        _controller == null || 
        !_controller!.value.isInitialized) {
      return Positioned.fill(
        child: Container(
          color: Colors.black,
          child: const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        ),
      );
    }
    
    // Calcul pour garantir un ratio 4:3 exact
    final size = MediaQuery.of(context).size;
    final targetRatio = 4.0 / 3.0;
    
    return Positioned.fill(
      child: Center(
        child: Container(
          color: Colors.black,
          child: Transform.rotate(
            angle: math.pi, // Rotation de 180° pour corriger l'inversion
            child: AspectRatio(
              aspectRatio: targetRatio,
              child: ClipRect(
                child: OverflowBox(
                  alignment: Alignment.center,
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: size.width,
                      height: size.width / targetRatio,
                      child: CameraPreview(_controller!),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrientationMessage() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.screen_rotation, color: Colors.white, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Tournez votre appareil',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Utilisez le mode paysage pour une meilleure prise de vue',
              style: TextStyle(color: Colors.white70, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.only(top: 40, bottom: 16, left: 16, right: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black.withOpacity(0.7), Colors.transparent],
          ),
        ),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 28),
              onPressed: () {
                if (widget.onCancel != null) {
                  widget.onCancel!();
                }
                Navigator.of(context).pop();
              },
            ),
            Expanded(
              child: Text(
                widget.photoType,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            // Espace pour équilibrer l'interface sans le bouton flash
            const SizedBox(width: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Colors.black.withOpacity(0.7), Colors.transparent],
          ),
        ),
        // Barre du bas vide pour conserver le dégradé
        child: const SizedBox(height: 20),
      ),
    );
  }

  // Nouveau bouton de capture positionné sur le côté, hors du cadre photo
  Widget _buildOutsideCaptureButton() {
    return Positioned(
      right: 20,
      top: 0,
      bottom: 0,
      child: Center(
        child: AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return GestureDetector(
              onTap: _capturePhoto,
              child: Transform.scale(
                scale: _canCapture() ? _pulseAnimation.value : 1.0,
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _canCapture() ? Colors.green : Colors.white70,
                      width: 3,
                    ),
                    color: _canCapture() 
                      ? Colors.green.withOpacity(0.4) 
                      : Colors.black.withOpacity(0.7),
                    boxShadow: [
                      BoxShadow(
                        color: _canCapture() ? Colors.green.withOpacity(0.5) : Colors.black.withOpacity(0.5),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: _isCapturing
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Icon(
                        Icons.camera,
                        color: _canCapture() ? Colors.green : Colors.white70,
                        size: 32,
                      ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAlignmentIndicators() {
    return Stack(
      children: [
        // Indicateur d'alignement central
        Positioned(
          top: 80,
          left: 0,
          right: 0,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: _isAligned && _isStable
                  ? Colors.green.withOpacity(0.8)
                  : _isAligned 
                    ? Colors.orange.withOpacity(0.8)
                    : Colors.red.withOpacity(0.8),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isAligned && _isStable
                      ? Icons.check_circle
                      : _isAligned
                        ? Icons.pause_circle
                        : Icons.warning,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isAligned && _isStable
                      ? 'Parfait ! Appuyez pour capturer'
                      : _isAligned
                        ? 'Maintenez stable'
                        : 'Ajustez l\'angle',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        
        // Niveau à bulle
        _buildBubbleLevel(),
        
        // Flèches directionnelles
        _buildDirectionArrows(),
      ],
    );
  }

  Widget _buildBubbleLevel() {
    return Positioned(
      top: 130,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          width: 240,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white24),
          ),
          child: Stack(
            children: [
              // Marques de niveau
              Positioned.fill(
                child: Row(
                  children: [
                    Expanded(flex: 1, child: Container()),
                    Container(width: 2, color: Colors.white38),
                    Expanded(flex: 1, child: Container()),
                    Container(width: 2, color: Colors.white),
                    Expanded(flex: 1, child: Container()),
                    Container(width: 2, color: Colors.white38),
                    Expanded(flex: 1, child: Container()),
                  ],
                ),
              ),
              
              // Bulle
              AnimatedBuilder(
                animation: _levelAnimation,
                builder: (context, child) {
                  final offset = (_roll * 60).clamp(-100.0, 100.0);
                  return AnimatedPositioned(
                    duration: const Duration(milliseconds: 100),
                    left: 120 + offset - 15,
                    top: 5,
                    child: Transform.scale(
                      scale: 1.0 + (_levelAnimation.value * 0.2),
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: _isAligned ? Colors.green : Colors.red,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: (_isAligned ? Colors.green : Colors.red)
                                  .withOpacity(0.5),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDirectionArrows() {
    return Stack(
      children: [
        // Flèche gauche
        if (_roll < -0.1)
          Positioned(
            left: 30,
            top: MediaQuery.of(context).size.height / 2 - 25,
            child: _buildAnimatedArrow(Icons.arrow_back),
          ),
        
        // Flèche droite
        if (_roll > 0.1)
          Positioned(
            right: 30,
            top: MediaQuery.of(context).size.height / 2 - 25,
            child: _buildAnimatedArrow(Icons.arrow_forward),
          ),
        
        // Flèche haut
        if (_pitch < -0.1)
          Positioned(
            left: MediaQuery.of(context).size.width / 2 - 25,
            top: MediaQuery.of(context).size.height / 2 - 100,
            child: _buildAnimatedArrow(Icons.arrow_upward),
          ),
        
        // Flèche bas
        if (_pitch > 0.1)
          Positioned(
            left: MediaQuery.of(context).size.width / 2 - 25,
            top: MediaQuery.of(context).size.height / 2 + 50,
            child: _buildAnimatedArrow(Icons.arrow_downward),
          ),
      ],
    );
  }

  Widget _buildAnimatedArrow(IconData icon) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.8),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 30),
          ),
        );
      },
    );
  }

  Widget _buildPhotoGuides() {
    return Positioned.fill(
      child: CustomPaint(
        painter: SmartGuidePainter(
          photoType: widget.photoType,
          isAligned: _isAligned,
          isStable: _isStable,
        ),
      ),
    );
  }

  Widget _buildInstructions() {
    return Positioned(
      bottom: 140,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          PhotoTypeHelper.getInstructions(widget.photoType),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

/// Helper pour les instructions spécifiques à chaque type de photo
class PhotoTypeHelper {
  static String getInstructions(String photoType) {
    switch (photoType) {
      case 'Vue avant plein centre':
        return 'Placez-vous face au véhicule, centrez-le dans le cadre. Assurez-vous que les phares et la plaque sont visibles.';
      
      case 'Vue arrière plein centre':
        return 'Placez-vous derrière le véhicule, centrez-le dans le cadre. La plaque d\'immatriculation doit être clairement visible.';
      
      case 'Vue latérale gauche':
      case 'Vue latérale droite':
        return 'Positionnez-vous perpendiculairement au véhicule. Capturez toute la longueur du véhicule dans le cadre.';
      
      case 'Avant ¾ gauche':
      case 'Avant ¾ droit':
        return 'Positionnez-vous à 45° par rapport à l\'avant du véhicule. Montrez l\'avant et le côté simultanément.';
      
      case 'Arrière ¾ gauche':
      case 'Arrière ¾ droit':
        return 'Positionnez-vous à 45° par rapport à l\'arrière du véhicule. Montrez l\'arrière et le côté simultanément.';
      
      default:
        return 'Suivez les guides visuels et maintenez l\'appareil stable pour une photo parfaite.';
    }
  }
}

/// Painter amélioré pour les guides visuels
class SmartGuidePainter extends CustomPainter {
  final String photoType;
  final bool isAligned;
  final bool isStable;
  
  SmartGuidePainter({
    required this.photoType,
    required this.isAligned,
    required this.isStable,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    
    // Grille des tiers
    _drawRuleOfThirds(canvas, size);
    
    // Guides spécifiques au type de photo
    _drawPhotoTypeGuide(canvas, size);
    
    // Zone de focus dynamique
    _drawFocusZone(canvas, size);
  }
  
  void _drawRuleOfThirds(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..strokeWidth = 1.0;
    
    final w = size.width;
    final h = size.height;
    
    // Lignes verticales
    canvas.drawLine(Offset(w / 3, 0), Offset(w / 3, h), paint);
    canvas.drawLine(Offset(2 * w / 3, 0), Offset(2 * w / 3, h), paint);
    
    // Lignes horizontales
    canvas.drawLine(Offset(0, h / 3), Offset(w, h / 3), paint);
    canvas.drawLine(Offset(0, 2 * h / 3), Offset(w, 2 * h / 3), paint);
  }
  
  void _drawPhotoTypeGuide(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = (isAligned && isStable ? Colors.green : Colors.orange)
          .withOpacity(0.6)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;
    
    final w = size.width;
    final h = size.height;
    
    switch (photoType) {
      case 'Vue avant plein centre':
      case 'Vue arrière plein centre':
        // Ligne centrale verticale
        canvas.drawLine(Offset(w * 0.5, h * 0.2), Offset(w * 0.5, h * 0.8), paint);
        // Rectangle central
        final rect = Rect.fromCenter(
          center: Offset(w * 0.5, h * 0.5),
          width: w * 0.6,
          height: h * 0.5,
        );
        canvas.drawRect(rect, paint);
        break;
        
      case 'Vue latérale gauche':
      case 'Vue latérale droite':
        // Rectangle horizontal
        final rect = Rect.fromLTWH(w * 0.1, h * 0.3, w * 0.8, h * 0.4);
        canvas.drawRect(rect, paint);
        break;
        
      case 'Avant ¾ gauche':
      case 'Arrière ¾ gauche':
        // Guide diagonal
        canvas.drawLine(Offset(w * 0.2, h * 0.2), Offset(w * 0.8, h * 0.8), paint);
        break;
        
      case 'Avant ¾ droit':
      case 'Arrière ¾ droit':
        // Guide diagonal inverse
        canvas.drawLine(Offset(w * 0.8, h * 0.2), Offset(w * 0.2, h * 0.8), paint);
        break;
    }
  }
  
  void _drawFocusZone(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = (isAligned && isStable ? Colors.green : Colors.red)
          .withOpacity(0.4)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    
    final center = Offset(size.width * 0.5, size.height * 0.5);
    final radius = isAligned && isStable ? 50.0 : 40.0;
    
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}