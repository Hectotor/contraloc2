import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VehicleAccessManager {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Variable pour stocker l'ID de l'utilisateur dont on doit accéder aux véhicules
  // (soit l'ID de l'utilisateur actuel, soit l'ID de l'admin associé)
  String? _targetUserId;
  bool _isInitialized = false;
  
  // Map pour stocker les timestamps de dernière mise à jour des véhicules
  final Map<String, DateTime> _lastVehicleUpdate = {};
  // Durée après laquelle on considère que les données du cache sont obsolètes (5 minutes par défaut)
  final Duration _cacheValidityDuration = Duration(minutes: 5);
  
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
  // Utilise le cache en priorité pour réduire les coûts Firebase
  Future<DocumentSnapshot> getVehicleDocument(String vehicleId) async {
    // S'assurer que le gestionnaire est initialisé
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
    
    // Vérifier si nous devons forcer une mise à jour depuis le serveur
    final bool shouldRefreshFromServer = _shouldRefreshVehicleData(vehicleId);
    
    try {
      // D'abord essayer de récupérer depuis le cache
      final DocumentSnapshot docSnapshot = await docRef.get(GetOptions(source: Source.cache));
      
      // Si les données sont dans le cache et ne nécessitent pas de mise à jour, les retourner
      if (docSnapshot.exists && !shouldRefreshFromServer) {
        print('📋 Véhicule $vehicleId récupéré depuis le cache');
        return docSnapshot;
      }
      
      // Si les données ne sont pas dans le cache ou nécessitent une mise à jour, 
      // les récupérer depuis le serveur
      final DocumentSnapshot serverSnapshot = await docRef.get(GetOptions(source: Source.server));
      
      // Mettre à jour le timestamp de dernière mise à jour
      _lastVehicleUpdate[vehicleId] = DateTime.now();
      
      print('🔄 Véhicule $vehicleId mis à jour depuis le serveur');
      return serverSnapshot;
    } catch (e) {
      // En cas d'erreur (ex: hors ligne), essayer de récupérer depuis le cache
      try {
        print('⚠️ Erreur serveur, tentative de récupération depuis le cache: $e');
        return await docRef.get(GetOptions(source: Source.cache));
      } catch (cacheError) {
        print('❌ Erreur cache: $cacheError');
        rethrow;
      }
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
  
  // Méthode privée pour déterminer si les données du véhicule doivent être mises à jour
  bool _shouldRefreshVehicleData(String vehicleId) {
    final lastUpdate = _lastVehicleUpdate[vehicleId];
    if (lastUpdate == null) {
      return true; // Première fois, mise à jour nécessaire
    }
    
    final now = DateTime.now();
    final difference = now.difference(lastUpdate);
    
    // Mettre à jour si les données sont plus anciennes que la durée de validité du cache
    return difference > _cacheValidityDuration;
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
      // D'abord essayer de récupérer depuis le cache
      final QuerySnapshot cacheSnapshot = await query.get(GetOptions(source: Source.cache));
      
      // Si des résultats sont trouvés dans le cache, les retourner
      if (!cacheSnapshot.docs.isEmpty) {
        print('📋 Véhicule avec immatriculation $immatriculation récupéré depuis le cache');
        return cacheSnapshot;
      }
      
      // Sinon, récupérer depuis le serveur
      final QuerySnapshot serverSnapshot = await query.get(GetOptions(source: Source.server));
      print('🔄 Véhicule avec immatriculation $immatriculation récupéré depuis le serveur');
      return serverSnapshot;
    } catch (e) {
      // En cas d'erreur (ex: hors ligne), essayer de récupérer depuis le cache
      try {
        print('⚠️ Erreur serveur, tentative de récupération depuis le cache: $e');
        return await query.get(GetOptions(source: Source.cache));
      } catch (cacheError) {
        print('❌ Erreur cache: $cacheError');
        rethrow;
      }
    }
  }
  
  // Méthode pour récupérer l'ID cible (utilisateur actuel ou admin)
  String? getTargetUserId() {
    return _targetUserId ?? _auth.currentUser?.uid;
  }
}
