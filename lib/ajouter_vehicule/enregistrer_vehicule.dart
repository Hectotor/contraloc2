import 'package:flutter/material.dart';
import '../widget/navigation.dart';

void showEnregistrementPopup(BuildContext context) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Votre voiture a bien été enregistrée"),
          backgroundColor: Color(0xFF006400),
          duration: Duration(seconds: 4),
        ),
      );
      Navigator.of(context).pop(); // Retourne à l'écran précédent
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const NavigationPage()),
        (route) => false,
      );
    }
  });
}
