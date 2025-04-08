import 'package:flutter/material.dart';

class TypePaiementContainer extends StatefulWidget {
  final String selectedType;
  final Function(String) onTypePaiementChanged;

  const TypePaiementContainer({
    Key? key,
    required this.selectedType,
    required this.onTypePaiementChanged,
  }) : super(key: key);

  @override
  State<TypePaiementContainer> createState() => _TypePaiementContainerState();
}

class _TypePaiementContainerState extends State<TypePaiementContainer> {
  String _selectedType = '';
  bool _showContent = true;
  final Map<String, IconData> _paymentTypes = {
    'Carte': Icons.credit_card,
    'Espèces': Icons.money,
    'Virement': Icons.account_balance_wallet,
  };

  @override
  void initState() {
    super.initState();
    _selectedType = widget.selectedType;
  }

  @override
  void didUpdateWidget(TypePaiementContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedType != widget.selectedType) {
      setState(() {
        _selectedType = widget.selectedType;
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
            GestureDetector(
              onTap: () {
                setState(() {
                  _showContent = !_showContent;
                });
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(Icons.payment, color: Colors.green[700], size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Type de paiement",
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
            if (_showContent)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _paymentTypes.entries.map((entry) {
                    final type = entry.key;
                    final icon = entry.value;
                    return ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _selectedType = type;
                        });
                        widget.onTypePaiementChanged(type);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _selectedType == type ? Colors.green : Colors.white,
                        foregroundColor: _selectedType == type ? Colors.white : Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                            color: _selectedType == type ? Colors.green : Colors.grey[300]!,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        minimumSize: const Size(0, 40),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(icon, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            type,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
