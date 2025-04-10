import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'dart:convert'; // Ajout de l'import pour la fonction base64Encode
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_view/photo_view.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart'; 
import 'package:photo_view/photo_view_gallery.dart';
import 'package:signature/signature.dart';
import '../utils/affichage_facture_pdf.dart';
import '../utils/affichage_contrat_pdf.dart';
import 'package:ContraLoc/services/collaborateur_util.dart';
import 'package:ContraLoc/services/access_locations.dart';
import 'MODIFICATION DE CONTRAT/supp_contrat.dart';
import 'MODIFICATION DE CONTRAT/info_loc.dart';
import 'MODIFICATION DE CONTRAT/info_loc_retour.dart';
import 'MODIFICATION DE CONTRAT/retour_loc.dart';
import 'MODIFICATION DE CONTRAT/retour_envoie_pdf.dart'; 
import 'MODIFICATION DE CONTRAT/info_client.dart';
import 'MODIFICATION DE CONTRAT/etat_vehicule_retour.dart';
import 'MODIFICATION DE CONTRAT/signature_retour.dart';
import 'MODIFICATION DE CONTRAT/cloturer_location.dart';
import 'MODIFICATION DE CONTRAT/facture.dart';
import 'navigation.dart';
import 'CREATION DE CONTRAT/client.dart';
import 'package:uuid/uuid.dart';

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
  final TextEditingController _dateFinEffectifController = TextEditingController();
  final TextEditingController _commentaireRetourController = TextEditingController();
  final SignatureController _signatureRetourController = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );
  final TextEditingController _kilometrageRetourController = TextEditingController();
  final TextEditingController _pourcentageEssenceRetourController = TextEditingController();
  final List<File> _photosRetour = [];
  List<String> _photosRetourUrls = [];
  bool _isUpdatingContrat = false; 
  bool _signatureRetourAccepted = false;
  String? _signatureRetourBase64;
  final TextEditingController _nettoyageIntController = TextEditingController();
  final TextEditingController _nettoyageExtController = TextEditingController();
  final TextEditingController _cautionController = TextEditingController();

  Map<String, dynamic> _fraisSupplementaires = {};

  String _formatStatus(String? status) {
    if (status == null) return '';
    switch (status) {
      case 'en_cours':
        return 'EN COURS';
      case 'restitue':
        return 'RESTITUÉS';
      case 'supprime':
        return 'SUPPRIMÉS';
      default:
        return status.replaceAll('_', ' ').toUpperCase();
    }
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
    _pourcentageEssenceRetourController.text = widget.data['niveauEssenceRetour']?.toString() ?? '';
    _cautionController.text = widget.data['caution']?.toString() ?? '';

    if (widget.data['photosRetourUrls'] != null) {
      _photosRetourUrls = List<String>.from(widget.data['photosRetourUrls']);
    }
  }

  @override
  void dispose() {
    _dateFinEffectifController.dispose();
    _commentaireRetourController.dispose();
    _kilometrageRetourController.dispose();
    _pourcentageEssenceRetourController.dispose();
    _nettoyageIntController.dispose();
    _nettoyageExtController.dispose();
    _cautionController.dispose();
    try {
      _signatureRetourController.dispose();
    } catch (e) {
      print('Erreur lors du dispose du SignatureController: $e');
    }
    super.dispose();
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

    if (mounted) {
      setState(() {
        _isUpdatingContrat = true;
      });
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(child: CircularProgressIndicator());
      },
    );

    try {
      // Récupérer les données d'authentification pour déterminer l'adminId
      final authData = await AccessLocations.getAuthData();
      final isCollaborateur = authData['isCollaborateur'] as bool;
      final targetId = isCollaborateur ? authData['adminId']?.toString() : authData['userId']?.toString();
      
      print('📝 MODIFERSCREEN - Mise à jour - isCollaborateur: $isCollaborateur, targetId: $targetId');
      print('📝 MODIFERSCREEN - contratId: ${widget.contratId}');
      print('📝 MODIFERSCREEN - authData: $authData');

      List<String> allPhotosUrls = List<String>.from(_photosRetourUrls);

      if (_photosRetour.isNotEmpty) {
        List<String> newUrls = await _uploadPhotos(_photosRetour);
        allPhotosUrls.addAll(newUrls);
      }

      String? signatureRetourBase64;
      try {
        final signatureBytes = await _signatureRetourController.toPngBytes();
        if (signatureBytes != null) {
          signatureRetourBase64 = base64Encode(signatureBytes);
        }
      } catch (e) {
        print('Erreur lors de la capture de la signature: $e');
      }

      Map<String, dynamic> fraisFinaux = _fraisSupplementaires;
      
      print(' Sauvegarde des frais définitifs: $fraisFinaux');

      // Récupérer les données de facture existantes
      Map<String, dynamic> factureData = {
        'facturePrixLocation': widget.data['facturePrixLocation'] ?? 0.0,
        'factureCaution': widget.data['factureCaution'] ?? 0.0,
        'factureFraisNettoyageInterieur': widget.data['facture']?['factureFraisNettoyageInterieur'] ?? 0.0,
        'factureFraisNettoyageExterieur': widget.data['facture']?['factureFraisNettoyageExterieur'] ?? 0.0,
        'factureFraisCarburantManquant': widget.data['facture']?['factureFraisCarburantManquant'] ?? 0.0,
        'factureFraisRayuresDommages': widget.data['facture']?['factureFraisRayuresDommages'] ?? 0.0,
        'factureFraisAutre': widget.data['facture']?['factureFraisAutre'] ?? 0.0,
        'factureCoutKmSupplementaires': widget.data['facture']?['factureCoutKmSupplementaires'] ?? 0.0,
        'factureRemise': widget.data['facture']?['factureRemise'] ?? 0.0,
        'factureTotalFrais': widget.data['facture']?['factureTotalFrais'] ?? 0.0,
        'factureTypePaiement': widget.data['facture']?['factureTypePaiement'] ?? 'Carte bancaire',
        'dateFacture': widget.data['facture']?['dateFacture'],
        'factureId': widget.data['facture']?['factureId'] ?? '',
        'factureGeneree': widget.data['facture']?['factureGeneree'] ?? true,
      };

      // Si on n'a pas de factureId, générer un nouvel ID unique
      if (factureData['factureId'].isEmpty) {
        factureData['factureId'] = const Uuid().v4();
      }

      final updateData = {
        'status': 'restitue',
        'dateFinEffectif': _dateFinEffectifController.text,
        'commentaireRetour': _commentaireRetourController.text,
        'kilometrageRetour': _kilometrageRetourController.text.isNotEmpty
            ? _kilometrageRetourController.text
            : null,
        'pourcentageEssenceRetour': _pourcentageEssenceRetourController.text,
        'signature_retour': signatureRetourBase64,
        'photosRetourUrls': allPhotosUrls,
        'facture': factureData,
      };

      // Utilisation de AccessLocations pour la mise à jour
      await AccessLocations.updateContract(widget.contratId, updateData);

      Navigator.pop(context);

      await RetourEnvoiePdf.genererEtEnvoyerPdfCloture(
        context: context,
        contratData: widget.data,
        contratId: widget.contratId,
        dateFinEffectif: _dateFinEffectifController.text,
        kilometrageRetour: _kilometrageRetourController.text,
        commentaireRetour: _commentaireRetourController.text,
        pourcentageEssenceRetour: _pourcentageEssenceRetourController.text,
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const NavigationPage(initialTab: 1),
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erreur : $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingContrat = false;
        });
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

  Future<void> _showConfirmationDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // empêche la fermeture en cliquant à l'extérieur
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmation'),
          content: SingleChildScrollView(
            child: ListBody(
              children: const <Widget>[
                Text('Êtes-vous sûr de vouloir renvoyer le contrat à votre client ?'),
                SizedBox(height: 10),
                Text('Cette action enverra un email avec le contrat PDF au client.'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Annuler'),
              onPressed: () {
                Navigator.of(context).pop(); // Ferme la boîte de dialogue
              },
            ),
            TextButton(
              child: const Text('Renvoyer'),
              onPressed: () async {
                Navigator.of(context).pop(); // Ferme la boîte de dialogue
                
                if (!_formKey.currentState!.validate()) return;
                
                try {
                  if (mounted) {
                    setState(() {
                      _isUpdatingContrat = true;
                    });
                  }
                  
                  // Récupérer la signature de retour
                  final signatureBytes = await _signatureRetourController.toPngBytes();
                  String? signatureBase64;
                  if (signatureBytes != null) {
                    signatureBase64 = base64Encode(signatureBytes);
                  }

                  // Générer et envoyer le PDF
                  await RetourEnvoiePdf.genererEtEnvoyerPdfCloture(
                    context: context,
                    contratData: widget.data,
                    contratId: widget.contratId,
                    dateFinEffectif: _dateFinEffectifController.text,
                    kilometrageRetour: _kilometrageRetourController.text,
                    commentaireRetour: _commentaireRetourController.text,
                    pourcentageEssenceRetour: _pourcentageEssenceRetourController.text,
                    signatureRetourBase64: signatureBase64,
                  );

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Le contrat a été renvoyé avec succès'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Erreur lors de l\'envoi du contrat: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } finally {
                  if (mounted) {
                    setState(() {
                      _isUpdatingContrat = false;
                    });
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
       
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              _formatStatus(widget.data['status']),
              style: const TextStyle(fontSize: 16, color: Colors.white,),
            ),
            const SizedBox(height: 4),
            Text(
              '${widget.data['modele'] ?? ''} - ${widget.data['immatriculation'] ?? ''}',
              style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF08004D),
        elevation: 0,
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
                      pourcentageEssenceRetourController: _pourcentageEssenceRetourController,
                      data: widget.data,
                      selectDateTime: _selectDateTime,
                      dateDebut: _parseDateWithFallback(widget.data['dateDebut']),
                      onFraisUpdated: (frais) {},
                    ),
                    const SizedBox(height: 20),
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
                    const SizedBox(height: 60),
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
                                    data: widget.data,
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
                          : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.receipt, color: Colors.white),
                              SizedBox(width: 10),
                              Text(
                                "Clôturer la location",
                                style: TextStyle(color: Colors.white, fontSize: 18),
                              ),
                            ],
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
                              
                              // Afficher la page de la facture
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FactureScreen(
                                    data: {...widget.data, 'contratId': widget.contratId},
                                    onFraisUpdated: (frais) {
                                      // Mettre à jour les données locales avec les nouvelles valeurs
                                      setState(() {
                                        widget.data.addAll(frais);
                                      });
                                    },

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
                        if (widget.data['factureGeneree'] == true) ...[
                          ElevatedButton(
                            onPressed: () => AffichageFacturePdf.genererEtAfficherFacturePdf(
                              context: context,
                              contratId: widget.contratId,
                              contratData: widget.data,
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.receipt, color: Colors.white),
                                SizedBox(width: 10),
                                Text(
                                  "Afficher la facture",
                                  style: TextStyle(color: Colors.white, fontSize: 18),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                        if (widget.data['status'] == 'réservé') ...[  
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ClientPage(
                                    marque: widget.data['marque'],
                                    modele: widget.data['modele'],
                                    immatriculation: widget.data['immatriculation'],
                                    contratId: widget.contratId,
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              minimumSize: const Size(double.infinity, 50),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.edit, color: Colors.white),
                                SizedBox(width: 10),
                                Text(
                                  "Modifier le contrat",
                                  style: TextStyle(color: Colors.white, fontSize: 18),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                        ElevatedButton(
                          onPressed: () => _showConfirmationDialog(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.send, color: Colors.white),
                              SizedBox(width: 10),
                              Text(
                                "Renvoyer le contrat",
                                style: TextStyle(color: Colors.white, fontSize: 18),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () => AffichageContratPdf.genererEtAfficherContratPdf(
                            context: context,
                            data: widget.data,
                            contratId: widget.contratId,
                            signatureRetourBase64: _signatureRetourBase64,
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.visibility, color: Colors.white),
                              SizedBox(width: 10),
                              Text(
                                "Afficher le contrat",
                                style: TextStyle(color: Colors.white, fontSize: 18),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () => AffichageContratPdf.viderCachePdf(context),
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