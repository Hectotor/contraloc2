import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_util.dart';

class AdminInfoWidget extends StatefulWidget {
  final bool showTitle;
  final bool showNomEntreprise;
  final bool showTelephone;
  final bool showAdresse;
  final bool showSiret;
  final TextStyle? titleStyle;
  final TextStyle? infoStyle;
  final EdgeInsets padding;
  final bool editable;

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
    this.editable = false,
  }) : super(key: key);

  @override
  State<AdminInfoWidget> createState() => _AdminInfoWidgetState();
}

class _AdminInfoWidgetState extends State<AdminInfoWidget> {
  bool _isLoading = true;
  bool _showContent = true;
  bool _isSaving = false;
  bool _isCollaborateur = false; // Ajouter un champ pour stocker si l'utilisateur est un collaborateur
  Map<String, dynamic> _adminInfo = {};
  String? _adminId;

  final TextEditingController _entrepriseController = TextEditingController();
  final TextEditingController _telephoneController = TextEditingController();
  final TextEditingController _adresseController = TextEditingController();
  final TextEditingController _siretController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAdminInfo();
  }

  @override
  void dispose() {
    _entrepriseController.dispose();
    _telephoneController.dispose();
    _adresseController.dispose();
    _siretController.dispose();
    super.dispose();
  }

  Future<void> _loadAdminInfo() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Vérifier si l'utilisateur est un collaborateur
      final authData = await AuthUtil.getAuthData();
      _isCollaborateur = authData['isCollaborateur'] ?? false;
      _adminId = authData['adminId'];

      if (_adminId != null) {
        final adminDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(_adminId)
            .collection('authentification')
            .doc(_adminId)
            .get();

        if (adminDoc.exists) {
          setState(() {
            _adminInfo = adminDoc.data() ?? {};

            _entrepriseController.text = _adminInfo['nomEntreprise'] ?? '';
            _telephoneController.text = _adminInfo['telephone'] ?? '';
            _adresseController.text = _adminInfo['adresse'] ?? '';
            _siretController.text = _adminInfo['siret'] ?? '';
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

  Future<void> _saveAdminInfo() async {
    if (_adminId == null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final updatedData = {
        'nomEntreprise': _entrepriseController.text.trim(),
        'telephone': _telephoneController.text.trim(),
        'adresse': _adresseController.text.trim(),
        'siret': _siretController.text.trim(),
      };

      // Mettre à jour les données dans Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_adminId)
          .collection('authentification')
          .doc(_adminId)
          .set(updatedData, SetOptions(merge: true)); // Utilisation de set() avec merge: true au lieu de update()

      setState(() {
        _adminInfo.addAll(updatedData);
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

    if (_adminInfo.isEmpty) {
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
                      'Informations administrateur',
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
                    if (widget.showNomEntreprise)
                      _buildInfoRow(
                        icon: null,
                        label: 'Entreprise',
                        controller: _entrepriseController,
                      ),
                    if (widget.showTelephone)
                      _buildInfoRow(
                        icon: null,
                        label: 'Téléphone',
                        controller: _telephoneController,
                      ),
                    if (widget.showAdresse)
                      _buildInfoRow(
                        icon: null,
                        label: 'Adresse',
                        controller: _adresseController,
                      ),
                    if (widget.showSiret)
                      _buildInfoRow(
                        icon: null,
                        label: 'SIRET',
                        controller: _siretController,
                      ),
                    // Afficher le bouton de sauvegarde uniquement si l'édition est permise et que l'utilisateur n'est pas un collaborateur
                    if (widget.editable && !_isCollaborateur)
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
                          onPressed: _isSaving ? null : _saveAdminInfo,
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

  Widget _buildInfoRow({
    required IconData? icon,
    required String label,
    required TextEditingController controller,
  }) {
    // Si c'est un collaborateur, l'édition n'est jamais permise, quelle que soit la valeur de widget.editable
    final bool canEdit = widget.editable && !_isCollaborateur;
    
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
                color: Color(0xFF08004D),
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
                color: Colors.white,
              ),
              padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
              child: canEdit
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
                        color: Color(0xFF08004D),
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
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF08004D),
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
}
