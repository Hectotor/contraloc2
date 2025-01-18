import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
}
