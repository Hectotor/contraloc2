import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FactureScreen extends StatefulWidget {
  final Map<String, dynamic> data;
  final Function(Map<String, dynamic>) onFraisUpdated;
  final double kilometrageInitial;
  final double kilometrageActuel;
  final double tarifKilometrique;
  final String dateFinEffective;

  const FactureScreen({
    Key? key,
    required this.data,
    required this.onFraisUpdated,
    required this.kilometrageInitial,
    required this.kilometrageActuel,
    required this.tarifKilometrique,
    required this.dateFinEffective,
  }) : super(key: key);

  @override
  State<FactureScreen> createState() => _FactureScreenState();
}

class _FactureScreenState extends State<FactureScreen> {
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
    _cautionController.dispose();
    _fraisNettoyageIntController.dispose();
    _fraisNettoyageExtController.dispose();
    _fraisCarburantController.dispose();
    _fraisRayuresController.dispose();
    _fraisAutreController.dispose();
    super.dispose();
  }

  // Méthode pour notifier le parent des changements
  void _notifierParent() {
    Map<String, dynamic> frais = {
      'facturePrixLocation': _coutTotalController.text,
      'factureCaution': _cautionController.text,
      'factureCoutKmSupplementaires': _kmSuppDisplayController.text,
      'factureFraisNettoyageInterieur': _fraisNettoyageIntController.text,
      'factureFraisNettoyageExterieur': _fraisNettoyageExtController.text,
      'factureFraisCarburantManquant': _fraisCarburantController.text,
      'factureFraisRayuresDommages': _fraisRayuresController.text,
      'factureFraisAutre': _fraisAutreController.text,
      'factureTotalFrais': _total.toStringAsFixed(2).replaceAll('.', ','),
      'factureTypePaiement': _typePaiement,
    };

    widget.onFraisUpdated(frais);
    Navigator.pop(context);
  }

  // Calculer le total des frais
  void _calculerTotal() {
    setState(() {
      double total = 0.0;
      
      // Ajouter tous les frais qui ont une valeur non nulle
      total += double.tryParse(_coutTotalController.text.replaceAll(',', '.')) ?? 0.0;
      total += double.tryParse(_kmSuppDisplayController.text.replaceAll(',', '.')) ?? 0.0;
      total += double.tryParse(_fraisNettoyageIntController.text.replaceAll(',', '.')) ?? 0.0;
      total += double.tryParse(_fraisNettoyageExtController.text.replaceAll(',', '.')) ?? 0.0;
      total += double.tryParse(_fraisCarburantController.text.replaceAll(',', '.')) ?? 0.0;
      total += double.tryParse(_fraisRayuresController.text.replaceAll(',', '.')) ?? 0.0;
      total += double.tryParse(_fraisAutreController.text.replaceAll(',', '.')) ?? 0.0;
      total += double.tryParse(_cautionController.text.replaceAll(',', '.')) ?? 0.0;
      
      _total = total;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
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
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // En-tête avec description
                  _buildHeader(),
                  const SizedBox(height: 24),
                  
                  // Section des frais principaux
                  _buildSection(
                    title: "Frais principaux",
                    icon: Icons.attach_money,
                    color: Colors.green[700]!,
                    children: [
                      _buildTextField("Prix de location", _coutTotalController),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Section des frais kilométriques
                  _buildSection(
                    title: "Frais kilométriques",
                    icon: Icons.directions_car,
                    color: Colors.blue[700]!,
                    children: [
                      _buildTextField("Frais kilométriques", _kmSuppDisplayController),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Section des frais additionnels
                  _buildSection(
                    title: "Frais additionnels",
                    icon: Icons.add_circle_outline,
                    color: Colors.orange[700]!,
                    children: [
                      _buildTextField("Frais nettoyage intérieur", _fraisNettoyageIntController),
                      _buildTextField("Frais nettoyage extérieur", _fraisNettoyageExtController),
                      _buildTextField("Frais carburant manquant", _fraisCarburantController),
                      _buildTextField("Frais rayures/dommages", _fraisRayuresController),
                      _buildTextField("Frais autres", _fraisAutreController),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Section de la caution
                  _buildSection(
                    title: "Caution",
                    icon: Icons.security,
                    color: Colors.blue[700]!,
                    children: [
                      _buildTextField("Frais caution", _cautionController),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Section du type de paiement
                  _buildSection(
                    title: "Type de paiement",
                    icon: Icons.payment,
                    color: Colors.purple[700]!,
                    children: [
                      DropdownButtonFormField<String>(
                        value: _typePaiement,
                        decoration: InputDecoration(
                          labelText: "Type de paiement",
                          labelStyle: const TextStyle(color: Color(0xFF08004D)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        items: _typesPaiement.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _typePaiement = newValue ?? 'Carte bancaire';
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Section du total
                  _buildSection(
                    title: "Total",
                    icon: Icons.attach_money,
                    color: Colors.green[700]!,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${_total.toStringAsFixed(2).replaceAll('.', ',')} €',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.green[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Bouton de validation
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 40),
                    child: ElevatedButton(
                      onPressed: _notifierParent,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF08004D),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: const Text(
                        'Valider',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Gestion de la facture',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF08004D),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Saisissez les éléments pour générer la facture',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête de section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          // Contenu de la section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Color(0xFF08004D)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          prefixText: '€',
        ),
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
        ],
        onChanged: (value) {
          _calculerTotal();
        },
      ),
    );
  }
}
