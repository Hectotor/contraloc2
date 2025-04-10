import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart' show FieldValue;
import 'FACTURE/prix_location_container.dart';
import 'FACTURE/frais_kilometrage_supp_container.dart';
import 'frais_additionnels_container.dart';
import 'FACTURE/caution_container.dart';
import 'FACTURE/remise_container.dart';
import 'FACTURE/type_paiement_container.dart';
import 'FACTURE/total_frais_container.dart';
import 'FACTURE/tva_container.dart';
import 'FACTURE/popup_succees.dart';

class FactureScreen extends StatefulWidget {
  final Map<String, dynamic> data;
  final Function(Map<String, dynamic>) onFraisUpdated;

  const FactureScreen({
    Key? key,
    required this.data,
    required this.onFraisUpdated,
  }) : super(key: key);

  @override
  State<FactureScreen> createState() => _FactureScreenState();
}

class _FactureScreenState extends State<FactureScreen> {
  late TextEditingController _prixLocationController;
  late TextEditingController _fraisKilometriqueController;
  late TextEditingController _fraisNettoyageIntController;
  late TextEditingController _fraisNettoyageExtController;
  late TextEditingController _fraisCarburantController;
  late TextEditingController _fraisRayuresController;
  late TextEditingController _fraisAutreController;
  late TextEditingController _cautionController;
  late TextEditingController _remiseController;
  String _tvaType = 'applicable';
  String _selectedPaymentType = 'Carte bancaire';

  String? adminId;  // Pour stocker l'ID de l'admin si l'utilisateur est un collaborateur

  @override
  void initState() {
    super.initState();
    
    // Initialiser les contrôleurs avec les valeurs existantes ou 0 par défaut
    _prixLocationController = TextEditingController(text: widget.data['facturePrixLocation']?.toString() ?? "0");
    _fraisKilometriqueController = TextEditingController(text: widget.data['factureCoutKmSupplementaires']?.toString() ?? "0");
    _fraisNettoyageIntController = TextEditingController(text: widget.data['factureFraisNettoyageInterieur']?.toString() ?? "0");
    _fraisNettoyageExtController = TextEditingController(text: widget.data['factureFraisNettoyageExterieur']?.toString() ?? "0");
    _fraisCarburantController = TextEditingController(text: widget.data['factureFraisCarburantManquant']?.toString() ?? "0");
    _fraisRayuresController = TextEditingController(text: widget.data['factureFraisRayuresDommages']?.toString() ?? "0");
    _fraisAutreController = TextEditingController(text: widget.data['factureFraisAutre']?.toString() ?? "0");
    _cautionController = TextEditingController(text: widget.data['factureCaution']?.toString() ?? "0");
    _remiseController = TextEditingController(text: widget.data['factureRemise']?.toString() ?? "0");

    // Initialiser le type de TVA et le type de paiement s'ils existent
    _tvaType = widget.data['factureTVA'] ?? 'applicable';
    _selectedPaymentType = widget.data['factureTypePaiement'] ?? 'Carte bancaire';

    // Vérifier si c'est un collaborateur et récupérer l'adminId
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Récupérer l'adminId directement depuis les données du contrat
      adminId = widget.data['adminId'];
      // Si adminId n'est pas disponible, le récupérer depuis le document utilisateur
      if (adminId == null) {
        FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get()
            .then((doc) {
          if (doc.exists && doc.data()?['role'] == 'collaborateur') {
            setState(() {
              adminId = doc.data()?['adminId'];
            });
          }
        });
      }
    }
  }

  double _parseDouble(String value) {
    if (value.isEmpty) return 0;
    return double.tryParse(value.replaceAll(',', '.')) ?? 0;
  }

  double _calculerTotal() {
    return _parseDouble(_prixLocationController.text) +
        _parseDouble(_fraisKilometriqueController.text) +
        _parseDouble(_fraisNettoyageIntController.text) +
        _parseDouble(_fraisNettoyageExtController.text) +
        _parseDouble(_fraisCarburantController.text) +
        _parseDouble(_fraisRayuresController.text) +
        _parseDouble(_fraisAutreController.text) +
        _parseDouble(_cautionController.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Facture',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF08004D),
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PrixLocationContainer(
                prixLocationController: _prixLocationController,
                onPrixLocationChanged: () {
                  setState(() {
                    // Le total se met à jour automatiquement
                  });
                },
              ),
              const SizedBox(height: 24),
              FraisKilometrageSuppContainer(
                fraisKilometriqueController: _fraisKilometriqueController,
                onFraisKilometriqueChanged: () {
                  setState(() {
                    // Le total se met à jour automatiquement
                  });
                },
              ),
              const SizedBox(height: 24),
              FraisAdditionnelsContainer(
                fraisNettoyageIntController: _fraisNettoyageIntController,
                fraisNettoyageExtController: _fraisNettoyageExtController,
                fraisCarburantController: _fraisCarburantController,
                fraisRayuresController: _fraisRayuresController,
                fraisAutreController: _fraisAutreController,
                onFraisChanged: () {
                  setState(() {
                    // Le total se met à jour automatiquement
                  });
                },
              ),
              const SizedBox(height: 24),
              CautionContainer(
                cautionController: _cautionController,
                onCautionChanged: () {
                  setState(() {
                    // Le total se met à jour automatiquement
                  });
                },
              ),
              const SizedBox(height: 24),
              RemiseContainer(
                remiseController: _remiseController,
                onRemiseChanged: () {
                  setState(() {
                    // Le total se met à jour automatiquement
                  });
                },
              ),
              const SizedBox(height: 24),
              TypePaiementContainer(
                selectedType: _selectedPaymentType,
                onTypePaiementChanged: (type) {
                  setState(() {
                    _selectedPaymentType = type;
                  });
                },
              ),
              const SizedBox(height: 24),
              TotalFraisContainer(
                prixLocationController: _prixLocationController,
                fraisKilometriqueController: _fraisKilometriqueController,
                fraisNettoyageIntController: _fraisNettoyageIntController,
                fraisNettoyageExtController: _fraisNettoyageExtController,
                fraisCarburantController: _fraisCarburantController,
                fraisRayuresController: _fraisRayuresController,
                fraisAutreController: _fraisAutreController,
                cautionController: _cautionController,
                remiseController: _remiseController,
              ),
              const SizedBox(height: 24),
              TVAContainer(
                onTVATypeChanged: (type) {
                  setState(() {
                    _tvaType = type;
                  });
                },
              ),
              const SizedBox(height: 24),
              Center(
                child: SizedBox(
                  width: 350,
                  child: ElevatedButton(
                    onPressed: () async {
                      final userId = FirebaseAuth.instance.currentUser?.uid;
                      if (userId != null && widget.data['contratId'] != null) {
                        print('Enregistrement de la facture - userId: $userId, contratId: ${widget.data['contratId']}');
                        
                        try {
                          // Générer un numéro de facture unique basé sur la date et l'heure
                          final now = DateTime.now();
                          final numeroFacture = 'F-${now.year}${now.month.toString().padLeft(2, '0')}-${now.day}${now.hour}${now.minute}${now.second}';
                          print('Numéro de facture généré: $numeroFacture');

                          // Préparer les données à sauvegarder
                          final factureData = {
                            'facturePrixLocation': double.tryParse(_prixLocationController.text) ?? 0.0,
                            'factureCaution': double.tryParse(_cautionController.text) ?? 0.0,
                            'factureFraisNettoyageInterieur': double.tryParse(_fraisNettoyageIntController.text) ?? 0.0,
                            'factureFraisNettoyageExterieur': double.tryParse(_fraisNettoyageExtController.text) ?? 0.0,
                            'factureFraisCarburantManquant': double.tryParse(_fraisCarburantController.text) ?? 0.0,
                            'factureFraisRayuresDommages': double.tryParse(_fraisRayuresController.text) ?? 0.0,
                            'factureFraisAutre': double.tryParse(_fraisAutreController.text) ?? 0.0,
                            'factureCoutKmSupplementaires': double.tryParse(_fraisKilometriqueController.text) ?? 0.0,
                            'factureRemise': double.tryParse(_remiseController.text) ?? 0.0,
                            'factureTotalFrais': _calculerTotal(),
                            'factureTypePaiement': _selectedPaymentType,
                            'dateFacture': FieldValue.serverTimestamp(),
                            'factureTVA': _tvaType,
                            'factureGeneree': true,
                            'factureId': numeroFacture,
                          };
                          print('Données à sauvegarder: $factureData');

                          // Sauvegarde dans Firestore
                          final db = FirebaseFirestore.instance;
                          // Utiliser l'adminId si l'utilisateur est un collaborateur, sinon utiliser userId
                          final userIdToUse = adminId ?? userId;
                          final docRef = db.collection('users').doc(userIdToUse).collection('locations').doc(widget.data['contratId']);
                          print('Référence du document: $docRef');
                          
                          // Sauvegarder les données
                          await docRef.set(factureData, SetOptions(merge: true));
                          print('Données sauvegardées avec succès');

                          // Vérifier le résultat après la sauvegarde
                          final snapshot = await docRef.get();
                          print('Données sauvegardées: ${snapshot.data()}');

                          // Mettre à jour les données dans le parent
                          widget.onFraisUpdated({
                            'facturePrixLocation': _prixLocationController.text,
                            'factureCaution': _cautionController.text,
                            'factureFraisNettoyageInterieur': _fraisNettoyageIntController.text,
                            'factureFraisNettoyageExterieur': _fraisNettoyageExtController.text,
                            'factureFraisCarburantManquant': _fraisCarburantController.text,
                            'factureFraisRayuresDommages': _fraisRayuresController.text,
                            'factureFraisAutre': _fraisAutreController.text,
                            'factureCoutKmSupplementaires': _fraisKilometriqueController.text,
                            'factureRemise': _remiseController.text,
                            'factureTotalFrais': _calculerTotal().toString(),
                            'factureTypePaiement': _selectedPaymentType,
                            'factureTVA': _tvaType,
                            'factureId': numeroFacture,
                          });

                          // Afficher le popup de succès
                          showDialog(
                            context: context,
                            builder: (context) => SuccessPopup(
                              title: 'Succès',
                              message: 'La facture a été sauvegardée avec succès.',
                              onConfirm: () {
                                Navigator.pop(context); // Fermer le popup
                              },
                            ),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Erreur lors de la sauvegarde : ${e.toString()}'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF08004D),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Valider',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }
}
