import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ContraLoc/USERS/Subscription/stripe_service.dart';
import 'package:ContraLoc/USERS/Subscription/stripe_url_launcher.dart';

/// Classe dédiée à la gestion des paiements Stripe
class StripePaymentHandler {
  /// Effectue un achat avec Stripe
  /// 
  /// [context] : Le contexte de build pour afficher des dialogues
  /// [userId] : L'ID de l'utilisateur actuel
  /// [productId] : L'ID du produit Stripe à acheter
  /// [plan] : Le type de plan (Premium ou Platinum)
  /// [isMonthly] : Indique si l'abonnement est mensuel ou annuel
  static Future<void> purchaseProductWithStripe({
    required BuildContext context,
    required String userId,
    required String productId,
    required String plan,
    required bool isMonthly,
  }) async {
    try {
      print('🔄 Démarrage du processus de paiement Stripe...');
      
      // Afficher un dialogue de chargement
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Dialog(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 20),
                  Text('Préparation du paiement...'),
                ],
              ),
            ),
          );
        },
      );

      // Récupérer les informations de l'utilisateur
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('❌ Utilisateur non connecté');
        Navigator.of(context).pop(); // Fermer le dialogue de chargement
        throw Exception('Utilisateur non connecté');
      }
      
      // Créer un client Stripe
      print('🔄 Récupération du client Stripe...');
      final customerId = await StripeService.createCustomer(
        user.email ?? '', 
        user.displayName ?? 'Utilisateur'
      );
      
      if (customerId == null) {
        print('❌ Impossible de créer un client Stripe');
        Navigator.of(context).pop(); // Fermer le dialogue de chargement
        throw Exception('Impossible de créer un client Stripe');
      }
      
      print('✔️ Client Stripe récupéré: $customerId');

      print('🔄 Création de la session de paiement...');
      // URLs de redirection
      final successUrl = 'https://www.contraloc.fr/payment-success/';
      final cancelUrl = 'https://contraloc.fr/';

      // Créer la session de paiement
      print('🔄 Création de la session de paiement Stripe...');
      final sessionUrl = await StripeService.createSubscriptionCheckoutSession(
        customerId,
        productId,
        successUrl,
        cancelUrl,
      );

      if (sessionUrl == null) {
        print('❌ Session de paiement null');
        Navigator.of(context).pop(); // Fermer le dialogue de chargement
        throw Exception('Impossible de créer la session de paiement');
      }

      // Fermer le dialogue de chargement
      Navigator.of(context).pop();

      print('✔️ URL de paiement obtenue: $sessionUrl');
      // Ouvrir l'URL de paiement dans le navigateur en utilisant notre classe spécialisée
      final result = await StripeUrlLauncher.launchStripeCheckout(
        context: context,
        stripeUrl: sessionUrl,
        onSuccess: () {
          print('✔️ URL Stripe ouverte avec succès');
        },
        onError: (errorMsg) {
          print('❌ Erreur lors de l\'ouverture de l\'URL Stripe: $errorMsg');
          throw Exception(errorMsg);
        },
      );
      
      if (!result) {
        throw Exception('Échec de l\'ouverture du lien de paiement');
      }

      // Comme le paiement se fait dans un navigateur externe, nous ne pouvons pas
      // savoir immédiatement si le paiement a réussi. La mise à jour du statut 
      // de l'abonnement sera gérée par le webhook Stripe.
    } catch (e) {
      print('❌ Erreur lors du paiement par carte bancaire: $e');
      // Fermer le dialogue de chargement s'il est ouvert
      if (context.mounted) {
        Navigator.of(context).pop();
      }
      rethrow;
    }
  }
  
  /// Met à jour Firestore avec les informations d'abonnement Stripe
  /// Cette méthode est maintenant dépréciée, utilisez StripeService.updateFirebaseFromStripe à la place
  static Future<void> updateFirestoreWithStripeSubscription({
    required String userId,
    required String subscriptionId,
    required String status,
    required String planType,
    required int numberOfCars,
  }) async {
    try {
      print('🔄 Redirection vers la méthode unifiée de mise à jour...');
      
      // Utiliser la méthode unifiée dans StripeService
      await StripeService.updateFirebaseFromStripe(userId, subscriptionId);
      
    } catch (e) {
      print('❌ Erreur lors de la mise à jour des données d\'abonnement Stripe: $e');
      rethrow;
    }
  }
  
  /// Vérifie si un utilisateur a un abonnement Stripe actif
  static Future<bool> hasActiveStripeSubscription(String userId) async {
    try {
      // Référence au document utilisateur dans Firestore
      final userDocRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('authentification')
          .doc(userId);
      
      // Récupérer les données de l'utilisateur
      final userDoc = await userDocRef.get();
      
      if (!userDoc.exists) {
        return false;
      }
      
      final userData = userDoc.data();
      if (userData == null) {
        return false;
      }
      
      // Vérifier si l'utilisateur a un abonnement Stripe actif
      final isActive = userData['isSubscriptionActive'] == true;
      final stripeStatus = userData['stripeStatus'];
      
      return isActive && (stripeStatus == 'active' || stripeStatus == 'trialing');
    } catch (e) {
      print('❌ Erreur lors de la vérification de l\'abonnement Stripe: $e');
      return false;
    }
  }
}
