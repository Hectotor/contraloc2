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
        const Text(
          "Informations du Client",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Text("Nom: ${data['nom']}"),
        Text("Prénom: ${data['prenom']}"),
        Text("Adresse: ${data['adresse']}"),
        Text("Téléphone: ${data['telephone']}"),
        Text("Email: ${data['email']}"),
        Text("N° Permis: ${data['numeroPermis']}"),
        const SizedBox(height: 10),
        if (data['permisRecto'] != null || data['permisVerso'] != null)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Permis de conduire:",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
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
                          child: Image.network(
                            data['permisRecto'],
                            width: 150,
                            height: 150,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    if (data['permisVerso'] != null)
                      GestureDetector(
                        onTap: () => onShowFullScreenImages(
                            context, [data['permisVerso']], 1),
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Image.network(
                            data['permisVerso'],
                            width: 150,
                            height: 150,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }
}
