# ContraLoc Firebase Functions

Ce dossier contient les fonctions Cloud Firebase utilisées par l'application ContraLoc.

## Configuration du Webhook Stripe

Le webhook Stripe est configuré pour recevoir les événements de Stripe (paiements, abonnements, etc.) et mettre à jour la base de données Firestore en conséquence.

### Configuration du secret du webhook

Pour sécuriser le webhook, vous devez configurer la vérification de signature. Suivez ces étapes :

1. **Obtenir le secret du webhook Stripe** :
   - Connectez-vous à votre [tableau de bord Stripe](https://dashboard.stripe.com/)
   - Allez dans Développeurs > Webhooks
   - Sélectionnez votre endpoint de webhook
   - Dans la section "Signing secret", cliquez sur "Reveal" pour voir le secret

2. **Ajouter le secret dans Firestore** :
   - Ajoutez le secret du webhook dans la collection `api_key_stripe`, document `api`
   - Créez un champ `_webhookSecret` avec la valeur du secret (format: `whsec_votre_secret_ici`)

3. **Déployer les fonctions Firebase** :
   ```bash
   firebase deploy --only functions
   ```

4. **Vérifier les logs** :
   - Après déploiement, vérifiez les logs de la fonction `stripeWebhook` pour confirmer qu'elle fonctionne avec la vérification de signature

### Mode développement

Si le secret du webhook n'est pas configuré dans Firestore (champ `_webhookSecret` absent ou vide), le webhook fonctionnera en mode développement et acceptera toutes les requêtes sans vérification de signature. Cela est pratique pour les tests mais ne doit pas être utilisé en production.

## Structure des données Firestore

### Configuration Stripe

```
/api_key_stripe/api
```

Avec les champs suivants :
- `_apiKey` : Clé API sécurisée Stripe
- `_publicKey` : Clé API publique Stripe
- `_webhookSecret` : Secret du webhook Stripe

### Données d'abonnement

```
/users/{userId}/authentification/{userId}
```

Avec les champs suivants :
- `stripePlanType` : Type de plan (premium, platinum, free)
- `isStripeSubscriptionActive` : État de l'abonnement (true/false)
- `stripeNumberOfCars` : Nombre de véhicules autorisés
- `stripeSubscriptionId` : ID de l'abonnement Stripe
- `stripeStatus` : Statut détaillé de l'abonnement (active, trialing, canceled, etc.)
- `lastStripeUpdateDate` : Date de dernière mise à jour
