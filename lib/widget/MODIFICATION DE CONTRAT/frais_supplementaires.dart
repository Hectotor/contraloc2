import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart'; // Importer la bibliothèque intl pour utiliser DateFormat

class FraisSupplementaires extends StatefulWidget {
  final Map<String, dynamic> data;
  final Function(Map<String, dynamic>) onFraisUpdated;
  final double kilometrageInitial;
  final double kilometrageActuel;
  final double tarifKilometrique;
  final String dateFinEffective;

  const FraisSupplementaires({
    Key? key,
    required this.data,
    required this.onFraisUpdated,
    required this.kilometrageInitial,
    required this.kilometrageActuel,
    required this.tarifKilometrique,
    required this.dateFinEffective,
  }) : super(key: key);

  @override
  State<FraisSupplementaires> createState() => _FraisSupplementairesState();
}

class _FraisSupplementairesState extends State<FraisSupplementaires> {
  // Contrôleurs pour les champs de texte
  final TextEditingController _cautionController = TextEditingController();
  final TextEditingController _fraisNettoyageIntController = TextEditingController();
  final TextEditingController _fraisNettoyageExtController = TextEditingController();
  final TextEditingController _fraisCarburantController = TextEditingController();
  final TextEditingController _fraisRayuresController = TextEditingController();

  // Contrôleurs spécifiques pour les champs calculés automatiquement
  late TextEditingController _kmSuppDisplayController;
  late TextEditingController _coutTotalController;

  // Variables pour les cases à cocher
  bool _includeNettoyageInt = false;
  bool _includeNettoyageExt = false;
  bool _includeCarburant = false;
  bool _includeRayures = false;
  bool _includeCoutTotal = false;
  bool _includeCaution = false;
  bool _includeCoutKmSupp = false;

  // Total calculé
  double _total = 0.0;
  
  // Stockage temporaire des frais
  Map<String, dynamic> _tempFrais = {};

  @override
  void initState() {
    super.initState();
    // Initialiser les contrôleurs d'affichage
    _kmSuppDisplayController = TextEditingController(text: _calculerFraisKilometriques().toStringAsFixed(2));
    _coutTotalController = TextEditingController(text: _calculerCoutTotal().toStringAsFixed(2));
    
    // Initialiser les contrôleurs avec les données existantes si disponibles
    _cautionController.text = widget.data['caution']?.toString() ?? '0';
    
    // Initialiser les frais avec les valeurs du PDF si disponibles
    if (widget.data['nettoyageInt'] != null && widget.data['nettoyageInt'].toString().isNotEmpty) {
      _fraisNettoyageIntController.text = widget.data['nettoyageInt'].toString();
    } else {
      _fraisNettoyageIntController.text = widget.data['fraisNettoyageInterieur']?.toString() ?? '0';
    }
    
    if (widget.data['nettoyageExt'] != null && widget.data['nettoyageExt'].toString().isNotEmpty) {
      _fraisNettoyageExtController.text = widget.data['nettoyageExt'].toString();
    } else {
      _fraisNettoyageExtController.text = widget.data['fraisNettoyageExterieur']?.toString() ?? '0';
    }
    
    if (widget.data['carburantManquant'] != null && widget.data['carburantManquant'].toString().isNotEmpty) {
      _fraisCarburantController.text = widget.data['carburantManquant'].toString();
    } else {
      _fraisCarburantController.text = widget.data['fraisCarburantManquant']?.toString() ?? '0';
    }
    
    if (widget.data['prixRayures'] != null && widget.data['prixRayures'].toString().isNotEmpty) {
      _fraisRayuresController.text = widget.data['prixRayures'].toString();
    } else {
      _fraisRayuresController.text = widget.data['fraisRayuresDommages']?.toString() ?? '0';
    }

    // Initialiser les cases à cocher avec les valeurs sauvegardées
    _includeNettoyageInt = widget.data['includeNettoyageInterieur'] ?? false;
    _includeNettoyageExt = widget.data['includeNettoyageExterieur'] ?? false;
    _includeCarburant = widget.data['includeCarburantManquant'] ?? false;
    _includeRayures = widget.data['includeRayuresDommages'] ?? false;
    _includeCoutTotal = widget.data['includeCoutTotal'] ?? false;
    _includeCaution = widget.data['includeCaution'] ?? false;
    _includeCoutKmSupp = widget.data['includeCoutKmSupp'] ?? false;

    // Calculer le total initial sans notifier le parent
    _calculerTotalSansNotification();
    
    // Utiliser Future.microtask pour notifier le parent après la construction initiale
    Future.microtask(() {
      _notifierParent();
    });
  }

  @override
  void didUpdateWidget(FraisSupplementaires oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Vérifier si les propriétés ont changé
    if (oldWidget.kilometrageActuel != widget.kilometrageActuel || 
        oldWidget.kilometrageInitial != widget.kilometrageInitial || 
        oldWidget.tarifKilometrique != widget.tarifKilometrique ||
        oldWidget.dateFinEffective != widget.dateFinEffective) {
      // Mettre à jour les contrôleurs d'affichage
      _kmSuppDisplayController.text = _calculerFraisKilometriques().toStringAsFixed(2);
      _coutTotalController.text = _calculerCoutTotal().toStringAsFixed(2);
      
      // Recalculer le total
      _calculerTotal();
    }
  }

  @override
  void dispose() {
    _kmSuppDisplayController.dispose();
    _coutTotalController.dispose();
    super.dispose();
  }
  
  // Méthode pour calculer le total sans notifier le parent
  void _calculerTotalSansNotification() {
    double total = 0.0;
    
    // Ajouter coût total si la case est cochée
    if (_includeCoutTotal) {
      total += _calculerCoutTotal();
    }
    
    // Ajouter caution si la case est cochée
    if (_includeCaution) {
      total += double.tryParse(_cautionController.text) ?? 0.0;
    }
    
    // Ajouter coût km supplémentaires si la case est cochée
    if (_includeCoutKmSupp) {
      total += _calculerFraisKilometriques();
    }
    
    // Ajouter frais optionnels selon les cases cochées
    if (_includeNettoyageInt) {
      total += double.tryParse(_fraisNettoyageIntController.text) ?? 0.0;
    }
    
    if (_includeNettoyageExt) {
      total += double.tryParse(_fraisNettoyageExtController.text) ?? 0.0;
    }
    
    if (_includeCarburant) {
      total += double.tryParse(_fraisCarburantController.text) ?? 0.0;
    }
    
    if (_includeRayures) {
      total += double.tryParse(_fraisRayuresController.text) ?? 0.0;
    }
    
    setState(() {
      _total = total;
    });
  }

  double _calculerFraisKilometriques() {
    double kilometrageAutorise = double.tryParse(widget.data['kilometrageAutorise'] ?? '0') ?? 0;
    double kilometrage = widget.kilometrageActuel - widget.kilometrageInitial;
    double kmSupplementaires = 0;
    
    // Si le kilométrage est inférieur au kilométrage initial, pas de frais
    if (kilometrage < 0) {
      kilometrage = 0;
      return 0;
    }
    
    // Calculer les kilomètres supplémentaires (au-delà du kilométrage autorisé)
    if (kilometrage > kilometrageAutorise && kilometrageAutorise > 0) {
      kmSupplementaires = kilometrage - kilometrageAutorise;
    }
    
    // Calculer les frais en fonction du tarif kilométrique
    double frais = kmSupplementaires * widget.tarifKilometrique;
    
    // Mettre à jour le contrôleur d'affichage si nous ne sommes pas dans initState
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _kmSuppDisplayController.text = frais.toStringAsFixed(2);
      }
    });
    
    return frais;
  }
  
  // Méthode pour calculer le coût total en fonction des données du contrat
  double _calculerCoutTotal() {
    try {
      // Récupérer le prix de location depuis les données
      double prixLocation = double.tryParse(widget.data['prixLocation'] ?? '0') ?? 0;
      
      // Récupérer et parser les dates
      DateTime dateDebut;
      DateTime dateFin;
      
      try {
        // Essayer de parser la date de début
        String dateDebutStr = widget.data['dateDebut'] ?? '';
        if (dateDebutStr.contains('à')) {
          // Format: "EEEE d MMMM yyyy à HH:mm"
          dateDebut = DateFormat('EEEE d MMMM yyyy à HH:mm', 'fr_FR').parse(dateDebutStr);
        } else {
          // Essayer d'autres formats courants
          dateDebut = DateTime.tryParse(dateDebutStr) ?? DateTime.now();
        }
        
        // Essayer de parser la date de fin effective
        if (widget.dateFinEffective.isNotEmpty) {
          if (widget.dateFinEffective.contains('à')) {
            // Format: "EEEE d MMMM yyyy à HH:mm"
            dateFin = DateFormat('EEEE d MMMM yyyy à HH:mm', 'fr_FR').parse(widget.dateFinEffective);
          } else {
            // Essayer d'autres formats courants
            dateFin = DateTime.tryParse(widget.dateFinEffective) ?? DateTime.now();
          }
        } else {
          // Utiliser la date de fin théorique si la date effective n'est pas disponible
          String dateFinStr = widget.data['dateFinTheorique'] ?? '';
          if (dateFinStr.contains('à')) {
            dateFin = DateFormat('EEEE d MMMM yyyy à HH:mm', 'fr_FR').parse(dateFinStr);
          } else {
            dateFin = DateTime.tryParse(dateFinStr) ?? DateTime.now();
          }
        }
      } catch (e) {
        print('Erreur lors du parsing des dates: $e');
        // En cas d'erreur, utiliser des valeurs par défaut
        dateDebut = DateTime.now();
        dateFin = DateTime.now().add(const Duration(days: 1));
      }
      
      // Calculer la différence en heures pour plus de précision
      int differenceEnHeures = dateFin.difference(dateDebut).inHours;
      
      // Calculer le nombre de jours facturés
      int joursFactures = 1; // Le premier jour est toujours facturé
      
      // Ajouter un jour pour chaque tranche de 24h complète
      if (differenceEnHeures >= 24) {
        joursFactures = 1 + (differenceEnHeures / 24).floor();
      }
      
      // Calculer le coût total
      double coutTotal = prixLocation * joursFactures;
      
      // Mettre à jour le contrôleur d'affichage si nous ne sommes pas dans initState
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _coutTotalController.text = coutTotal.toStringAsFixed(2);
        }
      });
      
      return coutTotal;
      
    } catch (e) {
      print('Erreur lors du calcul du coût total: $e');
      return 0.0;
    }
  }
  
  // Méthode pour notifier le parent des changements
  void _notifierParent() {
    // Préparer les données à envoyer au parent
    _tempFrais = {
      'coutTotal': _calculerCoutTotal(),
      'caution': double.tryParse(_cautionController.text) ?? 0.0,
      'coutKmSupplementaires': _calculerFraisKilometriques(),
      'fraisNettoyageInterieur': double.tryParse(_fraisNettoyageIntController.text) ?? 0.0,
      'fraisNettoyageExterieur': double.tryParse(_fraisNettoyageExtController.text) ?? 0.0,
      'fraisCarburantManquant': double.tryParse(_fraisCarburantController.text) ?? 0.0,
      'fraisRayuresDommages': double.tryParse(_fraisRayuresController.text) ?? 0.0,
      
      // Utiliser des noms de propriétés cohérents pour les cases à cocher
      'includeNettoyageInterieur': _includeNettoyageInt,
      'includeNettoyageExterieur': _includeNettoyageExt,
      'includeCarburantManquant': _includeCarburant,
      'includeRayuresDommages': _includeRayures,
      'includeCoutTotal': _includeCoutTotal,
      'includeCaution': _includeCaution,
      'includeCoutKmSupp': _includeCoutKmSupp,
      'totalFrais': _total,
      
      // Ajouter les champs pour le PDF avec le même format pour tous les frais
      'nettoyageInt': _includeNettoyageInt ? _fraisNettoyageIntController.text : '',
      'nettoyageExt': _includeNettoyageExt ? _fraisNettoyageExtController.text : '',
      'carburantManquant': _includeCarburant ? _fraisCarburantController.text : '',
      'prixRayures': _includeRayures ? _fraisRayuresController.text : '',
      'temporaire': true, // Marquer les frais comme temporaires
    };
    
    widget.onFraisUpdated(_tempFrais);
  }

  // Méthode pour calculer le total et notifier le parent
  void _calculerTotal() {
    _calculerTotalSansNotification();
    _notifierParent();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Frais supplémentaires",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Coût total
            _buildCheckboxField(
              controller: _coutTotalController,
              label: "Prix de la location",
              value: _includeCoutTotal,
              onChanged: (value) {
                setState(() {
                  _includeCoutTotal = value ?? false;
                  _calculerTotal();
                });
              },
              onTextChanged: (_) => _calculerTotal(),
              readOnly: true, // Rendre le champ en lecture seule car calculé automatiquement
            ),
            const SizedBox(height: 10),
            
            // Caution
            _buildCheckboxField(
              controller: _cautionController,
              label: "Caution",
              value: _includeCaution,
              onChanged: (value) {
                setState(() {
                  _includeCaution = value ?? false;
                  _calculerTotal();
                });
              },
              onTextChanged: (_) => _calculerTotal(),
            ),
            const SizedBox(height: 10),
            
            // Coût km supplémentaires
            _buildCheckboxField(
              controller: _kmSuppDisplayController,
              label: "Frais total km supplémentaires",
              value: _includeCoutKmSupp,
              onChanged: (value) {
                setState(() {
                  _includeCoutKmSupp = value ?? false;
                  _calculerTotal();
                });
              },
              onTextChanged: (_) => _calculerTotal(),
              readOnly: true, // Rendre le champ en lecture seule car calculé automatiquement
            ),
            const SizedBox(height: 10),
            
            // Frais avec cases à cocher
            _buildCheckboxField(
              controller: _fraisNettoyageIntController,
              label: "Frais de nettoyage intérieur",
              value: _includeNettoyageInt,
              onChanged: (value) {
                setState(() {
                  _includeNettoyageInt = value ?? false;
                  _calculerTotal();
                });
              },
              onTextChanged: (_) => _calculerTotal(),
            ),
            const SizedBox(height: 10),
            
            _buildCheckboxField(
              controller: _fraisNettoyageExtController,
              label: "Frais de nettoyage extérieur",
              value: _includeNettoyageExt,
              onChanged: (value) {
                setState(() {
                  _includeNettoyageExt = value ?? false;
                  _calculerTotal();
                });
              },
              onTextChanged: (_) => _calculerTotal(),
            ),
            const SizedBox(height: 10),
            
            _buildCheckboxField(
              controller: _fraisCarburantController,
              label: "Frais de carburant manquant",
              value: _includeCarburant,
              onChanged: (value) {
                setState(() {
                  _includeCarburant = value ?? false;
                  _calculerTotal();
                });
              },
              onTextChanged: (_) => _calculerTotal(),
            ),
            const SizedBox(height: 10),
            
            _buildCheckboxField(
              controller: _fraisRayuresController,
              label: "Frais de rayures/dommages",
              value: _includeRayures,
              onChanged: (value) {
                setState(() {
                  _includeRayures = value ?? false;
                  _calculerTotal();
                });
              },
              onTextChanged: (_) => _calculerTotal(),
            ),
            const SizedBox(height: 20),
            
            // Total
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF08004D).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "TOTAL",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "${_total.toStringAsFixed(2)} €",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF08004D),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            // Boutons d'action
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                  child: const Text("Annuler"),
                ),
                ElevatedButton(
                  onPressed: () {
                    _calculerTotal(); // Recalculer une dernière fois
                    Navigator.of(context).pop(true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF08004D),
                  ),
                  child: const Text(
                    "Valider",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Widget pour construire un champ avec case à cocher
  Widget _buildCheckboxField({
    required TextEditingController controller,
    required String label,
    required bool value,
    required Function(bool?) onChanged,
    required Function(String) onTextChanged,
    bool readOnly = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          value: value,
          onChanged: onChanged,
          activeColor: const Color(0xFF08004D),
        ),
        Expanded(
          child: TextFormField(
            controller: controller,
            readOnly: readOnly,
            decoration: InputDecoration(
              labelText: label,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              suffixText: "€",
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
            ],
            onChanged: onTextChanged,
          ),
        ),
      ],
    );
  }
}

// Fonction pour afficher le popup des frais supplémentaires
Future<bool?> showFraisSupplementairesDialog(
  BuildContext context,
  Map<String, dynamic> data,
  Function(Map<String, dynamic>) onFraisUpdated,
  double kilometrageInitial,
  double kilometrageActuel,
  double tarifKilometrique,
  String dateFinEffective,
) {
  return showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: FraisSupplementaires(
          data: data,
          onFraisUpdated: onFraisUpdated,
          kilometrageInitial: kilometrageInitial,
          kilometrageActuel: kilometrageActuel,
          tarifKilometrique: tarifKilometrique,
          dateFinEffective: dateFinEffective,
        ),
      );
    },
  );
}
