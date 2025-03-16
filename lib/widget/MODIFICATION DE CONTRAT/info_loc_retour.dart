import 'package:flutter/material.dart';

class InfoLocRetour extends StatelessWidget {
  final Map<String, dynamic> data;
  final Function(BuildContext, List<dynamic>, int) onShowFullScreenImages;

  const InfoLocRetour(
      {Key? key, required this.data, required this.onShowFullScreenImages})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Informations de la Location Retour",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Text("Date de fin effectif: ${data['dateFinEffectif']}"),
        Text("Kilométrage de retour: ${data['kilometrageRetour']}"),
        const SizedBox(height: 10),
        if (data['photosRetourUrls'] != null &&
            data['photosRetourUrls'].isNotEmpty)
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
                  itemCount: data['photosRetourUrls'].length,
                  itemBuilder: (context, index) {
                    final photoUrl = data['photosRetourUrls'][index];
                    return GestureDetector(
                      onTap: () => onShowFullScreenImages(
                          context, data['photosRetourUrls'], index),
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
        data['commentaireRetour'] == null || data['commentaireRetour'].isEmpty
            ? const Text("Aucun commentaire a été émis.")
            : Text("Commentaire: ${data['commentaireRetour']}"),
      ],
    );
  }
}
