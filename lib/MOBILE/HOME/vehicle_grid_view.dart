import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widget/CREATION DE CONTRAT/client.dart';
import '../widget/MES CONTRATS/vehicle_access_manager.dart';

/// Un widget qui affiche une grille de véhicules
/// 
/// Ce widget prend une liste de véhicules filtrés et les affiche dans une grille
/// avec des cartes cliquables. Il gère également les interactions comme la
/// navigation vers la page de détails du véhicule.
class VehicleGridView extends StatelessWidget {
  /// La liste des véhicules filtrés à afficher
  final List<QueryDocumentSnapshot> filteredVehicles;
  
  /// Le gestionnaire d'accès aux véhicules
  final VehicleAccessManager vehicleAccessManager;
  
  /// Fonction appelée lors d'un appui long sur un véhicule
  final Function(String) onLongPress;

  /// Constructeur pour la grille de véhicules
  const VehicleGridView({
    Key? key,
    required this.filteredVehicles,
    required this.vehicleAccessManager,
    required this.onLongPress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: Column(
            children: [
              const SizedBox(height: 5),
              const Text(
                "(Appuie long pour modifier)",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 3 / 4,
            ),
            padding: const EdgeInsets.all(12.0),
            itemCount: filteredVehicles.length,
            itemBuilder: (context, index) {
              final vehicle = filteredVehicles[index];
              final data = vehicle.data() as Map<String, dynamic>;

              return GestureDetector(
                onTap: () async {
                  final doc = await vehicleAccessManager.getVehicleDocument(vehicle.id);

                  if (!context.mounted) return;

                  if (doc.exists) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ClientPage(
                          marque: data['marque'] ?? '',
                          modele: data['modele'] ?? '',
                          immatriculation:
                              data['immatriculation'] ?? '',
                        ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Ce véhicule n'existe plus."),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                onLongPress: () => onLongPress(vehicle.id),
                child: Card(
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  color: Colors.white, 
                  child: Column(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                          ),
                          child: data['photoVehiculeUrl'] != null &&
                                  data['photoVehiculeUrl'].isNotEmpty
                              ? Image.network(
                                  data['photoVehiculeUrl'],
                                  width: double.infinity,
                                  height: double.infinity,
                                  fit: BoxFit.cover,
                                  loadingBuilder:
                                      (context, child, loadingProgress) {
                                    if (loadingProgress == null)
                                      return child;
                                    return const Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  },
                                  errorBuilder:
                                      (context, error, stackTrace) {
                                    return const Center(
                                      child: Icon(
                                        Icons.error,
                                        color: Colors.red,
                                        size: 50,
                                      ),
                                    );
                                  },
                                )
                              : const Center(
                                  child: Icon(
                                    Icons.directions_car_filled_rounded,
                                    size: 90,
                                    color: Colors.grey,
                                  ),
                                ),
                        ),
                      ),
                      const Divider(
                        color: Colors.black12,
                        height: 1,
                        thickness: 1,
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          children: [
                            Text(
                              "${data['marque']} ${data['modele']}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Color(0xFF1A237E),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "${data['immatriculation']}",
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
