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
        return false;
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
      
      // ESSAI DIRECT: Enregistrement direct dans Firestore
      try {
        await _firestore.doc(path).set(data, SetOptions(merge: true));
      } catch (error1) {
        // ESSAI ALTERNATIF: Utiliser la collection directement
        try {
          String collectionPath = path.substring(0, path.lastIndexOf('/'));
          String docId = path.substring(path.lastIndexOf('/') + 1);
          
          await _firestore.collection(collectionPath).doc(docId).set(data);
        } catch (error2) {
          // ESSAI DE SECOURS: Création manuelle de la collection si nécessaire
          try {
            // Construire le chemin complet
            List<String> pathSegments = path.split('/');
            String currentPath = '';
            
            // Parcourir les segments du chemin pour s'assurer que chaque niveau existe
            for (int i = 0; i < pathSegments.length; i += 2) {
              if (i + 1 < pathSegments.length) {
                currentPath += '${pathSegments[i]}/';
                String collectionPath = currentPath.substring(0, currentPath.length - 1);
                String docId = pathSegments[i + 1];
                currentPath += '$docId/';
                
                // Vérifier si le document existe
                DocumentSnapshot docSnapshot = await _firestore.doc('$collectionPath/$docId').get();
                if (!docSnapshot.exists && i + 2 < pathSegments.length) {
                  // Créer un document vide si nécessaire pour la hiérarchie
                  await _firestore.doc('$collectionPath/$docId').set({});
                }
              }
            }
            
            // Finalement, enregistrer les données dans le document final
            await _firestore.doc(path).set(data);
          } catch (error3) {
            throw error3;
          }
        }
      }
      
      // Vérification post-enregistrement
      try {
        final docSnapshot = await _firestore.doc(path).get();
        if (!docSnapshot.exists) {
          // Vérification supplémentaire: lister tous les documents de la collection
          String collectionPath = path.substring(0, path.lastIndexOf('/'));
          await _firestore.collection(collectionPath).get();
        }
      } catch (verifyError) {
        // Ignorer les erreurs de vérification
      }
      
      return true;
    } catch (e) {
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
        return docSnapshot.data() as Map<String, dynamic>;
      } else {
        return null;
      }
    } catch (e) {
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
      
      return results;
    } catch (e) {
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
        return false;
      }

      // Vérifier les permissions de suppression pour les collaborateurs
      if (isCollaborateur) {
        // Vérifier si le collaborateur a des permissions d'écriture (suffisant pour la suppression)
        final hasPermission = await CollaborateurUtil.checkCollaborateurPermission('ecriture');
        if (!hasPermission) {
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
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Récupère les informations détaillées d'un véhicule
  /// 
  /// [immatriculation] - L'immatriculation du véhicule
  /// 
  /// Retourne un Map contenant les informations du véhicule
  static Future<Map<String, dynamic>> getVehiculeInfo({
    required String immatriculation,
  }) async {
    try {
      // Vérifier le statut du collaborateur
      final statusInfo = await CollaborateurUtil.checkCollaborateurStatus();
      final bool isCollaborateur = statusInfo['isCollaborateur'] ?? false;
      final String? adminId = statusInfo['adminId'];
      final String userId = statusInfo['userId'] ?? _auth.currentUser?.uid ?? '';

      if (userId.isEmpty || immatriculation.isEmpty) {
        return {};
      }

      // Déterminer l'ID à utiliser (admin ou utilisateur)
      final String targetId = isCollaborateur && adminId != null && adminId.isNotEmpty 
          ? adminId 
          : userId;

      // Récupérer le document en utilisant l'immatriculation
      final querySnapshot = await _firestore
          .collection('users')
          .doc(targetId)
          .collection('vehicules')
          .where('immatriculation', isEqualTo: immatriculation)
          .get();
      
      if (querySnapshot.docs.isNotEmpty) {
        final vehiculeData = querySnapshot.docs.first.data();
        
        // Extraire les informations pertinentes
        final Map<String, dynamic> vehiculeInfo = {
          'marque': vehiculeData['marque'] ?? '',
          'modele': vehiculeData['modele'] ?? '',
          'immatriculation': vehiculeData['immatriculation'] ?? '',
          'photoVehiculeUrl': vehiculeData['photoVehiculeUrl'] ?? '',
        };
        
        return vehiculeInfo;
      } else {
        return {};
      }
    } catch (e) {
      return {};
    }
  }

  /// Calcule le montant total à partir des frais supplémentaires
  /// 
  /// [fraisSupplementaires] - Map contenant les différents frais
  /// 
  /// Retourne le montant total
  static double calculerMontantTotal(Map<String, dynamic> fraisSupplementaires) {
    double montantTotal = 0.0;
    
    // Additionner tous les frais
    
    // Ajouter le prix de la location s'il est présent
    montantTotal += fraisSupplementaires['prixLocation'] ?? 0.0;

    montantTotal += fraisSupplementaires['coutKmSupplementaires'] ?? 0.0;
    montantTotal += fraisSupplementaires['fraisNettoyageInterieur'] ?? 0.0;
    montantTotal += fraisSupplementaires['fraisNettoyageExterieur'] ?? 0.0;
    montantTotal += fraisSupplementaires['fraisCarburantManquant'] ?? 0.0;
    montantTotal += fraisSupplementaires['fraisRayuresDommages'] ?? 0.0;
    montantTotal += fraisSupplementaires['caution'] ?? 0.0;
    
    return montantTotal;
  }
}
