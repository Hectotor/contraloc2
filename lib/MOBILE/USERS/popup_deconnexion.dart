import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:contraloc/main_mobile.dart'; // Import pour accéder à navigatorKey
import 'package:contraloc/MOBILE/widget/MES%20CONTRATS/vehicle_access_manager.dart';
import 'package:contraloc/MOBILE/screens/login.dart';

class PopupDeconnexion {
  static Future<void> showLogoutConfirmationDialog(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text(
          "Confirmation de déconnexion",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF08004D),
          ),
        ),
        content: const Text(
          "Êtes-vous sûr de vouloir vous déconnecter ?",
          style: TextStyle(
            fontSize: 18,
            color: Colors.black87,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              "Annuler",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF08004D),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _logout(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              "Se déconnecter",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Méthode pour déconnecter l'utilisateur complètement
  static Future<void> _logout(BuildContext context) async {
    try {
      // Disposer de tous les gestionnaires qui pourraient causer des erreurs de permission
      // IMPORTANT: Nettoyer les streams AVANT de naviguer ou de déconnecter
      print('🔄 Nettoyage des gestionnaires avant déconnexion');
      VehicleAccessManager.instance.dispose();
      
      // Navigation immédiate vers la page de connexion pour éviter les erreurs de permission
      // dues aux streams actifs
      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false, // Supprime toutes les routes précédentes
      );
      
      // Attendre un court instant pour que l'écran de login soit affiché
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Déconnecter Firebase Auth après la navigation pour éviter les erreurs de permission
      await FirebaseAuth.instance.signOut();
      
      // Effacer les préférences partagées
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      
      print('👋 Déconnexion complète effectuée avec succès');
    } catch (e) {
      print('→ Erreur lors de la déconnexion: $e');
      // Même en cas d'erreur, s'assurer que l'utilisateur est redirigé vers login
      if (navigatorKey.currentState?.context != null) {
        navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
      }
    }
  }
}