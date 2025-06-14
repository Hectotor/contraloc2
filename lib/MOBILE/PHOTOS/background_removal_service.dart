import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:image/image.dart' as img;

class BackgroundRemovalService {
  /// Clé API pour remove.bg
  /// Vous devez obtenir une clé API sur https://www.remove.bg/
  static const String apiKey = 'VOTRE_CLE_API_REMOVE_BG';
  
  /// Supprime l'arrière-plan d'une image en utilisant l'API remove.bg
  /// et remplace par l'image background_car.png
  static Future<String?> removeBackground(String imagePath) async {
    try {
      // Vérification de la clé API
      if (apiKey == 'VOTRE_CLE_API_REMOVE_BG') {
        throw Exception('Veuillez configurer votre clé API remove.bg');
      }
      
      // Préparation du fichier image
      final bytes = await File(imagePath).readAsBytes();
      final base64Image = base64Encode(bytes);
      
      // Configuration de la requête
      final Map<String, String> headers = {
        'X-Api-Key': apiKey,
        'Content-Type': 'application/json',
      };
      
      // Préparation des données de la requête
      final Map<String, dynamic> requestData = {
        'image_file_b64': base64Image,
        'size': 'auto',
        'format': 'png',
        'bg_image_file': 'none', // Demander une image avec fond transparent
      };
      
      // Envoi de la requête à l'API
      final response = await http.post(
        Uri.parse('https://api.remove.bg/v1.0/removebg'),
        headers: headers,
        body: jsonEncode(requestData),
      );
      
      // Vérification de la réponse
      if (response.statusCode == 200) {
        // Sauvegarde temporaire de l'image sans arrière-plan
        final directory = await getTemporaryDirectory();
        final tempFileName = path.basenameWithoutExtension(imagePath) + '_temp_nobg.png';
        final tempFilePath = path.join(directory.path, tempFileName);
        
        await File(tempFilePath).writeAsBytes(response.bodyBytes);
        
        // Maintenant, fusionner avec l'image d'arrière-plan
        final finalFilePath = await _mergeWithBackground(tempFilePath);
        
        // Supprimer le fichier temporaire
        await File(tempFilePath).delete();
        
        return finalFilePath;
      } else {
        throw Exception('Erreur lors de la suppression de l\'arrière-plan: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      debugPrint('Erreur lors de la suppression de l\'arrière-plan: $e');
      return null;
    }
  }
  
  /// Fusionne l'image sans arrière-plan avec l'image d'arrière-plan
  static Future<String> _mergeWithBackground(String foregroundImagePath) async {
    try {
      // Charger l'image d'arrière-plan depuis les assets
      final ByteData backgroundData = await rootBundle.load('assets/background/background_car.png');
      final img.Image? backgroundImage = img.decodeImage(backgroundData.buffer.asUint8List());
      
      // Charger l'image sans arrière-plan
      final File foregroundFile = File(foregroundImagePath);
      final img.Image? foregroundImage = img.decodeImage(await foregroundFile.readAsBytes());
      
      if (backgroundImage == null || foregroundImage == null) {
        throw Exception('Impossible de charger les images');
      }
      
      // Redimensionner l'arrière-plan pour correspondre à l'image du premier plan
      final img.Image resizedBackground = img.copyResize(
        backgroundImage,
        width: foregroundImage.width,
        height: foregroundImage.height,
        interpolation: img.Interpolation.linear
      );
      
      // Superposer l'image du premier plan sur l'arrière-plan
      img.compositeImage(resizedBackground, foregroundImage);
      
      // Sauvegarder l'image fusionnée
      final directory = await getTemporaryDirectory();
      final fileName = path.basenameWithoutExtension(foregroundImagePath) + '_with_bg.png';
      final filePath = path.join(directory.path, fileName);
      
      await File(filePath).writeAsBytes(img.encodePng(resizedBackground));
      return filePath;
    } catch (e) {
      debugPrint('Erreur lors de la fusion des images: $e');
      // En cas d'erreur, retourner l'image sans arrière-plan
      return foregroundImagePath;
    }
  }
  
  /// Affiche un dialogue pour le traitement de l'image
  static Future<void> showProcessingDialog(BuildContext context) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Traitement de l\'image en cours...'),
            ],
          ),
        );
      },
    );
  }
  
  /// Affiche un dialogue d'erreur
  static Future<void> showErrorDialog(BuildContext context, String message) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Erreur'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
