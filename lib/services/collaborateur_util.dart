import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Utilitaire pour gérer l'accès aux données pour les collaborateurs
class CollaborateurUtil {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Vérifie si l'utilisateur actuel est un collaborateur
  /// Retourne un Map contenant:
  /// - isCollaborateur: true si l'utilisateur est un collaborateur
  /// - adminId: l'ID de l'administrateur si l'utilisateur est un collaborateur
  /// - userId: l'ID de l'utilisateur actuel
  static Future<Map<String, dynamic>> checkCollaborateurStatus() async {
    final user = _auth.currentUser;
    if (user == null) {
      return {
        'isCollaborateur': false,
        'adminId': null,
        'userId': null,
      };
    }

    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      
      if (userDoc.exists && userDoc.data()?['role'] == 'collaborateur') {
        final adminId = userDoc.data()?['adminId'];
        print('👥 Collaborateur détecté, administrateur associé: $adminId');
        
        return {
          'isCollaborateur': true,
          'adminId': adminId,
          'userId': user.uid,
        };
      }
    } catch (e) {
      print('❌ Erreur lors de la vérification du statut collaborateur: $e');
    }
    
    return {
      'isCollaborateur': false,
      'adminId': null,
      'userId': user.uid,
    };
  }

  /// Récupère les données d'authentification de l'utilisateur (admin ou collaborateur)
  /// Pour un collaborateur, récupère les données de son administrateur
  static Future<Map<String, dynamic>> getAuthData() async {
    final user = _auth.currentUser;
    if (user == null) {
      return {};
    }
    
    try {
      print('👤 Chargement des données utilisateur...');
      
      // Note: La vérification RevenueCat est gérée dans info_user.dart

      // Vérifier si l'utilisateur est un collaborateur
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      
      if (userDoc.exists && userDoc.data()?['role'] == 'collaborateur') {
        // C'est un collaborateur, récupérer ses propres données
        print('👥 Utilisateur collaborateur détecté');
        
        // Récupérer l'ID de l'admin pour référence
        final adminId = userDoc.data()?['adminId'];
        if (adminId != null) {
          print('👥 Administrateur associé: $adminId');
          
          // Essayer d'abord depuis le cache
          try {
            final docCache = await _firestore
                .collection('users')
                .doc(adminId)
                .collection('authentification')
                .doc(adminId)
                .get(GetOptions(source: Source.cache));
            
            if (docCache.exists) {
              print('📋 Données authentification admin récupérées depuis le cache');
              return docCache.data() as Map<String, dynamic>;
            }
          } catch (e) {
            print('⚠️ Cache non disponible: $e');
          }
          
          // Si pas dans le cache, essayer depuis le serveur
          try {
            final docServer = await _firestore
                .collection('users')
                .doc(adminId)
                .collection('authentification')
                .doc(adminId)
                .get();
                
            if (docServer.exists) {
              print('🔄 Données authentification admin récupérées depuis le serveur');
              return docServer.data() as Map<String, dynamic>;
            }
          } catch (e) {
            print('❌ Erreur récupération données admin: $e');
          }
        }
        
        // Si on n'a pas pu récupérer les données de l'admin, utiliser les données du collaborateur
        return userDoc.data() as Map<String, dynamic>;
      } else {
        // C'est un administrateur, continuer normalement
        try {
          final userData = await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('authentification')
              .doc(user.uid)
              .get();

          if (userData.exists) {
            print('📋 Données authentification admin récupérées');
            return userData.data() as Map<String, dynamic>;
          }
        } catch (e) {
          print('❌ Erreur récupération données authentification: $e');
        }
      }
    } catch (e) {
      print('❌ Erreur générale récupération données: $e');
    }
    
    return {};
  }
  
  /// Récupère les données d'un document dans une collection spécifique
  /// Pour un collaborateur, utilise l'ID de l'administrateur si nécessaire
  static Future<DocumentSnapshot> getDocument({
    required String collection,
    required String docId,
    String? subCollection,
    String? subDocId,
    bool useAdminId = false,
  }) async {
    final status = await checkCollaborateurStatus();
    final userId = status['userId'];
    
    if (userId == null) {
      throw Exception('Utilisateur non connecté');
    }
    
    // Déterminer l'ID à utiliser
    final targetId = (useAdminId && status['isCollaborateur']) 
        ? status['adminId'] 
        : userId;
    
    if (targetId == null) {
      throw Exception('ID cible non disponible');
    }
    
    try {
      // Construire la référence au document
      DocumentReference docRef = _firestore.collection(collection).doc(docId);
      
      // Ajouter la sous-collection si nécessaire
      if (subCollection != null) {
        docRef = docRef.collection(subCollection).doc(subDocId ?? docId);
      }
      
      // Essayer d'abord depuis le cache
      final docCache = await docRef.get(GetOptions(source: Source.cache));
      
      if (docCache.exists) {
        print('📋 Document récupéré depuis le cache: $collection/$docId${subCollection != null ? "/$subCollection/${subDocId ?? docId}" : ""}');
        return docCache;
      }
      
      // Si pas dans le cache, essayer depuis le serveur
      final docServer = await docRef.get();
      
      if (docServer.exists) {
        print('🔄 Document récupéré depuis le serveur: $collection/$docId${subCollection != null ? "/$subCollection/${subDocId ?? docId}" : ""}');
        return docServer;
      }
      
      print('⚠️ Document non trouvé: $collection/$docId${subCollection != null ? "/$subCollection/${subDocId ?? docId}" : ""}');
      return docServer; // Retourner le document vide
      
    } catch (e) {
      print('❌ Erreur récupération document: $e');
      throw e;
    }
  }
  
  /// Récupère les documents d'une collection spécifique
  /// Pour un collaborateur, utilise l'ID de l'administrateur si nécessaire
  static Future<QuerySnapshot> getCollection({
    required String collection,
    required String docId,
    required String subCollection,
    Query Function(Query)? queryBuilder,
    bool useAdminId = false,
  }) async {
    final status = await checkCollaborateurStatus();
    final userId = status['userId'];
    
    if (userId == null) {
      throw Exception('Utilisateur non connecté');
    }
    
    // Déterminer l'ID à utiliser
    final targetId = (useAdminId && status['isCollaborateur']) 
        ? status['adminId'] 
        : userId;
    
    if (targetId == null) {
      throw Exception('ID cible non disponible');
    }
    
    try {
      // Construire la référence à la collection
      Query query = _firestore
          .collection(collection)
          .doc(docId)
          .collection(subCollection);
      
      // Appliquer le constructeur de requête si fourni
      if (queryBuilder != null) {
        query = queryBuilder(query);
      }
      
      // Essayer d'abord depuis le cache
      final queryCache = await query.get(GetOptions(source: Source.cache));
      
      if (!queryCache.docs.isEmpty) {
        print('📋 Collection récupérée depuis le cache: $collection/$docId/$subCollection');
        return queryCache;
      }
      
      // Si pas dans le cache, essayer depuis le serveur
      final queryServer = await query.get();
      
      print('🔄 Collection récupérée depuis le serveur: $collection/$docId/$subCollection (${queryServer.docs.length} documents)');
      return queryServer;
      
    } catch (e) {
      print('❌ Erreur récupération collection: $e');
      throw e;
    }
  }

  /// Vérifie si l'utilisateur (ou son administrateur) a un abonnement premium
  /// Cette méthode remplace SubscriptionManager.isPremiumUser()
  static Future<bool> isPremiumUser() async {
    final userData = await getAuthData();
    
    if (userData.isEmpty) {
      // Vérifier si c'est un collaborateur sans accès aux données d'authentification
      final status = await checkCollaborateurStatus();
      if (status['isCollaborateur'] == true) {
        print('👥 Collaborateur détecté, accès premium accordé par défaut');
        return true; // Accorder l'accès premium aux collaborateurs par défaut
      }
      return false;
    }
    
    final subscriptionId = userData['subscriptionId'] ?? 'free';
    final cb_subscription = userData['cb_subscription'] ?? 'free';
    
    // L'utilisateur est premium si l'un des deux abonnements est premium
    return subscriptionId == 'premium-monthly_access' ||
        subscriptionId == 'premium-yearly_access' ||
        cb_subscription == 'premium-monthly_access' ||
        cb_subscription == 'premium-yearly_access';
  }

  /// Vérifie si un collaborateur a une permission spécifique
  /// Paramètres:
  /// - permissionType: 'lecture', 'ecriture', ou 'suppression'
  static Future<bool> checkCollaborateurPermission(String permissionType) async {
    try {
      final status = await checkCollaborateurStatus();
      
      // Si l'utilisateur n'est pas un collaborateur, on retourne true (admin a toutes les permissions)
      if (status['isCollaborateur'] != true) {
        return true;
      }
      
      final userId = status['userId'];
      final adminId = status['adminId'];
      
      if (userId == null || adminId == null) {
        print("❌ Identifiants manquants pour la vérification des permissions");
        return false;
      }
      
      // Récupérer les données du collaborateur depuis son propre document user
      // Cette approche respecte les règles de sécurité Firestore
      final userDoc = await _firestore.collection('users').doc(userId).get();
      
      if (!userDoc.exists) {
        print("❌ Document utilisateur non trouvé");
        return false;
      }
      
      // Vérifier si le document contient des permissions
      final permissions = userDoc.data()?['permissions'];
      if (permissions == null) {
        print("❌ Permissions non définies dans le document utilisateur");
        
        // Essayer de récupérer depuis la collection collaborateurs si on a les droits
        try {
          final collaborateurDoc = await _firestore
              .collection('users')
              .doc(adminId)
              .collection('collaborateurs')
              .doc(userId)
              .get();
          
          if (collaborateurDoc.exists) {
            final collabPermissions = collaborateurDoc.data()?['permissions'];
            if (collabPermissions != null) {
              return collabPermissions[permissionType] == true;
            }
          }
        } catch (e) {
          print("⚠️ Impossible d'accéder aux permissions dans la collection collaborateurs: $e");
        }
        
        return false;
      }
      
      return permissions[permissionType] == true;
    } catch (e) {
      print("❌ Erreur lors de la vérification des permissions: $e");
      return false;
    }
  }
}
