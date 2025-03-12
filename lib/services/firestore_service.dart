import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Future<String?> getAdminId(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data();
      if (userData != null && userData['role'] == 'collaborateur') {
        print('👥 Utilisateur collaborateur, utilisation de l\'ID admin: ${userData['adminId']}');
        return userData['adminId'];
      }
      print('👤 Utilisateur admin');
      return userId;
    } catch (e) {
      print('❌ Erreur récupération adminId: $e');
      return null;
    }
  }

  static Future<String> getTargetUserId() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User not authenticated");

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final userData = userDoc.data();

    if (userData != null && userData['role'] == 'collaborateur') {
      print('📝 Utilisation du compte admin pour les contrats');
      return userData['adminId'];
    } else {
      print('📝 Utilisation du compte utilisateur pour les contrats');
      return user.uid;
    }
  }

  static Future<DocumentReference> addContract(Map<String, dynamic> contractData) async {
    final targetUserId = await getTargetUserId();
    return _firestore
        .collection('users')
        .doc(targetUserId)
        .collection('locations')
        .add(contractData);
  }

  static Stream<QuerySnapshot> getContrats(String status) async* {
    final targetUserId = await getTargetUserId();
    yield* _firestore
        .collection('users')
        .doc(targetUserId)
        .collection('locations')
        .where('status', isEqualTo: "en_cours")
        .orderBy('dateCreation', descending: true)
        .snapshots();
  }

  static Stream<QuerySnapshot> getContratsRestitues() async* {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      print('❌ Utilisateur non connecté');
      yield* Stream.empty();
      return;
    }

    try {
      final adminId = await getAdminId(userId);
      if (adminId == null) {
        print('❌ AdminId non trouvé');
        yield* Stream.empty();
        return;
      }

      print('📄 Récupération des contrats restitués depuis: /users/$adminId/locations');
      yield* _firestore
          .collection('users')
          .doc(adminId)
          .collection('locations')
          .where('status', isEqualTo: 'restitue')
          .orderBy('dateRestitution', descending: true)
          .snapshots();
    } catch (e) {
      print('❌ Erreur récupération des contrats restitués: $e');
      yield* Stream.empty();
    }
  }

  static Future<QuerySnapshot> getContratsByDate(DateTime date) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) throw Exception("Utilisateur non connecté");

    final adminId = await getAdminId(userId);
    if (adminId == null) throw Exception("AdminId non trouvé");

    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    print('📄 Récupération des contrats par date depuis: /users/$adminId/locations');
    return _firestore
        .collection('users')
        .doc(adminId)
        .collection('locations')
        .where('dateCreation',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('dateCreation',
            isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .get();
  }

  static Future<QuerySnapshot> getAllContrats() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) throw Exception("Utilisateur non connecté");

    final adminId = await getAdminId(userId);
    if (adminId == null) throw Exception("AdminId non trouvé");

    print('📄 Récupération de tous les contrats depuis: /users/$adminId/locations');
    return _firestore
        .collection('users')
        .doc(adminId)
        .collection('locations')
        .orderBy('dateCreation', descending: true)
        .get();
  }

  static Stream<QuerySnapshot> getReservedContrats(String status) async* {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      print('❌ Utilisateur non connecté');
      yield* Stream.empty();
      return;
    }

    try {
      final adminId = await getAdminId(userId);
      if (adminId == null) {
        print('❌ AdminId non trouvé');
        yield* Stream.empty();
        return;
      }

      print('📄 Récupération des contrats réservés depuis: /users/$adminId/locations');
      yield* _firestore
          .collection('users')
          .doc(adminId)
          .collection('locations')
          .where('status', isEqualTo: 'réservé')
          .orderBy('dateCreation', descending: true)
          .snapshots();
    } catch (e) {
      print('❌ Erreur récupération des contrats réservés: $e');
      yield* Stream.empty();
    }
  }

  static Future<QuerySnapshot> getMonthlyContrats() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) throw Exception("Utilisateur non connecté");

    final adminId = await getAdminId(userId);
    if (adminId == null) throw Exception("AdminId non trouvé");

    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);

    print('📄 Récupération des contrats mensuels depuis: /users/$adminId/locations');
    return _firestore
        .collection('users')
        .doc(adminId)
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
      print('❌ Erreur lors du comptage des contrats mensuels: $e');
      return 0;
    }
  }

  static Future<void> deleteReservedContrat(String contratId) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) throw Exception("Utilisateur non connecté");

    final adminId = await getAdminId(userId);
    if (adminId == null) throw Exception("AdminId non trouvé");

    print('🗑️ Suppression du contrat réservé depuis: /users/$adminId/locations/$contratId');
    await _firestore
        .collection('users')
        .doc(adminId)
        .collection('locations')
        .doc(contratId)
        .delete();
  }

  static Future<Map<String, dynamic>?> getVehicleData(String immatriculation) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        print('❌ Utilisateur non connecté');
        return null;
      }

      final adminId = await getAdminId(userId);
      if (adminId == null) {
        print('❌ AdminId non trouvé');
        return null;
      }

      print('🚗 Récupération des données du véhicule: $immatriculation');
      final vehicleDoc = await _firestore
          .collection('users')
          .doc(adminId)
          .collection('vehicules')
          .doc(immatriculation)
          .get();

      if (!vehicleDoc.exists) {
        print('❌ Véhicule non trouvé: $immatriculation');
        return null;
      }

      return vehicleDoc.data();
    } catch (e) {
      print('❌ Erreur récupération données véhicule: $e');
      return null;
    }
  }
}
