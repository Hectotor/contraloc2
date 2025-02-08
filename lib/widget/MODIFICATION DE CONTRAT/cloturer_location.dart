import 'package:flutter/material.dart';

class CloturerLocationPopup extends StatelessWidget {
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;

  const CloturerLocationPopup({
    Key? key, 
    required this.onConfirm, 
    this.onCancel
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white, 
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15), 
      ),
      title: Text(
        'Clôturer la location', 
        style: TextStyle(
          color: Color(0xFF08004D),
          fontWeight: FontWeight.bold,
          fontSize: 20, 
        ),
        textAlign: TextAlign.center, 
      ),
      content: Text(
        'Êtes-vous sûr de vouloir clôturer cette location ?', 
        style: TextStyle(
          color: Colors.black87,
          fontSize: 16, 
        ),
        textAlign: TextAlign.center, 
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
                foregroundColor: Colors.grey,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: Text(
                'Annuler', 
                style: TextStyle(
                  fontSize: 16,
                ),
              ),
            ),
            SizedBox(width: 10), 
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(true);
                onConfirm();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF08004D),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Confirmer', 
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ],
      contentPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
    );
  }

  // Méthode statique pour afficher facilement la popup
  static Future<bool?> show(BuildContext context, {
    required VoidCallback onConfirm,
    VoidCallback? onCancel,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => CloturerLocationPopup(
        onConfirm: onConfirm,
        onCancel: onCancel,
      ),
    );
  }
}
