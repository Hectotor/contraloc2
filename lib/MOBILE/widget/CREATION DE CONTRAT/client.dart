import 'package:flutter/material.dart';
import 'dart:io';
import 'location.dart'; // Import de la page location
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:contraloc/MOBILE/services/auth_util.dart'; // Import de AuthUtil
import 'popup_vehicule_client.dart';
import 'image_upload_utils.dart';
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
  final TextEditingController _numeroPermisController = TextEditingController();
  final TextEditingController _immatriculationVehiculeClientController = TextEditingController();
  final TextEditingController _kilometrageVehiculeClientController = TextEditingController();
  File? _permisRecto;
  File? _permisVerso;
  String? _permisRectoUrl;
  String? _permisVersoUrl;
  List<String> _vehiculeClientPhotosUrls = [];
  List<File> _vehiculeClientPhotos = [];
  // Variable isPremiumUser supprimée car non utilisée
  bool _isLoading = false;
  
  // Méthode pour mettre à jour les informations du permis
  void updatePermisInfo(String numeroPermis, String? rectoUrl, String? versoUrl) {
    setState(() {
      _numeroPermisController.text = numeroPermis;
      _permisRectoUrl = rectoUrl;
      _permisVersoUrl = versoUrl;
    });
  }
  
  // Méthode pour télécharger les photos du véhicule client à partir des URLs
  Future<void> _downloadVehiculeClientPhotos() async {
    if (_vehiculeClientPhotosUrls.isEmpty) return;
    
    // Ne pas afficher l'indicateur de chargement pour ne pas bloquer l'interface
    // Télécharger les photos en arrière-plan
    try {
      for (String url in _vehiculeClientPhotosUrls) {
        final photoFile = await ImageUploadUtils.downloadImageFromUrl(url);
        if (photoFile != null && mounted) {
          setState(() {
            _vehiculeClientPhotos.add(photoFile);
          });
        }
      }
      print('Photos du véhicule client téléchargées: ${_vehiculeClientPhotos.length}');
    } catch (e) {
      print('Erreur lors du téléchargement des photos du véhicule client: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    // _initializeSubscription() supprimée car non utilisée
    
    // Si nous avons un contratId, c'est une modification de contrat existant
    if (widget.contratId != null) {
      _loadClientData();
    }
  }

  // Méthode _initializeSubscription supprimée car non utilisée

  Future<void> _loadClientData() async {
    try {
      // Afficher un indicateur de chargement uniquement pour la récupération initiale des données
      setState(() {
        _isLoading = true;
      });
      
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && widget.contratId != null) {
        String adminId = user.uid;
        
        // Vérifier si l'utilisateur est un collaborateur
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        final userData = userDoc.data();
        
        if (userData != null && userData['role'] == 'collaborateur' && userData['adminId'] != null) {
          adminId = userData['adminId'];
        }
        
        final docRef = FirebaseFirestore.instance
            .collection('users')
            .doc(adminId)
            .collection('locations')
            .doc(widget.contratId);

        final docSnapshot = await docRef.get();
        if (docSnapshot.exists && mounted) {
          final data = docSnapshot.data() as Map<String, dynamic>;
          
          // Mettre à jour l'interface avec les données textuelles
          setState(() {
            _isLoading = false; // Arrêter l'indicateur de chargement dès que les données textuelles sont disponibles
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
          });
          
          // Récupérer les URLs des photos du véhicule client après avoir affiché les données textuelles
          if (data['vehiculeClientPhotosUrls'] != null && data['vehiculeClientPhotosUrls'] is List) {
            _vehiculeClientPhotosUrls = List<String>.from(data['vehiculeClientPhotosUrls']);
            
            // Télécharger les photos du véhicule client en arrière-plan
            _downloadVehiculeClientPhotos();
          }
        } else {
          // Si le document n'existe pas, arrêter l'indicateur de chargement
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        }
      } else {
        // Si pas d'utilisateur ou pas de contratId, arrêter l'indicateur de chargement
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Erreur lors du chargement des données client: $e');
      // En cas d'erreur, arrêter l'indicateur de chargement
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
          'dateModification': DateTime.now()
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
          final adminId = await AuthUtilExtension.getAdminId();
          if (adminId == null) throw Exception('AdminId non trouvé');
          
          await FirebaseFirestore.instance
              .collection('users')
              .doc(adminId)
              .collection('locations')
              .doc(widget.contratId)
              .set(clientData, SetOptions(merge: true));
              
          // Afficher un message de succès avec une meilleure mise en page
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green[400]),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Modifications enregistrées avec succès',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green[800],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              margin: const EdgeInsets.all(16),
              duration: const Duration(seconds: 3),
            ),
          );
          
          // Pour les contrats existants, naviguer vers la page de location
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LocationPage(
                contratId: widget.contratId!,
                marque: widget.marque,
                modele: widget.modele,
                immatriculation: widget.immatriculation,
                // Passer également les données client pour la modification
                entrepriseClient: entrepriseClientController.text,
                nom: _nomController.text,
                prenom: _prenomController.text,
                adresse: _adresseController.text,
                telephone: _telephoneController.text,
                email: _emailController.text,
                numeroPermis: _numeroPermisController.text,
                immatriculationVehiculeClient: _immatriculationVehiculeClientController.text,
                kilometrageVehiculeClient: _kilometrageVehiculeClientController.text,
                permisRecto: _permisRecto,
                permisVerso: _permisVerso,
                vehiculeClientPhotos: _vehiculeClientPhotos, // Ajout des photos du véhicule client
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
                permisRectoUrl: _permisRectoUrl,
                permisVersoUrl: _permisVersoUrl,
                vehiculeClientPhotos: _vehiculeClientPhotos, // Ajout des photos du véhicule client
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
      existingPhotos: _vehiculeClientPhotos,
      onSave: (immatriculation, kilometrage, photos) {
        setState(() {
          _immatriculationVehiculeClientController.text = immatriculation;
          _kilometrageVehiculeClientController.text = kilometrage;
          _vehiculeClientPhotos = photos;
        });
        print('Photos du véhicule client enregistrées: ${photos.length}');
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
                      onPermisInfoUpdate: updatePermisInfo, // Ajout du callback pour mettre à jour les infos du permis
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