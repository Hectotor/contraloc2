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
    'prixLocation': true,
    'coutKmSupplementaires': true,
    'fraisNettoyageInterieur': true,
    'fraisNettoyageExterieur': true,
    'fraisCarburantManquant': true,
    'fraisRayuresDommages': true,
    'caution': true,
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
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final userData = userDoc.data();
      final bool isCollaborateur = userData != null && userData['role'] == 'collaborateur';
      final String? adminId = isCollaborateur ? userData['adminId'] as String? : null;
      final String userId = isCollaborateur && adminId != null ? adminId : user.uid;

      // Récupérer tous les contrats clôturés
      QuerySnapshot contratsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('chiffre_affaire')
          .get();

      // Récupérer tous les véhicules
      QuerySnapshot vehiculesSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('vehicules')
          .get();

      // Liste des véhicules
      List<String> vehicules = ['Tous'];
      for (var doc in vehiculesSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        String marque = data['marque'] ?? '';
        String modele = data['modele'] ?? '';
        String immatriculation = data['immatriculation'] ?? '';
        
        if (marque.isNotEmpty && modele.isNotEmpty) {
          vehicules.add('$marque $modele ($immatriculation)');
        }
      }

      // Traiter les contrats
      List<Map<String, dynamic>> contrats = [];
      double chiffreTotal = 0;
      Set<String> years = {};
      
      for (var doc in contratsSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        
        // Récupérer les informations du véhicule directement des données du contrat
        String marque = data['marque'] ?? '';
        String modele = data['modele'] ?? '';
        String immatriculation = data['immatriculation'] ?? '';
        String vehiculeInfoStr = '';
        
        if (marque.isNotEmpty && modele.isNotEmpty) {
          vehiculeInfoStr = '$marque $modele ($immatriculation)';
        }
        
        // Créer un objet vehiculeDetails à partir des données du contrat
        Map<String, dynamic> vehiculeDetails = {
          'marque': marque,
          'modele': modele,
          'immatriculation': immatriculation,
          'photoVehiculeUrl': data['photoVehiculeUrl'] ?? '',
        };
        
        // Récupérer les données financières
        double prixLocation = (data['prixLocation'] ?? 0.0).toDouble();
        double coutKmSupplementaires = (data['coutKmSupplementaires'] ?? 0.0).toDouble();
        double fraisNettoyageInterieur = (data['fraisNettoyageInterieur'] ?? 0.0).toDouble();
        double fraisNettoyageExterieur = (data['fraisNettoyageExterieur'] ?? 0.0).toDouble();
        double fraisCarburantManquant = (data['fraisCarburantManquant'] ?? 0.0).toDouble();
        double fraisRayuresDommages = (data['fraisRayuresDommages'] ?? 0.0).toDouble();
        double caution = (data['caution'] ?? 0.0).toDouble();
        double montantTotal = (data['montantTotal'] ?? 0.0).toDouble();
        
        // Récupérer la date de clôture
        DateTime dateCloture;
        try {
          dateCloture = DateTime.parse(data['dateCloture'] ?? DateTime.now().toIso8601String());
        } catch (e) {
          dateCloture = DateTime.now();
        }
        
        // Ajouter l'année à la liste des années disponibles
        years.add(dateCloture.year.toString());
        
        // Ajouter à la liste des contrats
        contrats.add({
          'vehiculeInfoStr': vehiculeInfoStr,
          'vehiculeDetails': vehiculeDetails,
          'prixLocation': prixLocation,
          'coutKmSupplementaires': coutKmSupplementaires,
          'fraisNettoyageInterieur': fraisNettoyageInterieur,
          'fraisNettoyageExterieur': fraisNettoyageExterieur,
          'fraisCarburantManquant': fraisCarburantManquant,
          'fraisRayuresDommages': fraisRayuresDommages,
          'caution': caution,
          'montantTotal': montantTotal,
          'dateCloture': dateCloture,
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
        _chiffreTotal = chiffreTotal;
        _years = sortedYears;
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
  
  void _calculerTousLesChiffres() {
    _calculerChiffreParPeriode();
    _calculerChiffreParVehicule();
    _calculerStatistiques();
  }
  
  void _calculerChiffreParPeriode() {
    Map<String, double> chiffreParPeriode = {};
    double chiffrePeriodeSelectionnee = 0;
    
    for (var contrat in _contrats) {
      DateTime dateCloture = contrat['dateCloture'];
      double montant = 0;
      if (_filtresCalcul['prixLocation']!) montant += contrat['prixLocation'];
      if (_filtresCalcul['coutKmSupplementaires']!) montant += contrat['coutKmSupplementaires'];
      if (_filtresCalcul['fraisNettoyageInterieur']!) montant += contrat['fraisNettoyageInterieur'];
      if (_filtresCalcul['fraisNettoyageExterieur']!) montant += contrat['fraisNettoyageExterieur'];
      if (_filtresCalcul['fraisCarburantManquant']!) montant += contrat['fraisCarburantManquant'];
      if (_filtresCalcul['fraisRayuresDommages']!) montant += contrat['fraisRayuresDommages'];
      if (_filtresCalcul['caution']!) montant += contrat['caution'];
      
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
      DateTime dateCloture = contrat['dateCloture'];
      if (!_estDansPeriodeSelectionnee(dateCloture)) {
        continue;
      }
      
      String vehiculeInfoStr = contrat['vehiculeInfoStr'] ?? '';
      if (vehiculeInfoStr.isEmpty) continue;
      
      // Récupérer les détails du véhicule
      Map<String, dynamic> vehiculeDetails = contrat['vehiculeDetails'] ?? {};
      
      // Calculer le montant en fonction des filtres sélectionnés
      double montant = 0;
      if (_filtresCalcul['prixLocation'] == true) {
        montant += contrat['prixLocation'] ?? 0;
      }
      if (_filtresCalcul['coutKmSupplementaires'] == true) {
        montant += contrat['coutKmSupplementaires'] ?? 0;
      }
      if (_filtresCalcul['fraisNettoyageInterieur'] == true) {
        montant += contrat['fraisNettoyageInterieur'] ?? 0;
      }
      if (_filtresCalcul['fraisNettoyageExterieur'] == true) {
        montant += contrat['fraisNettoyageExterieur'] ?? 0;
      }
      if (_filtresCalcul['fraisCarburantManquant'] == true) {
        montant += contrat['fraisCarburantManquant'] ?? 0;
      }
      if (_filtresCalcul['fraisRayuresDommages'] == true) {
        montant += contrat['fraisRayuresDommages'] ?? 0;
      }
      if (_filtresCalcul['caution'] == true) {
        montant += contrat['caution'] ?? 0;
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
    
    if (_selectedPeriod == 'Jour') {
      return DateFormat('yyyy-MM-dd').format(date) == DateFormat('yyyy-MM-dd').format(DateTime.now());
    } else if (_selectedPeriod == 'Semaine') {
      int weekNumber = ((date.difference(DateTime(date.year, 1, 1)).inDays) / 7).floor() + 1;
      int currentWeekNumber = ((DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays) / 7).floor() + 1;
      return weekNumber == currentWeekNumber && date.year == DateTime.now().year;
    } else if (_selectedPeriod == 'Mois') {
      return DateFormat('yyyy-MM').format(date) == DateFormat('yyyy-MM').format(DateTime.now());
    } else if (_selectedPeriod == 'Trimestre') {
      int trimestre = ((date.month - 1) / 3).floor() + 1;
      int currentTrimestre = ((DateTime.now().month - 1) / 3).floor() + 1;
      return trimestre == currentTrimestre && date.year == DateTime.now().year;
    } else if (_selectedPeriod == 'Année') {
      return DateFormat('yyyy').format(date) == _selectedYear;
    }
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
          tabs: const [
            Tab(text: 'Résumé'),
            Tab(text: 'Par période'),
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PeriodeTab(
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
          ),
        ],
      ),
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
