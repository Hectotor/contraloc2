import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/collaborateur_util.dart';

class AdminInfoWidget extends StatefulWidget {
  final bool showTitle;
  final bool showNomEntreprise;
  final bool showTelephone;
  final bool showAdresse;
  final bool showSiret;
  final TextStyle? titleStyle;
  final TextStyle? infoStyle;
  final EdgeInsets padding;

  const AdminInfoWidget({
    Key? key,
    this.showTitle = true,
    this.showNomEntreprise = true,
    this.showTelephone = true,
    this.showAdresse = true,
    this.showSiret = true,
    this.titleStyle,
    this.infoStyle,
    this.padding = const EdgeInsets.all(8.0),
  }) : super(key: key);

  @override
  State<AdminInfoWidget> createState() => _AdminInfoWidgetState();
}

class _AdminInfoWidgetState extends State<AdminInfoWidget> {
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
          print('Informations admin trouvées dans la sous-collection authentification');
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
        padding: widget.padding,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Si aucune information n'est disponible
    if (_adminInfo.isEmpty) {
      return Container(
        padding: widget.padding,
        child: const Center(
          child: Text('Informations non disponibles'),
        ),
      );
    }

    // Définir les styles par défaut si non fournis
    final titleStyle = widget.titleStyle ?? 
        const TextStyle(fontWeight: FontWeight.bold, fontSize: 16);
    final infoStyle = widget.infoStyle ?? 
        const TextStyle(fontSize: 14);

    return Container(
      padding: widget.padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.showTitle)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                'Informations de l\'entreprise',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
          if (widget.showNomEntreprise && _adminInfo['nomEntreprise'] != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'Entreprise: ',
                      style: titleStyle.copyWith(
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    TextSpan(
                      text: _adminInfo['nomEntreprise'],
                      style: infoStyle.copyWith(
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (widget.showTelephone && _adminInfo['telephone'] != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'Téléphone: ',
                      style: titleStyle.copyWith(
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    TextSpan(
                      text: _adminInfo['telephone'],
                      style: infoStyle.copyWith(
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (widget.showAdresse && _adminInfo['adresse'] != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'Adresse: ',
                      style: titleStyle.copyWith(
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    TextSpan(
                      text: _adminInfo['adresse'],
                      style: infoStyle.copyWith(
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (widget.showSiret && _adminInfo['siret'] != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'SIRET: ',
                      style: titleStyle.copyWith(
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    TextSpan(
                      text: _adminInfo['siret'],
                      style: infoStyle.copyWith(
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
