import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';
import '../widget/chargement.dart';

// Importer Firebase Auth pour utiliser currentUser
// import 'package:firebase_auth/firebase_auth.dart';

class PopAddColab {
  // Utiliser currentUser dans le fichier pop_add_colab.dart
  static User? currentUser = FirebaseAuth.instance.currentUser;

  static String generateUserId() {
    final random = Random();
    final letter = String.fromCharCode(random.nextInt(26) + 65); // Lettre majuscule aléatoire
    final digits = List.generate(5, (index) => random.nextInt(10)).join(''); // 5 chiffres aléatoires
    return letter + digits; // Combiner la lettre et les chiffres
  }

  static void showAddColabDialog(BuildContext context, {Map<String, dynamic>? collaborateurData, String? collaborateurId}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return PopAddColabDialog(context, collaborateurData: collaborateurData, collaborateurId: collaborateurId);
      },
    );
  }
}

class PopAddColabDialog extends StatefulWidget {
  final BuildContext context;
  final Map<String, dynamic>? collaborateurData;
  final String? collaborateurId;

  const PopAddColabDialog(
    this.context, {
    Key? key,
    this.collaborateurData,
    this.collaborateurId,
  }) : super(key: key);

  @override
  _PopAddColabDialogState createState() => _PopAddColabDialogState();
}

class _PopAddColabDialogState extends State<PopAddColabDialog> {
  final TextEditingController nomController = TextEditingController();
  final TextEditingController prenomController = TextEditingController();
  final TextEditingController motDePasseController = TextEditingController();
  final TextEditingController idController = TextEditingController();

  bool _obscureText = true; // État pour gérer la visibilité du mot de passe

  @override
  void initState() {
    super.initState();
    if (widget.collaborateurData != null) {
      // Mode édition
      idController.text = widget.collaborateurData!['id'];
      nomController.text = widget.collaborateurData!['nom'];
      prenomController.text = widget.collaborateurData!['prenom'];
      motDePasseController.text = widget.collaborateurData!['motDePasse'];
    } else {
      // Mode création
      String id = PopAddColab.generateUserId(); // Générer l'ID avant d'ouvrir le popup
      idController.text = id; // Mettre à jour le champ de texte avec l'ID généré
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      content: Container(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const SizedBox(height: 20),
              TextField(
                controller: idController,
                decoration: InputDecoration(
                  labelText: 'ID Utilisateur',
                  labelStyle: TextStyle(color: Color(0xFF0F056B)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Color(0xFF0F056B), width: 2),
                  ),
                  prefixIcon: Icon(Icons.badge, color: Color(0xFF0F056B)),
                ),
                readOnly: true,
              ),
              const SizedBox(height: 15),
              TextField(
                controller: nomController,
                decoration: InputDecoration(
                  labelText: 'Nom',
                  labelStyle: TextStyle(color: Color(0xFF0F056B)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Color(0xFF0F056B), width: 2),
                  ),
                  prefixIcon: Icon(Icons.person, color: Color(0xFF0F056B)),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: prenomController,
                decoration: InputDecoration(
                  labelText: 'Prénom',
                  labelStyle: TextStyle(color: Color(0xFF0F056B)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Color(0xFF0F056B), width: 2),
                  ),
                  prefixIcon: Icon(Icons.person_outline, color: Color(0xFF0F056B)),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: motDePasseController,
                decoration: InputDecoration(
                  labelText: 'Mot de passe',
                  labelStyle: TextStyle(color: Color(0xFF0F056B)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Color(0xFF0F056B), width: 2),
                  ),
                  prefixIcon: Icon(Icons.lock, color: Color(0xFF0F056B)),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureText ? Icons.visibility : Icons.visibility_off,
                      color: Color(0xFF0F056B),
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureText = !_obscureText;
                      });
                    },
                  ),
                ),
                obscureText: _obscureText,
              ),
              const SizedBox(height: 5),
              if (motDePasseController.text.length < 6 || !RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(motDePasseController.text)) ...[
                Text(
                  'Mot de passe : min. 6 caractères, dont 1 spécial.',
                  style: TextStyle(color: Colors.red),
                ),
              ],
              const SizedBox(height: 15),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Annuler',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
        ElevatedButton(
          onPressed: () async {
            // Afficher l'écran de chargement
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext context) {
                return const Chargement(message: "Ajout du collaborateur en cours...");
              },
            );

            String nom = nomController.text;
            String prenom = prenomController.text;
            String motDePasse = motDePasseController.text;

            // Mettre la première lettre en majuscule
            nom = nom[0].toUpperCase() + nom.substring(1);
            prenom = prenom[0].toUpperCase() + prenom.substring(1);

            String id = idController.text;

            // Validation du mot de passe
            if (motDePasse.length < 6 || !RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(motDePasse)) {
              // Fermer l'écran de chargement en cas d'erreur
              Navigator.of(context).pop();
              return;
            }

            try {
              if (widget.collaborateurId != null) {
                // Mode édition
                await FirebaseFirestore.instance
                  .collection('users')
                  .doc(PopAddColab.currentUser!.uid)
                  .collection('collaborateur')
                  .doc(widget.collaborateurId)
                  .update({
                    'id': id,
                    'nom': nom,
                    'prenom': prenom,
                    'motDePasse': motDePasse,
                    'lastUpdateDate': FieldValue.serverTimestamp(),
                  });
              } else {
                // Mode création
                await FirebaseFirestore.instance
                  .collection('users')
                  .doc(PopAddColab.currentUser!.uid)
                  .collection('collaborateur')
                  .doc(PopAddColab.currentUser!.uid)
                  .set({
                    'id': id,
                    'nom': nom,
                    'prenom': prenom,
                    'motDePasse': motDePasse,
                    'lastUpdateDate': FieldValue.serverTimestamp(),
                  });
              }

              // Fermer l'écran de chargement
              Navigator.of(context).pop();
              // Fermer le popup
              Navigator.of(context).pop();
            } catch (e) {
              // Fermer l'écran de chargement en cas d'erreur
              Navigator.of(context).pop();
              // Afficher une erreur
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Une erreur est survenue lors de l\'ajout du collaborateur'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0F056B),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          child: const Text(
            'Valider',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
