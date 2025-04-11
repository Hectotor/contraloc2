import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../SCREENS/login.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/collaborateur_util.dart';
import '../utils/photo_upload_manager.dart'; // Import pour GlobalNotification

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
      // Afficher un indicateur de chargement pendant la déconnexion
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF08004D)),
          ),
        ),
      );

      // 1. Déconnecter Firebase Auth d'abord pour éviter les problèmes d'authentification
      await FirebaseAuth.instance.signOut();
      
      // 2. Effacer le cache du collaborateur
      await CollaborateurUtil.clearCache();
      
      // 3. Effacer les préférences partagées
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      
      print('👋 Déconnexion complète effectuée avec succès');
      
      // 4. Fermer la boîte de dialogue de chargement
      if (context.mounted) {
        Navigator.pop(context);
      }
      
      // 5. Rediriger vers la page de connexion et effacer la pile de navigation
      // Utiliser un délai plus long pour s'assurer que le contexte est stable
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Utiliser le navigateur global pour la redirection
      GlobalNotification.navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false, // Supprime toutes les routes précédentes
      );
    } catch (e) {
      // Fermer la boîte de dialogue de chargement en cas d'erreur
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la déconnexion: $e')),
        );
      }
      print('→ Erreur lors de la déconnexion: $e');
    }
  }
}
