import 'dart:convert'; // Ajout de l'import pour base64Encode
import 'package:ContraLoc/utils/pdf.dart';
import 'package:ContraLoc/USERS/contrat_condition.dart';
import 'package:path_provider/path_provider.dart';
import 'package:signature/signature.dart';
import 'package:ContraLoc/services/collaborateur_util.dart';
import '../widget/navigation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:firebase_storage/firebase_storage.dart'; // Import Firebase Storage
// ignore: depend_on_referenced_packages
import 'package:intl/intl.dart'; // Import intl for date formatting
import 'CREATION DE CONTRAT/etat_vehicule.dart';
//import '../screens/contrat_screen.dart';
import 'CREATION DE CONTRAT/commentaire.dart'; // Import the new commentaire.dart
import 'chargement.dart'; // Import the new chargement.dart file
import 'CREATION DE CONTRAT/signature.dart';
import '../widget/CREATION DE CONTRAT/MAIL.DART';
import 'package:flutter_image_compress/flutter_image_compress.dart'; // Import pour la compression d'image
import 'CREATION DE CONTRAT/voiture_selectionne.dart'; // Import the new voiture_selectionne.dart file
import 'CREATION DE CONTRAT/create_contrat.dart'; // Import the new create_contrat.dart file
import 'CREATION DE CONTRAT/popup.dart'; // Import the new popup.dart file

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
  final String? immatriculationClient;
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
    this.immatriculationClient,
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
      FirebaseFirestore.instance; // Firestore instance

  final List<File> _photos = [];
  int _pourcentageEssence = 50; // Niveau d'essence par défaut
  bool _isLoading = false; // Add a state variable for loading
  bool _acceptedConditions = false; // Add a state variable for acceptance
  String _signatureBase64 = ''; // Add a state variable for signature
  bool _isSigning = false;

  late final SignatureController _signatureController;
  final TextEditingController _prixLocationController = TextEditingController();
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
    _signatureController = SignatureController(
      penStrokeWidth: 5,
      penColor: Colors.black,
      exportBackgroundColor: Colors.white,
    );

    // Initialiser la date de début avec l'année
    _dateDebutController.text = DateFormat('EEEE d MMMM yyyy à HH:mm', 'fr_FR').format(DateTime.now());
    
    // Initialiser _typeLocationController avec la valeur par défaut
    _typeLocationController.text = "Gratuite";

    // Récupérer le prix de location depuis les données du véhicule
    _fetchVehicleData();
  }

  Future<void> _fetchVehicleData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Déterminer si l'utilisateur est un collaborateur
      String adminId = user.uid; // Par défaut, l'utilisateur est considéré comme admin
      
      // Vérifier si l'utilisateur est un collaborateur
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data();
      
      if (userData != null && userData['role'] == 'collaborateur' && userData['adminId'] != null) {
        // Si c'est un collaborateur, utiliser l'ID de l'admin
        adminId = userData['adminId'];
        print('Utilisateur collaborateur détecté, utilisation de l\'adminId: $adminId');
      }
      
      // Récupérer les données du véhicule dans la collection de l'admin
      final vehiculeDoc = await _firestore
          .collection('users')
          .doc(adminId)
          .collection('vehicules')
          .where('immatriculation', isEqualTo: widget.immatriculation)
          .get();

      if (vehiculeDoc.docs.isNotEmpty) {
        final vehicleData = vehiculeDoc.docs.first.data();
        setState(() {
          _prixLocationController.text = vehicleData['prixLocation'] ?? '';
          _nettoyageIntController.text = vehicleData['nettoyageInt'] ?? '';
          _nettoyageExtController.text = vehicleData['nettoyageExt'] ?? '';
          _carburantManquantController.text = vehicleData['carburantManquant'] ?? '';
          _kilometrageAutoriseController.text = vehicleData['kilometrageAutorise'] ?? '';
          _kilometrageSuppController.text = vehicleData['kilometrageSupp'] ?? '';
          _vinController.text = vehicleData['vin'] ?? '';
          _assuranceNomController.text = vehicleData['assuranceNom'] ?? '';
          _assuranceNumeroController.text = vehicleData['assuranceNumero'] ?? '';
          _franchiseController.text = vehicleData['franchise'] ?? '';
          _rayuresController.text = vehicleData['rayures'] ?? '';
          _typeCarburantController.text = vehicleData['typeCarburant'] ?? '';
          _boiteVitessesController.text = vehicleData['boiteVitesses'] ?? '';
          _cautionController.text = vehicleData['caution'] ?? '';
          // Synchroniser les deux variables pour typeLocation
          String fetchedTypeLocation = vehicleData['typeLocation'] ?? 'Gratuite';
          _typeLocationController.text = fetchedTypeLocation;
        });
      } else {
        print('Aucun véhicule trouvé avec l\'immatriculation: ${widget.immatriculation}');
      }
    }
  }

  Future<void> _selectDateTime(TextEditingController controller) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: const Locale('fr', 'FR'), // Set locale to French
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF08004D), // Couleur de sélection
              onPrimary: Colors.white, // Couleur du texte sélectionné
              surface: Colors.white, // Couleur de fond du calendrier
              onSurface: Color(0xFF08004D), // Couleur du texte
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
                primary: Color(0xFF08004D), // Couleur des boutons et sélection
                onPrimary: Colors.white, // Couleur du texte sélectionné
                surface: Colors.white, // Couleur de fond
                onSurface: Color(0xFF08004D), // Couleur du texte
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

  Future<void> _validerContrat() async {
    // Capture de la signature avant la validation
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
      _isLoading = true; // Set loading state to true
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

      // Vérifier si l'utilisateur est un collaborateur
      final collaborateurStatus = await CollaborateurUtil.checkCollaborateurStatus();
      final String userId = collaborateurStatus['userId'] ?? user.uid;
      final String targetId = collaborateurStatus['isCollaborateur'] 
          ? collaborateurStatus['adminId'] ?? user.uid 
          : user.uid;

      print(' Création contrat - userId: $userId, targetId: $targetId');

      // D'abord, uploader toutes les photos et obtenir les URLs
      String? permisRectoUrl;
      String? permisVersoUrl;
      List<String> vehiculeUrls = [];

      // Générer un ID unique pour le contrat
      final contratId = widget.contratId ?? _firestore
          .collection('users')
          .doc(userId)
          .collection('locations')
          .doc()
          .id;

      // Upload permis photos d'abord
      if (widget.permisRecto != null) {
        permisRectoUrl = await _compressAndUploadPhoto(
            widget.permisRecto!, 'permis_recto', contratId);
      }
      if (widget.permisVerso != null) {
        permisVersoUrl = await _compressAndUploadPhoto(
            widget.permisVerso!, 'permis_verso', contratId);
      }

      // Upload des photos du véhicule
      for (var photo in _photos) {
        String url = await _compressAndUploadPhoto(photo, 'photos', contratId);
        vehiculeUrls.add(url);
      }

      // Récupérer les conditions depuis la collection 'users'
      String conditions = '';
      try {
        // Utiliser CollaborateurUtil pour récupérer les conditions
        final conditionsDoc = await CollaborateurUtil.getDocument(
          collection: 'users',
          docId: targetId,
          subCollection: 'contrats',
          subDocId: 'userId',
          useAdminId: true,
        );

        if (conditionsDoc.exists) {
          final data = conditionsDoc.data() as Map<String, dynamic>?;
          conditions = data?['texte'] ?? '';
        } else {
          // Essayer avec l'ID de l'utilisateur comme document ID
          final conditionsUserDoc = await CollaborateurUtil.getDocument(
            collection: 'users',
            docId: targetId,
            subCollection: 'contrats',
            subDocId: targetId,
            useAdminId: true,
          );

          if (conditionsUserDoc.exists) {
            final data = conditionsUserDoc.data() as Map<String, dynamic>?;
            conditions = data?['texte'] ?? '';
          } else {
            // Utiliser les conditions par défaut si aucune condition personnalisée n'existe
            final defaultConditionsDoc = await _firestore.collection('contrats').doc('default').get();
            conditions = (defaultConditionsDoc.data())?['texte'] ?? ContratModifier.defaultContract;
          }
        }
      } catch (e) {
        print('Erreur lors de la récupération des conditions: $e');
        // Utiliser les conditions par défaut en cas d'erreur
        conditions = ContratModifier.defaultContract;
      }

      // Récupérer les données utilisateur avec CollaborateurUtil avant de créer le contrat
      final userData = await CollaborateurUtil.getAuthData();
      
      // S'assurer que toutes les données sont présentes
      final nomEntreprise = userData['nomEntreprise'] ?? '';
      final adresseEntreprise = userData['adresse'] ?? '';
      final telephoneEntreprise = userData['telephone'] ?? '';
      final siretEntreprise = userData['siret'] ?? '';
      final logoUrl = userData['logoUrl'] ?? '';

      // Créer le contrat dans la collection de l'utilisateur
      await _firestore
          .collection('users')
          .doc(targetId) // Utiliser targetId au lieu de userId pour stocker dans la collection de l'admin
          .collection('locations')
          .doc(contratId)
          .set({
        'userId': userId, // Conserver l'ID de l'utilisateur qui a créé le contrat
        'adminId': targetId, // Ajouter l'ID de l'admin pour référence
        'createdBy': userId, // Ajouter qui a créé le contrat (collaborateur ou admin)
        'isCollaborateur': collaborateurStatus['isCollaborateur'] ?? false, // Indiquer si créé par un collaborateur
        'nom': widget.nom ?? '',
        'prenom': widget.prenom ?? '',
        'adresse': widget.adresse ?? '',
        'telephone': widget.telephone ?? '',
        'email': widget.email ?? '',
        'permisRecto': permisRectoUrl,
        'permisVerso': permisVersoUrl,
        'marque': widget.marque,
        'modele': widget.modele,
        'immatriculation': widget.immatriculation,
        'dateDebut': _dateDebutController.text,
        'dateFinTheorique': _dateFinTheoriqueController.text,
        'kilometrageDepart': _kilometrageDepartController.text,
        'typeLocation': _typeLocationController.text,
        'pourcentageEssence': _pourcentageEssence,
        'commentaire': _commentaireController.text,
        'photos': vehiculeUrls,
        'status': (() {
          // Par défaut, le statut est 'en_cours'
          String status = 'en_cours';
          if (_dateDebutController.text.isNotEmpty) {
            try {
              final now = DateTime.now();
              final parsedDate = DateFormat('EEEE d MMMM yyyy à HH:mm', 'fr_FR').parse(_dateDebutController.text);
              
              // Ajouter l'année actuelle à la date parsée
              final dateWithCurrentYear = DateTime(
                now.year,
                parsedDate.month,
                parsedDate.day,
                parsedDate.hour,
                parsedDate.minute,
              );
              
              // Si le mois est déjà passé cette année, on ajoute un an
              final dateToCompare = dateWithCurrentYear.isBefore(now) && 
                                   parsedDate.month < now.month ? 
                                   DateTime(now.year + 1, parsedDate.month, parsedDate.day, 
                                           parsedDate.hour, parsedDate.minute) : 
                                   dateWithCurrentYear;
              
              // On met 'réservé' uniquement si la date est dans le futur
              // et que ce n'est pas aujourd'hui
              if (dateToCompare.isAfter(now) && 
                  !(dateToCompare.year == now.year && 
                    dateToCompare.month == now.month && 
                    dateToCompare.day == now.day)) {
                status = 'réservé';
              }
            } catch (e) {
              print('Erreur parsing: $e');
            }
          }
          
          return status;
        })(),
        'dateReservation': (() {
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
        })(),
        'dateCreation':
            FieldValue.serverTimestamp(), // Ajouter la date de création
        'numeroPermis': widget.numeroPermis ??
            '', // Assurez-vous que numeroPermis est bien stocké
        'immatriculationClient': widget.immatriculationClient ??
            '', // Assurez-vous que immatriculationClient est bien stocké
        'nettoyageInt': _nettoyageIntController.text,
        'nettoyageExt': _nettoyageExtController.text,
        'carburantManquant': _carburantManquantController.text,
        'kilometrageAutorise': _kilometrageAutoriseController.text,
        'caution': _cautionController.text,
        'signature_aller': _signatureBase64, // Modification ici
        'kilometrageSupp': _kilometrageSuppController.text,
        'typeCarburant':  _typeCarburantController.text,
        'boiteVitesses':  _boiteVitessesController.text,
        'vin': _vinController.text,
        'assuranceNom': _assuranceNomController.text,
        'assuranceNumero': _assuranceNumeroController.text,
        'franchise': _franchiseController.text,
        'rayures': _rayuresController.text,
        'prixLocation': _prixLocationController.text,
        'logoUrl': logoUrl,
        'nomEntreprise': nomEntreprise,
        'adresseEntreprise': adresseEntreprise,
        'telephoneEntreprise': telephoneEntreprise,
        'siretEntreprise': siretEntreprise,
        'conditions': conditions, // Sauvegarder les conditions directement dans le document du contrat
      });

      // Si un email client est disponible, générer et envoyer le PDF
      if (widget.email != null && widget.email!.isNotEmpty) {
        // Les données utilisateur sont déjà récupérées ci-dessus
        if (userData.isEmpty) {
          throw Exception('Données utilisateur non trouvées');
        }

        final signatureAller = await _signatureController.toPngBytes();

        final pdfParams = {  
          'nom': widget.nom,  
          'prenom': widget.prenom,  
          'adresse': widget.adresse,  
          'telephone': widget.telephone,  
          'email': widget.email,  
          'numeroPermis': widget.numeroPermis,  
          'immatriculationClient': widget.immatriculationClient,  
          'marque': widget.marque,  
          'modele': widget.modele,  
          'immatriculation': widget.immatriculation,  
          'commentaire': _commentaireController.text,  
          'photos': vehiculeUrls,  
          'signatureAller': signatureAller,  
          'signatureBase64': _signatureBase64,  
          'nettoyageInt': _nettoyageIntController.text,  
          'nettoyageExt': _nettoyageExtController.text,  
          'carburantManquant': _carburantManquantController.text,  
          'caution': _cautionController.text,  
          'typeCarburant': _typeCarburantController.text,  
          'boiteVitesses': _boiteVitessesController.text,  
          'vin': _vinController.text,  
          'assuranceNom': _assuranceNomController.text,  
          'assuranceNumero': _assuranceNumeroController.text,  
          'franchise': _franchiseController.text,  
          'rayures': _rayuresController.text,  
          'kilometrageSupp': _kilometrageSuppController.text,  
          'kilometrageAutorise': _kilometrageAutoriseController.text,
          'typeLocation': _typeLocationController.text,
          'prixLocation': _prixLocationController.text,
          'kilometrageDepart': _kilometrageDepartController.text,  
          'pourcentageEssence': _pourcentageEssence.toString(),  
          'condition': conditions,  
        };  

        final pdfPath = await generatePdf(  
          pdfParams,  
          '', // dateFinEffectif  
          '', // kilometrageRetour  
          '', // commentaireRetour  
          [], // photosRetour  
          nomEntreprise,  
          logoUrl,  
          adresseEntreprise,  
          telephoneEntreprise,  
          siretEntreprise,  
          '', // commentaireRetourData  
          _typeCarburantController.text,  
          _boiteVitessesController.text,  
          _vinController.text,  
          _assuranceNomController.text,  
          _assuranceNumeroController.text,  
          _franchiseController.text,  
          _kilometrageSuppController.text,  
          _rayuresController.text,  
          _dateDebutController.text,  
          _dateFinTheoriqueController.text,  
          '', // dateFinEffectifData  
          _kilometrageDepartController.text,  
          _kilometrageAutoriseController.text,  
          _pourcentageEssence.toString(),  
          _typeLocationController.text,  
          _prixLocationController.text,  
          condition: conditions,  
        );

        // Envoyer le PDF par email
        await EmailService.sendEmailWithPdf(
          pdfPath: pdfPath,
          email: widget.email!,
          marque: widget.marque,
          modele: widget.modele,
          context: context,
          prenom: widget.prenom,
          nom: widget.nom,
          nomEntreprise: nomEntreprise,
        );
      }

      // Remplacer la redirection par navigation vers NavigationPage
      if (context.mounted) {
        Popup.showSuccess(context).then((_) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  const NavigationPage(fromPage: 'fromLocation'),
            ),
          );
        });
      }
    } catch (e) {
      print('Erreur lors de la validation du contrat : $e');
      if (context.mounted) {
        setState(() {
          _isLoading = false; // Set loading state to false
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _captureSignature() async {
    if (!_signatureController.isNotEmpty) {
      print('Aucune signature dessinée');
      return;
    }

    try {
      final signatureBytes = await _signatureController.toPngBytes();
      if (signatureBytes != null) {
        setState(() {
          _signatureBase64 = base64Encode(signatureBytes);
          print('Signature capturée en base64');
        });
      }
    } catch (e) {
      print('Erreur lors de la capture de la signature : $e');
    }
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
        // Vérifier le statut du collaborateur
        final status = await CollaborateurUtil.checkCollaborateurStatus();
        final userId = status['userId'];
        
        if (userId == null) {
          print("🔴 Erreur: Utilisateur non connecté");
          throw Exception("Utilisateur non connecté");
        }
        
        // Déterminer l'ID à utiliser (admin ou collaborateur)
        final targetId = status['isCollaborateur'] ? status['adminId'] : userId;
        
        if (targetId == null) {
          print("🔴 Erreur: ID cible non disponible");
          throw Exception("ID cible non disponible");
        }
        
        print("📝 Téléchargement d'image par ${status['isCollaborateur'] ? 'collaborateur' : 'admin'}");
        print("📝 userId: $userId, targetId (adminId): $targetId");

        String fileName =
            '${folder}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        
        // Stocker dans le dossier de l'administrateur si c'est un collaborateur
        final String storagePath = 'users/${targetId}/locations/$contratId/$folder/$fileName';
        print("📁 Chemin de stockage: $storagePath");
        
        Reference ref = FirebaseStorage.instance.ref().child(storagePath);

        // Create a temporary file for the compressed image
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/$fileName');
        await tempFile.writeAsBytes(compressedImage);

        print("⏳ Début du téléchargement...");
        // Téléchargement sans métadonnées
        await ref.putFile(tempFile);
        print("✅ Téléchargement terminé avec succès");
        
        return await ref.getDownloadURL();
      }
      throw Exception("Image compression failed");
    } catch (e) {
      print('🔴 Erreur lors du traitement de l\'image : $e');
      if (e.toString().contains('unauthorized')) {
        print('🔐 Problème d\'autorisation: Vérifiez les règles de sécurité Firebase Storage');
      }
      rethrow;
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
    _signatureController.dispose();
    _prixLocationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Ajout ici
      appBar: AppBar(
        title: const Text(
          "Détails de la Location",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF08004D), // Bleu nuit
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context); // Revenir à la page précédente
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
                      return SizedBox.shrink(); // Ne rien afficher si le champ est vide
                    }

                    try {
                      final now = DateTime.now();
                      final parsedDate = DateFormat('EEEE d MMMM yyyy à HH:mm', 'fr_FR').parse(dateText);
                      
                      // Ajouter l'année actuelle à la date parsée
                      final dateWithCurrentYear = DateTime(
                        now.year,
                        parsedDate.month,
                        parsedDate.day,
                        parsedDate.hour,
                        parsedDate.minute,
                      );
                      
                      // Si le mois est déjà passé cette année, on ajoute un an
                      final dateToCompare = dateWithCurrentYear.isBefore(now) && 
                                           parsedDate.month < now.month ? 
                                           DateTime(now.year + 1, parsedDate.month, parsedDate.day, 
                                                   parsedDate.hour, parsedDate.minute) : 
                                           dateWithCurrentYear;
                      
                      // On met 'réservé' uniquement si la date est dans le futur
                      // et que ce n'est pas aujourd'hui
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
                        return SizedBox.shrink(); // Ne rien afficher si la condition n'est pas remplie
                      }
                    } catch (e) {
                      return SizedBox.shrink(); // Ne rien afficher en cas d'erreur de parsing
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
                        _commentaireController), // Add CommentaireWidget
                const SizedBox(height: 20),
                SignatureWidget(
                  nom: widget.nom,
                  prenom: widget.prenom,
                  controller: _signatureController,
                  accepted: _acceptedConditions,
                  onAcceptedChanged: (bool value) {
                    setState(() {
                      _acceptedConditions = value;
                    });
                  },
                  onSignatureChanged: (String signature) {
                    setState(() {
                      _signatureBase64 = signature;
                    });
                  },
                  onSigningStatusChanged: (bool isSigning) {
                    setState(() {
                      _isSigning = isSigning;
                    });
                  },
                ),

                const SizedBox(height: 50),
                Padding(
                  padding: const EdgeInsets.only(
                      bottom: 40.0), // Ajout d'un padding en bas
                  child: ElevatedButton(
                    onPressed: (widget.nom == null ||
                            widget.nom!.isEmpty ||
                            widget.prenom == null ||
                            widget.prenom!.isEmpty ||
                            _acceptedConditions)
                        ? _validerContrat
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF08004D), // Bleu nuit
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
                              .normal), // Augmenter la taille de la police
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading) Chargement(), // Show loading indicator
        ],
      ),
    );
  }
}