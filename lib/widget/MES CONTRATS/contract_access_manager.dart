import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ContractAccessManager {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Variable pour stocker l'ID de l'utilisateur dont on doit accéder aux contrats
  // (soit l'ID de l'utilisateur actuel, soit l'ID de l'admin associé)
  String? _targetUserId;
  bool _isInitialized = false;
  
  // Méthode pour initialiser le gestionnaire
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    final user = _auth.currentUser;
    if (user == null) {
      _isInitialized = true;
      return;
    }
    
    try {
      // Vérifier si l'utilisateur est un collaborateur
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      
      if (userDoc.exists && userDoc.data()?['role'] == 'collaborateur') {
        // C'est un collaborateur, récupérer l'ID de l'admin
        print('👥 Collaborateur détecté pour accès contrats');
        
        final adminId = userDoc.data()?['adminId'];
        if (adminId != null) {
          print('👥 Utilisation des contrats de l\'administrateur: $adminId');
          _targetUserId = adminId;
        } else {
          print('⚠️ Collaborateur sans adminId, utilisation de son propre ID');
          _targetUserId = user.uid;
        }
      } else {
        // C'est un administrateur, utiliser son propre ID
        print('👤 Administrateur détecté, utilisation de son propre ID');
        _targetUserId = user.uid;
      }
      
      _isInitialized = true;
    } catch (e) {
      print('❌ Erreur initialisation accès contrats: $e');
      // En cas d'erreur, utiliser l'ID de l'utilisateur actuel par défaut
      _targetUserId = user.uid;
      _isInitialized = true;
    }
  }
  
  // Méthode pour obtenir le stream des contrats en cours
  Stream<QuerySnapshot> getActiveContractsStream() {
    if (!_isInitialized) {
      initialize();
    }
    
    if (_targetUserId == null) {
      // Si pas encore initialisé ou erreur, utiliser l'ID de l'utilisateur actuel
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return Stream.empty();
      
      return _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('locations')
          .where('status', isEqualTo: 'en_cours')
          .orderBy('dateCreation', descending: true)
          .snapshots();
    }
    
    // Utiliser l'ID cible (admin ou utilisateur actuel)
    return _firestore
        .collection('users')
        .doc(_targetUserId)
        .collection('locations')
        .where('status', isEqualTo: 'en_cours')
        .orderBy('dateCreation', descending: true)
        .snapshots();
  }
  
  // Méthode pour obtenir le stream des contrats restitués
  Stream<QuerySnapshot> getReturnedContractsStream() {
    if (!_isInitialized) {
      initialize();
    }
    
    if (_targetUserId == null) {
      // Si pas encore initialisé ou erreur, utiliser l'ID de l'utilisateur actuel
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return Stream.empty();
      
      return _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('locations')
          .where('status', isEqualTo: 'restitue')
          .orderBy('dateRestitution', descending: true)
          .snapshots();
    }
    
    // Utiliser l'ID cible (admin ou utilisateur actuel)
    return _firestore
        .collection('users')
        .doc(_targetUserId)
        .collection('locations')
        .where('status', isEqualTo: 'restitue')
        .orderBy('dateRestitution', descending: true)
        .snapshots();
  }
  
  // Méthode pour récupérer les contrats par date
  Future<QuerySnapshot> getContractsByDate(DateTime date) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
    
    if (_targetUserId == null) {
      // Si pas encore initialisé ou erreur, utiliser l'ID de l'utilisateur actuel
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) throw Exception("Utilisateur non connecté");
      
      return _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('locations')
          .where('dateCreation',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('dateCreation',
              isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .get();
    }
    
    // Utiliser l'ID cible (admin ou utilisateur actuel)
    return _firestore
        .collection('users')
        .doc(_targetUserId)
        .collection('locations')
        .where('dateCreation',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('dateCreation',
            isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .get();
  }
  
  // Méthode pour récupérer l'ID cible (utilisateur actuel ou admin)
  String? getTargetUserId() {
    return _targetUserId ?? _auth.currentUser?.uid;
  }
}
