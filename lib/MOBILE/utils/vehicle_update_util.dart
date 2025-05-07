import 'package:cloud_firestore/cloud_firestore.dart';

/// Utilitaire pour mettre à jour les informations des véhicules
class VehicleUpdateUtil {
  /// Met à jour le kilométrage actuel du véhicule dans la collection vehicules
  /// Ne met à jour le kilométrage que si une valeur est fournie
  static Future<bool> updateVehicleCurrentKilometrage({
    required String adminId,
    required String immatriculation,
    required String? kilometrage,
  }) async {
    // Ne pas mettre à jour si le kilométrage n'est pas fourni
    if (kilometrage == null || kilometrage.isEmpty) {
      print('❌ Impossible de mettre à jour le kilométrage actuel: kilométrage non spécifié');
      return false;
    }

    // Ne pas mettre à jour si l'immatriculation n'est pas fournie
    if (immatriculation.isEmpty) {
      print('❌ Impossible de mettre à jour le kilométrage actuel: immatriculation non spécifiée');
      return false;
    }

    try {
      // Rechercher le véhicule par immatriculation
      final vehiculesSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(adminId)
          .collection('vehicules')
          .where('immatriculation', isEqualTo: immatriculation)
          .limit(1)
          .get();

      if (vehiculesSnapshot.docs.isEmpty) {
        print('❌ Véhicule non trouvé avec l\'immatriculation: $immatriculation');
        return false;
      }

      // Mettre à jour le kilométrage actuel du véhicule
      final vehiculeDoc = vehiculesSnapshot.docs.first;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(adminId)
          .collection('vehicules')
          .doc(vehiculeDoc.id)
          .update({
        'kilometrageActuel': kilometrage,
        'dateModification': FieldValue.serverTimestamp(),
      });

      print('✅ Kilométrage actuel du véhicule mis à jour: $kilometrage km');
      return true;
    } catch (e) {
      print('❌ Erreur lors de la mise à jour du kilométrage actuel du véhicule: $e');
      return false;
    }
  }
}
