import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AccessCondition {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Récupère les conditions du contrat pour un utilisateur (admin ou collaborateur)
  static Future<Map<String, dynamic>?> getContractConditions() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('❌ Aucun utilisateur connecté');
        return null;
      }

      // Récupérer les données de base de l'utilisateur
      final userData = await _firestore
          .collection('users')
          .doc(user.uid)
          .get(GetOptions(source: Source.server));

      if (!userData.exists) {
        print('❌ Données utilisateur non trouvées');
        return null;
      }

      final userDataMap = userData.data();
      
      // Vérifier si c'est un collaborateur
      final isCollaborateur = userDataMap?['role'] == 'collaborateur';
      String targetId = user.uid;

      if (isCollaborateur) {
        final adminId = userDataMap?['adminId'];
        if (adminId != null) {
          print('👥 Collaborateur trouvé, vérification admin: $adminId');
          targetId = adminId;
        }
      }

      print('🔄 Vérification de l\'accès à la collection contrats pour: $targetId');
      final conditionsDoc = await _firestore
          .collection('users')
          .doc(targetId)
          .collection('contrats')
          .doc('userId')
          .get(GetOptions(source: Source.server));

      print('Document conditions trouvé: ${conditionsDoc.exists}');
      if (conditionsDoc.exists) {
        final data = conditionsDoc.data();
        print('Données du document: $data');
        if (data != null && data['texte'] != null) {
          print('✅ Conditions trouvées');
          return {'texte': data['texte']};
        }
      }

      print('❌ Aucune condition trouvée');
      return null;
    } catch (e) {
      print('❌ Erreur lors de la récupération des conditions: $e');
      return null;
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
