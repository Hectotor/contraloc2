import 'package:flutter/material.dart';
import 'package:signature/signature.dart';

class SignatureWidget extends StatefulWidget {
  final String? nom;
  final String? prenom;
  final SignatureController controller;
  final ValueChanged<bool> onAcceptedChanged;

  const SignatureWidget({
    Key? key,
    this.nom,
    this.prenom,
    required this.controller,
    required this.onAcceptedChanged,
  }) : super(key: key);

  @override
  _SignatureWidgetState createState() => _SignatureWidgetState();
}

class _SignatureWidgetState extends State<SignatureWidget> {
  bool _accepted = false; // Initialisation correcte

  @override
  Widget build(BuildContext context) {
    bool showSignature = widget.nom != null &&
        widget.nom!.isNotEmpty &&
        widget.prenom != null &&
        widget.prenom!.isNotEmpty &&
        _accepted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.nom != null &&
            widget.nom!.isNotEmpty &&
            widget.prenom != null &&
            widget.prenom!.isNotEmpty) ...[
          Row(
            children: [
              Checkbox(
                value: _accepted,
                onChanged: (bool? value) {
                  setState(() {
                    _accepted = value ?? false;
                  });
                  widget.onAcceptedChanged(_accepted);
                },
                activeColor: const Color(0xFF08004D), // Bleu nuit
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "En cochant cette case, je reconnais avoir pris connaissance des termes et conditions de location.",
                  style: TextStyle(
                    color: _accepted ? Colors.black : Colors.grey,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
        if (showSignature) ...[
          const Text(
            "Signature du client",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            height: 200,
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                "${widget.nom} ${widget.prenom}",
                style: TextStyle(
                  fontFamily: 'DancingScript',
                  fontSize: 35,
                  color: _accepted ? Colors.black : Colors.grey,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
