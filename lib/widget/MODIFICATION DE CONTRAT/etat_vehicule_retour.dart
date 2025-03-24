import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:ContraLoc/USERS/abonnement_screen.dart';
import 'package:ContraLoc/services/collaborateur_util.dart';

class EtatVehiculeRetour extends StatefulWidget {
  final List<File> photos;
  final Function(File) onAddPhoto;
  final Function(int) onRemovePhoto;

  const EtatVehiculeRetour({
    Key? key,
    required this.photos,
    required this.onAddPhoto,
    required this.onRemovePhoto,
  }) : super(key: key);

  @override
  _EtatVehiculeRetourState createState() => _EtatVehiculeRetourState();
}

class _EtatVehiculeRetourState extends State<EtatVehiculeRetour> {
  bool isPremiumUser = false;

  @override
  void initState() {
    super.initState();
    _initializeSubscription();
  }

  Future<void> _initializeSubscription() async {
    // Vérifier le statut premium via CollaborateurUtil
    final isPremium = await CollaborateurUtil.isPremiumUser();
    
    if (mounted) {
      setState(() {
        isPremiumUser = isPremium;
      });
    }
  }

  void _showPremiumDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text(
            "Fonctionnalité Premium",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF08004D),
            ),
          ),
          content: const Text(
            "La prise de photos de l'état du véhicule au retour est disponible uniquement avec l'abonnement Premium. Souhaitez-vous découvrir nos offres ?",
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Plus tard",
                style: TextStyle(color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AbonnementScreen(),
                  ),
                );
              },
              child: const Text(
                "Voir les offres",
                style: TextStyle(
                  color: Color(0xFF08004D),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "État du véhicule au retour",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        ElevatedButton.icon(
          onPressed: isPremiumUser ? _pickImage : _showPremiumDialog,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: Icon(isPremiumUser ? Icons.add_a_photo : Icons.lock,
              color: Colors.white),
          label: Text(
            isPremiumUser
                ? "Ajouter des photos"
                : "Ajouter des photos (Premium)",
            style: const TextStyle(color: Colors.white, fontSize: 18),
          ),
        ),
        const SizedBox(height: 10),
        if (widget.photos.isNotEmpty && isPremiumUser) _buildPhotoScroll(),
      ],
    );
  }

  Widget _buildPhotoScroll() {
    return SizedBox(
      height: 250,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: widget.photos.length,
        itemBuilder: (context, index) {
          return Stack(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    widget.photos[index],
                    width: 200,
                    height: 250,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () {
                    widget.onRemovePhoto(index);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 20,
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
}
