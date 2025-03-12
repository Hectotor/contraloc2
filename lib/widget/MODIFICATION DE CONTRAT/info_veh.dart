import 'package:flutter/material.dart';
import 'package:ContraLoc/services/firestore_service.dart';

class InfoVehicule extends StatefulWidget {
  final Map<String, dynamic> data;

  const InfoVehicule({Key? key, required this.data}) : super(key: key);

  @override
  _InfoVehiculeState createState() => _InfoVehiculeState();
}

class _InfoVehiculeState extends State<InfoVehicule> {
  Future<String?>? _photoUrlFuture;

  @override
  void initState() {
    super.initState();
    _photoUrlFuture = _getVehiclePhotoUrl();
  }

  Future<String?> _getVehiclePhotoUrl() async {
    try {
      final vehicleData = await FirestoreService.getVehicleData(widget.data['immatriculation']);
      return vehicleData?['photoVehiculeUrl'] as String?;
    } catch (e) {
      print('❌ Erreur récupération photo véhicule: $e');
      return null;
    }
  }

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
                  Text("Marque: ${widget.data['marque']}"),
                  Text("Modèle: ${widget.data['modele']}"),
                  Text("Immatriculation: ${widget.data['immatriculation']}"),
                ],
              ),
            ),
            FutureBuilder<String?>(
              future: _photoUrlFuture,
              builder: (context, snapshot) {
                Widget imageWidget;
                if (snapshot.connectionState == ConnectionState.waiting) {
                  imageWidget = const Center(
                    child: SizedBox(
                      width: 30,
                      height: 30,
                      child: CircularProgressIndicator(),
                    ),
                  );
                } else if (snapshot.hasError ||
                    !snapshot.hasData ||
                    snapshot.data == null) {
                  imageWidget = const Icon(Icons.directions_car,
                      size: 50, color: Colors.grey);
                } else {
                  imageWidget = Image.network(
                    snapshot.data!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.directions_car,
                            size: 50, color: Colors.grey),
                  );
                }

                return Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.grey[200],
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: imageWidget,
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}
