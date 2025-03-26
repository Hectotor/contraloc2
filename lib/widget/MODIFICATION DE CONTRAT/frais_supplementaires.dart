import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FraisSupplementaires extends StatefulWidget {
  final Map<String, dynamic> data;
  final Function(Map<String, dynamic>) onFraisUpdated;

  const FraisSupplementaires({
    Key? key,
    required this.data,
    required this.onFraisUpdated,
  }) : super(key: key);

  @override
  State<FraisSupplementaires> createState() => _FraisSupplementairesState();
}

class _FraisSupplementairesState extends State<FraisSupplementaires> {
  // Contrôleurs pour les champs de texte
  final TextEditingController _coutTotalTheoriqueController = TextEditingController();
  final TextEditingController _cautionController = TextEditingController();
  final TextEditingController _coutKmSuppController = TextEditingController();
  final TextEditingController _fraisNettoyageIntController = TextEditingController();
  final TextEditingController _fraisNettoyageExtController = TextEditingController();
  final TextEditingController _fraisCarburantController = TextEditingController();
  final TextEditingController _fraisRayuresController = TextEditingController();

  // Variables pour les cases à cocher
  bool _includeNettoyageInt = false;
  bool _includeNettoyageExt = false;
  bool _includeCarburant = false;
  bool _includeRayures = false;
  bool _includeCoutTotalTheorique = false;
  bool _includeCaution = false;
  bool _includeCoutKmSupp = false;

  // Total calculé
  double _total = 0.0;

  @override
  void initState() {
    super.initState();
    // Initialiser les contrôleurs avec les données existantes si disponibles
    _coutTotalTheoriqueController.text = widget.data['coutTotalTheorique']?.toString() ?? '0';
    _cautionController.text = widget.data['caution']?.toString() ?? '0';
    _coutKmSuppController.text = widget.data['coutKmSupplementaires']?.toString() ?? '0';
    _fraisNettoyageIntController.text = widget.data['fraisNettoyageInterieur']?.toString() ?? '0';
    _fraisNettoyageExtController.text = widget.data['fraisNettoyageExterieur']?.toString() ?? '0';
    _fraisCarburantController.text = widget.data['fraisCarburantManquant']?.toString() ?? '0';
    _fraisRayuresController.text = widget.data['fraisRayuresDommages']?.toString() ?? '0';

    // Initialiser les cases à cocher
    _includeNettoyageInt = widget.data['includeNettoyageInterieur'] ?? false;
    _includeNettoyageExt = widget.data['includeNettoyageExterieur'] ?? false;
    _includeCarburant = widget.data['includeCarburantManquant'] ?? false;
    _includeRayures = widget.data['includeRayuresDommages'] ?? false;
    _includeCoutTotalTheorique = widget.data['includeCoutTotalTheorique'] ?? false;
    _includeCaution = widget.data['includeCaution'] ?? false;
    _includeCoutKmSupp = widget.data['includeCoutKmSupp'] ?? false;

    // Récupérer les données de nettoyage, carburant et rayures du contrat si disponibles
    if (widget.data['nettoyageInt'] != null && widget.data['nettoyageInt'].toString().isNotEmpty) {
      _fraisNettoyageIntController.text = widget.data['nettoyageInt'].toString();
    }
    if (widget.data['nettoyageExt'] != null && widget.data['nettoyageExt'].toString().isNotEmpty) {
      _fraisNettoyageExtController.text = widget.data['nettoyageExt'].toString();
    }
    if (widget.data['carburantManquant'] != null && widget.data['carburantManquant'].toString().isNotEmpty) {
      _fraisCarburantController.text = widget.data['carburantManquant'].toString();
    }
    if (widget.data['prixRayures'] != null && widget.data['prixRayures'].toString().isNotEmpty) {
      _fraisRayuresController.text = widget.data['prixRayures'].toString();
    }

    // Calculer le total initial sans notifier le parent
    _calculerTotalSansNotification();
    
    // Utiliser Future.microtask pour notifier le parent après la construction initiale
    Future.microtask(() {
      _notifierParent();
    });
  }
  
  // Méthode pour calculer le total sans notifier le parent
  void _calculerTotalSansNotification() {
    double total = 0.0;
    
    // Ajouter coût théorique si la case est cochée
    if (_includeCoutTotalTheorique) {
      total += double.tryParse(_coutTotalTheoriqueController.text) ?? 0.0;
    }
    
    // Ajouter caution si la case est cochée
    if (_includeCaution) {
      total += double.tryParse(_cautionController.text) ?? 0.0;
    }
    
    // Ajouter coût km supplémentaires si la case est cochée
    if (_includeCoutKmSupp) {
      total += double.tryParse(_coutKmSuppController.text) ?? 0.0;
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
  
  // Méthode pour notifier le parent des changements
  void _notifierParent() {
    // Préparer les données à envoyer au parent
    final updatedFrais = {
      'coutTotalTheorique': double.tryParse(_coutTotalTheoriqueController.text) ?? 0.0,
      'caution': double.tryParse(_cautionController.text) ?? 0.0,
      'coutKmSupplementaires': double.tryParse(_coutKmSuppController.text) ?? 0.0,
      'fraisNettoyageInterieur': double.tryParse(_fraisNettoyageIntController.text) ?? 0.0,
      'fraisNettoyageExterieur': double.tryParse(_fraisNettoyageExtController.text) ?? 0.0,
      'fraisCarburantManquant': double.tryParse(_fraisCarburantController.text) ?? 0.0,
      'fraisRayuresDommages': double.tryParse(_fraisRayuresController.text) ?? 0.0,
      'includeNettoyageInterieur': _includeNettoyageInt,
      'includeNettoyageExterieur': _includeNettoyageExt,
      'includeCarburantManquant': _includeCarburant,
      'includeRayuresDommages': _includeRayures,
      'includeCoutTotalTheorique': _includeCoutTotalTheorique,
      'includeCaution': _includeCaution,
      'includeCoutKmSupp': _includeCoutKmSupp,
      'totalFrais': _total,
      // Ajouter les champs pour le PDF
      'nettoyageInt': _includeNettoyageInt ? _fraisNettoyageIntController.text : '',
      'nettoyageExt': _includeNettoyageExt ? _fraisNettoyageExtController.text : '',
      'carburantManquant': _includeCarburant ? _fraisCarburantController.text : '',
      'prixRayures': _includeRayures ? _fraisRayuresController.text : '',
    };
    
    widget.onFraisUpdated(updatedFrais);
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
            const Text(
              "Frais supplémentaires",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            
            // Coût total théorique
            _buildCheckboxField(
              controller: _coutTotalTheoriqueController,
              label: "Coût total théorique",
              value: _includeCoutTotalTheorique,
              onChanged: (value) {
                setState(() {
                  _includeCoutTotalTheorique = value ?? false;
                  _calculerTotal();
                });
              },
              onTextChanged: (_) => _calculerTotal(),
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
              controller: _coutKmSuppController,
              label: "Coût total km supplémentaires",
              value: _includeCoutKmSupp,
              onChanged: (value) {
                setState(() {
                  _includeCoutKmSupp = value ?? false;
                  _calculerTotal();
                });
              },
              onTextChanged: (_) => _calculerTotal(),
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
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("Annuler"),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    _calculerTotal(); // Recalculer une dernière fois
                    Navigator.of(context).pop(true); // Fermer avec confirmation
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF08004D),
                  ),
                  child: const Text(
                    "Confirmer",
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
        ),
      );
    },
  );
}
