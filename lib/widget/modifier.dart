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
            .doc(userData['id']) // Utiliser l'ID du collaborateur, pas son UID
            .get();

        if (!collabDoc.exists) {
          print('⚠️ Document collaborateur non trouvé, tentative avec UID...');
          // Essayer avec l'UID comme fallback
          final collabDocByUid = await FirebaseFirestore.instance
              .collection('users')
              .doc(adminId)
              .collection('authentification')
              .doc(user.uid)
              .get();
              
          if (collabDocByUid.exists) {
            final collabData = collabDocByUid.data();
            if (collabData != null && collabData['permissions'] != null) {
              final permissions = collabData['permissions'];
              print('📋 Permissions collaborateur (via UID):');
              print('   - Lecture: ${permissions['lecture'] == true ? "✅" : "❌"}');
              print('   - Écriture: ${permissions['ecriture'] == true ? "✅" : "❌"}');
              return {
                'adminId': adminId,
                'permissions': permissions,
                'id': userData['id'] // Conserver l'ID pour les opérations futures
              };
            }
          } else {
            print('❌ Document collaborateur non trouvé même avec UID');
            // Créer des permissions par défaut pour éviter les erreurs
            return {
              'adminId': adminId,
              'permissions': {'lecture': true, 'ecriture': false, 'suppression': false},
              'id': userData['id']
            };
          }
        } else {
          final collabData = collabDoc.data();
          if (collabData != null && collabData['permissions'] != null) {
            final permissions = collabData['permissions'];
            print('📋 Permissions collaborateur:');
            print('   - Lecture: ${permissions['lecture'] == true ? "✅" : "❌"}');
            print('   - Écriture: ${permissions['ecriture'] == true ? "✅" : "❌"}');
            return {
              'adminId': adminId,
              'permissions': permissions,
              'id': userData['id']
            };
          } else {
            print('❌ Aucune permission trouvée pour le collaborateur');
            // Créer des permissions par défaut pour éviter les erreurs
            return {
              'adminId': adminId,
              'permissions': {'lecture': true, 'ecriture': false, 'suppression': false},
              'id': userData['id']
            };
          }
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
      print('👤 Mise à jour pour l\'utilisateur: ${collabInfo != null ? 'Admin' : 'Utilisateur'} - $targetUserId');

      // Vérifier si le document existe avant de le mettre à jour
      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(targetUserId)
          .collection('locations')
          .doc(widget.contratId);
          
      final docSnapshot = await docRef.get();
      
      if (!docSnapshot.exists) {
        print('⚠️ Document non trouvé, vérification des autres emplacements possibles...');
        
        // Vérifier si le document existe dans la collection de l'utilisateur actuel
        final userDocRef = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('locations')
            .doc(widget.contratId);
            
        final userDocSnapshot = await userDocRef.get();
        
        if (userDocSnapshot.exists) {
          print('✅ Document trouvé dans la collection de l\'utilisateur actuel');
          // Mettre à jour Firestore avec les informations de retour
          print('💾 Sauvegarde des données dans Firestore (collection utilisateur)...');
          await userDocRef.update({
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
            'status': 'restitue', // Marquer comme restitué
          });
        } else {
          throw Exception("Document non trouvé dans Firestore");
        }
      } else {
        // Mettre à jour Firestore avec les informations de retour
        print('💾 Sauvegarde des données dans Firestore...');
        await docRef.update({
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
          'status': 'restitue', // Marquer comme restitué
        });
      }
      
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
    try {
      // Afficher un dialogue de chargement
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Récupérer les informations de l'utilisateur
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Utilisateur non connecté');
      }

      // Récupérer la signature de retour
      String? signatureRetourBase64;
      try {
        // Récupérer le document du contrat
        final contratDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('locations')
            .doc(widget.contratId)
            .get();

        // Récupérer la signature de retour
        if (contratDoc.exists) {
          Map<String, dynamic> contratData = contratDoc.data() as Map<String, dynamic>;

          // Essayer de récupérer la signature de retour
          if (contratData.containsKey('signature_retour') &&
              contratData['signature_retour'] is String) {
            signatureRetourBase64 = contratData['signature_retour'];
          }
        }
      } catch (e) {
        print('Erreur lors de la récupération de la signature de retour: $e');
      }

      print('📝 Utilisation du compte admin pour les contrats');
      print('📝 Signature de retour récupérée : ${signatureRetourBase64 != null ? 'Présente' : 'Absente'}');

      // Récupérer les données de l'utilisateur
      print('🔍 Récupération des données utilisateur depuis le document principal...');
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      Map<String, dynamic> userData = userDoc.data() ?? {};
      print('👤 Données utilisateur récupérées: ${userData.keys.toList()}');
      print('📋 Nom entreprise dans userData: ${userData['nomEntreprise']}');
      print('📋 Adresse entreprise dans userData: ${userData['adresse']}');
      print('📋 Téléphone entreprise dans userData: ${userData['telephone']}');
      print('📋 SIRET entreprise dans userData: ${userData['siret']}');

      // Déterminer si l'utilisateur est un collaborateur
      final isCollaborateur = userData['role'] == 'collaborateur';
      String targetUserId = user.uid;
      Map<String, dynamic> adminData = {};

      // Si c'est un collaborateur, récupérer les données de l'admin
      if (isCollaborateur && userData['adminId'] != null) {
        targetUserId = userData['adminId'];
        print('👥 Utilisateur collaborateur détecté, récupération des données admin (ID: $targetUserId)');
        
        // Essayer d'abord de récupérer depuis le document principal de l'admin
        final adminDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(targetUserId)
            .get();
        
        adminData = adminDoc.data() ?? {};
        print('👑 Données admin récupérées du document principal: ${adminData.keys.toList()}');
        
        // Si les données d'entreprise ne sont pas dans le document principal, essayer dans la collection 'authentification'
        if (adminData['nomEntreprise'] == null || adminData['adresse'] == null) {
          print('🔍 Données entreprise non trouvées dans le document principal, recherche dans authentification...');
          final adminAuthDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(targetUserId)
              .collection('authentification')
              .doc(targetUserId)
              .get();
              
          final adminAuthData = adminAuthDoc.data() ?? {};
          print('👑 Données admin récupérées de authentification: ${adminAuthData.keys.toList()}');
          
          // Fusionner les données
          if (adminAuthData.isNotEmpty) {
            adminData.addAll({
              'nomEntreprise': adminAuthData['nomEntreprise'],
              'adresse': adminAuthData['adresse'],
              'telephone': adminAuthData['telephone'],
              'siret': adminAuthData['siret'],
              'logoUrl': adminAuthData['logoUrl'],
            });
          }
        }
        
        print('📋 Nom entreprise final dans adminData: ${adminData['nomEntreprise']}');
        print('📋 Adresse entreprise finale dans adminData: ${adminData['adresse']}');
        print('📋 Téléphone entreprise final dans adminData: ${adminData['telephone']}');
        print('📋 SIRET entreprise final dans adminData: ${adminData['siret']}');
      } else {
        print('👤 Utilisateur admin détecté (ID: $targetUserId)');
        
        // Pour un admin, vérifier aussi dans la collection 'authentification' si nécessaire
        if (userData['nomEntreprise'] == null || userData['adresse'] == null) {
          print('🔍 Données entreprise non trouvées dans le document principal de l\'admin, recherche dans authentification...');
          final adminAuthDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('authentification')
              .doc(user.uid)
              .get();
              
          final adminAuthData = adminAuthDoc.data() ?? {};
          print('👑 Données admin récupérées de authentification: ${adminAuthData.keys.toList()}');
          
          // Fusionner les données
          if (adminAuthData.isNotEmpty) {
            userData.addAll({
              'nomEntreprise': adminAuthData['nomEntreprise'],
              'adresse': adminAuthData['adresse'],
              'telephone': adminAuthData['telephone'],
              'siret': adminAuthData['siret'],
              'logoUrl': adminAuthData['logoUrl'],
            });
          }
          
          print('📋 Nom entreprise final dans userData: ${userData['nomEntreprise']}');
          print('📋 Adresse entreprise finale dans userData: ${userData['adresse']}');
          print('📋 Téléphone entreprise final dans userData: ${userData['telephone']}');
          print('📋 SIRET entreprise final dans userData: ${userData['siret']}');
        }
      }
      
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
      print('📄 Préparation des données pour le PDF...');
      final nomEntrepriseValue = isCollaborateur ? adminData['nomEntreprise'] ?? '' : userData['nomEntreprise'] ?? '';
      final adresseEntrepriseValue = isCollaborateur ? adminData['adresse'] ?? '' : userData['adresse'] ?? '';
      final telephoneEntrepriseValue = isCollaborateur ? adminData['telephone'] ?? '' : userData['telephone'] ?? '';
      final siretEntrepriseValue = isCollaborateur ? adminData['siret'] ?? '' : userData['siret'] ?? '';
      
      // Préparer les données du collaborateur si nécessaire
      Map<String, dynamic> collaborateurData = {};
      if (isCollaborateur) {
        // Récupérer l'ID du collaborateur depuis son document principal
        String collaborateurId = userData['id'] ?? '';
        print('📋 ID du collaborateur: $collaborateurId');
        
        if (collaborateurId.isNotEmpty) {
          // Récupérer les données du collaborateur depuis la collection authentification de l'admin en utilisant son ID
          final collabQuery = await FirebaseFirestore.instance
              .collection('users')
              .doc(targetUserId)
              .collection('authentification')
              .where('id', isEqualTo: collaborateurId)
              .limit(1)
              .get();
              
          if (collabQuery.docs.isNotEmpty) {
            final collabData = collabQuery.docs.first.data();
            print('👤 Données collaborateur récupérées avec ID: ${collabData.keys.toList()}');
            print('📋 Nom collaborateur: ${collabData['nom']}');
            print('📋 Prénom collaborateur: ${collabData['prenom']}');
            
            collaborateurData = {
              'nom': collabData['nom'] ?? '',
              'prenom': collabData['prenom'] ?? '',
              'role': 'collaborateur'
            };
          } else {
            print('⚠️ Aucun document trouvé pour le collaborateur avec ID: $collaborateurId');
            
            // Fallback: utiliser les données du contrat
            collaborateurData = {
              'nom': widget.data['nom'] ?? '',
              'prenom': widget.data['prenom'] ?? '',
              'role': 'collaborateur'
            };
          }
        } else {
          print('⚠️ ID du collaborateur non trouvé dans son document principal');
          
          // Fallback: utiliser les données du contrat
          collaborateurData = {
            'nom': widget.data['nom'] ?? '',
            'prenom': widget.data['prenom'] ?? '',
            'role': 'collaborateur'
          };
        }
        
        print('👥 Données collaborateur préparées: ${collaborateurData.toString()}');
      }
      
      print('🏢 Valeurs finales pour le PDF:');
      print('📋 Nom entreprise: $nomEntrepriseValue');
      print('📋 Adresse entreprise: $adresseEntrepriseValue');
      print('📋 Téléphone entreprise: $telephoneEntrepriseValue');
      print('📋 SIRET entreprise: $siretEntrepriseValue');
      
      final pdfPath = await generatePdf(
        {
          ...widget.data,
          'nettoyageInt': _nettoyageIntController.text,
          'nettoyageExt': _nettoyageExtController.text,
          'carburantManquant': _carburantManquantController.text,
          'caution': _cautionController.text,
          'signatureRetour': signatureRetourBase64 ?? '',
          'nom': widget.data['nom'] ?? '',
          'prenom': widget.data['prenom'] ?? '',
          'adresse': widget.data['adresse'] ?? '',
          'telephone': widget.data['telephone'] ?? '',
          'email': widget.data['email'] ?? '',
          'numeroPermis': widget.data['numeroPermis'] ?? '',
          // Ajouter les informations de l'entreprise
          'nomEntreprise': nomEntrepriseValue,
          'adresseEntreprise': adresseEntrepriseValue,
          'telephoneEntreprise': telephoneEntrepriseValue,
          'siretEntreprise': siretEntrepriseValue,
          // Ajouter les informations du collaborateur si nécessaire
          if (isCollaborateur) 'collaborateur': collaborateurData,
        },
        widget.data['dateFinEffectif'] ?? '',
        widget.data['kilometrageRetour'] ?? '',
        widget.data['commentaireRetour'] ?? '',
        [],
        nomEntrepriseValue,
        isCollaborateur ? adminData['logoUrl'] ?? '' : userData['logoUrl'] ?? '',
        adresseEntrepriseValue,
        telephoneEntrepriseValue,
        siretEntrepriseValue,
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