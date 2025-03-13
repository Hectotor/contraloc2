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

      // Vérifier si c'est un admin ou un collaborateur
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception("User not authenticated");
      
      final currentUserDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      final currentUserData = currentUserDoc.data();
      final isCollaborateur = currentUserData?['role'] == 'collaborateur';

      // Récupérer la limite de véhicules de l'utilisateur
      DocumentSnapshot<Map<String, dynamic>> userDoc;
      if (isCollaborateur) {
        // Pour un collaborateur, lire les données de l'admin dans authentification
        userDoc = await _firestore
            .collection('users')
            .doc(targetUserId)
            .collection('authentification')
            .doc(targetUserId)
            .get();
      } else {
        // Pour un admin, lire directement dans son document
        userDoc = await _firestore
            .collection('users')
            .doc(targetUserId)
            .get();
      }

      final userData = userDoc.data();
      if (userData == null) {
        print('❌ Données utilisateur non trouvées');
        return false;
      }
      
      // Fonction utilitaire pour récupérer les valeurs entières de manière sécurisée
      int getIntValue(dynamic value, int defaultValue) {
        if (value == null) return defaultValue;
        if (value is int) return value;
        if (value is String) {
          final parsed = int.tryParse(value);
          if (parsed != null) return parsed;
        }
        return defaultValue;
      }

      // Récupérer les deux valeurs de limite de manière sécurisée
      final numberOfCars = getIntValue(userData['numberOfCars'], 1);
      final cb_nb_car = getIntValue(userData['cb_nb_car'], 1);
      
      print('🔍 Valeurs brutes - numberOfCars: $numberOfCars, cb_nb_car: $cb_nb_car');
      
      // Déterminer la limite finale selon la logique des MEMORIES
      int limiteVehicule;
      
      // 1. Vérifier numberOfCars en premier
      if (numberOfCars > 1 || numberOfCars == 999) {
        print('✅ Utilisation de numberOfCars: $numberOfCars');
        limiteVehicule = numberOfCars;
      }
      // 2. Si numberOfCars est 1, vérifier cb_nb_car
      else if (cb_nb_car > 1 || cb_nb_car == 999) {
        print('✅ Utilisation de cb_nb_car: $cb_nb_car');
        limiteVehicule = cb_nb_car;
      }
      // 3. Si les deux sont à 1, garder 1
      else {
        print('ℹ️ Les deux limites sont à 1, utilisation de la limite par défaut');
        limiteVehicule = 1;
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
