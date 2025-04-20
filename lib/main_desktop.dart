import 'package:flutter/material.dart';
// Importe ici tes widgets desktop, par exemple :
// import 'desktop/app_desktop.dart';

void main() {
  runApp(const ContralocDesktopApp());
}

class ContralocDesktopApp extends StatelessWidget {
  const ContralocDesktopApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Mets ici ton widget racine desktop (sidebar, navigation, etc.)
    return MaterialApp(
      title: 'Contraloc Desktop',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        // Ajoute un thème adapté au desktop ici
      ),
      home: Scaffold(
        body: Center(
          child: Text(
            'Bienvenue sur Contraloc Desktop !\nCommence à construire ton interface PC ici.',
            style: TextStyle(fontSize: 24),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}