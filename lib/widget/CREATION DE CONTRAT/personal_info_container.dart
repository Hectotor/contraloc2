import 'package:flutter/material.dart';

class PersonalInfoContainer extends StatelessWidget {
  final TextEditingController nomController;
  final TextEditingController prenomController;
  final TextEditingController emailController;
  final TextEditingController telephoneController;
  final TextEditingController adresseController;

  const PersonalInfoContainer({
    Key? key,
    required this.nomController,
    required this.prenomController,
    required this.emailController,
    required this.telephoneController,
    required this.adresseController,
  }) : super(key: key);

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  bool _isValidPhone(String phone) {
    return RegExp(r'^[0-9]{10}$').hasMatch(phone);
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  Widget _buildField(BuildContext context, String label, TextEditingController controller) {
    final EdgeInsetsGeometry padding;
    if (label == 'Prénom') {
      padding = const EdgeInsets.only(left: 16, right: 16, top: 24, bottom: 8);
    } else if (label == 'Email') {
      padding = const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 24);
    } else {
      padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 5);
    }

    return Padding(
      padding: padding,
      child: Row(
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
            child: TextFormField(
              controller: controller,
              maxLines: null,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF08004D)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF08004D), width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF08004D), width: 2),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF08004D),
              ),
              validator: (value) {
                if (label == 'Email' && value != null && value.isNotEmpty && !_isValidEmail(value)) {
                  return 'Email non valide';
                }
                if (label == 'Téléphone' && value != null && value.isNotEmpty && !_isValidPhone(value)) {
                  return 'Numéro de téléphone invalide (10 chiffres requis)';
                }
                return null;
              },
              keyboardType: label == 'Téléphone' ? TextInputType.phone : null,
              onChanged: (value) {
                if (label == 'Prénom' || label == 'Nom' || label == 'Adresse') {
                  controller.value = TextEditingValue(
                    text: value.split(' ').map((word) => _capitalize(word)).join(' '),
                    selection: TextSelection.collapsed(offset: value.length),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildFields(BuildContext context) {
    return [
      _buildField(context, 'Prénom', prenomController),
      _buildField(context, 'Nom', nomController),
      _buildField(context, 'Adresse', adresseController),
      _buildField(context, 'Téléphone', telephoneController),
      _buildField(context, 'Email', emailController),
    ];
  }

  @override
  Widget build(BuildContext context) {
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
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF08004D).withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
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
                  IconButton(
                    icon: const Icon(Icons.edit, color: Color(0xFF08004D)),
                    onPressed: () {
                      // TODO: Ajouter la logique d'édition
                    },
                  ),
                ],
              ),
            ),
            ..._buildFields(context),
          ],
        ),
      ),
    );
  }
}
