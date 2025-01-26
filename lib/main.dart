import 'dart:async';
import 'package:ContraLoc/firebase_options.dart';
import 'package:ContraLoc/services/subscription_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:purchases_flutter/purchases_flutter.dart'; // Import RevenueCat
import 'dart:io'; // Import dart:io pour Platform
import 'package:flutter/services.dart'; // Import SystemChrome
import 'screens/splash_screen.dart';

Future<String> fetchRevenueCatKey() async {
  try {
    // Récupère les clés API depuis Firestore
    final snapshot = await FirebaseFirestore.instance
        .collection('api_keys')
        .doc('revenuecat')
        .get();

    final data = snapshot.data();
    if (data == null) throw Exception('Clés API RevenueCat introuvables.');

    if (Platform.isIOS) {
      return data['ios_api_key'];
    } else if (Platform.isAndroid) {
      return data['android_api_key'];
    } else {
      throw Exception('Plateforme non prise en charge.');
    }
  } catch (e) {
    print('❌ Erreur lors de la récupération des clés RevenueCat: $e');
    throw e;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Optimisation des images
  ImageCache().maximumSize = 1024;
  ImageCache().maximumSizeBytes = 50 * 1024 * 1024; // 50MB

  // Initialisation Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialisé avec succès');
  } catch (e) {
    print('❌ Erreur initialisation Firebase: $e');
    return; // Arrêter l'exécution si Firebase échoue
  }

  // Récupération et configuration de RevenueCat
  String revenueCatKey;
  try {
    revenueCatKey = await fetchRevenueCatKey();
    await Purchases.setLogLevel(LogLevel.debug);

    // Configuration initiale de RevenueCat
    print('🔑 Configuration RevenueCat initiale');
    await Purchases.configure(PurchasesConfiguration(revenueCatKey));

    // Synchroniser l'utilisateur actuel si connecté
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      print('🔄 Vérification de la synchronisation RevenueCat');
      try {
        final customerInfo = await Purchases.getCustomerInfo();
        // Ne pas faire de logOut, seulement logIn si nécessaire
        if (customerInfo.originalAppUserId != currentUser.uid) {
          print('⚠️ Désynchronisation détectée, mise à jour...');
          await Purchases.logIn(currentUser.uid);
          print('✅ ID utilisateur RevenueCat synchronisé');
        } else {
          print('✅ ID utilisateur déjà synchronisé');
        }
      } catch (e) {
        print('❌ Erreur synchronisation RevenueCat: $e');
      }
    }

    print('✅ RevenueCat configuré avec succès');
  } catch (e) {
    print('❌ Erreur configuration RevenueCat: $e');
    return;
  }

  // Vérifier les abonnements uniquement si un utilisateur est connecté
  if (FirebaseAuth.instance.currentUser != null) {
    await SubscriptionService.checkAndUpdateSubscription();

    // Vérification périodique
    Timer.periodic(const Duration(hours: 1), (_) {
      if (FirebaseAuth.instance.currentUser != null) {
        SubscriptionService.checkAndUpdateSubscription();
      }
    });
  }

  // Forcer l'orientation en portrait
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return OrientationBuilder(
          builder: (context, orientation) {
            return MaterialApp(
              title: 'Contraloc',
              theme: ThemeData(
                primarySwatch: Colors.blue, // Thème principal
                fontFamily: 'OpenSans', // Police de base
              ),
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [
                Locale('fr', 'FR'), // Ajouter d'autres langues si nécessaire
              ],
              home: SplashScreen(), // Écran de démarrage
              debugShowCheckedModeBanner: false, // Retirer le badge "debug"
              builder: (context, child) {
                return ScrollConfiguration(
                  behavior: ScrollBehavior().copyWith(
                    physics: const BouncingScrollPhysics(),
                  ),
                  child: MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                      textScaleFactor: 1.0, // Échelle fixe pour le texte
                    ),
                    child: child!,
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
