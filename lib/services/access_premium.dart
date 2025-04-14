import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AccessPremium {
  /// Vérifie si l'utilisateur (ou son administrateur) a un abonnement premium
  static Future<bool> isPremiumUser() async {
    try {
      print('🔄 Vérification du statut premium');
      
      // Vérifier si l'utilisateur est connecté
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('❌ Aucun utilisateur connecté');
        return false;
      }

      final uid = user.uid;
      print('✅ Utilisateur connecté: $uid');

      // Récupérer d'abord les informations sur l'utilisateur pour savoir s'il est collaborateur
      final userDocRef = FirebaseFirestore.instance.collection('users').doc(uid);
      final userDoc = await userDocRef.get(GetOptions(source: Source.server));
      
      if (!userDoc.exists || userDoc.data() == null) {
        print('❌ Document utilisateur non trouvé');
        return false;
      }
      
      final userData = userDoc.data()!;
      
      // Vérifier si c'est un collaborateur
      if (userData['role'] == 'collaborateur') {
        final adminId = userData['adminId'] as String?;
        if (adminId == null) {
          print('❌ AdminId non trouvé pour le collaborateur');
          return false;
        }
        
        print('👥 Collaborateur détecté - Vérification du statut premium de l\'admin: $adminId');
        
        // Vérifier l'authentification de l'administrateur
        final adminAuthDocRef = FirebaseFirestore.instance
            .collection('users')
            .doc(adminId)
            .collection('authentification')
            .doc(adminId);
        
        // Utiliser Source.server pour éviter les problèmes de cache
        final adminAuthDoc = await adminAuthDocRef.get(GetOptions(source: Source.server));
        
        if (!adminAuthDoc.exists) {
          print('❌ Document auth admin non trouvé');
          return false;
        }
        
        return _checkPremiumStatus(adminAuthDoc.data());
      } else {
        // C'est un administrateur, vérifier directement son statut premium
        final authDocRef = FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('authentification')
            .doc(uid);
        
        final authDoc = await authDocRef.get(GetOptions(source: Source.server));
        
        if (authDoc.exists) {
          return _checkPremiumStatus(authDoc.data());
        }
      }
      
      print('❌ Aucun statut premium trouvé');
      print('flutter: _isPremiumUser défini à: false');
      return false;
    } catch (e) {
      print('❌ Erreur lors de la vérification du statut premium: $e');
      return false;
    }
  }
  
  /// Vérifie le statut premium à partir des données d'authentification
  static bool _checkPremiumStatus(Map<String, dynamic>? authData) {
    if (authData == null) {
      print('❌ Données auth null');
      return false;
    }

    // Vérifier tous les champs possibles pour premium et platinum
    final subscriptionId = authData['subscriptionId'] ?? 'free';
    final cbSubscription = authData['cb_subscription'] ?? 'free';
    final stripePlanType = authData['stripePlanType'] ?? 'free';
    
    print('📊 Valeurs d\'abonnement trouvées: subscriptionId=$subscriptionId, cbSubscription=$cbSubscription, stripePlanType=$stripePlanType');
    
    bool isPremium = false;
    String? reason;
    
    if (subscriptionId.toString().contains('premium') || subscriptionId.toString().contains('platinum')) {
      isPremium = true;
      reason = '✅ Statut premium trouvé dans subscriptionId: $subscriptionId';
    } else if (cbSubscription.toString().contains('premium') || cbSubscription.toString().contains('platinum')) {
      isPremium = true;
      reason = '✅ Statut premium trouvé dans cb_subscription: $cbSubscription';
    } else if (stripePlanType.toString().contains('premium') || stripePlanType.toString().contains('platinum')) {
      isPremium = true;
      reason = '✅ Statut premium trouvé dans stripePlanType: $stripePlanType';
    } else {
      reason = '❌ Aucun statut premium trouvé';
    }
    
    print(reason);
    print('flutter: _isPremiumUser défini à: $isPremium');
    return isPremium;
  }
}
