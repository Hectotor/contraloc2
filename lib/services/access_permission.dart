import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AccessPermission {
  static const String PERMISSION_READ = 'lecture';
  static const String PERMISSION_WRITE = 'ecriture';
  static const String PERMISSION_DELETE = 'suppression';

  /// Vérifie si un collaborateur a une permission spécifique
  /// Paramètres:
  /// - permissionType: 'lecture', 'ecriture', ou 'suppression'
  static Future<bool> checkPermission(String permissionType) async {
    try {
      print("🔍 Vérification de la permission '$permissionType'");
      
      // Vérifier le statut de l'utilisateur
      final status = await _checkUserStatus();
      
      // Si l'utilisateur n'est pas un collaborateur, il a toutes les permissions
      if (status['isCollaborateur'] != true) {
        print("👑 Utilisateur admin: toutes les permissions accordées");
        return true;
      }
      
      final userId = status['userId'];
      final adminId = status['adminId'];
      
      if (userId == null || adminId == null) {
        print("❌ Erreur: ID utilisateur ou adminId manquant");
        return false;
      }
      
      // Récupérer les permissions de l'utilisateur
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      
      final userData = userDoc.data();
      
      if (userData == null) {
        print("❌ Erreur: Données utilisateur non trouvées");
        return false;
      }
      
      // Vérifier si l'utilisateur a la permission demandée
      final permissions = userData['permissions'] ?? {};
      final hasPermission = permissions[permissionType] ?? false;
      
      print("✅ Permission '$permissionType': ${hasPermission ? 'accordée' : 'refusée'}");
      return hasPermission;
    } catch (e) {
      print("❌ Erreur lors de la vérification de la permission: $e");
      return false;
    }
  }

  static Future<Map<String, dynamic>> _checkUserStatus() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print("❌ Aucun utilisateur connecté");
        return {'isCollaborateur': false, 'userId': null, 'adminId': null};
      }
      
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      
      final userData = userDoc.data();
      if (userData == null) {
        print("❌ Données utilisateur non trouvées");
        return {'isCollaborateur': false, 'userId': user.uid, 'adminId': null};
      }
      
      final isCollaborateur = userData['role'] == 'collaborateur';
      final adminId = isCollaborateur ? userData['adminId'] : user.uid;
      
      return {
        'isCollaborateur': isCollaborateur,
        'userId': user.uid,
        'adminId': adminId,
      };
    } catch (e) {
      print("❌ Erreur lors de la vérification du statut: $e");
      rethrow;
    }
  }
}
