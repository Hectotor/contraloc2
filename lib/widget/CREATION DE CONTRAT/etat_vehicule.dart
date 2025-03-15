import 'package:flutter/material.dart';
import 'dart:io';
import 'package:ContraLoc/USERS/abonnement_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ContraLoc/widget/CREATION DE CONTRAT/pop_choice_picture.dart';

class EtatVehicule extends StatefulWidget {
  final List<File> photos;
  final Function(File) onAddPhoto;
  final Function(int) onRemovePhoto;

  const EtatVehicule({
    Key? key,
    required this.photos,
    required this.onAddPhoto,
    required this.onRemovePhoto,
  }) : super(key: key);

  @override
  _EtatVehiculeState createState() => _EtatVehiculeState();
}

class _EtatVehiculeState extends State<EtatVehicule> {
  bool isPremiumUser = false;

  @override
  void initState() {
    super.initState();
    _checkPremiumStatus();
  }

  Future<void> _checkPremiumStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // 1. Vérifier si c'est un collaborateur
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) return;
      
      final userData = userDoc.data() ?? {};
      final String role = userData['role'] ?? '';
      
      if (role == 'collaborateur') {
        // Pour un collaborateur, on utilise les données de l'admin
        final String adminId = userData['adminId'] ?? '';
        final String collaborateurId = userData['id'] ?? '';
        
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(adminId)
            .collection('authentification')
            .doc(collaborateurId)
            .get();
            
        if (doc.exists) {
          final data = doc.data() ?? {};
          final subscriptionId = data['subscriptionId'] ?? 'free';
          final cb_subscription = data['cb_subscription'] ?? 'free';

          setState(() {
            isPremiumUser = subscriptionId == 'premium-monthly_access' ||
                subscriptionId == 'premium-yearly_access' ||
                cb_subscription == 'premium-monthly_access' ||
                cb_subscription == 'premium-yearly_access';
          });
        }
      } else {
        // Pour un admin, on garde la logique existante
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('authentification')
            .doc(user.uid)
            .get();

        if (doc.exists) {
          final data = doc.data() ?? {};
          final subscriptionId = data['subscriptionId'] ?? 'free';
          final cb_subscription = data['cb_subscription'] ?? 'free';

          setState(() {
            isPremiumUser = subscriptionId == 'premium-monthly_access' ||
                subscriptionId == 'premium-yearly_access' ||
                cb_subscription == 'premium-monthly_access' ||
                cb_subscription == 'premium-yearly_access';
          });
        }
      }
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
            "La prise de photos de l'état du véhicule est disponible uniquement avec l'abonnement Premium. Souhaitez-vous découvrir nos offres ?",
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
    if (!isPremiumUser) {
      _showPremiumDialog();
      return;
    }

    if (widget.photos.length >= 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Vous ne pouvez ajouter que 10 photos maximum.")),
      );
      return;
    }

    final File? selectedImage = await ImagePickerDialog.showImagePickerDialog(
      context,
      imageQuality: 70,
      compressWidth: 800,
      compressHeight: 800,
      compressQuality: 85,
    );

    if (selectedImage != null) {
      widget.onAddPhoto(selectedImage);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "État du véhicule",
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
            isPremiumUser ? "Ajouter des photos" : "Ajouter des photos",
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
