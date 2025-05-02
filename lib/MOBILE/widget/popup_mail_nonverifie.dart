import 'package:flutter/material.dart';

class PopupMailNonVerifie {
  /// Affiche un dialogue pour informer que l'email n'est pas vérifié
  static void afficher({
    required BuildContext context,
    String titre = "Email non vérifié",
    String message = "Votre email n'est pas encore vérifié.\nVeuillez cliquer sur le lien dans l'email de confirmation pour activer votre compte.",
    String texteBouton = "J'ai compris",
    VoidCallback? onPressed,
    Future<void> Function()? onResendEmail,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _PopupMailNonVerifieDialog(
        titre: titre,
        message: message,
        texteBouton: texteBouton,
        onPressed: onPressed,
        onResendEmail: onResendEmail,
      ),
    );
  }
}

class _PopupMailNonVerifieDialog extends StatefulWidget {
  final String titre;
  final String message;
  final String texteBouton;
  final VoidCallback? onPressed;
  final Future<void> Function()? onResendEmail;

  const _PopupMailNonVerifieDialog({
    Key? key,
    required this.titre,
    required this.message,
    required this.texteBouton,
    this.onPressed,
    this.onResendEmail,
  }) : super(key: key);

  @override
  State<_PopupMailNonVerifieDialog> createState() => _PopupMailNonVerifieDialogState();
}

class _PopupMailNonVerifieDialogState extends State<_PopupMailNonVerifieDialog> {
  bool emailResent = false;
  bool loading = false;

  @override
  Widget build(BuildContext context) {
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
            const Icon(
              Icons.mark_email_unread,
              color: Color(0xFF0F056B),
              size: 60,
            ),
            const SizedBox(height: 20),
            Text(
              widget.titre,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F056B),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              widget.message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            if (widget.onResendEmail != null) ...[
              if (emailResent)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    "Email de vérification renvoyé.",
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: loading
                      ? null
                      : () async {
                          setState(() => loading = true);
                          await widget.onResendEmail!();
                          setState(() {
                            emailResent = true;
                            loading = false;
                          });
                        },
                  icon: loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh, color: Color(0xFF0F056B)),
                  label: Text(
                    "Renvoyer l'email de vérification",
                    style: const TextStyle(color: Color(0xFF0F056B)),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF0F056B)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: widget.onPressed ?? () {
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F056B),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  widget.texteBouton,
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
    );
  }
}
