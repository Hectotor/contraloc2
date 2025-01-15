import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:purchases_flutter/purchases_flutter.dart'; // Import RevenueCat

class AnnulerAbonnement extends StatelessWidget {
  final Function onCancelSuccess;
  final String currentSubscriptionId;

  const AnnulerAbonnement({
    Key? key,
    required this.onCancelSuccess,
    required this.currentSubscriptionId,
  }) : super(key: key);

  Future<void> _cancelSubscription(BuildContext context) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      bool? shouldCancel = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text('Annuler l\'abonnement'),
          content:
              const Text('Êtes-vous sûr de vouloir annuler votre abonnement ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Confirmer',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );

      if (shouldCancel != true) return;

      // Annulation via RevenueCat
      await Purchases.logOut();

      // Mise à jour dans Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'isSubscriptionActive': false,
        'subscriptionId': 'free',
        'numberOfCars': 1,
        'limiteContrat': 10,
        'subscriptionType': 'monthly',
        'subscriptionCancellationDate': DateTime.now().toIso8601String(),
      });

      // Appeler le callback immédiatement après la mise à jour Firestore
      onCancelSuccess();

      // Montrer le message de succès après que tout est terminé
      if (context.mounted) {
        Navigator.pop(context); // Retourner à l'écran précédent
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Abonnement annulé avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Erreur dans _cancelSubscription: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'annulation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Supprimons la condition sur le bouton pour qu'il soit toujours visible
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: ElevatedButton(
        onPressed: () => _cancelSubscription(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text(
              'Annuler mon abonnement',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
