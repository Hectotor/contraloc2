import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthUtil {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Récupère les données d'authentification de l'utilisateur
  static Future<Map<String, dynamic>> getAuthData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('\u274c Aucun utilisateur connect\u00e9');
        return {};
      }

      print('\u2705 Utilisateur authentifi\u00e9: ${user.uid}');

      // Vérifier d'abord dans le document utilisateur principal
      final userDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get(const GetOptions(source: Source.server));

      // Si le document principal n'existe pas, vérifions dans la sous-collection authentification
      if (!userDoc.exists || userDoc.data() == null) {
        print('\u2139\ufe0f Document utilisateur principal non trouv\u00e9, recherche dans authentification');
        
        final authDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('authentification')
            .doc(user.uid)
            .get(const GetOptions(source: Source.server));
            
        if (!authDoc.exists || authDoc.data() == null) {
          print('\u274c Document d\'authentification non trouv\u00e9 pour ${user.uid}');
          return {};
        }
        
        print('\u2705 Document d\'authentification r\u00e9cup\u00e9r\u00e9 avec succ\u00e8s');
        
        final userData = authDoc.data()!;
        final bool isCollaborateur = userData['role']?.toString() == 'collaborateur';
        print('\u2139\ufe0f R\u00f4le utilisateur (depuis auth): ${isCollaborateur ? 'collaborateur' : 'admin'}');
        
        String? adminId;
        if (isCollaborateur) {
          adminId = userData['adminId']?.toString();
          if (adminId == null) {
            print('\u274c ID administrateur manquant pour le collaborateur ${user.uid}');
            return {};
          }
          print('\u2705 Collaborateur avec admin ID: $adminId');
        } else {
          // Pour un admin, son propre ID est utilis\u00e9 comme adminId
          adminId = user.uid;
          print('\u2705 Administrateur d\u00e9tect\u00e9, utilisation de son propre ID: $adminId');
        }
        
        return {
          'isCollaborateur': isCollaborateur,
          'adminId': adminId,
        };
      }

      print('\u2705 Document utilisateur principal r\u00e9cup\u00e9r\u00e9 avec succ\u00e8s');

      final userData = userDoc.data()!;
      final bool isCollaborateur = userData['role']?.toString() == 'collaborateur';
      print('\u2139\ufe0f R\u00f4le utilisateur: ${isCollaborateur ? 'collaborateur' : 'admin'}');
      
      String? adminId;
      if (isCollaborateur) {
        adminId = userData['adminId']?.toString();
        if (adminId == null) {
          print('\u274c ID administrateur manquant pour le collaborateur ${user.uid}');
          return {};
        }
        print('\u2705 Collaborateur avec admin ID: $adminId');
      } else {
        // Pour un admin, son propre ID est utilis\u00e9 comme adminId
        adminId = user.uid;
        print('\u2705 Administrateur d\u00e9tect\u00e9, utilisation de son propre ID: $adminId');
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
      print('\ud83d\udc41 Essai d\'acc\u00e8s direct aux donn\u00e9es d\'authentification comme administrateur');
      
      // Essayer d'abord de vérifier le document principal
      final userDoc = await _firestore
          .collection('users')
          .doc(userId)
          .get(const GetOptions(source: Source.server));

      // Si le document principal existe
      if (userDoc.exists) {
        print('\u2705 Document utilisateur principal trouv\u00e9');
        return _firestore
          .collection('users')
          .doc(userId)
          .collection('authentification')
          .doc(userId);
      }
      
      // Vérifier si la sous-collection authentification existe
      final authDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('authentification')
          .doc(userId)
          .get(const GetOptions(source: Source.server));
          
      if (authDoc.exists) {
        print('\u2705 Document d\'authentification trouv\u00e9 directement');
        return _firestore
            .collection('users')
            .doc(userId)
            .collection('authentification')
            .doc(userId);
      }

      // Si aucun document n'est trouvé, créer la référence quand même
      print('\u26a0\ufe0f Aucun document trouv\u00e9, mais cr\u00e9ation de la r\u00e9f\u00e9rence pour ${userId}');
      return _firestore
          .collection('users')
          .doc(userId)
          .collection('authentification')
          .doc(userId);
    } catch (e) {
      print('\u274c Erreur lors de la récupération de la référence d\'authentification: $e');
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
