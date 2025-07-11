import 'package:flutter/material.dart';

class InfoLocRetour extends StatefulWidget {
  final Map<String, dynamic> data;
  final Function(BuildContext, List<dynamic>, int) onShowFullScreenImages;

  const InfoLocRetour({
    Key? key,
    required this.data,
    required this.onShowFullScreenImages,
  }) : super(key: key);

  @override
  State<InfoLocRetour> createState() => _InfoLocRetourState();
}

class _InfoLocRetourState extends State<InfoLocRetour> {
  bool _hasReadPermission = false;
  bool _isLoading = true;
  bool _showContent = true;

  void _handleHeaderTap() {
    setState(() {
      _showContent = !_showContent;
    });
  }

  Future<void> _checkPermissions() async {
    try {
      // Les utilisateurs peuvent toujours lire les informations de retour
      final hasReadPermission = true;
      
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
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Widget _buildReturnInfoSection(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_hasReadPermission) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                "Vous n'avez pas la permission de voir ces informations.",
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.20),
            blurRadius: 4,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête de section avec flèche
          GestureDetector(
            onTap: _handleHeaderTap,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange[700]!.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.assignment_turned_in, color: Colors.orange[700], size: 24),
                      const SizedBox(width: 12),
                      Text(
                        "Informations de Retour",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[700],
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    _showContent ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: Colors.orange[700],
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
          if (_showContent)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow(context, "Date fin", widget.data['dateFinEffectif'] ?? "Non spécifiée"),
                  const SizedBox(height: 12),
                  _buildInfoRow(context, "Arrivée", "${widget.data['kilometrageRetour'] ?? "Non spécifié"} km"),
                  const SizedBox(height: 12),
                  _buildInfoRow(context, "Essence", "${widget.data['pourcentageEssenceRetour'] ?? "Non spécifié"}%"),
                  
                  // Photos
                  if (widget.data['photosRetourUrls'] != null && widget.data['photosRetourUrls'].isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Icon(Icons.photo_library, color: Colors.orange[700], size: 20),
                        const SizedBox(width: 10),
                        Text(
                          "Photos du véhicule au retour",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.all(8),
                        itemCount: widget.data['photosRetourUrls'].length,
                        itemBuilder: (context, index) {
                          final photoUrl = widget.data['photosRetourUrls'][index];
                          return GestureDetector(
                            onTap: () => widget.onShowFullScreenImages(
                                context, widget.data['photosRetourUrls'], index),
                            child: Container(
                              margin: const EdgeInsets.only(right: 10),
                              width: 100,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  photoUrl,
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Center(
                                      child: CircularProgressIndicator(
                                        value: loadingProgress.expectedTotalBytes != null
                                            ? loadingProgress.cumulativeBytesLoaded /
                                                loadingProgress.expectedTotalBytes!
                                            : null,
                                        color: Colors.orange[700],
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 100,
                                      height: 100,
                                      color: Colors.grey[200],
                                      child: const Center(
                                        child: Icon(Icons.error, color: Colors.red),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 20),
                  ],
                  
                  // Commentaire
                  if (widget.data['commentaireRetour'] != null && widget.data['commentaireRetour'].toString().isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Icon(Icons.comment, color: Colors.orange[700], size: 20),
                        const SizedBox(width: 10),
                        Text(
                          "Commentaire",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "${widget.data['commentaireRetour']}",
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            "$label :",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,

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

  @override
  Widget build(BuildContext context) {
    return _buildReturnInfoSection(context);
  }
}
