import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:signature/signature.dart';

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
            'Signature de Location',
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
