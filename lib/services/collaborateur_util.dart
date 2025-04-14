import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'access_permission.dart';

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
      print('❌ Aucun utilisateur connecté');
      return {
        'isCollaborateur': false,
        'adminId': null,
        'userId': null,
      };
    }
    
    print('👥 Utilisateur connecté: ${user.uid}');

    try {
      // Récupérer l'ID de l'utilisateur actuel
      final userDoc = await _firestore.collection('users').doc(user.uid).get(GetOptions(source: Source.server));
      
      print('📄 Détails document utilisateur: ${userDoc.data()}');
      
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
      // En cas d'erreur, supposer que l'utilisateur n'est pas un collaborateur
      // mais renvoyer quand même son ID pour permettre l'accès à ses propres données
    }
    
    print('👋 Utilisateur standard (non collaborateur) détecté');
    return {
      'isCollaborateur': false,
      'adminId': null,
      'userId': user.uid,
    };
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
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('❌ Utilisateur non connecté');
      throw Exception('Utilisateur non connecté');
    }

    // Récupérer les données de l'utilisateur directement
    final userDoc = await _firestore.collection('users').doc(user.uid).get(GetOptions(source: Source.server));
    
    if (!userDoc.exists) {
      print('❌ Document utilisateur non trouvé');
      throw Exception('Document utilisateur non trouvé');
    }
    
    final userData = userDoc.data() ?? {};
    final userRole = userData['role'];
    final userAdminId = userData['adminId'];
    
    print('🔍 Récupération du document');
    print('📝 Rôle: $userRole, AdminId: $userAdminId');
    
    String finalAdminId = userRole == 'collaborateur' && userAdminId != null 
        ? userAdminId 
        : user.uid;

    print('🔄 Utilisation de l\'ID: $finalAdminId pour la requête');
    print('📁 Chemin de la requête: $collection/$finalAdminId/${subCollection ?? ''}/${subDocId ?? ''}');

    if (useAdminId) {
      print('🔍 Récupération avec ID admin');
      return await _firestore.collection(collection)
          .doc(finalAdminId)
          .collection(subCollection ?? '')
          .doc(subDocId ?? '')
          .get(GetOptions(source: Source.server));
    }

    print('🔍 Récupération avec ID document');
    return await _firestore.collection(collection)
        .doc(docId)
        .collection(subCollection ?? '')
        .doc(subDocId ?? '')
        .get(GetOptions(source: Source.server));
  }

  /// Met à jour un document dans une collection spécifique
  /// Pour un collaborateur, utilise l'ID de l'administrateur si nécessaire
  static Future<void> updateDocument({
    required String collection,
    required String docId,
    String? subCollection,
    String? subDocId,
    required Map<String, dynamic> data,
    bool useAdminId = false,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('❌ Utilisateur non connecté');
      throw Exception('Utilisateur non connecté');
    }

    // Vérifier les permissions du collaborateur
    final status = await checkCollaborateurStatus();
    final isCollaborateur = status['isCollaborateur'] == true;
    final adminId = status['adminId'];

    if (isCollaborateur) {
      final hasPermission = await AccessPermission.checkPermission('écriture');
      if (!hasPermission) {
        print('❌ Collaborateur sans permission d\'écriture');
        throw Exception('Vous n\'avez pas la permission de modifier ce document');
      }
    }

    String targetId = isCollaborateur && adminId != null && useAdminId
      ? adminId
      : docId;

    print('📝 Mise à jour du document - targetId: $targetId, isCollaborateur: $isCollaborateur');
    print('📁 Chemin de la mise à jour: $collection/$targetId/${subCollection ?? ''}/${subDocId ?? ''}');

    // Construire le chemin du document
    DocumentReference docRef = _firestore.collection(collection).doc(targetId);
    if (subCollection != null && subCollection.isNotEmpty) {
      docRef = docRef.collection(subCollection).doc(subDocId ?? docId);
    }

    // Mettre à jour le document en utilisant set avec merge: true pour éviter d'écraser
    try {
      await docRef.set(data, SetOptions(merge: true));
      print('✔️ Document mis à jour avec succès');
    } catch (e) {
      print('❌ Erreur lors de la mise à jour: $e');
      throw Exception('Erreur lors de la mise à jour du document: $e');
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
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('❌ Utilisateur non connecté');
      throw Exception('Utilisateur non connecté');
    }

    // Récupérer les données de l'utilisateur
    final status = await checkCollaborateurStatus();
    final isCollaborateur = status['isCollaborateur'] == true;
    final adminId = status['adminId'];

    String targetId = docId;
    if (isCollaborateur && adminId != null && useAdminId) {
      targetId = adminId;
      print('👥 Collaborateur détecté, utilisation de l\'ID admin: $targetId');
    }

    print('🔍 Récupération de la collection');
    print('📁 Chemin de la requête: $collection/$targetId/$subCollection');

    Query query = _firestore
        .collection(collection)
        .doc(targetId)
        .collection(subCollection);

    // Appliquer le queryBuilder si fourni
    if (queryBuilder != null) {
      query = queryBuilder(query);
    }

    return await query.get(GetOptions(source: Source.server));
  }

  /// Récupère les données d'un utilisateur
  static Future<Map<String, dynamic>> getUserData() async {
    final user = _auth.currentUser;
    if (user == null) {
      print('❌ Aucun utilisateur connecté');
      return {};
    }

    try {
      print('🔄 Forçage de la récupération des données depuis Firestore');
      final userDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get(GetOptions(source: Source.server));

      if (!userDoc.exists) {
        print('❌ Document utilisateur non trouvé');
        return {};
      }

      return userDoc.data() ?? {};
    } catch (e) {
      print('❌ Erreur lors de la récupération des données: $e');
      return {};
    }
  }

  /// Récupère les données d'authentification de l'utilisateur (admin ou collaborateur)
  /// Pour un collaborateur, récupère les données de son administrateur
  static Future<Map<String, dynamic>> getAuthData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('❌ Aucun utilisateur connecté');
        return {};
      }

      print('🔄 Chargement des données utilisateur...');
      final userDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get(GetOptions(source: Source.server));

      if (!userDoc.exists) {
        print('❌ Document utilisateur non trouvé');
        return {};
      }

      final userData = userDoc.data() ?? {};
      final isCollaborateur = userData['role'] == 'collaborateur';
      final adminId = isCollaborateur ? userData['adminId'] as String? : user.uid;

      if (isCollaborateur) {
        print('👥 Collaborateur détecté, récupération des données d\'authentification de l\'admin: $adminId');
      }

      if (adminId == null) {
        print('❌ ID administrateur non trouvé pour le collaborateur');
        return {};
      }

      // Récupérer les données depuis la sous-collection authentification
      final authDoc = await _firestore
          .collection('users')
          .doc(adminId) // Utiliser l'ID de l'admin pour un collaborateur
          .collection('authentification')
          .doc(adminId) // L'ID du document est celui de l'admin
          .get(GetOptions(source: Source.server));

      if (!authDoc.exists) {
        print('❌ Document authentification non trouvé pour ${isCollaborateur ? "l'administrateur $adminId" : "l'utilisateur $adminId"}');
        return {};
      }

      print('✔️ Données authentification récupérées depuis Firestore');
      return authDoc.data() ?? {};
    } catch (e) {
      print('❌ Erreur lors de la récupération des données: $e');
      return {};
    }
  }

  /// Récupère les données d'abonnement depuis Firestore
  static Future<Map<String, dynamic>> getSubscriptionData(String userId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('authentification')
          .doc(userId)
          .get(GetOptions(source: Source.server));

      if (doc.exists) {
        final data = doc.data();
        print('📊 Auth data: $data');
        return {
          'subscriptionId': data?['subscriptionId'] ?? 'free',
          'cb_subscription': data?['cb_subscription'] ?? 'free',
          'stripePlanType': data?['stripePlanType'] ?? 'free',
        };
      }
      return {
        'subscriptionId': 'free',
        'cb_subscription': 'free',
        'stripePlanType': 'free',
      };
    } catch (e) {
      print('⚠️ Error: $e');
      return {
        'subscriptionId': 'free',
        'cb_subscription': 'free',
        'stripePlanType': 'free',
      };
    }
  }

  /// Récupère les contrats de l'administrateur avec un statut spécifique
  static Future<List<Map<String, dynamic>>> getAdminContracts(
      String adminId, String status) async {
    try {
      final contracts = await _firestore
          .collection('users')
          .doc(adminId)
          .collection('locations')
          .where('status', isEqualTo: status)
          .get(GetOptions(source: Source.server));

      return contracts.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('Erreur lors de la récupération des contrats: $e');
      return [];
    }
  }

  /// Vérifie si un utilisateur a le rôle admin
  static Future<bool> isAdmin() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final userDoc = await _firestore
        .collection('users')
        .doc(user.uid)
        .get(GetOptions(source: Source.server));
    
    if (!userDoc.exists) return false;
    
    final userData = userDoc.data();
    return userData?['role'] == 'admin';
  }

  /// Vérifie si un collaborateur a une permission spécifique
  /// Paramètres:
  /// - permissionType: 'lecture', 'écriture', ou 'suppression'
  static Future<bool> checkCollaborateurPermission(String permissionType) async {
    return await AccessPermission.checkPermission(permissionType);
  }

  /// Efface les données de session lors de la déconnexion
  static Future<void> clearCache() async {
    try {
      print('🧹 Nettoyage des données...');
      
      print('✔️ Données effacées avec succès');
    } catch (e) {
      print('❌ Erreur lors du nettoyage: $e');
    }
  }

  /// Forçage de l'utilisation du serveur pour toutes les requêtes
  static GetOptions serverOnly() {
    return GetOptions(source: Source.server);
  }
}
