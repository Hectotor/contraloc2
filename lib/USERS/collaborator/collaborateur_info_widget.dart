import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CollaborateurInfoWidget extends StatefulWidget {
  final bool showTitle;
  final bool showNom;
  final bool showPrenom;
  final bool showEmail;
  final bool showTelephone;
  final bool showAdresse;
  final TextStyle? titleStyle;
  final TextStyle? infoStyle;
  final EdgeInsets padding;

  const CollaborateurInfoWidget({
    Key? key,
    this.showTitle = true,
    this.showNom = true,
    this.showPrenom = true,
    this.showEmail = true,
    this.showTelephone = true,
    this.showAdresse = true,
    this.titleStyle,
    this.infoStyle,
    this.padding = const EdgeInsets.all(16.0),
  }) : super(key: key);

  @override
  State<CollaborateurInfoWidget> createState() => _CollaborateurInfoWidgetState();
}

class _CollaborateurInfoWidgetState extends State<CollaborateurInfoWidget> {
  bool _isLoading = true;
  Map<String, dynamic> _collaborateurInfo = {};

  @override
  void initState() {
    super.initState();
    _loadCollaborateurInfo();
  }

  Future<void> _loadCollaborateurInfo() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        // Charger les informations du collaborateur directement depuis son document principal
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();
            
        if (userDoc.exists) {
          final data = userDoc.data() as Map<String, dynamic>;
          setState(() {
            _collaborateurInfo = {
              'email': currentUser.email ?? '',
              'nom': data['nom'] ?? '',
              'prenom': data['prenom'] ?? '',
              'telephone': data['telephone'] ?? '',
              'adresse': data['adresse'] ?? '',
            };
          });
        }
      }
    } catch (e) {
      print('Erreur lors du chargement des informations du collaborateur: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
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
    if (_collaborateurInfo.isEmpty) {
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
                    Icons.person,
                    color: const Color(0xFF1A237E),
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Mes informations personnelles',
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
                if (widget.showNom && _collaborateurInfo['nom'] != null && _collaborateurInfo['nom'].isNotEmpty)
                  _buildInfoRow(
                    icon: Icons.badge,
                    label: 'Nom',
                    value: _collaborateurInfo['nom'],
                  ),
                if (widget.showPrenom && _collaborateurInfo['prenom'] != null && _collaborateurInfo['prenom'].isNotEmpty)
                  _buildInfoRow(
                    icon: Icons.person_outline,
                    label: 'Prénom',
                    value: _collaborateurInfo['prenom'],
                  ),
                if (widget.showEmail && _collaborateurInfo['email'] != null && _collaborateurInfo['email'].isNotEmpty)
                  _buildInfoRow(
                    icon: Icons.email_outlined,
                    label: 'Email',
                    value: _collaborateurInfo['email'],
                  ),
                if (widget.showTelephone && _collaborateurInfo['telephone'] != null && _collaborateurInfo['telephone'].isNotEmpty)
                  _buildInfoRow(
                    icon: Icons.phone_outlined,
                    label: 'Téléphone',
                    value: _collaborateurInfo['telephone'],
                  ),
                if (widget.showAdresse && _collaborateurInfo['adresse'] != null && _collaborateurInfo['adresse'].isNotEmpty)
                  _buildInfoRow(
                    icon: Icons.location_on_outlined,
                    label: 'Adresse',
                    value: _collaborateurInfo['adresse'],
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
