import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ContraLoc/USERS/Subscription/stripe_service.dart';
import 'package:ContraLoc/USERS/Subscription/revenue_cat_service.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

/// Service pour gérer les abonnements
class SubscriptionService {
  /// Met à jour le statut d'abonnement de l'utilisateur actuel
  /// Cette méthode est appelée au démarrage de l'application
  static Future<void> updateSubscriptionStatus() async {
    try {
      // Obtenir l'utilisateur actuel
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        print('❌ Aucun utilisateur connecté');
        return;
      }

      // Récupérer les données d'abonnement depuis Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('authentification')
          .doc(currentUser.uid)
          .get();

      if (!userDoc.exists) {
        print('❌ Document utilisateur non trouvé');
        return;
      }

      final userData = userDoc.data();
      if (userData == null) {
        print('❌ Données utilisateur nulles');
        return;
      }

      // Vérifier si l'utilisateur a un abonnement Stripe
      final stripeSubscriptionId = userData['stripeSubscriptionId'];
      if (stripeSubscriptionId != null && stripeSubscriptionId.toString().isNotEmpty) {
        // Mettre à jour les données d'abonnement depuis Stripe
        await StripeService.updateFirebaseFromStripe(
          currentUser.uid, 
          stripeSubscriptionId.toString()
        );
        print('✅ Statut d\'abonnement Stripe mis à jour');
      } else {
        print('ℹ️ Aucun abonnement Stripe trouvé');
        
        // Vérifier si l'utilisateur a un abonnement RevenueCat
        try {
          // Récupérer les informations d'abonnement depuis RevenueCat
          final customerInfo = await Purchases.getCustomerInfo();
          
          // Vérifier si l'utilisateur a un abonnement actif sur RevenueCat
          final hasActiveRevenueCatSubscription = 
              RevenueCatService.hasPremiumAccess(customerInfo) || 
              RevenueCatService.hasPlatinumAccess(customerInfo);
          
          if (hasActiveRevenueCatSubscription) {
            // Mettre à jour les données d'abonnement depuis RevenueCat
            await RevenueCatService.updateFirebaseFromRevenueCat(
              currentUser.uid, 
              customerInfo
            );
            print('✅ Statut d\'abonnement RevenueCat mis à jour');
          } else {
            print('ℹ️ Aucun abonnement RevenueCat actif trouvé');
          }
        } catch (e) {
          print('❌ Erreur lors de la vérification RevenueCat: $e');
        }
      }

      print('✅ Statut d\'abonnement mis à jour avec succès');
    } catch (e) {
      print('❌ Erreur lors de la mise à jour du statut d\'abonnement: $e');
    }
  }
}
