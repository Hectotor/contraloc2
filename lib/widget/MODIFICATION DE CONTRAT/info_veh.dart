import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_util.dart';

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
      final authData = await AuthUtil.getAuthData();
      final hasReadPermission = authData['permissions']?['read'] ?? false;
      
      if (!mounted) return;
      
      setState(() {
        _hasReadPermission = hasReadPermission;
      });

      if (hasReadPermission) {
        // Utiliser directement l'URL de la photo du véhicule si disponible dans les données du contrat
        if (widget.data.containsKey('photoVehiculeUrl') && widget.data['photoVehiculeUrl'] != null) {
          setState(() {
            _vehiclePhotoUrl = widget.data['photoVehiculeUrl'];
            _isLoading = false;
            _errorMessage = '';
          });
        } else {
          // Sinon, charger la photo du véhicule depuis Firestore
          await _loadVehiclePhoto();
        }
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
      // Vérifier d'abord si les informations sont déjà dans les données du contrat
      if (widget.data.containsKey('photoVehiculeUrl') && widget.data['photoVehiculeUrl'] != null) {
        if (mounted) {
          setState(() {
            _vehiclePhotoUrl = widget.data['photoVehiculeUrl'];
          });
        }
        return; // Sortir de la fonction si les données sont déjà disponibles
      }
      
      final authData = await AuthUtil.getAuthData();
      final userId = authData['isCollaborateur'] ? authData['adminId'] : authData['userId'];
      
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
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Column(
                children: [
                  CircularProgressIndicator(color: Color(0xFF08004D)),
                  SizedBox(height: 16),
                  Text(
                    "Chargement des informations du véhicule...",
                    style: TextStyle(fontSize: 16, color: Color(0xFF08004D)),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage,
                    style: const TextStyle(color: Colors.red, fontSize: 16),
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF08004D),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "Réessayer",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    if (!_hasReadPermission) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Icon(Icons.no_accounts, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  const Text(
                    "Vous n'avez pas les permissions nécessaires pour voir ces informations.",
                    style: TextStyle(color: Colors.red, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildVehicleInfoSection(),
      ],
    );
  }

  Widget _buildVehicleInfoSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête de section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green[700]!.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.directions_car, color: Colors.green[700], size: 24),
                const SizedBox(width: 12),
                Text(
                  "Détails du véhicule",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700]!,
                  ),
                ),
              ],
            ),
          ),
          // Contenu de la section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Informations du véhicule
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow("Marque", widget.data['marque'] ?? "Non spécifié"),
                      const SizedBox(height: 12),
                      _buildInfoRow("Modèle", widget.data['modele'] ?? "Non spécifié"),
                      const SizedBox(height: 12),
                      _buildInfoRow("Immat", widget.data['immatriculation'] ?? "Non spécifié"),
                    ],
                  ),
                ),
                // Photo du véhicule
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        spreadRadius: 1,
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _vehiclePhotoUrl != null
                        ? Image.network(
                            _vehiclePhotoUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.directions_car,
                                    size: 60, color: Colors.grey),
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                  color: const Color(0xFF08004D),
                                ),
                              );
                            },
                          )
                        : const Icon(Icons.directions_car,
                            size: 60, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            "$label :",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(0xFF08004D),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[800],
            ),
          ),
        ),
      ],
    );
  }
}
