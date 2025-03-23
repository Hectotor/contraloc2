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
      // Utiliser _executeWithRetry pour gérer les erreurs de connectivité
      final userDoc = await _executeWithRetry(
        operation: () async {
          try {
            // Essayer d'abord depuis le cache
            final docCache = await _firestore.collection('users').doc(user.uid).get(GetOptions(source: Source.cache));
            
            if (docCache.exists) {
              print('📋 Statut collaborateur récupéré depuis le cache');
              return docCache;
            }
            
            // Si pas dans le cache, essayer depuis le serveur
            return await _firestore.collection('users').doc(user.uid).get();
          } catch (e) {
            // Si c'est une erreur de cache, essayer directement depuis le serveur
            if (e.toString().contains('Failed to get document from cache')) {
              print('⚠️ Cache non disponible pour le statut collaborateur, tentative depuis le serveur');
              return await _firestore.collection('users').doc(user.uid).get();
            }
            rethrow;
          }
        }
      );
      
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
      final status = await checkCollaborateurStatus();
      final userId = status['userId'];
      final isCollaborateur = status['isCollaborateur'] == true;
      final adminId = status['adminId'];
      
      if (isCollaborateur && adminId != null) {
        // C'est un collaborateur, récupérer les données de l'admin
        print('👥 Utilisateur collaborateur détecté');
        print('👥 Administrateur associé: $adminId');
        
        // Utiliser _executeWithRetry pour gérer les erreurs de connectivité
        try {
          return await _executeWithRetry(
            operation: () async {
              try {
                // Essayer d'abord depuis le cache
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
                
                // Si pas dans le cache, essayer depuis le serveur
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
                
                throw Exception('Données d\'authentification de l\'admin non trouvées');
              } catch (e) {
                // Si c'est une erreur de cache, essayer directement depuis le serveur
                if (e.toString().contains('Failed to get document from cache')) {
                  print('⚠️ Cache non disponible, tentative depuis le serveur');
                  final docServer = await _firestore
                      .collection('users')
                      .doc(adminId)
                      .collection('authentification')
                      .doc(adminId)
                      .get();
                      
                  if (docServer.exists) {
                    return docServer.data() as Map<String, dynamic>;
                  }
                }
                rethrow;
              }
            }
          );
        } catch (e) {
          print('❌ Erreur récupération données admin: $e');
          // Si on n'a pas pu récupérer les données de l'admin, utiliser les données du collaborateur
          final userDoc = await _executeWithRetry(
            operation: () => _firestore.collection('users').doc(userId).get()
          );
          return userDoc.data() as Map<String, dynamic>;
        }
      } else {
        // C'est un administrateur, continuer normalement
        try {
          return await _executeWithRetry(
            operation: () async {
              try {
                // Essayer d'abord depuis le cache
                final docCache = await _firestore
                    .collection('users')
                    .doc(user.uid)
                    .collection('authentification')
                    .doc(user.uid)
                    .get(GetOptions(source: Source.cache));
                
                if (docCache.exists) {
                  print('📋 Données authentification admin récupérées depuis le cache');
                  return docCache.data() as Map<String, dynamic>;
                }
                
                // Si pas dans le cache, essayer depuis le serveur
                final docServer = await _firestore
                    .collection('users')
                    .doc(user.uid)
                    .collection('authentification')
                    .doc(user.uid)
                    .get();
                    
                if (docServer.exists) {
                  print('📋 Données authentification admin récupérées');
                  return docServer.data() as Map<String, dynamic>;
                }
                
                return {};
              } catch (e) {
                // Si c'est une erreur de cache, essayer directement depuis le serveur
                if (e.toString().contains('Failed to get document from cache')) {
                  print('⚠️ Cache non disponible, tentative depuis le serveur');
                  final docServer = await _firestore
                      .collection('users')
                      .doc(user.uid)
                      .collection('authentification')
                      .doc(user.uid)
                      .get();
                      
                  if (docServer.exists) {
                    return docServer.data() as Map<String, dynamic>;
                  }
                }
                rethrow;
              }
            }
          );
        } catch (e) {
          print('❌ Erreur récupération données authentification: $e');
          return {};
        }
      }
    } catch (e) {
      print('❌ Erreur générale récupération données: $e');
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
      
      // Utiliser _executeWithRetry pour gérer les erreurs de connectivité
      return await _executeWithRetry(
        operation: () async {
          try {
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
            // Si c'est une erreur de cache, essayer directement depuis le serveur
            if (e.toString().contains('Failed to get document from cache')) {
              print('⚠️ Cache non disponible, tentative depuis le serveur');
              final docServer = await docRef.get();
              return docServer;
            }
            rethrow;
          }
        },
      );
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
      
      // Utiliser _executeWithRetry pour gérer les erreurs de connectivité
      return await _executeWithRetry(
        operation: () async {
          try {
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
            // Si c'est une erreur de cache, essayer directement depuis le serveur
            if (e.toString().contains('Failed to get documents from cache')) {
              print('⚠️ Cache non disponible, tentative depuis le serveur');
              final queryServer = await query.get();
              return queryServer;
            }
            rethrow;
          }
        },
      );
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

  /// Fonction utilitaire pour exécuter une requête Firestore avec retentative (backoff)
  /// en cas d'erreur temporaire de connectivité
  static Future<T> _executeWithRetry<T>({
    required Future<T> Function() operation,
    int maxRetries = 5,
    Duration initialDelay = const Duration(seconds: 1),
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
        
        print("⚠️ Tentative $attempts échouée, nouvelle tentative dans ${delay.inMilliseconds}ms: $e");
        await Future.delayed(delay);
        delay *= 2; // Backoff exponentiel
      }
    }
  }

  /// Vérifie si un collaborateur a une permission spécifique
  /// Paramètres:
  /// - permissionType: 'lecture', 'ecriture', ou 'suppression'
  static Future<bool> checkCollaborateurPermission(String permissionType) async {
    try {
      // Utiliser la fonction avec retentative pour vérifier le statut
      final status = await _executeWithRetry(
        operation: () => checkCollaborateurStatus(),
      );
      
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
      
      // Récupérer les données du collaborateur depuis son propre document user avec retentative
      // Cette approche respecte les règles de sécurité Firestore
      final userDoc = await _executeWithRetry(
        operation: () => _firestore.collection('users').doc(userId).get(),
      );
      
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
          final collaborateurDoc = await _executeWithRetry(
            operation: () => _firestore
                .collection('users')
                .doc(adminId)
                .collection('collaborateurs')
                .doc(userId)
                .get(),
          );
          
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
