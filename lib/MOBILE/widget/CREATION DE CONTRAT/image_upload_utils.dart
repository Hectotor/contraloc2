import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import '../../services/auth_util.dart';

class ImageUploadUtils {
  /// Compresse et télécharge une photo vers Firebase Storage
  /// 
  /// [photo] - Le fichier image à compresser et télécharger
  /// [folder] - Le dossier de destination dans Firebase Storage
  /// [contratId] - L'identifiant du contrat associé à l'image
  /// 
  /// Retourne l'URL de téléchargement de l'image
  static Future<String> compressAndUploadPhoto(
    File photo, String folder, String contratId) async {
    try {
      print(" Début de compression de l'image: ${photo.absolute.path}");
      print(" Taille de l'image avant compression: ${await photo.length()} octets");

      final compressedImage = await FlutterImageCompress.compressWithFile(
        photo.absolute.path,
        minWidth: 800,
        minHeight: 800,
        quality: 85,
      );

      if (compressedImage != null) {
        print(" Compression réussie, taille après compression: ${compressedImage.length} octets");

        final status = await AuthUtil.getAuthData();
        final userId = status['adminId'];

        if (userId == null) {
          print(" Erreur: Utilisateur non connecté");
          throw Exception("Utilisateur non connecté");
        }

        final targetId = status['isCollaborateur'] ? status['adminId'] : userId;

        if (targetId == null) {
          print(" Erreur: ID cible non disponible");
          throw Exception("ID cible non disponible");
        }

        print(" Téléchargement d'image par ${status['isCollaborateur'] ? 'collaborateur' : 'admin'}");
        print(" userId: $userId, targetId (adminId): $targetId");

        // Simplifier le nom de fichier pour éviter les problèmes de chemin
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        String fileName = folder.replaceAll('/', '_') + "_$timestamp.jpg";

        final String storagePath = 'users/${targetId}/locations/$contratId/$folder/$fileName';
        print(" Chemin de stockage: $storagePath");

        final tempDir = await getTemporaryDirectory();
        // Créer un dossier spécifique pour cette application
        final appTempDir = Directory('${tempDir.path}/contraloc_temp');
        if (!await appTempDir.exists()) {
          print(" Création du dossier temporaire de l'application: ${appTempDir.path}");
          await appTempDir.create(recursive: true);
        } else {
          print(" Dossier temporaire de l'application existant: ${appTempDir.path}");
        }

        final tempFile = File('${appTempDir.path}/$fileName');
        print(" Chemin du fichier temporaire: ${tempFile.path}");
        await tempFile.writeAsBytes(compressedImage);
        print(" Fichier temporaire créé avec succès: ${await tempFile.exists()}");
        print(" Taille du fichier temporaire: ${await tempFile.length()} octets");

        Reference ref = FirebaseStorage.instance.ref().child(storagePath);

        print(" Début du téléchargement...");
        await ref.putFile(tempFile);
        print(" Téléchargement terminé avec succès");

        // Récupérer l'URL de téléchargement
        String downloadUrl = await ref.getDownloadURL();
        print(" URL de téléchargement: $downloadUrl");

        // Supprimer le fichier temporaire après utilisation
        try {
          await tempFile.delete();
          print(" Fichier temporaire supprimé");
        } catch (e) {
          print(" Erreur lors de la suppression du fichier temporaire: $e");
        }

        return downloadUrl;
      }
      throw Exception("Image compression failed");
    } catch (e) {
      print(' Erreur lors du traitement de l\'image : $e');
      if (e.toString().contains('unauthorized')) {
        print(' Problème d\'autorisation: Vérifiez les règles de sécurité Firebase Storage');
      }
      rethrow;
    }
  }

  /// Télécharge une image depuis une URL Firebase Storage et la convertit en fichier local
  /// 
  /// [imageUrl] - L'URL de l'image à télécharger
  /// 
  /// Retourne un fichier local contenant l'image téléchargée, ou null en cas d'erreur
  static Future<File?> downloadImageFromUrl(String imageUrl) async {
    try {
      // Récupérer le répertoire temporaire
      final tempDir = await getTemporaryDirectory();
      final fileName = 'photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final file = File('${tempDir.path}/$fileName');

      // Télécharger l'image depuis l'URL
      final ref = FirebaseStorage.instance.refFromURL(imageUrl);
      final bytes = await ref.getData();

      if (bytes != null) {
        // Écrire les données dans le fichier
        await file.writeAsBytes(bytes);
        return file;
      }
      return null;
    } catch (e) {
      print('Erreur lors du téléchargement de l\'image: $e');
      return null;
    }
  }
}
