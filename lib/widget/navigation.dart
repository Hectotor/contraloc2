import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../screens/contrat_screen.dart';
import '../screens/user_screen.dart';
import '../screens/add_vehicule.dart';

class NavigationPage extends StatefulWidget {
  final String? fromPage;
  final int initialTab;

  const NavigationPage({Key? key, this.fromPage, this.initialTab = 0})
      : super(key: key);

  @override
  State<NavigationPage> createState() => _NavigationPageState();
}

class _NavigationPageState extends State<NavigationPage> {
  int _currentIndex = 0;

  // Liste des écrans
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const HomeScreen(),
      ContratScreen(showSuccessMessage: widget.fromPage == 'fromLocation'),
      const AddVehiculeScreen(),
      const UserScreen(),
    ];
    if (widget.fromPage == 'fromLocation') {
      _currentIndex = 1;
    }
    _currentIndex = widget.initialTab;
  }

  // Ajouter cette méthode pour changer l'index
  void setIndex(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void navigateToTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Ajout de cette ligne
      body: _screens[_currentIndex], // Affiche l'écran sélectionné
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 6,
              offset: const Offset(0, -3), // Ombre vers le haut
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setIndex(
                index); // Utiliser la méthode setIndex pour changer l'écran affiché
          },
          backgroundColor: Colors.white, // Fond blanc pour la barre
          selectedItemColor:
              const Color(0xFF0F056B), // Bleu nuit pour l'élément sélectionné
          unselectedItemColor:
              Colors.grey, // Gris pour les éléments non sélectionnés
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.bold, // Texte sélectionné en gras
            fontSize: 14,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 12, // Texte non sélectionné légèrement plus petit
          ),
          showUnselectedLabels: true, // Affiche les labels non sélectionnés
          elevation: 0, // Supprime l'ombre par défaut de la barre
          type: BottomNavigationBarType
              .fixed, // Fixe les icônes pour éviter le redimensionnement
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon:
                  Icon(Icons.home), // Icône pleine lorsqu'elle est sélectionnée
              label: "Home",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.description_outlined),
              activeIcon:
                  Icon(Icons.description), // Icône pleine pour "Contrat"
              label: "Contrats",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.add_outlined),
              activeIcon: Icon(Icons.add), // Icône pleine pour "Véhicule"
              label: "Véhicules",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person), // Icône pleine pour "User"
              label: "Profil",
            ),
          ],
        ),
      ),
    );
  }
}
