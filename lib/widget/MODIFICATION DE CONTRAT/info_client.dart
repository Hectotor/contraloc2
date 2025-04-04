import 'package:flutter/material.dart';

class InfoClient extends StatelessWidget {
  final Map<String, dynamic> data;
  final Function(BuildContext, List<dynamic>, int) onShowFullScreenImages;

  const InfoClient({
    Key? key,
    required this.data,
    required this.onShowFullScreenImages,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildClientInfoSection(context),
      ],
    );
  }

  Widget _buildClientInfoSection(BuildContext context) {
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
              color: Colors.teal[700]!.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.person, color: Colors.teal[700], size: 24),
                const SizedBox(width: 12),
                Text(
                  "Informations du client",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal[700],
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
                _buildInfoRow(context, "Nom", data['nom'] ?? "Non spécifié"),
                const SizedBox(height: 12),
                _buildInfoRow(context, "Prénom", data['prenom'] ?? "Non spécifié"),
                const SizedBox(height: 12),
                _buildInfoRow(context, "Adresse", data['adresse'] ?? "Non spécifié"),
                const SizedBox(height: 12),
                _buildInfoRow(context, "Téléphone", data['telephone'] ?? "Non spécifié"),
                const SizedBox(height: 12),
                _buildInfoRow(context, "Email", data['email'] ?? "Non spécifié"),
                const SizedBox(height: 12),
                _buildInfoRow(context, "N° Permis", data['numeroPermis'] ?? "Non spécifié"),
                if (data['immatriculationClient'] != null && data['immatriculationClient'].isNotEmpty)
                  const SizedBox(height: 12),
                if (data['immatriculationClient'] != null && data['immatriculationClient'].isNotEmpty)
                  _buildInfoRow(context, "N° Immat", data['immatriculationClient']),
                if (data['kilometrageVehiculeClient'] != null && data['kilometrageVehiculeClient'].isNotEmpty)
                  const SizedBox(height: 12),
                if (data['kilometrageVehiculeClient'] != null && data['kilometrageVehiculeClient'].isNotEmpty)
                  _buildInfoRow(context, "Km", data['kilometrageVehiculeClient']),
                
                // Photos du permis de conduire
                if (data['permisRecto'] != null || data['permisVerso'] != null) ...[  
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Icon(Icons.credit_card, color: Colors.teal[700], size: 24),
                      const SizedBox(width: 12),
                      Text(
                        "Permis de conduire",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 100,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        if (data['permisRecto'] != null)
                          GestureDetector(
                            onTap: () => onShowFullScreenImages(
                                context, [data['permisRecto']], 0),
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  data['permisRecto'],
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
                                        color: Colors.teal[700],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        if (data['permisVerso'] != null)
                          GestureDetector(
                            onTap: () => onShowFullScreenImages(
                                context, [data['permisVerso']], 0),
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  data['permisVerso'],
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
                                        color: Colors.teal[700],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                      ],
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
