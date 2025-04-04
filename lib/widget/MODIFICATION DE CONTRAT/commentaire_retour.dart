import 'package:flutter/material.dart';

class CommentaireRetourWidget extends StatelessWidget {
  final TextEditingController controller;

  const CommentaireRetourWidget({Key? key, required this.controller})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: 4,
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(
        hintText: "Décrivez l'état du véhicule, les problèmes constatés, etc.",
        hintStyle: TextStyle(color: Colors.grey[350]),
        suffixIcon: Padding(
          padding: const EdgeInsets.only(bottom: 64),
          child: IconButton(
            icon: Icon(Icons.check_circle, color: Colors.orange[200]!),
            onPressed: () {
              // Fermer le clavier
              FocusScope.of(context).unfocus();
            },
          ),
        ),
        filled: true,

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.orange[200]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.orange[200]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.orange[200]!),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      ),
      style: TextStyle(
        fontSize: 16,
        color: Colors.orange[800],
      ),
    );
  }
}
