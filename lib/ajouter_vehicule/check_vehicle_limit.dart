import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ContraLoc/USERS/abonnement_screen.dart';

class VehicleLimitChecker {
  final BuildContext context;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  VehicleLimitChecker(this.context);

  void _showVehicleLimitDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.warning_rounded, color: Color(0xFF08004D), size: 30),
              SizedBox(width: 10),
              Text(
                'Limite Atteinte',
                style: TextStyle(
                  color: Color(0xFF08004D),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            "Vous avez atteint la limite de véhicules pour votre abonnement. "
            "Passez à un abonnement supérieur pour ajouter plus de véhicules.",
            style: TextStyle(color: Colors.black87),
            textAlign: TextAlign.center,
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Voir les Abonnements',
                style: TextStyle(color: Color(0xFF08004D)),
              ),
              onPressed: () {
                Navigator.of(context).pop(); // Fermer le dialog
                // Naviguer vers l'écran des abonnements
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AbonnementScreen()),
                );
              },
            ),
            TextButton(
              child: Text(
                'Fermer',
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<bool> checkVehicleLimit() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    // Récupérer le nombre de véhicules actuels
    final vehiclesSnapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('vehicules')
        .get();
    final currentVehicleCount = vehiclesSnapshot.docs.length;

    // Récupérer la limite de l'abonnement
    final userDoc = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('authentification')
        .doc(user.uid)
        .get();
    
    final subscriptionId = userDoc.data()?['subscriptionId'] ?? 'free';
    
    int vehicleLimit = 1; // Par défaut, abonnement gratuit
    if (subscriptionId == 'pro-monthly_access' || 
        subscriptionId == 'pro-yearly_access') {
      vehicleLimit = 5;
    } else if (subscriptionId == 'premium-monthly_access' || 
               subscriptionId == 'premium-yearly_access') {
      vehicleLimit = 999;
    }

    if (currentVehicleCount >= vehicleLimit) {
      _showVehicleLimitDialog();
      return false;
    }
    return true;
  }
}
