import 'package:flutter/material.dart';

class PrivacyPolicy extends StatelessWidget {
  const PrivacyPolicy({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Politique de confidentialité",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF08004D), // Code couleur de la barre
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Politique de confidentialité",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            // Texte centralisé dans une constante
            const Text(
              _privacyPolicyText,
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

// Texte de la politique de confidentialité déplacé pour améliorer la lisibilité
const String _privacyPolicyText = """
Politique de Confidentialité

1. Responsable du traitement des données

Le responsable du traitement des données est :
HQ DIGITAL FRANCE
4 rue Jean Pierre Timbaud, 93700 Drancy
E-mail : contact@contraloc.fr

2. Données collectées

Nous collectons les données suivantes :

Informations personnelles : Nom, prénom, e-mail, téléphone.

Données sensibles : Pièces d’identité (ex. : permis de conduire).

Données contractuelles : Documents, photos, et informations liées aux contrats.

Données de géolocalisation (optionnel).

3. Utilisation des données

Les données sont utilisées pour :

La création et la gestion des contrats.

L’amélioration des services.

La mise en conformité avec les obligations légales.

4. Partage des données

Les données peuvent être partagées avec :

Firebase pour le stockage sécurisé.

Google Analytics pour l’analyse des performances.

Nous ne vendons jamais vos données à des tiers.

5. Sécurité des données

Vos données sont chiffrées en transit et au repos pour garantir leur sécurité.

6. Durée de conservation

Les données sont conservées pour une durée maximale de 5 ans, sauf suppression volontaire par l’utilisateur.

7. Droits des utilisateurs

Vous avez le droit de :

Accéder à vos données.

Les rectifier.

Les supprimer.

Demander leur portabilité.

Pour exercer vos droits, contactez-nous à : contact@contraloc.fr.

8. Modifications de la politique

Nous nous réservons le droit de modifier cette politique à tout moment. Les modifications seront publiées dans l’application.

HQ DIGITAL FRANCE vous remercie de votre confiance.
""";
