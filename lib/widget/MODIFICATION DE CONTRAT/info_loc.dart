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
        _buildLocationInfoSection(context),
      ],
    );
  }

  Widget _buildLocationInfoSection(BuildContext context) {
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
              color: Colors.purple[700]!.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.purple[700], size: 24),
                const SizedBox(width: 12),
                Text(
                  "Informations de la location",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple[700],
                  ),
                ),
              ],
            ),
          ),
          // Contenu de la section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(context, "Début", widget.data['dateDebut'] ?? "Non spécifié"),
                const SizedBox(height: 12),
                if (widget.data['dateFinTheorique'] != null && widget.data['dateFinTheorique'].toString().isNotEmpty) ...[
                  _buildInfoRow(context, "Fin théori", widget.data['dateFinTheorique']),
                  const SizedBox(height: 12),
                ],
                _buildInfoRow(context, "Départ", "${widget.data['kilometrageDepart']?.toString() ?? "Non spécifié"} km"),
                const SizedBox(height: 12),
                _buildInfoRow(context, "Autorisée", "${widget.data['kilometrageAutorise'] ?? "Non spécifié"} km"),
                const SizedBox(height: 12),
                _buildInfoRow(context, "Type loc", widget.data['typeLocation'] ?? "Non spécifié"),
                const SizedBox(height: 12),
                if (widget.data['typeLocation'] == 'Payante') ...[
                  _buildInfoRow(context, "Accompte", "${widget.data['accompte'] ?? "Non spécifié"} €"),
                  const SizedBox(height: 12),
                ],
                _buildInfoRow(context, "Essence", "${widget.data['pourcentageEssence'] ?? "Non spécifié"}%"),
                
                // Photos de la location
                if (widget.data['photos'] != null && widget.data['photos'].isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Icon(Icons.photo_library, color: Colors.purple[700], size: 24),
                      const SizedBox(width: 12),
                      Text(
                        "Photos de la location",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
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
                                      color: Colors.purple[700],
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
                
                // Commentaire
                if (widget.data['commentaire'] != null && widget.data['commentaire'].isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Icon(Icons.comment, color: Colors.purple[700], size: 24),
                      const SizedBox(width: 12),
                      Text(
                        "Commentaire",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.data['commentaire'],
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[800],
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
