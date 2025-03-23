import 'package:flutter/material.dart';
import '../../services/collaborateur_util.dart';

class InfoLocRetour extends StatefulWidget {
  final Map<String, dynamic> data;
  final Function(BuildContext, List<dynamic>, int) onShowFullScreenImages;

  const InfoLocRetour(
      {Key? key, required this.data, required this.onShowFullScreenImages})
      : super(key: key);

  @override
  State<InfoLocRetour> createState() => _InfoLocRetourState();
}

class _InfoLocRetourState extends State<InfoLocRetour> {
  bool _hasReadPermission = false;
  bool _isLoading = true;

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
        });
      }
    } catch (e) {
      print("Erreur lors de la vérification des permissions: $e");
      
      // Afficher un message d'erreur plus informatif à l'utilisateur
      if (mounted) {
        setState(() {
          _hasReadPermission = false;
          _isLoading = false;
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
        child: CircularProgressIndicator(),
      );
    }

    if (!_hasReadPermission) {
      return const Center(
        child: Text(
          "Vous n'avez pas les permissions nécessaires pour voir ces informations.",
          style: TextStyle(color: Colors.red),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Informations de la Location Retour",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Icon(Icons.date_range, size: 16),
            SizedBox(width: 8),
            Expanded(child: Text("Date de fin effectif: ${widget.data['dateFinEffectif']}")),
          ],
        ),
        Row(
          children: [
            Icon(Icons.speed, size: 16),
            SizedBox(width: 8),
            Expanded(child: Text("Kilométrage de retour: ${widget.data['kilometrageRetour']}")),
          ],
        ),
        const SizedBox(height: 10),
        if (widget.data['photosRetourUrls'] != null &&
            widget.data['photosRetourUrls'].isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Photos de la location retour:",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.data['photosRetourUrls'].length,
                  itemBuilder: (context, index) {
                    final photoUrl = widget.data['photosRetourUrls'][index];
                    return GestureDetector(
                      onTap: () => widget.onShowFullScreenImages(
                          context, widget.data['photosRetourUrls'], index),
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Image.network(
                          photoUrl,
                          width: 150,
                          height: 150,
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          )
        else
          const SizedBox(height: 10),
        widget.data['commentaireRetour'] == null || widget.data['commentaireRetour'].isEmpty
            ? const Text("Aucun commentaire a été émis.")
            : Text("Commentaire: ${widget.data['commentaireRetour']}"),
      ],
    );
  }
}
