import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../USERS/abonnement_screen.dart';

class VehicleLimitChecker {
  final BuildContext context;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  VehicleLimitChecker(this.context);

  Future<String> _getTargetUserId() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User not authenticated");

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final userData = userDoc.data();

    if (userData != null && userData['role'] == 'collaborateur') {
      print('👥 Vérification limite véhicules du compte admin');
      return userData['adminId'];
    } else {
      print('👤 Vérification limite véhicules du compte utilisateur');
      return user.uid;
    }
  }

  Future<bool> checkVehicleLimit({bool isUpdating = false}) async {
    try {
      final targetUserId = await _getTargetUserId();

      // Si c'est une mise à jour, pas besoin de vérifier la limite
      if (isUpdating) {
        print('✅ Mise à jour d\'un véhicule existant, pas de vérification de limite');
        return true;
      }

      // Récupérer la limite de véhicules de l'utilisateur
      final userDoc = await _firestore
          .collection('users')
          .doc(targetUserId)
          .collection('authentification')
          .doc(targetUserId)
          .get();

      final cb_limite_vehicule = userDoc.data()?['cb_limite_vehicule'] ?? 2;
      int limiteVehicule = 2; // Limite par défaut

      // Si cb_limite_vehicule est 999, on garde cette limite illimitée
      if (cb_limite_vehicule == 999) {
        limiteVehicule = 999;
      } else {
        // Si cb_limite_vehicule est 2, on vérifie limiteVehicule
        final limiteVehiculeTemp = userDoc.data()?['limiteVehicule'] ?? 2;
        // Si limiteVehicule est 999, on prend 999, sinon on garde 2
        if (limiteVehiculeTemp == 999) {
          limiteVehicule = 999;
        }
      }

      // Compter le nombre de véhicules actuels
      final vehiculesSnapshot = await _firestore
          .collection('users')
          .doc(targetUserId)
          .collection('vehicules')
          .get();

      final nombreVehicules = vehiculesSnapshot.docs.length;
      print('📊 Nombre de véhicules: $nombreVehicules sur $limiteVehicule autorisés');

      if (nombreVehicules >= limiteVehicule) {
        _showLimitReachedDialog();
        return false;
      }

      return true;
    } catch (e) {
      print('❌ Erreur vérification limite véhicules: $e');
      return false;
    }
  }

  void _showLimitReachedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text(
            "Limite de véhicules atteinte",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF08004D),
            ),
          ),
          content: const Text(
            "Vous avez atteint votre limite de véhicules. Passez à un abonnement supérieur pour ajouter plus de véhicules.",
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Plus tard",
                style: TextStyle(color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AbonnementScreen(),
                  ),
                );
              },
              child: const Text(
                "Voir les abonnements",
                style: TextStyle(
                  color: Color(0xFF08004D),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
