import 'package:ContraLoc/firebase_options.dart';
import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_localizations/flutter_localizations.dart'; // Import localization delegates
import 'package:firebase_core/firebase_core.dart';
import 'package:purchases_flutter/purchases_flutter.dart'; // Import RevenueCat
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Optimisation des images
  ImageCache().maximumSize = 1024;
  ImageCache().maximumSizeBytes = 50 * 1024 * 1024; // 50MB

  // Configuration Firebase avec options personnalisées
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialisation de RevenueCat
  await Purchases.setDebugLogsEnabled(true);
  await Purchases.setup(
      "appl_surBKRbCRgBprWYKIjWlprQgfUc"); // Remplacez par votre clé API publique RevenueCat

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
