import 'dart:async';
import 'package:ContraLoc/firebase_options.dart';
import 'package:ContraLoc/services/revenue_cat_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:purchases_flutter/purchases_flutter.dart'; // Import RevenueCat
import 'package:flutter/services.dart'; // Import SystemChrome
import 'screens/splash_screen.dart';
import 'package:ContraLoc/services/subscription_service.dart'; // Import SubscriptionService


Future<Map<String, String>> fetchRevenueCatKeys() async {
  try {
    final snapshot = await FirebaseFirestore.instance
        .collection('api_keys')
        .doc('revenuecat')
        .get();

    final data = snapshot.data();
    if (data == null) throw Exception('Clés API RevenueCat introuvables.');

    return {
      'android': data['android_api_key'] ?? '',
      'ios': data['ios_api_key'] ?? '',
    };
  } catch (e) {
    print('❌ Erreur lors de la récupération des clés RevenueCat: $e');
    throw e;
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  ImageCache().maximumSize = 1024;
  ImageCache().maximumSizeBytes = 50 * 1024 * 1024; // 50MB

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialisé avec succès');
  } catch (e) {
    print('❌ Erreur initialisation Firebase: $e');
    return;
  }

  try {
    final apiKeys = await fetchRevenueCatKeys();
    await RevenueCatService.initialize(
      androidApiKey: apiKeys['android']!,
      iosApiKey: apiKeys['ios']!,
    );

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      try {
        await Purchases.logIn(currentUser.uid);
        
        // Vérifier et mettre à jour le statut d'abonnement
        print('👤 Chargement des données utilisateur...');
        await SubscriptionService.updateSubscriptionStatus();
        
      } catch (e) {
        print('❌ Erreur vérification statut: $e');
      }
    }

    print('✅ RevenueCat configuré avec succès');
  } catch (e) {
    print('❌ Erreur configuration RevenueCat: $e');
    return;
  }

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
                primarySwatch: Colors.blue,
                fontFamily: 'OpenSans',
              ),
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [
                Locale('fr', 'FR'),
              ],
              home: SplashScreen(),
              debugShowCheckedModeBanner: false,
              builder: (context, child) {
                return ScrollConfiguration(
                  behavior: ScrollBehavior().copyWith(
                    physics: const BouncingScrollPhysics(),
                  ),
                  child: MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                      textScaleFactor: 1.0,
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
