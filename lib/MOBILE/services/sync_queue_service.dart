import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_util.dart';

/// Service de file d'attente pour synchroniser les opérations qui ont échoué
class SyncQueueService {
  static final SyncQueueService _instance = SyncQueueService._internal();
  factory SyncQueueService() => _instance;
  SyncQueueService._internal();
  
  // Utiliser SharedPreferences pour stocker la file d'attente
  Future<void> addToQueue(String contratId, Map<String, dynamic> updateData) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Récupérer la file d'attente existante ou créer une nouvelle
    final queueString = prefs.getString('sync_queue') ?? '[]';
    List<Map<String, dynamic>> queue = List<Map<String, dynamic>>.from(
      jsonDecode(queueString).map((x) => Map<String, dynamic>.from(x))
    );
    
    // Ajouter la nouvelle opération
    queue.add({
      'contratId': contratId,
      'updateData': updateData,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'type': 'clotureContract'
    });
    
    // Sauvegarder la file d'attente mise à jour
    await prefs.setString('sync_queue', jsonEncode(queue));
    
    print('\u{1F4CB} Contrat ajouté à la file d\'attente de synchronisation: $contratId');
  }
  
  // Traiter la file d'attente
  Future<void> processQueue() async {
    final prefs = await SharedPreferences.getInstance();
    final queueString = prefs.getString('sync_queue') ?? '[]';
    List<Map<String, dynamic>> queue = List<Map<String, dynamic>>.from(
      jsonDecode(queueString).map((x) => Map<String, dynamic>.from(x))
    );
    
    if (queue.isEmpty) return;
    
    print('\u{1F504} Traitement de ${queue.length} opérations en attente');
    List<Map<String, dynamic>> remainingQueue = [];
    
    for (var operation in queue) {
      try {
        if (operation['type'] == 'clotureContract') {
          final authData = await AuthUtil.getAuthData();
          final targetId = authData['adminId'] as String;
          
          try {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(targetId)
                .collection('locations')
                .doc(operation['contratId'])
                .set(
                  Map<String, dynamic>.from(operation['updateData']),
                  SetOptions(merge: true)
                );
            print('\u{2705} Opération en file d\'attente traitée: ${operation['contratId']}');
          } catch (e) {
            print('❌ Erreur lors du traitement: $e - contratId: ${operation['contratId']}');
            remainingQueue.add(operation);
          }
          
          // Si l'opération n'est pas dans remainingQueue, c'est qu'elle a réussi
          if (!remainingQueue.contains(operation)) {
            print('\u{2705} Opération en file d\'attente traitée: ${operation['contratId']}');
          }
        }
      } catch (e) {
        print('\u{274C} Erreur lors du traitement de l\'opération: $e');
        remainingQueue.add(operation);
      }
    }
    
    // Mettre à jour la file d'attente
    await prefs.setString('sync_queue', jsonEncode(remainingQueue));
    print('\u{1F4CB} File d\'attente mise à jour: ${remainingQueue.length} opérations restantes');
  }
  
  // Vérifier si des opérations sont en attente pour un contrat spécifique
  Future<bool> hasPendingOperations(String contratId) async {
    final prefs = await SharedPreferences.getInstance();
    final queueString = prefs.getString('sync_queue') ?? '[]';
    List<Map<String, dynamic>> queue = List<Map<String, dynamic>>.from(
      jsonDecode(queueString).map((x) => Map<String, dynamic>.from(x))
    );
    
    return queue.any((operation) => operation['contratId'] == contratId);
  }
}
