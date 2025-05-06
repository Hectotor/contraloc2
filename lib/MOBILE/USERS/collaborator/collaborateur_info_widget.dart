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
  final bool editable;

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
    this.editable = false,
  }) : super(key: key);

  @override
  State<CollaborateurInfoWidget> createState() => _CollaborateurInfoWidgetState();
}

class _CollaborateurInfoWidgetState extends State<CollaborateurInfoWidget> {
  bool _isLoading = true;
  bool _showContent = true;
  bool _isSaving = false;
  Map<String, dynamic> _collaborateurInfo = {};
  String? _userId;

  final TextEditingController _nomController = TextEditingController();
  final TextEditingController _prenomController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _telephoneController = TextEditingController();
  final TextEditingController _adresseController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCollaborateurInfo();
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _emailController.dispose();
    _telephoneController.dispose();
    _adresseController.dispose();
    super.dispose();
  }

  Future<void> _loadCollaborateurInfo() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      _userId = currentUser.uid;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get(const GetOptions(source: Source.server));

      if (userDoc.exists && userDoc.data() != null) {
        final data = userDoc.data() as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            _collaborateurInfo = {
              'email': currentUser.email ?? '',
              'nom': data['nom'] ?? '',
              'prenom': data['prenom'] ?? '',
              'telephone': data['telephone'] ?? '',
              'adresse': data['adresse'] ?? '',
            };

            _nomController.text = _collaborateurInfo['nom'];
            _prenomController.text = _collaborateurInfo['prenom'];
            _emailController.text = _collaborateurInfo['email'];
            _telephoneController.text = _collaborateurInfo['telephone'] ?? '';
            _adresseController.text = _collaborateurInfo['adresse'] ?? '';
          });
        }
      }
    } catch (error) {
      if (mounted) {
        print('Erreur lors du chargement des informations du collaborateur: $error');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveCollaborateurInfo() async {
    if (_userId == null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      // L'email n'est pas inclus intentionnellement pour empêcher sa modification
      // Téléphone et adresse sont également omis car ils ont été retirés de l'interface
      final updatedData = {
        'nom': _nomController.text.trim(),
        'prenom': _prenomController.text.trim(),
      };

      // Utilisation de set() avec merge: true au lieu de update() pour éviter les problèmes de permission
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .set(updatedData, SetOptions(merge: true));

      setState(() {
        _collaborateurInfo['nom'] = updatedData['nom'];
        _collaborateurInfo['prenom'] = updatedData['prenom'];
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informations mises à jour avec succès')),
      );
    } catch (e) {
      print('Erreur lors de la sauvegarde des informations: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  Widget _buildInfoRow({
    required IconData? icon,
    required String label,
    required TextEditingController controller,
    bool readOnly = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF08004D),
                  width: 1,
                ),
                color: readOnly ? const Color(0xFFF5F5F5) : Colors.white,
              ),
              padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
              child: widget.editable && !readOnly
                  ? TextFormField(
                      controller: controller,
                      maxLines: null,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        icon: icon != null ? Icon(icon, color: const Color(0xFF08004D), size: 20) : null,
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (icon != null) ...[
                          Icon(
                            icon,
                            color: const Color(0xFF08004D),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                          child: Text(
                            controller.text,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: readOnly && widget.editable
                                  ? const Color(0xFF666666)
                                  : Colors.black87,
                            ),
                            softWrap: true,
                            overflow: TextOverflow.visible,
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        padding: widget.padding,
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFF08004D)),
          ),
        ),
      );
    }

    if (_collaborateurInfo.isEmpty) {
      return Container(
        padding: widget.padding,
        child: Center(
          child: Text(
            'Informations non disponibles',
            style: const TextStyle(
              color: Color(0xFF08004D),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.20),
            blurRadius: 4,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () {
                setState(() {
                  _showContent = !_showContent;
                });
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF08004D).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Informations personnelles',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF08004D),
                      ),
                    ),
                    Icon(
                      _showContent ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      color: const Color(0xFF08004D),
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
            if (_showContent) ...[
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.showNom)
                      _buildInfoRow(
                        icon: null,
                        label: 'Nom',
                        controller: _nomController,
                      ),
                    if (widget.showPrenom)
                      _buildInfoRow(
                        icon: null,
                        label: 'Prénom',
                        controller: _prenomController,
                      ),
                    if (widget.showEmail)
                      _buildInfoRow(
                        icon: null,
                        label: 'Email',
                        controller: _emailController,
                        readOnly: true,
                      ),
                    if (widget.editable)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF08004D),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _isSaving ? null : _saveCollaborateurInfo,
                          child: SizedBox(
                            width: double.infinity,
                            child: Center(
                              child: _isSaving
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : const Text(
                                      'Sauvegarder',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
