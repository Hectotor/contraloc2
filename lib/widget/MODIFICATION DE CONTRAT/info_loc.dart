import 'package:flutter/material.dart';
import '../../services/collaborateur_util.dart';

class InfoLoc extends StatefulWidget {
  final Map<String, dynamic> data;
  final Function(BuildContext, List<dynamic>, int) onShowFullScreenImages;

  const InfoLoc(
      {Key? key, required this.data, required this.onShowFullScreenImages})
      : super(key: key);

  @override
  State<InfoLoc> createState() => _InfoLocState();
}

class _InfoLocState extends State<InfoLoc> {
  bool _hasReadPermission = false;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    try {
      // Vérifier si l'utilisateur a la permission de lecture
      // La méthode checkCollaborateurPermission utilise maintenant _executeWithRetry en interne
      final hasReadPermission = await CollaborateurUtil.checkCollaborateurPermission('lecture');
      
      if (mounted) {
        setState(() {
          _hasReadPermission = hasReadPermission;
          _isLoading = false;
          _errorMessage = '';
        });
      }
    } catch (e) {
      print("Erreur lors de la vérification des permissions: $e");
      
      // Afficher un message d'erreur plus informatif à l'utilisateur
      if (mounted) {
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
              _checkPermissions();
            }
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text("Chargement des informations..."),
          ],
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
                _checkPermissions();
              },
              child: const Text("Réessayer"),
            ),
          ],
        ),
      );
    }

    if (!_hasReadPermission) {
      return const Center(
        child: Text(
          "Vous n'avez pas les permissions nécessaires pour voir ces informations.",
          style: TextStyle(color: Colors.red),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Informations de la Location",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Icon(Icons.date_range, size: 16),
            SizedBox(width: 8),
            Expanded(child: Text("Date de début: ${widget.data['dateDebut']}")),
          ],
        ),
        Row(
          children: [
            Icon(Icons.date_range, size: 16),
            SizedBox(width: 8),
            Expanded(child: Text("Date de fin théorique: ${widget.data['dateFinTheorique']}")),
          ],
        ),
        Row(
          children: [
            Icon(Icons.speed, size: 16),
            SizedBox(width: 8),
            Expanded(child: Text("Kilométrage de départ: ${widget.data['kilometrageDepart']}")),
          ],
        ),
        Row(
          children: [
            Icon(Icons.category, size: 16),
            SizedBox(width: 8),
            Expanded(child: Text("Type de location: ${widget.data['typeLocation']}")),
          ],
        ),
        Row(
          children: [
            Icon(Icons.local_gas_station, size: 16),
            SizedBox(width: 8),
            Expanded(child: Text("Niveau d'essence: ${widget.data['pourcentageEssence']}%")),
          ],
        ),
        const SizedBox(height: 10),
        if (widget.data['photos'] != null && widget.data['photos'].isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Photos de la location:",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.data['photos'].length,
                  itemBuilder: (context, index) {
                    final photoUrl = widget.data['photos'][index];
                    return GestureDetector(
                      onTap: () => widget.onShowFullScreenImages(
                          context, widget.data['photos'], index),
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Image.network(
                          photoUrl,
                          width: 150,
                          height: 150,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 150,
                              height: 150,
                              color: Colors.grey[300],
                              child: const Center(
                                child: Icon(Icons.error, color: Colors.red),
                              ),
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              width: 150,
                              height: 150,
                              color: Colors.grey[200],
                              child: Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          )
        else
          const Text("Aucune photo a été prise."),
        const SizedBox(height: 10),
        widget.data['commentaire'] == null || widget.data['commentaire'].isEmpty
            ? const Text("Aucun commentaire a été émis.")
            : Text("Commentaire: ${widget.data['commentaire']}"),
      ],
    );
  }
}
