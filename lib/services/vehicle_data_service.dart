import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class VehicleDataService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Récupère les données du véhicule à partir de son immatriculation
  Future<Map<String, dynamic>?> getVehicleData(String immatriculation) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      String adminId = user.uid;
      
      // Vérifier si l'utilisateur est un collaborateur
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data();
      
      if (userData != null && userData['role'] == 'collaborateur' && userData['adminId'] != null) {
        adminId = userData['adminId'];
        print('Utilisateur collaborateur détecté, utilisation de l\'adminId: $adminId');
      }

      // Récupérer les données du véhicule
      final vehiculeDoc = await _firestore
          .collection('users')
          .doc(adminId)
          .collection('vehicules')
          .where('immatriculation', isEqualTo: immatriculation)
          .get();

      if (vehiculeDoc.docs.isNotEmpty) {
        return vehiculeDoc.docs.first.data();
      }
      
      print('Aucun véhicule trouvé avec l\'immatriculation: $immatriculation');
      return null;
    } catch (e) {
      print('Erreur lors de la récupération des données du véhicule: $e');
      return null;
    }
  }

  /// Remplit les données du véhicule dans un modèle de contrat
  Future<void> fillVehicleDataInContract(
      Map<String, dynamic> contractData,
      String immatriculation,
      Map<String, TextEditingController>? controllers) async {
    try {
      final vehicleData = await getVehicleData(immatriculation);
      if (vehicleData != null) {
        // Remplir les champs vides uniquement
        if (contractData['photoVehiculeUrl'] == null) {
          contractData['photoVehiculeUrl'] = vehicleData['photoVehiculeUrl'];
        }
        
        if (contractData['prixLocation'] == null) {
          contractData['prixLocation'] = vehicleData['prixLocation'] ?? '';
        }
        if (contractData['nettoyageInt'] == null) {
          contractData['nettoyageInt'] = vehicleData['nettoyageInt'] ?? '';
        }
        if (contractData['nettoyageExt'] == null) {
          contractData['nettoyageExt'] = vehicleData['nettoyageExt'] ?? '';
        }
        if (contractData['carburantManquant'] == null) {
          contractData['carburantManquant'] = vehicleData['carburantManquant'] ?? '';
        }
        if (contractData['kilometrageSupp'] == null) {
          contractData['kilometrageSupp'] = vehicleData['kilometrageSupp'] ?? '';
        }
        if (contractData['vin'] == null) {
          contractData['vin'] = vehicleData['vin'] ?? '';
        }
        if (contractData['assuranceNom'] == null) {
          contractData['assuranceNom'] = vehicleData['assuranceNom'] ?? '';
        }
        if (contractData['assuranceNumero'] == null) {
          contractData['assuranceNumero'] = vehicleData['assuranceNumero'] ?? '';
        }
        if (contractData['franchise'] == null) {
          contractData['franchise'] = vehicleData['franchise'] ?? '';
        }
        if (contractData['rayures'] == null) {
          contractData['rayures'] = vehicleData['rayures'] ?? '';
        }
        if (contractData['typeCarburant'] == null) {
          contractData['typeCarburant'] = vehicleData['typeCarburant'] ?? '';
        }
        if (contractData['locationCasque'] == null) {
          contractData['locationCasque'] = vehicleData['locationCasque'] ?? '';
        }
        if (contractData['boiteVitesses'] == null) {
          contractData['boiteVitesses'] = vehicleData['boiteVitesses'] ?? '';
        }
        if (contractData['caution'] == null) {
          contractData['caution'] = vehicleData['caution'] ?? '';
        }

        // Mettre à jour les contrôleurs si fournis
        if (controllers != null) {
          for (final entry in controllers.entries) {
            entry.value.text = contractData[entry.key] as String;
          }
        }
      }
    } catch (e) {
      print('Erreur lors du remplissage des données du véhicule: $e');
    }
  }
}
