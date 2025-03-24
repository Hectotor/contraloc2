import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/collaborateur_util.dart';

class AdminLogoWidget extends StatefulWidget {
  final double width;
  final double height;

  const AdminLogoWidget({
    Key? key,
    this.width = 150,
    this.height = 150,
  }) : super(key: key);

  @override
  State<AdminLogoWidget> createState() => _AdminLogoWidgetState();
}

class _AdminLogoWidgetState extends State<AdminLogoWidget> {
  String? _adminLogoUrl;
  bool _isLoading = true;

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
      // Vérifier si l'utilisateur est un collaborateur
      final status = await CollaborateurUtil.checkCollaborateurStatus();
      final isCollaborateur = status['isCollaborateur'] == true;
      
      if (isCollaborateur) {
        final adminId = status['adminId'];
        if (adminId != null) {
          // Essayer de récupérer le logo de l'admin
          final logoUrl = await _getAdminLogoUrl(adminId);
          
          setState(() {
            _adminLogoUrl = logoUrl;
          });
        }
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

    return Container(
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
          : Stack(
              children: [
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      "Logo Admin",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
