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
      
      // Récupérer les données de l'utilisateur
      final userDocRef = _firestore.collection('users').doc(uid);
      final userDoc = await userDocRef.get(GetOptions(source: Source.server));

      if (!userDoc.exists) {
        print('❌ Document utilisateur non trouvé');
        return {'texte': ContratModifier.defaultContract};
      }

      final userData = userDoc.data();
      if (userData == null) {
        print('❌ Données utilisateur null');
        return {'texte': ContratModifier.defaultContract};
      }

      // Vérifier si c'est un collaborateur
      if (userData['role'] == 'collaborateur') {
        final adminId = userData['adminId'];
        if (adminId == null) {
          print('❌ AdminId non trouvé pour le collaborateur');
          return {'texte': ContratModifier.defaultContract};
        }

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
        if (adminConditionsData == null) {
          print('⚠️ Données conditions admin null, utilisation des conditions par défaut');
          return {'texte': ContratModifier.defaultContract};
        }

        if (adminConditionsData['texte'] == null) {
          print('⚠️ Champ texte non trouvé dans les conditions admin, utilisation des conditions par défaut');
          return {'texte': ContratModifier.defaultContract};
        }

        print('✅ Conditions trouvées pour l\'admin');
        return {'texte': adminConditionsData['texte']};
      }

      // Pour un utilisateur normal
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
      if (conditionsData == null) {
        print('⚠️ Données conditions null, utilisation des conditions par défaut');
        return {'texte': ContratModifier.defaultContract};
      }

      if (conditionsData['texte'] == null) {
        print('⚠️ Champ texte non trouvé dans les conditions, utilisation des conditions par défaut');
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

      // Récupérer les données de l'utilisateur
      final authDataDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('authentification')
          .doc(user.uid)
          .get(GetOptions(source: Source.server));

      if (!authDataDoc.exists) {
        print('❌ Données authentification non trouvées');
        return false;
      }

      final authData = authDataDoc.data();
      final isCollaborateur = authData?['role'] == 'collaborateur';
      String targetUserId = user.uid;

      // Pour un collaborateur, utiliser l'ID de l'admin
      if (isCollaborateur) {
        final adminId = authData?['adminId'];
        if (adminId != null) {
          targetUserId = adminId;
        }
      }

      // Mettre à jour les conditions du contrat
      await _firestore
          .collection('users')
          .doc(targetUserId)
          .collection('contrats')
          .doc('userId')
          .set(conditions, SetOptions(merge: true));

      return true;
    } catch (e) {
      print('❌ Erreur lors de la mise à jour des conditions: $e');
      return false;
    }
  }
}
