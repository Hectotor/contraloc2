import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

class StripeService {
  // Base URL pour l'API Stripe
  static const String _apiBase = 'https://api.stripe.com/v1';
  
  // Récupérer les clés API Stripe depuis Firestore
  static Future<Map<String, String>> _getApiKeys() async {
    try {

      // Code pour récupérer les clés depuis Firestore
      final doc = await FirebaseFirestore.instance
          .collection('api_key_stripe')
          .doc('api')
          .get();
      
      if (doc.exists && doc.data() != null) {
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
  static Future<String?> createCustomer(String email, String nomEntreprise, {String? userId}) async {
    try {
      print('🔄 Création d\'un client Stripe pour: $email, nomEntreprise: $nomEntreprise, userId: $userId');
      final headers = await _getHeaders();
      
      // Préparer les données du client
      final Map<String, dynamic> customerData = {
        'email': email,
        'name': nomEntreprise,
         // Le champ 'name' dans l'API Stripe correspond à 'nomEntreprise' dans Firestore
      };
      
      print('📋 Données du client Stripe: $customerData');
      
      // Ajouter l'ID Firebase aux métadonnées si disponible
      if (userId != null && userId.isNotEmpty) {
        customerData['metadata[firebaseUserId]'] = userId;
      }
      
      final response = await http.post(
        Uri.parse('$_apiBase/customers'),
        headers: headers,
        body: customerData,
      );
      
      final jsonResponse = jsonDecode(response.body);
      print('📋 Réponse Stripe: ${response.statusCode} - ${response.body}');
      
      if (response.statusCode == 200) {
        return jsonResponse['id']; // Retourne l'ID du client Stripe
      } else {
        print('❌ Erreur création client Stripe: ${jsonResponse['error']['message']}');
        return null;
      }
    } catch (e) {
      print('❌ Erreur création client Stripe: $e');
      return null;
    }
  }
  
  // Créer une session de paiement pour un abonnement
  static Future<String?> createSubscriptionCheckoutSession(
    String customerId,
    String productId,
    String successUrl,
    String cancelUrl,
  ) async {
    try {
      print('🔄 Création session de paiement Stripe...');
      print('📋 Détails: customerId=$customerId, productId=$productId');
      print('📋 URLs: successUrl=$successUrl, cancelUrl=$cancelUrl');
      
      // Déterminer le montant et l'intervalle en fonction du produit
      int amount;
      String interval;
      
      if (productId == 'prod_RiIVqYAhJGzB0u') { // Premium Mensuel
        amount = 1999;
        interval = 'month';
      } else if (productId == 'prod_RiIXsD22K4xehY') { // Premium Annuel
        amount = 23999;
        interval = 'year';
      } else if (productId == 'prod_S26yXish2BNayF' || productId == 'prod_S27nF635Z0AoFs') { // Platinum Mensuel
        amount = 3999;
        interval = 'month';
      } else if (productId == 'prod_S26xbnrxhZn6TT') { // Platinum Annuel
        amount = 47999;
        interval = 'year';
      } else {
        print('❌ Produit non reconnu: $productId');
        return null;
      }
      
      print('💰 Montant: $amount, Intervalle: $interval');
      
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$_apiBase/checkout/sessions'),
        headers: headers,
        body: {
          'success_url': successUrl,
          'cancel_url': cancelUrl,
          'customer': customerId,
          'line_items[0][price_data][currency]': 'eur',
          'line_items[0][price_data][product]': productId,
          'line_items[0][price_data][unit_amount]': amount.toString(),
          'line_items[0][price_data][recurring][interval]': interval,
          'line_items[0][quantity]': '1',
          'mode': 'subscription',
          'payment_method_types[0]': 'card',
        },
      );
      
      final jsonResponse = jsonDecode(response.body);
      if (response.statusCode == 200) {
        final sessionUrl = jsonResponse['url'];
        print('✅ Session Stripe créée avec succès: $sessionUrl');
        return sessionUrl;
      } else {
        print('❌ Erreur création session Stripe: ${jsonResponse['error']['message']}');
        return null;
      }
    } catch (e) {
      print('❌ Erreur création session Stripe: $e');
      return null;
    }
  }
  
  // Récupérer les informations d'un abonnement
  static Future<Map<String, dynamic>?> getSubscription(String subscriptionId) async {
    try {
      final response = await http.get(
        Uri.parse('$_apiBase/subscriptions/$subscriptionId'),
        headers: await _getHeaders(),
      );
      
      final jsonResponse = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return jsonResponse;
      } else {
        print('❌ Erreur récupération abonnement: ${jsonResponse['error']['message']}');
        return null;
      }
    } catch (e) {
      print('❌ Erreur récupération abonnement: $e');
      return null;
    }
  }
  
  // Mettre à jour Firebase avec les informations d'abonnement Stripe
  static Future<void> updateFirebaseFromStripe(String userId, String subscriptionId) async {
    try {
      // Obtenir les détails de l'abonnement
      final response = await http.get(
        Uri.parse('$_apiBase/subscriptions/$subscriptionId'),
        headers: await _getHeaders(),
      );
      
      final jsonResponse = jsonDecode(response.body);
      if (response.statusCode != 200) {
        throw Exception('Erreur récupération abonnement: ${jsonResponse['error']['message']}');
      }
      
      final status = jsonResponse['status'];
      final isActive = status == 'active' || status == 'trialing';
      final productId = jsonResponse['items']['data'][0]['price']['product'];
      
      // Déterminer le type de plan et le nombre de véhicules
      String planType = 'free';
      int stripeNumberOfCars = 1;
      
      if (productId == 'prod_RiIVqYAhJGzB0u') {
        planType = 'premium-monthly_access';
        stripeNumberOfCars = 10;
      } else if (productId == 'prod_RiIXsD22K4xehY') {
        planType = 'premium-yearly_access';
        stripeNumberOfCars = 10;
      } else if (productId == 'prod_S26yXish2BNayF' || productId == 'prod_S27nF635Z0AoFs') {
        planType = 'platinum-monthly_access';
        stripeNumberOfCars = 20;
      } else if (productId == 'prod_S26xbnrxhZn6TT') {
        planType = 'platinum-yearly_access';
        stripeNumberOfCars = 20;
      }
      
      // Mettre à jour les données d'abonnement dans Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('authentification')
          .doc(userId)
          .set({
        'stripePlanType': planType,
        'isStripeSubscriptionActive': isActive,
        'stripeNumberOfCars': stripeNumberOfCars,
        'stripeSubscriptionId': subscriptionId,
        'stripeStatus': status,
        'lastStripeUpdateDate': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      print('✅ Firebase mis à jour avec succès depuis Stripe');
    } catch (e) {
      print('❌ Erreur mise à jour Firebase depuis Stripe: $e');
      rethrow;
    }
  }
  
  // Récupérer la clé publique Stripe
  static Future<String?> getPublicKey() async {
    final keys = await _getApiKeys();
    return keys['publicKey'];
  }
}
