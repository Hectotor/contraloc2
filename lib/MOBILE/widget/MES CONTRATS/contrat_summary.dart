import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'vehicle_access_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

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
  DateTime? _lastUpdated;
  static const String _cacheKey = 'contrat_summary_cache';
  static const Duration _cacheValidity = Duration(minutes: 15);

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

  // Formatage de date en français
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inMinutes < 1) {
      return 'À l\'instant';
    } else if (diff.inHours < 1) {
      final minutes = diff.inMinutes;
      return '${minutes} ${minutes > 1 ? "minutes" : "minute"}';
    } else if (diff.inDays < 1) {
      final hours = diff.inHours;
      return '${hours} ${hours > 1 ? "heures" : "heure"}';
    } else if (diff.inDays < 2) {
      return 'Hier à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      return '${date.day} ${_getMonthName(date.month)} à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
  }

  // Renvoie le nom du mois en français
  String _getMonthName(int month) {
    const months = [
      'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
      'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'
    ];
    return months[month - 1];
  }

  @override
  void initState() {
    super.initState();
    print('ContratSummary: Initialisation');
    _loadFromCacheAndUpdate();
  }

  @override
  void dispose() {
    _saveToCache();
    super.dispose();
  }

  Future<void> _loadFromCacheAndUpdate() async {
    // Essayer de charger depuis le cache d'abord
    bool cacheLoaded = await _loadFromCache();
    
    // Si le cache n'est pas disponible ou expiré, charger depuis Firestore
    if (!cacheLoaded) {
      await _loadContractCounts();
    }
  }

  Future<bool> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheString = prefs.getString(_cacheKey);
      
      if (cacheString != null) {
        final cacheData = json.decode(cacheString);
        final lastUpdatedMillis = cacheData['lastUpdated'] as int;
        final lastUpdated = DateTime.fromMillisecondsSinceEpoch(lastUpdatedMillis);
        
        // Vérifier si le cache est encore valide
        if (DateTime.now().difference(lastUpdated) < _cacheValidity) {
          if (mounted) {
            setState(() {
              _activeContracts = cacheData['activeContracts'];
              _returnedContracts = cacheData['returnedContracts'];
              _reservedContracts = cacheData['reservedContracts'];
              _deletedActiveContracts = cacheData['deletedActiveContracts'];
              _deletedReturnedContracts = cacheData['deletedReturnedContracts'];
              _deletedReservedContracts = cacheData['deletedReservedContracts'];
              _lastUpdated = lastUpdated;
              _isLoading = false;
            });
            print('ContratSummary: Données chargées depuis le cache (mis à jour le ${_lastUpdated?.toLocal().toString().substring(0, 19)})');
          }
          return true;
        } else {
          print('ContratSummary: Cache expiré, chargement depuis Firestore');
        }
      }
    } catch (e) {
      print('ContratSummary: Erreur lors du chargement du cache: $e');
    }
    return false;
  }

  Future<void> _saveToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final cacheData = {
        'activeContracts': _activeContracts,
        'returnedContracts': _returnedContracts,
        'reservedContracts': _reservedContracts,
        'deletedActiveContracts': _deletedActiveContracts,
        'deletedReturnedContracts': _deletedReturnedContracts,
        'deletedReservedContracts': _deletedReservedContracts,
        'lastUpdated': now.millisecondsSinceEpoch,
      };
      await prefs.setString(_cacheKey, json.encode(cacheData));
      if (mounted) {
        setState(() => _lastUpdated = now);
        print('ContratSummary: Données mises en cache');
      }
    } catch (e) {
      print('ContratSummary: Erreur lors de la mise en cache: $e');
    }
  }

  Future<void> _loadContractCounts() async {
    print('ContratSummary: Début du chargement des contrats');
    if (!mounted) return;
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
          .get(const GetOptions(source: Source.server));
      print('ContratSummary: Nombre total de contrats en cours: ${activeSnapshot.docs.length}');
      
      if (mounted) {
        setState(() {
          _activeContracts = activeSnapshot.docs.length;
          print('ContratSummary: Contrats en cours = $_activeContracts');
        });
      }

      // Contracts en cours supprimés
      final deletedActiveSnapshot = await locationQuery
          .where('status', isEqualTo: 'en_cours')
          .where('statussupprime', isEqualTo: 'supprimé')
          .get(const GetOptions(source: Source.server));
      print('ContratSummary: Nombre de contrats en cours supprimés: ${deletedActiveSnapshot.docs.length}');
      
      if (mounted) {
        setState(() {
          _deletedActiveContracts = deletedActiveSnapshot.docs.length;
          print('ContratSummary: Dont $_deletedActiveContracts supprimés (en cours)');
          if (_deletedActiveContracts > 0) {
            _activeContracts -= _deletedActiveContracts;
            print('ContratSummary: Contrats en cours après déduction = $_activeContracts');
          }
        });
      }

      // Returned contracts
      final returnedSnapshot = await locationQuery
          .where('status', isEqualTo: 'restitue')
          .get(const GetOptions(source: Source.server));
      print('ContratSummary: Nombre total de contrats restitués: ${returnedSnapshot.docs.length}');
      
      if (mounted) {
        setState(() {
          _returnedContracts = returnedSnapshot.docs.length;
          print('ContratSummary: Contrats restitués = $_returnedContracts');
        });
      }

      // Returned contracts supprimés
      final deletedReturnedSnapshot = await locationQuery
          .where('status', isEqualTo: 'restitue')
          .where('statussupprime', isEqualTo: 'supprimé')
          .get(const GetOptions(source: Source.server));
      print('ContratSummary: Nombre de contrats restitués supprimés: ${deletedReturnedSnapshot.docs.length}');
      
      if (mounted) {
        setState(() {
          _deletedReturnedContracts = deletedReturnedSnapshot.docs.length;
          print('ContratSummary: Dont $_deletedReturnedContracts supprimés (restitués)');
          if (_deletedReturnedContracts > 0) {
            _returnedContracts -= _deletedReturnedContracts;
            print('ContratSummary: Contrats restitués après déduction = $_returnedContracts');
          }
        });
      }

      // Reserved contracts
      final reservedSnapshot = await locationQuery
          .where('status', isEqualTo: 'réservé')
          .get(const GetOptions(source: Source.server));
      print('ContratSummary: Nombre total de contrats réservés: ${reservedSnapshot.docs.length}');
      
      if (mounted) {
        setState(() {
          _reservedContracts = reservedSnapshot.docs.length;
          print('ContratSummary: Contrats réservés = $_reservedContracts');
        });
      }

      // Reserved contracts supprimés
      final deletedReservedSnapshot = await locationQuery
          .where('status', isEqualTo: 'réservé')
          .where('statussupprime', isEqualTo: 'supprimé')
          .get(const GetOptions(source: Source.server));
      print('ContratSummary: Nombre de contrats réservés supprimés: ${deletedReservedSnapshot.docs.length}');
      
      if (mounted) {
        setState(() {
          _deletedReservedContracts = deletedReservedSnapshot.docs.length;
          print('ContratSummary: Dont $_deletedReservedContracts supprimés (réservés)');
          if (_deletedReservedContracts > 0) {
            _reservedContracts -= _deletedReservedContracts;
            print('ContratSummary: Contrats réservés après déduction = $_reservedContracts');
          }
        });
      }

      if (mounted) {
        setState(() => _isLoading = false);
        print('ContratSummary: Chargement terminé');
      }
      
      // Sauvegarder les données dans le cache
      _saveToCache();
    } catch (e) {
      print('ContratSummary: Erreur lors du chargement: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Erreur lors du chargement des données: ${e.toString()}';
        });
      }
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (_lastUpdated != null)
                      Expanded(
                        child: Text(
                          'Dernière mise à jour: ${_formatDate(_lastUpdated!)}',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ),
                    IconButton(
                      icon: const Icon(Icons.refresh, size: 20),
                      onPressed: () {
                        print('ContratSummary: Rafraîchissement manuel');
                        _loadContractCounts();
                      },
                      tooltip: 'Rafraîchir',
                      color: _primaryColor,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
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
