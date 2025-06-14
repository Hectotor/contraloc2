import 'package:flutter/material.dart';
import 'vehicle_photo_views.dart';
import 'generate_button.dart';

/// Page dédiée au formulaire d'informations du véhicule
class VehicleInfoPage extends StatelessWidget {
  const VehicleInfoPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(' '),
        backgroundColor: const Color(0xFF08004D),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Informations du véhicule',
                      labelStyle: const TextStyle(
                        color: Color(0xFF08004D),
                        fontWeight: FontWeight.bold,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFF08004D)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFF08004D), width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Vues du véhicule',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF08004D),
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Pour un rendu optimal, privilégiez les photos au format horizontal.',
                    style: TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: Color(0xFF08004D),
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const VehiclePhotoViews(),
                  const SizedBox(height: 30),
                  Center(
                    child: GenerateButton(
                      onPressed: () {
                        // Action à effectuer lors du clic sur le bouton
                      },
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
