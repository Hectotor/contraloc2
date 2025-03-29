import 'package:cloud_firestore/cloud_firestore.dart';

/// Service centralisé pour gérer les abonnements de différentes sources (RevenueCat, Stripe)
class SubscriptionManager {
  // Constantes pour les sources d'abonnement
  static const String sourceRevenueCat = 'revenueCat';
  static const String sourceStripe = 'stripe';
  static const String sourceFree = 'free';
  
  // Constantes pour les types d'abonnement
  static const String freeAccess = 'free_access';
  static const String premiumMonthly = 'premium-monthly_access';
  static const String premiumYearly = 'premium-yearly_access';
  static const String platinumMonthly = 'platinum-monthly_access';
  static const String platinumYearly = 'platinum-yearly_access';
  static const String gratuit = 'Gratuit'; // Ancienne valeur pour la rétrocompatibilité

  /// Vérifie si l'utilisateur a un abonnement actif provenant de RevenueCat
  static Future<bool> hasActiveRevenueCatSubscription(String userId) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('authentification')
          .doc(userId)
          .get();
      
      if (!userDoc.exists) {
        return false;
      }
      
      final data = userDoc.data();
      if (data == null) {
        return false;
      }
      
      final bool isActive = data['isSubscriptionActive'] == true;
      final String? source = data['subscriptionSource'];
      
      // Si la source est explicitement RevenueCat
      if (isActive && source == sourceRevenueCat) {
        print('📱 SubscriptionManager: Abonnement RevenueCat actif trouvé');
        return true;
      }
      
      // Pour la rétrocompatibilité: si pas de source spécifiée mais abonnement premium/platinum
      if (isActive && source == null) {
        final String? subscriptionId = data['subscriptionId'];
        // Vérifier que ce n'est pas un abonnement Stripe (cb_subscription)
        final String? cbSubscription = data['cb_subscription'];
        
        // Si nous avons un subscriptionId premium/platinum mais pas de cb_subscription, c'est probablement RevenueCat
        if (subscriptionId != null && 
            (subscriptionId == premiumMonthly || 
             subscriptionId == premiumYearly || 
             subscriptionId == platinumMonthly || 
             subscriptionId == platinumYearly) &&
            (cbSubscription == null || cbSubscription.isEmpty)) {
          print('📱 SubscriptionManager: Abonnement probablement RevenueCat détecté (pas de source)');
          return true;
        }
      }
      
      print('📱 SubscriptionManager: Aucun abonnement RevenueCat actif');
      return false;
    } catch (e) {
      print('📱 SubscriptionManager: Erreur lors de la vérification de l\'abonnement RevenueCat: $e');
      return false;
    }
  }

  /// Vérifie si l'utilisateur a un abonnement actif provenant de Stripe
  static Future<bool> hasActiveStripeSubscription(String userId) async {
    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('authentification')
          .doc(userId)
          .get();
      
      if (!docSnapshot.exists) {
        return false;
      }
      
      final data = docSnapshot.data() as Map<String, dynamic>;
      
      // Vérifier les nouveaux champs
      final bool isActive = data['isSubscriptionActive'] == true;
      final String? stripeSubId = data['stripeSubscriptionId'];
      final String? source = data['subscriptionSource'];
      
      // Vérifier les anciens champs (format manuel)
      final String? cbSubscription = data['cb_subscription'];
      
      // Si la source est explicitement Stripe
      if (isActive && source == sourceStripe) {
        return true;
      }
      
      // Si un ID d'abonnement Stripe est présent (format actuel)
      if (isActive && stripeSubId != null && stripeSubId.isNotEmpty) {
        return true;
      }
      
      // Si les anciens champs sont présents (format manuel)
      if (cbSubscription != null && cbSubscription.isNotEmpty) {
        // Considérer comme un abonnement Stripe actif si cb_subscription contient un abonnement valide
        if (cbSubscription == premiumMonthly || 
            cbSubscription == premiumYearly ||
            cbSubscription == platinumMonthly ||
            cbSubscription == platinumYearly) {
          return true;
        }
      }
      
      return false;
    } catch (e) {
      print('📱 SubscriptionManager: Erreur lors de la vérification de l\'abonnement Stripe: $e');
      return false;
    }
  }

  /// Vérifie si l'utilisateur a un abonnement gratuit
  static Future<bool> hasFreeSubscription(String userId) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('authentification')
          .doc(userId)
          .get();
      
      if (!userDoc.exists) {
        return false;
      }
      
      final data = userDoc.data();
      if (data == null) {
        return false;
      }
      
      final bool isActive = data['isSubscriptionActive'] == true;
      final String? subscriptionId = data['subscriptionId'];
      
      return isActive && (subscriptionId == freeAccess || subscriptionId == gratuit);
    } catch (e) {
      print('📱 SubscriptionManager: Erreur lors de la vérification de l\'abonnement gratuit: $e');
      return false;
    }
  }

  /// Vérifie si l'utilisateur a un abonnement actif de n'importe quelle source
  static Future<bool> hasAnyActiveSubscription(String userId) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('authentification')
          .doc(userId)
          .get();
      
      if (!userDoc.exists) {
        return false;
      }
      
      final data = userDoc.data();
      if (data == null) {
        return false;
      }
      
      return data['isSubscriptionActive'] == true;
    } catch (e) {
      print('📱 SubscriptionManager: Erreur lors de la vérification d\'abonnement: $e');
      return false;
    }
  }

  /// Récupère les détails de l'abonnement de l'utilisateur
  static Future<Map<String, dynamic>?> getSubscriptionDetails(String userId) async {
    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('authentification')
          .doc(userId)
          .get();
      
      if (!docSnapshot.exists) {
        return null;
      }
      
      final data = docSnapshot.data() as Map<String, dynamic>;
      
      // Créer un objet de résultat normalisé
      final Map<String, dynamic> result = {};
      
      // Traiter les nouveaux champs
      result['subscriptionId'] = data['subscriptionId'];
      result['isSubscriptionActive'] = data['isSubscriptionActive'] ?? false;
      result['numberOfCars'] = data['numberOfCars'] ?? 1;
      result['stripeSubscriptionId'] = data['stripeSubscriptionId'] ?? '';
      result['stripeStatus'] = data['stripeStatus'] ?? '';
      result['subscriptionSource'] = data['subscriptionSource'] ?? '';
      
      // Traiter les anciens champs (format manuel)
      final String? cbSubscription = data['cb_subscription'];
      final dynamic cbNbCar = data['cb_nb_car'];
      
      // Si les nouveaux champs sont vides mais que les anciens existent, utiliser les anciens
      if (cbSubscription != null && cbSubscription.isNotEmpty) {
        // Utiliser cb_subscription si subscriptionId est vide
        if (result['subscriptionId'] == null || result['subscriptionId'].toString().isEmpty) {
          result['subscriptionId'] = cbSubscription;
        }
        
        // Marquer comme actif si nous avons un cb_subscription
        result['isSubscriptionActive'] = true;
        
        // Utiliser cb_nb_car si numberOfCars est vide ou 1 (valeur par défaut)
        if (cbNbCar != null && (result['numberOfCars'] == null || result['numberOfCars'] == 1)) {
          // Convertir en entier si c'est une chaîne
          if (cbNbCar is String) {
            result['numberOfCars'] = int.tryParse(cbNbCar) ?? 1;
          } else if (cbNbCar is int) {
            result['numberOfCars'] = cbNbCar;
          }
        }
        
        // Si c'est un abonnement premium/platinum avec cb_subscription, c'est un abonnement Stripe
        if (cbSubscription == premiumMonthly || 
            cbSubscription == premiumYearly || 
            cbSubscription == platinumMonthly || 
            cbSubscription == platinumYearly) {
          result['subscriptionSource'] = sourceStripe;
        }
      }
      
      return result;
    } catch (e) {
      print('📱 SubscriptionManager: Erreur lors de la récupération des détails de l\'abonnement: $e');
      return null;
    }
  }

  /// Met à jour l'abonnement gratuit dans Firestore
  static Future<void> activateFreeSubscription(String userId) async {
    try {
      await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('authentification')
        .doc(userId)
        .set({
          'subscriptionId': freeAccess,
          'isSubscriptionActive': true,
          'numberOfCars': 1,  // Nombre de véhicules pour l'offre gratuite
          'stripeSubscriptionId': '',
          'stripeStatus': 'active',
          'subscriptionSource': sourceFree,
          'lastUpdateDate': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      
      print('📱 SubscriptionManager: Abonnement gratuit activé avec succès');
    } catch (e) {
      print('📱 SubscriptionManager: Erreur lors de l\'activation de l\'abonnement gratuit: $e');
      throw e;
    }
  }

  /// Obtient le nombre de véhicules autorisés pour l'abonnement actuel
  static Future<int> getNumberOfCarsAllowed(String userId) async {
    try {
      final details = await getSubscriptionDetails(userId);
      if (details == null) {
        return 1; // Par défaut, 1 véhicule pour l'offre gratuite
      }
      
      return details['numberOfCars'] ?? 1;
    } catch (e) {
      print('📱 SubscriptionManager: Erreur lors de la récupération du nombre de véhicules: $e');
      return 1;
    }
  }
}
