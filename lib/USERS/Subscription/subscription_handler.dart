import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ContraLoc/USERS/Subscription/revenue_cat_service.dart';

/// Classe qui gère la logique des abonnements
class SubscriptionHandler {
  /// Gère la logique de souscription en fonction du plan choisi
  static Future<void> handleSubscription({
    required BuildContext context,
    required String plan,
    required bool hasPremiumSubscription,
    required Function(bool) setProcessingState,
    required Future<void> Function(String) onSubscribe,
  }) async {
    setProcessingState(true);
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Utilisateur non connecté');
      }
      
      // Si c'est une offre gratuite et que l'utilisateur a déjà un abonnement premium
      if (plan.contains("Gratuite") && hasPremiumSubscription) {
        // Vérifier si l'utilisateur a un abonnement Stripe (sans cb_subscription)
        final hasStripeSubscription = await _hasActiveStripeSubscription(user.uid);
        
        if (hasStripeSubscription) {
          // Afficher un popup pour les abonnements Stripe
          _showStripeSubscriptionDialog(context);
          setProcessingState(false);
          return;
        }
        
        // Pour les autres types d'abonnements (RevenueCat)
        bool shouldOpenManagementScreen = await _showSubscriptionDialog(context);
        
        if (shouldOpenManagementScreen) {
          await RevenueCatService.openSubscriptionManagementScreen();
        }
        
        setProcessingState(false);
        return;
      }
      
      // Pour les autres cas (abonnements payants ou offre gratuite sans abonnement actif)
      await onSubscribe(plan);
      
    } catch (e) {
      // Afficher l'erreur
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Erreur'),
            content: Text('Une erreur est survenue : $e'),
            actions: [
              TextButton(
                child: const Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          );
        },
      );
    } finally {
      setProcessingState(false);
    }
  }

  /// Vérifie si l'utilisateur a un abonnement Stripe actif
  static Future<bool> _hasActiveStripeSubscription(String userId) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('authentification')
          .doc(userId)
          .get();
      
      if (!userDoc.exists) return false;
      
      final data = userDoc.data();
      if (data == null) return false;
      
      // Vérifier si l'utilisateur a un abonnement Stripe actif
      final isSubscriptionActive = data['isSubscriptionActive'] ?? false;
      final stripeStatus = data['stripeStatus'];
      final stripeSubscriptionId = data['stripeSubscriptionId'];
      final cbSubscription = data['cb_subscription'];
      
      // Cas 1: Abonnement Stripe actif sans cb_subscription
      final hasStripeWithoutCB = isSubscriptionActive && 
             (stripeStatus == 'active' || stripeStatus == 'trialing') && 
             stripeSubscriptionId != null && 
             stripeSubscriptionId.toString().isNotEmpty && 
             (cbSubscription == null || cbSubscription.toString().isEmpty);
      
      // Cas 2: Abonnement avec cb_subscription contenant premium-yearly_access ou premium-monthly_access
      final hasPremiumCBSubscription = isSubscriptionActive &&
             cbSubscription != null &&
             cbSubscription.toString().isNotEmpty &&
             (cbSubscription.toString().contains('premium-yearly_access') ||
              cbSubscription.toString().contains('premium-monthly_access'));
      
      return hasStripeWithoutCB || hasPremiumCBSubscription;
    } catch (e) {
      print('Erreur lors de la vérification de l\'abonnement Stripe: $e');
      return false;
    }
  }

  /// Affiche un dialogue pour les utilisateurs avec un abonnement Stripe
  static void _showStripeSubscriptionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 48,
                  color: Color(0xFF08004D),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Abonnement actif',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF08004D),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Vous avez actuellement un abonnement actif. Pour le résilier, '
                  'veuillez nous envoyer un email à contact@contraloc.fr. '
                  'Nous traiterons votre demande sous 24h.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF08004D),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Compris',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Affiche un dialogue pour les utilisateurs avec un abonnement premium
  static Future<bool> _showSubscriptionDialog(BuildContext context) async {
    bool result = false;
    
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 48,
                  color: Color(0xFF08004D),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Abonnement actif',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF08004D),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Vous avez actuellement un abonnement actif. '
                  'Pour passer à l\'offre gratuite, vous devez d\'abord résilier '
                  'votre abonnement actuel.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          result = false;
                          Navigator.of(context).pop();
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF08004D)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          'Annuler',
                          style: TextStyle(
                            color: Color(0xFF08004D),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          result = true;
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF08004D),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          'Gérer',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
    
    return result;
  }

  /// Construit le dialogue de paiement pour les abonnements payants
  static Widget buildPaymentDialog(BuildContext context, String plan) {
    // Utiliser isMonthly pour déterminer le type d'abonnement (mensuel ou annuel)
    final bool isMonthly = !plan.toLowerCase().contains("annuel");
    
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.payment_rounded,
            size: 48,
            color: Color(0xFF08004D),
          ),
          const SizedBox(height: 24),
          const Text(
            "Choisissez votre moyen de paiement",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF08004D),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Pour ${plan.toLowerCase()} ${isMonthly ? '(mensuel)' : '(annuel)'}",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          // Autres éléments du dialogue de paiement
        ],
      ),
    );
  }
}
