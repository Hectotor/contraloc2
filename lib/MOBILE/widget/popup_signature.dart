import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:signature/signature.dart';

/// Classe utilitaire pour afficher une popup de signature
class PopupSignature {
  /// Affiche une popup de signature et retourne la signature en base64
  /// 
  /// [context] : Le BuildContext actuel
  /// [title] : Le titre de la popup (ex: "Signature de Location" ou "Signature de Retour")
  /// [checkboxText] : Le texte à afficher à côté de la case à cocher
  /// [nom] : Le nom du client (optionnel)
  /// [prenom] : Le prénom du client (optionnel)
  /// [existingSignature] : Une signature existante en base64 (optionnel)
  /// 
  /// Retourne la signature en base64 si l'utilisateur valide, null sinon
  static Future<String?> showSignatureDialog(
    BuildContext context, {
    required String title,
    required String checkboxText,
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
                          title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF08004D),
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
                            checkboxText,
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
                          child: const Text(
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
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          ),
                          child: const Text(
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
}