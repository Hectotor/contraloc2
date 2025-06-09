import 'package:flutter/material.dart';
import '../client_search.dart';

class PersonalInfoContainer extends StatefulWidget {
  final TextEditingController entrepriseClientController;
  final TextEditingController nomController;
  final TextEditingController prenomController;
  final TextEditingController emailController;
  final TextEditingController telephoneController;
  final TextEditingController adresseController;

  const PersonalInfoContainer({
    Key? key,
    required this.entrepriseClientController,
    required this.nomController,
    required this.prenomController,
    required this.emailController,
    required this.telephoneController,
    required this.adresseController,
  }) : super(key: key);

  @override
  State<PersonalInfoContainer> createState() => _PersonalInfoContainerState();
}

class _PersonalInfoContainerState extends State<PersonalInfoContainer> {
  bool _showContent = true;
  final TextEditingController _searchController = TextEditingController();

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  Widget _buildField(BuildContext context, String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                if (label == 'Téléphone' && value != null && value.isNotEmpty) {
                  return null;
                }
                return null;
              },
              keyboardType: label == 'Téléphone' ? TextInputType.phone : null,
              onChanged: (value) {
                if (label == 'Prénom' || label == 'Nom' || label == 'Adresse' || label == 'Entreprise') {
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
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: GestureDetector(
          onTap: () {
            showClientSearchDialog(
              context: context,
              onClientSelected: (client) {
                // Remplir les champs avec les données du client sélectionné
                setState(() {
                  widget.entrepriseClientController.text = client['entreprise'] ?? '';
                  widget.nomController.text = client['nom'] ?? '';
                  widget.prenomController.text = client['prenom'] ?? '';
                  widget.emailController.text = client['email'] ?? '';
                  widget.telephoneController.text = client['telephone'] ?? '';
                  widget.adresseController.text = client['adresse'] ?? '';
                });
              },
            );
          },
          child: TextField(
            controller: _searchController,
            enabled: false, // Désactivé pour que le tap ouvre le popup à la place
            decoration: InputDecoration(
              hintText: 'Rechercher un client existant...',
              prefixIcon: const Icon(Icons.search, color: Color(0xFF08004D)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF08004D)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF08004D), width: 1),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF08004D), width: 1),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            ),
          ),
        ),
      ),
      _buildField(context, 'Entreprise', widget.entrepriseClientController),
      _buildField(context, 'Prénom', widget.prenomController),
      _buildField(context, 'Nom', widget.nomController),
      _buildField(context, 'Adresse', widget.adresseController),
      _buildField(context, 'Téléphone', widget.telephoneController),
      _buildField(context, 'Email', widget.emailController),
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
            // En-tête de la carte avec flèche
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
                    Row(
                      children: [
                        Icon(
                          Icons.person,
                          color: const Color(0xFF08004D),
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Informations client',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF08004D),
                          ),
                        ),
                      ],
                    ),
                    Icon(
                      _showContent ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      color: const Color(0xFF08004D),
                      size: 24,
                    ),
                  ],
                ),
              ),
            ),
            if (_showContent) ..._buildFields(context),
          ],
        ),
      ),
    );
  }
}
