import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'login.dart';
import '../widget/navigation.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkUser();
  }

  Future<void> _checkUser() async {
    try {
      await Future.delayed(Duration(seconds: 2)); // Splash duration
      if (!mounted) return; // Vérifie si le widget est monté
      User? user =
          FirebaseAuth.instance.currentUser; // Vérifie l'utilisateur connecté
      if (user == null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => NavigationPage()),
        );
      }
    } catch (e) {
      print('Erreur FirebaseAuth: $e');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF08004D),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF08004D),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 250, // Réduit la taille
              height: 250, // Réduit la taille
              child: Image.asset(
                'assets/icon/LogoContraLoc.png',
                fit: BoxFit.contain, // Assure que l'image s'adapte correctement
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'ContraLoc',
              style: TextStyle(
                fontSize: 40, // Réduit légèrement la taille du texte
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}
