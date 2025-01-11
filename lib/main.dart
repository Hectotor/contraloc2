import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_localizations/flutter_localizations.dart'; // Import localization delegates
import 'package:firebase_core/firebase_core.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Nécessaire pour Firebase
  await Firebase.initializeApp(); // Initialise Firebase

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
                return MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaleFactor: constraints.maxWidth > 600 ? 1.2 : 1.0,
                  ),
                  child: child!,
                );
              },
            );
          },
        );
      },
    );
  }
}
