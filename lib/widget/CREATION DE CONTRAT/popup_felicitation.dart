import 'package:flutter/material.dart';
import 'package:ContraLoc/widget/navigation.dart';

class Popup {
  static Future<void> showSuccess(BuildContext context, {String? email}) {
    return showDialog(
      context: context,
      barrierDismissible: false, // Empêche la fermeture en cliquant à l'extérieur
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Félicitations",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF08004D),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Votre contrat a bien été enregistré !",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (email != null && email.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text(
                    "Un exemplaire a été envoyé au client",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.green,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      // Fermer le popup
                      Navigator.of(context).pop();
                      
                      // Attendre un court instant pour éviter les conflits de navigation
                      await Future.delayed(const Duration(milliseconds: 100));
                      
                      // Naviguer vers NavigationPage avec l'onglet Contrats sélectionné
                      if (context.mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const NavigationPage(
                              initialTab: 1, // 1 correspond à l'onglet Contrats
                            ),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF08004D),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      "OK",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
