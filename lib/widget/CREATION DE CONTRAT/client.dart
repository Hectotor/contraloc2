import 'package:flutter/material.dart';
import 'dart:io';
import '../location.dart'; // Import de la page location
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ContraLoc/services/collaborateur_util.dart'; // Import de l'utilitaire collaborateur
import 'popup_vehicule_client.dart';
import 'Containers/permis_info_container.dart'; // Import du nouveau composant
import 'Containers/personal_info_container.dart'; // Import du nouveau composant

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    // Convertir le texte en majuscules
    final String upperCaseText = newValue.text.toUpperCase();
    
    // Si le texte n'a pas changé après conversion, retourner la valeur telle quelle
    if (upperCaseText == newValue.text) {
      return newValue;
    }
    
    // Calculer le décalage de la sélection si nécessaire
    final int selectionOffset = newValue.selection.baseOffset;
    
    return TextEditingValue(
      text: upperCaseText,
      selection: TextSelection.collapsed(offset: selectionOffset),
    );
  }
}

class ClientPage extends StatefulWidget {
  final String marque;
  final String modele;
  final String immatriculation;
  final String? contratId;

  const ClientPage({
    Key? key,
    required this.marque,
    required this.modele,
    required this.immatriculation,
    this.contratId,
  }) : super(key: key);

  @override
  State<ClientPage> createState() => _ClientPageState();
}

class _ClientPageState extends State<ClientPage> {
  // Variables d'état
  final _formKey = GlobalKey<FormState>();
  final TextEditingController entrepriseClientController = TextEditingController();
  final TextEditingController _nomController = TextEditingController();
  final TextEditingController _prenomController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _telephoneController = TextEditingController();
  final TextEditingController _adresseController = TextEditingController();
  final _numeroPermisController = TextEditingController();
  final _immatriculationVehiculeClientController = TextEditingController();
  final _kilometrageVehiculeClientController = TextEditingController();
  File? _permisRecto;
  File? _permisVerso;
  String? _permisRectoUrl;
  String? _permisVersoUrl;
  bool isPremiumUser = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeSubscription(); // Initialiser et vérifier le statut d'abonnement
    
    // Si nous avons un contratId, c'est une modification de contrat existant
    if (widget.contratId != null) {
      _loadClientData();
    }
  }

  // Méthode pour initialiser et vérifier le statut d'abonnement
  Future<void> _initializeSubscription() async {
    // Vérifier le statut premium via CollaborateurUtil
    final isPremium = await CollaborateurUtil.isPremiumUser();
    
    if (mounted) {
      setState(() {
        isPremiumUser = isPremium;
      });
    }
  }

  Future<void> _loadClientData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && widget.contratId != null) {
        String adminId = user.uid;
        
        // Vérifier si l'utilisateur est un collaborateur
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        final userData = userDoc.data();
        
        if (userData != null && userData['role'] == 'collaborateur' && userData['adminId'] != null) {
          adminId = userData['adminId'];
          print('Utilisateur collaborateur détecté, utilisation de l\'adminId: $adminId');
        }
        
        final docRef = FirebaseFirestore.instance
            .collection('users')
            .doc(adminId)
            .collection('locations')
            .doc(widget.contratId);

        final docSnapshot = await docRef.get();
        if (docSnapshot.exists) {
          final data = docSnapshot.data() as Map<String, dynamic>;
          print('Données récupérées: $data');
          
          setState(() {
            entrepriseClientController.text = data['entrepriseClient'] ?? '';
            _nomController.text = data['nom'] ?? '';
            _prenomController.text = data['prenom'] ?? '';
            _emailController.text = data['email'] ?? '';
            _telephoneController.text = data['telephone'] ?? '';
            _adresseController.text = data['adresse'] ?? '';
            _numeroPermisController.text = data['numeroPermis'] ?? '';
            _immatriculationVehiculeClientController.text = data['immatriculationVehiculeClient'] ?? '';
            _kilometrageVehiculeClientController.text = data['kilometrageVehiculeClient'] ?? '';
            
            // Récupérer les URLs des images du permis
            _permisRectoUrl = data['permisRecto'];
            _permisVersoUrl = data['permisVerso'];
            
            // Afficher les URLs dans la console
            print('URL permis recto: $_permisRectoUrl');
            print('URL permis verso: $_permisVersoUrl');
          });
        }
      }
    } catch (e) {
      print('Erreur lors du chargement des données client: $e');
    }
  }

  Future<void> _saveClientData() async {
    // Tous les champs sont optionnels, pas besoin de validation
    if (_formKey.currentState != null) {
      _formKey.currentState!.save();
      
      setState(() {
        _isLoading = true;
      });

      try {
        // Préparer les données du client
        Map<String, dynamic> clientData = {
          'entrepriseClient': entrepriseClientController.text,
          'nom': _nomController.text,
          'prenom': _prenomController.text,
          'adresse': _adresseController.text,
          'telephone': _telephoneController.text,
          'email': _emailController.text,
          'numeroPermis': _numeroPermisController.text,
          'marque': widget.marque,
          'modele': widget.modele,
          'immatriculation': widget.immatriculation,
          'immatriculationVehiculeClient': _immatriculationVehiculeClientController.text,
          'kilometrageVehiculeClient': _kilometrageVehiculeClientController.text,
          'dateCreation': DateTime.now(),
          'dateModification': DateTime.now(),
        };

        // Ajouter les URLs des photos si disponibles
        if (_permisRectoUrl != null && _permisRectoUrl!.isNotEmpty) {
          clientData['permisRectoUrl'] = _permisRectoUrl;
        }
        if (_permisVersoUrl != null && _permisVersoUrl!.isNotEmpty) {
          clientData['permisVersoUrl'] = _permisVersoUrl;
        }

        // Déterminer si c'est un nouveau contrat ou une mise à jour
        if (widget.contratId != null && widget.contratId!.isNotEmpty) {
          // Mise à jour d'un contrat existant
          final adminId = await _getAdminId();
          await FirebaseFirestore.instance
              .collection('users')
              .doc(adminId)
              .collection('locations')
              .doc(widget.contratId)
              .set(clientData, SetOptions(merge: true));
              
          // Pour les contrats existants, naviguer vers la page de location
          if (!mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LocationPage(
                contratId: widget.contratId!,
                marque: widget.marque,
                modele: widget.modele,
                immatriculation: widget.immatriculation,
              ),
            ),
          );
        } else {
          // Nouveau contrat - ne pas enregistrer dans Firestore, juste passer à la page suivante
          if (!mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LocationPage(
                // Pas de contratId car c'est une présauvegarde
                marque: widget.marque,
                modele: widget.modele,
                immatriculation: widget.immatriculation, // Immatriculation du véhicule de location
                // Passer les données client à la page suivante
                entrepriseClient: entrepriseClientController.text,
                nom: _nomController.text,
                prenom: _prenomController.text,
                adresse: _adresseController.text,
                telephone: _telephoneController.text,
                email: _emailController.text,
                numeroPermis: _numeroPermisController.text,
                immatriculationVehiculeClient: _immatriculationVehiculeClientController.text, // Immatriculation du véhicule du client
                kilometrageVehiculeClient: _kilometrageVehiculeClientController.text,
                permisRecto: _permisRecto,
                permisVerso: _permisVerso,
              ),
            ),
          );
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la sauvegarde: ${e.toString()}')),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  void _showVehicleDialog() {
    showVehiculeClientDialog(
      context: context,
      immatriculationVehiculeClient: _immatriculationVehiculeClientController.text,
      kilometrageVehiculeClient: _kilometrageVehiculeClientController.text,
      onSave: (immatriculation, kilometrage) {
        setState(() {
          _immatriculationVehiculeClientController.text = immatriculation;
          _kilometrageVehiculeClientController.text = kilometrage;
        });
      },
    );
  }

  Widget _buildLicenseInfo(BuildContext context) {
    return PermisInfoContainer(
      numeroPermisController: _numeroPermisController,
      onRectoImageSelected: (file) {
        setState(() {
          _permisRecto = file;
        });
      },
      onVersoImageSelected: (file) {
        setState(() {
          _permisVerso = file;
        });
      },
      permisRecto: _permisRecto,
      permisVerso: _permisVerso,
      permisRectoUrl: _permisRectoUrl,
      permisVersoUrl: _permisVersoUrl,
    );
  }

  // Récupérer l'ID de l'administrateur (utilisateur actuel ou admin si collaborateur)
  Future<String> _getAdminId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return '';
    
    // Vérifier le statut collaborateur
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    
    if (userDoc.exists && userDoc.data() is Map<String, dynamic>) {
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      if (userData['isCollaborateur'] == true && userData['adminId'] != null) {
        return userData['adminId'] as String;
      }
    }
    
    return user.uid;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Text(
            "${widget.modele} - ${widget.immatriculation}",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        backgroundColor: const Color(0xFF08004D),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.directions_car, color: Colors.white),
            onPressed: () => _showVehicleDialog(),
            tooltip: 'Véhicule client',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF08004D)))
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PersonalInfoContainer(
                      entrepriseClientController: entrepriseClientController,
                      nomController: _nomController,
                      prenomController: _prenomController,
                      emailController: _emailController,
                      telephoneController: _telephoneController,
                      adresseController: _adresseController,
                    ),
                    const SizedBox(height: 15),
                    _buildLicenseInfo(context),
                    const SizedBox(height: 50),
                    ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          _saveClientData();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF08004D),
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Suivant',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ), 
                    ), const SizedBox(height: 50),
                  ],
                ),
              ),
            ),
      ),
    );
  }
}