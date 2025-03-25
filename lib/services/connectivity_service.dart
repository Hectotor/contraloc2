import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ConnectivityService {
  // Singleton pattern
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  // Variables pour la connectivité
  bool _isConnected = true;
  bool _isDialogShowing = false;
  Timer? _connectivityTimer;
  
  // Getters
  bool get isConnected => _isConnected;
  
  // Initialiser la vérification de connectivité
  void initialize(BuildContext context, {Duration checkInterval = const Duration(seconds: 10)}) {
    // Vérifier la connectivité immédiatement
    _checkConnectivity(context);
    
    // Vérifier la connectivité périodiquement
    _connectivityTimer?.cancel();
    _connectivityTimer = Timer.periodic(checkInterval, (_) {
      _checkConnectivity(context);
    });
  }
  
  // Arrêter la vérification de connectivité
  void dispose() {
    _connectivityTimer?.cancel();
    _connectivityTimer = null;
  }
  
  // Vérifier la connectivité en essayant d'accéder à Google
  Future<void> _checkConnectivity(BuildContext context) async {
    bool previousConnectionState = _isConnected;
    
    try {
      final response = await http.get(Uri.parse('https://www.google.com')).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw TimeoutException('Timeout');
        },
      );
      
      if (response.statusCode == 200) {
        _isConnected = true;
        
        // Si nous sommes connectés et que le dialogue est affiché, le fermer
        if (_isDialogShowing && context.mounted) {
          Navigator.of(context, rootNavigator: true).pop();
          _isDialogShowing = false;
        }
      } else {
        _isConnected = false;
      }
    } catch (e) {
      _isConnected = false;
    }
    
    // Si l'état de connexion a changé et que nous sommes maintenant déconnectés
    if (previousConnectionState && !_isConnected && !_isDialogShowing && context.mounted) {
      _showNoInternetDialog(context);
    }
  }
  
  // Afficher le dialogue d'absence de connexion
  void _showNoInternetDialog(BuildContext context) {
    if (_isDialogShowing || !context.mounted) return;
    
    _isDialogShowing = true;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return WillPopScope(
          // Empêcher la fermeture du dialogue avec le bouton retour
          onWillPop: () async => false,
          child: AlertDialog(
            title: const Text(
              'Pas de connexion Internet',
              style: TextStyle(
                color: Color(0xFF08004D),
                fontWeight: FontWeight.bold,
              ),
            ),
            content: const Text(
              'Vous n\'êtes pas connecté à Internet. Certaines fonctionnalités de l\'application peuvent ne pas fonctionner correctement.',
              style: TextStyle(fontSize: 16),
            ),
            actions: <Widget>[
              // Ajouter un espace au-dessus du bouton pour le descendre
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  // Style de pilule bleue
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF08004D),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                    elevation: 3,
                  ),
                  onPressed: () async {
                    // Afficher un indicateur de chargement amélioré
                    _showLoadingDialog(dialogContext);
                    
                    // Attendre 3 secondes pour l'affichage du dialogue de chargement
                    await Future.delayed(const Duration(seconds: 3));
                    
                    // Vérifier la connectivité
                    bool isConnected = await checkConnectivity();
                    
                    // Fermer l'indicateur de chargement
                    if (dialogContext.mounted) {
                      Navigator.of(dialogContext, rootNavigator: true).pop();
                    }
                    
                    // Si nous sommes connectés, fermer le dialogue principal
                    if (isConnected && dialogContext.mounted) {
                      Navigator.of(dialogContext, rootNavigator: true).pop();
                      _isDialogShowing = false;
                    }
                  },
                  
                  child: const Text(
                    'Rafraîchir',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              // Ajouter un espace en bas pour une meilleure apparence
              const SizedBox(height: 10),
            ],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            backgroundColor: Colors.white,
            elevation: 5,
          ),
        );
      },
    ).then((_) {
      // Ce callback ne sera appelé que si le dialogue est fermé par programmation
      // (c'est-à-dire lorsque la connexion est rétablie)
      _isDialogShowing = false;
    });
  }
  
  // Afficher un dialogue de chargement amélioré
  void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext loadingContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          backgroundColor: Colors.white,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Spinner de chargement personnalisé
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF08004D)),
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Vérification de la connexion...',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF08004D),
                ),
              ),
              const SizedBox(height: 10),
              // Compteur de temps
              TweenAnimationBuilder<int>(
                tween: IntTween(begin: 3, end: 0),
                duration: const Duration(seconds: 3),
                builder: (context, value, child) {
                  return Text(
                    '$value seconde${value > 1 ? 's' : ''} restante${value > 1 ? 's' : ''}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
  
  // Vérifier manuellement la connectivité (peut être appelé depuis n'importe où)
  Future<bool> checkConnectivity() async {
    try {
      final response = await http.get(Uri.parse('https://www.google.com')).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw TimeoutException('Timeout');
        },
      );
      
      _isConnected = response.statusCode == 200;
      return _isConnected;
    } catch (e) {
      _isConnected = false;
      return false;
    }
  }
}
