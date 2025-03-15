import 'dart:convert'; // Ajout de l'import pour base64Encode
import 'package:ContraLoc/utils/pdf.dart';
import 'package:ContraLoc/USERS/contrat_condition.dart';
import 'package:signature/signature.dart';
import '../navigation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:firebase_storage/firebase_storage.dart'; // Import Firebase Storage
import 'package:intl/intl.dart'; // Import intl for date formatting
import 'etat_vehicule.dart';
import 'commentaire.dart'; // Import the new commentaire.dart
import '../chargement.dart'; // Import the new chargement.dart file
import 'signature.dart';
import 'MAIL.DART';
import 'voiture_selectionne.dart'; // Import the new voiture_selectionne.dart file
import 'create_contrat.dart'; // Import the new create_contrat.dart file
import 'popup.dart'; // Import the new popup.dart file

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
  String _typeLocation = "Gratuite";
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
  final TextEditingController _typeLocationController = TextEditingController();
  final TextEditingController _cautionController = TextEditingController();
  final TextEditingController _commentaireRetourController = TextEditingController();
  final TextEditingController _dateFinEffectifController = TextEditingController();
  final TextEditingController _kilometrageRetourController = TextEditingController();
  



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

    // Récupérer le prix de location depuis les données du véhicule
    _fetchVehicleData();
  }

  Future<String> _getTargetUserId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return '';

    try {
      // 1. Vérifier si c'est un collaborateur
      final userDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) return '';
      
      final userData = userDoc.data() ?? {};
      final String role = userData['role'] ?? '';
      
      if (role == 'collaborateur') {
        // Pour un collaborateur, on utilise l'ID de l'admin
        final String adminId = userData['adminId'] ?? '';
        if (adminId.isEmpty) {
          throw Exception("ID administrateur non trouvé");
        }
        return adminId;
      }

      // Pour un admin, on utilise son propre ID
      return user.uid;
    } catch (e) {
      print('❌ Erreur lors de la récupération de l\'ID cible : $e');
      throw Exception("Données administrateur non trouvées");
    }
  }

  Future<void> _fetchVehicleData() async {
    final targetUserId = await _getTargetUserId();
    if (targetUserId.isEmpty) return;

    final vehiculeDoc = await _firestore
        .collection('users')
        .doc(targetUserId)
        .collection('vehicules')
        .where('immatriculation', isEqualTo: widget.immatriculation)
        .get();

    if (vehiculeDoc.docs.isNotEmpty) {
      final vehicleData = vehiculeDoc.docs.first.data();
      setState(() {
        _prixLocationController.text = vehicleData['prixLocation']?.toString() ?? '';
        _nettoyageIntController.text = vehicleData['nettoyageInt']?.toString() ?? '';
        _nettoyageExtController.text = vehicleData['nettoyageExt']?.toString() ?? '';
        _carburantManquantController.text = vehicleData['carburantManquant']?.toString() ?? '';
        _kilometrageAutoriseController.text = vehicleData['kilometrageAutorise']?.toString() ?? '';
        _kilometrageSuppController.text = vehicleData['kilometrageSupp']?.toString() ?? '';
        _vinController.text = vehicleData['vin']?.toString() ?? '';
        _assuranceNomController.text = vehicleData['assuranceNom']?.toString() ?? '';
        _assuranceNumeroController.text = vehicleData['assuranceNumero']?.toString() ?? '';
        _franchiseController.text = vehicleData['franchise']?.toString() ?? '';
        _rayuresController.text = vehicleData['rayures']?.toString() ?? '';
        _typeCarburantController.text = vehicleData['typeCarburant']?.toString() ?? '';
        _boiteVitessesController.text = vehicleData['boiteVitesses']?.toString() ?? '';
        _typeLocationController.text = vehicleData['typeLocation']?.toString() ?? '';
        _cautionController.text = vehicleData['caution']?.toString() ?? '';
      });
    }
  }

  Future<void> _validerContrat() async {
    // Capture de la signature avant la validation
    await _captureSignature();

    if (_typeLocation == "Payante" && _prixLocationController.text.isEmpty) {
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
      final targetUserId = await _getTargetUserId();
      if (targetUserId.isEmpty) return;

      // D'abord, uploader toutes les photos et obtenir les URLs
      String? permisRectoUrl;
      String? permisVersoUrl;
      List<String> vehiculeUrls = [];

      // Générer un ID unique pour le contrat
      final contratId = widget.contratId ?? _firestore
          .collection('users')
          .doc(targetUserId)
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

      // Créer le contrat dans la collection de l'utilisateur
      await _firestore
          .collection('users')
          .doc(targetUserId)
          .collection('locations')
          .doc(contratId)
          .set({
        'userId': FirebaseAuth.instance.currentUser?.uid,
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
        'typeLocation': _typeLocation,
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
        'numeroPermis': widget.numeroPermis ??'', // Assurez-vous que numeroPermis est bien stocké
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
      });

      // Si un email client est disponible, générer et envoyer le PDF
      if (widget.email != null && widget.email!.isNotEmpty) {
        // Récupérer les données de l'utilisateur actuel pour déterminer le rôle
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          throw Exception('Utilisateur non connecté');
        }

        final userDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .get();

        if (!userDoc.exists) {
          throw Exception('Document utilisateur non trouvé');
        }

        final userData = userDoc.data() as Map<String, dynamic>;
        final String role = userData['role'] ?? '';
        String? collaborateurNom;
        String? collaborateurPrenom;

        // Si c'est un collaborateur, récupérer son nom et prénom
        if (role == 'collaborateur') {
          final String adminId = userData['adminId'] ?? '';
          final String collaborateurId = userData['id'] ?? '';

          print('📝 Récupération des données du collaborateur: ID=$collaborateurId, AdminID=$adminId');

          if (adminId.isNotEmpty && collaborateurId.isNotEmpty) {
            try {
              // Rechercher le document du collaborateur dans la collection authentification de l'admin
              final collaborateurQuery = await _firestore
                  .collection('users')
                  .doc(adminId)
                  .collection('authentification')
                  .where('id', isEqualTo: collaborateurId)
                  .limit(1)
                  .get();

              if (collaborateurQuery.docs.isNotEmpty) {
                final collaborateurData = collaborateurQuery.docs.first.data();
                collaborateurNom = collaborateurData['nom'];
                collaborateurPrenom = collaborateurData['prenom'];
                print('✅ Données collaborateur trouvées: $collaborateurPrenom $collaborateurNom');
              } else {
                print('⚠️ Document collaborateur non trouvé dans la collection authentification');
              }
            } catch (e) {
              print('❌ Erreur lors de la récupération des données du collaborateur: $e');
            }
          }
        }

        // Récupérer les données de l'entreprise depuis le document authentification de l'admin
        final adminDoc = await _firestore
            .collection('users')
            .doc(targetUserId)
            .collection('authentification')
            .doc(targetUserId)
            .get();

        if (!adminDoc.exists) {
          throw Exception('Données administrateur non trouvées');
        }

        final adminData = adminDoc.data()!;

        // S'assurer que toutes les données sont présentes
        final nomEntreprise = adminData['nomEntreprise'] ?? '';
        final adresseEntreprise = adminData['adresse'] ?? '';
        final telephoneEntreprise = adminData['telephone'] ?? '';
        final siretEntreprise = adminData['siret'] ?? '';
        final logoUrl = adminData['logoUrl'] ?? '';

        // Debug print pour vérifier les données
        print('📊 Données entreprise pour PDF:');
        print('Nom: $nomEntreprise');
        print('Adresse: $adresseEntreprise');
        print('Téléphone: $telephoneEntreprise');
        print('SIRET: $siretEntreprise');
        print('Logo: $logoUrl');

        // Récupérer les conditions depuis la collection 'users'
        final conditionsDoc = await _firestore
            .collection('users')
            .doc(targetUserId)
            .collection('contrats')
            .doc('userId')
            .get();

        String conditions = '';
        if (conditionsDoc.exists && conditionsDoc.data()?['texte'] != null) {
          conditions = conditionsDoc.data()?['texte'];
          print('✅ Conditions personnalisées trouvées pour l\'admin');
        } else {
          // Utiliser les conditions par défaut si aucune condition personnalisée n'existe
          final defaultConditionsDoc =
              await _firestore.collection('contrats').doc('default').get();
          conditions = defaultConditionsDoc.data()?['texte'] ??
              ContratModifier.defaultContract;
          print('⚠️ Conditions par défaut utilisées');
        }

        final signatureAller = await _signatureController.toPngBytes();

        // Générer le PDF avec tous les paramètres nécessaires
        final pdfPath = await generatePdf(
          {
            'nom': widget.nom,
            'prenom': widget.prenom,
            'adresse': widget.adresse,
            'telephone': widget.telephone,
            'email': widget.email,
            'numeroPermis': widget.numeroPermis,
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
            'typeLocation': _typeLocation,
            'prixLocation': _prixLocationController.text,
            'nomEntreprise': nomEntreprise,
            'adresseEntreprise': adresseEntreprise,
            'telephoneEntreprise': telephoneEntreprise,
            'siretEntreprise': siretEntreprise,
            'logoUrl': logoUrl,
            'collaborateur': {
              'nom': collaborateurNom,
              'prenom': collaborateurPrenom,
              'role': role,
            },
          },
          _dateFinEffectifController.text, // dateFinEffectif
          _kilometrageRetourController.text, // kilometrageRetour
          _commentaireRetourController.text, // commentaireRetour
          [], // photosRetour
          nomEntreprise,
          logoUrl,
          adresseEntreprise,
          telephoneEntreprise,
          siretEntreprise,
          _commentaireRetourController.text, // commentaireRetourData
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
          _dateFinEffectifController.text, // dateFinEffectifData
          _kilometrageDepartController.text,
          _kilometrageAutoriseController.text,
          _pourcentageEssence.toString(),
          _typeLocation,
          _prixLocationController.text,
          condition: conditions,
          signatureBase64: _signatureBase64,
          
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
      print(
          "Erreur lors de la validation du contrat : $e"); // Ajout d'un print pour déboguer
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur lors de la validation du contrat : $e")),
      );
    } finally {
      setState(() {
        _isLoading = false; // Set loading state to false
      });
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
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("Utilisateur non connecté");
      }

      String fileName =
          '${folder}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      // Stocker dans le dossier de l'utilisateur
      Reference ref = FirebaseStorage.instance
          .ref()
          .child('users/${user.uid}/locations/$contratId/$folder/$fileName');

      await ref.putFile(photo);
      return await ref.getDownloadURL();
    } catch (e) {
      print('Erreur lors du traitement de l\'image : $e');
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
                    print('dateText: $dateText'); // Afficher la valeur de dateText avant le parsing
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
                      print('Erreur de parsing de la date: $e');
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
                CreateContrat.buildDropdown(_typeLocation, (value) {
                  setState(() {
                    _typeLocation = value!;
                    if (_typeLocation == "Payante") {
                      _fetchVehicleData();
                    } else {
                      _prixLocationController.clear();
                    }
                  });
                }),
                if (_typeLocation == "Payante" &&
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
                if (_typeLocation == "Payante" &&
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