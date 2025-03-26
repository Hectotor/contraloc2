import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'collaborateur_util.dart';

/// Utilitaire spécifique pour gérer l'accès à la collection 'chiffre_affaire' pour les collaborateurs
class CollaborateurCA {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Ajoute ou met à jour un document dans la collection 'chiffre_affaire'
  /// 
  /// [contratId] - L'ID du contrat associé au chiffre d'affaire
  /// [data] - Les données à enregistrer
  /// 
  /// Retourne true si l'opération a réussi, false sinon
  static Future<bool> ajouterOuMettreAJourChiffreAffaire({
    required String contratId,
    required Map<String, dynamic> data,
  }) async {
    try {
      // Vérifier le statut du collaborateur
      final statusInfo = await CollaborateurUtil.checkCollaborateurStatus();
      final bool isCollaborateur = statusInfo['isCollaborateur'] ?? false;
      final String? adminId = statusInfo['adminId'];
      final String userId = statusInfo['userId'] ?? _auth.currentUser?.uid ?? '';

      if (userId.isEmpty) {
        print('❌ Utilisateur non authentifié');
        return false;
      }

      // Construire le chemin du document en fonction du statut
      String path;
      if (isCollaborateur && adminId != null && adminId.isNotEmpty) {
        // Pour un collaborateur, utiliser l'ID de l'administrateur
        path = 'users/$adminId/chiffre_affaire/$contratId';
        print('👥 Chemin collaborateur pour chiffre_affaire: $path');
      } else {
        // Pour un administrateur, utiliser son propre ID
        path = 'users/$userId/chiffre_affaire/$contratId';
        print('👤 Chemin administrateur pour chiffre_affaire: $path');
      }

      // Utiliser set avec merge pour éviter les problèmes de permissions
      await _firestore.doc(path).set(data, SetOptions(merge: true));
      print('✅ Document chiffre_affaire mis à jour avec succès: $contratId');
      return true;
    } catch (e) {
      print('❌ Erreur lors de la mise à jour du document chiffre_affaire: $e');
      return false;
    }
  }

  /// Récupère un document de la collection 'chiffre_affaire'
  /// 
  /// [contratId] - L'ID du contrat associé au chiffre d'affaire
  /// 
  /// Retourne le document s'il existe, null sinon
  static Future<Map<String, dynamic>?> getChiffreAffaire({
    required String contratId,
  }) async {
    try {
      // Vérifier le statut du collaborateur
      final statusInfo = await CollaborateurUtil.checkCollaborateurStatus();
      final bool isCollaborateur = statusInfo['isCollaborateur'] ?? false;
      final String? adminId = statusInfo['adminId'];
      final String userId = statusInfo['userId'] ?? _auth.currentUser?.uid ?? '';

      if (userId.isEmpty) {
        print('❌ Utilisateur non authentifié');
        return null;
      }

      // Construire le chemin du document en fonction du statut
      String path;
      if (isCollaborateur && adminId != null && adminId.isNotEmpty) {
        // Pour un collaborateur, utiliser l'ID de l'administrateur
        path = 'users/$adminId/chiffre_affaire/$contratId';
      } else {
        // Pour un administrateur, utiliser son propre ID
        path = 'users/$userId/chiffre_affaire/$contratId';
      }

      // Récupérer le document
      final docSnapshot = await _firestore.doc(path).get();
      
      if (docSnapshot.exists) {
        print('✅ Document chiffre_affaire récupéré avec succès: $contratId');
        return docSnapshot.data() as Map<String, dynamic>;
      } else {
        print('⚠️ Document chiffre_affaire non trouvé: $contratId');
        return null;
      }
    } catch (e) {
      print('❌ Erreur lors de la récupération du document chiffre_affaire: $e');
      return null;
    }
  }

  /// Récupère tous les documents de la collection 'chiffre_affaire'
  /// 
  /// [limit] - Nombre maximum de documents à récupérer (optionnel)
  /// [orderBy] - Champ pour trier les résultats (optionnel)
  /// [descending] - Ordre de tri (true pour descendant, false pour ascendant)
  /// 
  /// Retourne une liste de documents
  static Future<List<Map<String, dynamic>>> getAllChiffreAffaire({
    int? limit,
    String? orderBy,
    bool descending = true,
  }) async {
    try {
      // Vérifier le statut du collaborateur
      final statusInfo = await CollaborateurUtil.checkCollaborateurStatus();
      final bool isCollaborateur = statusInfo['isCollaborateur'] ?? false;
      final String? adminId = statusInfo['adminId'];
      final String userId = statusInfo['userId'] ?? _auth.currentUser?.uid ?? '';

      if (userId.isEmpty) {
        print('❌ Utilisateur non authentifié');
        return [];
      }

      // Construire le chemin de la collection en fonction du statut
      String path;
      if (isCollaborateur && adminId != null && adminId.isNotEmpty) {
        // Pour un collaborateur, utiliser l'ID de l'administrateur
        path = 'users/$adminId/chiffre_affaire';
      } else {
        // Pour un administrateur, utiliser son propre ID
        path = 'users/$userId/chiffre_affaire';
      }

      // Construire la requête
      Query query = _firestore.collection(path);
      
      // Ajouter le tri si spécifié
      if (orderBy != null && orderBy.isNotEmpty) {
        query = query.orderBy(orderBy, descending: descending);
      }
      
      // Ajouter la limite si spécifiée
      if (limit != null && limit > 0) {
        query = query.limit(limit);
      }

      // Exécuter la requête
      final querySnapshot = await query.get();
      
      // Convertir les résultats en liste de Map
      final List<Map<String, dynamic>> results = querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // Ajouter l'ID du document aux données
        return data;
      }).toList();
      
      print('✅ ${results.length} documents chiffre_affaire récupérés');
      return results;
    } catch (e) {
      print('❌ Erreur lors de la récupération des documents chiffre_affaire: $e');
      return [];
    }
  }

  /// Supprime un document de la collection 'chiffre_affaire'
  /// 
  /// [contratId] - L'ID du contrat associé au chiffre d'affaire
  /// 
  /// Retourne true si l'opération a réussi, false sinon
  static Future<bool> supprimerChiffreAffaire({
    required String contratId,
  }) async {
    try {
      // Vérifier le statut du collaborateur
      final statusInfo = await CollaborateurUtil.checkCollaborateurStatus();
      final bool isCollaborateur = statusInfo['isCollaborateur'] ?? false;
      final String? adminId = statusInfo['adminId'];
      final String userId = statusInfo['userId'] ?? _auth.currentUser?.uid ?? '';

      if (userId.isEmpty) {
        print('❌ Utilisateur non authentifié');
        return false;
      }

      // Vérifier les permissions de suppression pour les collaborateurs
      if (isCollaborateur) {
        // Vérifier si le collaborateur a des permissions d'écriture (suffisant pour la suppression)
        final hasPermission = await CollaborateurUtil.checkCollaborateurPermission('ecriture');
        if (!hasPermission) {
          print('❌ Le collaborateur n\'a pas la permission de supprimer des documents');
          return false;
        }
      }

      // Construire le chemin du document en fonction du statut
      String path;
      if (isCollaborateur && adminId != null && adminId.isNotEmpty) {
        // Pour un collaborateur, utiliser l'ID de l'administrateur
        path = 'users/$adminId/chiffre_affaire/$contratId';
      } else {
        // Pour un administrateur, utiliser son propre ID
        path = 'users/$userId/chiffre_affaire/$contratId';
      }

      // Supprimer le document
      await _firestore.doc(path).delete();
      print('✅ Document chiffre_affaire supprimé avec succès: $contratId');
      return true;
    } catch (e) {
      print('❌ Erreur lors de la suppression du document chiffre_affaire: $e');
      return false;
    }
  }

  /// Récupère les informations détaillées d'un véhicule
  /// 
  /// [vehiculeId] - L'ID du véhicule
  /// 
  /// Retourne un Map contenant les informations du véhicule
  static Future<Map<String, dynamic>> getVehiculeInfo({
    required String vehiculeId,
  }) async {
    try {
      // Vérifier le statut du collaborateur
      final statusInfo = await CollaborateurUtil.checkCollaborateurStatus();
      final bool isCollaborateur = statusInfo['isCollaborateur'] ?? false;
      final String? adminId = statusInfo['adminId'];
      final String userId = statusInfo['userId'] ?? _auth.currentUser?.uid ?? '';

      if (userId.isEmpty || vehiculeId.isEmpty) {
        print('❌ Utilisateur non authentifié ou ID véhicule manquant');
        return {};
      }

      // Construire le chemin du document en fonction du statut
      String path;
      if (isCollaborateur && adminId != null && adminId.isNotEmpty) {
        // Pour un collaborateur, utiliser l'ID de l'administrateur
        path = 'users/$adminId/vehicules/$vehiculeId';
      } else {
        // Pour un administrateur, utiliser son propre ID
        path = 'users/$userId/vehicules/$vehiculeId';
      }

      // Récupérer le document
      final docSnapshot = await _firestore.doc(path).get();
      
      if (docSnapshot.exists) {
        final vehiculeData = docSnapshot.data() as Map<String, dynamic>;
        
        // Extraire les informations pertinentes
        final Map<String, dynamic> vehiculeInfo = {
          'marque': vehiculeData['marque'] ?? '',
          'modele': vehiculeData['modele'] ?? '',
          'immatriculation': vehiculeData['immatriculation'] ?? '',
          'photoVehiculeUrl': vehiculeData['photoVehiculeUrl'] ?? '',
        };
        
        print('✅ Informations du véhicule récupérées avec succès: $vehiculeId');
        return vehiculeInfo;
      } else {
        print('⚠️ Véhicule non trouvé: $vehiculeId');
        return {};
      }
    } catch (e) {
      print('❌ Erreur lors de la récupération des informations du véhicule: $e');
      return {};
    }
  }

  /// Calcule le coût total à partir des frais supplémentaires
  /// 
  /// [fraisSupplementaires] - Map contenant les différents frais
  /// 
  /// Retourne le coût total
  static double calculerCoutTotal(Map<String, dynamic> fraisSupplementaires) {
    double coutTotal = 0.0;
    
    // Additionner tous les frais
  
    coutTotal += fraisSupplementaires['coutKmSupplementaires'] ?? 0.0;
    coutTotal += fraisSupplementaires['fraisNettoyageInterieur'] ?? 0.0;
    coutTotal += fraisSupplementaires['fraisNettoyageExterieur'] ?? 0.0;
    coutTotal += fraisSupplementaires['fraisCarburantManquant'] ?? 0.0;
    coutTotal += fraisSupplementaires['fraisRayuresDommages'] ?? 0.0;
    coutTotal += fraisSupplementaires['caution'] ?? 0.0;
    
    return coutTotal;
  }
}
