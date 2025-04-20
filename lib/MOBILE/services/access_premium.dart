import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_util.dart';

class AccessPremium {
  /// Vérifie si l'utilisateur (ou son administrateur) a un abonnement premium
  static Future<bool> isPremiumUser() async {
    try {
      print('🔄 Vérification du statut premium');
      
      // Utiliser AuthUtil pour obtenir les informations d'authentification
      final authData = await AuthUtil.getAuthData();
      if (authData.isEmpty) {
        print('❌ Aucun utilisateur connecté');
        return false;
      }

      final targetId = authData['adminId'] as String;
      print('✅ ID cible: $targetId');

      try {
        final userDocRef = FirebaseFirestore.instance.collection('users').doc(targetId);
        final userDoc = await userDocRef.get(const GetOptions(source: Source.server));
        
        final userData = userDoc.data();
        if (userData == null) {
          // Essayer d'accéder directement aux données d'authentification comme admin
          print('👀 Essai d\'accès direct aux données d\'authentification comme administrateur');
          final authDocRef = await AuthUtil.getAuthDocRef(targetId);
          
          final authDoc = await authDocRef.get(const GetOptions(source: Source.server));
          return _checkPremiumStatus(authDoc.data() as Map<String, dynamic>?);
        }
        
        // Vérifier si c'est un collaborateur
        if (userData['role'] == 'collaborateur') {
          final adminId = userData['adminId'] as String?;
          if (adminId == null) {
            print('❌ AdminId non trouvé pour le collaborateur');
            return false;
          }
          
          print('👥 Collaborateur détecté - Vérification du statut premium de l\'admin: $adminId');
          
          // Vérifier l'authentification de l'administrateur
          final adminAuthDocRef = await AuthUtil.getAuthDocRef(adminId);
          
          // Utiliser Source.server pour éviter les problèmes de cache
          final adminAuthDoc = await adminAuthDocRef.get(const GetOptions(source: Source.server));
          return _checkPremiumStatus(adminAuthDoc.data() as Map<String, dynamic>?);
        } else {
          // C'est un administrateur, vérifier directement son statut premium
          print('👴 Administrateur détecté, vérification directe du statut premium');
          final authDocRef = await AuthUtil.getAuthDocRef(targetId);
          
          final authDoc = await authDocRef.get(const GetOptions(source: Source.server));
          return _checkPremiumStatus(authDoc.data() as Map<String, dynamic>?);
        }
      } catch (e) {
        print('❌ Erreur pendant la récupération des données utilisateur: $e');
        return false;
      }
    } catch (e) {
      print('❌ Erreur globale lors de la vérification du statut premium: $e');
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
