import 'package:flutter/material.dart';

class InfoVehicule extends StatelessWidget {
  final Map<String, dynamic> data;

  const InfoVehicule({Key? key, required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Informations du Véhicule",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Marque: ${data['marque']}"),
                  Text("Modèle: ${data['modele']}"),
                  Text("Immatriculation: ${data['immatriculation']}"),
                ],
              ),
            ),
            if (data['photoVehiculeUrl'] != null &&
                data['photoVehiculeUrl'].isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(10), // Arrondir les bords
                child: Image.network(
                  data['photoVehiculeUrl'],
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                ),
              )
            else
              const Icon(Icons.directions_car, size: 80, color: Colors.grey),
          ],
        ),
      ],
    );
  }
}
