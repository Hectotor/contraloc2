import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ContraLoc/services/collaborateur_util.dart';

import 'abonnement_screen.dart';

class ContratModifier extends StatefulWidget {
  // Rendre defaultContract accessible
  static const String defaultContract = '''

Article 1 : Obligations du Bailleur
Le Bailleur s’engage à :
Fournir un véhicule en bon état de fonctionnement
Le véhicule doit être en parfait état de marche, propre, et entretenu conformément aux normes du constructeur.
Les équipements de sécurité (freins, pneus, éclairage, etc.) doivent être en bon état et conformes à la réglementation en vigueur.
Assurer la conformité des documents légaux
Le Bailleur doit fournir les documents nécessaires à l’utilisation légale du véhicule :
- Carte grise valide ;
- Attestation d’assurance mentionnant que le véhicule est couvert pour la location ;
- Rapport de contrôle technique en cours de validité.
Garantir la disponibilité du véhicule à la date prévue
Le véhicule doit être disponible à l’heure et au lieu convenus dans le contrat, sans retard ni empêchement non justifié.
Effectuer un état des lieux contradictoire
Un état des lieux détaillé, accompagné de photographies, doit être réalisé avant la remise du véhicule et signé par les deux parties.

Article 2 : Obligations du Locataire
Le Locataire s’engage à :
Utiliser le véhicule avec soin et responsabilité
Le Locataire doit conduire de manière prudente et respecter les lois et règlements en vigueur (notamment le Code de la route).
Toute utilisation abusive ou détournée du véhicule est interdite.
Ne pas sous-louer ou prêter le véhicule
Le Locataire ne peut en aucun cas sous-louer ou prêter le véhicule à un tiers, sauf accord exprès du Bailleur.
Assumer les frais liés à l’utilisation
Le carburant, les péages, les parkings, et autres frais d’utilisation sont à la charge exclusive du Locataire.
Restituer le véhicule dans l’état initial
Le Locataire doit restituer le véhicule propre et dans le même état que lors de la prise en charge, hormis l’usure normale liée à son utilisation.
Informer immédiatement en cas d’incident
En cas de panne, accident, ou autre incident, le Locataire doit informer le Bailleur dans les plus brefs délais et suivre les instructions données.

Article 3 : Assurances et responsabilités
Couverture d’assurance
Le véhicule est couvert par une assurance responsabilité civile souscrite par le Bailleur. Cette assurance couvre les dommages causés à des tiers pendant la durée de la location.
Responsabilité du Locataire
Le Locataire est responsable des dommages causés au véhicule dans la limite de la franchise prévue.
Le Locataire est également responsable des amendes, infractions, et contraventions commises pendant la période de location.
Sinistres et réparations
En cas de sinistre, le Locataire doit remplir un constat amiable et le transmettre au Bailleur.
Les frais de réparation non couverts par l’assurance restent à la charge du Locataire.

Article 4 : Restitution du véhicule
Lieu et heure de restitution
Le véhicule doit être restitué à la date, à l’heure, et au lieu convenus dans le contrat.
Frais de retard
Toute restitution tardive entraînera des frais supplémentaires calculés au prorata des heures de retard.
Inspection à la restitution
Le véhicule sera inspecté en présence des deux parties. Toute détérioration non liée à l’usure normale (rayures, chocs, etc.) sera facturée au Locataire.

Article 5 : Résiliation
Résiliation par le Bailleur
Le Bailleur peut résilier le contrat en cas de non-respect des obligations par le Locataire, notamment en cas d'utilisation abusive ou non autorisée du véhicule.
Résiliation par le Locataire
Le Locataire peut résilier le contrat en cas de non-conformité du véhicule ou d’indisponibilité injustifiée.
Conséquences de la résiliation
En cas de résiliation anticipée, le dépôt de garantie pourra être conservé, en tout ou partie, pour couvrir les frais engagés par la partie lésée.

Article 6 : Litiges
Règlement amiable
Les parties s’engagent à résoudre tout différend lié au contrat par voie amiable, en privilégiant le dialogue et la médiation.
Compétence juridictionnelle
En cas d’échec de la résolution amiable, les litiges seront soumis aux tribunaux compétents du lieu de résidence du Bailleur.
''';

  @override
  _ContratModifierState createState() => _ContratModifierState();
}

class _ContratModifierState extends State<ContratModifier> {
  final TextEditingController _controller = TextEditingController();
  bool isPremiumUser = false; // Ajouter cette variable
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkPremiumStatus();
    _loadContract();
  }

  Future<void> _checkPremiumStatus() async {
    try {
      setState(() {
        isLoading = true;
      });
      
      // Utiliser la nouvelle méthode de CollaborateurUtil
      final isPremium = await CollaborateurUtil.isPremiumUser();
      
      setState(() {
        isPremiumUser = isPremium;
        print('Status Premium: $isPremiumUser');
      });
    } catch (e) {
      print('Erreur lors de la vérification du statut Premium: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadContract() async {
    try {
      setState(() {
        isLoading = true;
      });
      
      // Récupérer le statut du collaborateur
      final collaborateurStatus = await CollaborateurUtil.checkCollaborateurStatus();
      final String targetId = collaborateurStatus['isCollaborateur'] 
          ? collaborateurStatus['adminId'] ?? FirebaseAuth.instance.currentUser?.uid 
          : FirebaseAuth.instance.currentUser?.uid ?? '';
      
      if (targetId.isNotEmpty) {
        try {
          // Essayer de récupérer le document avec un timeout
          final doc = await FirebaseFirestore.instance
              .collection('users')
              .doc(targetId)
              .collection('contrats')
              .doc('userId')
              .withConverter(
                fromFirestore: (snapshot, _) => snapshot.data(),
                toFirestore: (data, _) => data as Map<String, dynamic>,
              )
              .get(const GetOptions(source: Source.cache)); // Priorité à la cache
          
          if (mounted) {
            setState(() {
              _controller.text = doc.data()?['texte'] ?? ContratModifier.defaultContract;
            });
          }
        } catch (e) {
          print('⚠️ Tentative de cache échouée, nouvelle tentative avec le serveur: $e');
          try {
            // Si la cache échoue, essayer le serveur avec timeout
            final doc = await FirebaseFirestore.instance
                .collection('users')
                .doc(targetId)
                .collection('contrats')
                .doc('userId')
                .withConverter(
                  fromFirestore: (snapshot, _) => snapshot.data(),
                  toFirestore: (data, _) => data as Map<String, dynamic>,
                )
                .get(const GetOptions(source: Source.server));
            
            if (mounted) {
              setState(() {
                _controller.text = doc.data()?['texte'] ?? ContratModifier.defaultContract;
              });
            }
          } catch (e) {
            print('❌ Erreur après 2 tentatives: $e');
            if (mounted) {
              setState(() {
                _controller.text = ContratModifier.defaultContract;
              });
            }
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _controller.text = ContratModifier.defaultContract;
          });
        }
      }
    } catch (e) {
      print('❌ Erreur récupération document: $e');
      if (mounted) {
        setState(() {
          _controller.text = ContratModifier.defaultContract;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _saveContract() async {
    if (!isPremiumUser) {
      _showPremiumDialog();
      return;
    }

    try {
      // Récupérer le statut du collaborateur
      final collaborateurStatus = await CollaborateurUtil.checkCollaborateurStatus();
      final String userId = collaborateurStatus['userId'] ?? FirebaseAuth.instance.currentUser?.uid ?? '';
      final String targetId = collaborateurStatus['isCollaborateur'] 
          ? collaborateurStatus['adminId'] ?? userId 
          : userId;
      
      if (targetId.isNotEmpty) {
        // Vérifier les permissions
        bool hasWritePermission = true;
        if (collaborateurStatus['isCollaborateur'] == true) {
          final permissions = collaborateurStatus['permissions'];
          if (permissions is Map<String, dynamic>) {
            hasWritePermission = permissions['write'] == true;
          }
        }
        
        if (collaborateurStatus['isCollaborateur'] == true && !hasWritePermission) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Vous n\'avez pas les permissions nécessaires pour modifier le contrat.'),
              backgroundColor: Colors.redAccent,
            ),
          );
          return;
        }
        
        // Sauvegarder avec timeout
        await FirebaseFirestore.instance
            .collection('users')
            .doc(targetId)
            .collection('contrats')
            .doc('userId')
            .set({
              'texte': _controller.text,
              'dateModification': FieldValue.serverTimestamp(),
            });
            
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Contrat sauvegardé avec succès'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Erreur sauvegarde contrat: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de la sauvegarde du contrat'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  // Ajouter cette méthode
  void _showPremiumDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text(
            "Fonctionnalité Premium",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF08004D),
            ),
          ),
          content: const Text(
            "La modification du contrat est disponible uniquement avec l'abonnement Premium. Souhaitez-vous découvrir nos offres ?",
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Plus tard",
                style: TextStyle(color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AbonnementScreen(),
                  ),
                );
              },
              child: const Text(
                "Voir les offres",
                style: TextStyle(
                  color: Color(0xFF08004D),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _resetContract() {
    setState(() {
      _controller.text = ContratModifier.defaultContract;
    });
  }

  // Ajouter cette méthode
  void _onTextFieldTap() {
    if (!isPremiumUser) {
      _showPremiumDialog();
      // Masquer le clavier s'il est ouvert
      FocusScope.of(context).unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Modifier le Contrat",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        backgroundColor: const Color(0xFF08004D),
        iconTheme: const IconThemeData(
            color: Colors.white), // Icon color for back button
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.keyboard_hide, color: Colors.white),
            onPressed: () {
              FocusScope.of(context).unfocus();
            },
          ),
        ],
      ),
      body: isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF08004D)))
        : Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
          ),
          child: Column(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 2,
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF08004D),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                          ),
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: GestureDetector(
                            onTap:
                                _onTextFieldTap, // Ajouter le gestionnaire de tap
                            child: TextFormField(
                              controller: _controller,
                              maxLines: null,
                              enabled: isPremiumUser,
                              readOnly: !isPremiumUser, // Ajouter cette ligne
                              style: const TextStyle(
                                fontFamily: 'Roboto', // Change font to Roboto
                                fontSize: 16,
                                height: 1.6,
                                color: Color(0xFF2C3E50),
                              ),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: isPremiumUser
                                    ? 'Le contenu du contrat...'
                                    : 'Abonnement Premium requis pour modifier le contrat',
                                hintStyle: TextStyle(color: Colors.grey.shade400),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Garder les boutons existants
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: isPremiumUser ? _resetContract : null,
                        icon: const Icon(Icons.refresh, color: Colors.white),
                        label: const Text('Réinitialiser',
                            style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed:
                            isPremiumUser ? _saveContract : _showPremiumDialog,
                        icon: const Icon(Icons.save, color: Colors.white),
                        label: const Text('Enregistrer',
                            style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF08004D),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
    );
  }
}
