import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart';

import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'MODIFICATION DE CONTRAT/signature_retour.dart';
import 'MODIFICATION DE CONTRAT/info_veh.dart';
import 'MODIFICATION DE CONTRAT/info_client.dart';

import 'dart:io';
import 'package:signature/signature.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'MODIFICATION DE CONTRAT/etat_vehicule_retour.dart';
import 'MODIFICATION DE CONTRAT/commentaire_retour.dart';

import '../utils/pdf.dart';
import 'MES CONTRATS/contrat_condition.dart';
import 'chargement.dart'; // Import the new chargement.dart file

import 'MODIFICATION DE CONTRAT/supp_contrat.dart';
import 'MODIFICATION DE CONTRAT/info_loc.dart';
import 'MODIFICATION DE CONTRAT/info_loc_retour.dart';
import 'MODIFICATION DE CONTRAT/retour_loc.dart';
import 'navigation.dart'; // Import the NavigationPage

class ModifierScreen extends StatefulWidget {
  final String contratId;
  final Map<String, dynamic> data;

  const ModifierScreen({Key? key, required this.contratId, required this.data})
      : super(key: key);

  @override
  State<ModifierScreen> createState() => _ModifierScreenState();
}

class _ModifierScreenState extends State<ModifierScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _dateFinEffectifController =
      TextEditingController();
  final TextEditingController _commentaireRetourController =
      TextEditingController(); // Garder une seule instance
  final TextEditingController _kilometrageRetourController =
      TextEditingController();
  final SignatureController _signatureRetourController = SignatureController(
    penStrokeWidth: 5,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );
  final List<File> _photosRetour = [];
  // Ajout d'une liste pour stocker les URLs des photos
  List<String> _photosRetourUrls = [];
  bool _isGeneratingPdf = false; // Add a state variable for loading
  bool _isUpdatingContrat = false; // Add a state variable for updating

  @override
  void initState() {
    super.initState();
    _dateFinEffectifController.text = DateFormat('EEEE d MMMM à HH:mm', 'fr_FR')
        .format(DateTime.now()); // Date et heure actuelles par défaut
    _commentaireRetourController.text = widget.data['commentaireRetour'] ?? '';
    _kilometrageRetourController.text = widget.data['kilometrageRetour'] ?? '';

    // Récupérer les URLs des photos depuis Firestore
    if (widget.data['photosRetourUrls'] != null) {
      _photosRetourUrls = List<String>.from(widget.data['photosRetourUrls']);
    }
  }

  Future<void> _selectDateTime(TextEditingController controller) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: const Locale('fr', 'FR'), // Set locale to French
    );
    if (pickedDate != null) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (pickedTime != null) {
        final dateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        final formattedDateTime = DateFormat('EEEE d MMMM à HH:mm', 'fr_FR')
            .format(dateTime); // Use the specified format
        setState(() {
          controller.text = formattedDateTime;
        });
      }
    }
  }

  // Nouvelle méthode pour télécharger les photos avec index
  Future<List<String>> _uploadPhotos(List<File> photos) async {
    List<String> urls = [];
    int startIndex = _photosRetourUrls
        .length; // Commence à partir du nombre de photos existantes
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception("Utilisateur non connecté");
    }
    for (var photo in photos) {
      String fileName =
          'retour_${DateTime.now().millisecondsSinceEpoch}_${startIndex + urls.length}.jpg';
      Reference ref = FirebaseStorage.instance.ref().child(
          'users/${user.uid}/locations/${widget.contratId}/photos_retour/$fileName');

      await ref.putFile(photo);
      String downloadUrl = await ref.getDownloadURL();
      urls.add(downloadUrl);
    }
    return urls;
  }

  Future<void> _updateContrat() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Utilisateur non connecté")),
      );
      return;
    }

    if (_kilometrageRetourController.text.isNotEmpty &&
        int.tryParse(_kilometrageRetourController.text) != null &&
        widget.data['kilometrageDepart'] != null &&
        widget.data['kilometrageDepart'].isNotEmpty &&
        int.parse(_kilometrageRetourController.text) <
            int.parse(widget.data['kilometrageDepart'])) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              "Le kilométrage de retour ne peut pas être inférieur au kilométrage de départ"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Afficher le dialogue de chargement
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(child: CircularProgressIndicator());
      },
    );

    try {
      // Conserver les URLs existantes
      List<String> allPhotosUrls = List<String>.from(_photosRetourUrls);

      // Ajouter les nouvelles photos seulement s'il y en a
      if (_photosRetour.isNotEmpty) {
        List<String> newUrls = await _uploadPhotos(_photosRetour);
        allPhotosUrls.addAll(newUrls);
      }

      // Mettre à jour Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('locations')
          .doc(widget.contratId)
          .update({
        'dateFinEffectif': _dateFinEffectifController.text,
        'commentaireRetour': _commentaireRetourController.text,
        'kilometrageRetour': _kilometrageRetourController.text.isNotEmpty
            ? _kilometrageRetourController.text
            : null,
        'photosRetourUrls': allPhotosUrls,
        'status': 'restitue',
        'dateRestitution': FieldValue.serverTimestamp(),
      });

      // Fermer le dialogue de chargement
      if (context.mounted) {
        Navigator.pop(context);
      }

      // Afficher le message de succès et naviguer
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Contrat mis à jour avec succès !"),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const NavigationPage(initialTab: 1),
          ),
        );
      }
    } catch (e) {
      // Fermer le dialogue de chargement en cas d'erreur
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erreur : $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _addPhotoRetour(File photo) {
    setState(() {
      _photosRetour.add(photo);
    });
  }

  void _removePhotoRetour(int index) {
    setState(() {
      _photosRetour.removeAt(index);
    });
  }

  // Modifier la méthode _showFullScreenImages pour utiliser les URLs
  void _showFullScreenImages(
      BuildContext context, List<dynamic> images, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text(
              "Photos",
              style: TextStyle(color: Colors.white), // Texte en blanc
            ),
            backgroundColor: Colors.black, // Fond en noir
            iconTheme: const IconThemeData(
                color: Colors.white), // Icône retour en blanc
          ),
          body: PhotoViewGallery.builder(
            itemCount: images.length,
            builder: (context, index) {
              final image = images[index];
              final imageProvider = image is String && image.startsWith('http')
                  ? NetworkImage(image)
                  : FileImage(File(image)) as ImageProvider;

              return PhotoViewGalleryPageOptions(
                imageProvider: imageProvider,
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 2,
              );
            },
            scrollPhysics: const BouncingScrollPhysics(),
            backgroundDecoration: const BoxDecoration(
              color: Colors.black,
            ),
            pageController: PageController(initialPage: initialIndex),
          ),
        ),
      ),
    );
  }

  Future<void> _generatePdf() async {
    setState(() {
      _isGeneratingPdf = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("Utilisateur non connecté");

      // Récupérer les données utilisateur
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

      // Récupérer les données du véhicule depuis la collection de l'utilisateur
      final vehicleDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('vehicules')
          .where('immatriculation', isEqualTo: widget.data['immatriculation'])
          .get();

      final vehicleData =
          vehicleDoc.docs.isNotEmpty ? vehicleDoc.docs.first.data() : {};

      // Récupérer les conditions mises à jour depuis Firestore
      final conditionsDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('contrats')
          .doc('userId')
          .get();

      final conditions =
          conditionsDoc.exists && conditionsDoc.data()?['texte'] != null
              ? conditionsDoc.data()!['texte']
              : ContratModifier.defaultContract;

      final pdfPath = await generatePdf(
        widget.data,
        widget.data['dateFinEffectif'] ?? '',
        widget.data['kilometrageRetour'] ?? '',
        widget.data['commentaireRetour'] ?? '',
        [],
        userData['nomEntreprise'] ?? '',
        userData['logoUrl'] ?? '',
        userData['adresse'] ?? '',
        userData['telephone'] ?? '',
        userData['siret'] ?? '',
        widget.data['commentaireRetour'] ?? '',
        vehicleData['typeCarburant'] ?? '',
        vehicleData['boiteVitesses'] ?? '',
        vehicleData['vin'] ?? '',
        vehicleData['assuranceNom'] ?? '',
        vehicleData['assuranceNumero'] ?? '',
        vehicleData['franchise'] ?? '',
        vehicleData['kilometrageSupp'] ?? '',
        vehicleData['rayures'] ?? '',
        widget.data['dateDebut'] ?? '',
        widget.data['dateFinTheorique'] ?? '',
        widget.data['dateFinEffectif'] ?? '',
        widget.data['kilometrageDepart'] ?? '',
        widget.data['pourcentageEssence']?.toString() ?? '0',
        widget.data['typeLocation'] ?? '',
        vehicleData['prixLocation'] ?? '',
        condition: conditions, // Utiliser les conditions mises à jour
      );

      await OpenFilex.open(pdfPath);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur lors de la génération du PDF : $e")),
      );
    } finally {
      setState(() {
        _isGeneratingPdf = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Ajout ici
      appBar: AppBar(
        title: Text(
          widget.data['status'] == 'restitue' ? "Restitués" : "En cours",
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Color(0xFF08004D),
        iconTheme: const IconThemeData(
            color: Colors.white), // L'icône est déjà en blanc
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.white),
            onPressed: () => SuppContrat.showDeleteConfirmationDialog(
                context, widget.contratId),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InfoVehicule(data: widget.data),
                  const SizedBox(height: 20),
                  InfoClient(
                    data: widget.data,
                    onShowFullScreenImages: _showFullScreenImages,
                  ),
                  const SizedBox(height: 20),
                  InfoLoc(
                    data: widget.data,
                    onShowFullScreenImages: _showFullScreenImages,
                  ),
                  const SizedBox(height: 20),
                  if (widget.data['status'] == 'restitue') ...[
                    InfoLocRetour(
                      data: widget.data,
                      onShowFullScreenImages: _showFullScreenImages,
                    ),
                  ],
                  const SizedBox(height: 20),
                  if (widget.data['status'] == 'en_cours') ...[
                    RetourLoc(
                      dateFinEffectifController: _dateFinEffectifController,
                      kilometrageRetourController: _kilometrageRetourController,
                      data: widget.data,
                      selectDateTime: _selectDateTime,
                    ),
                    const SizedBox(height: 20),
                    EtatVehiculeRetour(
                      photos: _photosRetour,
                      onAddPhoto: _addPhotoRetour,
                      onRemovePhoto: _removePhotoRetour,
                    ),
                    const SizedBox(height: 20),
                    CommentaireRetourWidget(
                        controller: _commentaireRetourController),
                    const SizedBox(height: 20),
                    const SizedBox(height: 10),
                    SignatureRetourWidget(
                      nom: widget.data['nom'],
                      prenom: widget.data['prenom'],
                      controller: _signatureRetourController,
                      accepted: true,
                      onRetourAcceptedChanged:
                          (bool value) {}, // Assuming the signature is accepted
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _isUpdatingContrat
                          ? null
                          : _updateContrat, // Disable button if updating
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF08004D), // Bleu nuit
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: _isUpdatingContrat
                          ? const CircularProgressIndicator(
                              color: Colors.white) // Show loading indicator
                          : const Text(
                              "Clôturer la location",
                              style:
                                  TextStyle(color: Colors.white, fontSize: 18),
                            ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.only(
                        bottom: 30.0), // Augmenter la marge du bas
                    child: ElevatedButton(
                      onPressed: _generatePdf,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text(
                        "Afficher le contrat",
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          if (_isGeneratingPdf) Chargement(), // Show loading indicator
        ],
      ),
    );
  }
}
