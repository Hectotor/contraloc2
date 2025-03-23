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
    final status = await checkCollaborateurStatus();
    final userId = status['userId'];
    
    if (userId == null) {
      return {};
    }
    
    // Déterminer l'ID à utiliser pour récupérer les données d'authentification
    final targetId = status['isCollaborateur'] ? status['adminId'] : userId;
    
    if (targetId == null) {
      return {};
    }
    
    try {
      // Essayer d'abord depuis le cache
      final docCache = await _firestore
          .collection('users')
          .doc(targetId)
          .collection('authentification')
          .doc(targetId)
          .get(GetOptions(source: Source.cache));
      
      if (docCache.exists) {
        print('📋 Données authentification récupérées depuis le cache');
        return docCache.data() as Map<String, dynamic>;
      }
      
      // Si pas dans le cache et utilisateur est admin, essayer depuis le serveur
      if (!status['isCollaborateur']) {
        final docServer = await _firestore
            .collection('users')
            .doc(targetId)
            .collection('authentification')
            .doc(targetId)
            .get();
            
        if (docServer.exists) {
          print('🔄 Données authentification récupérées depuis le serveur');
          return docServer.data() as Map<String, dynamic>;
        }
      } else {
        // Pour les collaborateurs sans accès au cache, utiliser des valeurs par défaut
        print('👥 Collaborateur sans accès au cache, utilisation des valeurs par défaut');
      }
    } catch (e) {
      print('❌ Erreur récupération données authentification: $e');
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
}
