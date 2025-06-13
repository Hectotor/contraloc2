import 'package:flutter/material.dart';
import '../PHOTOS/button_photo_actions.dart';

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
          // Boutons d'action photo positionnés en bas de l'écran
          const PhotoActionButtons(),
        ],
      ),
    );
  }
}
