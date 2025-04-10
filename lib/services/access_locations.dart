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
      // Récupérer les données de l'utilisateur
      final userDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get(GetOptions(source: Source.server));

      if (!userDoc.exists) {
        print('❌ Document utilisateur non trouvé');
        return null;
      }

      final userData = userDoc.data() ?? {};
      final isCollaborateur = userData['role']?.toString() == 'collaborateur';
      final targetId = isCollaborateur ? userData['adminId']?.toString() : user.uid;

      if (targetId == null) {
        print('❌ ID cible non trouvé');
        return null;
      }

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
      // Récupérer les données de l'utilisateur
      final userDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get(GetOptions(source: Source.server));

      if (!userDoc.exists) {
        throw Exception('Document utilisateur non trouvé');
      }

      final userData = userDoc.data() ?? {};
      final isCollaborateur = userData['role']?.toString() == 'collaborateur';
      final targetId = isCollaborateur ? userData['adminId']?.toString() : user.uid;

      if (targetId == null) {
        throw Exception('ID cible non trouvé');
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
      // Récupérer les données de l'utilisateur
      final userDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get(GetOptions(source: Source.server));

      if (!userDoc.exists) {
        throw Exception('Document utilisateur non trouvé');
      }

      final userData = userDoc.data() ?? {};
      final isCollaborateur = userData['role']?.toString() == 'collaborateur';
      final targetId = isCollaborateur ? userData['adminId']?.toString() : user.uid;

      if (targetId == null) {
        throw Exception('ID cible non trouvé');
      }

      // Créer le contrat
      final contratRef = _firestore
          .collection('users')
          .doc(targetId)
          .collection('locations')
          .doc();

      await contratRef.set(data, SetOptions(merge: true));
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
      // Récupérer les données de l'utilisateur
      final userDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get(GetOptions(source: Source.server));

      if (!userDoc.exists) {
        throw Exception('Document utilisateur non trouvé');
      }

      final userData = userDoc.data() ?? {};
      final isCollaborateur = userData['role']?.toString() == 'collaborateur';
      final targetId = isCollaborateur ? userData['adminId']?.toString() : user.uid;

      if (targetId == null) {
        throw Exception('ID cible non trouvé');
      }

      // Supprimer le contrat
      await _firestore
          .collection('users')
          .doc(targetId)
          .collection('locations')
          .doc(contratId)
          .delete();
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

      // Récupérer les données de l'utilisateur
      final userDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get(GetOptions(source: Source.server));

      if (!userDoc.exists) {
        print('❌ Document utilisateur non trouvé');
        return {};
      }

      final userData = userDoc.data() ?? {};
      print('✅ Données utilisateur: $userData');
      
      // Vérifier si c'est un collaborateur
      final role = userData['role']?.toString();
      final isCollaborateur = role == 'collaborateur';
      print('👤 Role collaborateur: $isCollaborateur');

      // Récupérer l'adminId
      String? adminId;
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

      print('👤 Admin ID final: $adminId');
      
      return {
        'isCollaborateur': isCollaborateur,
        'adminId': adminId,
        'userId': user.uid,
        'role': role,
        'userData': userData
      };
    } catch (e) {
      print('❌ Erreur lors de la récupération des données: $e');
      return {};
    }
  }
}
