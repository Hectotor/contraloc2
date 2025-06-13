import 'package:flutter/material.dart';
import '../HOME/button_add_vehicle.dart';

class PhotosScreen extends StatefulWidget {
  const PhotosScreen({Key? key}) : super(key: key);

  @override
  State<PhotosScreen> createState() => _PhotosScreenState();
}

class _PhotosScreenState extends State<PhotosScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: AppBar(
          backgroundColor: const Color(0xFF08004D),
          title: const Text(
            'Valorisez mes véhicules',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          elevation: 0,
        ),
      ),
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(
                  Icons.photo_camera,
                  size: 80,
                  color: Color(0xFF08004D),
                ),
                SizedBox(height: 20),
                Text(
                  'Fonctionnalité en cours de développement',
                  style: TextStyle(fontSize: 18),
                ),
              ],
            ),
          ),
          // Bouton d'ajout positionné en bas de l'écran
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              child: CustomActionButton(
                text: "Prendre une photo",
                icon: Icons.camera_alt,
                onPressed: () {
                  // Afficher un message temporaire
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Fonctionnalité de prise de photo bientôt disponible'),
                      backgroundColor: Color(0xFF08004D),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
