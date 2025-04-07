import 'package:flutter/material.dart';

class TotalContainer extends StatefulWidget {
  final double total;
  final VoidCallback? onTTCChanged;

  const TotalContainer({
    Key? key,
    required this.total,
    this.onTTCChanged,
  }) : super(key: key);

  @override
  State<TotalContainer> createState() => _TotalContainerState();
}

class _TotalContainerState extends State<TotalContainer> {
  bool _isTTC = false;

  @override
  void initState() {
    super.initState();
  }

  void _handleTTCChange(bool value) {
    setState(() {
      _isTTC = value;
    });
    if (widget.onTTCChanged != null) {
      widget.onTTCChanged!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Affichage du total
        Row(
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
              '${widget.total.toStringAsFixed(2).replaceAll('.', ',')}€ TTC',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF08004D),
              ),
            ),
          ],
        ),
        // Mentions TVA
        if (_isTTC)
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'TVA 20% incluse',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: Colors.grey[600],
              ),
            ),
          ),
        if (!_isTTC)
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              "TVA non applicable (art. 293 B du CGI)",
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: Colors.grey[600],
              ),
            ),
          ),
        const SizedBox(height: 24),
        // Sélecteur de TVA
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Bouton TVA applicable
            Expanded(
              child: ElevatedButton(
                onPressed: () => _handleTTCChange(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isTTC ? Colors.green[500]! : Colors.grey.shade200,
                  foregroundColor: _isTTC ? Colors.white : Colors.black87,
                  elevation: _isTTC ? 2 : 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(8),
                      bottomLeft: Radius.circular(8),
                    ),
                  ),
                ),
                child: Text(
                  'Applicable',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: _isTTC ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
            // Bouton TVA non applicable
            Expanded(
              child: ElevatedButton(
                onPressed: () => _handleTTCChange(false),
                style: ElevatedButton.styleFrom(
                  backgroundColor: !_isTTC ? Colors.green[500]! : Colors.grey.shade200,
                  foregroundColor: !_isTTC ? Colors.white : Colors.black87,
                  elevation: !_isTTC ? 2 : 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(8),
                      bottomRight: Radius.circular(8),
                    ),
                  ),
                ),
                child: Text(
                  'Non applicable',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: !_isTTC ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
