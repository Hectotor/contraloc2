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
    this.padding = const EdgeInsets.all(8.0),
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
                'Mes informations personnelles',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
          if (widget.showNom && _collaborateurInfo['nom'] != null && _collaborateurInfo['nom'].isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'Nom: ',
                      style: titleStyle.copyWith(
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    TextSpan(
                      text: _collaborateurInfo['nom'],
                      style: infoStyle.copyWith(
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (widget.showPrenom && _collaborateurInfo['prenom'] != null && _collaborateurInfo['prenom'].isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'Prénom: ',
                      style: titleStyle.copyWith(
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    TextSpan(
                      text: _collaborateurInfo['prenom'],
                      style: infoStyle.copyWith(
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (widget.showEmail && _collaborateurInfo['email'] != null && _collaborateurInfo['email'].isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'Email: ',
                      style: titleStyle.copyWith(
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    TextSpan(
                      text: _collaborateurInfo['email'],
                      style: infoStyle.copyWith(
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (widget.showTelephone && _collaborateurInfo['telephone'] != null && _collaborateurInfo['telephone'].isNotEmpty)
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
                      text: _collaborateurInfo['telephone'],
                      style: infoStyle.copyWith(
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (widget.showAdresse && _collaborateurInfo['adresse'] != null && _collaborateurInfo['adresse'].isNotEmpty)
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
                      text: _collaborateurInfo['adresse'],
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
