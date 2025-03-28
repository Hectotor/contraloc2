import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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

import 'MODIFICATION DE CONTRAT/supp_contrat.dart';
import 'MODIFICATION DE CONTRAT/info_loc.dart';
import 'MODIFICATION DE CONTRAT/info_loc_retour.dart';
import 'MODIFICATION DE CONTRAT/retour_loc.dart';
import 'navigation.dart'; // Import the NavigationPage
import 'MODIFICATION DE CONTRAT/cloturer_location.dart'; // Import the popup
import 'MODIFICATION DE CONTRAT/retour_envoie_pdf.dart'; // Nouvelle importation
import 'package:ContraLoc/services/collaborateur_util.dart';
import 'package:ContraLoc/services/collaborateur_CA.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart'; // Import FlutterImageCompress
import 'package:path_provider/path_provider.dart'; // Import pour getTemporaryDirectory

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
  bool _isUpdatingContrat = false; // Add a state variable for updating
  final TextEditingController _nettoyageIntController = TextEditingController();
  final TextEditingController _nettoyageExtController = TextEditingController();
  final TextEditingController _carburantManquantController =
      TextEditingController();
  final TextEditingController _cautionController = TextEditingController();

  // Ajouter une variable pour stocker les frais supplémentaires
  Map<String, dynamic> _fraisSupplementaires = {};

  // Méthode pour gérer la mise à jour des frais
  void _handleFraisUpdated(Map<String, dynamic> frais) {
    // Utiliser Future.microtask pour éviter les appels à setState pendant la construction
    Future.microtask(() {
      setState(() {
        _fraisSupplementaires = frais;

        // Mettre à jour les contrôleurs avec les valeurs des frais
        if (frais['nettoyageInt'] != null && frais['nettoyageInt'].toString().isNotEmpty) {
          _nettoyageIntController.text = frais['nettoyageInt'].toString();
        }

        if (frais['nettoyageExt'] != null && frais['nettoyageExt'].toString().isNotEmpty) {
          _nettoyageExtController.text = frais['nettoyageExt'].toString();
        }

        if (frais['carburantManquant'] != null && frais['carburantManquant'].toString().isNotEmpty) {
          _carburantManquantController.text = frais['carburantManquant'].toString();
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
    int startIndex = _photosRetourUrls
        .length; // Commence à partir du nombre de photos existantes

    try {
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

      print("📝 Téléchargement de photos retour par ${status['isCollaborateur'] ? 'collaborateur' : 'admin'}");
      print("📝 userId: $userId, targetId (adminId): $targetId");

      for (var photo in photos) {
        // Compresser l'image avant de la télécharger
        final compressedImage = await FlutterImageCompress.compressWithFile(
          photo.absolute.path,
          minWidth: 800,
          minHeight: 800,
          quality: 70, // Réduire davantage la qualité pour diminuer la taille
        );

        if (compressedImage == null) {
          print("🔴 Erreur: Échec de la compression de l'image");
          continue;
        }

        String fileName =
            'retour_${DateTime.now().millisecondsSinceEpoch}_${startIndex + urls.length}.jpg';

        // Stocker dans le dossier de l'administrateur si c'est un collaborateur
        final String storagePath = 'users/${targetId}/locations/${widget.contratId}/photos_retour/$fileName';


        Reference ref = FirebaseStorage.instance.ref().child(storagePath);

        // Créer un fichier temporaire pour l'image compressée
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/$fileName');
        await tempFile.writeAsBytes(compressedImage);

        // Téléchargement sans métadonnées
        await ref.putFile(tempFile);

        String downloadUrl = await ref.getDownloadURL();
        urls.add(downloadUrl);
      }
      return urls;
    } catch (e) {
      print('🔴 Erreur lors du téléchargement des photos : $e');
      if (e.toString().contains('unauthorized')) {
        print('🔐 Problème d\'autorisation: Vérifiez les règles de sécurité Firebase Storage');
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

    // Mettre à jour l'état pour afficher l'indicateur de chargement
    setState(() {
      _isUpdatingContrat = true;
    });

    // Afficher le dialogue de chargement
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(child: CircularProgressIndicator());
      },
    );

    try {
      // Récupérer les informations du statut du collaborateur
      final status = await CollaborateurUtil.checkCollaborateurStatus();
      final userId = status['userId'];
      final isCollaborateur = status['isCollaborateur'] == true;
      final adminId = status['adminId'];

      print('🔄 Mise à jour du contrat - userId: $userId, isCollaborateur: $isCollaborateur, adminId: $adminId');

      // Conserver les URLs existantes
      List<String> allPhotosUrls = List<String>.from(_photosRetourUrls);

      // Ajouter les nouvelles photos seulement s'il y en a
      if (_photosRetour.isNotEmpty) {
        List<String> newUrls = await _uploadPhotos(_photosRetour);
        allPhotosUrls.addAll(newUrls);
      }

      // Convertir la signature de retour en base64
      String? signatureRetourBase64;
      if (_signatureRetourController.isNotEmpty) {
        final signatureBytes = await _signatureRetourController.toPngBytes();
        signatureRetourBase64 = base64Encode(signatureBytes!);
      }

      // Préparer les données des frais supplémentaires finaux
      Map<String, dynamic> fraisFinaux = {..._fraisSupplementaires};
      
      // Supprimer le marqueur temporaire
      if (fraisFinaux.containsKey('temporaire')) {
        fraisFinaux.remove('temporaire');
      }
      
      print('💰 Sauvegarde des frais définitifs: $fraisFinaux');

      // Préparer les données de mise à jour pour la collection 'locations'
      // IMPORTANT: On n'inclut pas les détails financiers ici, ils iront dans 'chiffre_affaire'
      final updateData = {
        'status': 'restitue',
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
        // On enregistre uniquement un indicateur que le contrat a été clôturé avec des frais
        'contratCloture': true,
        'dateClotureContrat': DateTime.now().toIso8601String(),
      };

      // Mettre à jour Firestore avec les informations de retour
      if (isCollaborateur && adminId != null) {
        // Si c'est un collaborateur, utiliser la collection de l'admin
        try {
          print('🔄 Début de la mise à jour du contrat par le collaborateur');
          print('👤 ID Collaborateur: ${FirebaseAuth.instance.currentUser?.uid}');
          print('👥 ID Admin: $adminId');
          print('📄 ID Contrat: ${widget.contratId}');
          
          // Vérifier si le collaborateur a la permission d'écriture dans la collection de l'admin
          print('🔑 Vérification des permissions d\'écriture');
          
          print('📝 Tentative de mise à jour du document: locations/${widget.contratId}');
          try {
            await CollaborateurUtil.updateDocument(
              collection: 'locations',
              docId: widget.contratId,
              data: updateData,
              useAdminId: true,
            );
            print('✅ Contrat mis à jour dans la collection de l\'admin: $adminId');
          } catch (updateError) {
            print('❌ Erreur lors de la mise à jour du document: $updateError');
            throw updateError;
          }
          
          // Ajouter les informations dans la collection 'chiffre_affaire'
          try {
            // Utiliser CollaborateurCA pour récupérer les informations du véhicule
            Map<String, dynamic> vehiculeInfoDetails = await CollaborateurCA.getVehiculeInfo(
              immatriculation: widget.data['immatriculation'] ?? '',
            );
            
            // Calculer le montant total
            double montantTotal = CollaborateurCA.calculerMontantTotal(_fraisSupplementaires);
            
            // Préparer les données pour la collection chiffre_affaire
            Map<String, dynamic> chiffreData = {
              'marque': vehiculeInfoDetails['marque'] ?? '',
              'modele': vehiculeInfoDetails['modele'] ?? '',
              'immatriculation': vehiculeInfoDetails['immatriculation'] ?? '',
              'photoVehiculeUrl': vehiculeInfoDetails['photoVehiculeUrl'] ?? '',
              'prixLocation': _fraisSupplementaires['includeCoutTotal'] == true ? (_fraisSupplementaires['prixLocation'] ?? 0.0) : 0.0,
              'coutKmSupplementaires': _fraisSupplementaires['includeCoutKmSupp'] == true ? (_fraisSupplementaires['coutKmSupplementaires'] ?? 0.0) : 0.0,
              'fraisNettoyageInterieur': _fraisSupplementaires['includeNettoyageInterieur'] == true ? (_fraisSupplementaires['fraisNettoyageInterieur'] ?? 0.0) : 0.0,
              'fraisNettoyageExterieur': _fraisSupplementaires['includeNettoyageExterieur'] == true ? (_fraisSupplementaires['fraisNettoyageExterieur'] ?? 0.0) : 0.0,
              'fraisCarburantManquant': _fraisSupplementaires['includeCarburantManquant'] == true ? (_fraisSupplementaires['fraisCarburantManquant'] ?? 0.0) : 0.0,
              'fraisRayuresDommages': _fraisSupplementaires['includeRayuresDommages'] == true ? (_fraisSupplementaires['fraisRayuresDommages'] ?? 0.0) : 0.0,
              'caution': _fraisSupplementaires['includeCaution'] == true ? (_fraisSupplementaires['caution'] ?? 0.0) : 0.0,
              'montantTotal': montantTotal,
              'dateCloture': DateTime.now().toIso8601String(),
              'contratId': widget.contratId,
            };
            
            print('💰 Enregistrement des données financières dans chiffre_affaire');
            print('📄 Données à enregistrer: ${chiffreData.keys.join(', ')}');
            print('📊 Statut des frais: ${_fraisSupplementaires.entries.where((e) => e.key.startsWith('include')).map((e) => '${e.key}: ${e.value}').join(', ')}');
            
            // ENREGISTREMENT SIMPLIFIÉ DANS CHIFFRE_AFFAIRE
            // Utiliser directement la méthode CollaborateurCA pour gérer l'enregistrement
            final success = await CollaborateurCA.ajouterOuMettreAJourChiffreAffaire(
              contratId: widget.contratId,
              data: chiffreData,
            );
            
            if (success) {
              print('✅ Données financières enregistrées avec succès dans chiffre_affaire');
            } else {
              print('⚠️ Échec de l\'enregistrement dans chiffre_affaire');
              throw Exception('Échec de l\'enregistrement des données financières');
            }
          } catch (e) {
            print('❌ Erreur lors de l\'ajout dans chiffre_affaire: $e');
            throw e;
          }
        } catch (vehiculeError) {
          print('❌ Erreur lors de la récupération des informations du véhicule: $vehiculeError');
        }
      } else {
        // Si c'est un admin, utiliser la même logique que pour les collaborateurs
        try {
          print('🔄 Début de la mise à jour du contrat par l\'administrateur');
          print('👤 ID Administrateur: ${FirebaseAuth.instance.currentUser?.uid}');
          print('📄 ID Contrat: ${widget.contratId}');
          
          // Vérifier si l'administrateur a la permission d'écriture dans sa propre collection
          print('🔑 Vérification des permissions d\'écriture');
          
          print('📝 Tentative de mise à jour du document: locations/${widget.contratId}');
          try {
            await CollaborateurUtil.updateDocument(
              collection: 'locations',
              docId: widget.contratId,
              data: updateData,
              useAdminId: false,
            );
            print('✅ Contrat mis à jour dans la collection de l\'administrateur');
          } catch (updateError) {
            print('❌ Erreur lors de la mise à jour du document: $updateError');
            throw updateError;
          }
          
          // Ajouter les informations dans la collection 'chiffre_affaire'
          try {
            // Utiliser CollaborateurCA pour récupérer les informations du véhicule
            Map<String, dynamic> vehiculeInfoDetails = await CollaborateurCA.getVehiculeInfo(
              immatriculation: widget.data['immatriculation'] ?? '',
            );
            
            // Calculer le montant total
            double montantTotal = CollaborateurCA.calculerMontantTotal(_fraisSupplementaires);
            
            // Préparer les données pour la collection chiffre_affaire
            Map<String, dynamic> chiffreData = {
              'marque': vehiculeInfoDetails['marque'] ?? '',
              'modele': vehiculeInfoDetails['modele'] ?? '',
              'immatriculation': vehiculeInfoDetails['immatriculation'] ?? '',
              'photoVehiculeUrl': vehiculeInfoDetails['photoVehiculeUrl'] ?? '',
              'prixLocation': _fraisSupplementaires['includeCoutTotal'] == true ? (_fraisSupplementaires['prixLocation'] ?? 0.0) : 0.0,
              'coutKmSupplementaires': _fraisSupplementaires['includeCoutKmSupp'] == true ? (_fraisSupplementaires['coutKmSupplementaires'] ?? 0.0) : 0.0,
              'fraisNettoyageInterieur': _fraisSupplementaires['includeNettoyageInterieur'] == true ? (_fraisSupplementaires['fraisNettoyageInterieur'] ?? 0.0) : 0.0,
              'fraisNettoyageExterieur': _fraisSupplementaires['includeNettoyageExterieur'] == true ? (_fraisSupplementaires['fraisNettoyageExterieur'] ?? 0.0) : 0.0,
              'fraisCarburantManquant': _fraisSupplementaires['includeCarburantManquant'] == true ? (_fraisSupplementaires['fraisCarburantManquant'] ?? 0.0) : 0.0,
              'fraisRayuresDommages': _fraisSupplementaires['includeRayuresDommages'] == true ? (_fraisSupplementaires['fraisRayuresDommages'] ?? 0.0) : 0.0,
              'caution': _fraisSupplementaires['includeCaution'] == true ? (_fraisSupplementaires['caution'] ?? 0.0) : 0.0,
              'montantTotal': montantTotal,
              'dateCloture': DateTime.now().toIso8601String(),
              'contratId': widget.contratId,
            };
            
            print('💰 Enregistrement des données financières dans chiffre_affaire');
            print('📄 Données à enregistrer: ${chiffreData.keys.join(', ')}');
            print('📊 Statut des frais: ${_fraisSupplementaires.entries.where((e) => e.key.startsWith('include')).map((e) => '${e.key}: ${e.value}').join(', ')}');
            
            // ENREGISTREMENT SIMPLIFIÉ DANS CHIFFRE_AFFAIRE
            // Utiliser directement la méthode CollaborateurCA pour gérer l'enregistrement
            final success = await CollaborateurCA.ajouterOuMettreAJourChiffreAffaire(
              contratId: widget.contratId,
              data: chiffreData,
            );
            
            if (success) {
              print('✅ Données financières enregistrées avec succès dans chiffre_affaire');
            } else {
              print('⚠️ Échec de l\'enregistrement dans chiffre_affaire');
              throw Exception('Échec de l\'enregistrement des données financières');
            }
          } catch (e) {
            print('❌ Erreur lors de l\'ajout dans chiffre_affaire: $e');
            throw e;
          }
        } catch (e) {
          print('❌ Erreur lors de la mise à jour du contrat: $e');
        }
      }

      // Fermer le dialogue de chargement
      if (context.mounted) {
        Navigator.pop(context);
      }

      // Générer et envoyer le PDF
      await RetourEnvoiePdf.genererEtEnvoyerPdfCloture(
        context: context,
        contratData: widget.data,
        contratId: widget.contratId,
        dateFinEffectif: _dateFinEffectifController.text,
        kilometrageRetour: _kilometrageRetourController.text,
        commentaireRetour: _commentaireRetourController.text,
        photosRetour: _photosRetour,
      );

      // Naviguer vers la page principale
      if (context.mounted) {
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
    } finally {
      // Réinitialiser l'état du bouton
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
    // Afficher le widget de chargement
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
      // Vérifier d'abord si le PDF existe déjà localement
      final appDir = await getApplicationDocumentsDirectory();
      final localPdfPath = '${appDir.path}/contrat_${widget.contratId}.pdf';
      final localPdfFile = File(localPdfPath);
      
      if (await localPdfFile.exists()) {
        print('📄 PDF trouvé en cache local, ouverture directe');
        
        // Fermer le dialogue de chargement si nécessaire
        if (dialogShown && context.mounted) {
          Navigator.pop(context);
          dialogShown = false;
        }
        
        // Ouvrir le PDF depuis le cache local
        await OpenFilex.open(localPdfPath);
        return;
      }
      
      print('📄 PDF non trouvé en cache local, génération sans appels Firestore...');

      // Récupérer les informations nécessaires pour le PDF depuis les données déjà en mémoire
      final status = await CollaborateurUtil.checkCollaborateurStatus();
      final userId = status['userId'];
      final isCollaborateur = status['isCollaborateur'] == true;
      
      print('🔍 Génération PDF - userId: $userId, isCollaborateur: $isCollaborateur');

      // Utiliser les données déjà en mémoire (widget.data) au lieu de refaire des appels à Firestore
      // Récupérer les conditions du contrat (utiliser les conditions par défaut si non disponibles)
      String conditions = widget.data['conditions'] ?? ContratModifier.defaultContract;
      
      // Récupérer la signature de retour depuis les données en mémoire
      String? signatureRetourBase64 = widget.data['signature_retour'] ?? widget.data['signatureRetour'];
      
      // Log de débogage
      print('📝 Signature de retour récupérée : ${signatureRetourBase64 != null ? 'Présente' : 'Absente'}');
      print('📄 Conditions personnalisées récupérées : ${conditions != ContratModifier.defaultContract ? 'Personnalisées' : 'Par défaut'}');

      // Récupérer les données utilisateur depuis les données en mémoire
      final userData = await CollaborateurUtil.getAuthData();

      // Générer le PDF en utilisant uniquement les données en mémoire
      final pdfPath = await generatePdf(
        {
          ...widget.data,
          'nettoyageInt': _nettoyageIntController.text,
          'nettoyageExt': _nettoyageExtController.text,
          'carburantManquant': _carburantManquantController.text,
          'caution': _cautionController.text,
          'signatureRetour': signatureRetourBase64 ?? '',
          'conditions': conditions,
        },
        widget.data['dateFinEffectif'] ?? '',
        widget.data['kilometrageRetour'] ?? '',
        widget.data['commentaireRetour'] ?? '',
        [],
        // Utiliser les données du contrat si disponibles, sinon les données de l'utilisateur
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
        condition: conditions,
        signatureBase64: '',
        signatureRetourBase64: signatureRetourBase64,
      );

      // Sauvegarder une copie du PDF dans le stockage local pour éviter de le régénérer
      try {
        await File(pdfPath).copy(localPdfPath);
        print('📄 PDF sauvegardé en cache local: $localPdfPath');
      } catch (e) {
        print('⚠️ Erreur lors de la sauvegarde du PDF en cache local: $e');
        // Continuer même si la sauvegarde échoue
      }

      // Fermer le dialogue de chargement si nécessaire
      if (dialogShown && context.mounted) {
        Navigator.pop(context);
        dialogShown = false;
      }

      // Ouvrir le PDF
      await OpenFilex.open(pdfPath);

    } catch (e) {
      print('❌ Erreur lors de la génération du PDF : $e');
      
      // Fermer le dialogue de chargement en cas d'erreur
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
                  const SizedBox(height: 50),
                  if (widget.data['status'] == 'en_cours') ...[
                    RetourLoc(
                      dateFinEffectifController: _dateFinEffectifController,
                      kilometrageRetourController: _kilometrageRetourController,
                      data: widget.data,
                      selectDateTime: _selectDateTime,
                      dateDebut: _parseDateWithFallback(widget.data['dateDebut']),
                      onFraisUpdated: _handleFraisUpdated,
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
        ],
      ),
    );
  }
}