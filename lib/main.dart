import 'package:ContraLoc/firebase_options.dart';
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

  // Configuration Firebase avec options personnalisées
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Configuration du store en fonction de la plateforme
  if (Platform.isIOS) {
    StoreConfig(
      store: Store.appleStore,
      apiKey:
          "appl_surBKRbCRgBprWYKIjWlprQgfUc", // Remplacez par votre clé API publique RevenueCat pour iOS
    );
  } else if (Platform.isAndroid) {
    StoreConfig(
      store: Store.googlePlay,
      apiKey:
          "goog_abc123xyz456", // Remplacez par votre clé API publique RevenueCat pour Android
    );
  }

  // Initialisation de RevenueCat
  final PurchasesConfiguration configuration =
      PurchasesConfiguration(StoreConfig.instance.apiKey);
  await Purchases.configure(configuration);

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
