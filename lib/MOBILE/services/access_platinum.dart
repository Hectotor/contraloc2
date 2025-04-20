import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_util.dart';

class AccessPlatinum {
  /// Vérifie si l'utilisateur (ou son administrateur) a un abonnement platinum
  static Future<bool> isPlatinumUser() async {
    try {
      print('🔍 Vérification du statut platinum');
      
      // Utiliser AuthUtil pour obtenir les informations d'authentification
      final authData = await AuthUtil.getAuthData();
      if (authData.isEmpty) {
        print('❌ Aucun utilisateur connecté');
        return false;
      }

      final targetId = authData['adminId'] as String;
      print('📝 ID cible: $targetId');

      try {
        final userDocRef = FirebaseFirestore.instance.collection('users').doc(targetId);
        final userDoc = await userDocRef.get(const GetOptions(source: Source.server));
        
        final userData = userDoc.data();
        if (userData == null) {
          // Essayer d'accéder directement à l'authentification comme admin
          print('📝 Essai d\'accès direct aux données d\'authentification');
          final authDocRef = await AuthUtil.getAuthDocRef(targetId);
          final authDoc = await authDocRef.get(const GetOptions(source: Source.server));
          return _checkPlatinumStatus(authDoc.data() as Map<String, dynamic>?);
        }
        
        // Vérifier si c'est un collaborateur
        if (userData['role'] == 'collaborateur') {
          final adminId = userData['adminId'] as String?;
          if (adminId == null) {
            print('❌ AdminId non trouvé pour le collaborateur');
            return false;
          }
          
          print('👥 Collaborateur détecté - Vérification du statut platinum de l\'admin: $adminId');
          
          // Vérifier l'authentification de l'administrateur
          final adminAuthDocRef = await AuthUtil.getAuthDocRef(adminId);
          final adminAuthDoc = await adminAuthDocRef.get(const GetOptions(source: Source.server));
          return _checkPlatinumStatus(adminAuthDoc.data() as Map<String, dynamic>?);
        } else {
          // C'est un administrateur, vérifier directement son statut platinum
          print('👮‍♂️ Administrateur détecté, vérification directe du statut platinum');
          final authDocRef = await AuthUtil.getAuthDocRef(targetId);
          
          final authDoc = await authDocRef.get(const GetOptions(source: Source.server));
          return _checkPlatinumStatus(authDoc.data() as Map<String, dynamic>?);
        }
      } catch (e) {
        print('❌ Erreur pendant la récupération des données utilisateur: $e');
        return false;
      }
    } catch (e) {
      print('❌ Erreur globale lors de la vérification du statut platinum: $e');
      return false;
    }
  }
  
  /// Vérifie le statut platinum à partir des données d'authentification
  static bool _checkPlatinumStatus(Map<String, dynamic>? authData) {
    if (authData == null) {
      print('❌ Données auth null');
      return false;
    }

    // Vérifier tous les champs possibles pour platinum
    final subscriptionId = authData['subscriptionId'] ?? 'free';
    final cbSubscription = authData['cb_subscription'] ?? 'free';
    final stripePlanType = authData['stripePlanType'] ?? 'free';
    
    print('🔍 Valeurs d\'abonnement trouvées: subscriptionId=$subscriptionId, cbSubscription=$cbSubscription, stripePlanType=$stripePlanType');
    
    bool isPlatinum = false;
    String? reason;
    
    if (subscriptionId.toString().contains('platinum')) {
      isPlatinum = true;
      reason = '📝 Statut platinum trouvé dans subscriptionId: $subscriptionId';
    } else if (cbSubscription.toString().contains('platinum')) {
      isPlatinum = true;
      reason = '📝 Statut platinum trouvé dans cb_subscription: $cbSubscription';
    } else if (stripePlanType.toString().contains('platinum')) {
      isPlatinum = true;
      reason = '📝 Statut platinum trouvé dans stripePlanType: $stripePlanType';
    } else {
      reason = '❌ Aucun statut platinum trouvé';
    }
    
    print(reason);
    print('flutter: _isPlatinumUser défini à: $isPlatinum');
    return isPlatinum;
  }
}
