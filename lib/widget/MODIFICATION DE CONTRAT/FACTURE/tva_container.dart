import 'package:flutter/material.dart';

class TVAContainer extends StatefulWidget {
  final Function(String) onTVATypeChanged;

  const TVAContainer({
    Key? key,
    required this.onTVATypeChanged,
  }) : super(key: key);

  @override
  State<TVAContainer> createState() => _TVAContainerState();
}

class _TVAContainerState extends State<TVAContainer> {
  String _selectedType = 'applicable';
  final Map<String, String> _tvaTypes = {
    'applicable': 'TVA 20% incluse',
    'non_applicable': 'TVA non applicable art. 293B du CGI',
  };

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
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.account_balance_wallet, color: Colors.blue[700], size: 24),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'TVA',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF08004D),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _selectedType = 'applicable';
                            });
                            widget.onTVATypeChanged('applicable');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _selectedType == 'applicable' ? Colors.blue[50] : Colors.grey[200],
                            foregroundColor: _selectedType == 'applicable' ? Colors.blue[700] : Colors.grey[600],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Applicable'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _selectedType = 'non_applicable';
                            });
                            widget.onTVATypeChanged('non_applicable');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _selectedType == 'non_applicable' ? Colors.blue[50] : Colors.grey[200],
                            foregroundColor: _selectedType == 'non_applicable' ? Colors.blue[700] : Colors.grey[600],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Non applicable'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _tvaTypes[_selectedType]!,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
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
