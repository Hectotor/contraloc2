import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:contraloc/MOBILE/USERS/Subscription/stripe_service.dart';
import 'package:contraloc/MOBILE/USERS/Subscription/stripe_url_launcher.dart';

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
        if (context.mounted) Navigator.of(context).pop(); // Fermer le dialogue de chargement
        throw Exception('Utilisateur non connecté');
      }
      
      // Récupérer le nom de l'entreprise depuis la sous-collection authentification
      final authUserDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('authentification')
        .doc(userId)
        .get();
      
      // Valeur par défaut
      String nomEntreprise = 'Utilisateur ContraLoc';
      
      if (authUserDoc.exists && authUserDoc.data() != null) {
        final userData = authUserDoc.data()!;
        if (userData['nomEntreprise'] != null && userData['nomEntreprise'].toString().isNotEmpty) {
          nomEntreprise = userData['nomEntreprise'];
        }
      }
      
      // Créer un client Stripe
      final customerId = await StripeService.createCustomer(
        user.email ?? '', 
        nomEntreprise, // Passer le nom d'entreprise récupéré depuis Firestore
        userId: userId, // Ajouter l'ID Firebase aux métadonnées
      );
      
      if (customerId == null) {
        if (context.mounted) Navigator.of(context).pop(); // Fermer le dialogue de chargement
        throw Exception('Impossible de créer un client Stripe');
      }

      // URLs de redirection
      final successUrl = 'https://www.contraloc.fr/payment-success/';
      final cancelUrl = 'https://contraloc.fr/';

      // Créer la session de paiement
      final sessionUrl = await StripeService.createSubscriptionCheckoutSession(
        customerId,
        productId,
        successUrl,
        cancelUrl,
      );

      if (sessionUrl == null || sessionUrl.isEmpty) {
        if (context.mounted) Navigator.of(context).pop(); // Fermer le dialogue de chargement
        throw Exception('Impossible de créer la session de paiement');
      }

      // Fermer le dialogue de chargement
      if (context.mounted) Navigator.of(context).pop();

      // Ouvrir l'URL de paiement dans le navigateur en utilisant notre classe spécialisée
      final result = await StripeUrlLauncher.launchStripeCheckout(
        context: context,
        stripeUrl: sessionUrl,
        onSuccess: () {},
        onError: (errorMsg) {
          if (context.mounted) {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('Erreur de paiement'),
                  content: Text('Erreur lors de l\'ouverture de la page de paiement: $errorMsg'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('OK'),
                    ),
                  ],
                );
              },
            );
          }
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
      // Fermer le dialogue de chargement s'il est ouvert
      if (context.mounted) {
        // Vérifier si le dialogue est affiché avant de le fermer
        try {
          Navigator.of(context).pop();
        } catch (dialogError) {}
        
        // Afficher un dialogue d'erreur
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Erreur de paiement'),
              content: Text('Une erreur est survenue lors du processus de paiement: $e'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
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
    required int stripeNumberOfCars,
  }) async {
    try {
      // Utiliser la méthode unifiée dans StripeService
      await StripeService.updateFirebaseFromStripe(userId, subscriptionId);
      
    } catch (e) {
      rethrow;
    }
  }
  
  /// Vérifie si un utilisateur a un abonnement Stripe actif
  static Future<bool> hasActiveStripeSubscription(String userId) async {
    try {
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
      final isActive = userData['isStripeSubscriptionActive'] == true;
      final stripeStatus = userData['stripeStatus'];
      
      // Vérifier à la fois le champ isStripeSubscriptionActive et le statut
      return isActive && (stripeStatus == 'active' || stripeStatus == 'trialing');
    } catch (e) {
      print(' Erreur lors de la vérification de l\'abonnement Stripe: $e');
      return false;
    }
  }
}
