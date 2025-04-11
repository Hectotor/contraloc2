import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:signature/signature.dart';
import 'package:uuid/uuid.dart';
import '../services/access_locations.dart';
import '../utils/affichage_facture_pdf.dart';
import '../utils/affichage_contrat_pdf.dart';
import '../utils/photo_upload_manager.dart';
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
  List<File> _photosRetour = [];
  List<String> _photosRetourUrls = [];
  bool _isUpdatingContrat = false; 
  bool _signatureRetourAccepted = false;
  // Variable pour stocker la signature de retour
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
    // Vérifier s'il reste des photos à télécharger avant de fermer l'écran
    _checkPendingUploads();
    
    // Liberer tous les contrôleurs
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

  // Méthode pour vérifier s'il y a des photos en attente de téléchargement
  void _checkPendingUploads() {
    if (_photosEnEchec.isNotEmpty || _photosUploadInfos.isNotEmpty) {
      // Sauvegarder les informations pour une tentative ultérieure
      print('Il reste ${_photosEnEchec.length} photos en échec et ${_photosUploadInfos.length} lots de photos à télécharger');
      // Ici, on pourrait implanter un mécanisme pour sauvegarder ces informations
      // dans un stockage persistant (SharedPreferences, Hive, etc.)
    }
  }

  Future<void> _selectDateTime(TextEditingController controller) async {
  }

  // Variable pour stocker les photos qui n'ont pas pu être téléchargées
  List<File> _photosEnEchec = [];

  // Variable pour stocker les PhotoUploadInfo
  List<PhotoUploadInfo> _photosUploadInfos = [];

  // Méthode pour télécharger les photos en arrière-plan
  Future<void> _uploadPhotosInBackground() async {
    // Vérifier si nous avons des photos à télécharger directement
    if (_photosRetour.isNotEmpty) {
      PhotoUploadManager.uploadPhotosInBackground(
        context: context, // Le contexte est toujours nécessaire pour certaines opérations internes
        contratId: widget.contratId,
        photos: _photosRetour,
        existingUrls: _photosRetourUrls,
        folder: 'photos_retour',
        onFailure: (failedPhotos) {
          if (mounted) {
            setState(() {
              _photosEnEchec = failedPhotos;
            });
          }
        },
        onSuccess: () {
          if (mounted) {
            setState(() {
              _photosRetour = [];
            });
          }
        },
      );
      return;
    }
    
    // Vérifier si nous avons des PhotoUploadInfo en attente
    if (_photosUploadInfos.isNotEmpty) {
      // Prendre le premier élément de la liste
      final uploadInfo = _photosUploadInfos.removeAt(0);
      
      PhotoUploadManager.uploadPhotosInBackground(
        context: context, // Le contexte est toujours nécessaire pour certaines opérations internes
        contratId: uploadInfo.contratId,
        photos: uploadInfo.photos,
        existingUrls: uploadInfo.existingUrls,
        folder: uploadInfo.folder,
        onFailure: (failedPhotos) {
          if (mounted) {
            setState(() {
              _photosEnEchec = failedPhotos;
            });
          }
        },
        onSuccess: () {
          // Si nous avons d'autres PhotoUploadInfo, traiter le suivant
          if (_photosUploadInfos.isNotEmpty && mounted) {
            _uploadPhotosInBackground();
          }
        },
      );
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
      // Stocker les photos pour les télécharger en arrière-plan plus tard
      List<File> photosToUploadLater = [];
      if (_photosRetour.isNotEmpty) {
        photosToUploadLater = List<File>.from(_photosRetour);
        // Vider la liste des photos à télécharger immédiatement
        _photosRetour = [];
      }
      
      // Vérifier si on a des photos en échec de téléchargement précédent
      if (_photosEnEchec.isNotEmpty) {
        // Ajouter les photos en échec aux photos à télécharger
        photosToUploadLater.addAll(_photosEnEchec);
        // Vider la liste des photos en échec
        _photosEnEchec = [];
      }
      
      // Utiliser uniquement les URLs de photos déjà téléchargées
      List<String> allPhotosUrls = List<String>.from(_photosRetourUrls);

      // Créer un PhotoUploadInfo si nous avons des photos à télécharger
      if (photosToUploadLater.isNotEmpty) {
        _photosUploadInfos.add(PhotoUploadInfo(
          contratId: widget.contratId,
          folder: 'photos_retour',
          photos: photosToUploadLater,
          existingUrls: allPhotosUrls,
        ));
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

      // Utiliser la signature existante si disponible
      if (signatureRetourBase64 == null && _signatureRetourBase64 != null) {
        signatureRetourBase64 = _signatureRetourBase64;
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
        'signatureRetour': signatureRetourBase64, // Utiliser signatureRetour au lieu de signature_retour
        'photosRetourUrls': allPhotosUrls,
      };

      // N'ajouter les données de facture que si elles existent déjà dans le contrat
      if (widget.data['facture'] != null) {
        updateData['facture'] = factureData;
      }

      // Utilisation de AccessLocations pour la mise à jour
      await AccessLocations.updateContract(widget.contratId, updateData);

      // Lancer le téléchargement des photos en arrière-plan après la mise à jour du contrat
      if (photosToUploadLater.isNotEmpty) {
        // Restaurer les photos pour le téléchargement en arrière-plan
        _photosRetour = photosToUploadLater;
        // Lancer le téléchargement en arrière-plan sans attendre
        _uploadPhotosInBackground();
      }

      await RetourEnvoiePdf.genererEtEnvoyerPdfCloture(
        context: context,
        contratData: widget.data,
        contratId: widget.contratId,
        dateFinEffectif: _dateFinEffectifController.text,
        kilometrageRetour: _kilometrageRetourController.text,
        commentaireRetour: _commentaireRetourController.text,
        pourcentageEssenceRetour: _pourcentageEssenceRetourController.text,
        signatureRetourBase64: signatureRetourBase64,
        dialogueDejaAffiche: true, // Nouveau paramètre pour indiquer que le dialogue est déjà affiché
      );

      // Fermer le dialogue de chargement après l'opération complète
      if (mounted) {
        Navigator.pop(context);
      }

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

  // Méthode pour afficher un widget avec les photos en échec
  Widget _buildPhotosEnEchecWidget() {
    if (_photosEnEchec.isEmpty) return const SizedBox.shrink();
    
    return PhotoUploadManager.buildPhotosEnEchecWidget(
      context: context,
      photosEnEchec: _photosEnEchec,
      contratId: widget.contratId,
      existingUrls: _photosRetourUrls,
      folder: 'photos_retour',
      onFailure: (failedPhotos) {
        if (mounted) {
          setState(() {
            _photosEnEchec = failedPhotos;
          });
        }
      },
      onSuccess: () {
        if (mounted) {
          setState(() {
            _photosEnEchec = [];
          });
        }
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
                        if (widget.data['status'] == 'restitue') ...[
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
                                  "Voir la facture",
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
                        //ElevatedButton(
                          //onPressed: () => _showConfirmationDialog(),
                          //style: ElevatedButton.styleFrom(
                          //  backgroundColor: Colors.green,
                          //  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                          //  shape: RoundedRectangleBorder(
                          //    borderRadius: BorderRadius.circular(10),
                          //  ),
                          //),
                          //child: const Row(
                          //  mainAxisAlignment: MainAxisAlignment.center,
                          //  children: [
                          //    Icon(Icons.send, color: Colors.white),
                          //    SizedBox(width: 10),
                          //    Text(
                          //      "Renvoyer le contrat",
                          //      style: TextStyle(color: Colors.white, fontSize: 18),
                          //    ),
                          //  ],
                          //),
                        //),
                          const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () => AffichageContratPdf.genererEtAfficherContratPdf(
                            context: context,
                            data: widget.data,
                            contratId: widget.contratId,
                            signatureRetourBase64: _signatureRetourBase64,
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
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
                       // const SizedBox(height: 20),
                        //ElevatedButton(
                          //onPressed: () => AffichageContratPdf.viderCachePdf(context),
                          //style: ElevatedButton.styleFrom(
                          //  backgroundColor: Colors.red,
                          //  minimumSize: const Size(double.infinity, 50),
                          //),
                          //child: const Text(
                          //  "Vider le cache des PDF",
                          //  style: TextStyle(color: Colors.white, fontSize: 18),
                          //),
                        //),
                        //const SizedBox(height: 20),
                        _buildPhotosEnEchecWidget(),
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