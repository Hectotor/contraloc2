import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_util.dart';
import '../../models/contrat_model.dart';
import 'image_upload_utils.dart';

class ContractDataUtils {
  /// Charge les données d'un contrat à partir de Firestore
  /// 
  /// Cette méthode récupère les données d'un contrat existant, y compris les photos
  /// et les signatures, et les convertit en modèle ContratModel.
  /// 
  /// [contratId] - L'identifiant du contrat à charger
  /// [firestore] - L'instance Firestore à utiliser
  /// [onUpdateControllers] - Callback pour mettre à jour les contrôleurs avec les données du modèle
  /// [onUpdateState] - Callback pour mettre à jour l'état avec les données du modèle
  /// [onAddPhoto] - Callback pour ajouter une photo téléchargée à la liste des photos
  /// 
  /// Retourne un ContratModel si le chargement réussit, sinon null
  static Future<ContratModel?> loadContractData({
    required String contratId,
    required FirebaseFirestore firestore,
    required Function(ContratModel model) onUpdateControllers,
    required Function({
      String? permisRectoUrl,
      String? permisVersoUrl,
      String? signatureAller,
      bool? acceptedConditions,
    }) onUpdateState,
    required Function(File photo) onAddPhoto,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('❌ Aucun utilisateur connecté');
        return null;
      }

      final collaborateurStatus = await AuthUtil.getAuthData();
      final String adminId = collaborateurStatus['isCollaborateur'] 
          ? collaborateurStatus['adminId'] ?? user.uid 
          : user.uid;

      // Récupérer les données du contrat
      final contratDoc = await firestore
          .collection('users')
          .doc(adminId)
          .collection('locations')
          .doc(contratId)
          .get();

      if (contratDoc.exists && contratDoc.data() != null) {
        // Créer un modèle de contrat à partir des données Firestore
        final contractData = contratDoc.data()!;
        final contratModel = ContratModel.fromFirestore(contractData, id: contratId);

        // Mettre à jour les contrôleurs avec les données du modèle
        onUpdateControllers(contratModel);
        
        // Mettre à jour l'état avec les URLs des photos du permis
        onUpdateState(
          permisRectoUrl: contratModel.permisRecto,
          permisVersoUrl: contratModel.permisVerso,
        );

        // Charger la signature si elle existe
        if (contractData['signatureAller'] != null) {
          final signatureAller = contractData['signatureAller'];
          final acceptedConditions = signatureAller.isNotEmpty;
          
          onUpdateState(
            signatureAller: signatureAller,
            acceptedConditions: acceptedConditions,
          );
        }

        // Charger les photos si elles existent
        if (contractData['photos'] != null && contractData['photos'] is List) {
          List<dynamic> photoUrls = contractData['photos'];
          print('Photos trouvées: ${photoUrls.length}');

          // Télécharger les photos depuis les URLs et les ajouter à la liste _photos
          for (String photoUrl in photoUrls) {
            try {
              print('Téléchargement de la photo: $photoUrl');
              final photoFile = await ImageUploadUtils.downloadImageFromUrl(photoUrl);
              if (photoFile != null) {
                onAddPhoto(photoFile);
              }
            } catch (e) {
              print('Erreur lors du traitement de la photo: $e');
            }
          }
        }
        
        // Le chargement des photos du véhicule client est maintenant géré directement dans la page client

        return contratModel;
      } else {
        print('Aucun contrat trouvé avec l\'ID: $contratId');
        return null;
      }
    } catch (e) {
      print('Erreur lors du chargement des données du contrat: $e');
      return null;
    }
  }
}
