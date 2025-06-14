import 'package:flutter/material.dart';

/// Bouton pour générer un rapport ou document
class GenerateButton extends StatelessWidget {
  final VoidCallback onPressed;
  
  const GenerateButton({
    Key? key,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 24.0,
          vertical: 16.0,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              spreadRadius: 0,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF08004D), Color(0xFF1A1A7F)],
          ),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_fix_high,
              color: Colors.white,
              size: 24,
            ),
            SizedBox(width: 12),
            Text(
              "Générer",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 18,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
