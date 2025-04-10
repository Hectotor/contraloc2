import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AccessAdmin {
  static Future<Map<String, dynamic>> getAdminInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return {};
    
    // Récupérer les données de l'utilisateur pour vérifier s'il est collaborateur
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get(GetOptions(source: Source.server));

    if (!userDoc.exists) {
      print('❌ Document utilisateur non trouvé');
      return {};
    }

    final userData = userDoc.data() ?? {};
    print('✅ Données utilisateur: $userData');
    
    // Vérifier si c'est un collaborateur
    final isCollaborateur = userData['role']?.toString() == 'collaborateur';
    final adminId = isCollaborateur ? userData['adminId']?.toString() : user.uid;
    print('👤 Role collaborateur: $isCollaborateur');
    print('👤 Admin ID: $adminId');
    
    if (adminId == null) {
      print('❌ Admin ID non trouvé');
      return {};
    }

    // Récupérer les données d'authentification de l'admin
    final adminAuthDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(adminId)
        .collection('authentification')
        .doc(adminId)
        .get(GetOptions(source: Source.server));

    if (!adminAuthDoc.exists) {
      print('❌ Document authentification admin non trouvé');
      return {};
    }

    final adminAuthData = adminAuthDoc.data() ?? {};
    
    final result = {
      'nomEntreprise': adminAuthData['nomEntreprise'] as String?,
      'logoUrl': adminAuthData['logoUrl'] as String?,
      'adresseEntreprise': adminAuthData['adresse'] as String?,
      'telephoneEntreprise': adminAuthData['telephone'] as String?,
      'siretEntreprise': adminAuthData['siret'] as String?,
    };
    
    return result;
  }
}
