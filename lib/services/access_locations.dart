import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Utilitaire pour gérer l'accès aux locations pour les collaborateurs et admins
/// Permet de s'assurer que les locations sont toujours accédées via l'ID admin
/// pour les collaborateurs, et via l'ID utilisateur pour les admins

class AccessLocations {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Récupère un contrat spécifique
  /// Pour un collaborateur, utilise l'ID de l'admin
  static Future<Map<String, dynamic>?> getContract(String contratId) async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      // Récupérer les données d'authentification directement
      print('📝 Vérification des données authentification pour le contrat');
      final authDocRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('authentification')
          .doc(user.uid);
          
      final authDoc = await authDocRef.get(GetOptions(source: Source.server));
      
      String targetId = user.uid;
      bool isCollaborateur = false;
      
      if (!authDoc.exists) {
        print('📝 Document auth non trouvé, vérification si collaborateur');
        // Essayer de récupérer depuis le document utilisateur principal
        final userDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .get(GetOptions(source: Source.server));

        if (!userDoc.exists) {
          print('⚠️ Utilisateur non trouvé');
          return null;
        }

        final userData = userDoc.data() ?? {};
        isCollaborateur = userData['role']?.toString() == 'collaborateur';
        
        if (isCollaborateur) {
          final adminId = userData['adminId']?.toString();
          if (adminId == null) {
            print('❌ AdminId non trouvé pour le collaborateur');
            return null;
          }
          targetId = adminId;
          print('👥 Collaborateur détecté, utilisation de l\'ID admin: $targetId');
        }
      } else {
        // Document d'authentification trouvé
        final authData = authDoc.data() ?? {};
        isCollaborateur = authData['role']?.toString() == 'collaborateur';
        
        if (isCollaborateur) {
          final adminId = authData['adminId']?.toString();
          if (adminId == null) {
            print('❌ AdminId non trouvé dans les données d\'authentification');
            return null;
          }
          targetId = adminId;
          print('👥 Collaborateur détecté (auth), utilisation de l\'ID admin: $targetId');
        }
      }

      print('📝 Chemin du contrat: users/$targetId/locations/$contratId');
      
      // Récupérer le contrat
      final contratDoc = await _firestore
          .collection('users')
          .doc(targetId)
          .collection('locations')
          .doc(contratId)
          .get(GetOptions(source: Source.server));

      if (!contratDoc.exists) {
        print('❌ Contrat non trouvé');
        return null;
      }

      return contratDoc.data() ?? {};
    } catch (e) {
      print('❌ Erreur lors de la récupération du contrat: $e');
      return null;
    }
  }

  /// Met à jour un contrat
  /// Pour un collaborateur, utilise l'ID de l'admin
  static Future<void> updateContract(String contratId, Map<String, dynamic> data) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Aucun utilisateur connecté');

    try {
      // Récupérer les données d'authentification directement
      print('📝 Vérification des données authentification pour la mise à jour');
      final authDocRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('authentification')
          .doc(user.uid);
          
      final authDoc = await authDocRef.get(GetOptions(source: Source.server));
      
      String targetId = user.uid;
      bool isCollaborateur = false;
      
      if (!authDoc.exists) {
        print('📝 Document auth non trouvé, vérification si collaborateur');
        // Essayer de récupérer depuis le document utilisateur principal
        final userDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .get(GetOptions(source: Source.server));

        if (!userDoc.exists) {
          print('⚠️ Utilisateur non trouvé');
          throw Exception('Impossible d\'accéder au document pour la mise à jour');
        }

        final userData = userDoc.data() ?? {};
        isCollaborateur = userData['role']?.toString() == 'collaborateur';
        
        if (isCollaborateur) {
          final adminId = userData['adminId']?.toString();
          if (adminId == null) {
            print('❌ AdminId non trouvé pour le collaborateur');
            throw Exception('ID cible non trouvé');
          }
          targetId = adminId;
          print('👥 Collaborateur détecté, utilisation de l\'ID admin: $targetId');
        }
      } else {
        // Document d'authentification trouvé
        final authData = authDoc.data() ?? {};
        isCollaborateur = authData['role']?.toString() == 'collaborateur';
        
        if (isCollaborateur) {
          final adminId = authData['adminId']?.toString();
          if (adminId == null) {
            print('❌ AdminId non trouvé dans les données d\'authentification');
            throw Exception('ID cible non trouvé');
          }
          targetId = adminId;
          print('👥 Collaborateur détecté (auth), utilisation de l\'ID admin: $targetId');
        }
      }

      print('📝 Mise à jour du contrat - targetId: $targetId, isCollaborateur: $isCollaborateur');
      print('📝 Chemin de la mise à jour: users/$targetId/locations/$contratId');
      
      // Mettre à jour le contrat
      await _firestore
          .collection('users')
          .doc(targetId)
          .collection('locations')
          .doc(contratId)
          .set(data, SetOptions(merge: true))
          .then((_) {
            print('✅ Document mis à jour avec succès');
          })
          .catchError((error) {
            print('❌ Erreur lors de la mise à jour: $error');
            throw error;
          });
    } catch (e) {
      print('❌ Erreur lors de la mise à jour du contrat: $e');
      rethrow;
    }
  }

  /// Crée un nouveau contrat
  /// Pour un collaborateur, utilise l'ID de l'admin
  static Future<String> createContract(Map<String, dynamic> data) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Aucun utilisateur connecté');

    try {
      // Récupérer les données d'authentification directement
      print('📝 Vérification des données authentification pour la création');
      final authDocRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('authentification')
          .doc(user.uid);
          
      final authDoc = await authDocRef.get(GetOptions(source: Source.server));
      
      String targetId = user.uid;
      bool isCollaborateur = false;
      
      if (!authDoc.exists) {
        print('📝 Document auth non trouvé, vérification si collaborateur');
        // Essayer de récupérer depuis le document utilisateur principal
        final userDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .get(GetOptions(source: Source.server));

        if (!userDoc.exists) {
          print('⚠️ Utilisateur non trouvé');
          throw Exception('Impossible d\'accéder au document pour la création');
        }

        final userData = userDoc.data() ?? {};
        isCollaborateur = userData['role']?.toString() == 'collaborateur';
        
        if (isCollaborateur) {
          final adminId = userData['adminId']?.toString();
          if (adminId == null) {
            print('❌ AdminId non trouvé pour le collaborateur');
            throw Exception('ID cible non trouvé');
          }
          targetId = adminId;
          print('👥 Collaborateur détecté, utilisation de l\'ID admin: $targetId');
        }
      } else {
        // Document d'authentification trouvé
        final authData = authDoc.data() ?? {};
        isCollaborateur = authData['role']?.toString() == 'collaborateur';
        
        if (isCollaborateur) {
          final adminId = authData['adminId']?.toString();
          if (adminId == null) {
            print('❌ AdminId non trouvé dans les données d\'authentification');
            throw Exception('ID cible non trouvé');
          }
          targetId = adminId;
          print('👥 Collaborateur détecté (auth), utilisation de l\'ID admin: $targetId');
        }
      }

      print('📝 Création d\'un contrat pour l\'ID: $targetId');
      print('📝 Chemin de création: users/$targetId/locations');
      
      // Créer le contrat
      final contratRef = _firestore
          .collection('users')
          .doc(targetId)
          .collection('locations')
          .doc();

      await contratRef.set(data, SetOptions(merge: true));
      print('✅ Contrat créé avec succès: ${contratRef.id}');
      return contratRef.id;
    } catch (e) {
      print('❌ Erreur lors de la création du contrat: $e');
      rethrow;
    }
  }

  /// Supprime un contrat
  /// Pour un collaborateur, utilise l'ID de l'admin
  static Future<void> deleteContract(String contratId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Aucun utilisateur connecté');

    try {
      // Récupérer les données d'authentification directement
      print('📝 Vérification des données authentification pour la suppression');
      final authDocRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('authentification')
          .doc(user.uid);
          
      final authDoc = await authDocRef.get(GetOptions(source: Source.server));
      
      String targetId = user.uid;
      bool isCollaborateur = false;
      
      if (!authDoc.exists) {
        print('📝 Document auth non trouvé, vérification si collaborateur');
        // Essayer de récupérer depuis le document utilisateur principal
        final userDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .get(GetOptions(source: Source.server));

        if (!userDoc.exists) {
          print('⚠️ Utilisateur non trouvé');
          throw Exception('Impossible d\'accéder au document pour la suppression');
        }

        final userData = userDoc.data() ?? {};
        isCollaborateur = userData['role']?.toString() == 'collaborateur';
        
        if (isCollaborateur) {
          final adminId = userData['adminId']?.toString();
          if (adminId == null) {
            print('❌ AdminId non trouvé pour le collaborateur');
            throw Exception('ID cible non trouvé');
          }
          targetId = adminId;
          print('👥 Collaborateur détecté, utilisation de l\'ID admin: $targetId');
        }
      } else {
        // Document d'authentification trouvé
        final authData = authDoc.data() ?? {};
        isCollaborateur = authData['role']?.toString() == 'collaborateur';
        
        if (isCollaborateur) {
          final adminId = authData['adminId']?.toString();
          if (adminId == null) {
            print('❌ AdminId non trouvé dans les données d\'authentification');
            throw Exception('ID cible non trouvé');
          }
          targetId = adminId;
          print('👥 Collaborateur détecté (auth), utilisation de l\'ID admin: $targetId');
        }
      }

      print('📝 Suppression du contrat: $contratId pour l\'ID: $targetId');
      print('📝 Chemin de suppression: users/$targetId/locations/$contratId');
      
      // Supprimer le contrat
      await _firestore
          .collection('users')
          .doc(targetId)
          .collection('locations')
          .doc(contratId)
          .delete();
          
      print('✅ Contrat supprimé avec succès');
    } catch (e) {
      print('❌ Erreur lors de la suppression du contrat: $e');
      rethrow;
    }
  }

  /// Récupère les données d'authentification de l'utilisateur (admin ou collaborateur)
  static Future<Map<String, dynamic>> getAuthData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return {};

      // Récupérer les données d'authentification directement
      print('📝 Vérification des données authentification');
      final authDocRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('authentification')
          .doc(user.uid);
          
      final authDoc = await authDocRef.get(GetOptions(source: Source.server));
      
      bool isCollaborateur = false;
      String? adminId;
      Map<String, dynamic> userData = {};
      
      if (!authDoc.exists) {
        print('📝 Document auth non trouvé, vérification si collaborateur');
        // Essayer de récupérer depuis le document utilisateur principal
        final userDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .get(GetOptions(source: Source.server));

        if (!userDoc.exists) {
          print('⚠️ Utilisateur non trouvé');
          return {};
        }

        userData = userDoc.data() ?? {};
        print('✅ Données utilisateur: $userData');
        
        // Vérifier si c'est un collaborateur
        final role = userData['role']?.toString();
        isCollaborateur = role == 'collaborateur';
        print('👥 Role collaborateur: $isCollaborateur');

        // Récupérer l'adminId
        if (isCollaborateur) {
          adminId = userData['adminId']?.toString();
          print('📝 AdminId trouvé: $adminId');
          if (adminId == null) {
            print('❌ AdminId non trouvé dans les données utilisateur');
            return {};
          }
        } else {
          adminId = user.uid;
        }
      } else {
        // Document d'authentification trouvé
        userData = authDoc.data() ?? {};
        print('✅ Données authentification: $userData');
        
        // Vérifier si c'est un collaborateur
        final role = userData['role']?.toString();
        isCollaborateur = role == 'collaborateur';
        print('👥 Role collaborateur (auth): $isCollaborateur');

        // Récupérer l'adminId
        if (isCollaborateur) {
          adminId = userData['adminId']?.toString();
          print('📝 AdminId trouvé (auth): $adminId');
          if (adminId == null) {
            print('❌ AdminId non trouvé dans les données d\'authentification');
            return {};
          }
        } else {
          adminId = user.uid;
        }
      }

      print('📝 Admin ID final: $adminId');
      
      return {
        'isCollaborateur': isCollaborateur,
        'adminId': adminId,
        'userId': user.uid,
        'role': userData['role'],
        'userData': userData
      };
    } catch (e) {
      print('❌ Erreur lors de la récupération des données: $e');
      return {};
    }
  }
}
