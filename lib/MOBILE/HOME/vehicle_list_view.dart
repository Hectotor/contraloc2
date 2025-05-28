import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VehicleListView extends StatelessWidget {
  final AsyncSnapshot<QuerySnapshot> snapshot;
  final String nomEntreprise;
  final String prenom;

  const VehicleListView({
    Key? key,
    required this.snapshot,
    required this.nomEntreprise,
    required this.prenom,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (snapshot.hasError) {
      print(' Erreur dans le stream des véhicules: ${snapshot.error}');
      return Center(
        child: Text(
          'Erreur lors du chargement des véhicules',
          style: TextStyle(color: Colors.red),
        ),
      );
    }

    final vehicles = snapshot.data?.docs ?? [];

    if (vehicles.isEmpty && snapshot.connectionState == ConnectionState.active) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                children: [
                  TextSpan(
                    text: nomEntreprise.isNotEmpty 
                        ? "$nomEntreprise\n \n" 
                        : "Bonjour $prenom,\n \n",
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A237E),
                    ),
                  ),
                  const TextSpan(
                    text: "Bienvenue sur Contraloc",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.normal,
                      color: Color(0xFF1A237E),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Commencez par ajouter un véhicule",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF757575),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    }
    
    // Retourner la liste des véhicules si elle n'est pas vide
    return ListView.builder(
      itemCount: vehicles.length,
      itemBuilder: (context, index) {
        // Ici, vous pouvez retourner votre widget d'affichage de véhicule
        // Par exemple, un VehicleCard ou autre
        return Container(); // À remplacer par votre widget d'affichage de véhicule
      },
    );
  }
}
