import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  late TextEditingController _cautionController;
  late TextEditingController _fraisNettoyageIntController;
  late TextEditingController _fraisNettoyageExtController;
  late TextEditingController _fraisCarburantController;
  late TextEditingController _fraisRayuresController;
  late TextEditingController _fraisAutreController;

  // Contrôleurs spécifiques pour les champs calculés automatiquement
  late TextEditingController _kmSuppDisplayController;
  late TextEditingController _coutTotalController;

  // Type de paiement
  String _typePaiement = 'Carte bancaire';
  final List<String> _typesPaiement = ['Carte bancaire', 'Espèces', 'Virement'];

  // Total calculé
  double _total = 0.0;
  
  // Méthode pour notifier le parent des changements
  void _notifierParent() {
    // Préparer les données à envoyer au parent
    Map<String, dynamic> frais = {
      'facturePrixLocation': _coutTotalController.text,
      'factureCaution': _cautionController.text,
      'factureCoutKmSupplementaires': _kmSuppDisplayController.text,
      'factureFraisNettoyageInterieur': _fraisNettoyageIntController.text,
      'factureFraisNettoyageExterieur': _fraisNettoyageExtController.text,
      'factureFraisCarburantManquant': _fraisCarburantController.text,
      'factureFraisRayuresDommages': _fraisRayuresController.text,
      'factureFraisAutre': _fraisAutreController.text,
      'factureTypePaiement': _total > 0 ? _typePaiement : '',
      'factureTotalFrais': _total.toStringAsFixed(2).replaceAll('.', ','),
    };
    
    // Notifier le parent des changements
    widget.onFraisUpdated(frais);
  }

  @override
  void initState() {
    super.initState();
    // Initialiser les contrôleurs avec des valeurs par défaut à 0
    _kmSuppDisplayController = TextEditingController(text: "0");
    _coutTotalController = TextEditingController(text: "0");
    _cautionController = TextEditingController(text: "0");
    _fraisNettoyageIntController = TextEditingController(text: "0");
    _fraisNettoyageExtController = TextEditingController(text: "0");
    _fraisCarburantController = TextEditingController(text: "0");
    _fraisRayuresController = TextEditingController(text: "0");
    _fraisAutreController = TextEditingController(text: "0");
    
    // Charger les valeurs existantes depuis widget.data
    if (widget.data.isNotEmpty) {
      // Charger les valeurs de base
      _cautionController.text = widget.data['factureCaution']?.toString() ?? "0";
      _fraisNettoyageIntController.text = widget.data['factureFraisNettoyageInterieur']?.toString() ?? "0";
      _fraisNettoyageExtController.text = widget.data['factureFraisNettoyageExterieur']?.toString() ?? "0";
      _fraisCarburantController.text = widget.data['factureFraisCarburantManquant']?.toString() ?? "0";
      _fraisRayuresController.text = widget.data['factureFraisRayuresDommages']?.toString() ?? "0";
      _fraisAutreController.text = widget.data['factureFraisAutre']?.toString() ?? "0";
      _coutTotalController.text = widget.data['facturePrixLocation']?.toString() ?? "0";
      
      // Charger le type de paiement s'il existe
      if (widget.data['factureTypePaiement'] != null && _typesPaiement.contains(widget.data['factureTypePaiement'])) {
        _typePaiement = widget.data['factureTypePaiement'];
      }
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
    
    // Ajouter tous les frais automatiquement sans vérifier les cases à cocher
    try { total += double.tryParse(_coutTotalController.text.replaceAll(',', '.')) ?? 0.0; } catch(_) {}
    try { total += double.tryParse(_cautionController.text.replaceAll(',', '.')) ?? 0.0; } catch(_) {}
    try { total += double.tryParse(_kmSuppDisplayController.text.replaceAll(',', '.')) ?? 0.0; } catch(_) {}
    try { total += double.tryParse(_fraisNettoyageIntController.text.replaceAll(',', '.')) ?? 0.0; } catch(_) {}
    try { total += double.tryParse(_fraisNettoyageExtController.text.replaceAll(',', '.')) ?? 0.0; } catch(_) {}
    try { total += double.tryParse(_fraisCarburantController.text.replaceAll(',', '.')) ?? 0.0; } catch(_) {}
    try { total += double.tryParse(_fraisRayuresController.text.replaceAll(',', '.')) ?? 0.0; } catch(_) {}
    try { total += double.tryParse(_fraisAutreController.text.replaceAll(',', '.')) ?? 0.0; } catch(_) {}
    
    // Mettre à jour le total
    setState(() {
      _total = total;
    });
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
            
            // Type de paiement
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Type de paiement", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _typePaiement,
                      items: _typesPaiement.map((String type) {
                        return DropdownMenuItem<String>(
                          value: type,
                          child: Text(type),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _typePaiement = newValue;
                          });
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Coût total
            _buildTextField(
              controller: _coutTotalController,
              label: "Prix de la location",
              onTextChanged: (_) => _calculerTotalSansNotification(),
              readOnly: false, // Permettre la modification manuelle
            ),
            const SizedBox(height: 10),
            
            // Caution
            _buildTextField(
              controller: _cautionController,
              label: "Caution",
              onTextChanged: (_) => _calculerTotalSansNotification(),
            ),
            const SizedBox(height: 10),
            
            // Coût kilomètres supplémentaires
            _buildTextField(
              controller: _kmSuppDisplayController,
              label: "Frais des kilomètres supplémentaires",
              onTextChanged: (_) => _calculerTotalSansNotification(),
            ),
            const SizedBox(height: 10),
            
            _buildTextField(
              controller: _fraisNettoyageIntController,
              label: "Frais de nettoyage intérieur",
              onTextChanged: (_) => _calculerTotalSansNotification(),
            ),
            const SizedBox(height: 10),
            
            _buildTextField(
              controller: _fraisNettoyageExtController,
              label: "Frais de nettoyage extérieur",
              onTextChanged: (_) => _calculerTotalSansNotification(),
            ),
            const SizedBox(height: 10),
            
            _buildTextField(
              controller: _fraisCarburantController,
              label: "Frais de carburant manquant",
              onTextChanged: (_) => _calculerTotalSansNotification(),
            ),
            const SizedBox(height: 10),
            
            _buildTextField(
              controller: _fraisRayuresController,
              label: "Frais de rayures/dommages",
              onTextChanged: (_) => _calculerTotalSansNotification(),
            ),
            const SizedBox(height: 10),
            
            _buildTextField(
              controller: _fraisAutreController,
              label: "Autre",
              onTextChanged: (_) => _calculerTotalSansNotification(),
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
                    "${_total.toStringAsFixed(2).replaceAll('.', ',')} €",
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
                    _calculerTotalSansNotification(); // Recalculer une dernière fois
                    _notifierParent(); // Notifier le parent uniquement lors de la validation
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

  // Widget pour créer un champ de texte avec étiquette (sans case à cocher)
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required Function(String) onTextChanged,
    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            suffixText: "€",
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9,]')),
          ],
          onChanged: onTextChanged,
          readOnly: readOnly,
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
