import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Classe spécialisée pour gérer l'ouverture des liens Stripe
class StripeUrlLauncher {
  /// Ouvre un lien Stripe dans le navigateur externe
  /// 
  /// [context] : Le contexte de build pour afficher des dialogues d'erreur
  /// [stripeUrl] : L'URL de la session de paiement Stripe à ouvrir
  /// [onSuccess] : Fonction appelée en cas de succès d'ouverture
  /// [onError] : Fonction appelée en cas d'échec d'ouverture
  static Future<bool> launchStripeCheckout({
    required BuildContext context,
    required String stripeUrl,
    Function()? onSuccess,
    Function(String)? onError,
  }) async {
    try {
      print('🔄 Préparation de l\'ouverture de l\'URL Stripe: $stripeUrl');
      
      // Vérifier si l'URL est valide
      if (stripeUrl.isEmpty) {
        final errorMsg = 'URL Stripe invalide ou vide';
        print('❌ $errorMsg');
        if (onError != null) onError(errorMsg);
        return false;
      }
      
      // Créer l'objet Uri
      final Uri url = Uri.parse(stripeUrl);
      print('✅ URI créé avec succès: $url');
      
      // Vérifier si l'URL peut être ouverte
      print('🔄 Vérification si l\'URL peut être ouverte...');
      if (await canLaunchUrl(url)) {
        print('✅ URL peut être ouverte, lancement...');
        
        // Définir le mode de lancement en fonction de la plateforme
        LaunchMode launchMode = LaunchMode.externalApplication;
        
        // Lancer l'URL
        final result = await launchUrl(url, mode: launchMode);
        print('🔄 Résultat du lancement: $result');
        
        if (result) {
          print('✅ URL ouverte avec succès');
          if (onSuccess != null) onSuccess();
          return true;
        } else {
          final errorMsg = 'Échec du lancement de l\'URL';
          print('❌ $errorMsg');
          if (onError != null) onError(errorMsg);
          return false;
        }
      } else {
        final errorMsg = 'Impossible d\'ouvrir l\'URL: $url';
        print('❌ $errorMsg');
        
        // Afficher un dialogue d'erreur si aucun gestionnaire d'erreur n'est fourni
        if (onError != null) {
          onError(errorMsg);
        } else {
          _showErrorDialog(context, errorMsg);
        }
        return false;
      }
    } catch (e) {
      final errorMsg = 'Exception lors de l\'ouverture de l\'URL: $e';
      print('❌ $errorMsg');
      
      // Afficher un dialogue d'erreur si aucun gestionnaire d'erreur n'est fourni
      if (onError != null) {
        onError(errorMsg);
      } else {
        _showErrorDialog(context, errorMsg);
      }
      return false;
    }
  }
  
  /// Affiche un dialogue d'erreur
  static void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Erreur'),
          content: Text(message),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }
  
  /// Vérifie si les schémas d'URL nécessaires sont configurés
  /// Cette méthode est utile pour le débogage
  static Future<Map<String, bool>> checkUrlSchemeSupport() async {
    Map<String, bool> results = {};
    
    // Vérifier les schémas courants
    final schemes = ['https', 'http'];
    
    for (final scheme in schemes) {
      try {
        final url = Uri.parse('$scheme://example.com');
        results[scheme] = await canLaunchUrl(url);
      } catch (e) {
        results[scheme] = false;
      }
    }
    
    return results;
  }
}
