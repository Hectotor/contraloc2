import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_util.dart';
import '../photo_upload_popup.dart';
import '../../USERS/contrat_condition.dart';

class ContratValidationUtils {
  /// Valide un contrat de location et gère le processus de sauvegarde
  /// 
  /// Cette méthode vérifie les conditions nécessaires pour valider un contrat,
  /// gère le téléchargement des photos et finalise la sauvegarde du contrat.
  /// 
  /// [context] - Le BuildContext pour afficher des messages et des popups
  /// [typeLocation] - Le type de location (Payante, Gratuite, etc.)
  /// [prixLocation] - Le prix de la location
  /// [acceptedConditions] - Si les conditions ont été acceptées
  /// [nom] - Le nom du client
  /// [prenom] - Le prénom du client
  /// [contratId] - L'ID du contrat existant (null pour un nouveau contrat)
  /// [permisRecto] - Le fichier image du recto du permis
  /// [permisVerso] - Le fichier image du verso du permis
  /// [photos] - La liste des photos du véhicule
  /// [onLoadingStateChanged] - Callback pour mettre à jour l'état de chargement
  /// [onFinalizeSave] - Callback pour finaliser la sauvegarde du contrat
  static Future<void> validerContrat({
    required BuildContext context,
    required String typeLocation,
    required String prixLocation,
    required bool acceptedConditions,
    required String? nom,
    required String? prenom,
    required String? contratId,
    required File? permisRecto,
    required File? permisVerso,
    required List<File> photos,
    List<File> vehiculeClientPhotos = const [],
    required Function(bool isLoading) onLoadingStateChanged,
    required Future<void> Function(
      String contratId,
      List<String> urls,
      String userId,
      String targetId,
      Map<String, dynamic> collaborateurStatus,
      String conditionsText
    ) onFinalizeSave,
  }) async {
    // Vérifier si le prix est configuré pour une location payante
    if (typeLocation == "Payante" && prixLocation.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Veuillez d'abord configurer le prix de location du véhicule dans sa fiche"),
        ),
      );
      return;
    }

    // Récupérer les conditions du contrat depuis Firestore
    final authData = await AuthUtil.getAuthData();
    if (authData.isEmpty) {
      print('❌ Aucun utilisateur connecté');
      return;
    }
    final targetId = authData['adminId'];
    if (targetId == null) {
      print('❌ Aucun adminId trouvé');
      throw Exception('Aucun administrateur trouvé');
    }

    final conditionsDocRef = FirebaseFirestore.instance
        .collection('users')
        .doc(targetId)
        .collection('contrats')
        .doc('userId');
    
    final conditionsDoc = await conditionsDocRef.get(const GetOptions(source: Source.server));
    final conditions = conditionsDoc.data() ?? {'texte': ContratModifier.defaultContract};
    final conditionsText = conditions['texte'] ?? 'Conditions générales de location';

    // Vérifier si les conditions sont acceptées
    if ((nom != null && nom.isNotEmpty && prenom != null && prenom.isNotEmpty) && !acceptedConditions) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Vous devez accepter les conditions de location")),
      );
      return;
    }

    // Mettre à jour l'état de chargement
    onLoadingStateChanged(true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Vous devez être connecté pour créer un contrat")),
        );
        onLoadingStateChanged(false);
        return;
      }

      final collaborateurStatus = await AuthUtil.getAuthData();
      final String userId = collaborateurStatus['userId'] ?? user.uid;
      final String adminId = collaborateurStatus['isCollaborateur'] 
          ? collaborateurStatus['adminId'] ?? user.uid 
          : user.uid;

      // Gestion de l'ID du contrat
      final String finalContratId = contratId ?? FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('locations')
          .doc()
          .id;

      // Préparer les photos à uploader (sans les photos du véhicule client)
      List<File> photosToUpload = [];
      if (permisRecto != null) {
        photosToUpload.add(permisRecto);
      }
      if (permisVerso != null) {
        photosToUpload.add(permisVerso);
      }
      photosToUpload.addAll(photos);
      
      // Noter s'il y a des photos de véhicule client à traiter
      bool hasVehiculeClientPhotos = vehiculeClientPhotos.isNotEmpty;
      if (hasVehiculeClientPhotos) {
        print('${vehiculeClientPhotos.length} photos du véhicule client détectées');
      }

      // Gérer le téléchargement des photos standard
      if (photosToUpload.isNotEmpty) {
        // Afficher le popup de téléchargement des photos standard
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => PhotoUploadPopup(
            photos: photosToUpload,
            contratId: finalContratId,
            onUploadComplete: (List<String> urls) async {
              // Continuer le processus de sauvegarde après l'upload des photos
              // Les photos du véhicule client seront traitées séparément dans _finalizeContractSave
              await onFinalizeSave(finalContratId, urls, userId, adminId, collaborateurStatus, conditionsText);
            },
          ),
        );
      } else {
        // Pas de photos à uploader
        await onFinalizeSave(finalContratId, [], userId, adminId, collaborateurStatus, conditionsText);
      }
    } catch (e) {
      print('Erreur lors de la validation du contrat: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
      onLoadingStateChanged(false);
    }
  }
}
