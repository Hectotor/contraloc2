import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/collaborateur_util.dart';

class InfoVehicule extends StatefulWidget {
  final Map<String, dynamic> data;

  const InfoVehicule({Key? key, required this.data}) : super(key: key);

  @override
  State<InfoVehicule> createState() => _InfoVehiculeState();
}

class _InfoVehiculeState extends State<InfoVehicule> {
  bool _hasReadPermission = false;
  bool _isLoading = true;
  String _errorMessage = '';
  String? _vehiclePhotoUrl;

  @override
  void initState() {
    super.initState();
    _checkPermissionsAndLoadData();
  }

  Future<void> _checkPermissionsAndLoadData() async {
    try {
      // Vérifier si l'utilisateur a la permission de lecture
      final hasReadPermission = await CollaborateurUtil.checkCollaborateurPermission('lecture');
      
      if (!mounted) return;
      
      setState(() {
        _hasReadPermission = hasReadPermission;
      });

      if (hasReadPermission) {
        // Charger la photo du véhicule si l'utilisateur a les permissions
        await _loadVehiclePhoto();
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = '';
        });
      }
    } catch (e) {
      print("Erreur lors de la vérification des permissions: $e");
      
      if (!mounted) return;
      
      setState(() {
        _hasReadPermission = false;
        _isLoading = false;
        
        if (e.toString().contains('unavailable')) {
          _errorMessage = "Le service est temporairement indisponible. Nouvelle tentative en cours...";
        } else if (e.toString().contains('network')) {
          _errorMessage = "Problème de connexion réseau. Vérifiez votre connexion internet.";
        } else {
          _errorMessage = "Une erreur s'est produite. Veuillez réessayer.";
        }
      });
      
      // Retenter automatiquement après un délai si c'est une erreur de connectivité
      if (e.toString().contains('unavailable') || 
          e.toString().contains('network error') ||
          e.toString().contains('timeout')) {
        
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _isLoading = true;
            });
            _checkPermissionsAndLoadData();
          }
        });
      }
    }
  }

  Future<void> _loadVehiclePhoto() async {
    try {
      final status = await CollaborateurUtil.checkCollaborateurStatus();
      final userId = status['isCollaborateur'] ? status['adminId'] : status['userId'];
      
      if (userId == null) {
        print("❌ ID utilisateur non disponible");
        return;
      }

      // Utiliser une approche avec retentative pour récupérer la photo du véhicule
      try {
        final vehiculeDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('vehicules')
            .where('immatriculation', isEqualTo: widget.data['immatriculation'])
            .get();

        if (vehiculeDoc.docs.isNotEmpty) {
          final photoUrl = vehiculeDoc.docs.first.data()['photoVehiculeUrl'] as String?;
          
          if (mounted) {
            setState(() {
              _vehiclePhotoUrl = photoUrl;
            });
          }
        }
      } catch (e) {
        // En cas d'erreur, réessayer après un délai
        if (e.toString().contains('unavailable') || 
            e.toString().contains('network error') ||
            e.toString().contains('timeout')) {
          
          await Future.delayed(const Duration(milliseconds: 500));
          
          // Deuxième tentative
          final vehiculeDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection('vehicules')
              .where('immatriculation', isEqualTo: widget.data['immatriculation'])
              .get();

          if (vehiculeDoc.docs.isNotEmpty) {
            final photoUrl = vehiculeDoc.docs.first.data()['photoVehiculeUrl'] as String?;
            
            if (mounted) {
              setState(() {
                _vehiclePhotoUrl = photoUrl;
              });
            }
          }
        } else {
          // Si ce n'est pas une erreur de connectivité, propager l'erreur
          rethrow;
        }
      }
    } catch (e) {
      print("❌ Erreur lors du chargement de la photo du véhicule: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Informations du Véhicule",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          const Center(
            child: Column(
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text("Chargement des informations du véhicule..."),
              ],
            ),
          ),
        ],
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Informations du Véhicule",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Center(
            child: Column(
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isLoading = true;
                    });
                    _checkPermissionsAndLoadData();
                  },
                  child: const Text("Réessayer"),
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (!_hasReadPermission) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Informations du Véhicule",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          const Center(
            child: Text(
              "Vous n'avez pas les permissions nécessaires pour voir ces informations.",
              style: TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      );
    }

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
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: _vehiclePhotoUrl != null
                    ? Image.network(
                        _vehiclePhotoUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.directions_car,
                                size: 50, color: Colors.grey),
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          );
                        },
                      )
                    : const Icon(Icons.directions_car,
                        size: 50, color: Colors.grey),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
