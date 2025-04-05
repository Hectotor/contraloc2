import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';

class ContratModel {
  // Identifiants
  final String? contratId;
  final String? userId;
  final String? adminId;
  final String? createdBy;
  final bool isCollaborateur;
  
  // Informations client
  final String? nom;
  final String? prenom;
  final String? adresse;
  final String? telephone;
  final String? email;
  final String? numeroPermis;
  final String? immatriculationVehiculeClient;
  final String? kilometrageVehiculeClient;
  
  // Informations permis
  final String? permisRectoUrl;
  final String? permisVersoUrl;
  final File? permisRectoFile;
  final File? permisVersoFile;
  
  // Informations véhicule
  final String? marque;
  final String? modele;
  final String? immatriculation;
  final String? photoVehiculeUrl;
  final String? vin;
  final String? typeCarburant;
  final String? boiteVitesses;
  
  // Informations contrat
  final String? dateDebut;
  final String? dateFinTheorique;
  final String? kilometrageDepart;
  final String? typeLocation;
  final int pourcentageEssence;
  final String? commentaire;
  final List<String>? photosUrls;
  final List<File>? photosFiles;
  final String? status;
  final Timestamp? dateReservation;
  final Timestamp? dateCreation;
  final String? signatureAller;
  
  // Informations assurance
  final String? assuranceNom;
  final String? assuranceNumero;
  final String? franchise;
  
  // Informations financières
  final String? prixLocation;
  final String? accompte;
  final String? caution;
  final String? nettoyageInt;
  final String? nettoyageExt;
  final String? carburantManquant;
  final String? kilometrageAutorise;
  final String? kilometrageSupp;
  final String? prixRayures;
  
  // Informations entreprise
  final String? logoUrl;
  final String? nomEntreprise;
  final String? adresseEntreprise;
  final String? telephoneEntreprise;
  final String? siretEntreprise;
  
  // Informations collaborateur
  final String? nomCollaborateur;
  final String? prenomCollaborateur;
  
  // Conditions
  final String? conditions;
  
  // Informations retour
  final String? dateRetour;
  final String? kilometrageRetour;
  final int? pourcentageEssenceRetour;
  final String? signatureRetour;
  
  // Informations facture
  final bool? factureGeneree;
  final String? factureId;
  final Timestamp? dateFacture;
  final String? factureTotalFrais;
  
  ContratModel({
    this.contratId,
    this.userId,
    this.adminId,
    this.createdBy,
    this.isCollaborateur = false,
    this.nom,
    this.prenom,
    this.adresse,
    this.telephone,
    this.email,
    this.numeroPermis,
    this.immatriculationVehiculeClient,
    this.kilometrageVehiculeClient,
    this.permisRectoUrl,
    this.permisVersoUrl,
    this.permisRectoFile,
    this.permisVersoFile,
    this.marque,
    this.modele,
    this.immatriculation,
    this.photoVehiculeUrl,
    this.vin,
    this.typeCarburant,
    this.boiteVitesses,
    this.dateDebut,
    this.dateFinTheorique,
    this.kilometrageDepart,
    this.typeLocation,
    this.pourcentageEssence = 50,
    this.commentaire,
    this.photosUrls,
    this.photosFiles,
    this.status,
    this.dateReservation,
    this.dateCreation,
    this.signatureAller,
    this.assuranceNom,
    this.assuranceNumero,
    this.franchise,
    this.prixLocation,
    this.accompte,
    this.caution,
    this.nettoyageInt,
    this.nettoyageExt,
    this.carburantManquant,
    this.kilometrageAutorise,
    this.kilometrageSupp,
    this.prixRayures,
    this.logoUrl,
    this.nomEntreprise,
    this.adresseEntreprise,
    this.telephoneEntreprise,
    this.siretEntreprise,
    this.nomCollaborateur,
    this.prenomCollaborateur,
    this.conditions,
    this.dateRetour,
    this.kilometrageRetour,
    this.pourcentageEssenceRetour,
    this.signatureRetour,
    this.factureGeneree,
    this.factureId,
    this.dateFacture,
    this.factureTotalFrais,
  });
  
  // Créer une instance à partir des données Firestore
  factory ContratModel.fromFirestore(Map<String, dynamic> data, {String? id}) {
    return ContratModel(
      contratId: id ?? data['contratId'],
      userId: data['userId'],
      adminId: data['adminId'],
      createdBy: data['createdBy'],
      isCollaborateur: data['isCollaborateur'] ?? false,
      nom: data['nom'],
      prenom: data['prenom'],
      adresse: data['adresse'],
      telephone: data['telephone'],
      email: data['email'],
      numeroPermis: data['numeroPermis'],
      immatriculationVehiculeClient: data['immatriculationVehiculeClient'],
      kilometrageVehiculeClient: data['kilometrageVehiculeClient'],
      permisRectoUrl: data['permisRecto'],
      permisVersoUrl: data['permisVerso'],
      marque: data['marque'],
      modele: data['modele'],
      immatriculation: data['immatriculation'],
      photoVehiculeUrl: data['photoVehiculeUrl'],
      vin: data['vin'],
      typeCarburant: data['typeCarburant'],
      boiteVitesses: data['boiteVitesses'],
      dateDebut: data['dateDebut'],
      dateFinTheorique: data['dateFinTheorique'],
      kilometrageDepart: data['kilometrageDepart'],
      typeLocation: data['typeLocation'],
      pourcentageEssence: data['pourcentageEssence'] ?? 50,
      commentaire: data['commentaire'],
      photosUrls: List<String>.from(data['photos'] ?? []),
      status: data['status'],
      dateReservation: data['dateReservation'],
      dateCreation: data['dateCreation'],
      signatureAller: data['signature_aller'],
      assuranceNom: data['assuranceNom'],
      assuranceNumero: data['assuranceNumero'],
      franchise: data['franchise'],
      prixLocation: data['prixLocation'],
      accompte: data['accompte'],
      caution: data['caution'],
      nettoyageInt: data['nettoyageInt'],
      nettoyageExt: data['nettoyageExt'],
      carburantManquant: data['carburantManquant'],
      kilometrageAutorise: data['kilometrageAutorise'],
      kilometrageSupp: data['kilometrageSupp'],
      prixRayures: data['prixRayures'],
      logoUrl: data['logoUrl'],
      nomEntreprise: data['nomEntreprise'],
      adresseEntreprise: data['adresseEntreprise'],
      telephoneEntreprise: data['telephoneEntreprise'],
      siretEntreprise: data['siretEntreprise'],
      nomCollaborateur: data['nomCollaborateur'],
      prenomCollaborateur: data['prenomCollaborateur'],
      conditions: data['conditions'],
      dateRetour: data['dateRetour'],
      kilometrageRetour: data['kilometrageRetour'],
      pourcentageEssenceRetour: data['pourcentageEssenceRetour'],
      signatureRetour: data['signature_retour'],
      factureGeneree: data['factureGeneree'],
      factureId: data['factureId'],
      dateFacture: data['dateFacture'],
      factureTotalFrais: data['factureTotalFrais'],
    );
  }
  
  // Convertir l'instance en Map pour Firestore
  Map<String, dynamic> toFirestore() {
    final Map<String, dynamic> data = {
      'userId': userId,
      'adminId': adminId,
      'createdBy': createdBy,
      'isCollaborateur': isCollaborateur,
      'nom': nom ?? '',
      'prenom': prenom ?? '',
      'adresse': adresse ?? '',
      'telephone': telephone ?? '',
      'email': email ?? '',
      'numeroPermis': numeroPermis ?? '',
      'immatriculationVehiculeClient': immatriculationVehiculeClient ?? '',
      'kilometrageVehiculeClient': kilometrageVehiculeClient ?? '',
      'permisRecto': permisRectoUrl,
      'permisVerso': permisVersoUrl,
      'marque': marque ?? '',
      'modele': modele ?? '',
      'immatriculation': immatriculation ?? '',
      'photoVehiculeUrl': photoVehiculeUrl,
      'vin': vin ?? '',
      'typeCarburant': typeCarburant ?? '',
      'boiteVitesses': boiteVitesses ?? '',
      'dateDebut': dateDebut ?? '',
      'dateFinTheorique': dateFinTheorique ?? '',
      'kilometrageDepart': kilometrageDepart ?? '',
      'typeLocation': typeLocation ?? 'Gratuite',
      'pourcentageEssence': pourcentageEssence,
      'commentaire': commentaire ?? '',
      'photos': photosUrls,
      'signature_aller': signatureAller,
      'assuranceNom': assuranceNom ?? '',
      'assuranceNumero': assuranceNumero ?? '',
      'franchise': franchise ?? '',
      'prixLocation': prixLocation ?? '',
      'accompte': accompte ?? '',
      'caution': caution ?? '',
      'nettoyageInt': nettoyageInt ?? '',
      'nettoyageExt': nettoyageExt ?? '',
      'carburantManquant': carburantManquant ?? '',
      'kilometrageAutorise': kilometrageAutorise ?? '',
      'kilometrageSupp': kilometrageSupp ?? '',
      'prixRayures': prixRayures ?? '',
      'logoUrl': logoUrl,
      'nomEntreprise': nomEntreprise,
      'adresseEntreprise': adresseEntreprise,
      'telephoneEntreprise': telephoneEntreprise,
      'siretEntreprise': siretEntreprise,
      'nomCollaborateur': nomCollaborateur,
      'prenomCollaborateur': prenomCollaborateur,
      'dateCreation': dateCreation,
      'status': status ?? 'en_cours',
      'conditions': conditions ?? '',
      'contratId': contratId,
    };
    
    // Ajouter les champs optionnels seulement s'ils existent
    if (status != null) data['status'] = status;
    if (dateReservation != null) data['dateReservation'] = dateReservation;
    if (dateRetour != null) data['dateRetour'] = dateRetour;
    if (kilometrageRetour != null) data['kilometrageRetour'] = kilometrageRetour;
    if (pourcentageEssenceRetour != null) data['pourcentageEssenceRetour'] = pourcentageEssenceRetour;
    if (signatureRetour != null) data['signature_retour'] = signatureRetour;
    if (factureGeneree != null) data['factureGeneree'] = factureGeneree;
    if (factureId != null) data['factureId'] = factureId;
    if (dateFacture != null) data['dateFacture'] = dateFacture;
    if (factureTotalFrais != null) data['factureTotalFrais'] = factureTotalFrais;
    
    return data;
  }
  
  // Créer une copie de l'instance avec des modifications
  ContratModel copyWith({
    String? contratId,
    String? userId,
    String? adminId,
    String? createdBy,
    bool? isCollaborateur,
    String? nom,
    String? prenom,
    String? adresse,
    String? telephone,
    String? email,
    String? numeroPermis,
    String? immatriculationVehiculeClient,
    String? kilometrageVehiculeClient,
    String? permisRectoUrl,
    String? permisVersoUrl,
    File? permisRectoFile,
    File? permisVersoFile,
    String? marque,
    String? modele,
    String? immatriculation,
    String? photoVehiculeUrl,
    String? vin,
    String? typeCarburant,
    String? boiteVitesses,
    String? dateDebut,
    String? dateFinTheorique,
    String? kilometrageDepart,
    String? typeLocation,
    int? pourcentageEssence,
    String? commentaire,
    List<String>? photosUrls,
    List<File>? photosFiles,
    String? status,
    Timestamp? dateReservation,
    Timestamp? dateCreation,
    String? signatureAller,
    String? assuranceNom,
    String? assuranceNumero,
    String? franchise,
    String? prixLocation,
    String? accompte,
    String? caution,
    String? nettoyageInt,
    String? nettoyageExt,
    String? carburantManquant,
    String? kilometrageAutorise,
    String? kilometrageSupp,
    String? prixRayures,
    String? logoUrl,
    String? nomEntreprise,
    String? adresseEntreprise,
    String? telephoneEntreprise,
    String? siretEntreprise,
    String? nomCollaborateur,
    String? prenomCollaborateur,
    String? conditions,
    String? dateRetour,
    String? kilometrageRetour,
    int? pourcentageEssenceRetour,
    String? signatureRetour,
    bool? factureGeneree,
    String? factureId,
    Timestamp? dateFacture,
    String? factureTotalFrais,
  }) {
    return ContratModel(
      contratId: contratId ?? this.contratId,
      userId: userId ?? this.userId,
      adminId: adminId ?? this.adminId,
      createdBy: createdBy ?? this.createdBy,
      isCollaborateur: isCollaborateur ?? this.isCollaborateur,
      nom: nom ?? this.nom,
      prenom: prenom ?? this.prenom,
      adresse: adresse ?? this.adresse,
      telephone: telephone ?? this.telephone,
      email: email ?? this.email,
      numeroPermis: numeroPermis ?? this.numeroPermis,
      immatriculationVehiculeClient: immatriculationVehiculeClient ?? this.immatriculationVehiculeClient,
      kilometrageVehiculeClient: kilometrageVehiculeClient ?? this.kilometrageVehiculeClient,
      permisRectoUrl: permisRectoUrl ?? this.permisRectoUrl,
      permisVersoUrl: permisVersoUrl ?? this.permisVersoUrl,
      permisRectoFile: permisRectoFile ?? this.permisRectoFile,
      permisVersoFile: permisVersoFile ?? this.permisVersoFile,
      marque: marque ?? this.marque,
      modele: modele ?? this.modele,
      immatriculation: immatriculation ?? this.immatriculation,
      photoVehiculeUrl: photoVehiculeUrl ?? this.photoVehiculeUrl,
      vin: vin ?? this.vin,
      typeCarburant: typeCarburant ?? this.typeCarburant,
      boiteVitesses: boiteVitesses ?? this.boiteVitesses,
      dateDebut: dateDebut ?? this.dateDebut,
      dateFinTheorique: dateFinTheorique ?? this.dateFinTheorique,
      kilometrageDepart: kilometrageDepart ?? this.kilometrageDepart,
      typeLocation: typeLocation ?? this.typeLocation,
      pourcentageEssence: pourcentageEssence ?? this.pourcentageEssence,
      commentaire: commentaire ?? this.commentaire,
      photosUrls: photosUrls ?? this.photosUrls,
      photosFiles: photosFiles ?? this.photosFiles,
      status: status ?? this.status,
      dateReservation: dateReservation ?? this.dateReservation,
      dateCreation: dateCreation ?? this.dateCreation,
      signatureAller: signatureAller ?? this.signatureAller,
      assuranceNom: assuranceNom ?? this.assuranceNom,
      assuranceNumero: assuranceNumero ?? this.assuranceNumero,
      franchise: franchise ?? this.franchise,
      prixLocation: prixLocation ?? this.prixLocation,
      accompte: accompte ?? this.accompte,
      caution: caution ?? this.caution,
      nettoyageInt: nettoyageInt ?? this.nettoyageInt,
      nettoyageExt: nettoyageExt ?? this.nettoyageExt,
      carburantManquant: carburantManquant ?? this.carburantManquant,
      kilometrageAutorise: kilometrageAutorise ?? this.kilometrageAutorise,
      kilometrageSupp: kilometrageSupp ?? this.kilometrageSupp,
      prixRayures: prixRayures ?? this.prixRayures,
      logoUrl: logoUrl ?? this.logoUrl,
      nomEntreprise: nomEntreprise ?? this.nomEntreprise,
      adresseEntreprise: adresseEntreprise ?? this.adresseEntreprise,
      telephoneEntreprise: telephoneEntreprise ?? this.telephoneEntreprise,
      siretEntreprise: siretEntreprise ?? this.siretEntreprise,
      nomCollaborateur: nomCollaborateur ?? this.nomCollaborateur,
      prenomCollaborateur: prenomCollaborateur ?? this.prenomCollaborateur,
      conditions: conditions ?? this.conditions,
      dateRetour: dateRetour ?? this.dateRetour,
      kilometrageRetour: kilometrageRetour ?? this.kilometrageRetour,
      pourcentageEssenceRetour: pourcentageEssenceRetour ?? this.pourcentageEssenceRetour,
      signatureRetour: signatureRetour ?? this.signatureRetour,
      factureGeneree: factureGeneree ?? this.factureGeneree,
      factureId: factureId ?? this.factureId,
      dateFacture: dateFacture ?? this.dateFacture,
      factureTotalFrais: factureTotalFrais ?? this.factureTotalFrais,
    );
  }
  
  // Convertir l'instance en Map pour la génération de PDF
  Map<String, dynamic> toPdfParams() {
    return {
      'nom': nom,
      'prenom': prenom,
      'adresse': adresse,
      'telephone': telephone,
      'email': email,
      'numeroPermis': numeroPermis,
      'immatriculationVehiculeClient': immatriculationVehiculeClient,
      'kilometrageVehiculeClient': kilometrageVehiculeClient,
      'marque': marque,
      'modele': modele,
      'immatriculation': immatriculation,
      'commentaire': commentaire,
      'photos': photosUrls,
      'signatureBase64': signatureAller,
      'nettoyageInt': nettoyageInt,
      'nettoyageExt': nettoyageExt,
      'carburantManquant': carburantManquant,
      'caution': caution,
      'typeCarburant': typeCarburant,
      'boiteVitesses': boiteVitesses,
      'vin': vin,
      'assuranceNom': assuranceNom,
      'assuranceNumero': assuranceNumero,
      'franchise': franchise,
      'prixRayures': prixRayures,
      'kilometrageSupp': kilometrageSupp,
      'kilometrageAutorise': kilometrageAutorise,
      'typeLocation': typeLocation,
      'prixLocation': prixLocation,
      'accompte': accompte,
      'kilometrageDepart': kilometrageDepart,
      'pourcentageEssence': pourcentageEssence.toString(),
      'condition': conditions,
      'nomCollaborateur': nomCollaborateur,
      'prenomCollaborateur': prenomCollaborateur,
      'contratId': contratId,
    };
  }
}
