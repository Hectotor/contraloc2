import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ContraLoc/USERS/Subscription/revenue_cat_service.dart';
import 'dart:io' show Platform;
import 'package:url_launcher/url_launcher.dart';

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
      
      // Si c'est une offre gratuite
      if (plan.contains("Gratuite")) {
        // Vérifier le type d'abonnement et afficher le dialogue approprié
        bool shouldOpenManagementScreen = await _showSubscriptionDialog(context);
        
        if (shouldOpenManagementScreen) {
          await RevenueCatService.openSubscriptionManagementScreen();
        }
        
        setProcessingState(false);
        return;
      }
      
      // Pour les abonnements payants, afficher le dialogue de paiement
      if (!plan.contains("Gratuite")) {
        // Afficher le dialogue de paiement
        final paymentMethod = await showDialog<String>(
          context: context,
          builder: (BuildContext context) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: buildPaymentDialog(context, plan),
            );
          },
        );
        
        // Si l'utilisateur a choisi une méthode de paiement
        if (paymentMethod == 'card') {
          // Traiter le paiement par carte bancaire
          await onSubscribe(plan);
        } else {
          // L'utilisateur a annulé le paiement
          setProcessingState(false);
          return;
        }
      } else {
        // Pour l'offre gratuite sans abonnement actif
        await onSubscribe(plan);
      }
      
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

  /// Affiche un dialogue pour les utilisateurs avec un abonnement premium
  static Future<bool> _showSubscriptionDialog(BuildContext context) async {
    bool result = false;
    
    // Variables pour identifier le type d'abonnement
    bool hasStripeSubscription = false;
    bool hasCBSubscription = false;
    bool hasRevenueCatSubscription = false;
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('authentification')
            .doc(user.uid)
            .get();
        
        if (userDoc.exists) {
          final data = userDoc.data();
          if (data != null) {
            final stripePlanType = data['stripePlanType'];
            final cbSubscription = data['cb_subscription'];
            final subscriptionId = data['subscriptionId'];
            
            // Vérifier si c'est un abonnement Stripe
            hasStripeSubscription = stripePlanType != null &&
                stripePlanType.toString().isNotEmpty &&
                (stripePlanType.toString().contains('monthly') ||
                 stripePlanType.toString().contains('yearly'));
                
            // Vérifier si c'est un abonnement CB
            hasCBSubscription = cbSubscription != null &&
                cbSubscription.toString().isNotEmpty &&
                (cbSubscription.toString().contains('monthly') ||
                 cbSubscription.toString().contains('yearly'));
                 
            // Vérifier si c'est un abonnement RevenueCat
            hasRevenueCatSubscription = subscriptionId != null &&
                subscriptionId.toString().isNotEmpty &&
                (subscriptionId.toString().contains('monthly') ||
                 subscriptionId.toString().contains('yearly'));
          }
        }
      }
    } catch (e) {
      print('Erreur lors de la vérification du type d\'abonnement: $e');
    }
    
    // Message selon le type d'abonnement
    String message;
    if (hasStripeSubscription || hasCBSubscription) {
      message = 'Vous avez actuellement un abonnement actif. Pour le résilier, '
               'veuillez nous envoyer un email à contact@contraloc.fr. '
               'Nous traiterons votre demande sous 24h.';
    } else if (hasRevenueCatSubscription) {
      message = 'Vous avez actuellement un abonnement actif. '
               'Pour passer à l\'offre gratuite, vous devez d\'abord résilier '
               'votre abonnement actuel.';
    } else {
      message = 'Vous avez actuellement un abonnement actif. '
               'Pour passer à l\'offre gratuite, vous devez d\'abord résilier '
               'votre abonnement actuel.';
    }
    
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
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (hasRevenueCatSubscription) const SizedBox(height: 24),
                if (hasRevenueCatSubscription)
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
                            _launchStoreSubscriptionSettings();
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
                if (!hasRevenueCatSubscription) const SizedBox(height: 24),
                if (!hasRevenueCatSubscription)
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF08004D),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 48),
                    ),
                    child: const Text(
                      'OK',
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
    
    return result;
  }

  /// Lance les paramètres d'abonnement du store approprié (App Store ou Google Play)
  static void _launchStoreSubscriptionSettings() async {
    try {
      if (Platform.isIOS || Platform.isMacOS) {
        // Lien vers les abonnements de l'App Store
        final url = Uri.parse('https://apps.apple.com/account/subscriptions');
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        }
      } else if (Platform.isAndroid) {
        // Lien vers les abonnements de Google Play
        final url = Uri.parse('https://play.google.com/store/account/subscriptions');
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        }
      }
    } catch (e) {
      print('Erreur lors de l\'ouverture des paramètres d\'abonnement: $e');
    }
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
          const SizedBox(height: 24),
          // Bouton de paiement par carte bancaire
          ElevatedButton(
            onPressed: () {
              // Fermer le dialogue de paiement
              Navigator.of(context).pop('card');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF08004D),
              minimumSize: const Size(double.infinity, 55),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.credit_card, color: Colors.white),
                SizedBox(width: 8),
                Flexible(
                  child: Text(
                    "Paiement par carte bancaire",
                    overflow: TextOverflow.ellipsis,
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
        ],
      ),
    );
  }
}
