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
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  spreadRadius: 5,
                  blurRadius: 7,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Color(0xFF08004D).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.car_rental,
                    color: Color(0xFF08004D),
                    size: 40,
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  'Limite de Véhicules Atteinte',
                  style: TextStyle(
                    color: Color(0xFF08004D),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 15),
                Text(
                  "Vous avez atteint la limite de véhicules pour votre abonnement actuel.",
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 10),
                Text(
                  "Passez à un abonnement supérieur pour gérer plus de véhicules !",
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 25),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      ),
                      child: Text(
                        'Plus tard',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => AbonnementScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF08004D),
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text(
                        'Voir les Offres',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<bool> checkVehicleLimit({bool isUpdating = false, bool isVehicleUpdate = false}) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    // Récupérer le nombre de véhicules actuels
    final vehiclesSnapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('vehicules')
        .get();
    final currentVehicleCount = vehiclesSnapshot.docs.length;

    // Si c'est une mise à jour, ne pas vérifier la limite
    if (isUpdating || isVehicleUpdate) return true;

    // Récupérer la limite de l'abonnement
    final userDoc = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('authentification')
        .doc(user.uid)
        .get();
    final subscriptionId = userDoc.data()?['subscriptionId'] ?? 'free';
    final cb_subscription = userDoc.data()?['cb_subscription'] ?? 'free';
    int vehicleLimit = 1; // Par défaut, abonnement gratuit
    if (subscriptionId == 'pro-monthly_access' || 
        subscriptionId == 'pro-yearly_access' ||
        cb_subscription == 'pro-monthly_access' || 
        cb_subscription == 'pro-yearly_access') {
      vehicleLimit = 5;
    } else if (subscriptionId == 'premium-monthly_access' || 
               subscriptionId == 'premium-yearly_access' ||
               cb_subscription == 'premium-monthly_access' || 
               cb_subscription == 'premium-yearly_access') {
      vehicleLimit = 999;
    }

    if (currentVehicleCount >= vehicleLimit) {
      _showVehicleLimitDialog();
      return false;
    }
    return true;
  }
}
