import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_util.dart';
import 'package:contraloc/MOBILE/USERS/Subscription/abonnement_screen.dart';

/// Classe qui vérifie si un utilisateur a le droit d'accéder à la page client
/// en fonction de son abonnement et du nombre de véhicules qu'il possède
class ClientAccessChecker {
  final BuildContext context;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  ClientAccessChecker(this.context);

  /// Affiche une boîte de dialogue informant l'utilisateur qu'il doit passer à un abonnement supérieur
  void _showUpgradeSubscriptionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.lock_outline,
                  color: Color(0xFF08004D),
                  size: 60,
                ),
                const SizedBox(height: 20),
                const Text(
                  "Accès Limité",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF08004D),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Avec l'abonnement gratuit, vous ne pouvez créer des contrats que pour 1 seul véhicule.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Passez à un abonnement supérieur pour gérer des contrats pour tous vos véhicules !",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey),
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
                          Navigator.pop(context);
                        },
                        child: const Text(
                          'Retour',
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
                          backgroundColor: Color(0xFF08004D),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const AbonnementScreen()),
                          );
                        },
                        child: const Text(
                          'Voir les Offres',
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
        );
      },
    );
  }

  /// Vérifie si l'utilisateur a le droit d'accéder à la page client
  /// Retourne true si l'accès est autorisé, false sinon
  Future<bool> canAccessClientPage() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print("❌ Utilisateur non connecté");
        return false;
      }

      // Vérifier si l'utilisateur est un collaborateur
      final status = await AuthUtil.getAuthData();
      final isCollaborateur = status['isCollaborateur'] ?? false;
      final adminId = status['adminId'];
      
      // Déterminer l'ID à utiliser (admin ou utilisateur courant)
      final targetId = isCollaborateur ? adminId : user.uid;
      
      if (targetId == null) {
        print("❌ ID cible non disponible");
        return false;
      }
      
      // Récupérer le document d'authentification de l'utilisateur
      final userDoc = await _firestore
          .collection('users')
          .doc(targetId)
          .collection('authentification')
          .doc(targetId)
          .get();
      
      // Vérifier si l'utilisateur a un abonnement payant
      final data = userDoc.data();
      if (data == null) {
        print("❌ Données d'authentification non disponibles");
        return false;
      }
      
      // Vérifier les différents types d'abonnements
      final bool hasPaidSubscription = _checkForPaidSubscription(data);
      
      // Si l'utilisateur a un abonnement payant, il peut accéder à la page client
      if (hasPaidSubscription) {
        print("✅ Utilisateur avec abonnement payant - Accès autorisé");
        return true;
      }
      
      // Si l'utilisateur a un abonnement gratuit, vérifier le nombre de véhicules
      final vehiclesSnapshot = await _firestore
          .collection('users')
          .doc(targetId)
          .collection('vehicules')
          .get();

      final vehicleCount = vehiclesSnapshot.docs.length;
      
      // Si l'utilisateur a plus d'un véhicule avec un abonnement gratuit, bloquer l'accès
      if (vehicleCount > 1) {
        print("❌ Utilisateur avec abonnement gratuit et $vehicleCount véhicules - Accès refusé");
        _showUpgradeSubscriptionDialog();
        return false;
      }
      
      // Sinon, autoriser l'accès (abonnement gratuit avec 0 ou 1 véhicule)
      print("✅ Utilisateur avec abonnement gratuit et $vehicleCount véhicule(s) - Accès autorisé");
      return true;
    } catch (e) {
      print('❌ Erreur lors de la vérification d\'accès à la page client: $e');
      return false;
    }
  }
  
  /// Vérifie si l'utilisateur a un abonnement payant en examinant les différents champs d'abonnement
  bool _checkForPaidSubscription(Map<String, dynamic> userData) {
    // Vérifier l'abonnement RevenueCat
    final String? subscriptionId = userData['subscriptionId'];
    if (subscriptionId != null && subscriptionId != 'free' && subscriptionId != '') {
      return true;
    }
    
    // Vérifier l'abonnement Stripe
    final String? stripePlanType = userData['stripePlanType'];
    if (stripePlanType != null && stripePlanType != 'free' && stripePlanType != '') {
      return true;
    }
    
    // Vérifier l'abonnement CB
    final String? cbSubscription = userData['cb_subscription'];
    if (cbSubscription != null && cbSubscription != 'free' && cbSubscription != '') {
      return true;
    }
    return false;
  }
}
