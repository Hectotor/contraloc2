import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

class StripeService {
  // URL de base pour l'API Stripe
  static const String _apiBase = 'https://api.stripe.com/v1';
  
  // Récupérer les clés API depuis Firestore
  static Future<Map<String, String>> _getApiKeys() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('api_key_stripe')
          .doc('api')
          .get();
          
      if (doc.exists) {
        final data = doc.data()!;
        return {
          'apiKey': data['_apiKey'] ?? '',
          'publicKey': data['_publicKey'] ?? '',
        };
      }
      
      print('❌ Clés API Stripe non trouvées dans Firestore');
      return {'apiKey': '', 'publicKey': ''};
    } catch (e) {
      print('❌ Erreur lors de la récupération des clés API Stripe: $e');
      return {'apiKey': '', 'publicKey': ''};
    }
  }
  
  // Headers pour les requêtes API
  static Future<Map<String, String>> _getHeaders() async {
    final keys = await _getApiKeys();
    return {
      'Authorization': 'Bearer ${keys['apiKey']}',
      'Content-Type': 'application/x-www-form-urlencoded',
    };
  }
  
  // Créer un client Stripe pour l'utilisateur actuel
  static Future<String?> createCustomer(String email, String name) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$_apiBase/customers'),
        headers: headers,
        body: {
          'email': email,
          'name': name,
        },
      );
      
      final jsonResponse = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return jsonResponse['id']; // Retourne l'ID du client Stripe
      } else {
        print('❌ Erreur création client Stripe: ${jsonResponse['error']['message']}');
        return null;
      }
    } catch (e) {
      print('❌ Exception création client Stripe: $e');
      return null;
    }
  }
  
  // Créer un lien de paiement pour un abonnement
  static Future<String?> createSubscriptionCheckoutSession(
    String customerId,
    String productId,
    String successUrl,
    String cancelUrl,
  ) async {
    try {
      // Déterminer le montant en fonction du type d'abonnement
      int amount;
      String interval = 'month'; // Par défaut mensuel
      
      if (productId == 'prod_RiIVqYAhJGzB0u') { // Premium Mensuel
        amount = 1999; // 19.99 EUR
        interval = 'month';
      } else if (productId == 'prod_RiIXsD22K4xehY') { // Premium Annuel
        amount = 23999; // 239.99 EUR
        interval = 'year';
      } else if (productId == 'prod_S27nF635Z0AoFs' || productId == 'prod_S26yXish2BNayF') { // Platinum Mensuel
        amount = 3999; // 39.99 EUR
        interval = 'month';
      } else if (productId == 'prod_S26xbnrxhZn6TT') { // Platinum Annuel
        amount = 47999; // 479.99 EUR
        interval = 'year';
      } else {
        amount = 1999; // Montant par défaut
        interval = 'month';
      }
      
      print('🔄 Création session Stripe: customerId=$customerId, productId=$productId');
      print('🔄 Montant: $amount EUR, Intervalle: $interval');
      print('🔄 URLs: success=$successUrl, cancel=$cancelUrl');
      
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$_apiBase/checkout/sessions'),
        headers: headers,
        body: {
          'customer': customerId,
          'success_url': successUrl,
          'cancel_url': cancelUrl,
          'mode': 'subscription',
          'line_items[0][price_data][product]': productId,
          'line_items[0][price_data][unit_amount]': amount.toString(),
          'line_items[0][price_data][recurring][interval]': interval,
          'line_items[0][price_data][currency]': 'eur',
          'line_items[0][quantity]': '1',
        },
      );
      
      final jsonResponse = jsonDecode(response.body);
      if (response.statusCode == 200) {
        final url = jsonResponse['url'] as String?;
        print('✅ URL de session Stripe créée: $url');
        return url; // URL de paiement Stripe
      } else {
        print('❌ Erreur création session: ${jsonResponse['error']['message']}');
        return null;
      }
    } catch (e) {
      print('❌ Exception création session: $e');
      return null;
    }
  }
  
  // Récupérer les informations d'un abonnement
  static Future<Map<String, dynamic>?> getSubscription(String subscriptionId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$_apiBase/subscriptions/$subscriptionId'),
        headers: headers,
      );
      
      final jsonResponse = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return jsonResponse;
      } else {
        print('❌ Erreur récupération abonnement: ${jsonResponse['error']['message']}');
        return null;
      }
    } catch (e) {
      print('❌ Exception récupération abonnement: $e');
      return null;
    }
  }
  
  // Mettre à jour Firebase avec les informations d'abonnement Stripe
  static Future<void> updateFirebaseFromStripe(String userId, String subscriptionId) async {
    try {
      // Récupérer les détails de l'abonnement depuis Stripe
      final subscriptionData = await getSubscription(subscriptionId);
      if (subscriptionData == null) return;
      
      // Déterminer le nombre de véhicules en fonction du produit
      int stripeNumberOfCars = 1;
      
      // Récupérer l'ID du produit pour déterminer le plan
      final String productId = subscriptionData['items']['data'][0]['price']['product'];
      
      // Mapper l'ID du produit au nombre de véhicules
      if (productId == 'prod_RiIVqYAhJGzB0u' || productId == 'prod_RiIXsD22K4xehY') {
        // Premium (mensuel ou annuel)
        stripeNumberOfCars = 10;
      } else if (productId == 'prod_S26yXish2BNayF' || productId == 'prod_S26xbnrxhZn6TT' || productId == 'prod_S27nF635Z0AoFs') {
        // Platinum (mensuel ou annuel)
        stripeNumberOfCars = 20;
      }
      
      // Mettre à jour les données d'abonnement dans Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('authentification')
          .doc(userId)
          .set({
        'stripeSubscriptionId': subscriptionId,
        'stripeNumberOfCars': stripeNumberOfCars,
        'lastUpdateDate': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      print('✅ Firebase mis à jour avec succès depuis Stripe');
    } catch (e) {
      print('❌ Erreur mise à jour Firebase depuis Stripe: $e');
      rethrow;
    }
  }
  
  // Obtenir la clé publique pour l'utiliser côté client
  static Future<String> getPublicKey() async {
    final keys = await _getApiKeys();
    return keys['publicKey'] ?? '';
  }
}
