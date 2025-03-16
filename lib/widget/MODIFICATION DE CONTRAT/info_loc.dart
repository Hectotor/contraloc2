import 'package:flutter/material.dart';

class InfoLoc extends StatelessWidget {
  final Map<String, dynamic> data;
  final Function(BuildContext, List<dynamic>, int) onShowFullScreenImages;

  const InfoLoc(
      {Key? key, required this.data, required this.onShowFullScreenImages})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Informations de la Location",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Text("Date de début: ${data['dateDebut']}"),
        Text("Date de fin théorique: ${data['dateFinTheorique']}"),
        Text("Kilométrage de départ: ${data['kilometrageDepart']}"),
        Text("Type de location: ${data['typeLocation']}"),
        Text("Niveau d'essence: ${data['pourcentageEssence']}%"),
        const SizedBox(height: 10),
        if (data['photos'] != null && data['photos'].isNotEmpty)
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
                  itemCount: data['photos'].length,
                  itemBuilder: (context, index) {
                    final photoUrl = data['photos'][index];
                    return GestureDetector(
                      onTap: () => onShowFullScreenImages(
                          context, data['photos'], index),
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
          const Text("Aucune photo a été prise."),
        const SizedBox(height: 10),
        data['commentaire'] == null || data['commentaire'].isEmpty
            ? const Text("Aucun commentaire a été émis.")
            : Text("Commentaire: ${data['commentaire']}"),
      ],
    );
  }
}
