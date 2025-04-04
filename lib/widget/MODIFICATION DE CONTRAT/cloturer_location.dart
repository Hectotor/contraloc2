import 'package:flutter/material.dart';

class CloturerLocationPopup extends StatelessWidget {
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;
  final Map<String, dynamic>? data;

  const CloturerLocationPopup({
    Key? key, 
    required this.onConfirm, 
    this.onCancel,
    this.data,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white, 
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20), 
      ),
      title: Column(
        children: [
          Icon(
            Icons.check_circle_outline,
            color: Color(0xFF08004D),
            size: 48,
          ),
          SizedBox(height: 16),
          Text(
            'Clôturer la location', 
            style: TextStyle(
              color: Color(0xFF08004D),
              fontWeight: FontWeight.bold,
              fontSize: 22, 
            ),
            textAlign: TextAlign.center, 
          ),
        ],
      ),
      content: Container(
        padding: EdgeInsets.symmetric(vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Êtes-vous sûr de vouloir clôturer cette location ?', 
              style: TextStyle(
                color: Colors.black87,
                fontSize: 16, 
                height: 1.5,
              ),
              textAlign: TextAlign.center, 
            ),
            if (data != null && data!['typeLocation']?.toString() == 'Payante') ...[  
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.amber[800]),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Après la restitution du véhicule, pensez à générer la facture pour suivre votre chiffre d'affaires.",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.amber[900],
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
                onCancel?.call();
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[700],
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              child: Text(
                'Annuler', 
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            SizedBox(width: 16), 
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(true);
                onConfirm();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF08004D),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Confirmer', 
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
      actionsPadding: EdgeInsets.only(bottom: 20, left: 20, right: 20),
      contentPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 10),
    );
  }

  // Méthode statique pour afficher facilement la popup
  static Future<bool?> show(BuildContext context, {
    required VoidCallback onConfirm,
    VoidCallback? onCancel,
    Map<String, dynamic>? data,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => CloturerLocationPopup(
        onConfirm: onConfirm,
        onCancel: onCancel,
        data: data,
      ),
    );
  }
}
