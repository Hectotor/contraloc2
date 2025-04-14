import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../USERS/contrat_condition.dart';

class AccessCondition {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Récupère les conditions du contrat pour un utilisateur (admin ou collaborateur)
  static Future<Map<String, dynamic>?> getContractConditions() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('❌ Aucun utilisateur connecté');
        return {'texte': ContratModifier.defaultContract};
      }

      final uid = user.uid;
      
      // Récupérer les données d'authentification directement
      print('🔍 Vérification des données authentification pour les conditions');
      final authDocRef = _firestore
          .collection('users')
          .doc(uid)
          .collection('authentification')
          .doc(uid);
          
      final authDoc = await authDocRef.get(GetOptions(source: Source.server));
      
      if (!authDoc.exists) {
        print('🔍 Document auth non trouvé, vérification si collaborateur');
        final userDoc = await _firestore
            .collection('users')
            .doc(uid)
            .get(GetOptions(source: Source.server));
            
        if (!userDoc.exists) {
          print('⚠️ Utilisateur non trouvé');
          return {'texte': ContratModifier.defaultContract};
        }
        
        final userData = userDoc.data();
        if (userData == null) {
          print('⚠️ Données utilisateur null');
          return {'texte': ContratModifier.defaultContract};
        }
        
        // Vérifier si c'est un collaborateur
        if (userData['role'] == 'collaborateur') {
          final adminId = userData['adminId'];
          if (adminId == null) {
            print('❌ AdminId non trouvé pour le collaborateur');
            return {'texte': ContratModifier.defaultContract};
          }
          
          print('👤 Collaborateur détecté, utilisation de l\'ID admin: $adminId');
          
          // Pour un collaborateur, récupérer les conditions de l'admin
          final adminConditionsDoc = await _firestore
              .collection('users')
              .doc(adminId)
              .collection('contrats')
              .doc('userId')
              .get(GetOptions(source: Source.server));
          
          if (!adminConditionsDoc.exists) {
            print('⚠️ Document conditions admin non trouvé, utilisation des conditions par défaut');
            return {'texte': ContratModifier.defaultContract};
          }
          
          final adminConditionsData = adminConditionsDoc.data();
          if (adminConditionsData == null || adminConditionsData['texte'] == null) {
            print('⚠️ Données conditions admin invalides, utilisation des conditions par défaut');
            return {'texte': ContratModifier.defaultContract};
          }
          
          print('✅ Conditions trouvées pour l\'admin');
          return {'texte': adminConditionsData['texte']};
        }
      } else {
        // Document d'authentification trouvé
        final authData = authDoc.data();
        if (authData == null) {
          print('⚠️ Données auth null');
          return {'texte': ContratModifier.defaultContract};
        }
        
        // Vérifier si c'est un collaborateur via les données d'auth
        if (authData['role'] == 'collaborateur') {
          final adminId = authData['adminId'];
          if (adminId == null) {
            print('❌ AdminId non trouvé dans les données d\'authentification');
            return {'texte': ContratModifier.defaultContract};
          }
          
          print('👤 Collaborateur détecté (auth), utilisation de l\'ID admin: $adminId');
          
          // Pour un collaborateur, récupérer les conditions de l'admin
          final adminConditionsDoc = await _firestore
              .collection('users')
              .doc(adminId)
              .collection('contrats')
              .doc('userId')
              .get(GetOptions(source: Source.server));
          
          if (!adminConditionsDoc.exists) {
            print('⚠️ Document conditions admin non trouvé, utilisation des conditions par défaut');
            return {'texte': ContratModifier.defaultContract};
          }
          
          final adminConditionsData = adminConditionsDoc.data();
          if (adminConditionsData == null || adminConditionsData['texte'] == null) {
            print('⚠️ Données conditions admin invalides, utilisation des conditions par défaut');
            return {'texte': ContratModifier.defaultContract};
          }
          
          print('✅ Conditions trouvées pour l\'admin');
          return {'texte': adminConditionsData['texte']};
        }
      }
      
      // Pour un utilisateur normal (non collaborateur)
      final conditionsDoc = await _firestore
          .collection('users')
          .doc(uid)
          .collection('contrats')
          .doc('userId')
          .get(GetOptions(source: Source.server));
      
      if (!conditionsDoc.exists) {
        print('⚠️ Document conditions non trouvé, utilisation des conditions par défaut');
        return {'texte': ContratModifier.defaultContract};
      }
      
      final conditionsData = conditionsDoc.data();
      if (conditionsData == null || conditionsData['texte'] == null) {
        print('⚠️ Données conditions invalides, utilisation des conditions par défaut');
        return {'texte': ContratModifier.defaultContract};
      }
      
      print('✅ Conditions trouvées');
      return {'texte': conditionsData['texte']};
    } catch (e) {
      print('❌ Erreur lors de la récupération des conditions: $e');
      return {'texte': ContratModifier.defaultContract};
    }
  }
  
  /// Met à jour les conditions du contrat pour un utilisateur (admin ou collaborateur)
  static Future<bool> updateContractConditions(Map<String, dynamic> conditions) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('❌ Aucun utilisateur connecté');
        return false;
      }
      
      String targetUserId = user.uid;
      bool isCollaborateur = false;
      
      // Récupérer les données d'authentification directement
      print('🔍 Vérification des données authentification pour la mise à jour');
      final authDocRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('authentification')
          .doc(user.uid);
          
      final authDoc = await authDocRef.get(GetOptions(source: Source.server));
      
      if (!authDoc.exists) {
        print('🔍 Document auth non trouvé, vérification si collaborateur');
        final userDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .get(GetOptions(source: Source.server));
            
        if (!userDoc.exists) {
          print('⚠️ Utilisateur non trouvé');
          return false;
        }
        
        final userData = userDoc.data();
        if (userData == null) {
          print('⚠️ Données utilisateur null');
          return false;
        }
        
        // Vérifier si c'est un collaborateur
        isCollaborateur = userData['role'] == 'collaborateur';
        if (isCollaborateur) {
          final adminId = userData['adminId'];
          if (adminId == null) {
            print('❌ AdminId non trouvé pour le collaborateur');
            return false;
          }
          targetUserId = adminId;
          print('👤 Collaborateur détecté, utilisation de l\'ID admin: $targetUserId');
        }
      } else {
        // Document d'authentification trouvé
        final authData = authDoc.data();
        if (authData == null) {
          print('⚠️ Données auth null');
          return false;
        }
        
        // Vérifier si c'est un collaborateur via les données d'auth
        isCollaborateur = authData['role'] == 'collaborateur';
        if (isCollaborateur) {
          final adminId = authData['adminId'];
          if (adminId == null) {
            print('❌ AdminId non trouvé dans les données d\'authentification');
            return false;
          }
          targetUserId = adminId;
          print('👤 Collaborateur détecté (auth), utilisation de l\'ID admin: $targetUserId');
        }
      }
      
      print('📝 Mise à jour des conditions pour l\'ID: $targetUserId');
      print('📝 Chemin de mise à jour: users/$targetUserId/contrats/userId');
      
      // Mettre à jour les conditions du contrat
      await _firestore
          .collection('users')
          .doc(targetUserId)
          .collection('contrats')
          .doc('userId')
          .set(conditions, SetOptions(merge: true));
      
      print('✅ Conditions mises à jour avec succès');
      return true;
    } catch (e) {
      print('❌ Erreur lors de la mise à jour des conditions: $e');
      return false;
    }
  }
}
