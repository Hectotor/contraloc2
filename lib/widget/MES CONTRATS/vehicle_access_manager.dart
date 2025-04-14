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
  bool _isDisposed = false; // Nouvel état pour savoir si le manager a été fermé
  
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
          .get(const GetOptions(source: Source.server));
      
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
    // Si le manager a été fermé, retourner un stream vide
    if (_isDisposed) {
      print('🚫 Tentative d\'accès au stream après dispose');
      return Stream.empty();
    }
    
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
            // Récupérer directement depuis le serveur sans utiliser le cache
            final snapshot = await _firestore
                .collection('users')
                .doc(effectiveUserId)
                .collection('vehicules')
                .get(const GetOptions(source: Source.server));
                
            return snapshot;
          } catch (e) {
            print('Récupération initiale échouée, retour d\'un snapshot vide');
            // En cas d'erreur, retourner un snapshot vide
            return FirebaseFirestore.instance.collection('empty').limit(0).get();
          }
        })
      ).handleError((error) {
        // Silence les erreurs de permission dans le stream initial
        print('Gestion silencieuse d\'une erreur de stream initial');
        return FirebaseFirestore.instance.collection('empty').limit(0).get();
      });
    }
    
    final effectiveUserId = _targetUserId ?? _auth.currentUser?.uid;
    if (effectiveUserId == null) {
      print('Aucun utilisateur connecté, retour d\'un stream vide');
      return Stream.empty();
    }
    
    // Récupérer le stream de la collection des véhicules
    final Stream<QuerySnapshot> stream = _firestore
        .collection('users')
        .doc(effectiveUserId)
        .collection('vehicules')
        // Utiliser un snapshotsOptions pour forcer Source.server pour chaque événement du stream
        .snapshots(includeMetadataChanges: true)
        // Filtrer pour ne garder que les événements qui viennent du serveur
        .where((snapshot) => snapshot.metadata.isFromCache == false);
    
    // Transformer le stream pour capturer les erreurs sans les afficher
    return stream.handleError((error) {
      // Ignorer les erreurs de permission sans les afficher
      if (error.toString().contains('permission-denied')) {
        print('🚫 Stream des véhicules interrompu silencieusement');
      }
      // Retourner un stream vide pour remplacer le stream en erreur
      return Stream.empty();
    }, test: (error) {
      // Ne capturer que les erreurs de permission
      return error.toString().contains('permission-denied');
    });
  }
  
  // Méthode pour récupérer un document de véhicule spécifique
  // Utilise le cache en priorité pour réduire les coûts Firebase
  Future<DocumentSnapshot> getVehicleDocument(String vehicleId) async {
    // Si le manager a été fermé, lancer une exception
    if (_isDisposed) {
      print('🚮 Tentative d\'accès au véhicule $vehicleId après dispose');
      throw Exception('Le gestionnaire d\'accès aux véhicules a été fermé');
    }
    
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
      // Récupérer directement depuis le serveur
      final DocumentSnapshot snapshot = await docRef.get(const GetOptions(source: Source.server));
      
      // Mettre à jour le timestamp de dernière mise à jour
      _lastVehicleUpdate[vehicleId] = DateTime.now();
      
      print('🔄 Véhicule $vehicleId récupéré depuis le serveur');
      return snapshot;
    } catch (e) {
      print('❌ Erreur récupération véhicule: $e');
      rethrow;
    }
  }
  
  // Méthode pour forcer la mise à jour d'un véhicule depuis le serveur
  Future<DocumentSnapshot> refreshVehicleFromServer(String vehicleId) async {
    // Si le manager a été fermé, lancer une exception
    if (_isDisposed) {
      print('🚮 Tentative de rafraichissement du véhicule $vehicleId après dispose');
      throw Exception('Le gestionnaire d\'accès aux véhicules a été fermé');
    }
    
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
    // Si le manager a été fermé, lancer une exception
    if (_isDisposed) {
      print('🚮 Tentative d\'accès à l\'immatriculation $immatriculation après dispose');
      throw Exception('Le gestionnaire d\'accès aux véhicules a été fermé');
    }
    
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
      // Récupérer directement depuis le serveur
      final QuerySnapshot snapshot = await query.get(const GetOptions(source: Source.server));
      print('📊 Véhicule avec immatriculation $immatriculation récupéré depuis le serveur');
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
  
  // Méthode pour nettoyer le manager et fermer les streams
  void dispose() {
    print('🚮 Nettoyage du gestionnaire d\'accès aux véhicules');
    _isDisposed = true;
    _isInitialized = false;
    _targetUserId = null;
    _lastVehicleUpdate.clear();
  }
  
  // Méthode pour réinitialiser le manager après un dispose
  Future<void> reset() async {
    _isDisposed = false;
    _isInitialized = false;
    await initialize();
  }
}
