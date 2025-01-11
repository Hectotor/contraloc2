import 'package:flutter/material.dart';
import '../widget/MES CONTRATS/contrat_condition.dart'; // Import de l'écran de modification
import '../widget/MES CONTRATS/contrat_encours.dart';
import '../widget/MES CONTRATS/contrat_restitues.dart';
import '../widget/MES CONTRATS/calendar.dart'; // Add this line

class ContratScreen extends StatefulWidget {
  final bool showSuccessMessage;
  final bool showRestitues;
  final BottomNavigationBar? bottomNavigationBar; // Add this line

  const ContratScreen({
    Key? key,
    this.showSuccessMessage = false,
    this.showRestitues = false,
    this.bottomNavigationBar, // Add this line
  }) : super(key: key);

  @override
  State<ContratScreen> createState() => _ContratScreenState();
}

class _ContratScreenState extends State<ContratScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  bool _showEnCours = true;
  bool _showRestitues = false;
  bool _showContrat = false;
  bool _showCalendar = false; // Add this line
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    // Set the initial tab based on the showRestitues parameter
    if (widget.showRestitues) {
      _showEnCours = false;
      _showRestitues = true;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Ajout ici
      appBar: AppBar(
        title: const Text(
          "Mes Contrats",
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF08004D),
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF08004D),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 30),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal, // Add this line
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildTabButton("En cours", _showEnCours, () {
                    setState(() {
                      _showEnCours = true;
                      _showRestitues = false;
                      _showContrat = false;
                      _showCalendar = false; // Add this line
                    });
                  }),
                  const SizedBox(width: 8), // Add this line
                  _buildTabButton("Restitués", _showRestitues, () {
                    setState(() {
                      _showEnCours = false;
                      _showRestitues = true;
                      _showContrat = false;
                      _showCalendar = false; // Add this line
                    });
                  }),
                  const SizedBox(width: 8), // Add this line
                  _buildTabButton("Contrat", _showContrat, () {
                    setState(() {
                      _showEnCours = false;
                      _showRestitues = false;
                      _showContrat = true;
                      _showCalendar = false; // Add this line
                    });
                  }),
                  const SizedBox(width: 8), // Add this line
                  _buildTabButton("Calendrier", _showCalendar, () {
                    setState(() {
                      _showEnCours = false;
                      _showRestitues = false;
                      _showContrat = false;
                      _showCalendar = true; // Add this line
                    });
                  }),
                ],
              ),
            ),
          ),
          if (!_showContrat) ...[
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: "Rechercher par nom, immatriculation...",
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    prefixIcon:
                        const Icon(Icons.search, color: Color(0xFF08004D)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                  ),
                  onChanged: (value) => setState(() {}),
                ),
              ),
            ),
          ],
          Expanded(
            child: _showContrat
                ? ContratModifier()
                : _showEnCours
                    ? ContratEnCours(searchText: _searchController.text)
                    : _showRestitues
                        ? ContratRestitues(searchText: _searchController.text)
                        : CalendarScreen(), // Add this line
          ),
        ],
      ),
      bottomNavigationBar: widget.bottomNavigationBar, // Add this line
    );
  }

  Widget _buildTabButton(String text, bool isSelected, VoidCallback onPressed) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isSelected ? Colors.white : Colors.white.withOpacity(0.3),
          foregroundColor: isSelected ? const Color(0xFF08004D) : Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          elevation: isSelected ? 4 : 0,
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
