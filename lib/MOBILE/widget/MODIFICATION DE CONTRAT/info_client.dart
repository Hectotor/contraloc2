import 'package:flutter/material.dart';

class InfoClient extends StatefulWidget {
  final Map<String, dynamic> data;
  final Function(BuildContext, List<dynamic>, int) onShowFullScreenImages;

  const InfoClient({
    Key? key,
    required this.data,
    required this.onShowFullScreenImages,
  }) : super(key: key);

  @override
  State<InfoClient> createState() => _InfoClientState();
}

class _InfoClientState extends State<InfoClient> {
  bool _showContent = false;

  void _handleHeaderTap() {
    setState(() {
      _showContent = !_showContent;
    });
  }

  Widget _buildClientInfoSection(BuildContext context) {
    return Container(
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
                color: Colors.green[700]!.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.person, color: Colors.green[700], size: 24),
                      const SizedBox(width: 12),
                      Text(
                        "Informations du client",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    _showContent ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: Colors.green[700],
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
                  if (widget.data['entrepriseClient'] != null && widget.data['entrepriseClient'].toString().isNotEmpty)
                    _buildInfoRow(context, "Entreprise", widget.data['entrepriseClient'] ?? "Non spécifié"),
                  const SizedBox(height: 12),
                  _buildInfoRow(context, "Nom", widget.data['nom'] ?? "Non spécifié"),
                  const SizedBox(height: 12),
                  _buildInfoRow(context, "Prénom", widget.data['prenom'] ?? "Non spécifié"),
                  const SizedBox(height: 12),
                  _buildInfoRow(context, "Adresse", widget.data['adresse'] ?? "Non spécifié"),
                  const SizedBox(height: 12),
                  _buildInfoRow(context, "Téléphone", widget.data['telephone'] ?? "Non spécifié"),
                  const SizedBox(height: 12),
                  _buildInfoRow(context, "Email", widget.data['email'] ?? "Non spécifié"),
                  const SizedBox(height: 12),
                  _buildInfoRow(context, "N° Permis", widget.data['numeroPermis'] ?? "Non spécifié"),
                  if (widget.data['immatriculationVehiculeClient'] != null && widget.data['immatriculationVehiculeClient'].isNotEmpty)
                    const SizedBox(height: 12),
                  if (widget.data['immatriculationVehiculeClient'] != null && widget.data['immatriculationVehiculeClient'].isNotEmpty)
                    _buildInfoRow(context, "N° Immat", widget.data['immatriculationVehiculeClient']),
                  if (widget.data['kilometrageVehiculeClient'] != null && widget.data['kilometrageVehiculeClient'].isNotEmpty)
                    const SizedBox(height: 12),
                  if (widget.data['kilometrageVehiculeClient'] != null && widget.data['kilometrageVehiculeClient'].isNotEmpty)
                    _buildInfoRow(context, "Km", widget.data['kilometrageVehiculeClient']),
                  
                  // Photos du permis de conduire
                  if ((widget.data['permisRecto'] != null && widget.data['permisRecto'].toString().isNotEmpty) || 
                      (widget.data['permisVerso'] != null && widget.data['permisVerso'].toString().isNotEmpty)) ...[
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Icon(Icons.credit_card, color: Colors.green[700], size: 24),
                        const SizedBox(width: 12),
                        Text(
                          "Permis de conduire",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (widget.data['permisRecto'] != null && widget.data['permisRecto'].toString().isNotEmpty)
                          GestureDetector(
                            onTap: () => widget.onShowFullScreenImages(
                                context, [widget.data['permisRecto']], 0),
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  widget.data['permisRecto'],
                                  width: 150,
                                  height: 150,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.error, size: 50, color: Colors.grey),
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Center(
                                      child: CircularProgressIndicator(
                                        value: loadingProgress.expectedTotalBytes != null
                                            ? loadingProgress.cumulativeBytesLoaded /
                                                loadingProgress.expectedTotalBytes!
                                            : null,
                                        color: Colors.green[700],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        if (widget.data['permisVerso'] != null && widget.data['permisVerso'].toString().isNotEmpty)
                          GestureDetector(
                            onTap: () => widget.onShowFullScreenImages(
                                context, [widget.data['permisVerso']], 0),
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  widget.data['permisVerso'],
                                  width: 150,
                                  height: 150,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.error, size: 50, color: Colors.grey),
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Center(
                                      child: CircularProgressIndicator(
                                        value: loadingProgress.expectedTotalBytes != null
                                            ? loadingProgress.cumulativeBytesLoaded /
                                                loadingProgress.expectedTotalBytes!
                                            : null,
                                        color: Colors.green[700],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                  
                  // Photos du véhicule client
                  if (widget.data['vehiculeClientPhotosUrls'] != null && 
                      widget.data['vehiculeClientPhotosUrls'] is List && 
                      (widget.data['vehiculeClientPhotosUrls'] as List).isNotEmpty) ...[                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Icon(Icons.directions_car, color: Colors.green[700], size: 24),
                        const SizedBox(width: 12),
                        Text(
                          "Photos du véhicule client",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: List.generate(
                          (widget.data['vehiculeClientPhotosUrls'] as List).length,
                          (index) => GestureDetector(
                            onTap: () => widget.onShowFullScreenImages(
                                context, widget.data['vehiculeClientPhotosUrls'], index),
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  widget.data['vehiculeClientPhotosUrls'][index],
                                  width: 150,
                                  height: 150,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.error, size: 50, color: Colors.grey),
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Center(
                                      child: CircularProgressIndicator(
                                        value: loadingProgress.expectedTotalBytes != null
                                            ? loadingProgress.cumulativeBytesLoaded /
                                                loadingProgress.expectedTotalBytes!
                                            : null,
                                        color: Colors.green[700],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
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
              color: Colors.green[700],
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildClientInfoSection(context),
      ],
    );
  }
}
