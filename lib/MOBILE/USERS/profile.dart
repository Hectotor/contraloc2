import 'package:flutter/material.dart';
import 'package:contraloc/MOBILE/services/auth_util.dart';

import 'collaborator/admin_info_widget.dart';
import 'collaborator/admin_logo_widget.dart';
import 'collaborator/admin_perso_widget.dart';
import 'collaborator/collaborateur_info_widget.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  bool _isCollaborateur = false;



  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authData = await AuthUtil.getAuthData();
      setState(() {
        _isCollaborateur = authData['isCollaborateur'] ?? false;
      });
    } catch (e) {
      print('Erreur lors du chargement des données: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Mon Profil",
          style: TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF08004D),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo de l'entreprise
                Container(
                  alignment: Alignment.center,
                  width: double.infinity,
                  child: AdminLogoWidget(
                    // Permettre la modification du logo seulement si l'utilisateur n'est pas un collaborateur
                    editable: !_isCollaborateur,
                  ),
                ),

              // Informations de l'entreprise
            const SizedBox(height: 24),
                AdminInfoWidget(
                  showTitle: true,
                  showNomEntreprise: true,
                  showTelephone: true,
                  showAdresse: true,
                  showSiret: true,
                  padding: const EdgeInsets.only(bottom: 20),
                  editable: true,
                ),

              // Informations personnelles de l'admin
              if (!_isCollaborateur)
                AdminPersoWidget(
                  showNom: true,
                  showPrenom: true,
                  showEmail: true,
                  showTelephone: true,
                  showAdresse: true,
                  padding: const EdgeInsets.only(bottom: 20),
                  editable: true,
                ),

              // Informations personnelles du collaborateur
              if (_isCollaborateur)
                CollaborateurInfoWidget(
                  showTitle: true,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  editable: true, // Ajout du paramètre pour rendre les champs modifiables
                ),
            const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }

}
