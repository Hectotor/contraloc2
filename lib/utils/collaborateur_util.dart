import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CollaborateurUtil {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Vérifie si l'utilisateur actuel est un collaborateur
  static Future<bool> isCollaborateur() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data();
      
      return userData != null && userData['isCollaborateur'] == true;
    } catch (e) {
      print('Erreur lors de la vérification du statut de collaborateur: $e');
      return false;
    }
  }

  // Récupère l'ID de l'administrateur pour un collaborateur
  static Future<String?> getAdminId() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data();
      
      if (userData != null && userData['isCollaborateur'] == true) {
        return userData['adminId'] as String?;
      }
      return null;
    } catch (e) {
      print('Erreur lors de la récupération de l\'ID admin: $e');
      return null;
    }
  }

  // Vérifie si le collaborateur a la permission de lecture
  static Future<bool> hasReadPermission() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;
      
      final adminId = await getAdminId();
      if (adminId == null) return false;

      final collaborateurDoc = await _firestore
          .collection('users')
          .doc(adminId)
          .collection('collaborateurs')
          .doc(user.uid)
          .get();
      
      final permissions = collaborateurDoc.data()?['permissions'];
      return permissions != null && permissions['read'] == true;
    } catch (e) {
      print('Erreur lors de la vérification des permissions de lecture: $e');
      return false;
    }
  }

  // Vérifie si le collaborateur a la permission d'écriture
  static Future<bool> hasWritePermission() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;
      
      final adminId = await getAdminId();
      if (adminId == null) return false;

      final collaborateurDoc = await _firestore
          .collection('users')
          .doc(adminId)
          .collection('collaborateurs')
          .doc(user.uid)
          .get();
      
      final permissions = collaborateurDoc.data()?['permissions'];
      return permissions != null && permissions['write'] == true;
    } catch (e) {
      print('Erreur lors de la vérification des permissions d\'écriture: $e');
      return false;
    }
  }

  // Récupère un document à partir de la collection de l'administrateur
  static Future<Map<String, dynamic>?> getDocument(
    String collectionName,
    String docId, {
    bool useAdminId = true,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      String userId = user.uid;
      
      if (useAdminId && await isCollaborateur()) {
        final adminId = await getAdminId();
        if (adminId == null) return null;
        userId = adminId;
      }

      final docSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection(collectionName)
          .doc(docId)
          .get();
      
      return docSnapshot.data();
    } catch (e) {
      print('Erreur lors de la récupération du document: $e');
      return null;
    }
  }

  // Met à jour un document dans la collection de l'administrateur
  static Future<bool> updateDocument(
    String collectionName,
    String docId,
    Map<String, dynamic> data, {
    bool useAdminId = true,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      String userId = user.uid;
      
      if (useAdminId && await isCollaborateur()) {
        final adminId = await getAdminId();
        if (adminId == null) return false;
        
        // Vérifier les permissions d'écriture
        if (!await hasWritePermission()) {
          print('Le collaborateur n\'a pas les permissions d\'écriture nécessaires');
          return false;
        }
        
        userId = adminId;
      }

      await _firestore
          .collection('users')
          .doc(userId)
          .collection(collectionName)
          .doc(docId)
          .update(data);
      
      return true;
    } catch (e) {
      print('Erreur lors de la mise à jour du document: $e');
      return false;
    }
  }
}
