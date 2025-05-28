import 'package:flutter/material.dart';
import '../screens/add_vehicule.dart';

/// Un bouton d'action personnalisé avec un design moderne
/// 
/// Ce widget crée un bouton avec un dégradé de couleur, une ombre et une icône.
/// Il peut être utilisé pour les actions principales dans l'application.
class CustomActionButton extends StatelessWidget {
  /// Le texte à afficher sur le bouton
  final String text;
  
  /// L'icône à afficher à côté du texte
  final IconData icon;
  
  /// La fonction à exécuter lorsque le bouton est pressé
  final VoidCallback onPressed;
  
  /// La couleur de début du dégradé
  final Color startColor;
  
  /// La couleur de fin du dégradé
  final Color endColor;
  
  /// La largeur du padding horizontal
  final double horizontalPadding;
  
  /// La hauteur du padding vertical
  final double verticalPadding;
  
  /// La taille de l'icône
  final double iconSize;
  
  /// L'espacement entre l'icône et le texte
  final double spacing;
  
  /// La taille de la police du texte
  final double fontSize;
  
  /// Le rayon de la bordure arrondie
  final double borderRadius;

  /// Constructeur pour le bouton d'action personnalisé
  const CustomActionButton({
    Key? key,
    required this.text,
    required this.icon,
    required this.onPressed,
    this.startColor = const Color(0xFF2979FF),
    this.endColor = const Color(0xFF1565C0),
    this.horizontalPadding = 24.0,
    this.verticalPadding = 14.0,
    this.iconSize = 20.0,
    this.spacing = 10.0,
    this.fontSize = 16.0,
    this.borderRadius = 30.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding, 
          vertical: verticalPadding
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              spreadRadius: 0,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [startColor, endColor],
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: iconSize,
            ),
            SizedBox(width: spacing),
            Text(
              text,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: fontSize,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Un bouton d'ajout positionné en bas de l'écran
///
/// Ce widget encapsule un CustomActionButton dans un Positioned
/// pour le placer en bas de l'écran.
class PositionedAddButton extends StatelessWidget {
  /// Constructeur pour le bouton d'ajout positionné
  const PositionedAddButton({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 20,
      left: 0,
      right: 0,
      child: Center(
        child: CustomActionButton(
          text: "Ajouter",
          icon: Icons.add_circle_outline,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AddVehiculeScreen(),
              ),
            );
          },
        ),
      ),
    );
  }
}
