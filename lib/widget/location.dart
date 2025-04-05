import 'package:ContraLoc/utils/pdf.dart';
import 'package:ContraLoc/USERS/contrat_condition.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ContraLoc/services/collaborateur_util.dart';
import '../widget/navigation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:firebase_storage/firebase_storage.dart'; 
// ignore: depend_on_referenced_packages
import 'package:intl/intl.dart'; 
import 'CREATION DE CONTRAT/etat_vehicule.dart';
import 'CREATION DE CONTRAT/commentaire.dart'; 
import 'chargement.dart'; 
import '../widget/CREATION DE CONTRAT/MAIL.DART';
import 'package:flutter_image_compress/flutter_image_compress.dart'; 
import 'CREATION DE CONTRAT/voiture_selectionne.dart'; 
import 'CREATION DE CONTRAT/create_contrat.dart'; 
import 'CREATION DE CONTRAT/popup_felicitation.dart'; 
import 'popup_signature.dart'; 
import '../models/contrat_model.dart';

class LocationPage extends StatefulWidget {
  final String marque;
  final String modele;
  final String immatriculation;
  final String? nom;
  final String? prenom;
  final String? adresse;
  final String? telephone;
  final String? email;
  final File? permisRecto;
  final File? permisVerso;
  final String? numeroPermis;
  final String? immatriculationVehiculeClient;
  final String? kilometrageVehiculeClient;
  final String? contratId;

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
    this.permisRecto,
    this.permisVerso,
    this.numeroPermis,
    this.immatriculationVehiculeClient,
    this.kilometrageVehiculeClient,
    this.contratId,
  }) : super(key: key);

  @override
  State<LocationPage> createState() => _LocationPageState();
}

class _LocationPageState extends State<LocationPage> {
  final TextEditingController _dateDebutController = TextEditingController();
  final TextEditingController _dateFinTheoriqueController =
      TextEditingController();
  final TextEditingController _kilometrageDepartController =
      TextEditingController();
  final TextEditingController _commentaireController = TextEditingController();
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance; 

  final List<File> _photos = [];
  int _pourcentageEssence = 50; 
  bool _isLoading = false; 
  bool _acceptedConditions = false; 
  String _signatureBase64 = ''; 
  bool _isSigning = false;
  String? _vehiclePhotoUrl; 

  final TextEditingController _prixLocationController = TextEditingController();
  final TextEditingController _accompteController = TextEditingController();
  final TextEditingController _nettoyageIntController = TextEditingController();
  final TextEditingController _nettoyageExtController = TextEditingController();
  final TextEditingController _carburantManquantController =
      TextEditingController();
  final TextEditingController _kilometrageAutoriseController = TextEditingController();
  final TextEditingController _kilometrageSuppController = TextEditingController();
  final TextEditingController _vinController = TextEditingController();
  final TextEditingController _assuranceNomController = TextEditingController();
  final TextEditingController _assuranceNumeroController = TextEditingController();
  final TextEditingController _franchiseController = TextEditingController();
  final TextEditingController _rayuresController = TextEditingController();
  final TextEditingController _typeCarburantController = TextEditingController();
  final TextEditingController _boiteVitessesController = TextEditingController();
  final TextEditingController _cautionController = TextEditingController();
  final TextEditingController _typeLocationController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _dateDebutController.text = DateFormat('EEEE d MMMM yyyy à HH:mm', 'fr_FR').format(DateTime.now());
    
    _typeLocationController.text = "Gratuite";

    _fetchVehicleData();
    
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
    }
  }

  Future<void> _fetchVehicleData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String adminId = user.uid; 
      
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data();
      
      if (userData != null && userData['role'] == 'collaborateur' && userData['adminId'] != null) {
        adminId = userData['adminId'];
        print('Utilisateur collaborateur détecté, utilisation de l\'adminId: $adminId');
      }
      
      final vehiculeDoc = await _firestore
          .collection('users')
          .doc(adminId)
          .collection('vehicules')
          .where('immatriculation', isEqualTo: widget.immatriculation)
          .get();

      if (vehiculeDoc.docs.isNotEmpty) {
        final vehicleData = vehiculeDoc.docs.first.data();
        setState(() {
          // Récupérer l'URL de la photo du véhicule
          _vehiclePhotoUrl = vehicleData['photoVehiculeUrl'];
          _prixLocationController.text = vehicleData['prixLocation'] ?? '';
          _nettoyageIntController.text = vehicleData['nettoyageInt'] ?? '';
          _nettoyageExtController.text = vehicleData['nettoyageExt'] ?? '';
          _carburantManquantController.text = vehicleData['carburantManquant'] ?? '';
          _kilometrageSuppController.text = vehicleData['kilometrageSupp'] ?? '';
          _vinController.text = vehicleData['vin'] ?? '';
          _assuranceNomController.text = vehicleData['assuranceNom'] ?? '';
          _assuranceNumeroController.text = vehicleData['assuranceNumero'] ?? '';
          _franchiseController.text = vehicleData['franchise'] ?? '';
          _rayuresController.text = vehicleData['rayures'] ?? '';
          _typeCarburantController.text = vehicleData['typeCarburant'] ?? '';
          _boiteVitessesController.text = vehicleData['boiteVitesses'] ?? '';
          _cautionController.text = vehicleData['caution'] ?? '';

        });
      } else {
        print('Aucun véhicule trouvé avec l\'immatriculation: ${widget.immatriculation}');
      }
    }
  }

  Future<ContratModel?> _loadContractData(String contratId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String adminId = user.uid; 
      
        // Vérifier si l'utilisateur est un collaborateur
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        final userData = userDoc.data();
      
        if (userData != null && userData['role'] == 'collaborateur' && userData['adminId'] != null) {
          adminId = userData['adminId'];
        }
      
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
      
          // Charger la signature si elle existe
          if (contractData['signature_aller'] != null) {
            setState(() {
              _signatureBase64 = contractData['signature_aller'];
              if (_signatureBase64.isNotEmpty) {
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
      
          // Mettre à jour les contrôleurs avec les données du contrat
          _updateControllersFromModel(contratModel);
          
          return contratModel;
        } else {
          print('Aucun contrat trouvé avec l\'ID: $contratId');
          return null;
        }
      }
      return null;
    } catch (e) {
      print('Erreur lors du chargement des données du contrat: $e');
      return null;
    }
  }

  Future<void> _validerContrat() async {
    await _captureSignature();

    if (_typeLocationController.text == "Payante" && _prixLocationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              "Veuillez d'abord configurer le prix de location du véhicule dans sa fiche"),
        ),
      );
      return;
    }

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

      final collaborateurStatus = await CollaborateurUtil.checkCollaborateurStatus();
      final String userId = collaborateurStatus['userId'] ?? user.uid;
      final String targetId = collaborateurStatus['isCollaborateur'] 
          ? collaborateurStatus['adminId'] ?? user.uid 
          : user.uid;

      print('Création contrat - userId: $userId, targetId: $targetId');

      // Gestion de l'ID du contrat
      final contratId = widget.contratId ?? _firestore
          .collection('users')
          .doc(userId)
          .collection('locations')
          .doc()
          .id;

      // Upload des photos
      String? permisRectoUrl;
      String? permisVersoUrl;
      List<String> vehiculeUrls = [];

      if (widget.permisRecto != null) {
        permisRectoUrl = await _compressAndUploadPhoto(
            widget.permisRecto!, 'permis_recto', contratId);
      }
      if (widget.permisVerso != null) {
        permisVersoUrl = await _compressAndUploadPhoto(
            widget.permisVerso!, 'permis_verso', contratId);
      }

      for (var photo in _photos) {
        String url = await _compressAndUploadPhoto(photo, 'photos', contratId);
        vehiculeUrls.add(url);
      }

      // Récupération des conditions
      String conditions = await _loadConditions(targetId);

      // Récupération des données utilisateur
      final userData = await CollaborateurUtil.getAuthData();
      
      final nomEntreprise = userData['nomEntreprise'] ?? '';
      final adresseEntreprise = userData['adresse'] ?? '';
      final telephoneEntreprise = userData['telephone'] ?? '';
      final siretEntreprise = userData['siret'] ?? '';
      final logoUrl = userData['logoUrl'] ?? '';

      // Récupération des informations du collaborateur
      String nomCollaborateur = '';
      String prenomCollaborateur = '';
      
      if (collaborateurStatus['isCollaborateur'] ?? false) {
        final collaborateurData = await _getCollaborateurData(userId);
        nomCollaborateur = collaborateurData['nom'] ?? '';
        prenomCollaborateur = collaborateurData['prenom'] ?? '';
      }

      // Création du modèle de contrat
      final contratModel = ContratModel(
        contratId: contratId,
        userId: userId,
        adminId: targetId,
        createdBy: userId,
        isCollaborateur: collaborateurStatus['isCollaborateur'] ?? false,
        nom: widget.nom,
        prenom: widget.prenom,
        adresse: widget.adresse,
        telephone: widget.telephone,
        email: widget.email,
        numeroPermis: widget.numeroPermis,
        immatriculationVehiculeClient: widget.immatriculationVehiculeClient,
        kilometrageVehiculeClient: widget.kilometrageVehiculeClient,
        permisRectoUrl: permisRectoUrl,
        permisVersoUrl: permisVersoUrl,
        permisRectoFile: widget.permisRecto,
        permisVersoFile: widget.permisVerso,
        marque: widget.marque,
        modele: widget.modele,
        immatriculation: widget.immatriculation,
        photoVehiculeUrl: _vehiclePhotoUrl,
        vin: _vinController.text.isNotEmpty ? _vinController.text : null,
        typeCarburant: _typeCarburantController.text.isNotEmpty ? _typeCarburantController.text : null,
        boiteVitesses: _boiteVitessesController.text.isNotEmpty ? _boiteVitessesController.text : null,
        dateDebut: _dateDebutController.text.isNotEmpty ? _dateDebutController.text : null,
        dateFinTheorique: _dateFinTheoriqueController.text.isNotEmpty ? _dateFinTheoriqueController.text : null,
        kilometrageDepart: _kilometrageDepartController.text.isNotEmpty ? _kilometrageDepartController.text : null,
        typeLocation: _typeLocationController.text.isNotEmpty ? _typeLocationController.text : "Gratuite",
        pourcentageEssence: _pourcentageEssence,
        commentaire: _commentaireController.text.isNotEmpty ? _commentaireController.text : null,
        photosUrls: vehiculeUrls,
        photosFiles: _photos,
        status: _determineContractStatus(),
        dateReservation: _calculateReservationDate(),
        dateCreation: Timestamp.now(),
        signatureAller: _signatureBase64,
        assuranceNom: _assuranceNomController.text.isNotEmpty ? _assuranceNomController.text : null,
        assuranceNumero: _assuranceNumeroController.text.isNotEmpty ? _assuranceNumeroController.text : null,
        franchise: _franchiseController.text.isNotEmpty ? _franchiseController.text : null,
        prixLocation: _prixLocationController.text.isNotEmpty ? _prixLocationController.text : null,
        accompte: _accompteController.text.isNotEmpty ? _accompteController.text : null,
        caution: _cautionController.text.isNotEmpty ? _cautionController.text : null,
        nettoyageInt: _nettoyageIntController.text.isNotEmpty ? _nettoyageIntController.text : null,
        nettoyageExt: _nettoyageExtController.text.isNotEmpty ? _nettoyageExtController.text : null,
        carburantManquant: _carburantManquantController.text.isNotEmpty ? _carburantManquantController.text : null,
        kilometrageAutorise: _kilometrageAutoriseController.text.isNotEmpty ? _kilometrageAutoriseController.text : null,
        kilometrageSupp: _kilometrageSuppController.text.isNotEmpty ? _kilometrageSuppController.text : null,
        prixRayures: _rayuresController.text.isNotEmpty ? _rayuresController.text : null,
        logoUrl: logoUrl,
        nomEntreprise: nomEntreprise,
        adresseEntreprise: adresseEntreprise,
        telephoneEntreprise: telephoneEntreprise,
        siretEntreprise: siretEntreprise,
        nomCollaborateur: nomCollaborateur,
        prenomCollaborateur: prenomCollaborateur,
        conditions: conditions,
      );

      // Sauvegarde dans Firestore
      await _firestore
          .collection('users')
          .doc(targetId)
          .collection('locations')
          .doc(contratId)
          .set(contratModel.toFirestore(), SetOptions(merge: true));

      // Génération et envoi du PDF si un email est fourni
      if (widget.email != null && widget.email!.isNotEmpty) {
        await _generateAndSendPdf(contratModel, nomEntreprise, logoUrl, adresseEntreprise, 
                                  telephoneEntreprise, siretEntreprise, nomCollaborateur, prenomCollaborateur);
      }

      // Affichage du succès et navigation
      if (context.mounted) {
        Popup.showSuccess(context).then((_) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const NavigationPage(fromPage: 'fromLocation'),
            ),
          );
        });
      }
    } catch (e) {
      // Gestion des erreurs
      print('Erreur lors de la validation du contrat : $e');
      if (context.mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : ${e.toString()}')),
        );
      }
    }
  }

  // Méthode pour déterminer le statut du contrat
  String _determineContractStatus() {
    String status = 'en_cours';
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
          status = 'réservé';
          print('Contrat défini comme réservé pour la date: ${_dateDebutController.text}');
        } else {
          print('Contrat défini comme en_cours pour la date: ${_dateDebutController.text}');
        }
      } catch (e) {
        print('Erreur parsing: $e');
      }
    }
    
    return status;
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

  // Méthode pour charger les conditions
  Future<String> _loadConditions(String targetId) async {
    try {
      // Vérifier d'abord si le document existe avant d'essayer de le récupérer
      final userDocRef = _firestore.collection('users').doc(targetId);
      final contratDocRef = userDocRef.collection('contrats').doc('userId');
      
      // Vérifier si le document existe sans déclencher d'erreur en cas d'absence
      final docExists = await _firestore.runTransaction<bool>((transaction) async {
        try {
          final docSnapshot = await transaction.get(contratDocRef);
          return docSnapshot.exists;
        } catch (e) {
          // En cas d'erreur de connectivité, supposer que le document n'existe pas
          print('Vérification de l\'existence du document impossible: $e');
          return false;
        }
      }).timeout(const Duration(seconds: 5), onTimeout: () => false);
      
      if (docExists) {
        // Le document existe, on peut le récupérer
        final conditionsDoc = await CollaborateurUtil.getDocument(
          collection: 'users',
          docId: targetId,
          subCollection: 'contrats',
          subDocId: 'userId',
          useAdminId: true,
        );

        if (conditionsDoc.exists) {
          final data = conditionsDoc.data() as Map<String, dynamic>?;
          return data?['texte'] ?? '';
        }
      } else {
        // Le document n'existe pas, essayer d'autres sources
        print('Document de conditions personnalisées non trouvé, utilisation des conditions par défaut');
        final defaultConditionsDoc = await _firestore.collection('contrats').doc('default').get();
        return (defaultConditionsDoc.data())?['texte'] ?? ContratModifier.defaultContract;
      }
    } catch (e) {
      print('Erreur lors de la récupération des conditions: $e');
    }
    return ContratModifier.defaultContract;
  }

  // Méthode pour récupérer les données du collaborateur
  Future<Map<String, dynamic>> _getCollaborateurData(String userId) async {
    try {
      final collaborateurDoc = await _firestore.collection('users').doc(userId).get();
      return collaborateurDoc.data() ?? {};
    } catch (e) {
      print('Erreur lors de la récupération des données du collaborateur: $e');
      return {};
    }
  }

  // Méthode pour générer et envoyer le PDF
  Future<void> _generateAndSendPdf(ContratModel contratModel, String nomEntreprise, String logoUrl, 
                                  String adresseEntreprise, String telephoneEntreprise, 
                                  String siretEntreprise, String nomCollaborateur, 
                                  String prenomCollaborateur) async {
    try {
      // Utilisation de la méthode toPdfParams() pour obtenir les paramètres du PDF
      final pdfParams = contratModel.toPdfParams();
      
      final pdfPath = await generatePdf(
        pdfParams,
        '', '', '', [],
        nomEntreprise, logoUrl, adresseEntreprise, telephoneEntreprise, siretEntreprise,
        '', contratModel.typeCarburant ?? '', contratModel.boiteVitesses ?? '',
        contratModel.vin ?? '', contratModel.assuranceNom ?? '',
        contratModel.assuranceNumero ?? '', contratModel.franchise ?? '',
        contratModel.kilometrageSupp ?? '', contratModel.prixRayures ?? '',
        contratModel.dateDebut ?? '', contratModel.dateFinTheorique ?? '',
        '', contratModel.kilometrageDepart ?? '', contratModel.kilometrageAutorise ?? '',
        contratModel.pourcentageEssence.toString(), contratModel.typeLocation ?? '',
        contratModel.prixLocation ?? '', contratModel.accompte ?? '',
        condition: contratModel.conditions ?? '',
        nomCollaborateur: nomCollaborateur.isNotEmpty && prenomCollaborateur.isNotEmpty 
            ? '$prenomCollaborateur $nomCollaborateur' 
            : null,
      );

      if (contratModel.email != null && contratModel.email!.isNotEmpty) {
        await EmailService.sendEmailWithPdf(
          pdfPath: pdfPath,
          email: contratModel.email!,
          marque: contratModel.marque ?? '',
          modele: contratModel.modele ?? '',
          immatriculation: contratModel.immatriculation ?? '',
          context: context,
          prenom: contratModel.prenom ?? '',
          nom: contratModel.nom ?? '',
          nomEntreprise: nomEntreprise,
          nomCollaborateur: nomCollaborateur,
          prenomCollaborateur: prenomCollaborateur,
        );
      }
    } catch (e) {
      print('Erreur lors de la génération ou de l\'envoi du PDF: $e');
      throw e; // Propager l'erreur pour la gestion globale
    }
  }

  Future<void> _captureSignature() async {
    if (_signatureBase64.isEmpty) {
      print('Aucune signature disponible');
      return;
    }
    
    print('Signature déjà capturée en base64');
  }

  Future<String> _compressAndUploadPhoto(
      File photo, String folder, String contratId) async {
    try {
      final compressedImage = await FlutterImageCompress.compressWithFile(
        photo.absolute.path,
        minWidth: 800,
        minHeight: 800,
        quality: 85,
      );

      if (compressedImage != null) {
        final status = await CollaborateurUtil.checkCollaborateurStatus();
        final userId = status['userId'];
        
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

        String fileName =
            '${folder}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        
        final String storagePath = 'users/${targetId}/locations/$contratId/$folder/$fileName';
        print(" Chemin de stockage: $storagePath");
        
        Reference ref = FirebaseStorage.instance.ref().child(storagePath);

        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/$fileName');
        await tempFile.writeAsBytes(compressedImage);

        print(" Début du téléchargement...");
        await ref.putFile(tempFile);
        print(" Téléchargement terminé avec succès");
        
        return await ref.getDownloadURL();
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

  void _removePhoto(int index) {
    setState(() {
      _photos.removeAt(index);
    });
  }

  @override
  void dispose() {
    _prixLocationController.dispose();
    _accompteController.dispose();
    super.dispose();
  }

  void _updateControllersFromModel(ContratModel model) {
    // Mise à jour des contrôleurs avec les données du modèle
    if (model.dateDebut != null) _dateDebutController.text = model.dateDebut!;
    if (model.dateFinTheorique != null) _dateFinTheoriqueController.text = model.dateFinTheorique!;
    if (model.kilometrageDepart != null) _kilometrageDepartController.text = model.kilometrageDepart!;
    if (model.typeLocation != null) _typeLocationController.text = model.typeLocation!;
    if (model.commentaire != null) _commentaireController.text = model.commentaire!;
    setState(() => _pourcentageEssence = model.pourcentageEssence);
    
    // Informations financières
    if (model.prixLocation != null) _prixLocationController.text = model.prixLocation!;
    if (model.accompte != null) _accompteController.text = model.accompte!;
    if (model.caution != null) _cautionController.text = model.caution!;
    if (model.nettoyageInt != null) _nettoyageIntController.text = model.nettoyageInt!;
    if (model.nettoyageExt != null) _nettoyageExtController.text = model.nettoyageExt!;
    if (model.carburantManquant != null) _carburantManquantController.text = model.carburantManquant!;
    if (model.kilometrageAutorise != null) _kilometrageAutoriseController.text = model.kilometrageAutorise!;
    if (model.kilometrageSupp != null) _kilometrageSuppController.text = model.kilometrageSupp!;
    if (model.prixRayures != null) _rayuresController.text = model.prixRayures!;
    
    // Informations véhicule
    if (model.typeCarburant != null) _typeCarburantController.text = model.typeCarburant!;
    if (model.boiteVitesses != null) _boiteVitessesController.text = model.boiteVitesses!;
    if (model.vin != null) _vinController.text = model.vin!;
    
    // Informations assurance
    if (model.assuranceNom != null) _assuranceNomController.text = model.assuranceNom!;
    if (model.assuranceNumero != null) _assuranceNumeroController.text = model.assuranceNumero!;
    if (model.franchise != null) _franchiseController.text = model.franchise!;
    
    // Mise à jour des variables d'état
    setState(() {
      _vehiclePhotoUrl = model.photoVehiculeUrl;
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, 
      appBar: AppBar(
        title: const Text(
          "Détails de la Location",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF08004D), 
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context); 
          },
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: _isSigning ? const NeverScrollableScrollPhysics() : null,
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                VoitureSelectionne(
                  marque: widget.marque,
                  modele: widget.modele,
                  immatriculation: widget.immatriculation,
                  firestore: _firestore,
                ),
                const SizedBox(height: 30),
                Center(
                  child: (() {
                    String dateText = _dateDebutController.text;
                    if (dateText.isEmpty) {
                      return SizedBox.shrink(); 
                    }

                    try {
                      final now = DateTime.now();
                      final parsedDate = DateFormat('EEEE d MMMM yyyy à HH:mm', 'fr_FR').parse(dateText);
                      
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
                        return Text(
                          textAlign: TextAlign.center,
                          'Véhicule réservé pour le:\n$dateText',
                          style: TextStyle(color: Colors.red, fontWeight: FontWeight.w900),
                        );
                      } else {
                        return SizedBox.shrink(); 
                      }
                    } catch (e) {
                      return SizedBox.shrink(); 
                    }
                  }()),
                ),
                const SizedBox(height: 30),
                CreateContrat.buildDateField("Date de début",
                    _dateDebutController, true, context, _selectDateTime),
                CreateContrat.buildDateField(
                    "Date de fin théorique",
                    _dateFinTheoriqueController,
                    false,
                    context,
                    _selectDateTime),
                CreateContrat.buildTextField(
                    "Kilométrage de départ", _kilometrageDepartController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ]),
                CreateContrat.buildTextField(
                  "Kilométrage Autorisé (km)",
                  _kilometrageAutoriseController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                CreateContrat.buildDropdown(_typeLocationController.text, (value) {
                  setState(() {
                    _typeLocationController.text = value!;
                  });
                }),
                if (_typeLocationController.text == "Payante" &&
                    _prixLocationController.text.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 8.0),
                    child: Text(
                      "Veuillez configurer le prix de la location dans sa fiche afin qu'il soit affiché correctement.",
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                      ),
                    ),
                  ),
                if (_typeLocationController.text == "Payante" &&
                    _prixLocationController.text.isNotEmpty) ...[
                  const SizedBox(height: 35),
                  CreateContrat.buildPrixLocationField(_prixLocationController),
                  CreateContrat.buildAccompteField(_accompteController),
                  const SizedBox(height: 20),
                ],
                const SizedBox(height: 20),
                CreateContrat.buildFuelSlider(_pourcentageEssence, (value) {
                  setState(() {
                    _pourcentageEssence = value.toInt();
                  });
                }),
                const SizedBox(height: 20),
                EtatVehicule(
                  photos: _photos,
                  onAddPhoto: _addPhoto,
                  onRemovePhoto: _removePhoto,
                ),
                const SizedBox(height: 20),
                CommentaireWidget(
                    controller:
                        _commentaireController), 
                const SizedBox(height: 20),
                
                // Afficher le conteneur de signature si au moins le nom OU le prénom est présent
                if ((widget.nom != null && widget.nom!.isNotEmpty) || 
                    (widget.prenom != null && widget.prenom!.isNotEmpty)) 
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
                      const Text(
                        'Signature de Location',
                        style: TextStyle(
                          fontSize: 16, 
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF08004D),
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
                        const SizedBox(height: 15),
                        if (_signatureBase64.isNotEmpty) ...[
                          Container(
                            width: double.infinity,
                            height: 100,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Image.memory(
                              Uri.parse('data:image/png;base64,$_signatureBase64').data!.contentAsBytes(),
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                        Center(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final signature = await PopupSignature.showSignatureDialog(
                                context,
                                title: 'Signature du contrat',
                                checkboxText: 'J\'accepte les conditions de location',
                                nom: widget.nom,
                                prenom: widget.prenom,
                                existingSignature: _signatureBase64,
                              );
                              
                              if (signature != null) {
                                setState(() {
                                  _signatureBase64 = signature;
                                });
                              }
                            },
                            icon: const Icon(Icons.edit),
                            label: Text(_signatureBase64.isEmpty ? 'Signer le contrat' : 'Modifier la signature'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF08004D),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            ),
                          ),
                        ),
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
              ],
            ),
          ),
          if (_isLoading) Chargement(), 
        ],
      ),
    );
  }
}