import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TypeLocationContainer extends StatefulWidget {
  final String typeLocation;
  final Function(String) onTypeChanged;
  final TextEditingController prixLocationController;
  final TextEditingController accompteController;
  final Function(String) onAccompteChanged;
  final Function(String) onPaymentMethodChanged;

  const TypeLocationContainer({
    super.key,
    required this.typeLocation,
    required this.onTypeChanged,
    required this.prixLocationController,
    required this.accompteController,
    required this.onAccompteChanged,
    required this.onPaymentMethodChanged,
  });

  static Widget buildPrixLocationField(TextEditingController controller) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: 'Prix de location en €',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        suffixText: '€',
        prefixIcon: Icon(Icons.monetization_on),
      ),
      keyboardType: TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')), // Accepte uniquement des chiffres et une virgule avec maximum 2 décimales
      ],
    );
  }

  static Widget buildAccompteField(TextEditingController controller) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: 'Montant de l\'acompte en €',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        suffixText: '€',
        prefixIcon: Icon(Icons.account_balance_wallet),
      ),
      keyboardType: TextInputType.number,
    );
  }

  @override
  State<TypeLocationContainer> createState() => _TypeLocationContainerState();
}

class _TypeLocationContainerState extends State<TypeLocationContainer> {
  String _selectedType = '';
  bool _showContent = true;
  String _selectedPaymentMethod = 'Espèces';

  @override
  void initState() {
    super.initState();
    _selectedType = widget.typeLocation;
  }

  @override
  void didUpdateWidget(TypeLocationContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.typeLocation != widget.typeLocation) {
      setState(() {
        _selectedType = widget.typeLocation;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.20),
            blurRadius: 4,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête de la carte avec flèche
            GestureDetector(
              onTap: () {
                setState(() {
                  _showContent = !_showContent;
                });
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF08004D).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(Icons.category, color: const Color(0xFF08004D), size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Type de location",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF08004D),
                        ),
                      ),
                    ),
                    Icon(
                      _showContent ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      color: const Color(0xFF08004D),
                    ),
                  ],
                ),
              ),
            ),
            // Contenu de la carte
            if (_showContent)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Type de location',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF08004D),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _selectedType = 'Gratuite';
                                widget.onTypeChanged('Gratuite');
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _selectedType == 'Gratuite' ? const Color(0xFF08004D) : Colors.white,
                              foregroundColor: _selectedType == 'Gratuite' ? Colors.white : const Color(0xFF08004D),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: _selectedType == 'Gratuite' ? const Color(0xFF08004D) : Colors.grey[300]!,
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.free_breakfast, size: 20),
                                const SizedBox(width: 8),
                                const Text('Gratuite'),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _selectedType = 'Payante';
                                widget.onTypeChanged('Payante');
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _selectedType == 'Payante' ? const Color(0xFF08004D) : Colors.white,
                              foregroundColor: _selectedType == 'Payante' ? Colors.white : const Color(0xFF08004D),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: _selectedType == 'Payante' ? const Color(0xFF08004D) : Colors.grey[300]!,
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.attach_money, size: 20),
                                const SizedBox(width: 8),
                                const Text('Payante'),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Prix de location et acompte
                    if (_selectedType == 'Payante') ...[
                      TypeLocationContainer.buildPrixLocationField(widget.prixLocationController),
                      const SizedBox(height: 16),
                      TypeLocationContainer.buildAccompteField(widget.accompteController),
                      const SizedBox(height: 16),
                    ],

                    // Méthode de paiement
                    if (_selectedType == 'Payante') ...[
                      Text(
                        'Méthode de paiement',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF08004D),
                        ),
                      ),
                      const SizedBox(height: 8),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          return Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      _selectedPaymentMethod = 'Espèces';
                                      widget.onPaymentMethodChanged('Espèces');
                                    });
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _selectedPaymentMethod == 'Espèces' ? const Color(0xFF08004D) : Colors.white,
                                    foregroundColor: _selectedPaymentMethod == 'Espèces' ? Colors.white : const Color(0xFF08004D),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      side: BorderSide(
                                        color: _selectedPaymentMethod == 'Espèces' ? const Color(0xFF08004D) : Colors.grey[300]!,
                                      ),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                    minimumSize: const Size(0, 32),
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.money, size: 16),
                                      const SizedBox(width: 4),
                                      const Text('Espèces', style: TextStyle(fontSize: 12)),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      _selectedPaymentMethod = 'Carte bancaire';
                                      widget.onPaymentMethodChanged('Carte bancaire');
                                    });
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _selectedPaymentMethod == 'Carte bancaire' ? const Color(0xFF08004D) : Colors.white,
                                    foregroundColor: _selectedPaymentMethod == 'Carte bancaire' ? Colors.white : const Color(0xFF08004D),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      side: BorderSide(
                                        color: _selectedPaymentMethod == 'Carte bancaire' ? const Color(0xFF08004D) : Colors.grey[300]!,
                                      ),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                    minimumSize: const Size(0, 32),
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.credit_card, size: 16),
                                      const SizedBox(width: 4),
                                      const Text('Carte', style: TextStyle(fontSize: 12)),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      _selectedPaymentMethod = 'Virement';
                                      widget.onPaymentMethodChanged('Virement');
                                    });
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _selectedPaymentMethod == 'Virement' ? const Color(0xFF08004D) : Colors.white,
                                    foregroundColor: _selectedPaymentMethod == 'Virement' ? Colors.white : const Color(0xFF08004D),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      side: BorderSide(
                                        color: _selectedPaymentMethod == 'Virement' ? const Color(0xFF08004D) : Colors.grey[300]!,
                                      ),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                    minimumSize: const Size(0, 32),
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.swap_horiz, size: 16),
                                      const SizedBox(width: 4),
                                      const Text('Virement', style: TextStyle(fontSize: 12)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
