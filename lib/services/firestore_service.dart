import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  static Stream<QuerySnapshot> getContrats(String status) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return Stream.empty();

    return FirebaseFirestore.instance
        .collection('locations')
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'en_cours')
        .orderBy('dateCreation', descending: true)
        .snapshots();
  }

  static Stream<QuerySnapshot> getContratsRestitues() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return Stream.empty();

    return FirebaseFirestore.instance
        .collection('locations')
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'restitue')
        .orderBy('dateRestitution', descending: true)
        .snapshots();
  }

  static Future<QuerySnapshot> getContratsByDate(DateTime date) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      return FirebaseFirestore.instance.collection('locations').limit(1).get();
    }

    final startOfDay =
        Timestamp.fromDate(DateTime(date.year, date.month, date.day));
    final endOfDay = Timestamp.fromDate(
        DateTime(date.year, date.month, date.day, 23, 59, 59));
    return FirebaseFirestore.instance
        .collection('locations')
        .where('userId', isEqualTo: userId)
        .where('dateCreation', isGreaterThanOrEqualTo: startOfDay)
        .where('dateCreation', isLessThanOrEqualTo: endOfDay)
        .get();
  }

  static Future<QuerySnapshot> getAllContrats() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      return FirebaseFirestore.instance.collection('locations').limit(1).get();
    }

    return FirebaseFirestore.instance
        .collection('locations')
        .where('userId', isEqualTo: userId)
        .get();
  }
}
