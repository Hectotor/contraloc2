import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class BackgroundRemovalService {
  /// Clé API pour remove.bg
  /// Vous devez obtenir une clé API sur https://www.remove.bg/
  static const String apiKey = 'VOTRE_CLE_API_REMOVE_BG';
  
  /// Supprime l'arrière-plan d'une image et le remplace par l'image background_car.png
  /// en utilisant directement l'API remove.bg
  static Future<String?> removeBackground(String imagePath) async {
    try {
      // Vérification de la clé API
      if (apiKey == 'VOTRE_CLE_API_REMOVE_BG') {
        throw Exception('Veuillez configurer votre clé API remove.bg');
      }
      
      // Charger l'image d'arrière-plan
      final backgroundImageFile = await _getBackgroundImageFile();
      
      // Configuration de la requête
      final request = http.MultipartRequest(
        'POST', 
        Uri.parse('https://api.remove.bg/v1.0/removebg')
      );
      
      // Ajouter les en-têtes
      request.headers['X-Api-Key'] = apiKey;
      
      // Ajouter l'image principale
      request.files.add(
        await http.MultipartFile.fromPath(
          'image_file',
          imagePath,
        )
      );
      
      // Ajouter l'image d'arrière-plan
      request.files.add(
        await http.MultipartFile.fromPath(
          'bg_image_file',
          backgroundImageFile.path,
        )
      );
      
      // Ajouter les autres paramètres
      request.fields['size'] = 'auto';
      request.fields['format'] = 'auto';
      
      // Envoi de la requête à l'API
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      // Vérification de la réponse
      if (response.statusCode == 200) {
        // Sauvegarde de l'image traitée
        final directory = await getTemporaryDirectory();
        final fileName = path.basenameWithoutExtension(imagePath) + '_with_bg.png';
        final filePath = path.join(directory.path, fileName);
        
        await File(filePath).writeAsBytes(response.bodyBytes);
        return filePath;
      } else {
        throw Exception('Erreur lors de la suppression de l\'arrière-plan: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      debugPrint('Erreur lors de la suppression de l\'arrière-plan: $e');
      return null;
    }
  }
  
  /// Copie l'image d'arrière-plan depuis les assets vers un fichier temporaire
  /// pour pouvoir l'envoyer à l'API remove.bg
  static Future<File> _getBackgroundImageFile() async {
    // Charger l'image d'arrière-plan depuis les assets
    final ByteData backgroundData = await rootBundle.load('assets/background/background_car.png');
    final List<int> bytes = backgroundData.buffer.asUint8List();
    
    // Créer un fichier temporaire
    final directory = await getTemporaryDirectory();
    final tempFile = File(path.join(directory.path, 'background_car_temp.png'));
    
    // Écrire les données dans le fichier
    await tempFile.writeAsBytes(bytes);
    return tempFile;
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
