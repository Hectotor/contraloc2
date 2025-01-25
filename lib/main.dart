import 'dart:async';
import 'package:ContraLoc/firebase_options.dart';
import 'package:ContraLoc/services/subscription_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_localizations/flutter_localizations.dart'; // Import localization delegates
import 'package:firebase_core/firebase_core.dart';
import 'package:purchases_flutter/purchases_flutter.dart'; // Import RevenueCat
import 'dart:io'; // Import dart:io for Platform
import 'package:flutter/services.dart'; // Import SystemChrome
import 'screens/splash_screen.dart';

enum Store { appleStore, googlePlay }

class StoreConfig {
  final Store store;
  final String apiKey;
  static StoreConfig? _instance;
  factory StoreConfig({required Store store, required String apiKey}) {
    _instance ??= StoreConfig._internal(store, apiKey);
    return _instance!;
  }
  StoreConfig._internal(this.store, this.apiKey);
  static StoreConfig get instance {
    return _instance!;
  }

  static bool isForAppleStore() => _instance!.store == Store.appleStore;
  static bool isForGooglePlay() => _instance!.store == Store.googlePlay;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Optimisation des images
  ImageCache().maximumSize = 1024;
  ImageCache().maximumSizeBytes = 50 * 1024 * 1024; // 50MB

  // Configuration Firebase AVANT RevenueCat
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialisé avec succès');
  } catch (e) {
    print('❌ Erreur initialisation Firebase: $e');
    return; // Arrêter l'exécution si Firebase échoue
  }

  // Configuration de RevenueCat APRÈS Firebase
  try {
    if (Platform.isIOS) {
      StoreConfig(
        store: Store.appleStore,
        apiKey: "appl_surBKRbCRgBprWYKIjWlprQgfUc",
      );
    } else if (Platform.isAndroid) {
      StoreConfig(
        store: Store.googlePlay,
        apiKey: "goog_XlRowaKUKvXsFhNqZdqzRbQnVzO",
      );
    }

    await Purchases.setLogLevel(LogLevel.debug);
    await Purchases.configure(
      PurchasesConfiguration(StoreConfig.instance.apiKey)
        ..appUserID = FirebaseAuth.instance.currentUser?.uid,
    );
    print('✅ RevenueCat configuré avec succès');
  } catch (e) {
    print('❌ Erreur configuration RevenueCat: $e');
  }

  // Vérification de l'abonnement
  if (FirebaseAuth.instance.currentUser != null) {
    await SubscriptionService.checkAndUpdateSubscription();
  }

  // Vérification périodique toutes les heures
  Timer.periodic(const Duration(hours: 1), (_) {
    SubscriptionService.checkAndUpdateSubscription();
  });

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
                Locale('fr', 'FR'), // Add French locale
              ],
              home: SplashScreen(), // Appel du SplashScreen au démarrage
              debugShowCheckedModeBanner: false, // Retire le badge "debug"
              builder: (context, child) {
                return ScrollConfiguration(
                  behavior: ScrollBehavior().copyWith(
                    physics: const BouncingScrollPhysics(),
                  ),
                  child: MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                      textScaleFactor: 1.0, // Force une échelle de texte fixe
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
