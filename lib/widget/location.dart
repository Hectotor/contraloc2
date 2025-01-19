import 'package:ContraLoc/utils/pdf.dart';
import 'package:ContraLoc/widget/MES%20CONTRATS/contrat_condition.dart';
import 'package:path_provider/path_provider.dart';
import 'package:signature/signature.dart';
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
import 'CREATION DE CONTRAT/voiture_selectionne.dart'; // Import the new voiture_selectionne.dart file
import 'CREATION DE CONTRAT/create_contrat.dart'; // Import the new create_contrat.dart file
import 'CREATION DE CONTRAT/popup.dart'; // Import the new popup.dart file
import 'package:flutter_image_compress/flutter_image_compress.dart';

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

  late final SignatureController _signatureController;
  final TextEditingController _prixLocationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _signatureController = SignatureController(
      penStrokeWidth: 5,
      penColor: Colors.black,
      exportBackgroundColor: Colors.white,
    );

    // Récupérer le prix de location depuis les données du véhicule
    _fetchVehicleData();
  }

  Future<void> _fetchVehicleData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final vehiculeDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('vehicules')
          .where('immatriculation', isEqualTo: widget.immatriculation)
          .get();

      if (vehiculeDoc.docs.isNotEmpty) {
        final vehicleData = vehiculeDoc.docs.first.data();
        setState(() {
          _prixLocationController.text = vehicleData['prixLocation'] ?? '';
        });
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
        final formattedDateTime =
            DateFormat('EEEE d MMMM à HH:mm', 'fr_FR').format(dateTime);
        setState(() {
          controller.text = formattedDateTime;
        });
      }
    }
  }

  Future<void> _validerContrat() async {
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

      // D'abord, uploader toutes les photos et obtenir les URLs
      String? permisRectoUrl;
      String? permisVersoUrl;
      List<String> vehiculeUrls = [];

      // Générer un ID unique pour le contrat
      final contratId = _firestore
          .collection('users')
          .doc(user.uid)
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
          .doc(user.uid)
          .collection('locations')
          .doc(contratId)
          .set({
        'userId': user.uid,
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
        'status': 'en_cours', // Modifier 'en cours' en 'en_cours'
        'dateCreation':
            FieldValue.serverTimestamp(), // Ajouter la date de création
        'numeroPermis': widget.numeroPermis ??
            '', // Assurez-vous que numeroPermis est bien stocké
      });

      // Si un email client est disponible, générer et envoyer le PDF
      if (widget.email != null && widget.email!.isNotEmpty) {
        // Récupérer les données utilisateur de manière plus robuste
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('authentification')
            .doc(user.uid)
            .get();

        if (!userDoc.exists) {
          throw Exception('Données utilisateur non trouvées');
        }

        final userData = userDoc.data()!;

        // S'assurer que toutes les données sont présentes
        final nomEntreprise = userData['nomEntreprise'] ?? '';
        final adresseEntreprise = userData['adresse'] ?? '';
        final telephoneEntreprise = userData['telephone'] ?? '';
        final siretEntreprise = userData['siret'] ?? '';

        // Debug print pour vérifier les données
        print('Données entreprise pour PDF:');
        print('Nom: $nomEntreprise');
        print('Adresse: $adresseEntreprise');
        print('Téléphone: $telephoneEntreprise');
        print('SIRET: $siretEntreprise');

        // Récupérer les données du véhicule depuis la collection de l'utilisateur
        final vehicleDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('vehicules')
            .where('immatriculation', isEqualTo: widget.immatriculation)
            .get();

        final vehicleData =
            vehicleDoc.docs.isNotEmpty ? vehicleDoc.docs.first.data() : {};

        // Récupérer les conditions depuis la collection 'users'
        final conditionsDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('contrats')
            .doc(user.uid)
            .get();

        String conditions = '';
        if (conditionsDoc.exists && conditionsDoc.data()?['texte'] != null) {
          conditions = conditionsDoc.data()?['texte'];
        } else {
          // Utiliser les conditions par défaut si aucune condition personnalisée n'existe
          final defaultConditionsDoc =
              await _firestore.collection('contrats').doc('default').get();
          conditions = defaultConditionsDoc.data()?['texte'] ??
              ContratModifier.defaultContract;
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
            'numeroPermis': widget.numeroPermis, // Ajoutez cette ligne
            'marque': widget.marque,
            'modele': widget.modele,
            'immatriculation': widget.immatriculation,
            'commentaire': _commentaireController.text,
            'photos': vehiculeUrls,
            'signatureAller': signatureAller,
          },
          '', // dateFinEffectif
          '', // kilometrageRetour
          '', // commentaireRetour
          [], // photosRetour
          nomEntreprise, // déjà passé comme paramètre positionnel
          userData['logoUrl'] ?? '',
          adresseEntreprise, // déjà passé comme paramètre positionnel
          telephoneEntreprise, // déjà passé comme paramètre positionnel
          siretEntreprise, // déjà passé comme paramètre positionnel
          '', // commentaireRetourData
          vehicleData['typeCarburant'] ?? '',
          vehicleData['boiteVitesses'] ?? '',
          vehicleData['vin'] ?? '',
          vehicleData['assuranceNom'] ?? '',
          vehicleData['assuranceNumero'] ?? '',
          vehicleData['franchise'] ?? '',
          vehicleData['kilometrageSupp'] ?? '',
          vehicleData['rayures'] ?? '',
          _dateDebutController.text,
          _dateFinTheoriqueController.text,
          '', // dateFinEffectifData
          _kilometrageDepartController.text,
          _pourcentageEssence.toString(),
          _typeLocation,
          vehicleData['prixLocation'] ?? '',
          condition: conditions, // seul paramètre nommé nécessaire
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
          nomEntreprise: userData['nomEntreprise'] ??
              '', // Passer le nom de l'entreprise de l'utilisateur
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

        // Create a temporary file for the compressed image
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/$fileName');
        await tempFile.writeAsBytes(compressedImage);

        await ref.putFile(tempFile);
        return await ref.getDownloadURL();
      }
      throw Exception("Image compression failed");
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Ajout ici
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
                const SizedBox(height: 40),
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
                const SizedBox(height: 20),
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
                  onAcceptedChanged: (bool accepted) {
                    setState(() {
                      _acceptedConditions = accepted;
                    });
                  },
                ),
                const SizedBox(height: 20),
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
