import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VehicleAccessManager {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Variable pour stocker l'ID de l'utilisateur dont on doit accéder aux véhicules
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
        print('👥 Collaborateur détecté pour accès véhicules');
        
        final adminId = userDoc.data()?['adminId'];
        if (adminId != null) {
          print('👥 Utilisation des véhicules de l\'administrateur: $adminId');
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
      print('❌ Erreur initialisation accès véhicules: $e');
      // En cas d'erreur, utiliser l'ID de l'utilisateur actuel par défaut
      _targetUserId = user.uid;
      _isInitialized = true;
    }
  }
  
  // Méthode pour obtenir le stream des véhicules
  Stream<QuerySnapshot> getVehiclesStream() {
    if (_targetUserId == null) {
      // Si pas encore initialisé ou erreur, utiliser l'ID de l'utilisateur actuel
      final currentUserId = _auth.currentUser?.uid;
      return _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('vehicules')
          .snapshots();
    }
    
    // Utiliser l'ID cible (admin ou utilisateur actuel)
    return _firestore
        .collection('users')
        .doc(_targetUserId)
        .collection('vehicules')
        .snapshots();
  }
  
  // Méthode pour récupérer un document de véhicule spécifique
  Future<DocumentSnapshot> getVehicleDocument(String vehicleId) async {
    // S'assurer que le gestionnaire est initialisé
    if (!_isInitialized) {
      await initialize();
    }
    
    // Utiliser l'ID cible (admin ou utilisateur actuel)
    if (_targetUserId == null) {
      final currentUserId = _auth.currentUser?.uid;
      return _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('vehicules')
          .doc(vehicleId)
          .get();
    }
    
    return _firestore
        .collection('users')
        .doc(_targetUserId)
        .collection('vehicules')
        .doc(vehicleId)
        .get();
  }
  
  // Méthode pour récupérer un véhicule par immatriculation
  Future<QuerySnapshot> getVehicleByImmatriculation(String immatriculation) async {
    // S'assurer que le gestionnaire est initialisé
    if (!_isInitialized) {
      await initialize();
    }
    
    // Utiliser l'ID cible (admin ou utilisateur actuel)
    if (_targetUserId == null) {
      final currentUserId = _auth.currentUser?.uid;
      return _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('vehicules')
          .where('immatriculation', isEqualTo: immatriculation)
          .get();
    }
    
    return _firestore
        .collection('users')
        .doc(_targetUserId)
        .collection('vehicules')
        .where('immatriculation', isEqualTo: immatriculation)
        .get();
  }
  
  // Méthode pour récupérer l'ID cible (utilisateur actuel ou admin)
  String? getTargetUserId() {
    return _targetUserId ?? _auth.currentUser?.uid;
  }
}
