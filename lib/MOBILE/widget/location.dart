import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:contraloc/MOBILE/utils/generation_contrat_pdf.dart';
import 'package:contraloc/MOBILE/models/contrat_model.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../widget/chargement.dart';
import '../widget/popup_signature.dart';
import '../widget/photo_upload_popup.dart';
import 'CREATION DE CONTRAT/Containers/date_container.dart';
import 'CREATION DE CONTRAT/Containers/kilometrage_container.dart';
import 'CREATION DE CONTRAT/Containers/type_location_container.dart';
import 'CREATION DE CONTRAT/Containers/essence_container.dart';
import 'CREATION DE CONTRAT/Containers/etat_commentaire_container.dart';
import '../utils/affichage_contrat_pdf.dart';
import '../utils/contract_utils.dart';
import '../services/auth_util.dart';
import '../USERS/contrat_condition.dart';
import '../utils/pdf_upload_utils.dart';
import 'CREATION DE CONTRAT/Containers/lieux_popup.dart';

class LocationPage extends StatefulWidget {
  final String marque;
  final String modele;
  final String immatriculation;
  final String? nom;
  final String? prenom;
  final String? adresse;
  final String? telephone;
  final String? email;
  final String? entrepriseClient;
  final String? numeroPermis;
  final String? immatriculationVehiculeClient;
  final String? kilometrageVehiculeClient;
  final String? contratId;
  final File? permisRecto;
  final File? permisVerso;
  final String? permisRectoUrl;
  final String? permisVersoUrl;

  const LocationPage({
    Key? key,
    required this.marque,
    required this.modele,
    required this.immatriculation,
    this.nom,
    this.prenom,
    this.adresse,
    this.telephone,
    this.email,
    this.entrepriseClient,
    this.numeroPermis,
    this.immatriculationVehiculeClient,
    this.kilometrageVehiculeClient,
    this.contratId,
    this.permisRecto,
    this.permisVerso,
    this.permisRectoUrl,
    this.permisVersoUrl,
  }) : super(key: key);

  @override
  State<LocationPage> createState() => _LocationPageState();
}

class _LocationPageState extends State<LocationPage> {
  final TextEditingController _dateDebutController = TextEditingController();
  final TextEditingController _dateFinTheoriqueController =
      TextEditingController();
  final TextEditingController _lieuDepartController = TextEditingController();
  final TextEditingController _lieuRestitutionController = TextEditingController();
  final TextEditingController _kilometrageDepartController =
      TextEditingController();
  final TextEditingController _commentaireController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final List<File> _photos = [];
  int _pourcentageEssence = 50;
  bool _isLoading = false;
  bool _acceptedConditions = false;
  String _signatureAller = '';
  bool _isSigning = false;
  String? _vehiclePhotoUrl;
  String? _permisRectoUrl;
  String? _permisVersoUrl;

  final TextEditingController _prixLocationController = TextEditingController();
  final TextEditingController _accompteController = TextEditingController();
  final TextEditingController _nettoyageIntController = TextEditingController();
  final TextEditingController _nettoyageExtController = TextEditingController();
  final TextEditingController _carburantManquantController =TextEditingController();
  final TextEditingController _kilometrageAutoriseController = TextEditingController();
  final TextEditingController _kilometrageSuppController = TextEditingController();
  final TextEditingController _vinController = TextEditingController();
  final TextEditingController _assuranceNomController = TextEditingController();
  final TextEditingController _assuranceNumeroController = TextEditingController();
  final TextEditingController _franchiseController = TextEditingController();
  final TextEditingController _rayuresController = TextEditingController();
  final TextEditingController _typeCarburantController = TextEditingController();
  final TextEditingController _boiteVitessesController = TextEditingController();
  final TextEditingController _typeLocationController = TextEditingController();
  final TextEditingController _cautionController = TextEditingController();
  final TextEditingController _entrepriseClientController = TextEditingController();
  final TextEditingController _conditionsController = TextEditingController();
  final TextEditingController _locationCasqueController = TextEditingController();
  String? _selectedPaymentMethod;

  final TextEditingController _nomController = TextEditingController();
  final TextEditingController _prenomController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _telephoneController = TextEditingController();
  final TextEditingController _adresseController = TextEditingController();
  final TextEditingController _numeroPermisController = TextEditingController();
  final TextEditingController _immatriculationVehiculeClientController = TextEditingController();
  final TextEditingController _kilometrageVehiculeClientController = TextEditingController();
  final TextEditingController _nomEntrepriseController = TextEditingController();
  final TextEditingController _logoUrlController = TextEditingController();
  final TextEditingController _adresseEntrepriseController = TextEditingController();
  final TextEditingController _telephoneEntrepriseController = TextEditingController();
  final TextEditingController _siretEntrepriseController = TextEditingController();
  final TextEditingController _devisesLocationController = TextEditingController();

  String? _lieuDepart;
  String? _lieuRestitution;

  String? nomEntreprise;
  String? logoUrl;
  String? adresseEntreprise;
  String? telephoneEntreprise;
  String? siretEntreprise;

  Map<String, dynamic>? adminDataMap;

  @override
  void initState() {
    super.initState();
    _selectedPaymentMethod = 'Espèces';
    
    // Debug des photos du permis
    print('=== DEBUG INIT PERMIS PHOTOS ===');
    print('permisRecto dans widget: ${widget.permisRecto}');
    print('permisVerso dans widget: ${widget.permisVerso}');
    print('=== FIN DEBUG INIT PERMIS PHOTOS ===');

    // Charger les informations de l'entreprise
    _loadAdminInfo();
    
    _dateDebutController.text = DateFormat('EEEE d MMMM yyyy à HH:mm', 'fr_FR').format(DateTime.now());
    _typeLocationController.text = "Gratuite";
    
    // Initialiser les données du client à partir des paramètres
    _entrepriseClientController.text = widget.entrepriseClient ?? '';
    _nomController.text = widget.nom ?? '';
    _prenomController.text = widget.prenom ?? '';
    _emailController.text = widget.email ?? '';
    _telephoneController.text = widget.telephone ?? '';
    _adresseController.text = widget.adresse ?? '';
    _numeroPermisController.text = widget.numeroPermis ?? '';
    _immatriculationVehiculeClientController.text = widget.immatriculationVehiculeClient ?? '';
    _kilometrageVehiculeClientController.text = widget.kilometrageVehiculeClient ?? '';
    
    // Initialiser les URLs des images du permis
    _permisRectoUrl = widget.permisRectoUrl;
    _permisVersoUrl = widget.permisVersoUrl;
    
    // Debug des URLs du permis
    print('=== DEBUG INIT PERMIS URLS ===');
    print('permisRectoUrl dans widget: ${widget.permisRectoUrl}');
    print('permisVersoUrl dans widget: ${widget.permisVersoUrl}');
    print('=== FIN DEBUG INIT PERMIS URLS ===');
    
    // Initialiser les variables d'entreprise
    _loadAdminInfo();
    
    // Charger les données du contrat si un ID est fourni
    if (widget.contratId != null && widget.contratId!.isNotEmpty) {
      _loadContractData(widget.contratId!).then((contractData) {
        if (contractData != null) {
          setState(() {
            // Mise à jour des contrôleurs avec les données du contrat
            _updateControllersFromModel(contractData);
          });
        }
      });
    } else {
      _fetchVehicleData();
    }
  }

  Future<Map<String, dynamic>> _loadAdminInfo() async {
    try {
      print('=== Début _loadAdminInfo ===');
      // Récupérer les données d'authentification
      final authData = await AuthUtil.getAuthData();
      print('authData: $authData');
      
      if (authData.isEmpty) {
        print('❌ Aucun utilisateur connecté');
        throw Exception('Aucun utilisateur connecté');
      }

      // Récupérer l'ID de l'admin directement avec l'extension
      final adminId = await AuthUtilExtension.getAdminId();
      print('adminId via extension: $adminId');
      
      // Pour collaborateur, il faut récupérer les infos d'authentification de l'admin
      final userId = adminId;
      final authDocSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('authentification')
          .doc(userId)
          .get();

      if (!authDocSnap.exists) {
        print('❌ Document infos entreprise non trouvé dans authentification');
        throw Exception('Infos entreprise manquantes');
      }
      final adminData = authDocSnap.data() ?? {};

      setState(() {
        // On ne met à jour que les contrôleurs, plus besoin de stocker dans les variables d'instance
        _nomEntrepriseController.text = adminData['nomEntreprise'] ?? '';
        _logoUrlController.text = adminData['logoUrl'] ?? '';
        _adresseEntrepriseController.text = adminData['adresse'] ?? '';
        _telephoneEntrepriseController.text = adminData['telephone'] ?? '';
        _siretEntrepriseController.text = adminData['siret'] ?? '';
        _devisesLocationController.text = adminData['devisesLocation'] ?? '';
      });

      // Ajouter l'adminId aux données retournées
      final result = Map<String, dynamic>.from(adminData);
      result['adminId'] = userId;
      return result;
    } catch (e) {
      print('❌ Erreur lors du chargement des informations de l\'entreprise: $e');
      throw e;
    }
  }

  void _updateControllersFromModel(ContratModel model) {
    // Mise à jour des contrôleurs avec les données du modèle
    if (model.dateDebut != null) _dateDebutController.text = model.dateDebut!;
    if (model.dateFinTheorique != null) _dateFinTheoriqueController.text = model.dateFinTheorique!;
    if (model.lieuDepart != null) _lieuDepart = model.lieuDepart;
    if (model.lieuRestitution != null) _lieuRestitution = model.lieuRestitution;
    if (model.kilometrageDepart != null) _kilometrageDepartController.text = model.kilometrageDepart!;
    if (model.typeLocation != null) _typeLocationController.text = model.typeLocation!;
    if (model.commentaireAller != null) _commentaireController.text = model.commentaireAller!;
    setState(() => _pourcentageEssence = model.pourcentageEssence);
    
    // Informations financières
    if (model.prixLocation != null) _prixLocationController.text = model.prixLocation!;
    if (model.accompte != null) _accompteController.text = model.accompte!;
    if (model.nettoyageInt != null) _nettoyageIntController.text = model.nettoyageInt!;
    if (model.nettoyageExt != null) _nettoyageExtController.text = model.nettoyageExt!;
    if (model.carburantManquant != null) _carburantManquantController.text = model.carburantManquant!;
    if (model.kilometrageAutorise != null) _kilometrageAutoriseController.text = model.kilometrageAutorise ?? '';
    if (model.kilometrageSupp != null) _kilometrageSuppController.text = model.kilometrageSupp!;
    if (model.rayures != null) _rayuresController.text = model.rayures!;
    if (model.locationCasque != null) _locationCasqueController.text = model.locationCasque!;
    
    // Informations véhicule
    if (model.vin != null) _vinController.text = model.vin!;
    
    // Informations assurance
    if (model.assuranceNom != null) _assuranceNomController.text = model.assuranceNom!;
    if (model.assuranceNumero != null) _assuranceNumeroController.text = model.assuranceNumero!;
    if (model.franchise != null) _franchiseController.text = model.franchise!;
    if (model.typeCarburant != null) _typeCarburantController.text = model.typeCarburant!;
    if (model.boiteVitesses != null) _boiteVitessesController.text = model.boiteVitesses!;
    
    // Signature
    if (model.signatureAller != null) {
      setState(() {
        _signatureAller = model.signatureAller!;
      });
    }

    // Mise à jour des variables d'état
    _vehiclePhotoUrl = model.photoVehiculeUrl;
    _cautionController.text = model.caution ?? '';
    _entrepriseClientController.text = model.entrepriseClient ?? '';
    _selectedPaymentMethod = model.methodePaiement ?? 'Espèces';
    _conditionsController.text = model.conditions ?? '';
    _nomController.text = model.nom ?? '';
    _prenomController.text = model.prenom ?? '';
    _emailController.text = model.email ?? '';
    _telephoneController.text = model.telephone ?? '';
    _adresseController.text = model.adresse ?? '';
    _numeroPermisController.text = model.numeroPermis ?? '';
    _immatriculationVehiculeClientController.text = model.immatriculationVehiculeClient ?? '';
    _kilometrageVehiculeClientController.text = model.kilometrageVehiculeClient ?? '';
    _permisRectoUrl = model.permisRecto;
    _permisVersoUrl = model.permisVerso;
    _lieuDepartController.text = model.lieuDepart ?? '';
    _lieuRestitutionController.text = model.lieuRestitution ?? '';
  }

  Future<ContratModel?> _loadContractData(String contratId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('❌ Aucun utilisateur connecté');
        return null;
      }

      final collaborateurStatus = await AuthUtil.getAuthData();
      final String adminId = collaborateurStatus['isCollaborateur'] 
          ? collaborateurStatus['adminId'] ?? user.uid 
          : user.uid;

      // Récupérer les données du contrat
      final contratDoc = await _firestore
          .collection('users')
          .doc(adminId)
          .collection('locations')
          .doc(contratId)
          .get();

      if (contratDoc.exists && contratDoc.data() != null) {
        // Créer un modèle de contrat à partir des données Firestore
        final contractData = contratDoc.data()!;
        final contratModel = ContratModel.fromFirestore(contractData, id: contratId);

        // Mettre à jour les contrôleurs avec les données du modèle
        setState(() {
          _updateControllersFromModel(contratModel);
          // Charger les URLs des photos du permis depuis Firestore
          _permisRectoUrl = contratModel.permisRecto;
          _permisVersoUrl = contratModel.permisVerso;
        });

        // Charger la signature si elle existe
        if (contractData['signatureAller'] != null) {
          setState(() {
            _signatureAller = contractData['signatureAller'];
            if (_signatureAller.isNotEmpty) {
              _acceptedConditions = true; // Si une signature existe, les conditions ont été acceptées
            }
          });
        }

        // Charger les photos si elles existent
        if (contractData['photos'] != null && contractData['photos'] is List) {
          List<dynamic> photoUrls = contractData['photos'];
          print('Photos trouvées: ${photoUrls.length}');

          // Télécharger les photos depuis les URLs et les ajouter à la liste _photos
          for (String photoUrl in photoUrls) {
            try {
              print('Téléchargement de la photo: $photoUrl');
              final photoFile = await _downloadImageFromUrl(photoUrl);
              if (photoFile != null) {
                setState(() {
                  _photos.add(photoFile);
                });
              }
            } catch (e) {
              print('Erreur lors du traitement de la photo: $e');
            }
          }
        }

        return contratModel;
      } else {
        print('Aucun contrat trouvé avec l\'ID: $contratId');
        return null;
      }
    } catch (e) {
      print('Erreur lors du chargement des données du contrat: $e');
      return null;
    }
  }

  Future<void> _fetchVehicleData() async {
    try {
      // Récupérer les données du véhicule depuis la collection 'vehicules'
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('❌ Aucun utilisateur connecté');
        return;
      }

      final collaborateurStatus = await AuthUtil.getAuthData();
      final String targetId = collaborateurStatus['isCollaborateur'] 
          ? collaborateurStatus['adminId'] ?? user.uid 
          : user.uid;

      final vehicleDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(targetId)
          .collection('vehicules')
          .where('immatriculation', isEqualTo: widget.immatriculation)
          .limit(1)
          .get();

      if (vehicleDoc.docs.isEmpty) {
        print('❌ Véhicule non trouvé dans la collection vehicules');
        return;
      }

      final vehicleData = vehicleDoc.docs.first.data();

      // Mettre à jour les contrôleurs avec les données du véhicule
      final Map<String, TextEditingController> controllers = {
        'prixLocation': _prixLocationController,
        'nettoyageInt': _nettoyageIntController,
        'nettoyageExt': _nettoyageExtController,
        'carburantManquant': _carburantManquantController,
        'kilometrageSupp': _kilometrageSuppController,
        'locationCasque': _locationCasqueController,
        'vin': _vinController,
        'assuranceNom': _assuranceNomController,
        'assuranceNumero': _assuranceNumeroController,
        'franchise': _franchiseController,
        'rayures': _rayuresController,
        'typeCarburant': _typeCarburantController,
        'boiteVitesses': _boiteVitessesController,
        'caution': _cautionController,
      };

      // Remplir les contrôleurs avec les données du véhicule
      controllers.forEach((key, controller) {
        if (vehicleData[key] != null) {
          controller.text = vehicleData[key].toString();
        }
      });

      // Mettre à jour la photo du véhicule si elle existe
      _vehiclePhotoUrl = vehicleData['photoUrl'] as String?;

      print('✅ Données du véhicule récupérées avec succès');
    } catch (e) {
      print('❌ Erreur lors de la récupération des données du véhicule: $e');
    }
  }

  Future<void> _validerContrat() async {
    if (_typeLocationController.text == "Payante" && _prixLocationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Veuillez d'abord configurer le prix de location du véhicule dans sa fiche"),
        ),
      );
      return;
    }

    // Récupérer les conditions du contrat depuis Firestore
    final authData = await AuthUtil.getAuthData();
    if (authData.isEmpty) {
      print('❌ Aucun utilisateur connecté');
      return;
    }
    final targetId = authData['adminId'];
    if (targetId == null) {
      print('❌ Aucun adminId trouvé');
      throw Exception('Aucun administrateur trouvé');
    }

    final conditionsDocRef = FirebaseFirestore.instance
        .collection('users')
        .doc(targetId)
        .collection('contrats')
        .doc('userId');
    
    final conditionsDoc = await conditionsDocRef.get(const GetOptions(source: Source.server));
    final conditions = conditionsDoc.data() ?? {'texte': ContratModifier.defaultContract};
    final conditionsText = conditions['texte'] ?? 'Conditions générales de location';

    if ((widget.nom != null &&
        widget.nom!.isNotEmpty &&
        widget.prenom != null &&
        widget.prenom!.isNotEmpty) &&
        !_acceptedConditions) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Vous devez accepter les conditions de location")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Vous devez être connecté pour créer un contrat")),
        );
        return;
      }

      final collaborateurStatus = await AuthUtil.getAuthData();
      final String userId = collaborateurStatus['userId'] ?? user.uid;
      final String targetId = collaborateurStatus['isCollaborateur'] 
          ? collaborateurStatus['adminId'] ?? user.uid 
          : user.uid;

      // Gestion de l'ID du contrat
      final contratId = widget.contratId ?? _firestore
          .collection('users')
          .doc(userId)
          .collection('locations')
          .doc()
          .id;

      // Préparer les photos à uploader
      List<File> photosToUpload = [];
      if (widget.permisRecto != null) {
        photosToUpload.add(widget.permisRecto as File);
      }
      if (widget.permisVerso != null) {
        photosToUpload.add(widget.permisVerso as File);
      }
      photosToUpload.addAll(_photos);

      // Afficher le popup de téléchargement des photos si des photos sont à uploader
      if (photosToUpload.isNotEmpty) {
        // Afficher le popup de téléchargement des photos
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => PhotoUploadPopup(
            photos: photosToUpload,
            contratId: contratId,
            onUploadComplete: (List<String> urls) async {
              // Continuer le processus de sauvegarde après l'upload des photos
              await _finalizeContractSave(contratId, urls, userId, targetId, collaborateurStatus, conditionsText);
            },
          ),
        );
      } else {
        // Pas de photos à uploader, continuer directement
        await _finalizeContractSave(contratId, [], userId, targetId, collaborateurStatus, conditionsText);
      }
    } catch (e) {
      print('Erreur lors de la validation du contrat: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Méthode pour finaliser la sauvegarde du contrat après l'upload des photos
  Future<void> _finalizeContractSave(String contratId, List<String> photoUrls, String userId, String targetId, Map<String, dynamic> collaborateurStatus, String conditionsText) async {
    try {
      // Upload des photos
      // Initialiser avec les URLs existantes pour ne pas les perdre
      String? permisRectoUrl = _permisRectoUrl;
      String? permisVersoUrl = _permisVersoUrl;
      List<String> vehiculeUrls = [];

      // Si des URLs de photos ont été retournées par le popup, les utiliser
      if (photoUrls.isNotEmpty) {
        // Attribuer les URLs aux bonnes variables
        int index = 0;
        if (widget.permisRecto != null) {
          permisRectoUrl = photoUrls[index++];
        }
        if (widget.permisVerso != null) {
          permisVersoUrl = photoUrls[index++];
        }
        // Le reste des URLs sont pour les photos du véhicule
        if (index < photoUrls.length) {
          vehiculeUrls = photoUrls.sublist(index);
        }
      } else {
        // Fallback au cas où le popup n'a pas été utilisé
        print('=== DEBUG PERMIS PHOTOS ===');
        print('permisRecto existe: ${widget.permisRecto != null}');
        print('permisVerso existe: ${widget.permisVerso != null}');
        
        // Vérifier si les URLs existent déjà avant de télécharger
        if (widget.permisRecto != null && _permisRectoUrl == null) {
          print('Uploading permisRecto...');
          permisRectoUrl = await _compressAndUploadPhoto(
            widget.permisRecto as File,
            'permis/recto',
            contratId
          );
          print('permisRectoUrl après upload: $permisRectoUrl');
        }

        if (widget.permisVerso != null && _permisVersoUrl == null) {
          print('Uploading permisVerso...');
          permisVersoUrl = await _compressAndUploadPhoto(
            widget.permisVerso as File,
            'permis/verso',
            contratId
          );
          print('permisVersoUrl après upload: $permisVersoUrl');
        }
        print('=== FIN DEBUG PERMIS PHOTOS ===');

        // Afficher les photos existantes pour débogage
        if (_photos.isNotEmpty) {
          print('Photos existantes avant upload: ${_photos.length}');
        } else {
          print('Aucune photo à uploader');
        }

        // Upload des autres photos uniquement si nécessaire
        for (var photo in _photos) {
          // Vérifier si l'URL existe déjà
          bool urlExists = false;
          for (var url in vehiculeUrls) {
            if (url == photo.path) {
              urlExists = true;
              break;
            }
          }
          if (!urlExists) {
            String url = await _compressAndUploadPhoto(photo, 'photos', contratId);
            vehiculeUrls.add(url);
          }
        }

        print('=== DEBUG PHOTOS VEHICULE ===');
        print('Photos du véhicule téléchargées: ${vehiculeUrls.length}');
        if (vehiculeUrls.isNotEmpty) {
          print('Première URL de photo: ${vehiculeUrls.first}');
        }
        print('=== FIN DEBUG PHOTOS VEHICULE ===');
      }

      // Récupérer l'adminId via AuthUtil
      final authData = await AuthUtil.getAuthData();
      if (authData.isEmpty) {
        print('❌ Aucun utilisateur connecté');
        throw Exception('Aucun utilisateur connecté');
      }
      
      final targetId = authData['adminId'] as String?;
      if (targetId == null) {
        print('❌ Aucun adminId trouvé');
        throw Exception('Aucun administrateur trouvé');
      }

      // Utiliser les variables d'état déjà chargées
      // Création du contrat
      // D'abord, télécharger les photos du permis si elles sont présentes en tant que fichiers
      if (widget.permisRecto != null) {
        _permisRectoUrl = await _compressAndUploadPhoto(widget.permisRecto!, 'permis/recto', contratId);
        print('URL permis recto sauvegardée: $_permisRectoUrl');
      }
      if (widget.permisVerso != null) {
        _permisVersoUrl = await _compressAndUploadPhoto(widget.permisVerso!, 'permis/verso', contratId);
        print('URL permis verso sauvegardée: $_permisVersoUrl');
      }

      final contratModel = ContratModel(
        contratId: contratId,
        userId: userId,
        adminId: targetId,
        createdBy: userId,
        isCollaborateur: collaborateurStatus['isCollaborateur'] ?? false,
        nom: _nomController.text,
        prenom: _prenomController.text,
        entrepriseClient: _entrepriseClientController.text,
        adresse: _adresseController.text,
        telephone: _telephoneController.text,
        email: _emailController.text,
        permisRecto: _permisRectoUrl,
        permisVerso: _permisVersoUrl,
        marque: widget.marque,
        modele: widget.modele,
        immatriculation: widget.immatriculation,
        photoVehiculeUrl: _vehiclePhotoUrl,
        vin: _vinController.text.isNotEmpty ? _vinController.text : '',
        typeCarburant: _typeCarburantController.text.isNotEmpty ? _typeCarburantController.text : '',
        boiteVitesses: _boiteVitessesController.text.isNotEmpty ? _boiteVitessesController.text : '',
        dateDebut: _dateDebutController.text.isNotEmpty ? _dateDebutController.text : '',
        dateFinTheorique: _dateFinTheoriqueController.text.isNotEmpty ? _dateFinTheoriqueController.text : '',
        lieuDepart: _lieuDepartController.text.isNotEmpty ? _lieuDepartController.text : '',
        lieuRestitution: _lieuRestitutionController.text.isNotEmpty ? _lieuRestitutionController.text : '',
        kilometrageDepart: _kilometrageDepartController.text.isNotEmpty ? _kilometrageDepartController.text : '',
        typeLocation: _typeLocationController.text.isNotEmpty ? _typeLocationController.text : "Gratuite",
        pourcentageEssence: _pourcentageEssence,
        commentaireAller: _commentaireController.text.isNotEmpty ? _commentaireController.text : '',
        photosUrls: vehiculeUrls,
        status: _determineContractStatus(),
        dateReservation: _calculateReservationDate(),
        dateCreation: Timestamp.now(),
        signatureAller: _signatureAller,
        assuranceNom: _assuranceNomController.text.isNotEmpty ? _assuranceNomController.text : '',
        assuranceNumero: _assuranceNumeroController.text.isNotEmpty ? _assuranceNumeroController.text : '',
        franchise: _franchiseController.text.isNotEmpty ? _franchiseController.text : '',
        prixLocation: _prixLocationController.text.isNotEmpty ? _prixLocationController.text : '',
        accompte: _accompteController.text.isNotEmpty ? _accompteController.text : '',
        nomEntreprise: _nomEntrepriseController.text,
        logoUrl: _logoUrlController.text,
        adresseEntreprise: _adresseEntrepriseController.text,
        telephoneEntreprise: _telephoneEntrepriseController.text,
        siretEntreprise: _siretEntrepriseController.text,
        devisesLocation: _devisesLocationController.text.isNotEmpty ? _devisesLocationController.text : '',
        rayures: _rayuresController.text.isNotEmpty ? _rayuresController.text : null,
        kilometrageAutorise: _kilometrageAutoriseController.text.isNotEmpty ? _kilometrageAutoriseController.text : null,
        kilometrageSupp: _kilometrageSuppController.text.isNotEmpty ? _kilometrageSuppController.text : '',
        carburantManquant: _carburantManquantController.text.isNotEmpty ? _carburantManquantController.text : '',
        conditions: conditionsText,
        methodePaiement: _selectedPaymentMethod ?? 'Espèces',
        numeroPermis: _numeroPermisController.text,
        immatriculationVehiculeClient: _immatriculationVehiculeClientController.text,
        kilometrageVehiculeClient: _kilometrageVehiculeClientController.text,
      );

      // === Génération et upload du PDF du contrat (état EN COURS) ===
      final pdfUrl = await generateAndUploadPdfAndSaveUrl(
        generatePdf: () async => await AffichageContratPdf.genererEtAfficherContratPdf(
          data: contratModel.toFirestore(),
          afficherPdf: false,
          contratId: contratId,
          context: context,
        ),
        userId: targetId,
        contratId: contratId,
        context: context,
        firestoreData: contratModel.toFirestore(),
      );
      if (pdfUrl != null) {
        print('✅ PDF généré, uploadé et url enregistrée: $pdfUrl');
      } else {
        print('❌ Erreur lors de la génération, upload ou sauvegarde du PDF');
      }
      // === Fin génération/upload PDF ===

      // Sauvegarder le contrat dans Firestore
      print(' Sauvegarde du contrat dans la collection de ${collaborateurStatus['isCollaborateur'] ? 'l\'administrateur' : 'l\'utilisateur'}');
      print(' Path: users/$targetId/locations/$contratId');

      // Convertir le modèle en Map pour Firestore
      Map<String, dynamic> contratData = contratModel.toFirestore();

      // Vérifier si les photos sont présentes dans le modèle mais pas dans les données Firestore
      if (contratModel.photosUrls != null && contratModel.photosUrls!.isNotEmpty && contratData['photos'] == null) {
        contratData['photos'] = contratModel.photosUrls;
      }

      await _firestore
          .collection('users')
          .doc(targetId)
          .collection('locations')
          .doc(contratId)
          .set(contratData, SetOptions(merge: true));

      // Mettre à jour le statut du véhicule dans la collection des véhicules
      // Récupérer l'ID du véhicule à partir de l'immatriculation
      final vehicleQuery = await _firestore
          .collection('users')
          .doc(targetId)
          .collection('vehicules')
          .where('immatriculation', isEqualTo: widget.immatriculation)
          .limit(1)
          .get();

      if (vehicleQuery.docs.isNotEmpty) {
        final vehicleId = vehicleQuery.docs.first.id;
        print('🚗 Mise à jour du statut du véhicule: $vehicleId');
        
        // Mettre à jour le statut du véhicule avec le même statut que le contrat
        final String vehicleStatus = _determineContractStatus();
        
        // Préparer les données de mise à jour
        Map<String, dynamic> updateData = {'isRented': vehicleStatus};
        
        // Si le véhicule est réservé ou en cours, ajouter la date de début de location
        if ((vehicleStatus == 'réservé' || vehicleStatus == 'en_cours') && _dateDebutController.text.isNotEmpty) {
          // Convertir la date de début en format court (JJ/MM/AAAA)
          try {
            final dateDebut = DateFormat('EEEE d MMMM yyyy à HH:mm', 'fr_FR').parse(_dateDebutController.text);
            final dateFormatted = DateFormat('dd/MM/yyyy').format(dateDebut);
            updateData['dateReserve'] = dateFormatted;
            print('📅 Date de début ajoutée: $dateFormatted pour statut: $vehicleStatus');
          } catch (e) {
            print('❌ Erreur lors du formatage de la date: $e');
          }
        }
        
        // Mettre à jour le document du véhicule
        await _firestore
            .collection('users')
            .doc(targetId)
            .collection('vehicules')
            .doc(vehicleId)
            .update(updateData);
            
        print('✅ Statut du véhicule mis à jour: $vehicleStatus');
      } else {
        print('❌ Véhicule non trouvé pour l\'immatriculation: ${widget.immatriculation}');
      }



      // Générer et envoyer le PDF
      await GenerationContratPdf.genererEtEnvoyerPdf(
        context: context,
        contratId: contratId,
        nom: _nomController.text,
        prenom: _prenomController.text,
        adresse: _adresseController.text,
        telephone: _telephoneController.text,
        email: _emailController.text,
        signatureAller: _signatureAller,
        photoVehiculeUrl: _vehiclePhotoUrl,
        dateDebut: _dateDebutController.text,
        dateFinTheorique: _dateFinTheoriqueController.text,
        lieuDepart: _lieuDepartController.text.isNotEmpty ? _lieuDepartController.text : '',
        lieuRestitution: _lieuRestitutionController.text.isNotEmpty ? _lieuRestitutionController.text : '',
        kilometrageDepart: _kilometrageDepartController.text,
        typeLocation: _typeLocationController.text,
        pourcentageEssence: _pourcentageEssence,
        commentaireAller: _commentaireController.text,
        vin: _vinController.text.isNotEmpty ? _vinController.text : '',
        typeCarburant: _typeCarburantController.text.isNotEmpty ? _typeCarburantController.text : '',
        boiteVitesses: _boiteVitessesController.text.isNotEmpty ? _boiteVitessesController.text : '',
        assuranceNom: _assuranceNomController.text.isNotEmpty ? _assuranceNomController.text : '',
        assuranceNumero: _assuranceNumeroController.text.isNotEmpty ? _assuranceNumeroController.text : '',
        franchise: _franchiseController.text.isNotEmpty ? _franchiseController.text : '',
        prixLocation: _prixLocationController.text.isNotEmpty ? _prixLocationController.text : '',
        accompte: _accompteController.text.isNotEmpty ? _accompteController.text : '',
        caution: _cautionController.text.isNotEmpty ? _cautionController.text : '',
        nettoyageInt: _nettoyageIntController.text.isNotEmpty ? _nettoyageIntController.text : '',
        nettoyageExt: _nettoyageExtController.text.isNotEmpty ? _nettoyageExtController.text : '',
        locationCasque: _locationCasqueController.text.isNotEmpty ? _locationCasqueController.text : '',
        carburantManquant: _carburantManquantController.text.isNotEmpty ? _carburantManquantController.text : '',
        kilometrageAutorise: _kilometrageAutoriseController.text.isNotEmpty ? _kilometrageAutoriseController.text : '',
        kilometrageSupp: _kilometrageSuppController.text.isNotEmpty ? _kilometrageSuppController.text : '',
        rayures: _rayuresController.text.isNotEmpty ? _rayuresController.text : '',
        methodePaiement: _selectedPaymentMethod ?? 'Espèces',
        numeroPermis: _numeroPermisController.text,
        immatriculationVehiculeClient: _immatriculationVehiculeClientController.text,
        kilometrageVehiculeClient: _kilometrageVehiculeClientController.text,
        permisRecto: permisRectoUrl,
        permisVerso: permisVersoUrl,
        marque: widget.marque,
        modele: widget.modele,
        immatriculation: widget.immatriculation,
        conditions: conditionsText,
        entrepriseClient: _entrepriseClientController.text,
        nomEntreprise: _nomEntrepriseController.text,
        logoUrl: _logoUrlController.text,
        adresseEntreprise: _adresseEntrepriseController.text,
        telephoneEntreprise: _telephoneEntrepriseController.text,
        siretEntreprise: _siretEntrepriseController.text,
        devisesLocation: _devisesLocationController.text.isNotEmpty ? _devisesLocationController.text : '',
        photosUrls: vehiculeUrls,
      );

      // Affichage du succès et navigation
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.email != null && widget.email!.isNotEmpty
                    ? 'Contrat validé et envoyé au client'
                    : 'Contrat validé et sauvegardé',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                if (widget.email != null && widget.email!.isNotEmpty) Text('Client: ${_nomController.text} ${_prenomController.text}'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }

    } catch (e) {
      print('❌ Erreur lors de la création du contrat: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la création du contrat: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Méthode pour déterminer le statut du contrat
  String _determineContractStatus() {
    return ContractUtils.determineContractStatus(_dateDebutController.text);
  }

  // Méthode pour calculer la date de réservation
  Timestamp? _calculateReservationDate() {
    if (_dateDebutController.text.isNotEmpty) {
      try {
        final now = DateTime.now();
        final parsedDate = DateFormat('EEEE d MMMM yyyy à HH:mm', 'fr_FR').parse(_dateDebutController.text);

        final dateWithCurrentYear = DateTime(
          now.year,
          parsedDate.month,
          parsedDate.day,
          parsedDate.hour,
          parsedDate.minute,
        );

        final dateToCompare = dateWithCurrentYear.isBefore(now) && 
                             parsedDate.month < now.month ? 
                             DateTime(now.year + 1, parsedDate.month, parsedDate.day, 
                                     parsedDate.hour, parsedDate.minute) : 
                             dateWithCurrentYear;

        if (dateToCompare.isAfter(now) && 
            !(dateToCompare.year == now.year && 
              dateToCompare.month == now.month && 
              dateToCompare.day == now.day)) {
          return Timestamp.fromDate(dateToCompare);
        }
      } catch (e) {
        print('Erreur parsing dateReservation: $e');
      }
    }
    return null;
  }

  Future<void> _captureSignature() async {
    // Afficher la popup de signature, qu'une signature existe déjà ou non
    print('Affichage de la popup de signature');
    final signature = await PopupSignature.showSignatureDialog(
      context,
      title: 'Signature du contrat',
      checkboxText: 'Je reconnais avoir pris connaissance des termes et conditions de location.',
      nom: _nomController.text,
      prenom: _prenomController.text,
      existingSignature: _signatureAller.isNotEmpty ? _signatureAller : null,
    );

    if (signature != null && signature.isNotEmpty) {
      setState(() {
        _signatureAller = signature;
        _acceptedConditions = true;
      });
      print('Nouvelle signature capturée');
    } else {
      print('Aucune signature capturée ou modification annulée');
    }
  }

  Future<String> _compressAndUploadPhoto(
    File photo, String folder, String contratId) async {
  try {
    print(" Début de compression de l'image: ${photo.absolute.path}");
    print(" Taille de l'image avant compression: ${await photo.length()} octets");

    final compressedImage = await FlutterImageCompress.compressWithFile(
      photo.absolute.path,
      minWidth: 800,
      minHeight: 800,
      quality: 85,
    );

    if (compressedImage != null) {
      print(" Compression réussie, taille après compression: ${compressedImage.length} octets");

      final status = await AuthUtil.getAuthData();
      final userId = status['adminId'];

      if (userId == null) {
        print(" Erreur: Utilisateur non connecté");
        throw Exception("Utilisateur non connecté");
      }

      final targetId = status['isCollaborateur'] ? status['adminId'] : userId;

      if (targetId == null) {
        print(" Erreur: ID cible non disponible");
        throw Exception("ID cible non disponible");
      }

      print(" Téléchargement d'image par ${status['isCollaborateur'] ? 'collaborateur' : 'admin'}");
      print(" userId: $userId, targetId (adminId): $targetId");

      // Simplifier le nom de fichier pour éviter les problèmes de chemin
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      String fileName = folder.replaceAll('/', '_') + "_$timestamp.jpg";

      final String storagePath = 'users/${targetId}/locations/$contratId/$folder/$fileName';
      print(" Chemin de stockage: $storagePath");

      final tempDir = await getTemporaryDirectory();
      // Créer un dossier spécifique pour cette application
      final appTempDir = Directory('${tempDir.path}/contraloc_temp');
      if (!await appTempDir.exists()) {
        print(" Création du dossier temporaire de l'application: ${appTempDir.path}");
        await appTempDir.create(recursive: true);
      } else {
        print(" Dossier temporaire de l'application existant: ${appTempDir.path}");
      }

      final tempFile = File('${appTempDir.path}/$fileName');
      print(" Chemin du fichier temporaire: ${tempFile.path}");
      await tempFile.writeAsBytes(compressedImage);
      print(" Fichier temporaire créé avec succès: ${await tempFile.exists()}");
      print(" Taille du fichier temporaire: ${await tempFile.length()} octets");

      Reference ref = FirebaseStorage.instance.ref().child(storagePath);

      print(" Début du téléchargement...");
      await ref.putFile(tempFile);
      print(" Téléchargement terminé avec succès");

      // Récupérer l'URL de téléchargement
      String downloadUrl = await ref.getDownloadURL();
      print(" URL de téléchargement: $downloadUrl");

      // Supprimer le fichier temporaire après utilisation
      try {
        await tempFile.delete();
        print(" Fichier temporaire supprimé");
      } catch (e) {
        print(" Erreur lors de la suppression du fichier temporaire: $e");
      }

      return downloadUrl;
    }
    throw Exception("Image compression failed");
  } catch (e) {
    print(' Erreur lors du traitement de l\'image : $e');
    if (e.toString().contains('unauthorized')) {
      print(' Problème d\'autorisation: Vérifiez les règles de sécurité Firebase Storage');
    }
    rethrow;
  }
}

  // Méthode pour télécharger une image depuis une URL et la convertir en fichier local
  Future<File?> _downloadImageFromUrl(String imageUrl) async {
    try {
      // Récupérer le répertoire temporaire
      final tempDir = await getTemporaryDirectory();
      final fileName = 'photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final file = File('${tempDir.path}/$fileName');

      // Télécharger l'image depuis l'URL
      final ref = FirebaseStorage.instance.refFromURL(imageUrl);
      final bytes = await ref.getData();

      if (bytes != null) {
        // Écrire les données dans le fichier
        await file.writeAsBytes(bytes);
        return file;
      }
      return null;
    } catch (e) {
      print('Erreur lors du téléchargement de l\'image: $e');
      return null;
    }
  }

  void _addPhoto(File photo) {
    setState(() {
      _photos.add(photo);
    });
  }

  void _removePhoto(File photo) {
    setState(() {
      _photos.remove(photo);
    });
  }

  @override
  void dispose() {
    _dateDebutController.dispose();
    _dateFinTheoriqueController.dispose();
    _lieuDepartController.dispose();
    _lieuRestitutionController.dispose();
    _kilometrageDepartController.dispose();
    _commentaireController.dispose();
    _prixLocationController.dispose();
    _accompteController.dispose();
    _nettoyageIntController.dispose();
    _nettoyageExtController.dispose();
    _carburantManquantController.dispose();
    _locationCasqueController.dispose();
    _kilometrageAutoriseController.dispose();
    _kilometrageSuppController.dispose();
    _vinController.dispose();
    _assuranceNomController.dispose();
    _assuranceNumeroController.dispose();
    _franchiseController.dispose();
    _rayuresController.dispose();
    _typeCarburantController.dispose();
    _boiteVitessesController.dispose();
    _typeLocationController.dispose();
    _cautionController.dispose();
    _entrepriseClientController.dispose();
    _conditionsController.dispose();
    _nomController.dispose();
    _prenomController.dispose();
    _emailController.dispose();
    _telephoneController.dispose();
    _adresseController.dispose();
    _numeroPermisController.dispose();
    _immatriculationVehiculeClientController.dispose();
    _kilometrageVehiculeClientController.dispose();

    super.dispose();
  }

  Future<void> _selectDateTime(TextEditingController controller) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: const Locale('fr', 'FR'), 
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF08004D), 
              onPrimary: Colors.white, 
              surface: Colors.white, 
              onSurface: Color(0xFF08004D), 
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );
    if (pickedDate != null) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: Color(0xFF08004D), 
                onPrimary: Colors.white, 
                surface: Colors.white, 
                onSurface: Color(0xFF08004D), 
              ),
              dialogBackgroundColor: Colors.white,
            ),
            child: child!,
          );
        },
      );
      if (pickedTime != null) {
        final dateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        final formattedDateTime = DateFormat('EEEE d MMMM yyyy à HH:mm', 'fr_FR').format(dateTime);
        setState(() {
          controller.text = formattedDateTime;
        });
      }
    }
  }

  void _showLieuxPopup() {
    showDialog(
      context: context,
      builder: (context) => LieuxPopup(
        lieuDepartInitial: _lieuDepart,
        lieuRestitutionInitial: _lieuRestitution,
        onLieuxSelected: (lieuDepart, lieuRestitution) {
          setState(() {
            // Mettre u00e0 jour les variables
            _lieuDepart = lieuDepart;
            _lieuRestitution = lieuRestitution;
            
            // Mettre u00e0 jour les contru00f4leurs de texte pour l'enregistrement
            _lieuDepartController.text = lieuDepart;
            _lieuRestitutionController.text = lieuRestitution;
            
            // Debug pour vu00e9rifier les valeurs
            print('Lieu de du00e9part mis u00e0 jour: $lieuDepart');
            print('Lieu de restitution mis u00e0 jour: $lieuRestitution');
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, 
      appBar: AppBar(
        title: Padding(
          padding: const EdgeInsets.only(left: 16), 
          child: Text(
            "${widget.modele} - ${widget.immatriculation}",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
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
            icon: const Icon(Icons.location_on),
            onPressed: () {
              _showLieuxPopup();
            },
            tooltip: 'Sélectionner les lieux',
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: _isSigning ? const NeverScrollableScrollPhysics() : null,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TypeLocationContainer(
                  typeLocation: _typeLocationController.text,
                  onTypeChanged: (type) {
                    setState(() {
                      _typeLocationController.text = type;
                    });
                  },
                  onAccompteChanged: (value) {
                    setState(() {
                      _accompteController.text = value;
                    });
                  },
                  onPaymentMethodChanged: (method) {
                    setState(() {
                      _selectedPaymentMethod = method;
                    });
                  },
                  prixLocationController: _prixLocationController,
                  accompteController: _accompteController,
                ),
                const SizedBox(height: 15),
                DateContainer(
                  dateDebutController: _dateDebutController,
                  dateFinTheoriqueController: _dateFinTheoriqueController,
                  selectDateTime: (controller) => _selectDateTime(controller),
                ),
                const SizedBox(height: 15),
                KilometrageContainer(
                  kilometrageDepartController: _kilometrageDepartController,
                  kilometrageAutoriseController: _kilometrageAutoriseController,
                ),
                const SizedBox(height: 15),
                EssenceContainer(
                  pourcentageEssence: _pourcentageEssence,
                  onPourcentageChanged: (value) {
                    setState(() {
                      _pourcentageEssence = value;
                    });
                  },
                ),
                const SizedBox(height: 15),
                EtatCommentaireContainer(
                  photos: _photos,
                  onAddPhoto: _addPhoto,
                  onRemovePhoto: _removePhoto,
                  commentaireController: _commentaireController,
                ),
                const SizedBox(height: 15),

                // Afficher le conteneur de signature si au moins le nom OU le prénom est présent
                // OU si une signature existe déjà OU si on est en mode modification (widget.contratId != null)
                // Note: widget.nom et widget.prenom contiennent les valeurs du client déjà existant
                if ((widget.nom != null && widget.nom!.isNotEmpty) || 
                    (widget.prenom != null && widget.prenom!.isNotEmpty) ||
                    _signatureAller.isNotEmpty || 
                    widget.contratId != null) 
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Signature de Location',
                          style: TextStyle(
                            fontSize: 16, 
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF08004D),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Checkbox(
                              value: _acceptedConditions,
                              onChanged: (bool? value) {
                                setState(() {
                                  _acceptedConditions = value ?? false;
                                });
                              },
                              activeColor: const Color(0xFF08004D),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                "Je reconnais avoir pris connaissance des termes et conditions de location.",
                                style: TextStyle(
                                  color: _acceptedConditions ? Colors.black87 : Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_acceptedConditions) ...[  
                          const SizedBox(height: 10),
                          if (_signatureAller.isNotEmpty) ...[  // Afficher la signature existante
                            Container(
                              width: double.infinity,
                              height: 200,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(color: Colors.grey.shade300, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.shade200,
                                    blurRadius: 5,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(13),
                                child: Image.memory(
                                  base64Decode(_signatureAller),
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Center(
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  await _captureSignature();
                                },
                                icon: const Icon(Icons.edit, color: Colors.white),
                                label: const Text('Modifier la signature', style: TextStyle(color: Colors.white)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF08004D),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                ),
                              ),
                            ),
                          ] else ...[  // Afficher le bouton pour ajouter une signature
                            Center(
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  await _captureSignature();
                                },
                                icon: const Icon(Icons.draw, color: Colors.white),
                                label: const Text('Ajouter une signature', style: TextStyle(color: Colors.white)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF08004D),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                
                const SizedBox(height: 50),
                Padding(
                  padding: const EdgeInsets.only(
                      bottom: 40.0), 
                  child: ElevatedButton(
                    onPressed: (widget.nom == null ||
                            widget.nom!.isEmpty ||
                            widget.prenom == null ||
                            widget.prenom!.isEmpty ||
                            _acceptedConditions)
                        ? _validerContrat
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF08004D), 
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      widget.email != null && widget.email!.isNotEmpty
                          ? "Valider et envoyer le contrat"
                          : "Sauvegarder le contrat",
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight
                              .normal), 
                    ),
                  ),
                ),
                const SizedBox(height: 50),
              ],
            ),
          ),
          if (_isLoading) Chargement(), 
        ],
      ),
    );
  }
}