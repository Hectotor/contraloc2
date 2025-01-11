import 'package:flutter/material.dart';
import 'package:signature/signature.dart';

class SignatureRetourWidget extends StatefulWidget {
  final String? nom;
  final String? prenom;
  final SignatureController controller;
  final bool accepted;
  final ValueChanged<bool> onRetourAcceptedChanged;

  const SignatureRetourWidget({
    Key? key,
    this.nom,
    this.prenom,
    required this.controller,
    required this.accepted,
    required this.onRetourAcceptedChanged,
  }) : super(key: key);

  @override
  _SignatureRetourWidgetState createState() => _SignatureRetourWidgetState();
}

class _SignatureRetourWidgetState extends State<SignatureRetourWidget> {
  bool _acceptedRetour = false;

  @override
  Widget build(BuildContext context) {
    if (widget.nom == null ||
        widget.prenom == null ||
        widget.nom!.isEmpty ||
        widget.prenom!.isEmpty) {
      return const SizedBox.shrink();
    }

    bool showSignature = _acceptedRetour;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                "En cochant cette case, je reconnais avoir restitué le véhicule dans l'état convenu et conformément aux termes du contrat de location.",
                style: TextStyle(
                  color: _acceptedRetour ? Colors.black : Colors.grey,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
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
                  color: _acceptedRetour ? Colors.black : Colors.grey,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
