import 'package:flutter/material.dart';

class TermsOfService extends StatelessWidget {
  const TermsOfService({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Conditions d'utilisation",
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
              "Conditions d'utilisation",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            // Texte centralisé dans une variable pour améliorer la lisibilité
            const Text(
              _termsText,
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

// Texte des conditions d'utilisation déplacé pour éviter un widget trop long
const String _termsText = """
Conditions Générales d'Utilisation (CGU)

1. Présentation

Bienvenue sur Contraloc, une application développée par HQ DIGITAL FRANCE. L’application offre aux entreprises une solution de dématérialisation des contrats de location de véhicules.

En accédant à notre application, vous acceptez les présentes Conditions Générales d’Utilisation (« CGU »). Si vous n’êtes pas d’accord avec ces termes, nous vous invitons à ne pas utiliser nos services.

2. Services proposés

Contraloc permet aux entreprises de :

Créer, signer et gérer des contrats de location de véhicules de manière numérique.

Stocker et partager des contrats de manière sécurisée.

Personnaliser les contrats avec leurs propres termes et conditions.

3. Accès à l’application

L’accès à l’application est réservé aux entreprises ayant créé un compte utilisateur. Les utilisateurs doivent fournir des informations exactes lors de leur inscription.

4. Utilisation autorisée

Les utilisateurs s’engagent à :

Ne pas utiliser l’application à des fins frauduleuses ou illégales.

Respecter les lois et règlements en vigueur dans leur juridiction.

Assurer la confidentialité de leurs identifiants de connexion.

Nous nous réservons le droit de suspendre ou de supprimer tout compte en cas de non-respect de ces règles.

5. Collecte et conservation des données

Nous collectons des données personnelles, notamment des pièces d’identité, pour la gestion des contrats et l’amélioration du service. Ces données sont conservées pendant une durée maximale de 5 ans ou jusqu’à leur suppression par l’utilisateur.

6. Paiements

Les paiements pour les services peuvent être effectués directement dans l’application ou via notre site web. Aucune politique de remboursement ou d’annulation n’est prévue pour le moment.

7. Propriété intellectuelle

Tous les contenus et technologies utilisés dans l’application sont la propriété exclusive de HQ DIGITAL FRANCE.

8. Responsabilité

Nous ne saurions être tenus responsables en cas de :

Perte ou détérioration de données due à une mauvaise utilisation de l’application.

Dommages indirects ou consécutifs liés à l’utilisation de l’application.

9. Géolocalisation

L’application peut accéder à la géolocalisation de l’utilisateur pour améliorer certains services. Vous pouvez désactiver cette fonctionnalité dans les paramètres de l’application.

10. Juridiction

Les présentes CGU sont régies par la loi française. En cas de litige, les tribunaux français seront seuls compétents.
""";
