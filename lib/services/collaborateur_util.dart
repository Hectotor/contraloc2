import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ContraLoc/USERS/Subscription/revenue_cat_service.dart';

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
      // Récupérer l'ID de l'utilisateur actuel
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
      print('❌ Erreur lors de la vérification du statut collaborateur: $e');      // En cas d'erreur, supposer que l'utilisateur n'est pas un collaborateur
      // mais renvoyer quand même son ID pour permettre l'accès à ses propres données
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
    try {
      print('🔄 Forçage de la récupération des données depuis Firestore');
      
      // Récupérer l'ID de l'utilisateur actuel
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('❌ Aucun utilisateur connecté');
        return {};
      }

      // Récupérer les données depuis la sous-collection authentification
      final authDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('authentification')
          .doc(user.uid)
          .get(GetOptions(source: Source.server));

      if (!authDoc.exists) {
        print('❌ Document authentification non trouvé');
        return {};
      }

      print('✅ Données authentification récupérées depuis Firestore');
      return authDoc.data() ?? {};
    } catch (e) {
      print('❌ Erreur lors de la récupération des données: $e');
      return {};
    }
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
      throw Exception('Utilisateur non connecté');
    }

    // Récupérer les données de l'utilisateur
    final userData = await getUserData();
    final userRole = userData['role'];
    final userAdminId = userData['adminId'];
    
    print('flutter: 🔍 Récupération du document');
    print('flutter: 📝 Rôle: $userRole, AdminId: $userAdminId');
    print('flutter: 📊 Données utilisateur: $userData');
    
    String finalAdminId = userRole == 'collaborateur' && userAdminId != null 
        ? userAdminId 
        : user.uid;

    print('flutter: 🔄 Utilisation de l\'ID: $finalAdminId pour la requête');
    print('flutter: 📁 Chemin de la requête: $collection/$finalAdminId/${subCollection ?? ''}/${subDocId ?? ''}');

    if (useAdminId) {
      print('flutter: 🔍 Récupération avec ID admin');
      return await _firestore.collection(collection)
          .doc(finalAdminId)
          .collection(subCollection ?? '')
          .doc(subDocId ?? '')
          .get();
    }

    print('flutter: 🔍 Récupération avec ID document');
    return await _firestore.collection(collection)
        .doc(docId)
        .collection(subCollection ?? '')
        .doc(subDocId ?? '')
        .get();
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
      throw Exception('Utilisateur non connecté');
    }

    // Récupérer les données de l'utilisateur
    final userData = await getUserData();
    final userRole = userData['role'];
    final userAdminId = userData['adminId'];
    
    print('flutter: 📝 Rôle: $userRole, AdminId: $userAdminId');
    print('flutter: 📊 Données utilisateur: $userData');
    
    String finalAdminId = userRole == 'collaborateur' && userAdminId != null 
        ? userAdminId 
        : user.uid;

    print('flutter: 🔄 Utilisation de l\'ID: $finalAdminId pour la mise à jour');
    print('flutter: 📁 Chemin de la mise à jour: $collection/$finalAdminId/${subCollection ?? ''}/${subDocId ?? ''}');

    try {
      if (useAdminId) {
        print('flutter: 🔍 Mise à jour avec ID admin');
        await _firestore.collection(collection)
            .doc(finalAdminId)
            .collection(subCollection ?? '')
            .doc(subDocId ?? '')
            .set(data, SetOptions(merge: true));
      } else {
        print('flutter: 🔍 Mise à jour avec ID document');
        await _firestore.collection(collection)
            .doc(docId)
            .collection(subCollection ?? '')
            .doc(subDocId ?? '')
            .set(data, SetOptions(merge: true));
      }
    } catch (e) {
      print('❌ Erreur lors de la mise à jour du document: $e');
      rethrow;
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
      
      // Récupérer directement depuis Firestore
      final queryServer = await query.get(GetOptions(source: Source.server));
      
      if (!queryServer.docs.isEmpty) {
        print('✅ Collection récupérée depuis Firestore: $collection/$docId/$subCollection');
      } else {
        print('❌ Collection vide dans Firestore: $collection/$docId/$subCollection');
      }
      
      return queryServer;
    } catch (e) {
      print('❌ Erreur lors de la récupération de la collection: $e');
      throw e;
    }
  }

  /// Récupère les données d'abonnement depuis Firestore
  static Future<Map<String, dynamic>> getSubscriptionData(String userId) async {
    try {
      final doc = await FirebaseFirestore.instance
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

  /// Vérifie si l'utilisateur (ou son administrateur) a un abonnement premium
  static Future<bool> isPremiumUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    
    // Récupérer les données de l'utilisateur
    final userData = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get(GetOptions(source: Source.server));

    if (!userData.exists) {
      return false;
    }

    final userDataMap = userData.data();
    
    // Vérifier si c'est un collaborateur
    final isCollaborateur = userDataMap?['role'] == 'collaborateur';
    
    if (isCollaborateur) {
      final adminId = userDataMap?['adminId'];
      if (adminId != null) {
        print('👥 Collaborateur trouvé, vérification admin: $adminId');
        
        // Récupérer les données de l'admin
        final adminData = await FirebaseFirestore.instance
            .collection('users')
            .doc(adminId)
            .get(GetOptions(source: Source.server));

        if (!adminData.exists) {
          return false;
        }
        
        // Vérifier si l'admin a un abonnement premium
        final adminAuthDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(adminId)
            .collection('authentification')
            .doc(adminId)
            .get(GetOptions(source: Source.server));

        if (!adminAuthDoc.exists) {
          print('❌ Admin auth document not found');
          return false;
        }

        final adminAuthData = adminAuthDoc.data();

        
        // Vérifier tous les champs possibles
        final subscriptionId = adminAuthData?['subscriptionId'] ?? 'free';
        final cbSubscription = adminAuthData?['cb_subscription'] ?? 'free';
        final stripePlanType = adminAuthData?['stripePlanType'] ?? 'free';
        
        return subscriptionId.toString().contains('monthly_access') ||
               subscriptionId.toString().contains('yearly_access') ||
               cbSubscription.toString().contains('monthly_access') ||
               cbSubscription.toString().contains('yearly_access') ||
               stripePlanType.toString().contains('monthly_access') ||
               stripePlanType.toString().contains('yearly_access');
      }
    }

    // Si ce n'est pas un collaborateur, vérifier sa propre souscription
    print('👤 Utilisateur standard, vérification de sa propre souscription');
    final authDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('authentification')
        .doc(user.uid)
        .get(GetOptions(source: Source.server));

    if (!authDoc.exists) {
      print('❌ Auth document not found');
      return false;
    }

    final authData = authDoc.data();
    //print('📊 Auth data: $authData');
    
    // Vérifier tous les champs possibles
    final subscriptionId = authData?['subscriptionId'] ?? 'free';
    final cbSubscription = authData?['cb_subscription'] ?? 'free';
    final stripePlanType = authData?['stripePlanType'] ?? 'free';
    
    return subscriptionId.toString().contains('monthly_access') ||
           subscriptionId.toString().contains('yearly_access') ||
           cbSubscription.toString().contains('monthly_access') ||
           cbSubscription.toString().contains('yearly_access') ||
           stripePlanType.toString().contains('monthly_access') ||
           stripePlanType.toString().contains('yearly_access');
  }

  /// Vérifie si l'utilisateur (ou son administrateur) a un abonnement platinum
  static Future<bool> isPlatinumUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    
    // Récupérer les données de l'utilisateur
    final userData = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get(GetOptions(source: Source.server));

    if (!userData.exists) {
      return false;
    }

    final userDataMap = userData.data();
    
    // Vérifier si c'est un collaborateur
    final isCollaborateur = userDataMap?['role'] == 'collaborateur';
    
    if (isCollaborateur) {
      final adminId = userDataMap?['adminId'];
      if (adminId != null) {
        // Récupérer les données de l'admin
        final adminAuthDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(adminId)
            .collection('authentification')
            .doc(adminId)
            .get(GetOptions(source: Source.server));

        if (!adminAuthDoc.exists) {
          return false;
        }

        final adminAuthData = adminAuthDoc.data();
        
        // Vérifier tous les champs possibles pour platinum
        final subscriptionId = adminAuthData?['subscriptionId'] ?? 'free';
        final cbSubscription = adminAuthData?['cb_subscription'] ?? 'free';
        final stripePlanType = adminAuthData?['stripePlanType'] ?? 'free';
        
        return subscriptionId.toString().contains('platinum') ||
               cbSubscription.toString().contains('platinum') ||
               stripePlanType.toString().contains('platinum');
      }
    }

    // Si ce n'est pas un collaborateur, vérifier sa propre souscription
    final authDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('authentification')
        .doc(user.uid)
        .get(GetOptions(source: Source.server));

    if (!authDoc.exists) {
      return false;
    }

    final authData = authDoc.data();
    
    // Vérifier tous les champs possibles pour platinum
    final subscriptionId = authData?['subscriptionId'] ?? 'free';
    final cbSubscription = authData?['cb_subscription'] ?? 'free';
    final stripePlanType = authData?['stripePlanType'] ?? 'free';
    
    return subscriptionId.toString().contains('platinum') ||
           cbSubscription.toString().contains('platinum') ||
           stripePlanType.toString().contains('platinum');
  }

  /// Récupère les contrats de l'administrateur avec un statut spécifique
  /// Cette méthode est utilisée par les collaborateurs pour accéder aux contrats de leur admin
  static Stream<QuerySnapshot> getAdminContrats(String adminId, String status) {
    return _firestore
        .collection('users')
        .doc(adminId)
        .collection('contrats')
        .where('status', isEqualTo: status)
        .snapshots();
  }

  /// Vérifie si un collaborateur a une permission spécifique
  /// Paramètres:
  /// - permissionType: 'lecture', 'ecriture', ou 'suppression'
  static Future<bool> checkCollaborateurPermission(String permissionType) async {
    try {
      print("🔍 Vérification de la permission '$permissionType'");
      
      // Utiliser la fonction avec retentative pour vérifier le statut
      final status = await _executeWithRetry(
        operation: () => checkCollaborateurStatus(),
      );
      
      // Si l'utilisateur n'est pas un collaborateur, on retourne true (admin a toutes les permissions)
      if (status['isCollaborateur'] != true) {
        print("👑 Utilisateur admin: toutes les permissions accordées");
        return true;
      }
      
      final userId = status['userId'];
      final adminId = status['adminId'];
      
      print("👤 Vérification des permissions pour le collaborateur: $userId");
      print("👥 Admin associé: $adminId");
      
      if (userId == null || adminId == null) {
        print("❌ Identifiants manquants pour la vérification des permissions");
        return false;
      }
      
      // Récupérer les données du collaborateur depuis son propre document user avec retentative
      // Cette approche respecte les règles de sécurité Firestore
      print("📄 Tentative de récupération des permissions depuis le document utilisateur");
      final userDoc = await _executeWithRetry(
        operation: () => _firestore.collection('users').doc(userId).get(),
      );
      
      // Vérifier si le document contient des permissions
      final permissions = userDoc.data()?['permissions'];
      if (permissions == null) {
        print("❌ Permissions non définies dans le document utilisateur");
        
        // Essayer de récupérer depuis la collection authentification si on a les droits
        try {
          print("📄 Tentative de récupération des permissions depuis la collection authentification");
          print("📄 Chemin: /users/$adminId/authentification/$userId");
          
          final collaborateurDoc = await _executeWithRetry(
            operation: () => _firestore
                .collection('users')
                .doc(adminId)
                .collection('authentification')
                .doc(userId)
                .get(),
          );
          
          if (collaborateurDoc.exists) {
            print("✅ Document collaborateur trouvé dans la collection authentification");
            final collabPermissions = collaborateurDoc.data()?['permissions'];
            if (collabPermissions != null) {
              final hasPermission = collabPermissions[permissionType] == true;
              print("🔑 Permission '$permissionType': ${hasPermission ? 'OUI' : 'NON'}");
              print("📋 Toutes les permissions: $collabPermissions");
              return hasPermission;
            } else {
              print("❌ Champ 'permissions' non trouvé dans le document collaborateur");
            }
          } else {
            print("❌ Document collaborateur non trouvé dans la collection authentification");
          }
        } catch (e) {
          print("⚠️ Impossible d'accéder aux permissions dans la collection authentification: $e");
        }
        
        return false;
      }
      
      final hasPermission = permissions[permissionType] == true;
      print("🔑 Permission '$permissionType' depuis document utilisateur: ${hasPermission ? 'OUI' : 'NON'}");
      return hasPermission;
    } catch (e) {
      print("❌ Erreur lors de la vérification des permissions: $e");
      return false;
    }
  }

  /// Fonction utilitaire pour exécuter une requête Firestore avec retentative (backoff)
  /// en cas d'erreur temporaire de connectivité
  static Future<T> _executeWithRetry<T>({
    required Future<T> Function() operation,
    int maxRetries = 5,
    Duration initialDelay = const Duration(milliseconds: 500),
  }) async {
    int attempts = 0;
    Duration delay = initialDelay;
    
    while (true) {
      try {
        attempts++;
        return await operation();
      } catch (e) {
        final isUnavailable = e.toString().contains('unavailable') || 
                             e.toString().contains('network error') ||
                             e.toString().contains('timeout');
        
        if (!isUnavailable || attempts >= maxRetries) {
          print("❌ Erreur après $attempts tentatives: $e");
          rethrow; // Relancer l'erreur si ce n'est pas une erreur de connectivité ou si max retries atteint
        }
        
        // Calcul du délai avec backoff exponentiel au lieu de multiplication par 1.5
        int delayMs = initialDelay.inMilliseconds * (1 << (attempts - 1));
        // Ajouter un jitter aléatoire entre 0 et 100ms pour éviter les collisions
        delayMs += (DateTime.now().millisecondsSinceEpoch % 100);
        delay = Duration(milliseconds: delayMs);
        
        print("⚠️ Tentative $attempts/$maxRetries échouée, nouvelle tentative dans ${delay.inMilliseconds}ms: $e");
        await Future.delayed(delay);
      }
    }
  }
  
  /// Efface toutes les données en cache et les préférences locales
  /// Utilisé lors de la déconnexion pour garantir une déconnexion complète
  static Future<void> clearCache() async {
    try {
      print("🧹 Nettoyage du cache et des préférences...");
      
      // 1. Déconnecter RevenueCat et réinitialiser son état
      try {
        // Essayer de déconnecter RevenueCat, mais ne pas bloquer si ça échoue
        await RevenueCatService.logout().timeout(
          const Duration(seconds: 2),
          onTimeout: () {
            print("⚠️ Timeout lors de la déconnexion RevenueCat");
            return;
          },
        );
        // Réinitialiser l'état d'initialisation de RevenueCat
        RevenueCatService.resetInitializationState();
      } catch (e) {
        print("⚠️ Erreur lors de la déconnexion RevenueCat: $e");
        // Réinitialiser quand même l'état d'initialisation
        RevenueCatService.resetInitializationState();
      }
      
      // 2. Effacer les préférences partagées
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      
      // 3. Tenter de nettoyer le cache Firestore de manière sécurisée
      try {
        // Vérifier d'abord que l'utilisateur est toujours authentifié
        // pour éviter les erreurs de permission
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          // L'utilisateur est encore authentifié, on peut essayer de nettoyer Firestore
          try {
            // Désactiver la persistance pour les futures sessions
            await _firestore.terminate();
            await _firestore.clearPersistence().timeout(
              const Duration(seconds: 2),
              onTimeout: () {
                print("⚠️ Timeout lors du nettoyage du cache Firestore, mais ce n'est pas bloquant");
                return;
              },
            );
          } catch (firestoreError) {
            if (firestoreError.toString().contains('permission-denied')) {
              print("⚠️ Erreur de permission lors du nettoyage du cache Firestore - l'utilisateur est peut-être déjà déconnecté");
            } else {
              print("⚠️ Impossible de nettoyer complètement le cache Firestore: $firestoreError");
            }
            // Ne pas bloquer la déconnexion si le nettoyage du cache échoue
          }
        } else {
          // L'utilisateur est déjà déconnecté, on saute le nettoyage de Firestore
          print("👋 Utilisateur déjà déconnecté, nettoyage Firestore ignoré");
        }
      } catch (authError) {
        print("⚠️ Erreur lors de la vérification de l'état d'authentification: $authError");
        // Ne pas bloquer la déconnexion si la vérification échoue
      }
      
      print("✅ Cache et préférences effacés avec succès");
    } catch (e) {
      print("❌ Erreur lors du nettoyage du cache: $e");
      // Ne pas relancer l'erreur pour ne pas bloquer la déconnexion
    }
  }

  /// Nettoie le cache Firestore pour forcer la récupération des données depuis le serveur
  static Future<void> clearFirestoreCache() async {
    try {
      // Nettoyer le cache en désactivant temporairement la persistance
      await FirebaseFirestore.instance.disableNetwork();
      await Future.delayed(const Duration(milliseconds: 500));
      await FirebaseFirestore.instance.enableNetwork();
      
      print('✅ Cache Firestore nettoyé');
    } catch (e) {
      print('❌ Erreur lors du nettoyage du cache Firestore: $e');
    }
  }

  /// Récupère les données d'un utilisateur
  static Future<Map<String, dynamic>> getUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('❌ Aucun utilisateur connecté');
      return {};
    }

    print('flutter: 🔍 Récupération des données utilisateur depuis Firestore (ID: ${user.uid})');
    
    try {
      // Récupérer les données de l'utilisateur
      final userData = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('authentification')
          .doc(user.uid)
          .get(GetOptions(source: Source.server));

      print('flutter: 📄 Document utilisateur trouvé: ${userData.exists}');
      print('flutter: 📊 Type de données: ${userData.data()?.runtimeType}');
      print('flutter: 📊 Données brutes: ${userData.data()}');
      
      if (!userData.exists) {
        print('❌ Document utilisateur non trouvé pour l\'ID: ${user.uid}');
        return {};
      }

      final userDataMap = userData.data() ?? {};
      print('flutter: 📊 Données utilisateur: $userDataMap');
      print('flutter: 📊 Clés disponibles: ${userDataMap.keys}');
      
      final userRole = userDataMap['role'];
      final userAdminId = userDataMap['adminId'];
      
      print('flutter: 📝 Rôle: $userRole, AdminId: $userAdminId');
      
      return userDataMap;
    } catch (e) {
      print('❌ Erreur lors de la récupération des données utilisateur: $e');
      print('flutter: ❌ Stack trace: ${StackTrace.current.toString()}');
      return {};
    }
  }

  /// Vérifie si un utilisateur a le rôle admin
  static Future<bool> isAdmin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get(GetOptions(source: Source.server));
    
    if (!userDoc.exists) return false;
    
    final userData = userDoc.data();
    return userData?['role'] == 'admin';
  }
}
