import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AccessAdmin {
  /// Récupérer les informations de l'entreprise pour l'utilisateur connecté
  /// Si l'utilisateur est un collaborateur, récupérer les informations de son administrateur
  static Future<Map<String, dynamic>> getAdminInfo() async {
    try {
      print('Récupération des informations de l\'entreprise...');
      
      // Vérifier si l'utilisateur est connecté
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('❌ Aucun utilisateur connecté');
        return {};
      }

      final uid = user.uid;
      print('✅ Utilisateur connecté: $uid');

      // Essayer d'abord la sous-collection authentification, qui fonctionne dans les cas connus
      try {
        print('🔓 Accès direct à la sous-collection authentification...');
        final authDocRef = FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('authentification')
              .doc(uid);
        
        final authDoc = await authDocRef.get(const GetOptions(source: Source.server));
        
        if (authDoc.exists) {
          final authData = authDoc.data() ?? {};
          print('✅ Document authentification trouvé!');
          
          // Vérifier si c'est un collaborateur ou s'il contient directement les infos d'entreprise
          final isCollaborateur = authData['role'] == 'collaborateur' || authData['isCollaborateur'] == true;
          final adminId = authData['adminId'] as String?;
          
          // S'il contient des infos d'entreprise, les utiliser directement
          if (_containsEnterpriseInfo(authData)) {
            print('✅ Informations d\'entreprise trouvées directement dans authentification');
            return _formatEnterpriseInfo(authData);
          }
          
          // S'il s'agit d'un collaborateur, chercher les infos de l'admin
          if (isCollaborateur && adminId != null && adminId != uid) {
            print('👥 Collaborateur détecté via authentification - Récupération des infos de l\'admin: $adminId');
            return await _getAdminInfoById(adminId);
          }
        } else {
          print('❌ Document authentification non trouvé, tentative alternative...');
        }
      } catch (e) {
        print('⚠️ Erreur lors de l\'accès à l\'authentification: $e');
      }

      // Si authentification n'a pas fonctionné, vérifier le document utilisateur principal
      try {
        print('🔍 Tentative via le document utilisateur principal...');
        final userDocRef = FirebaseFirestore.instance.collection('users').doc(uid);
        final userDoc = await userDocRef.get(const GetOptions(source: Source.server));
        
        if (userDoc.exists) {
          final userData = userDoc.data() ?? {};
          
          // S'il contient des infos d'entreprise, les utiliser directement
          if (_containsEnterpriseInfo(userData)) {
            print('✅ Informations d\'entreprise trouvées directement dans le document utilisateur');
            return _formatEnterpriseInfo(userData);
          }
          
          // Vérifier si c'est un collaborateur
          final isCollaborateur = userData['role'] == 'collaborateur';
          final adminId = userData['adminId'] as String?;
          
          if (isCollaborateur && adminId != null) {
            print('👥 Collaborateur détecté - Récupération des infos de l\'admin: $adminId');
            return await _getAdminInfoById(adminId);
          }
        } else {
          print('❌ Document utilisateur principal non trouvé');
        }
      } catch (e) {
        print('⚠️ Erreur lors de l\'accès au document utilisateur: $e');
      }

      // Tentative via la collection company
      try {
        print('🔍 Tentative d\'accès à la collection company...');
        final companyDocRef = FirebaseFirestore.instance.collection('company').doc(uid);
        final companyDoc = await companyDocRef.get(const GetOptions(source: Source.server));
        
        if (companyDoc.exists) {
          final companyData = companyDoc.data() ?? {};
          print('✅ Document company trouvé!');
          return _formatEnterpriseInfo(companyData);
        } else {
          print('❌ Document company non trouvé');
        }
      } catch (e) {
        print('⚠️ Erreur lors de la tentative d\'accès à la collection company: $e');
      }

      print('❌ Aucune information d\'entreprise n\'a pu être trouvée malgré toutes les tentatives');
      return {};
    } catch (e) {
      print('❌ Erreur globale lors de la récupération des informations d\'entreprise: $e');
      return {};
    }
  }
  
  /// Récupérer les informations d'entreprise pour un administrateur spécifique
  static Future<Map<String, dynamic>> _getAdminInfoById(String adminId) async {
    try {
      // Essayer d'abord la sous-collection authentification de l'admin
      try {
        print('🔍 Tentative via la sous-collection authentification de l\'admin...');
        final adminAuthDocRef = FirebaseFirestore.instance
            .collection('users')
            .doc(adminId)
            .collection('authentification')
            .doc(adminId);
        
        final adminAuthDoc = await adminAuthDocRef.get(const GetOptions(source: Source.server));
        if (adminAuthDoc.exists) {
          final adminAuthData = adminAuthDoc.data() ?? {};
          print('✅ Document authentification admin trouvé!');
          return _formatEnterpriseInfo(adminAuthData);
        } else {
          print('❌ Document authentification admin non trouvé');
        }
      } catch (e) {
        print('⚠️ Erreur lors de l\'accès à l\'authentification admin: $e');
      }
      
      // Essayer ensuite le document admin principal
      try {
        print('🔍 Tentative via le document admin principal...');
        final adminDocRef = FirebaseFirestore.instance.collection('users').doc(adminId);
        final adminDoc = await adminDocRef.get(const GetOptions(source: Source.server));
        
        if (adminDoc.exists) {
          final adminData = adminDoc.data() ?? {};
          if (_containsEnterpriseInfo(adminData)) {
            print('✅ Informations d\'entreprise trouvées directement dans le document admin');
            return _formatEnterpriseInfo(adminData);
          } else {
            print('❌ Document admin ne contient pas d\'informations d\'entreprise');
          }
        } else {
          print('❌ Document admin principal non trouvé');
        }
      } catch (e) {
        print('⚠️ Erreur lors de l\'accès au document admin: $e');
      }
      
      // Finalement essayer /company/{adminId}
      try {
        print('🔍 Tentative d\'accès à la collection company pour l\'admin...');
        final companyDocRef = FirebaseFirestore.instance.collection('company').doc(adminId);
        final companyDoc = await companyDocRef.get(const GetOptions(source: Source.server));
        
        if (companyDoc.exists) {
          final companyData = companyDoc.data() ?? {};
          print('✅ Document company admin trouvé!');
          return _formatEnterpriseInfo(companyData);
        } else {
          print('❌ Document company admin non trouvé');
        }
      } catch (e) {
        print('⚠️ Erreur lors de la tentative d\'accès à la collection company admin: $e');
      }
      
      print('❌ Aucune information d\'entreprise pour l\'admin $adminId n\'a pu être trouvée');
      return {};
    } catch (e) {
      print('❌ Erreur globale lors de la récupération des informations d\'entreprise pour l\'admin: $e');
      return {};
    }
  }
  
  /// Formate les informations d'entreprise à partir des données d'authentification
  static Map<String, dynamic> _formatEnterpriseInfo(Map<String, dynamic> authData) {
    // Tenter plusieurs noms de champ possibles pour maximiser les chances de trouver les données
    final result = {
      'nomEntreprise': authData['nomEntreprise'] as String? ?? authData['nom_entreprise'] as String? ?? authData['nom'] as String? ?? '',
      'logoUrl': authData['logoUrl'] as String? ?? authData['logo_url'] as String? ?? authData['logo'] as String? ?? '',
      'adresseEntreprise': authData['adresseEntreprise'] as String? ?? authData['adresse'] as String? ?? '',
      'telephoneEntreprise': authData['telephoneEntreprise'] as String? ?? authData['telephone'] as String? ?? '',
      'siretEntreprise': authData['siretEntreprise'] as String? ?? authData['siret'] as String? ?? '',
    };
    
    print('Informations entreprise récupérées:');
    print('Nom: ${result['nomEntreprise']}');
    print('Logo: ${result['logoUrl']}');
    print('Adresse: ${result['adresseEntreprise']}');
    print('Téléphone: ${result['telephoneEntreprise']}');
    print('SIRET: ${result['siretEntreprise']}');
    
    return result;
  }
  
  /// Vérifie si un document contient des informations d'entreprise
  static bool _containsEnterpriseInfo(Map<String, dynamic> data) {
    return data.containsKey('nomEntreprise') || 
           data.containsKey('nom_entreprise') || 
           (data.containsKey('adresse') && (data.containsKey('siret') || data.containsKey('telephone')));
  }
}
