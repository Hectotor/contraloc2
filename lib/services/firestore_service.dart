import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Stream<QuerySnapshot> getContrats(String status) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return Stream.empty();

    // Index composite utilisé ici
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('locations')
        .where('status', isEqualTo: 'en_cours')
        .orderBy('dateCreation', descending: true)
        .snapshots();
  }

  static Stream<QuerySnapshot> getContratsRestitues() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return Stream.empty();

    // Index composite utilisé ici
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('locations')
        .where('status', isEqualTo: 'restitue')
        .orderBy('dateRestitution', descending: true)
        .snapshots();
  }

  static Future<QuerySnapshot> getContratsByDate(DateTime date) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) throw Exception("Utilisateur non connecté");

    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    // Index composite utilisé ici
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('locations')
        .where('dateCreation',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('dateCreation',
            isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .get();
  }

  static Future<QuerySnapshot> getAllContrats() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) throw Exception("Utilisateur non connecté");

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('locations')
        .orderBy('dateCreation', descending: true)
        .get();
  }

  static Stream<QuerySnapshot> getReservedContrats(String status) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return Stream.empty();

    // Index composite utilisé ici
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('locations')
        .where('status', isEqualTo: 'réservé')
        .orderBy('dateCreation', descending: true)
        .snapshots();
  }

  static Future<QuerySnapshot> getMonthlyContrats() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) throw Exception("Utilisateur non connecté");

    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);

    // Index composite utilisé ici
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('locations')
        .where('dateCreation',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth),
            isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
        .orderBy('dateCreation', descending: true)
        .get();
  }

  static Future<int> getMonthlyContratsCount() async {
    try {
      final snapshot = await getMonthlyContrats();
      return snapshot.docs.length;
    } catch (e) {
      print('Erreur lors du comptage des contrats mensuels: $e');
      return 0;
    }
  }

  static Future<void> deleteReservedContrat(String contratId) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) throw Exception("Utilisateur non connecté");

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('locations')
        .doc(contratId)
        .delete();
  }

  static Future<void> checkAndDeleteExpiredContracts() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      // Récupérer tous les contrats marqués comme supprimés
      final QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('locations')
          .where('statussupprime', isEqualTo: 'supprimé')
          .get();

      final now = DateTime.now();
      final batch = _firestore.batch();
      bool hasDeletions = false;

      // Vérifier chaque contrat
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        
        // Vérifier si la date de suppression définitive est passée
        if (data['dateSuppressionDefinitive'] != null) {
          final dateSuppressionDefinitive = DateTime.parse(data['dateSuppressionDefinitive']);
          
          if (now.isAfter(dateSuppressionDefinitive)) {
            // Ajouter le document à supprimer au batch
            batch.delete(doc.reference);
            hasDeletions = true;
            
            // Supprimer également les photos associées si nécessaire
            await _deleteContractPhotos(data);
          }
        }
      }

      // Exécuter le batch si des suppressions sont nécessaires
      if (hasDeletions) {
        await batch.commit();
      }

      print('Vérification des contrats expirés terminée. ${hasDeletions ? "Des contrats ont été supprimés définitivement." : "Aucun contrat à supprimer."}');
    } catch (e) {
      print('Erreur lors de la vérification des contrats expirés: $e');
    }
  }

  // Méthode auxiliaire pour supprimer les photos d'un contrat
  static Future<void> _deleteContractPhotos(Map<String, dynamic> contractData) async {
    try {
      final photosToDelete = <String>[];
      
      // Ajouter les photos standard
      if (contractData['photos'] != null) {
        photosToDelete.addAll(List<String>.from(contractData['photos']));
      }

      // Ajouter les photos de retour
      if (contractData['photosRetourUrls'] != null) {
        photosToDelete.addAll(List<String>.from(contractData['photosRetourUrls']));
      }

      // Ajouter les photos de permis
      if (contractData['permisRecto'] != null) {
        photosToDelete.add(contractData['permisRecto']);
      }
      if (contractData['permisVerso'] != null) {
        photosToDelete.add(contractData['permisVerso']);
      }

      // Supprimer chaque photo
      for (final photoUrl in photosToDelete) {
        if (photoUrl.isNotEmpty && photoUrl.startsWith('https://firebasestorage.googleapis.com')) {
          try {
            final ref = FirebaseStorage.instance.refFromURL(photoUrl);
            await ref.delete();
          } catch (e) {
            print('Erreur lors de la suppression de la photo: $e');
          }
        }
      }
    } catch (e) {
      print('Erreur lors de la suppression des photos: $e');
    }
  }
}
