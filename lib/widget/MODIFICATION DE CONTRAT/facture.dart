import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ContraLoc/services/collaborateur_util.dart';

class FactureScreen extends StatefulWidget {
  final Map<String, dynamic> data;
  final Function(Map<String, dynamic>) onFraisUpdated;
  final double kilometrageInitial;
  final double kilometrageActuel;
  final double tarifKilometrique;
  final String dateFinEffective;

  const FactureScreen({
    Key? key,
    required this.data,
    required this.onFraisUpdated,
    required this.kilometrageInitial,
    required this.kilometrageActuel,
    required this.tarifKilometrique,
    required this.dateFinEffective,
  }) : super(key: key);

  @override
  State<FactureScreen> createState() => _FactureScreenState();
}

class _FactureScreenState extends State<FactureScreen> {
  // Contrôleurs pour les champs de texte
  late TextEditingController _cautionController;
  late TextEditingController _fraisNettoyageIntController;
  late TextEditingController _fraisNettoyageExtController;
  late TextEditingController _fraisCarburantController;
  late TextEditingController _fraisRayuresController;
  late TextEditingController _fraisAutreController;
  late TextEditingController _remiseController; // Nouveau contrôleur pour la remise

  // Contrôleurs spécifiques pour les champs calculés automatiquement
  late TextEditingController _fraisKilometriqueController;
  late TextEditingController _fraisPrixLocationController;

  // Contrôleurs pour les champs de kilométrage
  late TextEditingController _kmDepartController;
  late TextEditingController _kmAutoriseController;
  late TextEditingController _kmSuppController;
  late TextEditingController _kmRetourController;

  // Type de paiement
  String _typePaiement = 'Carte bancaire';
  final List<String> _typesPaiement = ['Carte bancaire', 'Espèces', 'Virement'];
  
  // ID unique pour la facture
  String _factureId = '';
  
  // Option pour afficher les prix TTC ou HT
  bool _isTTC = true;

  // Total calculé
  double _total = 0.0;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('fr_FR', null); // Initialisation des locales françaises
    
    // Vérifier si un factureId existe déjà
    if (widget.data['factureId'] != null && widget.data['factureId'].toString().isNotEmpty) {
      _factureId = widget.data['factureId'];
      print('Utilisation du factureId existant: $_factureId');
    } else {
      // Générer un ID unique pour la facture seulement si aucun n'existe
      _factureId = 'FAC-${DateTime.now().millisecondsSinceEpoch}-${widget.data['contratId']?.substring(0, 5) ?? ''}';
      print('Nouveau factureId généré: $_factureId');
    }
    
    // Initialiser les contrôleurs avec des valeurs par défaut à 0
    _fraisKilometriqueController = TextEditingController(text: "0");
    _fraisPrixLocationController = TextEditingController(text: "0");
    _cautionController = TextEditingController(text: "0");
    _fraisNettoyageIntController = TextEditingController(text: "0");
    _fraisNettoyageExtController = TextEditingController(text: "0");
    _fraisCarburantController = TextEditingController(text: "0");
    _fraisRayuresController = TextEditingController(text: "0");
    _fraisAutreController = TextEditingController(text: "0");
    _kmDepartController = TextEditingController(text: "0");
    _kmAutoriseController = TextEditingController(text: "0");
    _kmSuppController = TextEditingController(text: "0");
    _kmRetourController = TextEditingController(text: "0");
    _remiseController = TextEditingController(text: "0");
    
    // Charger les données existantes si disponibles
    if (widget.data.isNotEmpty) {
      // Vérifier si les données sont dans un sous-objet 'facture'
      if (widget.data['facture'] != null && widget.data['facture'] is Map<String, dynamic>) {
        Map<String, dynamic> factureData = widget.data['facture'];
        
        // Charger les valeurs des contrôleurs depuis factureData
        _cautionController.text = factureData['factureCaution']?.toString() ?? "0";
        _fraisNettoyageIntController.text = factureData['factureFraisNettoyageInterieur']?.toString() ?? "0";
        _fraisNettoyageExtController.text = factureData['factureFraisNettoyageExterieur']?.toString() ?? "0";
        _fraisCarburantController.text = factureData['factureFraisCarburantManquant']?.toString() ?? "0";
        _fraisRayuresController.text = factureData['factureFraisRayuresDommages']?.toString() ?? "0";
        _fraisAutreController.text = factureData['factureFraisAutre']?.toString() ?? "0";
        _fraisPrixLocationController.text = factureData['facturePrixLocation']?.toString() ?? "0";
        
        // Assurer que les frais kilométriques sont correctement chargés
        var fraisKm = factureData['factureFraisKilometrique'];
        if (fraisKm != null) {
          // Convertir en chaîne et formater si nécessaire
          String fraisKmStr = fraisKm.toString();
          // Remplacer le point par une virgule pour l'affichage
          fraisKmStr = fraisKmStr.replaceAll('.', ',');
          _fraisKilometriqueController.text = fraisKmStr;
          print('Frais kilométriques chargés: $fraisKmStr (original: $fraisKm)');
        } else {
          _fraisKilometriqueController.text = "0";
        }
        
        _remiseController.text = factureData['factureRemise']?.toString() ?? "0";

        // Charger le type de paiement s'il existe
        if (factureData['factureTypePaiement'] != null && _typesPaiement.contains(factureData['factureTypePaiement'])) {
          _typePaiement = factureData['factureTypePaiement'];
        }
        
        // Charger l'option TTC/HT si elle existe
        if (factureData['tva'] != null) {
          _isTTC = factureData['tva'] == 'applicable';
        }
      } else {
        // Fallback au format ancien (données directement dans widget.data)
        _cautionController.text = widget.data['factureCaution']?.toString() ?? "0";
        _fraisNettoyageIntController.text = widget.data['factureFraisNettoyageInterieur']?.toString() ?? "0";
        _fraisNettoyageExtController.text = widget.data['factureFraisNettoyageExterieur']?.toString() ?? "0";
        _fraisCarburantController.text = widget.data['factureFraisCarburantManquant']?.toString() ?? "0";
        _fraisRayuresController.text = widget.data['factureFraisRayuresDommages']?.toString() ?? "0";
        _fraisAutreController.text = widget.data['factureFraisAutre']?.toString() ?? "0";
        _fraisPrixLocationController.text = widget.data['facturePrixLocation']?.toString() ?? "0";
        
        // Assurer que les frais kilométriques sont correctement chargés
        var fraisKm = widget.data['factureFraisKilometrique'];
        if (fraisKm != null) {
          // Convertir en chaîne et formater si nécessaire
          String fraisKmStr = fraisKm.toString();
          // Remplacer le point par une virgule pour l'affichage
          fraisKmStr = fraisKmStr.replaceAll('.', ',');
          _fraisKilometriqueController.text = fraisKmStr;
          print('Frais kilométriques chargés: $fraisKmStr (original: $fraisKm)');
        } else {
          _fraisKilometriqueController.text = "0";
        }
        
        _remiseController.text = widget.data['factureRemise']?.toString() ?? "0";

        // Charger le type de paiement s'il existe
        if (widget.data['factureTypePaiement'] != null && _typesPaiement.contains(widget.data['factureTypePaiement'])) {
          _typePaiement = widget.data['factureTypePaiement'];
        }
        
        // Charger l'option TTC/HT si elle existe
        if (widget.data['tva'] != null) {
          _isTTC = widget.data['tva'] == 'applicable';
        }
      }
    }

    // Charger les données de kilométrage
    _kmDepartController.text = widget.kilometrageInitial.toString();
    _kmRetourController.text = widget.kilometrageActuel.toString();
    _kmSuppController.text = widget.data['kilometrageSupp']?.toString() ?? '0';
    
    // Calculer le kilométrage autorisé (s'il existe dans les données)
    double kmAutorise = double.tryParse(widget.data['kilometrageAutorise']?.toString() ?? '0') ?? 0.0;
    _kmAutoriseController.text = kmAutorise.toString();
    
    // Ajouter des écouteurs pour recalculer le total lorsque les valeurs changent
    _cautionController.addListener(_calculerTotal);
    _fraisNettoyageIntController.addListener(_calculerTotal);
    _fraisNettoyageExtController.addListener(_calculerTotal);
    _fraisCarburantController.addListener(_calculerTotal);
    _fraisRayuresController.addListener(_calculerTotal);
    _fraisAutreController.addListener(_calculerTotal);
    _remiseController.addListener(_calculerTotal);
    
    // Calculer le total initial
    // Retarder légèrement le calcul pour s'assurer que les contrôleurs sont correctement initialisés
    Future.delayed(Duration.zero, () {
      _calculerTotal();
    });
  }

  @override
  void dispose() {
    _fraisKilometriqueController.dispose();
    _fraisPrixLocationController.dispose();
    _cautionController.dispose();
    _fraisNettoyageIntController.dispose();
    _fraisNettoyageExtController.dispose();
    _fraisCarburantController.dispose();
    _fraisRayuresController.dispose();
    _fraisAutreController.dispose();
    _kmDepartController.dispose();
    _kmAutoriseController.dispose();
    _kmSuppController.dispose();
    _kmRetourController.dispose();
    _remiseController.dispose(); // Dispose du contrôleur de remise
    super.dispose();
  }

  // Méthode pour notifier le parent des changements

  // Calculer le total des frais
  void _calculerTotal() {
    setState(() {
      double total = 0.0;
      bool prixLocationModifie = false;
      bool fraisKmModifies = false;

      // Vérifier si l'utilisateur a modifié manuellement les valeurs
      if (widget.data.containsKey('facturePrixLocation') && 
          _fraisPrixLocationController.text != widget.data['facturePrixLocation']?.toString()) {
        prixLocationModifie = true;
      }

      if (widget.data.containsKey('factureFraisKilometrique') && 
          _fraisKilometriqueController.text != widget.data['factureFraisKilometrique']?.toString()) {
        fraisKmModifies = true;
      }

      // Calcul du prix de location basé sur la durée
      try {
        // Récupérer les dates
        String dateDebutStr = (widget.data['dateDebut'] as String?) ?? '';
        String dateFinStr = widget.dateFinEffective;
        String prixLocationStr = (widget.data['prixLocation'] as String?) ?? '0';
        
        // Convertir le prix de location en double
        double prixLocationJournalier = double.tryParse(prixLocationStr.replaceAll(',', '.')) ?? 0.0;
        
        // Ne pas recalculer si l'utilisateur a modifié manuellement ou vidé le champ
        if (!prixLocationModifie && _fraisPrixLocationController.text.isNotEmpty && 
            dateDebutStr.isNotEmpty && dateFinStr.isNotEmpty && prixLocationJournalier > 0) {
          // Extraire les dates en garantissant différents formats possibles
          DateTime? dateDebut;
          DateTime? dateFin;
          
          // Essayer de parser le format complet avec heure (ex: "mardi 1 avril 2025 à 17:19")
          try {
            // Extraire la date et l'heure
            RegExp regExpDate = RegExp(r'\d{1,2}\s+\w+\s+\d{4}');
            RegExp regExpHeure = RegExp(r'\d{1,2}:\d{2}');
            
            // Pour la date de début
            var matchDate = regExpDate.firstMatch(dateDebutStr);
            var matchHeure = regExpHeure.firstMatch(dateDebutStr);
            
            if (matchDate != null) {
              String simplifiedDate = matchDate.group(0)!;
              String heure = matchHeure != null ? matchHeure.group(0)! : "00:00";
              
              // Combiner la date et l'heure
              dateDebut = DateFormat('d MMMM yyyy HH:mm', 'fr_FR').parse("$simplifiedDate $heure");
            }
            
            // Pour la date de fin
            matchDate = regExpDate.firstMatch(dateFinStr);
            matchHeure = regExpHeure.firstMatch(dateFinStr);
            
            if (matchDate != null) {
              String simplifiedDate = matchDate.group(0)!;
              String heure = matchHeure != null ? matchHeure.group(0)! : "00:00";
              
              // Combiner la date et l'heure
              dateFin = DateFormat('d MMMM yyyy HH:mm', 'fr_FR').parse("$simplifiedDate $heure");
            }
          } catch (e) {
            print('Erreur lors de l\'extraction de la date et de l\'heure: $e');
          }
          
          // Si l'extraction a échoué, essayer d'autres formats courants
          if (dateDebut == null) {
            try {
              // Essayer le format dd/MM/yyyy
              dateDebut = DateFormat('dd/MM/yyyy').parse(dateDebutStr);
            } catch (e) {
              print('Impossible de parser la date de début: $e');
            }
          }
          
          if (dateFin == null) {
            try {
              // Essayer le format dd/MM/yyyy
              dateFin = DateFormat('dd/MM/yyyy').parse(dateFinStr);
            } catch (e) {
              print('Impossible de parser la date de fin: $e');
            }
          }
          
          // Si les deux dates sont valides, calculer la durée
          if (dateDebut != null && dateFin != null) {
            // Calculer la durée en heures
            int dureeHeures = dateFin.difference(dateDebut).inHours;
            
            // Calculer le nombre de tranches de 24h (arrondi au supérieur)
            double dureeJours = dureeHeures / 24.0;
            dureeJours = (dureeHeures % 24 == 0) ? dureeJours : dureeJours.ceilToDouble();
            dureeJours = dureeJours <= 0 ? 1.0 : dureeJours; // Au moins 1 tranche de 24h
            
            // Calculer le prix total de location (100€ pour 24h)
            double prixLocationTotal = dureeJours * prixLocationJournalier;
            
            // Mettre à jour le champ du prix de location total
            _fraisPrixLocationController.text = prixLocationTotal.toStringAsFixed(2).replaceAll('.', ',');
            
            // Afficher les informations de calcul pour le débogage
            print('Date de début: $dateDebut, Date de fin: $dateFin, Durée: $dureeHeures heures ($dureeJours tranches de 24h), Prix par 24h: $prixLocationJournalier€, Total: ${prixLocationTotal}€');
          }
        }
      } catch (e) {
        // En cas d'erreur, garder la valeur actuelle
        print('Erreur lors du calcul de la durée de location: $e');
      }

      // Calcul des frais kilométriques seulement si le champ n'a pas été modifié manuellement
      // et si le kilométrage de retour a été saisi
      if (!fraisKmModifies && _kmRetourController.text.isNotEmpty && _kmRetourController.text != "0") {
        double kmDepart = double.tryParse(_kmDepartController.text.replaceAll(',', '.')) ?? 0;
        double kmAutorise = double.tryParse(_kmAutoriseController.text.replaceAll(',', '.')) ?? 0;
        double kmRetour = double.tryParse(_kmRetourController.text.replaceAll(',', '.')) ?? 0;
        double kmSupp = double.tryParse(_kmSuppController.text.replaceAll(',', '.')) ?? 0;

        // Ne calculer que si le kilométrage de retour est supérieur au kilométrage de départ + autorisé
        if (kmRetour > (kmDepart + kmAutorise) && kmSupp > 0) {
          // Calcul : (kmRetour - (kmDepart + kmAutorise)) * kmSupp
          double fraisKm = (kmRetour - (kmDepart + kmAutorise)) * kmSupp;
          
          // Assurer que le résultat est positif
          fraisKm = fraisKm < 0 ? 0 : fraisKm;
          
          _fraisKilometriqueController.text = fraisKm.toStringAsFixed(2).replaceAll('.', ',');
          print('Frais kilométriques calculés: ${_fraisKilometriqueController.text} (kmDepart: $kmDepart, kmAutorise: $kmAutorise, kmRetour: $kmRetour, kmSupp: $kmSupp)');
        }
      }

      // Ajouter tous les frais qui ont une valeur non nulle
      if (_fraisPrixLocationController.text.isNotEmpty) {
        total += double.tryParse(_fraisPrixLocationController.text.replaceAll(',', '.')) ?? 0.0;
      }
      if (_fraisKilometriqueController.text.isNotEmpty) {
        total += double.tryParse(_fraisKilometriqueController.text.replaceAll(',', '.')) ?? 0.0;
      }
      total += double.tryParse(_fraisNettoyageIntController.text.replaceAll(',', '.')) ?? 0.0;
      total += double.tryParse(_fraisNettoyageExtController.text.replaceAll(',', '.')) ?? 0.0;
      total += double.tryParse(_fraisCarburantController.text.replaceAll(',', '.')) ?? 0.0;
      total += double.tryParse(_fraisRayuresController.text.replaceAll(',', '.')) ?? 0.0;
      total += double.tryParse(_fraisAutreController.text.replaceAll(',', '.')) ?? 0.0;
      total += double.tryParse(_cautionController.text.replaceAll(',', '.')) ?? 0.0;
      
      // Appliquer la remise (soustraire du total)
      double remise = double.tryParse(_remiseController.text.replaceAll(',', '.')) ?? 0.0;
      total -= remise;
      
      // S'assurer que le total n'est pas négatif
      total = total < 0 ? 0 : total;
      
      // Appliquer la TVA si applicable (20%)
      if (_isTTC) {
        // Si on est en mode TTC, le total est déjà TTC
        _total = total;
      } else {
        // Si on est en mode HT, le total est HT
        _total = total;
      }
    });
  }

  Future<void> _sauvegarderDonneesFrais() async {
    try {
      // Obtenir l'utilisateur actuel
      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Utilisateur non connecté')),
        );
        return;
      }

      // Convertir les valeurs des contrôleurs en nombres
      double caution = double.tryParse(_cautionController.text.replaceAll(',', '.')) ?? 0.0;
      double fraisNettoyageInt = double.tryParse(_fraisNettoyageIntController.text.replaceAll(',', '.')) ?? 0.0;
      double fraisNettoyageExt = double.tryParse(_fraisNettoyageExtController.text.replaceAll(',', '.')) ?? 0.0;
      double fraisCarburant = double.tryParse(_fraisCarburantController.text.replaceAll(',', '.')) ?? 0.0;
      double fraisRayures = double.tryParse(_fraisRayuresController.text.replaceAll(',', '.')) ?? 0.0;
      double fraisAutre = double.tryParse(_fraisAutreController.text.replaceAll(',', '.')) ?? 0.0;
      double remise = double.tryParse(_remiseController.text.replaceAll(',', '.')) ?? 0.0;
      double fraisKilometrique = double.tryParse(_fraisKilometriqueController.text.replaceAll(',', '.')) ?? 0.0;
      double prixLocation = double.tryParse(_fraisPrixLocationController.text.replaceAll(',', '.')) ?? 0.0;

      // Créer un objet avec les données de la facture
      Map<String, dynamic> factureData = {
        'factureId': _factureId,
        'factureCaution': caution,
        'facturePrixLocation': prixLocation,
        'factureFraisNettoyageInterieur': fraisNettoyageInt,
        'factureFraisNettoyageExterieur': fraisNettoyageExt,
        'factureFraisCarburantManquant': fraisCarburant,
        'factureFraisRayuresDommages': fraisRayures,
        'factureFraisAutre': fraisAutre,
        'factureFraisKilometrique': fraisKilometrique,
        'factureRemise': remise,
        'factureTotalFrais': _total,
        'factureTypePaiement': _typePaiement,
        'dateFacture': Timestamp.now(),
        'tva': _isTTC ? 'applicable' : 'non applicable', // Remplacer factureTTC par tva avec une chaîne
      };

      // Vérifier si l'utilisateur est un collaborateur
      final collaborateurStatus = await CollaborateurUtil.checkCollaborateurStatus();
      final String targetId = collaborateurStatus['isCollaborateur'] 
          ? collaborateurStatus['adminId'] ?? user.uid 
          : user.uid;

      // Mettre à jour les données dans Firestore
      // Utiliser la structure correcte: users/[userId]/locations/[contratId]
      // Vérifier et afficher l'ID du contrat pour le débogage
      String? contratId = widget.data['id'];
      print('ID du contrat: $contratId');
      print('Données du widget: ${widget.data}');
      
      if (contratId == null || contratId.isEmpty) {
        // Essayer d'utiliser contratId s'il existe
        contratId = widget.data['contratId'];
        print('Tentative avec contratId alternatif: $contratId');
      }
      
      if (contratId == null || contratId.isEmpty) {
        throw Exception('ID du contrat non trouvé dans les données');
      }
      
      await FirebaseFirestore.instance
          .collection('users')
          .doc(targetId)
          .collection('locations')
          .doc(contratId)
          .update({
        'facture': factureData,
        'factureId': _factureId,
        'factureGeneree': true,
        'kilometrageRetour': _kmRetourController.text,
        'dateFinEffectif': widget.dateFinEffective,
      });
      
      // Appeler la fonction onFraisUpdated pour mettre à jour les données locales
      widget.onFraisUpdated({
        'facture': factureData,
        'factureId': _factureId,
        'factureGeneree': true,
      });
      // Afficher un message de succès
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Facture enregistrée avec succès')),
      );

      // Fermer l'écran
      Navigator.pop(context);
    } catch (e) {
      print('Erreur lors de la sauvegarde des frais: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la sauvegarde: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Facture',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF08004D),
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // En-tête avec description
                  _buildHeader(),
                  const SizedBox(height: 24),

                  // Section des frais principaux
                  _buildSection(
                    title: "Prix de location (Prix / 24h)",
                    icon: Icons.attach_money,
                    color: Colors.green[700]!,
                    children: [
                      // Champ de date de début
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: TextFormField(
                          initialValue: widget.data['dateDebut'] ?? '',
                          decoration: InputDecoration(
                            labelText: "Date de début",
                            labelStyle: const TextStyle(color: Color(0xFF08004D)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          readOnly: true,
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                      
                      // Champ de date de fin effective
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: TextFormField(
                          initialValue: widget.dateFinEffective,
                          decoration: InputDecoration(
                            labelText: "Date de fin effective",
                            labelStyle: const TextStyle(color: Color(0xFF08004D)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          readOnly: true,
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                      
                      // Champ du prix de location initial
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: TextFormField(
                          initialValue: widget.data['prixLocation'] ?? '',
                          decoration: InputDecoration(
                            labelText: "Prix de location initial",
                            labelStyle: const TextStyle(color: Color(0xFF08004D)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            prefixText: '€',
                          ),
                          readOnly: true,
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                      
                      // Prix de location total
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: TextFormField(
                          controller: _fraisPrixLocationController,
                          decoration: InputDecoration(
                            labelText: "Prix de location total",
                            labelStyle: const TextStyle(color: Color(0xFF08004D)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            prefixText: '€',
                            helperText: "Calculé automatiquement",
                            helperStyle: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
                          ),
                          enabled: true,
                          readOnly: false,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d*\,?\d{0,2}')),
                          ],
                          onChanged: (value) {
                            // Marquer explicitement que ce champ a été modifié manuellement
                            setState(() {
                              widget.data['facturePrixLocation'] = null; // Force la détection de modification
                              _calculerTotal();
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Section des frais kilométriques
                  _buildSection(
                    title: "Frais kilométriques",
                    icon: Icons.directions_car,
                    color: Colors.blue[700]!,
                    children: [
                      // Champ de kilométrage de départ
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: TextFormField(
                          controller: _kmDepartController,
                          decoration: InputDecoration(
                            labelText: "Kilométrage de départ",
                            labelStyle: const TextStyle(color: Color(0xFF08004D)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            suffixText: 'km',
                          ),
                          readOnly: true,
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                        ),
                      ),

                      // Champ de kilométrage autorisé
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: TextFormField(
                          controller: _kmAutoriseController,
                          decoration: InputDecoration(
                            labelText: "Kilométrage autorisé",
                            labelStyle: const TextStyle(color: Color(0xFF08004D)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            suffixText: 'km',
                          ),
                          readOnly: true,
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                        ),
                      ),

                      // Champ du tarif kilométrique
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: TextFormField(
                          controller: _kmSuppController,
                          decoration: InputDecoration(
                            labelText: "Tarif kilométrique",
                            labelStyle: const TextStyle(color: Color(0xFF08004D)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            suffixText: '€/km',
                          ),
                          readOnly: true,
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                      
                      // Champ du kilométrage de retour
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: TextFormField(
                          controller: _kmRetourController,
                          decoration: InputDecoration(
                            labelText: "Kilométrage de retour",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.check_circle),
                              onPressed: () {
                                // Fermer le clavier
                                FocusScope.of(context).unfocus();
                              },
                            ),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d*\,?\d{0,2}')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _calculerTotal();
                            });
                          },
                        ),
                      ),
                      
                      // Champ des frais kilométriques
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: TextFormField(
                          controller: _fraisKilometriqueController,
                          decoration: InputDecoration(
                            labelText: "Frais kilométriques",
                            labelStyle: const TextStyle(color: Color(0xFF08004D)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            prefixText: '€',
                            helperText: "Calculé automatiquement, mais modifiable ou effaçable",
                            helperStyle: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
                          ),
                          enabled: true,
                          readOnly: false,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d*\,?\d{0,2}')),
                          ],
                          onChanged: (value) {
                            // Marquer explicitement que ce champ a été modifié manuellement
                            setState(() {
                              widget.data['factureFraisKilometrique'] = null; // Force la détection de modification
                              _calculerTotal();
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Section des frais additionnels
                  _buildSection(
                    title: "Frais additionnels",
                    icon: Icons.add_circle_outline,
                    color: Colors.orange[700]!,
                    children: [
                      _buildTextField("Frais nettoyage intérieur", _fraisNettoyageIntController),
                      _buildTextField("Frais nettoyage extérieur", _fraisNettoyageExtController),
                      _buildTextField("Frais carburant manquant", _fraisCarburantController),
                      _buildTextField("Frais rayures/dommages", _fraisRayuresController),
                      _buildTextField("Frais autres", _fraisAutreController),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Section de la caution
                  _buildSection(
                    title: "Caution",
                    icon: Icons.security,
                    color: Colors.blue[700]!,
                    children: [
                      _buildTextField("Frais caution", _cautionController),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Section de la remise
                  _buildSection(
                    title: "Remise",
                    icon: Icons.discount,
                    color: Colors.purple[700]!,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: TextFormField(
                          controller: _remiseController,
                          decoration: InputDecoration(
                            labelText: "Remise",
                            labelStyle: const TextStyle(color: Color(0xFF08004D)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            suffixText: '€',
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d*\,?\d{0,2}')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _calculerTotal();
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Section du type de paiement
                  _buildSection(
                    title: "Type de paiement",
                    icon: Icons.payment,
                    color: Colors.purple[700]!,
                    children: [
                      DropdownButtonFormField<String>(
                        value: _typePaiement,
                        decoration: InputDecoration(
                          labelText: "Type de paiement",
                          labelStyle: const TextStyle(color: Color(0xFF08004D)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        items: _typesPaiement.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _typePaiement = newValue ?? 'Carte bancaire';
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Section du total
                  _buildSection(
                    title: "Total",
                    icon: Icons.attach_money,
                    color: Colors.green[700]!,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${_total.toStringAsFixed(2).replaceAll('.', ',')}€ TTC',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green[700],
                                  ),
                                ),
                                if (_isTTC)
                                  Text(
                                    'TVA 20% incluse',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TVA',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF08004D),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Bouton TVA applicable
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    _isTTC = true;
                                    _calculerTotal();
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _isTTC ? Color(0xFF08004D) : Colors.grey.shade200,
                                  foregroundColor: _isTTC ? Colors.white : Colors.black87,
                                  elevation: _isTTC ? 2 : 0,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(8),
                                      bottomLeft: Radius.circular(8),
                                    ),
                                  ),
                                ),
                                child: Text(
                                  'Applicable',
                                  style: TextStyle(fontSize: 16, fontWeight: _isTTC ? FontWeight.bold : FontWeight.normal),
                                ),
                              ),
                            ),
                            // Bouton TVA non applicable
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    _isTTC = false;
                                    _calculerTotal();
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: !_isTTC ? Color(0xFF08004D) : Colors.grey.shade200,
                                  foregroundColor: !_isTTC ? Colors.white : Colors.black87,
                                  elevation: !_isTTC ? 2 : 0,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.only(
                                      topRight: Radius.circular(8),
                                      bottomRight: Radius.circular(8),
                                    ),
                                  ),
                                ),
                                child: Text(
                                  'Non applicable',
                                  style: TextStyle(fontSize: 16, fontWeight: !_isTTC ? FontWeight.bold : FontWeight.normal),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Bouton de validation
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Center(
                      child: SizedBox(
                        width: 350, // Largeur fixe du bouton
                        child: ElevatedButton(
                          onPressed: _sauvegarderDonneesFrais,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF08004D),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Valider',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Gestion de la facture',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF08004D),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Saisissez les éléments pour générer la facture',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête de section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          // Contenu de la section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool isEditable = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Color(0xFF08004D)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          prefixText: '€',
          helperText: isEditable ? "Modifiable" : null,
          helperStyle: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
        ),
        keyboardType: TextInputType.number,
        readOnly: !isEditable,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\,?\d{0,2}')),
        ],
        onChanged: (value) {
          setState(() {
            _calculerTotal();
          });
        },
      ),
    );
  }
}
