import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import '../popup_signature.dart';

/// Widget pour afficher et capturer une signature
class SignatureWidget extends StatefulWidget {
  final String? nom;
  final String? prenom;
  final SignatureController controller;
  final bool accepted;
  final ValueChanged<bool> onAcceptedChanged;
  final Function(String)? onSignatureChanged;
  final Function(bool)? onSigningStatusChanged;

  const SignatureWidget({
    Key? key,
    this.nom,
    this.prenom,
    required this.controller,
    required this.accepted,
    required this.onAcceptedChanged,
    this.onSignatureChanged,
    this.onSigningStatusChanged,
  }) : super(key: key);

  /// Affiche le widget de signature dans une popup
  /// Retourne la signature en base64 si l'utilisateur valide, null sinon
  static Future<String?> showSignatureDialog(
    BuildContext context, {
    String? nom,
    String? prenom,
    String? existingSignature,
  }) async {
    // Rediriger vers la nouvelle implémentation dans PopupSignature
    return PopupSignature.showSignatureDialog(
      context,
      title: 'Signature du contrat',
      checkboxText: 'Je reconnais avoir pris connaissance des termes et conditions de location.',
      nom: nom,
      prenom: prenom,
      existingSignature: existingSignature,
    );
  }

  @override
  _SignatureWidgetState createState() => _SignatureWidgetState();
}

class _SignatureWidgetState extends State<SignatureWidget> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(() {
      if (widget.controller.isNotEmpty) {
        _captureSignature();
      }
    });
  }

  Future<void> _captureSignature() async {
    final signatureBytes = await widget.controller.toPngBytes();
    if (signatureBytes != null) {
      final base64Signature = base64Encode(signatureBytes);
      widget.onSignatureChanged?.call(base64Signature);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Vérifier si au moins le nom OU le prénom est présent
    bool hasClientInfo = (widget.nom != null && widget.nom!.isNotEmpty) || 
                         (widget.prenom != null && widget.prenom!.isNotEmpty);
    
    // Si nom ET prénom sont vides, ne rien afficher
    if (!hasClientInfo) {
      return const SizedBox.shrink();
    }
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Signature de Location',
            style: TextStyle(
              fontSize: 16, 
              fontWeight: FontWeight.bold,
              color: const Color(0xFF08004D),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Checkbox(
                value: widget.accepted,
                onChanged: (bool? value) {
                  widget.onAcceptedChanged(value ?? false);
                },
                activeColor: const Color(0xFF08004D),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              Expanded(
                child: Text(
                  "Je reconnais avoir pris connaissance des termes et conditions de location.",
                  style: TextStyle(
                    color: widget.accepted ? Colors.black87 : Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          if (widget.accepted) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.grey.shade300, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade200,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(13),
                    child: GestureDetector(
                      onPanStart: (_) => widget.onSigningStatusChanged?.call(true),
                      onPanEnd: (_) => widget.onSigningStatusChanged?.call(false),
                      child: Signature(
                        controller: widget.controller,
                        height: 250,
                        backgroundColor: Colors.white,
                        width: double.infinity,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 5,
                    right: 5,
                    child: GestureDetector(
                      onTap: () {
                        widget.controller.clear();
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.7),
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(4),
                        child: const Icon(
                          Icons.close, 
                          color: Colors.white, 
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
