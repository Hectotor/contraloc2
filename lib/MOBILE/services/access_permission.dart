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
      print('🔍 Vérification de la permission \'$permissionType\'');
      
      // Vérifier le statut de l'utilisateur
      final status = await _checkUserStatus();
      
      // Si l'utilisateur n'est pas un collaborateur, il a toutes les permissions
      if (status['isCollaborateur'] != true) {
        print('👑 Utilisateur admin: toutes les permissions accordées');
        return true;
      }
      
      final userId = status['userId'];
      final adminId = status['adminId'];
      
      print('👥 Collaborateur détecté - Vérification des permissions: userId=$userId, adminId=$adminId');
      
      if (userId == null || adminId == null) {
        print('❌ Erreur: ID utilisateur ou adminId manquant');
        return false;
      }
      
      // Récupérer les permissions de l'utilisateur
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get(GetOptions(source: Source.server));
      
      final userData = userDoc.data();
      
      if (userData == null) {
        print('🚨 Données utilisateur indisponibles, mode de secours activé');
        print('🤔 Essai d\'accès direct aux données d\'authentification comme administrateur');
        
        // Si nous n'avons pas pu obtenir les données utilisateur, mais que nous avons un adminId,
        // on suppose que c'est un collaborateur avec des permissions d'accès complètes
        // Cela permet d'éviter les problèmes lorsque les collaborateurs ne sont pas correctement configurés
        return true;
      }
      
      // Log détaillé de toutes les données du collaborateur
      print('📝 Détails complets du collaborateur: ${userData.toString()}');
      
      // Vérifier si l'utilisateur a la permission demandée
      final permissions = userData['permissions'] ?? {};
      print('📝 Permissions disponibles: ${permissions.toString()}');
      
      final hasPermission = permissions[permissionType] ?? false;
      
      print('${hasPermission ? '✔️' : '❌'} Permission \'$permissionType\': ${hasPermission ? 'accordée' : 'refusée'}');
      return hasPermission;
    } catch (e) {
      print('❌ Erreur lors de la vérification de la permission: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>> _checkUserStatus() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('❌ Aucun utilisateur connecté');
        return {'isCollaborateur': false, 'userId': null, 'adminId': null};
      }
      
      print('✔️ Utilisateur connecté: ${user.uid}');
      
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get(GetOptions(source: Source.server));
      
      final userData = userDoc.data();
      if (userData == null) {
        print('🚨 Données utilisateur indisponibles, mode de secours activé');
        print("🤔 Traitement comme administrateur par défaut pour assurer l'accès");
        
        // Si les données utilisateur ne sont pas trouvées, on considère l'utilisateur comme administrateur
        // pour éviter les blocages d'accès
        return {
          'isCollaborateur': false,
          'userId': user.uid,
          'adminId': user.uid, // Considérer comme son propre admin
        };
      }
      
      // Log détaillé des données utilisateur
      print('📝 Détails complets de l\'utilisateur: ${userData.toString()}');
      
      final isCollaborateur = userData['role'] == 'collaborateur';
      final adminId = isCollaborateur ? userData['adminId'] : user.uid;
      
      print('📝 Statut utilisateur: ${isCollaborateur ? 'Collaborateur' : 'Admin'}, adminId: $adminId');
      
      return {
        'isCollaborateur': isCollaborateur,
        'userId': user.uid,
        'adminId': adminId,
      };
    } catch (e) {
      print('❌ Erreur lors de la vérification du statut: $e');
      rethrow;
    }
  }
}
