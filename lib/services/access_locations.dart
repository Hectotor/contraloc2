import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ContraLoc/services/sync_queue_service.dart';

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

  /// Clôture un contrat en utilisant une transaction pour garantir l'atomicité
  /// et ajoute l'opération à une file d'attente en cas d'échec
  static Future<bool> clotureContract(String contratId, Map<String, dynamic> updateData) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Aucun utilisateur connecté');

    bool success = false;
    
    try {
      // Déterminer l'ID cible (collaborateur ou admin)
      String targetId = user.uid;
      
      try {
        // Récupérer les informations sur l'utilisateur pour savoir s'il est collaborateur
        final userDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .get(const GetOptions(source: Source.server));

        if (userDoc.exists && userDoc.data() != null) {
          final userData = userDoc.data()!;
          final bool isCollaborateur = userData['role']?.toString() == 'collaborateur';
          
          if (isCollaborateur) {
            final adminId = userData['adminId']?.toString();
            if (adminId != null) {
              targetId = adminId;
              print('👥 Collaborateur détecté, utilisation de l\'ID admin: $targetId');
            }
          }
        } else {
          print('⚠️ Utilisateur non trouvé, utilisera ID par défaut: $targetId');
        }
      } catch (e) {
        print('⚠️ Erreur lors de la vérification du statut utilisateur: $e');
        print('⚠️ Utilisation de l\'ID utilisateur par défaut: $targetId');
      }
      
      // Créer une référence au document du contrat
      final docRef = _firestore
          .collection('users')
          .doc(targetId)
          .collection('locations')
          .doc(contratId);
      
      // Log de recherche du contrat spécifique
      print('🔍 Tentative de clôture du contrat: $contratId');
      print('🔍 Recherche du contrat dans: users/$targetId/locations/$contratId');
      
      // Exécuter la transaction
      await _firestore.runTransaction((transaction) async {
        // Vérifier que le contrat existe et récupérer son état actuel
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) {
          throw Exception('Contrat non trouvé: $contratId');
        }
        
        // S'assurer que le contrat n'est pas déjà clôturé
        final data = snapshot.data()!;
        print('📊 État actuel du contrat ${contratId}: status=${data['status']}');
        
        if (data['status'] == 'restitue') {
          print('⚠️ Ce contrat est déjà clôturé: $contratId');
          return; // Ne pas lever d'exception, simplement sortir de la transaction
        }
        
        // S'assurer que le champ 'status' est inclus dans les données de mise à jour
        if (!updateData.containsKey('status')) {
          updateData['status'] = 'restitue';
        }
        
        // Appliquer les modifications dans la transaction
        transaction.update(docRef, updateData);
      });
      
      // Si on arrive ici, la transaction a réussi
      print('✅ Contrat clôturé avec succès: $contratId');
      success = true;
    } catch (e) {
      print('❌ Erreur lors de la clôture du contrat: $e');
      // Ajouter le contrat à la file d'attente pour réessayer plus tard
      await addToSyncQueue(contratId, updateData);
      success = false;
    }
    
    return success;
  }
  
  /// Ajoute une opération à la file d'attente de synchronisation
  static Future<void> addToSyncQueue(String contratId, Map<String, dynamic> updateData) async {
    await SyncQueueService().addToQueue(contratId, updateData);
  }
}
