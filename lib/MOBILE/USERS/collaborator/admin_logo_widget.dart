import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_util.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../widget/take_picture.dart';

class AdminLogoWidget extends StatefulWidget {
  final double width;
  final double height;
  final bool editable;

  const AdminLogoWidget({
    Key? key,
    this.width = 150,
    this.height = 150,
    this.editable = false,
  }) : super(key: key);

  @override
  State<AdminLogoWidget> createState() => _AdminLogoWidgetState();
}

class _AdminLogoWidgetState extends State<AdminLogoWidget> {
  String? _adminLogoUrl;
  bool _isLoading = true;
  bool _isUploading = false;
  File? _imageFile;
  bool _isCollaborateur = false; // Pour vérifier si l'utilisateur est un collaborateur
  String? _adminId;

  @override
  void initState() {
    super.initState();
    _loadAdminLogo();
  }

  Future<void> _loadAdminLogo() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Récupérer les données d'authentification pour vérifier si l'utilisateur est un collaborateur
      final authData = await AuthUtil.getAuthData();
      _isCollaborateur = authData['isCollaborateur'] ?? false;
      _adminId = authData['adminId'];

      if (_adminId != null) {
        // Essayer de récupérer le logo de l'admin
        final logoUrl = await _getAdminLogoUrl(_adminId!);
        
        setState(() {
          _adminLogoUrl = logoUrl;
        });
      }
    } catch (e) {
      print('Erreur lors du chargement du logo admin: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<String?> _getAdminLogoUrl(String adminId) async {
    try {
      // Essayer d'accéder à la sous-collection authentification
      try {
        final adminAuthDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(adminId)
            .collection('authentification')
            .doc(adminId)
            .get();
        
        if (adminAuthDoc.exists && adminAuthDoc.data()?['logoUrl'] != null) {
          print('Logo admin trouvé dans la sous-collection authentification');
          return adminAuthDoc.data()?['logoUrl'];
        }
      } catch (e) {
        print('Erreur d\'accès à la sous-collection authentification: $e');
        // Si l'accès à Firestore échoue, essayer via Storage
        return await _getAdminLogoFromStorage(adminId);
      }
      
      // Si le logo n'est pas trouvé dans Firestore, essayer via Storage
      return await _getAdminLogoFromStorage(adminId);
    } catch (e) {
      print('Erreur lors de la récupération du logo admin: $e');
      return null;
    }
  }

  Future<String?> _getAdminLogoFromStorage(String adminId) async {
    try {
      // Essayer le chemin standard pour le logo dans Storage
      try {
        final Reference storageRef = FirebaseStorage.instance
            .ref()
            .child('users/$adminId/authentification/$adminId.jpg');
        
        final url = await storageRef.getDownloadURL();
        print('Logo admin trouvé dans Storage');
        return url;
      } catch (e) {
        print('Logo admin non trouvé dans Storage: $e');
        return null;
      }
    } catch (e) {
      print('Erreur lors de la récupération du logo admin depuis Storage: $e');
      return null;
    }
  }

  // Méthode pour télécharger le logo vers Firebase Storage
  Future<void> _uploadLogo() async {
    if (_imageFile == null || _adminId == null) return;

    setState(() {
      _isUploading = true;
    });

    try {
      // Obtenir l'ID de l'utilisateur actuel
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('Utilisateur non connecté');
      }

      // Chemin de stockage pour le logo - l'utilisateur doit télécharger dans son propre répertoire
      // pour respecter les règles de sécurité de Firebase Storage
      final Reference storageRef = FirebaseStorage.instance
          .ref()
          .child('users/${currentUser.uid}/logos/$_adminId.jpg');

      // Télécharger l'image
      await storageRef.putFile(_imageFile!);

      // Obtenir l'URL de téléchargement
      final String downloadUrl = await storageRef.getDownloadURL();

      // Mettre à jour l'URL dans Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_adminId)
          .collection('authentification')
          .doc(_adminId)
          .set({'logoUrl': downloadUrl}, SetOptions(merge: true));

      // Mettre à jour l'affichage
      setState(() {
        _adminLogoUrl = downloadUrl;
        _isUploading = false;
        _imageFile = null; // Réinitialiser le fichier image après le téléchargement
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logo mis à jour avec succès')),
      );
    } catch (e) {
      print('Erreur lors du téléchargement du logo: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors du téléchargement du logo')),
      );
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Vérifier si l'utilisateur peut modifier le logo
    // Un collaborateur ne peut pas modifier le logo de l'admin, même si editable est true
    final bool canEdit = widget.editable && !_isCollaborateur;

    return GestureDetector(
      // Permettre la modification du logo seulement si l'utilisateur peut éditer
      onTap: canEdit ? _showImagePickerOptions : null,
      child: Stack(
        children: [
          Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey),
              image: _adminLogoUrl != null
                  ? DecorationImage(
                      image: NetworkImage(_adminLogoUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: _adminLogoUrl == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(
                        Icons.business,
                        size: 50,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Logo Admin",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  )
                : null,
          ),
          // Afficher un indicateur de chargement pendant le téléchargement
          if (_isUploading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.5),
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
            ),
          // Afficher un label en bas à droite
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.8),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Logo",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  // Afficher une icône d'édition si l'utilisateur peut modifier le logo
                  if (canEdit) ...[  
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.edit,
                      color: Colors.white,
                      size: 12,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Afficher une boite de dialogue pour choisir la source de l'image
  Future<void> _showImagePickerOptions() async {
    final XFile? pickedFile = await showImagePickerDialog(context, 'logo');
    
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
      await _uploadLogo();
    }
  }
}
