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
      
      // Récupérer d'abord les informations sur l'utilisateur pour savoir s'il est collaborateur
      final userDocRef = _firestore.collection('users').doc(uid);
      final userDoc = await userDocRef.get(GetOptions(source: Source.server));
            
      if (!userDoc.exists || userDoc.data() == null) {
        print('⚠️ Utilisateur non trouvé ou données null');
        return {'texte': ContratModifier.defaultContract};
      }
      
      final userData = userDoc.data()!;
      
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
        
        if (!adminConditionsDoc.exists || adminConditionsDoc.data() == null) {
          print('⚠️ Document conditions admin non trouvé, utilisation des conditions par défaut');
          return {'texte': ContratModifier.defaultContract};
        }
        
        final adminConditionsData = adminConditionsDoc.data()!;
        if (adminConditionsData['texte'] == null) {
          print('⚠️ Données conditions admin invalides, utilisation des conditions par défaut');
          return {'texte': ContratModifier.defaultContract};
        }
        
        print('✅ Conditions trouvées pour l\'admin');
        return {'texte': adminConditionsData['texte']};
      } else {
        // Pour un administrateur, récupérer ses propres conditions
        final conditionsDoc = await _firestore
            .collection('users')
            .doc(uid)
            .collection('contrats')
            .doc('userId')
            .get(GetOptions(source: Source.server));
      
        if (!conditionsDoc.exists || conditionsDoc.data() == null) {
          print('⚠️ Document conditions non trouvé, utilisation des conditions par défaut');
          return {'texte': ContratModifier.defaultContract};
        }
        
        final conditionsData = conditionsDoc.data()!;
        if (conditionsData['texte'] == null) {
          print('⚠️ Données conditions invalides, utilisation des conditions par défaut');
          return {'texte': ContratModifier.defaultContract};
        }
        
        print('✅ Conditions trouvées');
        return {'texte': conditionsData['texte']};
      }
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
      
      // Récupérer d'abord les informations sur l'utilisateur pour savoir s'il est collaborateur
      final userDocRef = _firestore.collection('users').doc(user.uid);
      final userDoc = await userDocRef.get(GetOptions(source: Source.server));
            
      if (!userDoc.exists || userDoc.data() == null) {
        print('⚠️ Utilisateur non trouvé ou données null');
        return false;
      }
      
      final userData = userDoc.data()!;
      String targetUserId = user.uid;
      
      // Vérifier si c'est un collaborateur
      final bool isCollaborateur = userData['role'] == 'collaborateur';
      if (isCollaborateur) {
        final adminId = userData['adminId'];
        if (adminId == null) {
          print('❌ AdminId non trouvé pour le collaborateur');
          return false;
        }
        targetUserId = adminId;
        print('👤 Collaborateur détecté, utilisation de l\'ID admin: $targetUserId');
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
