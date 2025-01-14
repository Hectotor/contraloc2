import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class AnnulerAbonnement extends StatelessWidget {
  final Function onCancelSuccess;
  final String currentSubscriptionId;
  final InAppPurchase inAppPurchase;

  const AnnulerAbonnement({
    Key? key,
    required this.onCancelSuccess,
    required this.currentSubscriptionId,
    required this.inAppPurchase,
  }) : super(key: key);

  Future<void> _cancelSubscription(BuildContext context) async {
    // Ajout des prints de débogage
    print('Début de _cancelSubscription');
    print('currentSubscriptionId: $currentSubscriptionId');

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('Erreur: Utilisateur non connecté');
        return;
      }

      print('Utilisateur trouvé: ${user.uid}');

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
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text(
                'Confirmer',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );

      print('Réponse dialog: $shouldCancel');
      if (shouldCancel != true) return;

      print('Début annulation dans le store');
      await inAppPurchase.restorePurchases();
      print('Fin annulation dans le store');

      print('Début mise à jour Firestore');
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'numberOfCars': 1,
        'limiteContrat': 10,
        'isSubscriptionActive': false,
        'subscriptionId': 'free',
        'subscriptionType': 'free',
        'subscriptionPurchaseDate': DateTime.now().toIso8601String(),
        'subscriptionCancellationDate':
            DateTime.now().toIso8601String(), // Ajouter la date d'annulation
      });
      print('Fin mise à jour Firestore');

      onCancelSuccess();
      print('onCancelSuccess appelé');

      // Confirmer à l'utilisateur
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Abonnement annulé avec succès'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Erreur dans _cancelSubscription: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur détaillée: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ajout de print pour vérifier l'état du bouton
    print('Build AnnulerAbonnement');
    print('currentSubscriptionId: $currentSubscriptionId');
    print('Bouton actif: ${currentSubscriptionId != 'free'}');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: ElevatedButton(
        onPressed: currentSubscriptionId == 'free'
            ? null
            : () => _cancelSubscription(context),
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
