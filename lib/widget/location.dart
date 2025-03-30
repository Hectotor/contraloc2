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

    _dateDebutController.text = DateFormat('EEEE d MMMM yyyy à HH:mm', 'fr_FR').format(DateTime.now());
    
    _typeLocationController.text = "Gratuite";

    _fetchVehicleData();
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

      print(' Création contrat - userId: $userId, targetId: $targetId');

      String? permisRectoUrl;
      String? permisVersoUrl;
      List<String> vehiculeUrls = [];

      final contratId = widget.contratId ?? _firestore
          .collection('users')
          .doc(userId)
          .collection('locations')
          .doc()
          .id;

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

      String conditions = '';  
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
            conditions = data?['texte'] ?? '';
          }
        } else {
          // Le document n'existe pas, essayer d'autres sources
          print('Document de conditions personnalisées non trouvé, utilisation des conditions par défaut');
          final defaultConditionsDoc = await _firestore.collection('contrats').doc('default').get();
          conditions = (defaultConditionsDoc.data())?['texte'] ?? ContratModifier.defaultContract;
        }
      } catch (e) {
        print('Erreur lors de la récupération des conditions: $e');
        conditions = ContratModifier.defaultContract;
      }

      final userData = await CollaborateurUtil.getAuthData();
      
      final nomEntreprise = userData['nomEntreprise'] ?? '';
      final adresseEntreprise = userData['adresse'] ?? '';
      final telephoneEntreprise = userData['telephone'] ?? '';
      final siretEntreprise = userData['siret'] ?? '';
      final logoUrl = userData['logoUrl'] ?? '';

      // Récupérer les informations du collaborateur qui crée le contrat
      String nomCollaborateur = '';
      String prenomCollaborateur = '';
      
      if (collaborateurStatus['isCollaborateur'] ?? false) {
        // Si c'est un collaborateur, récupérer son nom et prénom
        final collaborateurDoc = await _firestore.collection('users').doc(userId).get();
        final collaborateurData = collaborateurDoc.data();
        if (collaborateurData != null) {
          nomCollaborateur = collaborateurData['nom'] ?? '';
          prenomCollaborateur = collaborateurData['prenom'] ?? '';
        }
      }

      await _firestore
          .collection('users')
          .doc(targetId) 
          .collection('locations')
          .doc(contratId)
          .set({
        'userId': userId, 
        'adminId': targetId, 
        'createdBy': userId, 
        'isCollaborateur': collaborateurStatus['isCollaborateur'] ?? false, 
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
            FieldValue.serverTimestamp(), 
        'numeroPermis': widget.numeroPermis ??
            '', 
        'immatriculationVehiculeClient': widget.immatriculationVehiculeClient ??
            '', 
        'kilometrageVehiculeClient': widget.kilometrageVehiculeClient ??
            '', 
        'nettoyageInt': _nettoyageIntController.text,
        'nettoyageExt': _nettoyageExtController.text,
        'carburantManquant': _carburantManquantController.text,
        'kilometrageAutorise': _kilometrageAutoriseController.text,
        'caution': _cautionController.text,
        'signature_aller': _signatureBase64, 
        'kilometrageSupp': _kilometrageSuppController.text,
        'typeCarburant':  _typeCarburantController.text,
        'boiteVitesses':  _boiteVitessesController.text,
        'vin': _vinController.text,
        'assuranceNom': _assuranceNomController.text,
        'assuranceNumero': _assuranceNumeroController.text,
        'franchise': _franchiseController.text,
        'prixRayures': _rayuresController.text,  
        'prixLocation': _prixLocationController.text,
        'logoUrl': logoUrl,
        'nomEntreprise': nomEntreprise,
        'adresseEntreprise': adresseEntreprise,
        'telephoneEntreprise': telephoneEntreprise,
        'siretEntreprise': siretEntreprise,
        'conditions': conditions, 
        'nomCollaborateur': nomCollaborateur,
        'prenomCollaborateur': prenomCollaborateur,
      });

      if (widget.email != null && widget.email!.isNotEmpty) {
        final pdfParams = {  
          'nom': widget.nom,  
          'prenom': widget.prenom,  
          'adresse': widget.adresse,  
          'telephone': widget.telephone,  
          'email': widget.email,  
          'numeroPermis': widget.numeroPermis,  
          'immatriculationVehiculeClient': widget.immatriculationVehiculeClient,
          'kilometrageVehiculeClient': widget.kilometrageVehiculeClient,  
          'marque': widget.marque,  
          'modele': widget.modele,  
          'immatriculation': widget.immatriculation,  
          'commentaire': _commentaireController.text,  
          'photos': vehiculeUrls,  
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
          'prixRayures': _rayuresController.text,  
          'kilometrageSupp': _kilometrageSuppController.text,  
          'kilometrageAutorise': _kilometrageAutoriseController.text,
          'typeLocation': _typeLocationController.text,
          'prixLocation': _prixLocationController.text,
          'kilometrageDepart': _kilometrageDepartController.text,  
          'pourcentageEssence': _pourcentageEssence.toString(),  
          'condition': conditions, 
          'nomCollaborateur': nomCollaborateur, 
          'prenomCollaborateur': prenomCollaborateur, 
        };  

        final pdfPath = await generatePdf(  
          pdfParams,  
          '', 
          '', 
          '', 
          [], 
          nomEntreprise,  
          logoUrl,  
          adresseEntreprise,  
          telephoneEntreprise,  
          siretEntreprise,  
          '', 
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
          '', 
          _kilometrageDepartController.text,  
          _kilometrageAutoriseController.text,  
          _pourcentageEssence.toString(),  
          _typeLocationController.text,  
          _prixLocationController.text,  
          condition: conditions,  
          nomCollaborateur: nomCollaborateur.isNotEmpty && prenomCollaborateur.isNotEmpty 
              ? '$prenomCollaborateur $nomCollaborateur' 
              : null,
        );

        await EmailService.sendEmailWithPdf(
          pdfPath: pdfPath,
          email: widget.email!,
          marque: widget.marque,
          modele: widget.modele,
          immatriculation: widget.immatriculation,
          context: context,
          prenom: widget.prenom,
          nom: widget.nom,
          nomEntreprise: nomEntreprise,
        );
      }

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
          _isLoading = false; 
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : ${e.toString()}')),
        );
      }
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
    super.dispose();
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