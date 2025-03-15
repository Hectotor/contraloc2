import 'dart:convert';
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
import '../USERS/contrat_condition.dart';
import 'chargement.dart'; // Import the new chargement.dart file

import 'MODIFICATION DE CONTRAT/supp_contrat.dart';
import 'MODIFICATION DE CONTRAT/info_loc.dart';
import 'MODIFICATION DE CONTRAT/info_loc_retour.dart';
import 'MODIFICATION DE CONTRAT/retour_loc.dart';
import 'navigation.dart'; // Import the NavigationPage
import 'MODIFICATION DE CONTRAT/cloturer_location.dart'; // Import the popup
import 'MODIFICATION DE CONTRAT/retour_envoie_pdf.dart'; // Nouvelle importation

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
  final TextEditingController _nettoyageIntController = TextEditingController();
  final TextEditingController _nettoyageExtController = TextEditingController();
  final TextEditingController _carburantManquantController =
      TextEditingController();
  final TextEditingController _cautionController = TextEditingController();

  Future<Map<String, dynamic>?> _getCollaborateurPermissions() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    try {
      // Vérifier si l'utilisateur est un collaborateur
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final userData = userDoc.data();
      if (userData != null && userData['role'] == 'collaborateur') {
        final adminId = userData['adminId'];
        print('👥 Utilisateur collaborateur détecté');
        print('   - Admin ID: $adminId');

        // Récupérer les permissions du collaborateur
        final collabDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(adminId)
            .collection('authentification')
            .doc(user.uid)
            .get();

        final collabData = collabDoc.data();
        if (collabData != null && collabData['permissions'] != null) {
          final permissions = collabData['permissions'];
          print('📋 Permissions collaborateur:');
          print('   - Lecture: ${permissions['lecture'] == true ? "✅" : "❌"}');
          print('   - Écriture: ${permissions['ecriture'] == true ? "✅" : "❌"}');
          return {
            'adminId': adminId,
            'permissions': permissions,
          };
        } else {
          print('❌ Aucune permission trouvée pour le collaborateur');
        }
      } else {
        print('👤 Utilisateur admin');
      }
      return null;
    } catch (e) {
      print('❌ Erreur récupération permissions : $e');
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _dateFinEffectifController.text = DateFormat('EEEE d MMMM à HH:mm', 'fr_FR')
        .format(DateTime.now()); // Date et heure actuelles par défaut
    _commentaireRetourController.text = widget.data['commentaireRetour'] ?? '';
    _kilometrageRetourController.text = widget.data['kilometrageRetour'] ?? '';
    _nettoyageIntController.text = widget.data['nettoyageInt'] ?? '';
    _nettoyageExtController.text = widget.data['nettoyageExt'] ?? '';
    _carburantManquantController.text = widget.data['carburantManquant'] ?? '';
    _cautionController.text = widget.data['caution'] ?? '';

    // Récupérer les URLs des photos depuis Firestore
    if (widget.data['photosRetourUrls'] != null) {
      _photosRetourUrls = List<String>.from(widget.data['photosRetourUrls']);
    }
  }

  Future<void> _selectDateTime(TextEditingController controller) async {
    // Suppression de la logique de sélection de date et d'heure
  }

  Future<List<String>> _uploadPhotos(List<File> photos) async {
    List<String> urls = [];
    int startIndex = _photosRetourUrls.length;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception("Utilisateur non connecté");
    }

    // Vérifier les permissions du collaborateur
    final collabInfo = await _getCollaborateurPermissions();

    // Si c'est un collaborateur avec permission d'écriture, utiliser son propre ID
    if (collabInfo != null && collabInfo['permissions']['ecriture'] == true) {
      print('👥 Upload des photos en tant que collaborateur avec droits d\'écriture');
      for (var photo in photos) {
        String fileName = 'retour_${DateTime.now().millisecondsSinceEpoch}_${startIndex + urls.length}.jpg';
        Reference ref = FirebaseStorage.instance.ref().child(
            'users/${user.uid}/locations/${widget.contratId}/photos_retour/$fileName');

        await ref.putFile(photo);
        String downloadUrl = await ref.getDownloadURL();
        urls.add(downloadUrl);
      }
    } else if (collabInfo != null) {
      // Collaborateur sans permission d'écriture, utiliser l'ID de l'admin
      print('👥 Upload des photos vers le compte admin (collaborateur sans droits d\'écriture)');
      for (var photo in photos) {
        String fileName = 'retour_${DateTime.now().millisecondsSinceEpoch}_${startIndex + urls.length}.jpg';
        Reference ref = FirebaseStorage.instance.ref().child(
            'users/${collabInfo['adminId']}/locations/${widget.contratId}/photos_retour/$fileName');

        await ref.putFile(photo);
        String downloadUrl = await ref.getDownloadURL();
        urls.add(downloadUrl);
      }
    } else {
      // Utilisateur normal
      print('👤 Upload des photos en tant qu\'utilisateur normal');
      for (var photo in photos) {
        String fileName = 'retour_${DateTime.now().millisecondsSinceEpoch}_${startIndex + urls.length}.jpg';
        Reference ref = FirebaseStorage.instance.ref().child(
            'users/${user.uid}/locations/${widget.contratId}/photos_retour/$fileName');

        await ref.putFile(photo);
        String downloadUrl = await ref.getDownloadURL();
        urls.add(downloadUrl);
      }
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

    // Vérifier les permissions du collaborateur
    final collabInfo = await _getCollaborateurPermissions();

    // Si c'est un collaborateur sans permission d'écriture, bloquer la mise à jour
    if (collabInfo != null && collabInfo['permissions']['ecriture'] != true) {
      print('❌ Tentative de clôture refusée - collaborateur sans permission d\'écriture');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Vous n'avez pas la permission de modifier ce contrat"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    print('📝 Début de la mise à jour du contrat...');

    if (_kilometrageRetourController.text.isNotEmpty &&
        int.tryParse(_kilometrageRetourController.text) != null &&
        widget.data['kilometrageDepart'] != null &&
        widget.data['kilometrageDepart'].isNotEmpty &&
        int.parse(_kilometrageRetourController.text) <
            int.parse(widget.data['kilometrageDepart'])) {
      print('❌ Erreur: kilométrage de retour inférieur au kilométrage de départ');
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
      print('📸 Traitement des photos...');
      // Conserver les URLs existantes
      List<String> allPhotosUrls = List<String>.from(_photosRetourUrls);

      // Ajouter les nouvelles photos seulement s'il y en a
      if (_photosRetour.isNotEmpty) {
        print('📤 Upload de ${_photosRetour.length} nouvelles photos...');
        List<String> newUrls = await _uploadPhotos(_photosRetour);
        allPhotosUrls.addAll(newUrls);
        print('✅ Upload des photos terminé');
      }

      // Convertir la signature de retour en base64
      String? signatureRetourBase64;
      if (_signatureRetourController.isNotEmpty) {
        print('✍️ Traitement de la signature...');
        final signatureBytes = await _signatureRetourController.toPngBytes();
        signatureRetourBase64 = base64Encode(signatureBytes!);
      }

      // Déterminer l'ID de l'utilisateur à utiliser (collaborateur avec droits ou admin)
      String targetUserId = collabInfo != null ? collabInfo['adminId'] : user.uid;
      print('👤 Mise à jour pour l\'utilisateur: ${collabInfo != null ? 'Collaborateur (Admin ID)' : 'Admin'} - $targetUserId');

      // Mettre à jour Firestore avec les informations de retour
      print('💾 Sauvegarde des données dans Firestore...');
      await FirebaseFirestore.instance
          .collection('users')
          .doc(targetUserId)
          .collection('locations')
          .doc(widget.contratId)
          .update({
        'dateFinEffectif': _dateFinEffectifController.text,
        'commentaireRetour': _commentaireRetourController.text,
        'kilometrageRetour': _kilometrageRetourController.text.isNotEmpty
            ? _kilometrageRetourController.text
            : null,
        'photosRetourUrls': allPhotosUrls,
        'nettoyageInt': _nettoyageIntController.text,
        'nettoyageExt': _nettoyageExtController.text,
        'carburantManquant': _carburantManquantController.text,
        'signature_retour': signatureRetourBase64,
      });
      print('✅ Données sauvegardées avec succès');

      // Fermer le dialogue de chargement
      if (context.mounted) {
        Navigator.pop(context);
      }

      // Générer et envoyer le PDF
      print('📄 Génération du PDF...');
      await RetourEnvoiePdf.genererEtEnvoyerPdfCloture(
        context: context,
        contratData: widget.data,
        contratId: widget.contratId,
        dateFinEffectif: _dateFinEffectifController.text,
        kilometrageRetour: _kilometrageRetourController.text,
        commentaireRetour: _commentaireRetourController.text,
        photosRetour: _photosRetour,
      );
      print('✅ PDF généré et envoyé avec succès');

      // Naviguer vers la page principale
      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const NavigationPage(initialTab: 1),
          ),
        );
      }
      print('✨ Clôture du contrat terminée avec succès');
    } catch (e) {
      print('❌ Erreur lors de la clôture du contrat: $e');
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
    // Afficher un dialogue de chargement personnalisé
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Chargement(
          message: "Génération du PDF en cours...",
        );
      },
    );

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("Utilisateur non connecté");

      // Récupérer le document du contrat
      final contratDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('locations')
          .doc(widget.contratId)
          .get();

      // Récupérer la signature de retour
      String? signatureRetourBase64;
      if (contratDoc.exists) {
        Map<String, dynamic> contratData = contratDoc.data() as Map<String, dynamic>;

        // Essayer de récupérer la signature de retour
        if (contratData.containsKey('signature_retour') &&
            contratData['signature_retour'] is String) {
          signatureRetourBase64 = contratData['signature_retour'];
        }
      }

      // Log de débogage
      print('📝 Signature de retour récupérée : ${signatureRetourBase64 != null ? 'Présente (${signatureRetourBase64.length} caractères)' : 'Absente'}');

      // Récupérer les données utilisateur
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('authentification')
          .doc(user.uid)
          .get();

      final userData = userDoc.data() ?? {};

      // Récupérer les données du véhicule
      final vehicleDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('vehicules')
          .where('immatriculation', isEqualTo: widget.data['immatriculation'])
          .get();

      final vehicleData = vehicleDoc.docs.isNotEmpty
          ? vehicleDoc.docs.first.data()
          : {};

      // Générer le PDF
      final pdfPath = await generatePdf(
        {
          ...widget.data,
          'nettoyageInt': _nettoyageIntController.text,
          'nettoyageExt': _nettoyageExtController.text,
          'carburantManquant': _carburantManquantController.text,
          'caution': _cautionController.text,
          'signatureRetour': signatureRetourBase64 ?? '',
        },
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
        widget.data['typeCarburant'] ?? '',
        widget.data['boiteVitesses'] ?? '',
        widget.data['vin'] ?? '',
        widget.data['assuranceNom'] ?? '',
        widget.data['assuranceNumero'] ?? '',
        widget.data['franchise'] ?? '',
        widget.data['kilometrageSupp'] ?? '',
        widget.data['rayures'] ?? '',
        widget.data['dateDebut'] ?? '',
        widget.data['dateFinTheorique'] ?? '',
        widget.data['dateFinEffectif'] ?? '',
        widget.data['kilometrageDepart'] ?? '',
        widget.data['kilometrageAutorise'] ?? '',
        (widget.data['pourcentageEssence'] ?? '').toString(),
        widget.data['typeLocation'] ?? '',
        widget.data['prixLocation'] ?? vehicleData['prixLocation'] ?? '',
        condition: (widget.data['conditions'] ?? ContratModifier.defaultContract).toString(),
        signatureBase64: '',
        signatureRetourBase64: signatureRetourBase64,
      );

      // Fermer le dialogue de chargement
      if (context.mounted) {
        Navigator.pop(context);
      }

      // Ouvrir le PDF
      await OpenFilex.open(pdfPath);
    } catch (e) {
      // Gestion des erreurs
      print('Erreur lors de la génération du PDF : $e');

      // Fermer le dialogue de chargement en cas d'erreur
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : ${e.toString()}')),
        );
      }
    }
  }

  DateTime _parseDateWithFallback(String dateStr) {
    try {
      // Essayer d'abord le nouveau format avec l'année
      return DateFormat('EEEE d MMMM yyyy à HH:mm', 'fr_FR').parse(dateStr);
    } catch (e) {
      // Si ça échoue, essayer l'ancien format et ajouter l'année courante
      try {
        DateTime parsedDate = DateFormat('EEEE d MMMM à HH:mm', 'fr_FR').parse(dateStr);
        // Ajouter l'année courante
        return DateTime(
          DateTime.now().year,
          parsedDate.month,
          parsedDate.day,
          parsedDate.hour,
          parsedDate.minute,
        );
      } catch (e) {
        // Si tout échoue, retourner la date actuelle
        return DateTime.now();
      }
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
              context,
              widget.contratId,
            ),
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
                      dateDebut: _parseDateWithFallback(widget.data['dateDebut']),
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
                      nom: widget.data['nom'] ?? '',
                      prenom: widget.data['prenom'] ?? '',
                      controller: _signatureRetourController,
                      accepted: true,
                      onRetourAcceptedChanged: (bool value) {
                        print('🖊️ Signature de retour acceptée : $value');
                      },
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _isUpdatingContrat
                          ? null
                          : () {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return CloturerLocationPopup(
                                    onConfirm: _updateContrat,
                                    onCancel: () {
                                      // Optional: Add any specific cancel logic if needed
                                    },
                                  );
                                },
                              );
                            }, // Disable button if updating
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