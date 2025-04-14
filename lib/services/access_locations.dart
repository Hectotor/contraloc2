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
      // Récupérer les informations sur l'utilisateur pour savoir s'il est collaborateur
      final userDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get(const GetOptions(source: Source.server));

      if (!userDoc.exists || userDoc.data() == null) {
        print('⚠️ Utilisateur non trouvé');
        print('👀 Traitement comme administrateur par défaut pour la récupération');
        
        // Si les données utilisateur ne sont pas trouvées, on utilise l'ID de l'utilisateur connecté
        String targetId = user.uid;
        
        print('📝 Chemin du contrat par défaut: users/$targetId/locations/$contratId');
        
        // Récupérer le contrat avec l'ID de l'utilisateur par défaut
        final contratDoc = await _firestore
            .collection('users')
            .doc(targetId)
            .collection('locations')
            .doc(contratId)
            .get(const GetOptions(source: Source.server));

        if (!contratDoc.exists) {
          print('❌ Contrat non trouvé dans le chemin par défaut');
          return null;
        }

        print('✅ Contrat récupéré avec succès (mode par défaut)');
        return contratDoc.data() ?? {};
      }

      final userData = userDoc.data()!;
      String targetId = user.uid;
      final bool isCollaborateur = userData['role']?.toString() == 'collaborateur';
      
      if (isCollaborateur) {
        final adminId = userData['adminId']?.toString();
        if (adminId == null) {
          print('❌ AdminId non trouvé pour le collaborateur');
          return null;
        }
        targetId = adminId;
        print('👥 Collaborateur détecté, utilisation de l\'ID admin: $targetId');
      }

      print('📝 Chemin du contrat: users/$targetId/locations/$contratId');
      
      // Récupérer le contrat
      final contratDoc = await _firestore
          .collection('users')
          .doc(targetId)
          .collection('locations')
          .doc(contratId)
          .get(const GetOptions(source: Source.server));

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
      // Récupérer les informations sur l'utilisateur pour savoir s'il est collaborateur
      final userDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get(const GetOptions(source: Source.server));

      if (!userDoc.exists || userDoc.data() == null) {
        print('⚠️ Utilisateur non trouvé');
        print('👀 Traitement comme administrateur par défaut pour la mise à jour');
        
        // Si les données utilisateur ne sont pas trouvées, on utilise l'ID de l'utilisateur connecté
        // comme cible pour la mise à jour (comportement par défaut pour un administrateur)
        String targetId = user.uid;
        
        print('📝 Mise à jour du contrat: $contratId pour l\'ID par défaut: $targetId');
        print('📝 Chemin de mise à jour: users/$targetId/locations/$contratId');
        
        // Mettre à jour le contrat avec l'ID de l'utilisateur par défaut
        await _firestore
            .collection('users')
            .doc(targetId)
            .collection('locations')
            .doc(contratId)
            .set(data, SetOptions(merge: true));
            
        print('✅ Contrat mis à jour avec succès (mode par défaut)');
        return; // Sortir de la fonction après la mise à jour réussie
      }

      final userData = userDoc.data()!;
      String targetId = user.uid;
      final bool isCollaborateur = userData['role']?.toString() == 'collaborateur';
      
      if (isCollaborateur) {
        final adminId = userData['adminId']?.toString();
        if (adminId == null) {
          print('❌ AdminId non trouvé pour le collaborateur');
          throw Exception('ID cible non trouvé');
        }
        targetId = adminId;
        print('👥 Collaborateur détecté, utilisation de l\'ID admin: $targetId');
      }

      print('📝 Mise à jour du contrat: $contratId pour l\'ID: $targetId');
      print('📝 Chemin de mise à jour: users/$targetId/locations/$contratId');
      
      // Mettre à jour le contrat
      await _firestore
          .collection('users')
          .doc(targetId)
          .collection('locations')
          .doc(contratId)
          .set(data, SetOptions(merge: true));
          
      print('✅ Contrat mis à jour avec succès');
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
      // Récupérer les informations sur l'utilisateur pour savoir s'il est collaborateur
      final userDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get(const GetOptions(source: Source.server));

      if (!userDoc.exists || userDoc.data() == null) {
        print('⚠️ Utilisateur non trouvé');
        print('👀 Traitement comme administrateur par défaut pour la création');
        
        // Si les données utilisateur ne sont pas trouvées, on utilise l'ID de l'utilisateur connecté
        String targetId = user.uid;
        
        print('📝 Création d\'un contrat pour l\'ID par défaut: $targetId');
        
        // Créer le contrat avec un ID automatique
        final docRef = _firestore
            .collection('users')
            .doc(targetId)
            .collection('locations')
            .doc();
        
        // Ajouter l'ID du document aux données
        final updatedData = Map<String, dynamic>.from(data);
        updatedData['id'] = docRef.id;
        
        // Enregistrer les données
        await docRef.set(updatedData);
        
        print('✅ Contrat créé avec succès en mode par défaut, ID: ${docRef.id}');
        return docRef.id;
      }

      final userData = userDoc.data()!;
      String targetId = user.uid;
      final bool isCollaborateur = userData['role']?.toString() == 'collaborateur';
      
      if (isCollaborateur) {
        final adminId = userData['adminId']?.toString();
        if (adminId == null) {
          print('❌ AdminId non trouvé pour le collaborateur');
          throw Exception('ID cible non trouvé');
        }
        targetId = adminId;
        print('👥 Collaborateur détecté, utilisation de l\'ID admin: $targetId');
      }

      print('📝 Création d\'un nouveau contrat pour l\'ID: $targetId');
      print('📝 Chemin de création: users/$targetId/locations/<nouveau-doc>');
      
      // Créer le contrat avec un ID automatique
      final docRef = _firestore
          .collection('users')
          .doc(targetId)
          .collection('locations')
          .doc();
      
      // Ajouter l'ID du document aux données
      final updatedData = Map<String, dynamic>.from(data);
      updatedData['id'] = docRef.id;
      
      // Enregistrer les données
      await docRef.set(updatedData);
      
      print('✅ Contrat créé avec succès, ID: ${docRef.id}');
      return docRef.id;
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
      // Récupérer les informations sur l'utilisateur pour savoir s'il est collaborateur
      final userDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get(const GetOptions(source: Source.server));

      if (!userDoc.exists || userDoc.data() == null) {
        print('⚠️ Utilisateur non trouvé');
        print('👀 Traitement comme administrateur par défaut pour la suppression');
        
        // Si les données utilisateur ne sont pas trouvées, on utilise l'ID de l'utilisateur connecté
        String targetId = user.uid;
        
        print('📝 Suppression du contrat: $contratId pour l\'ID par défaut: $targetId');
        print('📝 Chemin de suppression: users/$targetId/locations/$contratId');
        
        // Supprimer le contrat avec l'ID de l'utilisateur par défaut
        await _firestore
            .collection('users')
            .doc(targetId)
            .collection('locations')
            .doc(contratId)
            .delete();
            
        print('✅ Contrat supprimé avec succès (mode par défaut)');
        return; // Sortir de la fonction après la suppression réussie
      }

      final userData = userDoc.data()!;
      String targetId = user.uid;
      final bool isCollaborateur = userData['role']?.toString() == 'collaborateur';
      
      if (isCollaborateur) {
        final adminId = userData['adminId']?.toString();
        if (adminId == null) {
          print('❌ AdminId non trouvé pour le collaborateur');
          throw Exception('ID cible non trouvé');
        }
        targetId = adminId;
        print('👥 Collaborateur détecté, utilisation de l\'ID admin: $targetId');
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

      // Récupérer les informations sur l'utilisateur pour savoir s'il est collaborateur
      final userDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get(const GetOptions(source: Source.server));

      if (!userDoc.exists || userDoc.data() == null) {
        print('⚠️ Utilisateur non trouvé');
        return {};
      }

      final userData = userDoc.data()!;
      print('✅ Données utilisateur: $userData');
      
      // Vérifier si c'est un collaborateur
      final role = userData['role']?.toString();
      final bool isCollaborateur = role == 'collaborateur';
      print('👥 Role collaborateur: $isCollaborateur');

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

      print('📝 Admin ID final: $adminId');
      
      return {
        'isCollaborateur': isCollaborateur,
        'adminId': adminId,
        'userId': user.uid,
        'role': userData['role'],
        'prenom': userData['prenom'],
        'nomEntreprise': userData['nomEntreprise'],
        'userData': userData
      };
    } catch (e) {
      print('❌ Erreur lors de la récupération des données: $e');
      return {};
    }
  }
}
