import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../CHIFFRES/chiffre_affaire_card.dart';
import '../CHIFFRES/repartition_vehicule_card.dart';
import '../CHIFFRES/evolution_chiffre_card.dart';
import '../CHIFFRES/popup_filtre.dart';
import '../CHIFFRES/periode.dart';

class ChiffreAffaireScreen extends StatefulWidget {
  const ChiffreAffaireScreen({Key? key}) : super(key: key);

  @override
  State<ChiffreAffaireScreen> createState() => _ChiffreAffaireScreenState();
}

class _ChiffreAffaireScreenState extends State<ChiffreAffaireScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String _selectedPeriod = 'Mois';
  String _selectedYear = DateTime.now().year.toString();
  String _selectedMonth = 'Tous';
  
  // Filtres pour le calcul du chiffre d'affaire
  Map<String, bool> _filtresCalcul = {
    'facturePrixLocation': true,
    'factureCoutKmSupplementaires': true,
    'factureFraisNettoyageInterieur': true,
    'factureFraisNettoyageExterieur': true,
    'factureFraisCarburantManquant': true,
    'factureFraisRayuresDommages': true,
    'factureFraisAutre': true,
    'factureCaution': true,
    'factureFraisCasque': true,
    'factureRemise': true,
  };
  
  List<Map<String, dynamic>> _contrats = [];
  List<String> _years = [];
  
  // Données calculées
  Map<String, double> _chiffreParVehicule = {};
  Map<String, Map<String, dynamic>> _detailsVehicules = {}; // Pour stocker les détails des véhicules
  Map<String, double> _chiffreParPeriode = {};
  double _chiffreTotal = 0;
  double _chiffrePeriodeSelectionnee = 0;
  
  // Statistiques
  String _vehiculePlusRentable = '';
  String _marqueVehiculePlusRentable = '';
  String _modeleVehiculePlusRentable = '';
  String _immatriculationVehiculePlusRentable = '';
  double _montantVehiculePlusRentable = 0;
  double _pourcentageVehiculePlusRentable = 0;
  
  String? _error;
  
  // Périodes disponibles
  final List<String> _periodes = ['Jour', 'Semaine', 'Mois', 'Trimestre', 'Année'];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchData();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Vérifier si l'utilisateur est connecté
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _isLoading = false;
          _error = "Utilisateur non connecté";
        });
        return;
      }

      // Vérifier si l'utilisateur est un collaborateur
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get(const GetOptions(source: Source.serverAndCache));
      
      final userData = userDoc.data();
      final bool isCollaborateur = userData != null && userData['role'] == 'collaborateur';
      final String? adminId = isCollaborateur ? userData['adminId'] as String? : null;
      final String userId = isCollaborateur && adminId != null ? adminId : user.uid;

      print('Récupération des contrats pour l\'utilisateur: $userId');
      
      // Récupérer tous les contrats avec une date de facture, triés par date (plus récents en premier)
      QuerySnapshot contratsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('locations')
          .where('dateFacture', isNull: false)
          .orderBy('dateFacture', descending: true)
          .get(const GetOptions(source: Source.serverAndCache));

      print('Nombre de contrats trouvés: ${contratsSnapshot.docs.length}');

      // Traiter les contrats
      List<Map<String, dynamic>> contrats = [];
      double chiffreTotal = 0;
      Set<String> years = {};
      Map<String, Map<String, dynamic>> vehiculesMap = {};
      
      // Récupérer tous les véhicules uniques en une seule requête
      final vehiculesRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('vehicules');
      
      // Extraire les IDs des véhicules des contrats
      Set<String> vehiculesIds = {};
      for (var doc in contratsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final vehiculeId = data['vehiculeId'] as String?;
        if (vehiculeId != null) {
          vehiculesIds.add(vehiculeId);
        }
      }

      // Récupérer les informations des véhicules en une seule requête
      if (vehiculesIds.isNotEmpty) {
        final vehiculesSnapshot = await vehiculesRef
            .where(FieldPath.documentId, whereIn: vehiculesIds.toList())
            .get(const GetOptions(source: Source.serverAndCache));

        // Créer un mapping des véhicules par ID
        for (var doc in vehiculesSnapshot.docs) {
          final vehiculeData = doc.data();
          final vehiculeInfoStr = '${vehiculeData['marque']} ${vehiculeData['modele']} (${vehiculeData['immatriculation']})';
          vehiculesMap[vehiculeInfoStr] = {
            'marque': vehiculeData['marque'] ?? '',
            'modele': vehiculeData['modele'] ?? '',
            'immatriculation': vehiculeData['immatriculation'] ?? '',
            'photoVehiculeUrl': vehiculeData['photoVehiculeUrl'] ?? '',
          };
        }
      }

      // Maintenant traiter les contrats avec les informations des véhicules déjà récupérées
      for (var doc in contratsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        
        // Récupérer les informations du véhicule depuis le mapping
        String? vehiculeInfoStr;
        if (data['marque'] != null && data['modele'] != null && data['immatriculation'] != null) {
          vehiculeInfoStr = '${data['marque']} ${data['modele']} (${data['immatriculation']})';
        } else {
          // Si les informations ne sont pas directement dans le contrat, utiliser le mapping
          vehiculeInfoStr = vehiculesMap.keys.firstWhere(
            (key) => key.contains(data['immatriculation'] ?? ''),
            orElse: () => '',
          );
        }

        // Récupérer les données financières directement du contrat
        double prixLocation = _convertToDouble(data['facturePrixLocation'] ?? '0');
        double caution = _convertToDouble(data['factureCaution'] ?? '0');
        double coutKmSupplementaires = _convertToDouble(data['factureCoutKmSupplementaires'] ?? '0');
        double fraisNettoyageInterieur = _convertToDouble(data['factureFraisNettoyageInterieur'] ?? '0');
        double fraisNettoyageExterieur = _convertToDouble(data['factureFraisNettoyageExterieur'] ?? '0');
        double fraisCarburantManquant = _convertToDouble(data['factureFraisCarburantManquant'] ?? '0');
        double fraisRayuresDommages = _convertToDouble(data['factureFraisRayuresDommages'] ?? '0');
        double fraisCasque = _convertToDouble(data['factureFraisCasque'] ?? '0');
        double fraisAutre = _convertToDouble(data['factureFraisAutre'] ?? '0');
        double remise = _convertToDouble(data['factureRemise'] ?? '0');
        String typePaiement = data['factureTypePaiement'] ?? '';
        String tvaStatus = data['tva'] ?? 'applicable';
        bool isTTC = tvaStatus == 'applicable';
        
        // Récupérer le total des frais s'il existe, sinon le calculer
        double montantTotal = 0;
        
        if (data['factureTotalFrais'] != null && _convertToDouble(data['factureTotalFrais']) > 0) {
          montantTotal = _convertToDouble(data['factureTotalFrais']);
        } else {
          double totalBrut = prixLocation + caution + coutKmSupplementaires + 
                          fraisNettoyageInterieur + fraisNettoyageExterieur + 
                          fraisCarburantManquant + fraisRayuresDommages + 
                          fraisCasque + fraisAutre;
          
          if (isTTC) {
            montantTotal = totalBrut - remise;
          } else {
            montantTotal = totalBrut - remise;
          }
        }
        
        // Récupérer la date de facture
        DateTime dateFacture = (data['dateFacture'] as Timestamp).toDate();
        
        // Ajouter l'année à la liste des années disponibles
        years.add(dateFacture.year.toString());
        
        // Ajouter à la liste des contrats
        contrats.add({
          'vehiculeInfoStr': vehiculeInfoStr,
          'vehiculeDetails': vehiculesMap[vehiculeInfoStr],
          'facturePrixLocation': prixLocation,
          'factureCaution': caution,
          'factureCoutKmSupplementaires': coutKmSupplementaires,
          'factureFraisNettoyageInterieur': fraisNettoyageInterieur,
          'factureFraisNettoyageExterieur': fraisNettoyageExterieur,
          'factureFraisCarburantManquant': fraisCarburantManquant,
          'factureFraisRayuresDommages': fraisRayuresDommages,
          'factureFraisCasque': fraisCasque,
          'factureFraisAutre': fraisAutre,
          'factureRemise': remise,
          'factureTypePaiement': typePaiement,
          'factureTotalFrais': montantTotal,
          'tvaStatus': tvaStatus,
          'isTTC': isTTC,
          'dateCloture': dateFacture,
        });
        
        chiffreTotal += montantTotal;
      }

      // Trier les années par ordre décroissant
      List<String> sortedYears = years.toList()..sort((a, b) => b.compareTo(a));
      if (sortedYears.isNotEmpty) {
        _selectedYear = sortedYears.first;
      }

      // Mettre à jour l'état
      setState(() {
        _contrats = contrats;
        _detailsVehicules = vehiculesMap;
        _years = sortedYears;
        _chiffreTotal = chiffreTotal;
        _isLoading = false;
      });

      // Calculer les chiffres par période et par véhicule
      _calculerTousLesChiffres();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = "Erreur lors de la récupération des données: $e";
      });
    }
  }
  
  // Méthode utilitaire pour convertir en double
  double _convertToDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      // Remplacer la virgule par un point pour la conversion
      String valueStr = value.replaceAll(',', '.');
      return double.tryParse(valueStr) ?? 0.0;
    }
    return 0.0;
  }
  
  void _calculerTousLesChiffres() {
    _calculerChiffreParPeriode();
    _calculerChiffreParVehicule();
    _calculerStatistiques();
  }
  
  void _calculerChiffreParPeriode() {
    Map<String, double> chiffreParPeriode = {};
    double chiffrePeriodeSelectionnee = 0;
    
    for (var contrat in _contrats) {
      DateTime dateCloture = contrat['dateCloture']; // On utilise la date de facture stockée dans dateCloture
      double montant = 0;
      if (_filtresCalcul['facturePrixLocation']!) montant += contrat['facturePrixLocation'];
      if (_filtresCalcul['factureFraisCasque']!) montant += contrat['factureFraisCasque'];
      if (_filtresCalcul['factureCoutKmSupplementaires']!) montant += contrat['factureCoutKmSupplementaires'];
      if (_filtresCalcul['factureFraisNettoyageInterieur']!) montant += contrat['factureFraisNettoyageInterieur'];
      if (_filtresCalcul['factureFraisNettoyageExterieur']!) montant += contrat['factureFraisNettoyageExterieur'];
      if (_filtresCalcul['factureFraisCarburantManquant']!) montant += contrat['factureFraisCarburantManquant'];
      if (_filtresCalcul['factureFraisRayuresDommages']!) montant += contrat['factureFraisRayuresDommages'];
      if (_filtresCalcul['factureFraisAutre']!) montant += contrat['factureFraisAutre'];
      if (_filtresCalcul['factureCaution']!) montant += contrat['factureCaution'];
      
      // Soustraire la remise si elle existe et si le filtre est actif
      if (_filtresCalcul['factureRemise']! && contrat.containsKey('factureRemise')) {
        montant -= contrat['factureRemise'];
      }
      
      // Filtrer par année si nécessaire
      if (dateCloture.year.toString() != _selectedYear) {
        continue;
      }
      
      String periode;
      if (_selectedPeriod == 'Jour') {
        // Format: 2025-03-26
        periode = DateFormat('yyyy-MM-dd').format(dateCloture);
      } else if (_selectedPeriod == 'Semaine') {
        // Format: 2025-W12 (année-semaine)
        int weekNumber = ((dateCloture.difference(DateTime(dateCloture.year, 1, 1)).inDays) / 7).floor() + 1;
        periode = '${dateCloture.year}-S$weekNumber';
      } else if (_selectedPeriod == 'Mois') {
        // Format: 2025-03
        periode = DateFormat('yyyy-MM').format(dateCloture);
      } else if (_selectedPeriod == 'Trimestre') {
        // Format: 2025-Q1, 2025-Q2, etc.
        int trimestre = ((dateCloture.month - 1) / 3).floor() + 1;
        periode = '${dateCloture.year}-T$trimestre';
      } else {
        // Format: 2025
        periode = DateFormat('yyyy').format(dateCloture);
      }
      
      if (chiffreParPeriode.containsKey(periode)) {
        chiffreParPeriode[periode] = (chiffreParPeriode[periode] ?? 0) + montant;
      } else {
        chiffreParPeriode[periode] = montant;
      }
      
      // Pour l'onglet Période, calculer le chiffre d'affaires total pour le mois sélectionné
      if (_tabController.index == 1) {
        // Si un mois spécifique est sélectionné, vérifier si ce contrat correspond au mois sélectionné
        if (_selectedMonth != 'Tous') {
          int moisSelectionne = getMonthNumber(_selectedMonth);
          if (moisSelectionne > 0 && dateCloture.month == moisSelectionne) {
            chiffrePeriodeSelectionnee += montant;
          }
        } else {
          // Si tous les mois sont sélectionnés, ajouter tous les contrats de l'année sélectionnée
          chiffrePeriodeSelectionnee += montant;
        }
      } else {
        // Pour l'onglet Résumé, utiliser la logique existante
        chiffrePeriodeSelectionnee += montant;
      }
    }
    
    setState(() {
      _chiffreParPeriode = chiffreParPeriode;
      _chiffrePeriodeSelectionnee = chiffrePeriodeSelectionnee;
    });
  }
  
  void _calculerChiffreParVehicule() {
    Map<String, double> chiffreParVehicule = {};
    Map<String, Map<String, dynamic>> detailsVehicules = {};
    
    for (var contrat in _contrats) {
      DateTime dateCloture = contrat['dateCloture']; // On utilise la date de facture stockée dans dateCloture
      if (!_estDansPeriodeSelectionnee(dateCloture)) {
        continue;
      }
      
      String vehiculeInfoStr = contrat['vehiculeInfoStr'] ?? '';
      if (vehiculeInfoStr.isEmpty) continue;
      
      // Récupérer les détails du véhicule
      Map<String, dynamic> vehiculeDetails = contrat['vehiculeDetails'] ?? {};
      
      // Calculer le montant en fonction des filtres sélectionnés
      double montant = 0;
      if (_filtresCalcul['facturePrixLocation'] == true) {
        montant += contrat['facturePrixLocation'] ?? 0;
      }
      if (_filtresCalcul['factureFraisCasque'] == true) {
        montant += contrat['factureFraisCasque'] ?? 0;
      }
      if (_filtresCalcul['factureCoutKmSupplementaires'] == true) {
        montant += contrat['factureCoutKmSupplementaires'] ?? 0;
      }
      if (_filtresCalcul['factureFraisNettoyageInterieur'] == true) {
        montant += contrat['factureFraisNettoyageInterieur'] ?? 0;
      }
      if (_filtresCalcul['factureFraisNettoyageExterieur'] == true) {
        montant += contrat['factureFraisNettoyageExterieur'] ?? 0;
      }
      if (_filtresCalcul['factureFraisCarburantManquant'] == true) {
        montant += contrat['factureFraisCarburantManquant'] ?? 0;
      }
      if (_filtresCalcul['factureFraisRayuresDommages'] == true) {
        montant += contrat['factureFraisRayuresDommages'] ?? 0;
      }
      if (_filtresCalcul['factureFraisAutre'] == true) {
        montant += contrat['factureFraisAutre'] ?? 0;
      }
      if (_filtresCalcul['factureCaution'] == true) {
        montant += contrat['factureCaution'] ?? 0;
      }
      
      // Soustraire la remise si elle existe et si le filtre est actif
      if (_filtresCalcul['factureRemise']! && contrat.containsKey('factureRemise')) {
        montant -= contrat['factureRemise'];
      }
      
      if (chiffreParVehicule.containsKey(vehiculeInfoStr)) {
        chiffreParVehicule[vehiculeInfoStr] = (chiffreParVehicule[vehiculeInfoStr] ?? 0) + montant;
      } else {
        chiffreParVehicule[vehiculeInfoStr] = montant;
      }
      
      // Stocker les détails du véhicule s'ils ne sont pas déjà enregistrés
      if (!detailsVehicules.containsKey(vehiculeInfoStr) && vehiculeDetails.isNotEmpty) {
        detailsVehicules[vehiculeInfoStr] = vehiculeDetails;
      }
    }
    
    setState(() {
      _chiffreParVehicule = chiffreParVehicule;
      _detailsVehicules = detailsVehicules;
    });
  }
  
  void _calculerStatistiques() {
    // Trouver le véhicule le plus rentable
    if (_chiffreParVehicule.isNotEmpty) {
      MapEntry<String, double> vehiculePlusRentable = _chiffreParVehicule.entries
          .reduce((a, b) => a.value > b.value ? a : b);
      
      setState(() {
        _vehiculePlusRentable = vehiculePlusRentable.key;
        
        // Récupérer les détails du véhicule le plus rentable
        if (_detailsVehicules.containsKey(_vehiculePlusRentable)) {
          Map<String, dynamic> details = _detailsVehicules[_vehiculePlusRentable]!;
          _marqueVehiculePlusRentable = details['marque'] ?? '';
          _modeleVehiculePlusRentable = details['modele'] ?? '';
          _immatriculationVehiculePlusRentable = details['immatriculation'] ?? '';
        } else {
          // Essayer d'extraire les informations du nom du véhicule
          List<String> parts = _vehiculePlusRentable.split(' ');
          if (parts.length >= 2) {
            _marqueVehiculePlusRentable = parts[0];
            
            // Extraire le modèle (tout sauf la marque et l'immatriculation entre parenthèses)
            String reste = _vehiculePlusRentable.substring(_marqueVehiculePlusRentable.length).trim();
            int indexParenthese = reste.lastIndexOf('(');
            if (indexParenthese > 0) {
              _modeleVehiculePlusRentable = reste.substring(0, indexParenthese).trim();
              
              // Extraire l'immatriculation
              String immat = reste.substring(indexParenthese);
              _immatriculationVehiculePlusRentable = immat.replaceAll('(', '').replaceAll(')', '').trim();
            } else {
              _modeleVehiculePlusRentable = reste;
            }
          }
        }
        
        _montantVehiculePlusRentable = vehiculePlusRentable.value;
        _pourcentageVehiculePlusRentable = _chiffrePeriodeSelectionnee > 0 
            ? (vehiculePlusRentable.value / _chiffrePeriodeSelectionnee) * 100 
            : 0;
      });
    }
  }

  bool _estDansPeriodeSelectionnee(DateTime date) {
    // Vérifier l'année sélectionnée
    if (date.year.toString() != _selectedYear) {
      return false;
    }
    
    // Vérifier le mois sélectionné si on est dans l'onglet Période (_tabController.index == 1)
    if (_tabController.index == 1 && _selectedMonth != 'Tous') {
      int moisSelectionne = getMonthNumber(_selectedMonth);
      if (moisSelectionne > 0 && date.month != moisSelectionne) {
        return false;
      }
    }
    
    // Pour la période sélectionnée, nous comparons maintenant avec la date actuelle
    // seulement si la période est 'Jour', 'Semaine', 'Mois' ou 'Trimestre'
    // Pour 'Année', nous utilisons simplement l'année sélectionnée
    
    if (_selectedPeriod == 'Année') {
      return date.year.toString() == _selectedYear;
    }
    
    // Pour les autres périodes, nous filtrons en fonction de la période sélectionnée
    // sans comparer à la date actuelle
    return true;
  }

  // Convertir le nom du mois en numéro
  int getMonthNumber(String monthName) {
    switch (monthName) {
      case 'Janvier': return 1;
      case 'Février': return 2;
      case 'Mars': return 3;
      case 'Avril': return 4;
      case 'Mai': return 5;
      case 'Juin': return 6;
      case 'Juillet': return 7;
      case 'Août': return 8;
      case 'Septembre': return 9;
      case 'Octobre': return 10;
      case 'Novembre': return 11;
      case 'Décembre': return 12;
      default: return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFF08004D),
        elevation: 0,
        toolbarHeight: kToolbarHeight,
        title: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorSize: TabBarIndicatorSize.label,
          tabs: [
            Tab(
              child: Text(
                'Résumé',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            Tab(
              child: Text(
                'Par période',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF08004D)))
          : _error != null
              ? Center(child: Text(_error!))
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildResumeTab(),
                    _buildPeriodeTab(),
                  ],
                ),
    );
  }
  
  Widget _buildResumeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sélecteurs de période et d'année
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 10,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Période: ', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: _selectedPeriod,
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedPeriod = newValue;
                          _calculerTousLesChiffres();
                        });
                      }
                    },
                    items: _periodes.map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Année: ', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: _selectedYear,
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedYear = newValue;
                          _calculerTousLesChiffres();
                        });
                      }
                    },
                    items: _years.map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.filter_list, color: Color(0xFF08004D)),
                onPressed: _afficherFiltresDialog,
                tooltip: 'Filtres de calcul',
              ),
            ],
          ),
          
          const SizedBox(height: 10),
          
          // Chiffre d'affaires de la période sélectionnée
          ChiffreAffaireCard(
            chiffrePeriodeSelectionnee: _chiffrePeriodeSelectionnee,
            vehiculePlusRentable: _vehiculePlusRentable,
            marqueVehiculePlusRentable: _marqueVehiculePlusRentable,
            modeleVehiculePlusRentable: _modeleVehiculePlusRentable,
            immatriculationVehiculePlusRentable: _immatriculationVehiculePlusRentable,
            montantVehiculePlusRentable: _montantVehiculePlusRentable,
            pourcentageVehiculePlusRentable: _pourcentageVehiculePlusRentable,
          ),
          
          const SizedBox(height: 24),
          
          // Répartition par véhicule
          RepartitionVehiculeCard(
            chiffreParVehicule: _chiffreParVehicule,
            chiffreTotal: _chiffreTotal,
            chiffrePeriodeSelectionnee: _chiffrePeriodeSelectionnee,
          ),
          
          const SizedBox(height: 24),
          
          // Évolution du chiffre d'affaires
          EvolutionChiffreCard(
            chiffreParPeriode: _chiffreParPeriode,
            anneeSelectionnee: int.parse(_selectedYear),
          ),
          
          const SizedBox(height: 24),
        ],
      ),
    );
  }
  
  Widget _buildPeriodeTab() {
    return PeriodeTab(
      selectedMonth: _selectedMonth,
      selectedYear: _selectedYear,
      years: _years,
      onMonthChanged: (String newMonth) {
        setState(() {
          _selectedMonth = newMonth;
          _calculerTousLesChiffres();
        });
      },
      onYearChanged: (String newYear) {
        setState(() {
          _selectedYear = newYear;
          _calculerTousLesChiffres();
        });
      },
      chiffrePeriodeSelectionnee: _chiffrePeriodeSelectionnee,
      onFilterPressed: _afficherFiltresDialog,
      chiffreParVehicule: _chiffreParVehicule,
      detailsVehicules: _detailsVehicules,
    );
  }

  // Afficher la boîte de dialogue des filtres
  void _afficherFiltresDialog() {
    afficherFiltresDialog(
      context: context,
      filtresCalcul: _filtresCalcul,
      onFiltresChanged: (newFiltres) {
        setState(() {
          _filtresCalcul = newFiltres;
        });
      },
      onApply: () {
        setState(() {
          _calculerTousLesChiffres();
        });
      },
    );
  }
}
