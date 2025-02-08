import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:signature/signature.dart';

class SignatureWidget extends StatefulWidget {
  final String? nom;
  final String? prenom;
  final SignatureController controller;
  final ValueChanged<bool> onAcceptedChanged;
  final Function(String)? onSignatureCaptured;
  final Function(String)? onSignatureChanged;

  const SignatureWidget({
    Key? key,
    this.nom,
    this.prenom,
    required this.controller,
    required this.onAcceptedChanged,
    this.onSignatureCaptured,
    this.onSignatureChanged,
  }) : super(key: key);

  @override
  _SignatureWidgetState createState() => _SignatureWidgetState();
}

class _SignatureWidgetState extends State<SignatureWidget> {
  bool _accepted = false;
  String _base64Signature = '';

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
      setState(() {
        _base64Signature = base64Encode(signatureBytes);
      });
      
      // Appel des callbacks
      widget.onSignatureCaptured?.call(_base64Signature);
      widget.onSignatureChanged?.call(_base64Signature);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Vérifier si nom ou prénom est présent
    bool hasName = (widget.nom != null && widget.nom!.isNotEmpty) || 
                   (widget.prenom != null && widget.prenom!.isNotEmpty);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // N'afficher la case à cocher que si un nom ou prénom est présent
          if (hasName) ...[
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: Row(
                children: [
                  Checkbox(
                    value: _accepted,
                    onChanged: (bool? value) {
                      setState(() {
                        _accepted = value ?? false;
                      });
                      widget.onAcceptedChanged(_accepted);
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
                        color: _accepted ? Colors.black87 : Colors.grey,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
          if (_accepted) ...[
            Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Signature de ${widget.prenom ?? ''} ${widget.nom ?? ''}",
                      style: const TextStyle(
                        fontSize: 16, 
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF08004D),
                      ),
                    ),
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
                              controller: widget.controller,  // Utiliser le controller passé en paramètre
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
                                setState(() {
                                  _base64Signature = '';
                                });
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
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
