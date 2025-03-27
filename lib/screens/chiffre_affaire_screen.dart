import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class ChiffreAffaireScreen extends StatefulWidget {
  const ChiffreAffaireScreen({Key? key}) : super(key: key);

  @override
  State<ChiffreAffaireScreen> createState() => _ChiffreAffaireScreenState();
}

class _ChiffreAffaireScreenState extends State<ChiffreAffaireScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String _selectedPeriod = 'Mois';
  String _selectedVehicule = 'Tous';
  String _selectedYear = DateTime.now().year.toString();
  
  List<Map<String, dynamic>> _contrats = [];
  List<String> _vehicules = ['Tous'];
  List<String> _years = [];
  
  // Données calculées
  Map<String, double> _chiffreParVehicule = {};
  Map<String, double> _chiffreParPeriode = {};
  double _chiffreTotal = 0;
  double _chiffrePeriodeSelectionnee = 0;
  
  // Statistiques
  String _vehiculePlusRentable = '';
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
        
        // Récupérer les informations du véhicule
        Map<String, dynamic> vehiculeDetails = data['vehiculeDetails'] as Map<String, dynamic>? ?? {};
        String vehiculeInfoStr = data['vehiculeInfoStr'] ?? '';
        
        // Si vehiculeInfoStr est vide, essayer de le construire à partir de vehiculeDetails
        if (vehiculeInfoStr.isEmpty) {
          String marque = vehiculeDetails['marque'] ?? '';
          String modele = vehiculeDetails['modele'] ?? '';
          String immatriculation = vehiculeDetails['immatriculation'] ?? '';
          vehiculeInfoStr = '$marque $modele ($immatriculation)';
        }
        
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
          'contratId': data['contratId'] ?? '',
        });
        
        // Ajouter au chiffre d'affaire total
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
        _vehicules = vehicules;
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
      double montant = contrat['montantTotal'];
      String vehiculeInfo = contrat['vehiculeInfoStr'];
      
      // Filtrer par véhicule si nécessaire
      if (_selectedVehicule != 'Tous' && vehiculeInfo != _selectedVehicule) {
        continue;
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
      
      chiffrePeriodeSelectionnee += montant;
    }
    
    setState(() {
      _chiffreParPeriode = chiffreParPeriode;
      _chiffrePeriodeSelectionnee = chiffrePeriodeSelectionnee;
    });
  }
  
  void _calculerChiffreParVehicule() {
    Map<String, double> chiffreParVehicule = {};
    
    for (var contrat in _contrats) {
      DateTime dateCloture = contrat['dateCloture'];
      double montant = contrat['montantTotal'];
      String vehiculeInfo = contrat['vehiculeInfoStr'];
      
      // Filtrer par année si nécessaire
      if (dateCloture.year.toString() != _selectedYear) {
        continue;
      }
      
      // Filtrer par période si nécessaire
      bool inclure = true;
      if (_selectedPeriod == 'Jour') {
        inclure = DateFormat('yyyy-MM-dd').format(dateCloture) == DateFormat('yyyy-MM-dd').format(DateTime.now());
      } else if (_selectedPeriod == 'Semaine') {
        int weekNumber = ((dateCloture.difference(DateTime(dateCloture.year, 1, 1)).inDays) / 7).floor() + 1;
        int currentWeekNumber = ((DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays) / 7).floor() + 1;
        inclure = weekNumber == currentWeekNumber && dateCloture.year == DateTime.now().year;
      } else if (_selectedPeriod == 'Mois') {
        inclure = DateFormat('yyyy-MM').format(dateCloture) == DateFormat('yyyy-MM').format(DateTime.now());
      } else if (_selectedPeriod == 'Trimestre') {
        int trimestre = ((dateCloture.month - 1) / 3).floor() + 1;
        int currentTrimestre = ((DateTime.now().month - 1) / 3).floor() + 1;
        inclure = trimestre == currentTrimestre && dateCloture.year == DateTime.now().year;
      } else if (_selectedPeriod == 'Année') {
        inclure = DateFormat('yyyy').format(dateCloture) == _selectedYear;
      }
      
      if (!inclure) continue;
      
      if (chiffreParVehicule.containsKey(vehiculeInfo)) {
        chiffreParVehicule[vehiculeInfo] = (chiffreParVehicule[vehiculeInfo] ?? 0) + montant;
      } else {
        chiffreParVehicule[vehiculeInfo] = montant;
      }
    }
    
    setState(() {
      _chiffreParVehicule = chiffreParVehicule;
    });
  }
  
  void _calculerStatistiques() {
    // Trouver le véhicule le plus rentable
    if (_chiffreParVehicule.isNotEmpty) {
      MapEntry<String, double> vehiculePlusRentable = _chiffreParVehicule.entries
          .reduce((a, b) => a.value > b.value ? a : b);
      
      setState(() {
        _vehiculePlusRentable = vehiculePlusRentable.key;
        _montantVehiculePlusRentable = vehiculePlusRentable.value;
        _pourcentageVehiculePlusRentable = _chiffrePeriodeSelectionnee > 0 
            ? (vehiculePlusRentable.value / _chiffrePeriodeSelectionnee) * 100 
            : 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Chiffre d\'affaire', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF08004D),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
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
    final formatCurrency = NumberFormat.currency(locale: 'fr_FR', symbol: '€');
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sélecteurs de période et d'année
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
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
              const SizedBox(width: 24),
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

          
          const SizedBox(height: 10),
          
          // Chiffre d'affaires de la période sélectionnée
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chiffre d\'affaire',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    formatCurrency.format(_chiffrePeriodeSelectionnee),
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF08004D),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_vehiculePlusRentable.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        const Divider(),
                        const SizedBox(height: 8),
                        const Text(
                          'Véhicule le plus rentable:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(_vehiculePlusRentable),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              formatCurrency.format(_montantVehiculePlusRentable),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF08004D),
                              ),
                            ),
                            Text(
                              '${_pourcentageVehiculePlusRentable.toStringAsFixed(1)}% du total',
                              style: const TextStyle(
                                fontStyle: FontStyle.italic,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Répartition par véhicule
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Répartition par véhicule',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 300,
                    child: _chiffreParVehicule.isEmpty
                        ? const Center(child: Text('Aucune donnée disponible'))
                        : PieChart(
                            PieChartData(
                              sectionsSpace: 2,
                              centerSpaceRadius: 40,
                              sections: _buildPieSections(),
                              pieTouchData: PieTouchData(
                                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                                  // Interaction avec le graphique
                                },
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(height: 16),
                  // Légende du graphique
                  ..._buildPieChartLegend(),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Évolution du chiffre d'affaires
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Évolution du chiffre d\'affaire',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 300,
                    child: _chiffreParPeriode.isEmpty
                        ? const Center(child: Text('Aucune donnée disponible'))
                        : LineChart(
                            LineChartData(
                              gridData: FlGridData(show: true),
                              titlesData: FlTitlesData(
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 40,
                                    getTitlesWidget: (value, meta) {
                                      if (value == 0) return const Text('0€');
                                      return Text('${value.toInt()}€');
                                    },
                                  ),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 30,
                                    getTitlesWidget: (value, meta) {
                                      if (value % 1 == 0 && value >= 0 && value < _buildLineSpots().length) {
                                        return Text(value.toInt().toString());
                                      }
                                      return const Text('');
                                    },
                                  ),
                                ),
                                topTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                rightTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                              ),
                              borderData: FlBorderData(show: true),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: _buildLineSpots(),
                                  isCurved: true,
                                  color: const Color(0xFF08004D),
                                  barWidth: 4,
                                  isStrokeCapRound: true,
                                  dotData: FlDotData(show: true),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    color: const Color(0xFF08004D).withOpacity(0.2),
                                  ),
                                ),
                              ],
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
  
  // Méthode pour construire la légende du graphique en camembert
  List<Widget> _buildPieChartLegend() {
    final formatCurrency = NumberFormat.currency(locale: 'fr_FR', symbol: '€');
    List<MapEntry<String, double>> sortedEntries = _chiffreParVehicule.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    // Limiter à 5 entrées pour la lisibilité
    if (sortedEntries.length > 5) {
      double autresMontant = 0;
      for (int i = 5; i < sortedEntries.length; i++) {
        autresMontant += sortedEntries[i].value;
      }
      sortedEntries = sortedEntries.sublist(0, 5);
      if (autresMontant > 0) {
        sortedEntries.add(MapEntry('Autres', autresMontant));
      }
    }
    
    // Couleurs pour les sections
    final List<Color> colors = [
      const Color(0xFF08004D),
      const Color(0xFF1A237E),
      const Color(0xFF303F9F),
      const Color(0xFF3949AB),
      const Color(0xFF5C6BC0),
      const Color(0xFF7986CB),
    ];
    
    return sortedEntries.asMap().entries.map((entry) {
      final index = entry.key;
      final vehicule = entry.value.key;
      final montant = entry.value.value;
      final percentage = (montant / _chiffrePeriodeSelectionnee) * 100;
      
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: colors[index % colors.length],
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                vehicule,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              formatCurrency.format(montant),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF08004D),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${percentage.toStringAsFixed(1)}%',
              style: const TextStyle(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
  
  Widget _buildPeriodeTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
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
              const Spacer(),
              const Text('Véhicule: ', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: _selectedVehicule,
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedVehicule = newValue;
                      _calculerTousLesChiffres();
                    });
                  }
                },
                items: _vehicules.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(
                      value,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
              ),
              const Spacer(),
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
        ),
        // Affichage du chiffre d'affaires pour la période sélectionnée
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Chiffre d\'affaire total pour la période:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Text(
                    NumberFormat.currency(locale: 'fr_FR', symbol: '€').format(_chiffrePeriodeSelectionnee),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Color(0xFF08004D),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: _chiffreParPeriode.isEmpty
              ? const Center(child: Text('Aucune donnée disponible pour cette période'))
              : ListView(
                  children: _buildPeriodeListItems(),
                ),
        ),
      ],
    );
  }
  
  List<Widget> _buildPeriodeListItems() {
    final formatCurrency = NumberFormat.currency(locale: 'fr_FR', symbol: '€');
    List<MapEntry<String, double>> sortedEntries = _chiffreParPeriode.entries.toList()
      ..sort((a, b) => b.key.compareTo(b.key)); // Tri par date décroissante
    
    return sortedEntries.map((entry) {
      String periodeFormatee;
      
      if (_selectedPeriod == 'Jour') {
        // Convertir 2025-03-26 en mercredi 26 mars 2025
        DateTime date = DateFormat('yyyy-MM-dd').parse(entry.key);
        periodeFormatee = DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(date);
      } else if (_selectedPeriod == 'Semaine') {
        // Convertir 2025-W12 en semaine 12 de 2025
        String year = entry.key.split('-')[0];
        int weekNumber = int.parse(entry.key.split('-')[1].replaceFirst('S', ''));
        DateTime date = DateTime.parse('$year-01-01');
        periodeFormatee = 'Semaine $weekNumber de ${date.year}';
      } else if (_selectedPeriod == 'Mois') {
        // Convertir 2025-03 en mars 2025
        DateTime date = DateFormat('yyyy-MM').parse(entry.key);
        periodeFormatee = DateFormat('MMMM yyyy', 'fr_FR').format(date);
      } else if (_selectedPeriod == 'Trimestre') {
        // Convertir 2025-Q1 en trimestre 1 de 2025
        String year = entry.key.split('-')[0];
        int trimestre = int.parse(entry.key.split('-')[1].replaceFirst('T', ''));
        DateTime date = DateTime.parse('$year-01-01');
        periodeFormatee = 'Trimestre $trimestre de ${date.year}';
      } else {
        // Année reste telle quelle
        periodeFormatee = entry.key;
      }
      
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: ListTile(
          title: Text(
            periodeFormatee,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          trailing: Text(
            formatCurrency.format(entry.value),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(0xFF08004D),
            ),
          ),
        ),
      );
    }).toList();
  }
  
  List<PieChartSectionData> _buildPieSections() {
    List<MapEntry<String, double>> sortedEntries = _chiffreParVehicule.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    // Limiter à 5 sections pour la lisibilité
    if (sortedEntries.length > 5) {
      double autresMontant = 0;
      for (int i = 5; i < sortedEntries.length; i++) {
        autresMontant += sortedEntries[i].value;
      }
      sortedEntries = sortedEntries.sublist(0, 5);
      if (autresMontant > 0) {
        sortedEntries.add(MapEntry('Autres', autresMontant));
      }
    }
    
    // Couleurs pour les sections
    final List<Color> colors = [
      const Color(0xFF08004D),
      const Color(0xFF1A237E),
      const Color(0xFF303F9F),
      const Color(0xFF3949AB),
      const Color(0xFF5C6BC0),
      const Color(0xFF7986CB),
    ];
    
    return List.generate(sortedEntries.length, (index) {
      final entry = sortedEntries[index];
      final percentage = (entry.value / _chiffreTotal) * 100;
      
      return PieChartSectionData(
        color: colors[index % colors.length],
        value: entry.value,
        title: '${percentage.toStringAsFixed(1)}%',
        radius: 100,
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    });
  }
  
  List<FlSpot> _buildLineSpots() {
    List<MapEntry<String, double>> sortedEntries = _chiffreParPeriode.entries.toList()
      ..sort((a, b) => a.key.compareTo(a.key)); // Tri par date croissante
    
    // Limiter à 10 points pour la lisibilité
    if (sortedEntries.length > 10) {
      sortedEntries = sortedEntries.sublist(sortedEntries.length - 10);
    }
    
    return List.generate(sortedEntries.length, (index) {
      return FlSpot(index.toDouble(), sortedEntries[index].value);
    });
  }
}
