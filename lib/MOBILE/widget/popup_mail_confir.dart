import 'package:flutter/material.dart';

class PopupMailConfirmation {
  /// Affiche un dialogue de confirmation d'envoi d'email
  /// 
  /// [context] : Le contexte de l'application
  /// [titre] : Le titre du dialogue (par défaut "Inscription réussie !")
  /// [message] : Le message à afficher (par défaut un message de confirmation d'email)
  /// [texteBouton] : Le texte du bouton (par défaut "Compris")
  /// [onPressed] : Action à effectuer lorsque le bouton est pressé (par défaut ferme le dialogue)
  static void afficher({
    required BuildContext context,
    String titre = "Inscription réussie !",
    String message = "Un email de confirmation a été envoyé.\nVeuillez vérifier votre boîte de réception pour activer votre compte.",
    String texteBouton = "Compris",
    VoidCallback? onPressed,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.mark_email_read,
                color: Color(0xFF0F056B),
                size: 60,
              ),
              const SizedBox(height: 20),
              Text(
                titre,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F056B),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onPressed ?? () {
                    Navigator.of(context).pop(); // Ferme le popup
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F056B),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    texteBouton,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
