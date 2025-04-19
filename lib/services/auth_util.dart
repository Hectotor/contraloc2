import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthUtil {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Récupère les données d'authentification de l'utilisateur
  static Future<Map<String, dynamic>> getAuthData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return {};

      final userDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get(const GetOptions(source: Source.server));

      if (!userDoc.exists || userDoc.data() == null) {
        return {};
      }

      final userData = userDoc.data()!;
      final bool isCollaborateur = userData['role']?.toString() == 'collaborateur';
      
      String? adminId;
      if (isCollaborateur) {
        adminId = userData['adminId']?.toString();
        if (adminId == null) {
          return {};
        }
      } else {
        adminId = user.uid;
      }

      return {
        'isCollaborateur': isCollaborateur,
        'adminId': adminId,
      };
    } catch (e) {
      print('❌ Erreur lors de la récupération des données: $e');
      return {};
    }
  }

  /// Obtient la référence au document d'authentification pour un utilisateur
  static Future<DocumentReference> getAuthDocRef(String userId) async {
    try {
      final userDoc = await _firestore
          .collection('users')
          .doc(userId)
          .get(const GetOptions(source: Source.server));

      if (!userDoc.exists) {
        throw Exception('Utilisateur non trouvé');
      }

      return _firestore
          .collection('users')
          .doc(userId)
          .collection('authentification')
          .doc(userId);
    } catch (e) {
      print('❌ Erreur lors de la récupération de la référence d\'authentification: $e');
      throw e;
    }
  }
}

/// Extension pour rendre la méthode plus facile à utiliser
extension AuthUtilExtension on AuthUtil {
  static Future<bool> isUserCollaborateur() async {
    final data = await AuthUtil.getAuthData();
    return data['isCollaborateur'] ?? false;
  }
  
  static Future<String?> getAdminId() async {
    final data = await AuthUtil.getAuthData();
    return data['adminId'] as String?;
  }
}
