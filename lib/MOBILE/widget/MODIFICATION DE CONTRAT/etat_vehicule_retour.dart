import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
// Import supprimé car plus nécessaire après la suppression des vérifications premium
import 'package:contraloc/MOBILE/widget/MODIFICATION DE CONTRAT/commentaire_retour.dart';
// Import supprimé car plus nécessaire après la suppression des vérifications premium
// Import supprimé car plus nécessaire après la suppression des vérifications premium

class EtatVehiculeRetour extends StatefulWidget {
  final List<File> photos;
  final Function(File) onAddPhoto;
  final Function(int) onRemovePhoto;
  final TextEditingController? commentaireController;

  const EtatVehiculeRetour({
    Key? key,
    required this.photos,
    required this.onAddPhoto,
    required this.onRemovePhoto,
    this.commentaireController,
  }) : super(key: key);

  @override
  _EtatVehiculeRetourState createState() => _EtatVehiculeRetourState();
}

class _EtatVehiculeRetourState extends State<EtatVehiculeRetour> {
  // Variable isPremiumUser supprimée car tous les utilisateurs peuvent prendre des photos
  late TextEditingController _commentaireController;
  bool _showContent = true;

  void _handleHeaderTap() {
    setState(() {
      _showContent = !_showContent;
    });
  }

  @override
  void initState() {
    super.initState();
    // _initializeSubscription() supprimée car elle ne faisait plus rien
    _commentaireController = widget.commentaireController ?? TextEditingController();
  }

  @override
  void dispose() {
    // Ne pas disposer le contrôleur s'il a été fourni par le parent
    if (widget.commentaireController == null) {
      _commentaireController.dispose();
    }
    super.dispose();
  }

  // Méthode _initializeSubscription supprimée car elle ne faisait plus rien

  // Méthode _showPremiumDialog supprimée car elle n'est plus utilisée

  Future<void> _pickImage() async {
    if (widget.photos.length >= 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Vous ne pouvez ajouter que 10 photos maximum.")),
      );
      return;
    }

    final picker = ImagePicker();
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white, 
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Choisir une option",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF08004D),
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading:
                    const Icon(Icons.photo_camera, color: Color(0xFF08004D)),
                title: const Text('Prendre une photo'),
                onTap: () async {
                  final pickedFile = await picker.pickImage(
                    source: ImageSource.camera,
                    imageQuality: 70,
                  );
                  if (pickedFile != null) {
                    widget.onAddPhoto(File(pickedFile.path));
                  }
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading:
                    const Icon(Icons.photo_library, color: Color(0xFF08004D)),
                title: const Text('Choisir depuis la galerie'),
                onTap: () async {
                  final pickedFile = await picker.pickImage(
                    source: ImageSource.gallery,
                    imageQuality: 70,
                  );
                  if (pickedFile != null) {
                    widget.onAddPhoto(File(pickedFile.path));
                  }
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(  
            color: Colors.black.withOpacity(0.20),
            blurRadius: 4,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête de section avec flèche
          GestureDetector(
            onTap: _handleHeaderTap,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.purple[700]!.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.car_repair, color: Colors.purple[700], size: 24),
                      const SizedBox(width: 12),
                      Text(
                        "État du véhicule au retour",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple[700],
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    _showContent ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: Colors.purple[700],
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
          if (_showContent)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    child: InkWell(
                      onTap: _pickImage,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.purple.shade200),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo, color: Colors.purple[700], size: 20),
                            const SizedBox(width: 10),
                            Text(
                              "Ajouter des photos",
                              style: TextStyle(
                                color: Colors.purple[700],
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (widget.photos.isNotEmpty) _buildPhotoScroll(),
                  const SizedBox(height: 20),
                  CommentaireRetourWidget(controller: _commentaireController),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPhotoScroll() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "${widget.photos.length} photo${widget.photos.length > 1 ? 's' : ''} (${widget.photos.length}/10)",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 250,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: widget.photos.length,
            itemBuilder: (context, index) {
              return Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        widget.photos[index],
                        width: 200,
                        height: 234,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: GestureDetector(
                      onTap: () {
                        widget.onRemovePhoto(index);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              spreadRadius: 1,
                              blurRadius: 3,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
