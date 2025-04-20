import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Classe spécialisée pour lancer les URL de paiement Stripe
class StripeUrlLauncher {
  /// Lance l'URL de paiement Stripe dans le navigateur externe
  /// 
  /// [context] : Le contexte de build pour afficher des dialogues
  /// [stripeUrl] : L'URL de la session de paiement Stripe
  /// [onSuccess] : Callback appelé en cas de succès
  /// [onError] : Callback appelé en cas d'erreur
  static Future<bool> launchStripeCheckout({
    required BuildContext context,
    required String stripeUrl,
    required Function onSuccess,
    required Function(String) onError,
  }) async {
    try {
      print('📱 Tentative d\'ouverture de l\'URL Stripe: $stripeUrl');
      
      // Vérifier si l'URL est valide
      if (stripeUrl.isEmpty) {
        print('❌ URL Stripe vide ou invalide');
        onError('URL Stripe vide ou invalide');
        return false;
      }
      
      // Convertir l'URL en Uri
      final Uri uri = Uri.parse(stripeUrl);
      
      print('🔍 Vérification si l\'URL peut être ouverte: $uri');
      // Vérifier si l'URL peut être ouverte
      if (await canLaunchUrl(uri)) {
        print('✅ L\'URL peut être ouverte, tentative de lancement...');
        
        // Essayer d'abord avec le mode externe
        try {
          print('🌐 Tentative avec mode externe...');
          final externalResult = await launchUrl(
            uri,
            mode: LaunchMode.externalApplication,
          );
          
          if (externalResult) {
            print('✅ URL Stripe ouverte avec succès (mode externe)');
            onSuccess();
            return true;
          } else {
            print('⚠️ Échec du mode externe, tentative avec mode inApp...');
          }
        } catch (e) {
          print('⚠️ Erreur avec mode externe: $e, tentative avec mode inApp...');
        }
        
        // Si le mode externe échoue, essayer avec le mode inApp
        try {
          print('🌐 Tentative avec mode inApp...');
          final inAppResult = await launchUrl(
            uri,
            mode: LaunchMode.inAppWebView,
            webViewConfiguration: const WebViewConfiguration(
              enableJavaScript: true,
              enableDomStorage: true,
            ),
          );
          
          if (inAppResult) {
            print('✅ URL Stripe ouverte avec succès (mode inApp)');
            onSuccess();
            return true;
          } else {
            print('❌ Échec du mode inApp également');
            onError('Échec de l\'ouverture de l\'URL Stripe');
            return false;
          }
        } catch (e) {
          print('❌ Erreur avec mode inApp: $e');
          onError('Erreur lors de l\'ouverture de l\'URL Stripe: $e');
          return false;
        }
      } else {
        print('❌ Impossible d\'ouvrir l\'URL: $stripeUrl');
        onError('Impossible d\'ouvrir l\'URL: $stripeUrl');
        
        // Afficher un dialogue d'erreur
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Erreur de paiement'),
              content: const Text('Impossible d\'ouvrir la page de paiement. Veuillez réessayer plus tard.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
        
        return false;
      }
    } catch (e) {
      print('❌ Erreur lors de l\'ouverture de l\'URL Stripe: $e');
      onError('Erreur lors de l\'ouverture de l\'URL Stripe: $e');
      
      // Afficher un dialogue d'erreur
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Erreur de paiement'),
            content: Text('Une erreur est survenue: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
      
      return false;
    }
  }
}
