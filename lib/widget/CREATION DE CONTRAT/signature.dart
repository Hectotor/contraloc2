import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:signature/signature.dart';

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
    final controller = SignatureController(
      penStrokeWidth: 3,
      penColor: Colors.black,
      exportBackgroundColor: Colors.white,
    );

    bool accepted = true;
    
    return await showDialog<String?>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            // Variable pour suivre si une signature est présente
            bool hasSignature = controller.isNotEmpty;
            
            // Ajouter un écouteur pour mettre à jour hasSignature quand la signature change
            controller.addListener(() {
              if (hasSignature != controller.isNotEmpty) {
                setState(() {
                  hasSignature = controller.isNotEmpty;
                });
              }
            });
            
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Signature',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF08004D),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Checkbox(
                          value: accepted,
                          onChanged: (bool? value) {
                            setState(() {
                              accepted = value ?? false;
                            });
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
                              color: accepted ? Colors.black87 : Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (accepted) ...[
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
                                onPanUpdate: (_) {
                                  // Force la mise à jour de l'état quand l'utilisateur dessine
                                  if (!hasSignature) {
                                    Future.delayed(Duration.zero, () {
                                      setState(() {
                                        hasSignature = true;
                                      });
                                    });
                                  }
                                },
                                child: Signature(
                                  controller: controller,
                                  height: 200,
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
                                  controller.clear();
                                  setState(() {
                                    hasSignature = false;
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
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Text(
                            'Annuler',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: accepted && hasSignature
                              ? () async {
                                  final signatureBytes = await controller.toPngBytes();
                                  if (signatureBytes != null) {
                                    final base64Signature = base64Encode(signatureBytes);
                                    Navigator.of(context).pop(base64Signature);
                                  }
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF08004D),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          ),
                          child: Text(
                            'Valider',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
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
    bool hasName = (widget.nom != null && widget.nom!.isNotEmpty) || 
                   (widget.prenom != null && widget.prenom!.isNotEmpty);

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
