import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widget/CREATION DE CONTRAT/client.dart';
import '../widget/MES CONTRATS/vehicle_access_manager.dart';
import 'client_access_checker.dart';

/// Un widget qui affiche une grille de véhicules
/// 
/// Ce widget prend une liste de véhicules filtrés et les affiche dans une grille
/// avec des cartes cliquables. Il gère également les interactions comme la
/// navigation vers la page de détails du véhicule.
class VehicleGridView extends StatelessWidget {
  /// Méthode commune pour naviguer vers la page client après vérification d'accès
  Future<void> _navigateToClientPage(BuildContext context, Map<String, dynamic> data) async {
    if (!context.mounted) return;
    
    // Vérifier l'accès à la page client
    final clientAccessChecker = ClientAccessChecker(context);
    final bool canAccess = await clientAccessChecker.canAccessClientPage();
    
    // Naviguer uniquement si l'accès est autorisé et le contexte est toujours valide
    if (canAccess && context.mounted) {
      // Naviguer vers la page de création de contrat
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ClientPage(
            immatriculation: data['immatriculation'] ?? '',
            marque: data['marque'] ?? '',
            modele: data['modele'] ?? '',
          ),
        ),
      );
    }
  }

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
                    // Utiliser directement les données du document data
                    if (data['isRented'] == 'en_cours' || data['isRented'] == 'réservé') {
                      // Pour les véhicules en cours ou réservés, afficher un popup d'avertissement mais autoriser la création
                      showDialog(
                        context: context,
                        builder: (context) => Dialog(
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  color: data['isRented'] == 'en_cours' ? Colors.red : Colors.orange,
                                  size: 60,
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  data['isRented'] == 'en_cours' ? "Véhicule loué" : "Véhicule réservé",
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF08004D),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  data['isRented'] == 'en_cours'
                                    ? "Attention : ce véhicule est loué. "
                                      "Restituez-le avant de créer un nouveau contrat, sauf si vous souhaitez le réserver."
                                    : (data['dateReserve'] != null
                                      ? "Attention : ce véhicule a été réservé pour le ${data['dateReserve']} et potentiellement en cours de location. "
                                        "Voulez-vous tout de même créer un contrat ?"
                                      : "Attention : ce véhicule est déjà réservé. "
                                        "Voulez-vous tout de même créer un contrat ?"),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 14),
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Expanded(
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.grey[300],
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                        ),
                                        onPressed: () {
                                          Navigator.pop(context); // Fermer le popup sans rien faire
                                        },
                                        child: const Text(
                                          'Annuler',
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF08004D),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                        ),
                                        onPressed: () async {
                                          Navigator.pop(context); // Fermer le popup
                                          // Utiliser la méthode commune pour naviguer vers ClientPage
                                          await _navigateToClientPage(context, data);
                                        },
                                        child: const Text(
                                          'Continuer',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    } else {
                      // Si le véhicule est disponible, utiliser la méthode commune pour naviguer vers ClientPage
                      await _navigateToClientPage(context, data);
                    }
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
                  child: Stack(
                    children: [
                      Column(
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
                      
                      // Badge de statut
                      if (data['isRented'] != null)
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: data['isRented'] == 'en_cours' 
                                ? Colors.red.withOpacity(0.9)
                                : data['isRented'] == 'réservé'
                                  ? Colors.orange.withOpacity(0.9)
                                  : Colors.green.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  data['isRented'] == 'en_cours'
                                    ? 'Loué'
                                    : data['isRented'] == 'réservé'
                                      ? 'Réservé'
                                      : 'Disponible',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                // Afficher les dates de début et fin pour les véhicules loués
                                if (data['isRented'] == 'en_cours')
                                  Column(
                                    children: [
                                      // Date de début (utiliser dateDebut ou dateReserve selon disponibilité)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 2),
                                        child: Text(
                                          data['dateReserve'] ?? "",
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      // Tiret de séparation et date de fin seulement si dateFinTheorique existe
                                      if (data['dateFinTheorique'] != null) ...[  
                                        const Text(
                                          '-',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        // Date de fin
                                        Text(
                                          data['dateFinTheorique'],
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                // Afficher la date de réservation pour les véhicules réservés
                                if (data['dateReserve'] != null && data['isRented'] == 'réservé')
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(
                                      '${data['dateReserve']}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
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
