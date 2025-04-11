import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import '../services/collaborateur_util.dart';
import '../services/access_locations.dart';

// Classe pour stocker les informations sur les photos en échec
class PhotoUploadInfo {
  final String contratId;
  final String folder; // 'photos' ou 'photos_retour'
  final List<File> photos;
  final List<String> existingUrls;
  
  PhotoUploadInfo({
    required this.contratId,
    required this.folder,
    required this.photos,
    required this.existingUrls,
  });
}

// Classe pour gérer les notifications globales
class GlobalNotification {
  static final GlobalNotification _instance = GlobalNotification._internal();
  factory GlobalNotification() => _instance;
  GlobalNotification._internal();
  
  // Clé globale pour accéder au NavigatorState
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  
  // Méthode pour afficher une notification de succès
  static void showSuccess(String message, {List<String>? successUrls}) {
    _showNotification(
      message: message,
      backgroundColor: Colors.green.shade800,
      icon: Icons.check_circle,
      durationSeconds: 5,
      onTap: () {
        if (successUrls != null) {
          _showSuccessPhotosDialog(navigatorKey.currentContext!, successUrls);
        }
      },
    );
  }
  
  // Méthode pour afficher une notification d'erreur
  static void showError(String message, {List<File>? failedPhotos}) {
    _showNotification(
      message: message,
      backgroundColor: Colors.red.shade800,
      icon: Icons.error_outline,
      durationSeconds: 6,
      onTap: () {
        if (failedPhotos != null) {
          _showFailedPhotosDialog(navigatorKey.currentContext!, failedPhotos);
        }
      },
    );
  }
  
  // Méthode pour afficher une notification d'information
  static void showInfo(String message) {
    _showNotification(
      message: message,
      backgroundColor: Colors.blue.shade800,
      icon: Icons.info_outline,
      durationSeconds: 4,
    );
  }
  
  // Méthode pour afficher une notification persistante en haut de l'écran
  static OverlayEntry? showPersistentNotification(String message, {Color backgroundColor = Colors.blue}) {
    // Assurez-vous que la clé du scaffold est disponible
    if (navigatorKey.currentState == null || navigatorKey.currentContext == null) return null;
    
    try {
      // Créer un widget de notification persistant
      final overlay = OverlayEntry(
        builder: (context) => Positioned(
          top: AppBar().preferredSize.height + MediaQuery.of(context).padding.top,
          left: 0,
          right: 0,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: backgroundColor,
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      message,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      
      // Ajouter l'overlay à l'écran
      Overlay.of(navigatorKey.currentContext!).insert(overlay);
      
      // Retourner l'overlay pour qu'il puisse être supprimé plus tard
      return overlay;
    } catch (e) {
      print('Erreur lors de l\'affichage de la notification persistante: $e');
      // En cas d'erreur, afficher une notification standard
      showInfo(message);
      return null;
    }
  }
  
  // Supprimer une notification persistante
  static void removePersistentNotification(OverlayEntry? overlay) {
    if (overlay != null) {
      try {
        overlay.remove();
      } catch (e) {
        print('Erreur lors de la suppression de la notification persistante: $e');
      }
    }
  }
  
  // Méthode privée pour afficher une notification
  static void _showNotification({
    required String message,
    required Color backgroundColor,
    required IconData icon,
    int durationSeconds = 3,
    VoidCallback? onTap,
  }) {
    if (navigatorKey.currentContext == null) return;
    
    final snackBar = SnackBar(
      content: Row(
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message),
              ],
            ),
          ),
        ],
      ),
      backgroundColor: backgroundColor,
      duration: Duration(seconds: durationSeconds),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      action: onTap != null ? SnackBarAction(
        label: 'Voir',
        textColor: Colors.white,
        onPressed: onTap,
      ) : null,
    );
    
    ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(snackBar);
  }
  
  // Afficher une boîte de dialogue avec les photos en échec
  static void _showFailedPhotosDialog(BuildContext context, List<File> failedPhotos) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Photos non téléchargées"),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              const Text("Les photos suivantes n'ont pas pu être téléchargées:"),
              const SizedBox(height: 16),
              ...failedPhotos.asMap().entries.map((entry) {
                final index = entry.key;
                final photo = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.file(
                          photo,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text("Photo ${index + 1}", style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Fermer"),
          ),
        ],
      ),
    );
  }

  // Afficher une boîte de dialogue avec les photos téléchargées avec succès
  static void _showSuccessPhotosDialog(BuildContext context, List<String> successUrls) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Photos téléchargées"),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              const Text("Les photos ont été téléchargées avec succès"),
              const SizedBox(height: 16),
              ...successUrls.asMap().entries.map((entry) {
                final index = entry.key;
                final url = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.network(
                          url,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              width: 60,
                              height: 60,
                              color: Colors.grey.shade200,
                              child: const Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 60,
                              height: 60,
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.broken_image, color: Colors.grey),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text("Photo ${index + 1}", style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Fermer"),
          ),
        ],
      ),
    );
  }
}

// Classe singleton pour gérer les photos en échec
class PendingPhotosManager {
  static final PendingPhotosManager _instance = PendingPhotosManager._internal();
  factory PendingPhotosManager() => _instance;
  PendingPhotosManager._internal();

  // Liste des photos en attente de validation
  final Map<String, List<PhotoUploadInfo>> _pendingPhotos = {};
  
  // Overlay pour la notification persistante
  OverlayEntry? _overlayEntry;

  // Ajouter des photos en attente
  void addPendingPhotos(String contratId, PhotoUploadInfo info) {
    _pendingPhotos[contratId] ??= [];
    _pendingPhotos[contratId]!.add(info);
    _updateNotification();
  }

  // Supprimer des photos validées
  void removePendingPhotos(String contratId, List<File> photos) {
    if (_pendingPhotos.containsKey(contratId)) {
      _pendingPhotos[contratId]!.removeWhere((info) {
        return info.photos.every((photo) => photos.contains(photo));
      });
      if (_pendingPhotos[contratId]!.isEmpty) {
        _pendingPhotos.remove(contratId);
      }
      _updateNotification();
    }
  }

  // Mettre à jour la notification
  void _updateNotification() {
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
    }

    if (_pendingPhotos.isNotEmpty) {
      final totalPhotos = _pendingPhotos.values
          .expand((list) => list)
          .map((info) => info.photos.length)
          .reduce((a, b) => a + b);

      _overlayEntry = GlobalNotification.showPersistentNotification(
        "${totalPhotos} photo${totalPhotos > 1 ? 's' : ''} en attente de validation",
        backgroundColor: Colors.orange.shade700,
      );
    }
  }

  // Obtenir les photos en attente pour un contrat
  List<PhotoUploadInfo> getPendingPhotos(String contratId) {
    return _pendingPhotos[contratId] ?? [];
  }

  // Vérifier s'il y a des photos en attente
  bool hasPendingPhotos(String contratId) {
    return _pendingPhotos.containsKey(contratId) && _pendingPhotos[contratId]!.isNotEmpty;
  }
}

class PhotoUploadManager {
  static const int MAX_RETRY_ATTEMPTS = 3;
  
  // Clé globale pour accéder au ScaffoldMessengerState
  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  
  // Méthode pour télécharger des photos en arrière-plan avec réessais automatiques
  static Future<void> uploadPhotosInBackground({
    required BuildContext context,
    required String contratId,
    required List<File> photos,
    required List<String> existingUrls,
    required String folder, // 'photos' ou 'photos_retour'
    Function(List<File>)? onFailure,
    Function()? onSuccess,
    int retryAttempt = 0, // Nombre de tentatives déjà effectuées
  }) async {
    if (photos.isEmpty) return;
    
    try {
      // Message de téléchargement
      String message = retryAttempt > 0 
          ? "Nouvelle tentative de téléchargement (${retryAttempt}/$MAX_RETRY_ATTEMPTS)..."
          : "Téléchargement des photos en arrière-plan...";
      
      print('Début du téléchargement des photos... Tentative ${retryAttempt + 1}');
      
      // Afficher une notification persistante pendant le téléchargement
      GlobalNotification.showPersistentNotification(
        message,
        backgroundColor: Colors.blue.shade700,
      );
      
      // Télécharger les photos
      List<String> newUrls = await _uploadPhotos(contratId, photos, folder);
      print('Photos téléchargées avec succès: ${newUrls.length} photos');
      
      // Supprimer la notification persistante
      GlobalNotification.removePersistentNotification(null);
      
      // Mettre à jour Firestore avec les nouvelles URLs
      List<String> allPhotosUrls = List<String>.from(existingUrls);
      allPhotosUrls.addAll(newUrls);
      
      // Déterminer le nom du champ Firestore en fonction du dossier
      String fieldName = folder == 'photos_retour' ? 'photosRetourUrls' : 'photosUrls';
      
      // Mettre à jour Firestore
      await _updateFirestore(contratId, fieldName, allPhotosUrls);
      
      // Supprimer les photos de la liste des photos en attente
      if (folder == 'photos_retour') {
        PendingPhotosManager().removePendingPhotos(contratId, photos);
      }
      
      // Afficher le message de succès
      GlobalNotification.showSuccess(
        "${newUrls.length} photo${newUrls.length > 1 ? 's' : ''} téléchargée${newUrls.length > 1 ? 's' : ''} avec succès.",
        successUrls: newUrls,
      );
      
      // Appeler le callback de succès
      if (onSuccess != null) {
        onSuccess();
      }
    } catch (e) {
      print('Erreur lors du téléchargement des photos: $e');
      
      // Ajouter les photos en échec à la liste des photos en attente
      if (folder == 'photos_retour') {
        PendingPhotosManager().addPendingPhotos(contratId, PhotoUploadInfo(
          contratId: contratId,
          folder: folder,
          photos: photos,
          existingUrls: existingUrls,
        ));
      }
      
      // Afficher une notification persistante d'échec
      GlobalNotification.showPersistentNotification(
        "${photos.length} photo${photos.length > 1 ? 's' : ''} n'a pas pu être téléchargée${photos.length > 1 ? 's' : ''} après plusieurs tentatives.",
        backgroundColor: Colors.red.shade700,
      );
      
      // Vérifier si nous pouvons réessayer
      if (retryAttempt < MAX_RETRY_ATTEMPTS - 1) {
        // Attendre 2 secondes avant de réessayer
        await Future.delayed(const Duration(seconds: 2));
        
        // Réessayer le téléchargement
        return uploadPhotosInBackground(
          context: context,
          contratId: contratId,
          photos: photos,
          existingUrls: existingUrls,
          folder: folder,
          onFailure: onFailure,
          onSuccess: onSuccess,
          retryAttempt: retryAttempt + 1,
        );
      }
      
      // Appeler le callback d'erreur
      if (onFailure != null) {
        onFailure(photos);
      }
    }
  }
  
  // Méthode pour télécharger manuellement des photos (sans overlay)
  static Future<void> uploadPhotosManually({
    required BuildContext context,
    required String contratId,
    required List<File> photos,
    required List<String> existingUrls,
    required String folder, // 'photos' ou 'photos_retour'
    Function(List<File>)? onFailure,
    Function()? onSuccess,
  }) async {
    if (photos.isEmpty) return;
    
    try {
      // Afficher un indicateur de chargement simple
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text("Téléchargement des photos en cours..."),
            ],
          ),
        ),
      );
      
      // Télécharger les photos
      List<String> newUrls = await _uploadPhotos(contratId, photos, folder);
      
      // Mettre à jour Firestore avec les nouvelles URLs
      List<String> allPhotosUrls = List<String>.from(existingUrls);
      allPhotosUrls.addAll(newUrls);
      
      // Déterminer le nom du champ Firestore en fonction du dossier
      String fieldName = folder == 'photos_retour' ? 'photosRetourUrls' : 'photosUrls';
      
      // Mettre à jour Firestore
      await _updateFirestore(contratId, fieldName, allPhotosUrls);
      
      // Fermer la boîte de dialogue de chargement
      Navigator.of(context).pop();
      
      // Afficher le message de succès
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("${newUrls.length} photo${newUrls.length > 1 ? 's' : ''} téléchargée${newUrls.length > 1 ? 's' : ''} avec succès."),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 5),
        ),
      );
      
      // Appeler le callback de succès
      if (onSuccess != null) {
        onSuccess();
      }
    } catch (e) {
      print('Erreur lors du téléchargement manuel des photos: $e');
      
      // Fermer la boîte de dialogue de chargement si elle est ouverte
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
      
      // Afficher le message d'erreur
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur lors du téléchargement des photos: $e"),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 6),
        ),
      );
      
      // Appeler le callback d'erreur
      if (onFailure != null) {
        onFailure(photos);
      }
    }
  }
  
  // Méthode privée pour télécharger les photos
  static Future<List<String>> _uploadPhotos(String contratId, List<File> photos, String folder) async {
    List<String> urls = [];
    int startIndex = 0;

    try {
      final status = await CollaborateurUtil.checkCollaborateurStatus();
      final userId = status['userId'];

      if (userId == null) {
        print(" Erreur: Utilisateur non connecté");
        throw Exception("Utilisateur non connecté");
      }

      final targetId = status['isCollaborateur'] ? status['adminId'] : userId;

      if (targetId == null) {
        print(" Erreur: ID cible non disponible");
        throw Exception("ID cible non disponible");
      }

      print(" Téléchargement de photos par ${status['isCollaborateur'] ? 'collaborateur' : 'admin'}");
      print(" userId: $userId, targetId (adminId): $targetId");

      for (var photo in photos) {
        final compressedImage = await FlutterImageCompress.compressWithFile(
          photo.absolute.path,
          minWidth: 800,
          minHeight: 800,
          quality: 70, 
        );

        if (compressedImage == null) {
          print(" Erreur: Échec de la compression de l'image");
          continue;
        }

        String fileName =
            '${DateTime.now().millisecondsSinceEpoch}_${startIndex + urls.length}.jpg';

        final String storagePath = 'users/${targetId}/locations/${contratId}/${folder}/$fileName';

        Reference ref = FirebaseStorage.instance.ref().child(storagePath);

        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/$fileName');
        await tempFile.writeAsBytes(compressedImage);

        // Ajouter des métadonnées
        final metadata = SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'uploaded_by': status['isCollaborateur'] ? 'collaborateur' : 'admin',
            'uploaded_by_id': userId,
          },
        );

        await ref.putFile(tempFile, metadata);

        String downloadUrl = await ref.getDownloadURL();
        urls.add(downloadUrl);
      }
      return urls;
    } catch (e) {
      print(' Erreur lors du téléchargement des photos : $e');
      if (e.toString().contains('unauthorized')) {
        print(' Problème d\'autorisation: Vérifiez les règles de sécurité Firebase Storage');
      }
      rethrow;
    }
  }
  
  // Méthode pour mettre à jour Firestore
  static Future<void> _updateFirestore(String contratId, String fieldName, List<String> allPhotosUrls) async {
    await AccessLocations.updateContract(contratId, {
      fieldName: allPhotosUrls,
    });
  }
  
  // Méthode pour valider les photos en attente
  static Future<void> validatePendingPhotos(BuildContext context, String contratId) async {
    final pendingPhotos = PendingPhotosManager().getPendingPhotos(contratId);
    
    if (pendingPhotos.isEmpty) return;
    
    try {
      // Afficher un indicateur de chargement
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text("Validation des photos en cours...")
            ],
          ),
        ),
      );
      
      // Valider chaque photo en attente
      for (final info in pendingPhotos) {
        await uploadPhotosInBackground(
          context: context,
          contratId: info.contratId,
          photos: info.photos,
          existingUrls: info.existingUrls,
          folder: info.folder,
        );
      }
      
      // Fermer la boîte de dialogue
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
      
      // Afficher le message de succès
      GlobalNotification.showSuccess(
        "Les photos ont été validées avec succès.",
      );
    } catch (e) {
      print('Erreur lors de la validation des photos: $e');
      
      // Afficher le message d'erreur
      GlobalNotification.showError(
        "Erreur lors de la validation des photos: $e",
      );
    }
  }

  // Widget pour afficher les photos en échec et permettre de réessayer le téléchargement
  static Widget buildPhotosEnEchecWidget({
    required BuildContext context,
    required List<File> photosEnEchec,
    required String contratId,
    required List<String> existingUrls,
    required String folder,
    Function(List<File>)? onFailure,
    Function()? onSuccess,
  }) {
    if (photosEnEchec.isEmpty) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red.shade700),
              const SizedBox(width: 8),
              Text(
                'Photos en attente de téléchargement',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Certaines photos n\'ont pas pu être téléchargées. Vous pouvez réessayer le téléchargement.',
            style: TextStyle(color: Colors.red.shade700),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 70,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: photosEnEchec.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(7),
                    child: Image.file(
                      photosEnEchec[index],
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: () {
              // Utiliser notre nouveau système de notification global
              uploadPhotosInBackground(
                context: context,
                contratId: contratId,
                photos: photosEnEchec,
                existingUrls: existingUrls,
                folder: folder,
                onFailure: onFailure,
                onSuccess: onSuccess,
              );
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer le téléchargement'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade100,
              foregroundColor: Colors.red.shade700,
            ),
          ),
        ],
      ),
    );
  }

  // Méthode pour construire un widget permettant de télécharger manuellement les photos en échec
  static Widget buildManualUploadWidget({
    required BuildContext context,
    required String contratId,
    required List<File> failedPhotos,
    required List<String> existingUrls,
    required String folder,
    Function()? onSuccess,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red.shade700),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "${failedPhotos.length} photo${failedPhotos.length > 1 ? 's' : ''} en attente de téléchargement",
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "Le téléchargement automatique a échoué. Vous pouvez essayer de télécharger manuellement.",
            style: TextStyle(color: Colors.red.shade800),
          ),
          const SizedBox(height: 16),
          // Afficher les miniatures des photos en échec
          if (failedPhotos.isNotEmpty)
            SizedBox(
              height: 70,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: failedPhotos.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.file(
                        failedPhotos[index],
                        width: 70,
                        height: 70,
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 16),
          // Bouton pour télécharger manuellement
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                uploadPhotosManually(
                  context: context,
                  contratId: contratId,
                  photos: failedPhotos,
                  existingUrls: existingUrls,
                  folder: folder,
                  onSuccess: onSuccess,
                );
              },
              icon: const Icon(Icons.upload_file),
              label: const Text("Télécharger manuellement"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget pour afficher les photos en attente de validation
  static Widget buildPendingPhotosWidget({
    required BuildContext context,
    required String contratId,
    Function()? onValidate,
  }) {
    final pendingPhotos = PendingPhotosManager().getPendingPhotos(contratId);
    
    if (pendingPhotos.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.pending_actions, color: Colors.orange.shade700),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "${pendingPhotos.length} photo${pendingPhotos.length > 1 ? 's' : ''} en attente de validation",
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange.shade700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "Ces photos doivent être validées avant de pouvoir être utilisées.",
            style: TextStyle(color: Colors.orange.shade800),
          ),
          const SizedBox(height: 16),
          // Afficher les miniatures des photos en attente
          if (pendingPhotos.isNotEmpty)
            SizedBox(
              height: 70,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: pendingPhotos.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.file(
                        pendingPhotos[index].photos.first,
                        width: 70,
                        height: 70,
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 16),
          // Bouton de validation
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                if (onValidate != null) {
                  onValidate();
                }
              },
              icon: const Icon(Icons.check_circle),
              label: const Text("Valider les photos"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
