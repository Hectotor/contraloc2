import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/collaborateur_util.dart';

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
    this.padding = const EdgeInsets.all(16.0),
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

    return Container(
      padding: widget.padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.showTitle)
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Row(
                children: [
                  Icon(
                    Icons.business,
                    color: const Color(0xFF1A237E),
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Informations de l\'entreprise',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: const Color(0xFF1A237E),
                    ),
                  ),
                ],
              ),
            ),
          Container(
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
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.showNomEntreprise && _adminInfo['nomEntreprise'] != null)
                  _buildInfoRow(
                    icon: Icons.business_center,
                    label: 'Entreprise',
                    value: _adminInfo['nomEntreprise'],
                  ),
                if (widget.showTelephone && _adminInfo['telephone'] != null)
                  _buildInfoRow(
                    icon: Icons.phone,
                    label: 'Téléphone',
                    value: _adminInfo['telephone'],
                  ),
                if (widget.showAdresse && _adminInfo['adresse'] != null)
                  _buildInfoRow(
                    icon: Icons.location_on,
                    label: 'Adresse',
                    value: _adminInfo['adresse'],
                  ),
                if (widget.showSiret && _adminInfo['siret'] != null)
                  _buildInfoRow(
                    icon: Icons.numbers,
                    label: 'SIRET',
                    value: _adminInfo['siret'],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({required IconData icon, required String label, required String value}) {
    final titleStyle = widget.titleStyle ?? 
        const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Color(0xFF424242));
    final infoStyle = widget.infoStyle ?? 
        const TextStyle(fontSize: 16, color: Color(0xFF1A237E));

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: const Color(0xFF1A237E)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: titleStyle),
                const SizedBox(height: 4),
                Text(value, style: infoStyle),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
