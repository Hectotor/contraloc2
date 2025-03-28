import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import '../popup_signature.dart';

class SignatureRetourWidget extends StatefulWidget {
  final String? nom;
  final String? prenom;
  final SignatureController controller;
  final bool accepted;
  final ValueChanged<bool> onRetourAcceptedChanged;
  final Function(String)? onSignatureCaptured;
  final Function(String)? onSignatureChanged;

  const SignatureRetourWidget({
    Key? key,
    this.nom,
    this.prenom,
    required this.controller,
    required this.accepted,
    required this.onRetourAcceptedChanged,
    this.onSignatureCaptured,
    this.onSignatureChanged,
  }) : super(key: key);

  /// Affiche le widget de signature de retour dans une popup
  /// Retourne la signature en base64 si l'utilisateur valide, null sinon
  static Future<String?> showSignatureRetourDialog(
    BuildContext context, {
    String? nom,
    String? prenom,
    String? existingSignature,
  }) async {
    // Rediriger vers la nouvelle implémentation dans PopupSignature
    return PopupSignature.showSignatureDialog(
      context,
      title: 'Signature de Retour',
      checkboxText: 'Je confirme la signature de retour',
      nom: nom,
      prenom: prenom,
      existingSignature: existingSignature,
    );
  }

  @override
  _SignatureRetourWidgetState createState() => _SignatureRetourWidgetState();
}

class _SignatureRetourWidgetState extends State<SignatureRetourWidget> {
  bool _acceptedRetour = false;

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
      
      // Mettre à jour l'état local
      setState(() {
      });

      // Appel des callbacks
      widget.onSignatureCaptured?.call(base64Signature);
      widget.onSignatureChanged?.call(base64Signature);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Vérifier si nom ou prénom est présent
    bool hasName = (widget.nom != null && widget.nom!.isNotEmpty) || 
                   (widget.prenom != null && widget.prenom!.isNotEmpty);

    // Si pas de nom ni de prénom, retourner un widget vide
    if (!hasName) {
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
            'Signature de Retour',
            style: TextStyle(
              fontSize: 16, 
              fontWeight: FontWeight.bold,
              color: Color(0xFF08004D),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Checkbox(
                value: _acceptedRetour,
                onChanged: (bool? value) {
                  setState(() {
                    _acceptedRetour = value ?? false;
                  });
                  widget.onRetourAcceptedChanged(_acceptedRetour);
                },
                activeColor: const Color(0xFF08004D),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              Expanded(
                child: Text(
                  'Je confirme la signature de retour',
                  style: TextStyle(
                    color: _acceptedRetour ? Colors.black87 : Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          if (_acceptedRetour) ...[
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
                    child: Signature(
                      controller: widget.controller,
                      height: 250,
                      backgroundColor: Colors.white,
                      width: double.infinity,
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
