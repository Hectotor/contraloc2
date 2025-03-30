import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../USERS/popup_deconnexion.dart';
import '../USERS/question_user.dart';
import '../USERS/Subscription/abonnement_screen.dart';
import '../USERS/contrat_condition.dart';
import '../USERS/collaborator/collaborator.dart';
import '../USERS/supprimer_compte.dart';
import '../USERS/profile.dart';
import '../services/collaborateur_util.dart';

class UserScreen extends StatefulWidget {
  const UserScreen({Key? key}) : super(key: key);

  @override
  State<UserScreen> createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  String _prenom = '';
  String _nomEntreprise = '';
  bool _isCollaborateur = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Méthode pour charger les données utilisateur
  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Vérifier si l'utilisateur est un collaborateur
      final status = await CollaborateurUtil.checkCollaborateurStatus();
      final isCollaborateur = status['isCollaborateur'] == true;
      
      // Récupérer les données d'authentification
      final authData = await CollaborateurUtil.getAuthData();
      String prenom = authData['prenom'] ?? '';
      String nomEntreprise = authData['nomEntreprise'] ?? '';
      
      if (isCollaborateur) {
        // Pour un collaborateur, utiliser son prénom depuis son document utilisateur
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          try {
            // Essayer d'abord depuis le cache
            try {
              final userDoc = await FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .get(const GetOptions(source: Source.cache));
              
              if (userDoc.exists && userDoc.data() != null) {
                final userData = userDoc.data()!;
                if (userData.containsKey('prenom') && userData['prenom'] != null) {
                  prenom = userData['prenom'];
                  print('✅ Prénom du collaborateur récupéré depuis le cache: $prenom');
                }
              }
            } catch (cacheError) {
              print('⚠️ Tentative de cache échouée, nouvelle tentative avec le serveur: $cacheError');
              // Si la cache échoue, essayer le serveur
              final userDoc = await FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .get(const GetOptions(source: Source.server));
              
              if (userDoc.exists && userDoc.data() != null) {
                final userData = userDoc.data()!;
                if (userData.containsKey('prenom') && userData['prenom'] != null) {
                  prenom = userData['prenom'];
                  print('✅ Prénom du collaborateur récupéré depuis le serveur: $prenom');
                }
              }
            }
          } catch (e) {
            print('⚠️ Erreur lors de la récupération du prénom du collaborateur: $e');
          }
        }
      }
      
      setState(() {
        _prenom = prenom;
        _nomEntreprise = nomEntreprise;
        _isCollaborateur = isCollaborateur;
        _isLoading = false;
      });
    } catch (e) {
      print('Erreur lors du chargement des données utilisateur: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Méthode pour réinitialiser le mot de passe
  Future<void> _resetPassword() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _auth.sendPasswordResetEmail(email: user.email!);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Un email de réinitialisation a été envoyé à votre adresse."),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erreur : $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Mon Compte",
          style: TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF08004D),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.help_outline, color: Colors.white),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const QuestionUser()),
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => PopupDeconnexion.showLogoutConfirmationDialog(context),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // En-tête avec salutation
                      _buildHeader(),
                      const SizedBox(height: 24),
                      
                      // Section principale avec les cartes
                      _buildMainSection(),
                      const SizedBox(height: 30),
                      
                      // Section des paramètres du compte
                      _buildAccountSettings(),
                      const SizedBox(height: 40),
                      
                      // Pied de page
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: Text(
                            'Version 1.1.0\nFabriqué en France  \nDepuis 2020 - Contraloc.fr',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  // Widget d'en-tête avec salutation
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: "Bonjour, ",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                TextSpan(
                  text: _prenom,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A237E),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isCollaborateur
                ? "Accédez à vos paramètres et options"
                : "Gérez votre compte et vos préférences",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          if (!_isCollaborateur && _nomEntreprise.isNotEmpty) ...[  
            const SizedBox(height: 8),
            Text(
              "Entreprise: $_nomEntreprise",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1A237E),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Section principale avec les cartes de fonctionnalités
  Widget _buildMainSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Carte "Gérer mon profil"
        _buildFeatureCard(
          title: "Gérer mon profil",
          description: "Modifier vos informations personnelles et professionnelles",
          icon: Icons.person,
          color: const Color(0xFF1A237E),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfileScreen()),
            );
          },
        ),
        
        // Carte "Gérer mon abonnement" - visible uniquement pour les administrateurs
        if (!_isCollaborateur) ...[  
          const SizedBox(height: 16),
          _buildFeatureCard(
            title: "Gérer mon abonnement",
            description: "Consulter et modifier votre formule d'abonnement",
            icon: Icons.subscriptions,
            color: Colors.green[700]!,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AbonnementScreen()),
              );
            },
          ),
          
          const SizedBox(height: 16),
          // Carte "Ajouter un collaborateur"
          _buildFeatureCard(
            title: "Ajouter un collaborateur",
            description: "Gérer les accès de vos collaborateurs",
            icon: Icons.people,
            color: Colors.purple[700]!,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CollaboratorPage(
                    adminId: _auth.currentUser!.uid,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          // Carte "Personnaliser le contrat de location"
          _buildFeatureCard(
            title: "Personnaliser le contrat",
            description: "Modifier les termes et conditions de vos contrats",
            icon: Icons.description,
            color: Colors.blue[700]!,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ContratModifier()),
              );
            },
          ),
        ],
      ],
    );
  }

  // Section des paramètres du compte
  Widget _buildAccountSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 8, bottom: 16),
          child: Text(
            "Paramètres du compte",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF08004D),
            ),
          ),
        ),
        // Carte "Modifier mon mot de passe"
        _buildFeatureCard(
          title: "Modifier mon mot de passe",
          description: "Recevoir un email pour réinitialiser votre mot de passe",
          icon: Icons.lock,
          color: Colors.orange[700]!,
          onTap: _resetPassword,
        ),
        const SizedBox(height: 16),
        // Carte "Supprimer mon compte"
        _buildFeatureCard(
          title: "Supprimer mon compte",
          description: "Supprimer définitivement votre compte et vos données",
          icon: Icons.delete_forever,
          color: Colors.red[700]!,
          onTap: () {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return const SupprimerCompte();
              },
            );
          },
        ),
      ],
    );
  }

  // Widget de carte pour les fonctionnalités
  Widget _buildFeatureCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF08004D),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey[400],
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
