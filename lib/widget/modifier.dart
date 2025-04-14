import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:signature/signature.dart';
import '../utils/affichage_facture_pdf.dart';
import '../utils/affichage_contrat_pdf.dart';
import 'package:ContraLoc/services/access_locations.dart';
import 'MODIFICATION DE CONTRAT/supp_contrat.dart';
import 'MODIFICATION DE CONTRAT/info_loc.dart';
import 'MODIFICATION DE CONTRAT/info_loc_retour.dart';
import 'MODIFICATION DE CONTRAT/retour_loc.dart';
import 'MODIFICATION DE CONTRAT/retour_envoie_pdf.dart';
import 'MODIFICATION DE CONTRAT/info_client.dart';
import 'MODIFICATION DE CONTRAT/etat_vehicule_retour.dart';
import 'MODIFICATION DE CONTRAT/cloturer_location.dart';
import 'MODIFICATION DE CONTRAT/facture.dart';
import 'MODIFICATION DE CONTRAT/signature_retour.dart';
import 'navigation.dart';
import 'CREATION DE CONTRAT/client.dart';
import 'package:uuid/uuid.dart';
import 'photo_upload_popup.dart';

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
    print('Status du contrat: ${widget.data['status']}'); // Ajouté pour le debug
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
    try {
      // Afficher le popup de téléchargement
      List<String>? uploadedUrls = await showDialog<List<String>>(
        context: context,
        barrierDismissible: false,
        builder: (context) => PhotoUploadPopup(
          photos: photos,
          contratId: widget.contratId,
          onUploadComplete: (List<String> urls) {
            Navigator.of(context).pop(urls);
          },
        ),
      );

      if (uploadedUrls == null) {
        throw Exception('Téléchargement annulé par l\'utilisateur');
      }

      return uploadedUrls;
    } catch (e) {
      print('Erreur lors du téléchargement des photos: $e');
      throw e;
    }
  }

  /// Clôture le contrat avec une approche transactionnelle robuste
  Future<void> _updateContrat() async {
    if (!_formKey.currentState!.validate()) return;

    // Vérification de la cohérence du kilométrage
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

    // Afficher un dialogue de chargement
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(child: CircularProgressIndicator());
      },
    );

    try {
      // Préparer les photos
      List<String> allPhotosUrls = List<String>.from(_photosRetourUrls);

      if (_photosRetour.isNotEmpty) {
        List<String> newUrls = await _uploadPhotos(_photosRetour);
        allPhotosUrls.addAll(newUrls);
      }

      // Gérer la signature
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
      
      print('💰 Sauvegarde des frais définitifs: $fraisFinaux');

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
        'factureFraisCasque': widget.data['facture']?['factureFraisCasque'] ?? 0.0,
        'dateFacture': widget.data['facture']?['dateFacture'],
        'factureId': widget.data['facture']?['factureId'] ?? '',
        'factureGeneree': widget.data['facture']?['factureGeneree'] ?? true,
      };

      // Si on n'a pas de factureId, générer un nouvel ID unique
      if (factureData['factureId'].isEmpty) {
        factureData['factureId'] = const Uuid().v4();
      }

      // Préparer les données de mise à jour
      final updateData = {
        'status': 'restitue',
        'dateFinEffectif': _dateFinEffectifController.text,
        'commentaireRetour': _commentaireRetourController.text,
        'kilometrageRetour': _kilometrageRetourController.text.isNotEmpty
            ? _kilometrageRetourController.text
            : null,
        'pourcentageEssenceRetour': _pourcentageEssenceRetourController.text,
        'signatureRetour': signatureRetourBase64,
        'photosRetourUrls': allPhotosUrls,
      };

      // N'ajouter les données de facture que si elles existent déjà dans le contrat
      if (widget.data['facture'] != null) {
        updateData['facture'] = factureData;
      }

      // Utiliser la nouvelle méthode avec transactions pour clôturer le contrat
      final bool success = await AccessLocations.clotureContract(widget.contratId, updateData);

      print('📊 Résultat de la clôture: ${success ? "Succès" : "En attente - ajouté à la file"} - contratId: ${widget.contratId}');
      
      // Vérifier le statut de l'opération
      if (success) {
        // Générer le PDF si la clôture a réussi
        await RetourEnvoiePdf.genererEtEnvoyerPdfCloture(
          context: context,
          contratData: widget.data,
          contratId: widget.contratId,
          dateFinEffectif: _dateFinEffectifController.text,
          kilometrageRetour: _kilometrageRetourController.text,
          commentaireRetour: _commentaireRetourController.text,
          pourcentageEssenceRetour: _pourcentageEssenceRetourController.text,
          signatureRetourBase64: signatureRetourBase64,
          dialogueDejaAffiche: true,
        );
        
        // Fermer le dialogue de chargement
        if (mounted && Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        
        // Afficher un message de succès
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Contrat clôturé avec succès. Le contrat est maintenant disponible dans la section 'Contrats restitués'"),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 5),
          ),
        );
        
        // Naviguer vers l'écran principal après une clôture réussie
        if (mounted) {
          Navigator.pushReplacement(
            context, 
            MaterialPageRoute(
              builder: (context) => const NavigationPage(initialTab: 1)
            )
          );
        }
      } else {
        // Fermer le dialogue de chargement
        if (mounted && Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        
        // Afficher un message indiquant que l'opération sera complétée plus tard
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("La connexion est instable. Votre contrat sera clôturé automatiquement dès que la connexion sera rétablie."),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 5),
          ),
        );
        
        // Naviguer vers l'écran principal même en cas d'échec
        if (mounted) {
          Navigator.pushReplacement(
            context, 
            MaterialPageRoute(
              builder: (context) => const NavigationPage(initialTab: 0)
            )
          );
        }
      }
    } catch (e) {
      print('❌ Erreur majeure lors de la clôture du contrat: $e');
      
      // Fermer le dialogue de chargement en cas d'erreur
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      // Afficher un message d'erreur
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Une erreur s'est produite lors de la clôture: $e"),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
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

  // Fonction pour créer un bouton avec dégradé
  Widget _buildGradientButton({
    required Function()? onPressed,
    required Widget child,
    required List<Color> gradientColors,
    double height = 50,
    BorderRadius? borderRadius,
  }) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        borderRadius: borderRadius ?? BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: onPressed == null ? [Colors.grey.shade400, Colors.grey.shade600] : gradientColors,
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: (onPressed == null ? Colors.grey : gradientColors.last).withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: borderRadius ?? BorderRadius.circular(12),
          ),
        ),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Debug pour vérifier le statut du contrat
    print('Dans build - Status du contrat: ${widget.data['status']}');
    print('Type du statut: ${widget.data['status'].runtimeType}');
    print('Comparaison avec "restitue": ${widget.data['status'] == 'restitue'}');
    
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
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.white),
            onPressed: () => SuppContrat.showDeleteConfirmationDialog(
                context, widget.contratId),
          ),
        ],
        backgroundColor: const Color(0xFF08004D),
        elevation: 0,
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
                    _buildGradientButton(
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
                      gradientColors: [
                        Colors.blue,
                        Colors.blueAccent,
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                  Padding(
                    padding: const EdgeInsets.only(
                        bottom: 30.0), 
                    child: Column(
                      children: [
                        const SizedBox(height: 60),
                        if (widget.data['status'] == 'restitue') ...[
                          _buildGradientButton(
                            onPressed: () async {
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
                            gradientColors: [Colors.teal.shade400, Colors.teal.shade700],
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
                          _buildGradientButton(
                            onPressed: () => AffichageFacturePdf.genererEtAfficherFacturePdf(
                              context: context,
                              contratData: widget.data,
                              contratId: widget.contratId,
                            ),
                            gradientColors: [Colors.blue.shade400, Colors.blue.shade700],
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
                          ),const SizedBox(height: 20),
                        ],
                        
                        if (widget.data['status'] == 'réservé') ...[
                        
                          _buildGradientButton(
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
                            gradientColors: [Colors.green.shade400, Colors.green.shade700],
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
                        
                        _buildGradientButton(
                          onPressed: () => AffichageContratPdf.genererEtAfficherContratPdf(
                            context: context,
                            data: widget.data,
                            contratId: widget.contratId,
                            signatureRetourBase64: _signatureRetourBase64,
                          ),
                          gradientColors: [Colors.red.shade400, Colors.red.shade700],
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.picture_as_pdf, color: Colors.white),
                              SizedBox(width: 10),
                              Text(
                                "Afficher le contrat",
                                style: TextStyle(color: Colors.white, fontSize: 18),
                              ),
                            ],
                          ),
                        ),
                       const SizedBox(height: 20),
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