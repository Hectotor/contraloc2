import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'vehicle_access_manager.dart';

class ContratSummary extends StatefulWidget {
  const ContratSummary({Key? key}) : super(key: key);

  @override
  State<ContratSummary> createState() => _ContratSummaryState();
}

class _ContratSummaryState extends State<ContratSummary> {
  final VehicleAccessManager _vehicleAccessManager = VehicleAccessManager.instance;
  int _activeContracts = 0;
  int _returnedContracts = 0;
  int _reservedContracts = 0;
  int _deletedActiveContracts = 0;
  int _deletedReturnedContracts = 0;
  int _deletedReservedContracts = 0;
  bool _isLoading = true;
  String? _error;

  // Couleur principale
  static const Color _primaryColor = Color(0xFF08004D);
  
  // Couleurs spécifiques pour chaque type de contrat
  static const Map<String, Color> _statusColors = {
    'en_cours': Color(0xFF1976D2),  // Bleu
    'restitue': Color(0xFF1B5E20),  // Vert
    'réservé': Color(0xFFE65100),   // Orange
  };
  
  // Icônes pour chaque type de contrat
  static const Map<String, IconData> _statusIcons = {
    'en_cours': Icons.directions_car,
    'restitue': Icons.check_circle,
    'réservé': Icons.calendar_today,
  };

  @override
  void initState() {
    super.initState();
    print('ContratSummary: Initialisation');
    _loadContractCounts();
  }

  Future<void> _loadContractCounts() async {
    print('ContratSummary: Début du chargement des contrats');
    setState(() => _isLoading = true);
    try {
      // Initialiser le VehicleAccessManager si nécessaire
      await _vehicleAccessManager.initialize();
      print('ContratSummary: VehicleAccessManager initialisé');
      
      // Obtenir l'ID utilisateur cible (utilisateur ou admin selon les droits)
      final targetUserId = _vehicleAccessManager.getTargetUserId();
      print('ContratSummary: TargetUserId = $targetUserId');
      
      if (targetUserId == null) {
        throw Exception('Impossible de déterminer l\'ID utilisateur');
      }

      final locationQuery = FirebaseFirestore.instance
          .collection('users')
          .doc(targetUserId)
          .collection('locations');
      print('ContratSummary: Requête Firestore configurée');

      // Active contracts
      final activeSnapshot = await locationQuery
          .where('status', isEqualTo: 'en_cours')
          .get(const GetOptions(source: Source.serverAndCache));
      print('ContratSummary: Nombre total de contrats en cours: ${activeSnapshot.docs.length}');
      setState(() {
        _activeContracts = activeSnapshot.docs.length;
        print('ContratSummary: Contrats en cours = $_activeContracts');
      });

      // Contracts en cours supprimés
      final deletedActiveSnapshot = await locationQuery
          .where('status', isEqualTo: 'en_cours')
          .where('statussupprime', isEqualTo: 'supprimé')
          .get(const GetOptions(source: Source.serverAndCache));
      print('ContratSummary: Nombre de contrats en cours supprimés: ${deletedActiveSnapshot.docs.length}');
      setState(() {
        _deletedActiveContracts = deletedActiveSnapshot.docs.length;
        print('ContratSummary: Dont $_deletedActiveContracts supprimés (en cours)');
        if (_deletedActiveContracts > 0) {
          _activeContracts -= _deletedActiveContracts;
          print('ContratSummary: Contrats en cours après déduction = $_activeContracts');
        }
      });

      // Returned contracts
      final returnedSnapshot = await locationQuery
          .where('status', isEqualTo: 'restitue')
          .get(const GetOptions(source: Source.serverAndCache));
      print('ContratSummary: Nombre total de contrats restitués: ${returnedSnapshot.docs.length}');
      setState(() {
        _returnedContracts = returnedSnapshot.docs.length;
        print('ContratSummary: Contrats restitués = $_returnedContracts');
      });

      // Returned contracts supprimés
      final deletedReturnedSnapshot = await locationQuery
          .where('status', isEqualTo: 'restitue')
          .where('statussupprime', isEqualTo: 'supprimé')
          .get(const GetOptions(source: Source.serverAndCache));
      print('ContratSummary: Nombre de contrats restitués supprimés: ${deletedReturnedSnapshot.docs.length}');
      setState(() {
        _deletedReturnedContracts = deletedReturnedSnapshot.docs.length;
        print('ContratSummary: Dont $_deletedReturnedContracts supprimés (restitués)');
        if (_deletedReturnedContracts > 0) {
          _returnedContracts -= _deletedReturnedContracts;
          print('ContratSummary: Contrats restitués après déduction = $_returnedContracts');
        }
      });

      // Reserved contracts
      final reservedSnapshot = await locationQuery
          .where('status', isEqualTo: 'réservé')
          .get(const GetOptions(source: Source.serverAndCache));
      print('ContratSummary: Nombre total de contrats réservés: ${reservedSnapshot.docs.length}');
      setState(() {
        _reservedContracts = reservedSnapshot.docs.length;
        print('ContratSummary: Contrats réservés = $_reservedContracts');
      });

      // Reserved contracts supprimés
      final deletedReservedSnapshot = await locationQuery
          .where('status', isEqualTo: 'réservé')
          .where('statussupprime', isEqualTo: 'supprimé')
          .get(const GetOptions(source: Source.serverAndCache));
      print('ContratSummary: Nombre de contrats réservés supprimés: ${deletedReservedSnapshot.docs.length}');
      setState(() {
        _deletedReservedContracts = deletedReservedSnapshot.docs.length;
        print('ContratSummary: Dont $_deletedReservedContracts supprimés (réservés)');
        if (_deletedReservedContracts > 0) {
          _reservedContracts -= _deletedReservedContracts;
          print('ContratSummary: Contrats réservés après déduction = $_reservedContracts');
        }
      });

      setState(() => _isLoading = false);
      print('ContratSummary: Chargement terminé');
    } catch (e) {
      print('ContratSummary: Erreur lors du chargement: $e');
      setState(() {
        _isLoading = false;
        _error = 'Erreur lors du chargement des données: ${e.toString()}';
      });
    }
  }

  Widget _buildInfoRow(String label, String value, {Color? color}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            "$label :",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: color ?? _primaryColor,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[800],
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildContractCard(String title, int count, int? deletedCount, String status) {
    final Color statusColor = _statusColors[status] ?? _primaryColor;
    final IconData statusIcon = _statusIcons[status] ?? Icons.assignment;
    
    return Card(
      elevation: 10,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: statusColor.withOpacity(0.3), width: 1),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        child: Row(
          children: [
            // Icône avec cercle coloré
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                statusIcon,
                size: 28,
                color: statusColor,
              ),
            ),
            const SizedBox(width: 16),
            // Informations
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    "Nombre", 
                    count.toString(),
                    color: statusColor,
                  ),
                  if (deletedCount != null && deletedCount > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: _buildInfoRow(
                        "Supprimés", 
                        deletedCount.toString(),
                        color: Colors.grey[600],
                      ),
                    ),
                ],
              ),
            ),
            // Nombre en grand
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            )
          else if (_error != null)
            Center(
              child: Text(
                _error!,
                style: const TextStyle(color: Colors.red),
              ),
            )
          else
            Column(
              children: [ 
                const SizedBox(height: 30),
                _buildContractCard(
                  "En cours",
                  _activeContracts,
                  _deletedActiveContracts,
                  'en_cours',
                ),
                const SizedBox(height: 16),
                _buildContractCard(
                  "Restitués",
                  _returnedContracts,
                  _deletedReturnedContracts,
                  'restitue',
                ),
                const SizedBox(height: 16),
                _buildContractCard(
                  "Réservés",
                  _reservedContracts,
                  _deletedReservedContracts,
                  'réservé',
                ),
              ],
            ),
        ],
      ),
    );
  }
}
