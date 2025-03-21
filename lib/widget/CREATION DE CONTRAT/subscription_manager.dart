import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SubscriptionManager {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Variable pour stocker l'ID de l'utilisateur dont on doit vérifier l'abonnement
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
        print('👥 Collaborateur détecté pour vérification abonnement');
        
        final adminId = userDoc.data()?['adminId'];
        if (adminId != null) {
          print('👥 Utilisation de l\'abonnement de l\'administrateur: $adminId');
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
      print('❌ Erreur initialisation vérification abonnement: $e');
      // En cas d'erreur, utiliser l'ID de l'utilisateur actuel par défaut
      _targetUserId = user.uid;
      _isInitialized = true;
    }
  }
  
  // Méthode pour vérifier si l'utilisateur a un abonnement premium
  Future<bool> isPremiumUser() async {
    // S'assurer que le gestionnaire est initialisé
    if (!_isInitialized) {
      await initialize();
    }
    
    // Utiliser l'ID cible (admin ou utilisateur actuel)
    if (_targetUserId == null) {
      return false; // Si pas d'ID, considérer comme non premium par défaut
    }
    
    try {
      final doc = await _firestore
          .collection('users')
          .doc(_targetUserId)
          .collection('authentification')
          .doc(_targetUserId)
          .get();
      
      if (doc.exists) {
        final data = doc.data() ?? {};
        final subscriptionId = data['subscriptionId'] ?? 'free';
        final cb_subscription = data['cb_subscription'] ?? 'free';
        
        // L'utilisateur est premium si l'un des deux abonnements est premium
        return subscriptionId == 'premium-monthly_access' ||
            subscriptionId == 'premium-yearly_access' ||
            cb_subscription == 'premium-monthly_access' ||
            cb_subscription == 'premium-yearly_access';
      }
      
      return false; // Document n'existe pas
    } catch (e) {
      print('❌ Erreur vérification abonnement premium: $e');
      return false; // En cas d'erreur, considérer comme non premium
    }
  }
}
