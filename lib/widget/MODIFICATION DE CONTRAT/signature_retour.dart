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
  final Function(String)? onSignatureChanged;

  const SignatureRetourWidget({
    Key? key,
    this.nom,
    this.prenom,
    required this.controller,
    required this.accepted,
    required this.onRetourAcceptedChanged,
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
  State<SignatureRetourWidget> createState() => _SignatureRetourWidgetState();
}

class _SignatureRetourWidgetState extends State<SignatureRetourWidget> {
  String? _currentSignature;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_captureSignature);
  }

  void _captureSignature() {
    if (widget.controller.isNotEmpty) {
      widget.controller.toPngBytes().then((bytes) {
        if (bytes != null) {
          final base64 = base64Encode(bytes);
          setState(() {
            _currentSignature = base64;
          });
          if (widget.onSignatureChanged != null) {
            widget.onSignatureChanged!(base64);
          }
        }
      });
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête de section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF08004D).withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.draw_rounded,
                  color: Color(0xFF08004D),
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Signature de Retour',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF08004D),
                  ),
                ),
              ],
            ),
          ),
          // Contenu de la section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Afficher le nom et prénom
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.person,
                        color: Color(0xFF08004D),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Client: ${widget.prenom ?? ''} ${widget.nom ?? ''}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF08004D),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Checkbox de confirmation
                Container(
                  decoration: BoxDecoration(
                    color: widget.accepted ? Colors.green.withOpacity(0.05) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: widget.accepted 
                        ? Border.all(color: Colors.green.shade300)
                        : null,
                  ),
                  child: Row(
                    children: [
                      Transform.scale(
                        scale: 1.1,
                        child: Checkbox(
                          value: widget.accepted,
                          onChanged: (bool? value) {
                            widget.onRetourAcceptedChanged(value ?? false);
                          },
                          activeColor: const Color(0xFF08004D),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Je confirme la signature de retour',
                          style: TextStyle(
                            color: widget.accepted ? Colors.black87 : Colors.grey,
                            fontSize: 15,
                            fontWeight: widget.accepted ? FontWeight.w500 : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.accepted) ...[                  
                  const SizedBox(height: 16),
                  // Affichage de la signature ou du bouton pour signer
                  if (_currentSignature != null) ...[                    
                    // Affichage de la signature existante
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
                            child: Image.memory(
                              base64Decode(_currentSignature!),
                              width: double.infinity,
                              height: 200,
                              fit: BoxFit.contain,
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _currentSignature = null;
                                  widget.controller.clear();
                                  if (widget.onSignatureChanged != null) {
                                    widget.onSignatureChanged!('');
                                  }
                                });
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.8),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      spreadRadius: 1,
                                      blurRadius: 3,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(6),
                                child: const Icon(
                                  Icons.close, 
                                  color: Colors.white, 
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[                    
                    // Bouton pour ouvrir la popup de signature
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final signature = await PopupSignature.showSignatureDialog(
                            context,
                            title: 'Signature de Retour',
                            checkboxText: 'Je confirme la signature de retour',
                            nom: widget.nom,
                            prenom: widget.prenom,
                          );
                          
                          if (signature != null) {
                            setState(() {
                              _currentSignature = signature;
                            });
                            
                            if (widget.onSignatureChanged != null) {
                              widget.onSignatureChanged!(signature);
                            }
                          }
                        },
                        icon: const Icon(Icons.draw, color: Colors.white),
                        label: const Text(
                          'Signer le retour',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF08004D),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
