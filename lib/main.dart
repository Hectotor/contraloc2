import 'dart:async';
import 'package:ContraLoc/firebase_options.dart';
import 'package:ContraLoc/USERS/Subscription/revenue_cat_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import pour SystemChrome
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'SCREENS/splash_screen.dart';
import 'package:ContraLoc/USERS/Subscription/subscription_service.dart'; // Import SubscriptionService
import 'package:ContraLoc/utils/photo_upload_manager.dart'; // Import pour GlobalNotification

// Couleur principale de l'application
const Color primaryColor = Color(0xFF08004D);

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

  // Configuration du style de la barre d'état pour que les icônes s'adaptent à l'arrière-plan
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent, // Barre d'état transparente
    statusBarIconBrightness: Brightness.dark, // Icônes sombres pour fond clair
    systemNavigationBarColor: Colors.white, // Couleur de la barre de navigation
    systemNavigationBarIconBrightness: Brightness.dark, // Icônes sombres pour la barre de navigation
  ));

  ImageCache().maximumSize = 1024;
  ImageCache().maximumSizeBytes = 50 * 1024 * 1024; // 50MB

  try {
    // 1. Initialiser Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialisé avec succès');

    // 2. Récupérer les clés RevenueCat
    final apiKeys = await fetchRevenueCatKeys();
    
    // 3. Initialiser RevenueCat
    await RevenueCatService.initialize(
      androidApiKey: apiKeys['android']!,
      iosApiKey: apiKeys['ios']!,
    );

    // 4. Gérer l'utilisateur courant
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      try {
        // 5. Login RevenueCat
        await RevenueCatService.login(currentUser.uid);
        
        // 6. Mettre à jour le statut d'abonnement
        print('👤 Chargement des données utilisateur...');
        await SubscriptionService.updateSubscriptionStatus();
      } catch (e) {
        print('⚠️ Erreur lors de la configuration utilisateur: $e');
        // Continue l'exécution même en cas d'erreur
      }
    }

  } catch (e) {
    print('❌ Erreur fatale lors de l\'initialisation: $e');
    return; // Arrêter l'application en cas d'erreur critique
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
              navigatorKey: GlobalNotification.navigatorKey, // Utilisation de la clé de navigateur globale pour les notifications
              scaffoldMessengerKey: PhotoUploadManager.scaffoldMessengerKey, // Clé pour le ScaffoldMessenger
              title: 'Contraloc',
              debugShowCheckedModeBanner: false,
              theme: ThemeData(
                primarySwatch: Colors.blue,
                fontFamily: 'OpenSans',
                scaffoldBackgroundColor: Colors.white,
                colorScheme: ColorScheme.light(
                  background: Colors.white,
                  surface: Colors.white,
                ),
                appBarTheme: const AppBarTheme(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                ),
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                hoverColor: Colors.transparent,
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
