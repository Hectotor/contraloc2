import 'package:ContraLoc/widget/CREATION%20DE%20CONTRAT/client.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; 
import 'package:ContraLoc/widget/MES%20CONTRATS/vehicle_access_manager.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CalendarScreen extends StatefulWidget {
  final Function(int)? onEventsCountChanged;

  CalendarScreen({Key? key, this.onEventsCountChanged}) : super(key: key);

  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  String selectedFilter = 'Tous';
  final Map<String, String?> _photoUrlCache = {}; 
  late VehicleAccessManager _vehicleAccessManager;
  String? _targetUserId;
  bool _isInitialized = false;
  
  @override
  void initState() {
    super.initState();
    _vehicleAccessManager = VehicleAccessManager();
    _initializeAccess();
  }
  
  Future<void> _initializeAccess() async {
    await _vehicleAccessManager.initialize();
    _targetUserId = _vehicleAccessManager.getTargetUserId();
    _isInitialized = true;
    if (mounted) {
      setState(() {});
    }
  }

  Stream<QuerySnapshot> _getReservedContractsStream() {
    if (!_isInitialized) {
      return Stream.fromFuture(
        Future(() async {
          await _initializeAccess();
          
          final effectiveUserId = _targetUserId ?? FirebaseAuth.instance.currentUser?.uid;
          if (effectiveUserId == null) {
            return FirebaseFirestore.instance.collection('empty').limit(0).get();
          }
          
          final snapshot = await FirebaseFirestore.instance
              .collection('users')
              .doc(effectiveUserId)
              .collection('locations')
              .where('status', isEqualTo: 'réservé')
              .orderBy('dateCreation', descending: true)
              .get();
              
          return snapshot;
        })
      ).asyncExpand((snapshot) {
        final effectiveUserId = _targetUserId ?? FirebaseAuth.instance.currentUser?.uid;
        if (effectiveUserId == null) {
          return Stream.empty();
        }
        
        return FirebaseFirestore.instance
            .collection('users')
            .doc(effectiveUserId)
            .collection('locations')
            .where('status', isEqualTo: 'réservé')
            .orderBy('dateCreation', descending: true)
            .snapshots();
      });
    }
    
    final effectiveUserId = _targetUserId ?? FirebaseAuth.instance.currentUser?.uid;
    if (effectiveUserId == null) {
      return Stream.empty();
    }
    
    return FirebaseFirestore.instance
        .collection('users')
        .doc(effectiveUserId)
        .collection('locations')
        .where('status', isEqualTo: 'réservé')
        .orderBy('dateCreation', descending: true)
        .snapshots();
  }
  
  Future<void> _deleteReservedContract(String contratId) async {
    final effectiveUserId = _targetUserId ?? FirebaseAuth.instance.currentUser?.uid;
    if (effectiveUserId == null) {
      throw Exception("Utilisateur non connecté");
    }
    
    await FirebaseFirestore.instance
        .collection('users')
        .doc(effectiveUserId)
        .collection('locations')
        .doc(contratId)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF08004D).withOpacity(0.05), Colors.white],
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: _getReservedContractsStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF08004D)),
                ),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                    const SizedBox(height: 16),
                    const Text(
                      "Erreur de chargement des contrats",
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.calendar_today, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    const Text(
                      "Aucun contrat réservé",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              );
            }

            final contrats = snapshot.data!.docs;
            
            contrats.sort((a, b) {
              final dateA = (a.data() as Map<String, dynamic>)['dateReservation'] as Timestamp;
              final dateB = (b.data() as Map<String, dynamic>)['dateReservation'] as Timestamp;
              return dateA.compareTo(dateB); 
            });

            if (widget.onEventsCountChanged != null) {
              widget.onEventsCountChanged!(contrats.length);
            }

            return Column(
              children: [
                Container(
                  margin: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                child: Material(
                                  color: selectedFilter == 'Tous' 
                                      ? const Color(0xFF08004D) 
                                      : Colors.white,
                                  borderRadius: const BorderRadius.horizontal(
                                    left: Radius.circular(15),
                                  ),
                                  child: InkWell(
                                    onTap: () => setState(() => selectedFilter = 'Tous'),
                                    borderRadius: const BorderRadius.horizontal(
                                      left: Radius.circular(15),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      child: Text(
                                        'Tous',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: selectedFilter == 'Tous' 
                                              ? Colors.white 
                                              : Colors.black87,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                child: Material(
                                  color: selectedFilter == 'mois' 
                                      ? const Color(0xFF08004D) 
                                      : Colors.white,
                                  borderRadius: const BorderRadius.horizontal(
                                    right: Radius.circular(15),
                                  ),
                                  child: InkWell(
                                    onTap: () => setState(() => selectedFilter = 'mois'),
                                    borderRadius: const BorderRadius.horizontal(
                                      right: Radius.circular(15),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      child: Text(
                                        'Mois en cours',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: selectedFilter == 'mois' 
                                              ? Colors.white 
                                              : Colors.black87,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '(Appui long pour supprimer)',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 1),
                    itemCount: contrats.length,
                    itemBuilder: (context, index) {
                      final contrat = contrats[index];
                      final data = contrat.data() as Map<String, dynamic>;

                      if (selectedFilter == 'mois' && data['dateReservation'] != null) {
                        final dateReservation = (data['dateReservation'] as Timestamp).toDate();
                        final now = DateTime.now();
                        if (dateReservation.month != now.month || dateReservation.year != now.year) {
                          return Container();
                        }
                      }

                      return FutureBuilder<String?>(
                        future: _getVehiclePhotoUrl(data['immatriculation']),
                        builder: (context, snapshot) {
                          final photoUrl = snapshot.data;

                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Material(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              elevation: 2,
                              shadowColor: Colors.black.withOpacity(0.1),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ClientPage(
                                        marque: data['marque'],
                                        modele: data['modele'],
                                        immatriculation: data['immatriculation'],
                                        contratId: contrat.id,
                                      ),
                                    ),
                                  );
                                },
                                onLongPress: () => _showDeleteDialog(context, contrat.id),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      Hero(
                                        tag: 'vehicle_${contrat.id}',
                                        child: Container(
                                          width: 100,
                                          height: 100,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(12),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.1),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(12),
                                            child: photoUrl != null && photoUrl.isNotEmpty
                                                ? Image.network(
                                                    photoUrl,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (context, error, stackTrace) =>
                                                        _buildPlaceholderIcon(),
                                                  )
                                                : _buildPlaceholderIcon(),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "${data['nom'] ?? ''} ${data['prenom'] ?? ''}",
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF08004D),
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            _buildInfoRow(
                                              Icons.calendar_today,
                                              "Réservé pour le :\n${_formatDate(data['dateReservation'])}",
                                            ),
                                            const SizedBox(height: 4),
                                            _buildInfoRow(
                                              Icons.event_available,
                                              "Fin : ${data['dateFinTheorique']}",
                                            ),
                                            const SizedBox(height: 4),
                                            _buildInfoRow(
                                              Icons.directions_car,
                                              data['immatriculation'] ?? '',
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        Icons.chevron_right,
                                        color: Colors.grey[400],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildPlaceholderIcon() {
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: Icon(
          Icons.directions_car,
          size: 40,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Icon(
            icon,
            size: 16,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return '';
    final date = (timestamp as Timestamp).toDate();
    return DateFormat('EEEE d MMMM yyyy à HH:mm', 'fr_FR').format(date).toLowerCase();
  }

  void _showDeleteDialog(BuildContext context, String contratId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.warning_rounded,
                    color: Colors.red[400],
                    size: 48,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Supprimer la réservation ?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF08004D),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Cette action est irréversible.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.grey[100],
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Annuler',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF08004D),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          _deleteReservedContract(contratId);
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Supprimer',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<String?> _getVehiclePhotoUrl(String immatriculation) async {
    final cacheKey = immatriculation;
    if (_photoUrlCache.containsKey(cacheKey)) {
      return _photoUrlCache[cacheKey];
    }

    final vehiculeDoc = await _vehicleAccessManager.getVehicleByImmatriculation(immatriculation);

    if (vehiculeDoc.docs.isNotEmpty) {
      final data = vehiculeDoc.docs.first.data();
      String? photoUrl;
      
      if (data != null && data is Map<String, dynamic>) {
        photoUrl = data['photoVehiculeUrl'] as String?;
      }
      
      _photoUrlCache[cacheKey] = photoUrl;
      return photoUrl;
    }
    return null;
  }
}
