import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:photo_view/photo_view.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart'; 
import 'package:photo_view/photo_view_gallery.dart';
import 'package:signature/signature.dart';
import '../utils/pdf.dart';
import '../USERS/contrat_condition.dart';
import 'package:ContraLoc/services/collaborateur_util.dart';
import 'MODIFICATION DE CONTRAT/supp_contrat.dart';
import 'MODIFICATION DE CONTRAT/info_loc.dart';
import 'MODIFICATION DE CONTRAT/info_loc_retour.dart';
import 'MODIFICATION DE CONTRAT/retour_loc.dart';
import 'MODIFICATION DE CONTRAT/retour_envoie_pdf.dart'; 
import 'MODIFICATION DE CONTRAT/info_veh.dart';
import 'MODIFICATION DE CONTRAT/info_client.dart';
import 'MODIFICATION DE CONTRAT/etat_vehicule_retour.dart';
import 'MODIFICATION DE CONTRAT/signature_retour.dart';
import 'MODIFICATION DE CONTRAT/cloturer_location.dart';
import 'MODIFICATION DE CONTRAT/facture.dart';
import 'navigation.dart';

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
      TextEditingController();
  final SignatureController _signatureRetourController = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );
  final TextEditingController _kilometrageRetourController =
      TextEditingController();
  final List<File> _photosRetour = [];
  List<String> _photosRetourUrls = [];
  bool _isUpdatingContrat = false; 
  bool _signatureRetourAccepted = false;
  String? _signatureRetourBase64;
  final TextEditingController _nettoyageIntController = TextEditingController();
  final TextEditingController _nettoyageExtController = TextEditingController();
  final TextEditingController _niveauEssenceRetourController =
      TextEditingController();
  final TextEditingController _cautionController = TextEditingController();

  Map<String, dynamic> _fraisSupplementaires = {};

  void _handleFraisUpdated(Map<String, dynamic> frais) {
    Future.microtask(() {
      setState(() {
        _fraisSupplementaires = frais;

        if (frais['nettoyageInt'] != null && frais['nettoyageInt'].toString().isNotEmpty) {
          _nettoyageIntController.text = frais['nettoyageInt'].toString();
        }

        if (frais['nettoyageExt'] != null && frais['nettoyageExt'].toString().isNotEmpty) {
          _nettoyageExtController.text = frais['nettoyageExt'].toString();
        }

        if (frais['niveauEssenceRetour'] != null && frais['niveauEssenceRetour'].toString().isNotEmpty) {
          _niveauEssenceRetourController.text = frais['niveauEssenceRetour'].toString();
        }

        if (frais['caution'] != null) {
          _cautionController.text = frais['caution'].toString();
        }


      });
    });
  }

  @override
  void initState() {
    super.initState();
    _dateFinEffectifController.text = DateFormat('EEEE d MMMM yyyy à HH:mm', 'fr_FR')
        .format(DateTime.now()); 
    _commentaireRetourController.text = widget.data['commentaireRetour'] ?? '';
    _kilometrageRetourController.text = widget.data['kilometrageRetour']?.toString() ?? '';
    
    // Conversion des valeurs en String pour éviter les erreurs de type
    _nettoyageIntController.text = widget.data['nettoyageInt']?.toString() ?? '';
    _nettoyageExtController.text = widget.data['nettoyageExt']?.toString() ?? '';
    _niveauEssenceRetourController.text = widget.data['niveauEssenceRetour']?.toString() ?? '';
    _cautionController.text = widget.data['caution']?.toString() ?? '';

    if (widget.data['photosRetourUrls'] != null) {
      _photosRetourUrls = List<String>.from(widget.data['photosRetourUrls']);
    }
  }

  Future<void> _selectDateTime(TextEditingController controller) async {
  }

  Future<List<String>> _uploadPhotos(List<File> photos) async {
    List<String> urls = [];
    int startIndex = _photosRetourUrls
        .length; 

    try {
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

      print(" Téléchargement de photos retour par ${status['isCollaborateur'] ? 'collaborateur' : 'admin'}");
      print(" userId: $userId, targetId (adminId): $targetId");

      for (var photo in photos) {
        final compressedImage = await FlutterImageCompress.compressWithFile(
          photo.absolute.path,
          minWidth: 800,
          minHeight: 800,
          quality: 70, 
        );

        if (compressedImage == null) {
          print(" Erreur: Échec de la compression de l'image");
          continue;
        }

        String fileName =
            'retour_${DateTime.now().millisecondsSinceEpoch}_${startIndex + urls.length}.jpg';

        final String storagePath = 'users/${targetId}/locations/${widget.contratId}/photos_retour/$fileName';


        Reference ref = FirebaseStorage.instance.ref().child(storagePath);

        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/$fileName');
        await tempFile.writeAsBytes(compressedImage);

        await ref.putFile(tempFile);

        String downloadUrl = await ref.getDownloadURL();
        urls.add(downloadUrl);
      }
      return urls;
    } catch (e) {
      print(' Erreur lors du téléchargement des photos : $e');
      if (e.toString().contains('unauthorized')) {
        print(' Problème d\'autorisation: Vérifiez les règles de sécurité Firebase Storage');
      }
      rethrow;
    }
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

    setState(() {
      _isUpdatingContrat = true;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(child: CircularProgressIndicator());
      },
    );

    try {
      final status = await CollaborateurUtil.checkCollaborateurStatus();
      final userId = status['userId'];
      final isCollaborateur = status['isCollaborateur'] == true;
      final adminId = status['adminId'];

      print(' Mise à jour du contrat - userId: $userId, isCollaborateur: $isCollaborateur, adminId: $adminId');

      List<String> allPhotosUrls = List<String>.from(_photosRetourUrls);

      if (_photosRetour.isNotEmpty) {
        List<String> newUrls = await _uploadPhotos(_photosRetour);
        allPhotosUrls.addAll(newUrls);
      }

      String? signatureRetourBase64 = _signatureRetourBase64 != null && _signatureRetourBase64!.isNotEmpty ? _signatureRetourBase64 : null;

      Map<String, dynamic> fraisFinaux = _fraisSupplementaires;
      
      print(' Sauvegarde des frais définitifs: $fraisFinaux');

      final updateData = {
        'status': 'restitue',
        'dateFinEffectif': _dateFinEffectifController.text,
        'commentaireRetour': _commentaireRetourController.text,
        'kilometrageRetour': _kilometrageRetourController.text.isNotEmpty
            ? _kilometrageRetourController.text
            : null,
        'photosRetourUrls': allPhotosUrls,
        'pourcentageEssenceRetour': _niveauEssenceRetourController.text,
        'signature_retour': signatureRetourBase64,
      };

      if (isCollaborateur && adminId != null) {
        try {
          print(' Début de la mise à jour du contrat par le collaborateur');
          print(' ID Collaborateur: ${FirebaseAuth.instance.currentUser?.uid}');
          print(' ID Admin: $adminId');
          print(' ID Contrat: ${widget.contratId}');
          
          await CollaborateurUtil.updateDocument(
            collection: 'locations',
            docId: widget.contratId,
            data: updateData,
            useAdminId: true,
          );
          print(' Contrat mis à jour dans la collection de l\'admin: $adminId');
        } catch (e) {
          print(' Erreur lors de la mise à jour du contrat: $e');
        }
      } else {
        try {
          print(' Début de la mise à jour du contrat par l\'administrateur');
          print(' ID Administrateur: ${FirebaseAuth.instance.currentUser?.uid}');
          print(' ID Contrat: ${widget.contratId}');
          
          await CollaborateurUtil.updateDocument(
            collection: 'locations',
            docId: widget.contratId,
            data: updateData,
            useAdminId: false,
          );
          print(' Contrat mis à jour dans la collection de l\'administrateur');
        } catch (e) {
          print(' Erreur lors de la mise à jour du contrat: $e');
        }
      }

      Navigator.pop(context);

      await RetourEnvoiePdf.genererEtEnvoyerPdfCloture(
        context: context,
        contratData: widget.data,
        contratId: widget.contratId,
        dateFinEffectif: _dateFinEffectifController.text,
        kilometrageRetour: _kilometrageRetourController.text,
        commentaireRetour: _commentaireRetourController.text,
        photosRetour: _photosRetour,
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const NavigationPage(initialTab: 1),
        ),
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur : $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isUpdatingContrat = false;
      });
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
              style: TextStyle(color: Colors.white), 
            ),
            backgroundColor: Colors.black, 
            iconTheme: const IconThemeData(
                color: Colors.white), 
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
    bool dialogShown = false;
    if (context.mounted) {
      dialogShown = true;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
    }

    try {
      final appDir = await getApplicationDocumentsDirectory();
      final localPdfPath = '${appDir.path}/contrat_${widget.contratId}.pdf';
      final localPdfFile = File(localPdfPath);
      
      // Vérifier si le contrat est en cours
      bool isContratEnCours = widget.data['status'] == 'en_cours';
      
      // Si le PDF existe en cache ET que le contrat n'est PAS en cours, utiliser la version cachée
      if (await localPdfFile.exists() && !isContratEnCours) {
        print(' PDF trouvé en cache local, ouverture directe');
        
        if (dialogShown && context.mounted) {
          Navigator.pop(context);
          dialogShown = false;
        }
        
        await OpenFilex.open(localPdfPath);
        return;
      }
      
      // Si le contrat est en cours ou si le PDF n'existe pas en cache, générer un nouveau PDF
      if (isContratEnCours) {
        print(' Contrat en cours, génération d\'un nouveau PDF sans utiliser le cache');
      } else {
        print(' PDF non trouvé en cache local, génération sans appels Firestore...');
      }
      
      final status = await CollaborateurUtil.checkCollaborateurStatus();
      final userId = status['userId'];
      final isCollaborateur = status['isCollaborateur'] == true;
      
      print(' Génération PDF - userId: $userId, isCollaborateur: $isCollaborateur');

      String conditions = widget.data['conditions'] ?? ContratModifier.defaultContract;
      
      String? signatureRetourBase64 = widget.data['signature_retour'] ?? widget.data['signatureRetour'];
      
      print(' Signature de retour récupérée : ${signatureRetourBase64 != null ? 'Présente' : 'Absente'}');
      print(' Conditions personnalisées récupérées : ${conditions != ContratModifier.defaultContract ? 'Personnalisées' : 'Par défaut'}');

      final userData = await CollaborateurUtil.getAuthData();

      final pdfPath = await generatePdf(
        {
          ...widget.data,
          'nettoyageInt': _nettoyageIntController.text,
          'nettoyageExt': _nettoyageExtController.text,
          'pourcentageEssenceRetour': _niveauEssenceRetourController.text,
          'caution': _cautionController.text,
          'signatureRetour': _signatureRetourBase64 != null && _signatureRetourBase64!.isNotEmpty ? _signatureRetourBase64 : null,
          'conditions': conditions,
          'contratId': widget.contratId,
        },
        widget.data['dateFinEffectif'] ?? '',
        widget.data['kilometrageRetour'] ?? '',
        widget.data['commentaireRetour'] ?? '',
        [],  // photosRetour
        widget.data['nomEntreprise'] ?? userData['nomEntreprise'] ?? '',
        widget.data['logoUrl'] ?? userData['logoUrl'] ?? '',
        widget.data['adresseEntreprise'] ?? userData['adresse'] ?? '',
        widget.data['telephoneEntreprise'] ?? userData['telephone'] ?? '',
        widget.data['siretEntreprise'] ?? userData['siret'] ?? '',
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
        widget.data['prixLocation'] ?? '',
        widget.data['accompte'] ?? '',
        condition: conditions,
        signatureBase64: '',
        signatureRetourBase64: _signatureRetourBase64 != null && _signatureRetourBase64!.isNotEmpty ? _signatureRetourBase64 : null,
        nomCollaborateur: widget.data['nomCollaborateur'] != null && widget.data['prenomCollaborateur'] != null
            ? '${widget.data['prenomCollaborateur']} ${widget.data['nomCollaborateur']}'
            : null,
      );
      
      try {
        // Ne sauvegarder en cache que si le contrat n'est PAS en cours
        if (!isContratEnCours) {
          await File(pdfPath).copy(localPdfPath);
          print(' PDF sauvegardé en cache local: $localPdfPath');
        } else {
          print(' Contrat en cours - PDF non sauvegardé en cache');
        }
      } catch (e) {
        print(' Erreur lors de la sauvegarde du PDF en cache local: $e');
      }

      if (dialogShown && context.mounted) {
        Navigator.pop(context);
        dialogShown = false;
      }

      await OpenFilex.open(pdfPath);

    } catch (e) {
      print(' Erreur lors de la génération du PDF : $e');
      
      if (dialogShown && context.mounted) {
        Navigator.pop(context);
        dialogShown = false;

        String errorMessage = 'Une erreur est survenue lors de la génération du PDF.';
        if (e.toString().contains('unavailable')) {
          errorMessage = 'Problème de connexion au serveur. Vérifiez votre connexion internet et réessayez.';
        } else if (e.toString().contains('permission-denied')) {
          errorMessage = 'Vous n\'avez pas les permissions nécessaires pour accéder à ce contrat.';
        } else {
          errorMessage = 'Erreur : ${e.toString()}';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Réessayer',
              onPressed: () {
                _generatePdf();
              },
            ),
          ),
        );
      }
    }
  }

  // Fonction pour vider le cache des PDF
  Future<void> _clearPdfCache() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final directory = Directory(appDir.path);
      
      // Lister tous les fichiers du répertoire
      final files = directory.listSync();
      
      // Filtrer pour ne garder que les fichiers PDF
      final pdfFiles = files.where((file) => 
        file.path.toLowerCase().endsWith('.pdf') && 
        file.path.contains('contrat_')
      );
      
      // Supprimer chaque fichier PDF
      for (var file in pdfFiles) {
        await File(file.path).delete();
        print('Suppression du fichier caché: ${file.path}');
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cache des PDF vidé avec succès'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Erreur lors de la suppression du cache: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du vidage du cache: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  DateTime _parseDateWithFallback(String dateStr) {
    try {
      return DateFormat('EEEE d MMMM yyyy à HH:mm', 'fr_FR').parse(dateStr);
    } catch (e) {
      try {
        DateTime parsedDate = DateFormat('EEEE d MMMM à HH:mm', 'fr_FR').parse(dateStr);
        return DateTime(
          DateTime.now().year,
          parsedDate.month,
          parsedDate.day,
          parsedDate.hour,
          parsedDate.minute,
        );
      } catch (e) {
        return DateTime.now();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
       
      appBar: AppBar(
        title: Text(
          widget.data['status'] == 'restitue' ? "Restitués" : "En cours",
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Color(0xFF08004D),
        iconTheme: const IconThemeData(
            color: Colors.white), 
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
                  const SizedBox(height: 50),
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
                  const SizedBox(height: 30),
                  if (widget.data['status'] == 'en_cours') ...[
                    RetourLoc(
                      dateFinEffectifController: _dateFinEffectifController,
                      kilometrageRetourController: _kilometrageRetourController,
                      niveauEssenceRetourController: _niveauEssenceRetourController,
                      data: widget.data,
                      selectDateTime: _selectDateTime,
                      dateDebut: _parseDateWithFallback(widget.data['dateDebut']),
                      onFraisUpdated: _handleFraisUpdated,
                    ),
                    const SizedBox(height: 40),
                    EtatVehiculeRetour(
                      photos: _photosRetour,
                      onAddPhoto: _addPhotoRetour,
                      onRemovePhoto: _removePhotoRetour,
                      commentaireController: _commentaireRetourController,
                    ),
                    const SizedBox(height: 20),
                    // Utilisation du widget SignatureRetourWidget amélioré
                    if ((widget.data['nom'] != null && widget.data['nom'] != '') || 
                        (widget.data['prenom'] != null && widget.data['prenom'] != ''))
                    SignatureRetourWidget(
                      nom: widget.data['nom'],
                      prenom: widget.data['prenom'],
                      controller: _signatureRetourController,
                      accepted: _signatureRetourAccepted,
                      onRetourAcceptedChanged: (value) {
                        setState(() {
                          _signatureRetourAccepted = value;
                        });
                      },
                      onSignatureChanged: (base64) {
                        setState(() {
                          _signatureRetourBase64 = base64;
                        });
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
                                    },
                                  );
                                },
                              );
                            }, 
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black, 
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: _isUpdatingContrat
                          ? const CircularProgressIndicator(
                              color: Colors.white) 
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
                        bottom: 30.0), 
                    child: Column(
                      children: [
                        if (widget.data['status'] == 'restitue') ...[
                          ElevatedButton(
                            onPressed: () async {
                              // Mettre à jour les données avec le kilométrage de retour actuel
                              if (_kilometrageRetourController.text.isNotEmpty) {
                                widget.data['kilometrageRetour'] = _kilometrageRetourController.text;
                              }
                              
                              // Récupérer les valeurs de kilométrage
                              double kilometrageInitial = double.tryParse(widget.data['kilometrageDepart'] ?? '0') ?? 0;
                              double kilometrageActuel = double.tryParse(_kilometrageRetourController.text) ?? 0;
                              double tarifKilometrique = double.tryParse(widget.data['tarifKilometrique'] ?? '0') ?? 0;
                              
                              // Récupérer la date de fin effective
                              String dateFinEffective = _dateFinEffectifController.text;
                              
                              // Afficher la page de la facture
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FactureScreen(
                                    data: {...widget.data, 'contratId': widget.contratId},
                                    onFraisUpdated: _handleFraisUpdated,
                                    kilometrageInitial: kilometrageInitial,
                                    kilometrageActuel: kilometrageActuel,
                                    tarifKilometrique: tarifKilometrique,
                                    dateFinEffective: dateFinEffective,
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal, 
                              minimumSize: const Size(double.infinity, 50),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.receipt_long, color: Colors.white),
                                SizedBox(width: 10),
                                Text(
                                  "Facturer la location",
                                  style: TextStyle(color: Colors.white, fontSize: 18),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                        ElevatedButton(
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
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: _clearPdfCache,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            minimumSize: const Size(double.infinity, 50),
                          ),
                          child: const Text(
                            "Vider le cache des PDF",
                            style: TextStyle(color: Colors.white, fontSize: 18),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}