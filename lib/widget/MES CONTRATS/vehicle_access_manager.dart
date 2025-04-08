import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VehicleAccessManager {
  static final VehicleAccessManager _instance = VehicleAccessManager._internal();
  
  factory VehicleAccessManager() {
    return _instance;
  }
  
  static VehicleAccessManager get instance => _instance;
  
  VehicleAccessManager._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Variable pour stocker l'ID de l'utilisateur dont on doit accéder aux véhicules
  // (soit l'ID de l'utilisateur actuel, soit l'ID de l'admin associé)
  String? _targetUserId;
  bool _isInitialized = false;
  
  // Map pour stocker les timestamps de dernière mise à jour des véhicules
  final Map<String, DateTime> _lastVehicleUpdate = {};
  
  // Méthode pour initialiser le gestionnaire
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    final user = _auth.currentUser;
    if (user == null) {
      _isInitialized = true;
      return;
    }
    
    try {
      // Récupérer directement depuis le serveur et mettre à jour le cache en même temps
      print('📊 Récupération des données utilisateur directement du serveur et mise à jour du cache...');
      final userDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get(GetOptions(source: Source.serverAndCache));
      
      _processUserDocument(userDoc, user);
      _isInitialized = true;
    } catch (e) {
      print('❌ Erreur initialisation accès véhicules: $e');
      // En cas d'erreur, utiliser l'ID de l'utilisateur actuel par défaut
      _targetUserId = user.uid;
      _isInitialized = true;
    }
  }
  
  // Méthode auxiliaire pour traiter le document utilisateur
  void _processUserDocument(DocumentSnapshot userDoc, User user) {
    if (userDoc.exists && userDoc.data() is Map<String, dynamic> && (userDoc.data() as Map<String, dynamic>)['role'] == 'collaborateur') {
      // C'est un collaborateur, récupérer l'ID de l'admin
      print('👥 Collaborateur détecté pour accès véhicules');
      
      final adminId = (userDoc.data() as Map<String, dynamic>)['adminId'];
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
  }
  
  // Méthode pour obtenir le stream des véhicules
  Stream<QuerySnapshot> getVehiclesStream() {
    if (!_isInitialized) {
      // Si le gestionnaire n'est pas encore initialisé, initialiser de manière synchrone
      // et retourner un stream qui attend l'initialisation
      return Stream.fromFuture(
        Future(() async {
          await initialize();
          
          final effectiveUserId = _targetUserId ?? _auth.currentUser?.uid;
          if (effectiveUserId == null) {
            // Retourner un snapshot vide si aucun utilisateur n'est connecté
            return FirebaseFirestore.instance.collection('empty').limit(0).get();
          }
          
          // Une fois initialisé, récupérer les données
          print('Récupération initiale des véhicules pour $effectiveUserId');
          try {
            final snapshot = await _firestore
                .collection('users')
                .doc(effectiveUserId)
                .collection('vehicules')
                .get(GetOptions(source: Source.cache))
                .timeout(Duration(seconds: 2), onTimeout: () {
                  print('Cache timeout, récupération depuis le serveur');
                  return _firestore
                      .collection('users')
                      .doc(effectiveUserId)
                      .collection('vehicules')
                      .get();
                });
            print('Données initiales récupérées avec succès: ${snapshot.docs.length} véhicules');
            return snapshot;
          } catch (e) {
            print('Erreur lors de la récupération initiale: $e');
            // En cas d'erreur, essayer directement depuis le serveur
            return _firestore
                .collection('users')
                .doc(effectiveUserId)
                .collection('vehicules')
                .get();
          }
        })
      ).asyncExpand((snapshot) {
        // Une fois que nous avons les données initiales, retourner le stream continu
        final effectiveUserId = _targetUserId ?? _auth.currentUser?.uid;
        if (effectiveUserId == null) {
          return Stream.empty();
        }
        
        print('Configuration du stream continu pour $effectiveUserId');
        return _firestore
            .collection('users')
            .doc(effectiveUserId)
            .collection('vehicules')
            .snapshots();
      });
    }
    
    // Si déjà initialisé, utiliser l'ID cible (admin ou utilisateur actuel)
    final effectiveUserId = _targetUserId ?? _auth.currentUser?.uid;
    if (effectiveUserId == null) {
      // Retourner un stream vide si aucun utilisateur n'est connecté
      return Stream.empty();
    }
    
    return _firestore
        .collection('users')
        .doc(effectiveUserId)
        .collection('vehicules')
        .snapshots();
  }
  
  // Méthode pour récupérer un document de véhicule spécifique
  // Utilise le cache en priorité pour réduire les coûts Firebase
  Future<DocumentSnapshot> getVehicleDocument(String vehicleId) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    final String effectiveUserId = _targetUserId ?? _auth.currentUser?.uid ?? '';
    if (effectiveUserId.isEmpty) {
      throw Exception('Aucun utilisateur connecté');
    }
    
    final docRef = _firestore
        .collection('users')
        .doc(effectiveUserId)
        .collection('vehicules')
        .doc(vehicleId);
    
    try {
      // Récupérer directement depuis le serveur et mettre à jour le cache en même temps
      final DocumentSnapshot snapshot = await docRef.get(GetOptions(source: Source.serverAndCache));
      
      // Mettre à jour le timestamp de dernière mise à jour
      _lastVehicleUpdate[vehicleId] = DateTime.now();
      
      print('🔄 Véhicule $vehicleId récupéré depuis le serveur et mise à jour du cache');
      return snapshot;
    } catch (e) {
      print('❌ Erreur récupération véhicule: $e');
      rethrow;
    }
  }
  
  // Méthode pour forcer la mise à jour d'un véhicule depuis le serveur
  Future<DocumentSnapshot> refreshVehicleFromServer(String vehicleId) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    final String effectiveUserId = _targetUserId ?? _auth.currentUser?.uid ?? '';
    if (effectiveUserId.isEmpty) {
      throw Exception('Aucun utilisateur connecté');
    }
    
    final docRef = _firestore
        .collection('users')
        .doc(effectiveUserId)
        .collection('vehicules')
        .doc(vehicleId);
    
    final serverSnapshot = await docRef.get(GetOptions(source: Source.server));
    _lastVehicleUpdate[vehicleId] = DateTime.now();
    
    print('🔄 Véhicule $vehicleId forcé depuis le serveur');
    return serverSnapshot;
  }
  
  // Méthode pour récupérer un véhicule par immatriculation
  Future<QuerySnapshot> getVehicleByImmatriculation(String immatriculation) async {
    // S'assurer que le gestionnaire est initialisé
    if (!_isInitialized) {
      await initialize();
    }
    
    final String effectiveUserId = _targetUserId ?? _auth.currentUser?.uid ?? '';
    if (effectiveUserId.isEmpty) {
      throw Exception('Aucun utilisateur connecté');
    }
    
    final query = _firestore
        .collection('users')
        .doc(effectiveUserId)
        .collection('vehicules')
        .where('immatriculation', isEqualTo: immatriculation);
    
    try {
      // Récupérer directement depuis le serveur et le cache en même temps
      final QuerySnapshot snapshot = await query.get(GetOptions(source: Source.serverAndCache));
      print('📊 Véhicule avec immatriculation $immatriculation récupéré depuis le serveur et mise à jour du cache');
      return snapshot;
    } catch (e) {
      print('❌ Erreur récupération véhicule: $e');
      rethrow;
    }
  }
  
  // Méthode pour récupérer l'ID cible (utilisateur actuel ou admin)
  String? getTargetUserId() {
    return _targetUserId ?? _auth.currentUser?.uid;
  }
}
