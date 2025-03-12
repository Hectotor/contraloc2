import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ContraLoc/services/firestore_service.dart';

class VoitureSelectionne extends StatefulWidget {
  final String marque;
  final String modele;
  final String immatriculation;
  final FirebaseFirestore firestore;

  const VoitureSelectionne({
    Key? key,
    required this.marque,
    required this.modele,
    required this.immatriculation,
    required this.firestore,
  }) : super(key: key);

  @override
  _VoitureSelectionneState createState() => _VoitureSelectionneState();
}

class _VoitureSelectionneState extends State<VoitureSelectionne> {
  final Map<String, String?> _photoUrlCache = {};
  Future<String?>? _photoUrlFuture;

  @override
  void initState() {
    super.initState();
    _photoUrlFuture = _getVehiclePhotoUrl();
  }

  @override
  void didUpdateWidget(VoitureSelectionne oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.immatriculation != widget.immatriculation) {
      _photoUrlFuture = _getVehiclePhotoUrl();
    }
  }

  Future<String?> _getVehiclePhotoUrl() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final cacheKey = '${user.uid}-${widget.immatriculation}';
    if (_photoUrlCache.containsKey(cacheKey)) {
      return _photoUrlCache[cacheKey];
    }

    try {
      final vehicleData = await FirestoreService.getVehicleData(widget.immatriculation);
      
      if (vehicleData != null) {
        final photoUrl = vehicleData['photoVehiculeUrl'] as String?;
        if (photoUrl != null) {
          _photoUrlCache[cacheKey] = photoUrl;
          return photoUrl;
        }
      }
      _photoUrlCache[cacheKey] = null;
      return null;
    } catch (e) {
      print('❌ Erreur récupération photo véhicule: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Véhicule sélectionné :",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                "Marque : ${widget.marque}",
                style: const TextStyle(fontSize: 14),
              ),
              Text(
                "Modèle : ${widget.modele}",
                style: const TextStyle(fontSize: 14),
              ),
              Text(
                "Immatriculation : ${widget.immatriculation}",
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
        if (widget.immatriculation.isNotEmpty)
          FutureBuilder<String?>(
            future: _photoUrlFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  width: 100,
                  height: 100,
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              
              Widget imageWidget;
              if (snapshot.hasError ||
                  !snapshot.hasData ||
                  snapshot.data == null ||
                  snapshot.data!.isEmpty) {
                imageWidget = const Icon(Icons.directions_car,
                    size: 80, color: Colors.grey);
              } else {
                imageWidget = Image.network(
                  snapshot.data!,
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    print("❌ Erreur chargement image : $error");
                    return const Icon(Icons.directions_car,
                        size: 80, color: Colors.grey);
                  },
                );
              }
              
              return ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 100,
                  height: 100,
                  color: Colors.grey[200],
                  child: imageWidget,
                ),
              );
            },
          ),
      ],
    );
  }
}
