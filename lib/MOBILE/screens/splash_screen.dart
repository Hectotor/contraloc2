import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'login.dart';
import '../widget/navigation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/auth_util.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  String? _enterpriseLogoUrl;
  bool _showEnterpriseLogo = false;

  @override
  void initState() {
    super.initState();
    
    // Configuration de l'animation
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Interval(0.0, 0.6, curve: Curves.easeOut),
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.85,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Interval(0.3, 0.8, curve: Curves.easeOutBack),
    ));
    
    // Démarrer l'animation
    _controller.forward();
    
    // Charger le logo de l'entreprise en arrière-plan
    _loadEnterpriseLogo();
    
    _navigateToNextPage();
  }

  Future<void> _loadEnterpriseLogo() async {
    final logoUrl = await _getEnterpriseLogoUrl();
    if (logoUrl != null && mounted) {
      // Attendre 2 secondes avant d'afficher le logo de l'entreprise
      await Future.delayed(const Duration(milliseconds: 2000));
      if (mounted) {
        setState(() {
          _enterpriseLogoUrl = logoUrl;
          _showEnterpriseLogo = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _navigateToNextPage() async {
    await Future.delayed(const Duration(milliseconds: 5000));
    User? user = FirebaseAuth.instance.currentUser;
    if (!mounted) return;

    if (user != null) {
      // Synchroniser Firestore si l'email est confirmé côté Firebase ET que le doc existe déjà
      final authDocRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('authentification')
          .doc(user.uid);
      final authDocSnapshot = await authDocRef.get();
      final docExists = authDocSnapshot.exists;
      if (user.emailVerified && docExists) {
        await authDocRef.update({'emailVerifie': true});
      }
      // Vérification Firestore du champ emailVerifie dans la sous-collection authentification
      try {
        final authDoc = await authDocRef.get();
        final data = authDoc.data();
        final hasEmailVerifie = data != null && data.containsKey('emailVerifie');
        final emailVerifie = hasEmailVerifie ? data['emailVerifie'] : null;
        if (data == null || !hasEmailVerifie || emailVerifie == true) {
          // Champ absent OU true OU pas de doc -> laisser passer
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => NavigationPage()),
          );
        } else {
          // Champ présent ET false -> bloquer
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => LoginPage()),
          );
        }
      } catch (e) {
        if (e.toString().contains('not-found')) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => NavigationPage()),
          );
        } else {
          print('Erreur Firestore: $e');
          // Optionnel : afficher une erreur à l'utilisateur
        }
      }
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => LoginPage()),
      );
    }
  }

  Future<String?> _getEnterpriseLogoUrl() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      // Récupérer les données d'authentification
      final authData = await AuthUtil.getAuthData();
      final adminId = authData['adminId'];

      if (adminId != null) {
        // Essayer d'accéder à la sous-collection authentification
        try {
          final adminAuthDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(adminId)
              .collection('authentification')
              .doc(adminId)
              .get();
          
          if (adminAuthDoc.exists && adminAuthDoc.data()?['logoUrl'] != null) {
            return adminAuthDoc.data()?['logoUrl'];
          }
        } catch (e) {
          print('Erreur d\'accès à la sous-collection authentification: $e');
        }
      }
    } catch (e) {
      print('Erreur lors de la récupération du logo: $e');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo avec effet d'ombre douce
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFF08004D).withOpacity(0.15),
                              blurRadius: 25,
                              spreadRadius: 0,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        child: AnimatedCrossFade(
                          duration: const Duration(milliseconds: 500),
                          firstChild: ClipRRect(
                            borderRadius: BorderRadius.circular(100),
                            child: Image.asset(
                              'assets/icon/logoCon.png',
                              width: 180,
                              height: 180,
                              fit: BoxFit.cover,
                            ),
                          ),
                          secondChild: _enterpriseLogoUrl != null ? CachedNetworkImage(
                            imageUrl: _enterpriseLogoUrl!,
                            width: 180,
                            height: 180,
                            fit: BoxFit.contain,
                            placeholder: (context, url) => ClipRRect(
                              borderRadius: BorderRadius.circular(100),
                              child: Image.asset(
                                'assets/icon/logoCon.png',
                                width: 180,
                                height: 180,
                                fit: BoxFit.cover,
                              ),
                            ),
                            errorWidget: (context, url, error) => ClipRRect(
                              borderRadius: BorderRadius.circular(100),
                              child: Image.asset(
                                'assets/icon/logoCon.png',
                                width: 180,
                                height: 180,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ) : ClipRRect(
                            borderRadius: BorderRadius.circular(100),
                            child: Image.asset(
                              'assets/icon/logoCon.png',
                              width: 180,
                              height: 180,
                              fit: BoxFit.cover,
                            ),
                          ),
                          crossFadeState: _showEnterpriseLogo && _enterpriseLogoUrl != null
                              ? CrossFadeState.showSecond
                              : CrossFadeState.showFirst,
                        ),
                      ),
                      const SizedBox(height: 40),
                      
                      // Titre avec dégradé subtil
                      ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          colors: [Color(0xFF08004D), Color(0xFF1A237E)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(bounds),
                        child: const Text(
                          'ContraLoc',
                          style: TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      
                      // Sous-titre animé avec couleur plus douce
                      DefaultTextStyle(
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF08004D).withOpacity(0.7),
                          letterSpacing: 0.5,
                          fontWeight: FontWeight.w500,
                        ),
                        child: AnimatedTextKit(
                          animatedTexts: [
                            TypewriterAnimatedText(
                              'Simplifiez votre gestion locative',
                              speed: const Duration(milliseconds: 80),
                            ),
                          ],
                          isRepeatingAnimation: false,
                        ),
                      ),
                      const SizedBox(height: 60),
                      
                      // Indicateur de chargement modernisé
                      SizedBox(
                        width: 45,
                        height: 45,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF08004D).withOpacity(0.6),
                          ),
                          strokeWidth: 2.5,
                          backgroundColor: Color(0xFF08004D).withOpacity(0.1),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
