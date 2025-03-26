import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../utils/collaborateur_util.dart';

class ChiffreAffaireScreen extends StatefulWidget {
  const ChiffreAffaireScreen({Key? key}) : super(key: key);

  @override
  State<ChiffreAffaireScreen> createState() => _ChiffreAffaireScreenState();
}

class _ChiffreAffaireScreenState extends State<ChiffreAffaireScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String _selectedPeriod = 'Jour';
  String _selectedVehicule = 'Tous';
  List<Map<String, dynamic>> _contrats = [];
  List<String> _vehicules = ['Tous'];
  Map<String, double> _chiffreParVehicule = {};
  Map<String, double> _chiffreParPeriode = {};
  double _chiffreTotal = 0;
  
  // Périodes disponibles
  final List<String> _periodes = ['Jour', 'Mois', 'Année'];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Vérifier si l'utilisateur est un collaborateur
      final isCollaborateur = await CollaborateurUtil.isCollaborateur();
      String userId = user.uid;
      String? adminId;

      if (isCollaborateur) {
        adminId = await CollaborateurUtil.getAdminId();
        if (adminId == null) return;
      }

      // Récupérer tous les contrats clôturés
      QuerySnapshot contratsSnapshot;
      if (isCollaborateur && adminId != null) {
        // Utiliser l'ID de l'admin pour les collaborateurs
        contratsSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(adminId)
            .collection('contrats')
            .where('statut', isEqualTo: 'cloture')
            .get();
      } else {
        // Pour les utilisateurs normaux
        contratsSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('contrats')
            .where('statut', isEqualTo: 'cloture')
            .get();
      }

      // Récupérer tous les véhicules
      QuerySnapshot vehiculesSnapshot;
      if (isCollaborateur && adminId != null) {
        vehiculesSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(adminId)
            .collection('vehicules')
            .get();
      } else {
        vehiculesSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('vehicules')
            .get();
      }

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
      
      for (var doc in contratsSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        
        // Récupérer les données essentielles
        String vehiculeId = data['vehiculeId'] ?? '';
        String vehiculeInfo = data['vehiculeInfo'] ?? '';
        double montantTotal = double.tryParse(data['montantTotal'] ?? '0') ?? 0;
        String dateFinEffective = data['dateFinEffectif'] ?? '';
        DateTime? dateFin;
        
        // Parser la date de fin
        if (dateFinEffective.isNotEmpty) {
          try {
            if (dateFinEffective.contains('à')) {
              dateFin = DateFormat('EEEE d MMMM yyyy à HH:mm', 'fr_FR').parse(dateFinEffective);
            } else {
              dateFin = DateTime.tryParse(dateFinEffective);
            }
          } catch (e) {
            print('Erreur de parsing de date: $e');
          }
        }
        
        if (dateFin != null) {
          contrats.add({
            'vehiculeId': vehiculeId,
            'vehiculeInfo': vehiculeInfo,
            'montantTotal': montantTotal,
            'dateFin': dateFin,
          });
          
          chiffreTotal += montantTotal;
        }
      }

      setState(() {
        _contrats = contrats;
        _vehicules = vehicules;
        _chiffreTotal = chiffreTotal;
        _isLoading = false;
      });
      
      // Calculer les chiffres par période et par véhicule
      _calculerChiffreParPeriode();
      _calculerChiffreParVehicule();
      
    } catch (e) {
      print('Erreur lors de la récupération des données: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _calculerChiffreParPeriode() {
    Map<String, double> chiffreParPeriode = {};
    
    for (var contrat in _contrats) {
      DateTime dateFin = contrat['dateFin'];
      double montant = contrat['montantTotal'];
      String vehiculeInfo = contrat['vehiculeInfo'];
      
      // Filtrer par véhicule si nécessaire
      if (_selectedVehicule != 'Tous' && vehiculeInfo != _selectedVehicule) {
        continue;
      }
      
      String periode;
      if (_selectedPeriod == 'Jour') {
        // Format: 2025-03-26
        periode = DateFormat('yyyy-MM-dd').format(dateFin);
      } else if (_selectedPeriod == 'Mois') {
        // Format: 2025-03
        periode = DateFormat('yyyy-MM').format(dateFin);
      } else {
        // Format: 2025
        periode = DateFormat('yyyy').format(dateFin);
      }
      
      if (chiffreParPeriode.containsKey(periode)) {
        chiffreParPeriode[periode] = (chiffreParPeriode[periode] ?? 0) + montant;
      } else {
        chiffreParPeriode[periode] = montant;
      }
    }
    
    setState(() {
      _chiffreParPeriode = chiffreParPeriode;
    });
  }
  
  void _calculerChiffreParVehicule() {
    Map<String, double> chiffreParVehicule = {};
    
    for (var contrat in _contrats) {
      DateTime dateFin = contrat['dateFin'];
      double montant = contrat['montantTotal'];
      String vehiculeInfo = contrat['vehiculeInfo'];
      
      // Filtrer par période si nécessaire
      bool inclure = true;
      if (_selectedPeriod == 'Jour') {
        inclure = DateFormat('yyyy-MM-dd').format(dateFin) == DateFormat('yyyy-MM-dd').format(DateTime.now());
      } else if (_selectedPeriod == 'Mois') {
        inclure = DateFormat('yyyy-MM').format(dateFin) == DateFormat('yyyy-MM').format(DateTime.now());
      } else if (_selectedPeriod == 'Année') {
        inclure = DateFormat('yyyy').format(dateFin) == DateFormat('yyyy').format(DateTime.now());
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
            Tab(text: 'Par véhicule'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF08004D)))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildResumeTab(),
                _buildPeriodeTab(),
                _buildVehiculeTab(),
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
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Chiffre d\'affaire total',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    formatCurrency.format(_chiffreTotal),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF08004D),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Basé sur tous les contrats clôturés',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
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
                    ),
                  ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Évolution récente',
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
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
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
    );
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
                      _calculerChiffreParPeriode();
                      _calculerChiffreParVehicule();
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
                      _calculerChiffreParPeriode();
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
            ],
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
  
  Widget _buildVehiculeTab() {
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
                      _calculerChiffreParVehicule();
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
        ),
        Expanded(
          child: _chiffreParVehicule.isEmpty
              ? const Center(child: Text('Aucune donnée disponible pour cette période'))
              : ListView(
                  children: _buildVehiculeListItems(),
                ),
        ),
      ],
    );
  }
  
  List<Widget> _buildPeriodeListItems() {
    final formatCurrency = NumberFormat.currency(locale: 'fr_FR', symbol: '€');
    List<MapEntry<String, double>> sortedEntries = _chiffreParPeriode.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key)); // Tri par date décroissante
    
    return sortedEntries.map((entry) {
      String periodeFormatee;
      
      if (_selectedPeriod == 'Jour') {
        // Convertir 2025-03-26 en mercredi 26 mars 2025
        DateTime date = DateFormat('yyyy-MM-dd').parse(entry.key);
        periodeFormatee = DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(date);
      } else if (_selectedPeriod == 'Mois') {
        // Convertir 2025-03 en mars 2025
        DateTime date = DateFormat('yyyy-MM').parse(entry.key);
        periodeFormatee = DateFormat('MMMM yyyy', 'fr_FR').format(date);
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
  
  List<Widget> _buildVehiculeListItems() {
    final formatCurrency = NumberFormat.currency(locale: 'fr_FR', symbol: '€');
    List<MapEntry<String, double>> sortedEntries = _chiffreParVehicule.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value)); // Tri par montant décroissant
    
    return sortedEntries.map((entry) {
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: ListTile(
          title: Text(
            entry.key,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            _getPeriodeLabel(),
            style: const TextStyle(fontSize: 12),
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
  
  String _getPeriodeLabel() {
    if (_selectedPeriod == 'Jour') {
      return 'Aujourd\'hui';
    } else if (_selectedPeriod == 'Mois') {
      return 'Ce mois-ci';
    } else {
      return 'Cette année';
    }
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
      ..sort((a, b) => a.key.compareTo(b.key)); // Tri par date croissante
    
    // Limiter à 10 points pour la lisibilité
    if (sortedEntries.length > 10) {
      sortedEntries = sortedEntries.sublist(sortedEntries.length - 10);
    }
    
    return List.generate(sortedEntries.length, (index) {
      return FlSpot(index.toDouble(), sortedEntries[index].value);
    });
  }
}
