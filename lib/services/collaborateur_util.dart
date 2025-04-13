import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ContraLoc/USERS/Subscription/revenue_cat_service.dart';
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

  /// Récupère les contrats de l'administrateur avec un statut spécifique
  static Future<List<Map<String, dynamic>>> getAdminContracts(
      String adminId, String status) async {
    try {
      final contracts = await FirebaseFirestore.instance
          .collection('users')
          .doc(adminId)
          .collection('locations')
          .where('status', isEqualTo: status)
          .get();

      return contracts.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('Erreur lors de la récupération des contrats: $e');
      return [];
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

  /// Vérifie si un collaborateur a une permission spécifique
  /// Paramètres:
  /// - permissionType: 'lecture', 'ecriture', ou 'suppression'
  static Future<bool> checkCollaborateurPermission(String permissionType) async {
    return await AccessPermission.checkPermission(permissionType);
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
      // Récupérer les données de l'utilisateur directement depuis la collection users
      final userData = await FirebaseFirestore.instance
          .collection('users')
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
}
