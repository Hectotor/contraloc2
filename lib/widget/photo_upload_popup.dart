import 'package:flutter/material.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:contraloc/services/collaborateur_util.dart';

class PhotoUploadPopup extends StatefulWidget {
  final List<File> photos;
  final Function(List<String>) onUploadComplete;
  final String contratId;

  const PhotoUploadPopup({
    Key? key,
    required this.photos,
    required this.onUploadComplete,
    required this.contratId,
  }) : super(key: key);

  @override
  State<PhotoUploadPopup> createState() => _PhotoUploadPopupState();
}

class _PhotoUploadPopupState extends State<PhotoUploadPopup> {
  List<double> progressValues = [];
  List<String> uploadStatus = [];
  List<String> uploadedUrls = [];
  bool isUploading = false;

  @override
  void initState() {
    super.initState();
    progressValues = List.generate(widget.photos.length, (index) => 0.0);
    uploadStatus = List.generate(widget.photos.length, (index) => 'pending');
    _startUpload();
  }

  Future<void> _startUpload() async {
    setState(() {
      isUploading = true;
    });

    for (int i = 0; i < widget.photos.length; i++) {
      try {
        setState(() {
          uploadStatus[i] = 'uploading';
        });

        // Compresser l'image
        final compressedImage = await FlutterImageCompress.compressWithFile(
          widget.photos[i].absolute.path,
          minWidth: 800,
          minHeight: 800,
          quality: 70,
        );

        if (compressedImage == null) {
          setState(() {
            uploadStatus[i] = 'error';
            progressValues[i] = 0.0;
          });
          continue;
        }

        // Obtenir les informations de l'utilisateur
        final status = await CollaborateurUtil.checkCollaborateurStatus();
        final userId = status['userId'];
        final targetId = status['isCollaborateur'] ? status['adminId'] : userId;

        if (targetId == null) {
          setState(() {
            uploadStatus[i] = 'error';
            progressValues[i] = 0.0;
          });
          continue;
        }

        // Préparer le chemin de stockage
        String fileName = 'retour_${DateTime.now().millisecondsSinceEpoch}_${i + 1}.jpg';
        String storagePath = 'users/${targetId}/locations/${widget.contratId}/photos_retour/$fileName';

        // Créer un fichier temporaire
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/$fileName');
        await tempFile.writeAsBytes(compressedImage);

        // Uploader l'image
        Reference ref = FirebaseStorage.instance.ref().child(storagePath);
        final uploadTask = ref.putFile(tempFile);

        // Suivre la progression
        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          if (snapshot.totalBytes > 0) {
            double progress = (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
            setState(() {
              progressValues[i] = progress / 100;
            });
          }
        });

        // Attendre la fin de l'upload
        final snapshot = await uploadTask.whenComplete(() {});

        if (snapshot.state == TaskState.success) {
          String downloadUrl = await snapshot.ref.getDownloadURL();
          setState(() {
            uploadStatus[i] = 'success';
            uploadedUrls.add(downloadUrl);
            
            // Si c'est la dernière photo, fermer automatiquement le popup
            if (i == widget.photos.length - 1) {
              widget.onUploadComplete(uploadedUrls);
              Navigator.of(context).pop(uploadedUrls);
            }
          });
        } else {
          setState(() {
            uploadStatus[i] = 'error';
            progressValues[i] = 0.0;
          });
        }

      } catch (e) {
        print('Erreur lors du téléchargement de la photo $i : $e');
        setState(() {
          uploadStatus[i] = 'error';
          progressValues[i] = 0.0;
        });
      }
    }

    setState(() {
      isUploading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 300,
        height: 300, // Hauteur fixe pour un popup carré
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Téléchargement des photos',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.photos.length,
                physics: const AlwaysScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 5,
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Photo ${index + 1}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                if (uploadStatus[index] == 'success')
                                  Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                    size: 20,
                                  )
                                else if (uploadStatus[index] == 'error')
                                  Icon(
                                    Icons.error,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: progressValues[index],
                              backgroundColor: Colors.grey[200],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                uploadStatus[index] == 'success'
                                    ? Colors.green
                                    : uploadStatus[index] == 'error'
                                        ? Colors.red
                                        : Theme.of(context).primaryColor,
                              ),
                              minHeight: 4,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              uploadStatus[index] == 'success'
                                  ? 'Téléchargée'
                                  : uploadStatus[index] == 'error'
                                      ? 'Échec'
                                      : '${(progressValues[index] * 100).toStringAsFixed(0)}%',
                              style: TextStyle(
                                color: uploadStatus[index] == 'success'
                                    ? Colors.green
                                    : uploadStatus[index] == 'error'
                                        ? Colors.red
                                        : Colors.black87,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${uploadedUrls.length}/${widget.photos.length} photos téléchargées',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
