import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ContractLimitManager {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Vérifier la limite mensuelle de contrats
  Future<bool> checkMonthlyContractLimit() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    
    try {
      // Vérifier si l'utilisateur est un collaborateur
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      
      String userId = user.uid;
      
      if (userDoc.exists && userDoc.data()?['role'] == 'collaborateur') {
        // C'est un collaborateur, récupérer l'ID de l'admin
        print('👥 Utilisateur collaborateur détecté pour vérification de limite');
        
        final adminId = userDoc.data()?['adminId'];
        if (adminId != null) {
          print('👥 Administrateur associé: $adminId');
          userId = adminId; // Utiliser l'ID de l'admin pour vérifier les limites
        }
      }
      
      // Récupérer la limite de contrats de l'utilisateur (admin ou collaborateur)
      final authDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('authentification')
          .doc(userId)
          .get();

      final cb_limite_contrat = authDoc.data()?['cb_limite_contrat'] ?? 10;
      
      int limiteContrat = 10; // Limite par défaut
      
      // Si cb_limite_contrat est 999, on garde cette limite illimitée
      if (cb_limite_contrat == 999) {
        limiteContrat = 999;
      } else {
        // Si cb_limite_contrat est 10, on vérifie limiteContrat
        final limiteContratTemp = authDoc.data()?['limiteContrat'] ?? 10;
        // Si limiteContrat est 999, on prend 999, sinon on garde 10
        if (limiteContratTemp == 999) {
          limiteContrat = 999;
        }
      }

      // Calculer le début et la fin du mois en cours
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0);

      // Compter les contrats créés ce mois-ci en utilisant la collection 'locations'
      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('locations')
          .where('dateCreation', isGreaterThanOrEqualTo: startOfMonth)
          .where('dateCreation', isLessThanOrEqualTo: endOfMonth)
          .get();

      final nombreContratsMois = querySnapshot.docs.length;
      print(
          '📊 Nombre de contrats ce mois: $nombreContratsMois sur $limiteContrat autorisés');

      return nombreContratsMois < limiteContrat;
    } catch (e) {
      print('❌ Erreur vérification limite contrats: $e');
      return false;
    }
  }
}
