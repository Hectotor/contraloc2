import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/collaborateur_util.dart';
import '../tampon.dart';

class AdminTamponWidget extends StatefulWidget {
  final double width;
  final double height;
  final EdgeInsets padding;

  const AdminTamponWidget({
    Key? key,
    this.width = 300,
    this.height = 200,
    this.padding = const EdgeInsets.all(8.0),
  }) : super(key: key);

  @override
  State<AdminTamponWidget> createState() => _AdminTamponWidgetState();
}

class _AdminTamponWidgetState extends State<AdminTamponWidget> {
  bool _isLoading = true;
  Map<String, dynamic> _adminInfo = {};

  @override
  void initState() {
    super.initState();
    _loadAdminInfo();
  }

  Future<void> _loadAdminInfo() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Vérifier si l'utilisateur est un collaborateur
      final status = await CollaborateurUtil.checkCollaborateurStatus();
      final isCollaborateur = status['isCollaborateur'] == true;
      
      if (isCollaborateur) {
        final adminId = status['adminId'];
        if (adminId != null) {
          // Récupérer les informations de l'admin
          final adminInfo = await _getAdminInfo(adminId);
          
          setState(() {
            _adminInfo = adminInfo ?? {};
          });
        }
      }
    } catch (e) {
      print('Erreur lors du chargement des informations admin: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<Map<String, dynamic>?> _getAdminInfo(String adminId) async {
    try {
      // Essayer d'accéder à la sous-collection authentification
      try {
        final adminAuthDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(adminId)
            .collection('authentification')
            .doc(adminId)
            .get();
        
        if (adminAuthDoc.exists) {
          print('Informations tampon admin trouvées dans la sous-collection authentification');
          return adminAuthDoc.data();
        }
      } catch (e) {
        print('Erreur d\'accès à la sous-collection authentification: $e');
      }
      
      // Si les informations ne sont pas trouvées, essayer via CollaborateurUtil
      return await CollaborateurUtil.getAuthData();
    } catch (e) {
      print('Erreur lors de la récupération des informations admin: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        width: widget.width,
        height: widget.height,
        padding: widget.padding,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Si aucune information n'est disponible
    if (_adminInfo.isEmpty) {
      return Container(
        width: widget.width,
        height: widget.height,
        padding: widget.padding,
        child: const Center(
          child: Text('Tampon non disponible'),
        ),
      );
    }

    // Extraire les données pour le tampon
    final logoUrl = _adminInfo['logoUrl'];
    final nomEntreprise = _adminInfo['nomEntreprise'] ?? '';
    final adresse = _adminInfo['adresse'] ?? '';
    final telephone = _adminInfo['telephone'] ?? '';
    final siret = _adminInfo['siret'] ?? '';

    return Container(
      padding: widget.padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Center(
            child: Text(
              'Tampon de l\'entreprise',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Tampon(
            logoPath: logoUrl ?? '',
            nomEntreprise: nomEntreprise,
            adresse: adresse,
            telephone: telephone,
            siret: siret,
          ),
        ],
      ),
    );
  }
}
