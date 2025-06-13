import 'package:flutter/material.dart';

/// Un bouton d'action personnalisé avec un design moderne
/// 
/// Ce widget crée un bouton avec un dégradé de couleur, une ombre et une icône.
/// Il peut être utilisé pour les actions principales dans l'application.
class PhotoActionButton extends StatelessWidget {
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
  const PhotoActionButton({
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

/// Un bouton pour la suppression d'arrière-plan positionné en bas de l'écran
///
/// Ce widget encapsule un PhotoActionButton dans un Positioned
/// pour le placer en bas de l'écran.
class PositionedPhotoButton extends StatelessWidget {
  /// Constructeur pour le bouton d'action positionné
  const PositionedPhotoButton({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 20,
      left: 0,
      right: 0,
      child: Center(
        child: PhotoActionButton(
          text: "Supprimer l'arrière-plan",
          icon: Icons.auto_fix_high,
          onPressed: () {
            // Afficher un message temporaire
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Fonctionnalité de suppression d\'arrière-plan bientôt disponible'),
                backgroundColor: Color(0xFF08004D),
                duration: Duration(seconds: 2),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Un widget qui affiche deux boutons d'action pour les photos
///
/// Ce widget affiche deux boutons côte à côte pour différentes actions liées aux photos.
class PhotoActionButtons extends StatelessWidget {
  /// Constructeur pour les boutons d'action photo
  const PhotoActionButtons({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 20,
      left: 0,
      right: 0,
      child: Center(
        child: PhotoActionButton(
          text: "Commencer",
          icon: Icons.auto_fix_high,
          onPressed: () {
            // Afficher un message temporaire
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Fonctionnalité de suppression d\'arrière-plan bientôt disponible'),
                backgroundColor: Color(0xFF08004D),
                duration: Duration(seconds: 2),
              ),
            );
          },
        ),
      ),
    );
  }
}
