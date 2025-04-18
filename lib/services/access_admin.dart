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

      try {
        // IMPORTANT: Vérifier d'abord si l'utilisateur est un collaborateur
        // en cherchant son document principal
        print('🔓 Vérification si l\'utilisateur est un collaborateur...');
        final userDocRef = FirebaseFirestore.instance.collection('users').doc(uid);
        final userDoc = await userDocRef.get(const GetOptions(source: Source.server));
        
        if (userDoc.exists) {
          final userData = userDoc.data() ?? {};
          final isCollaborateur = userData['role'] == 'collaborateur';
          final adminId = userData['adminId'] as String?;
          
          print('👥 Utilisateur collaborateur? $isCollaborateur');
          print('👥 Admin ID: $adminId');
          
          if (isCollaborateur && adminId != null) {
            print('👥 Collaborateur détecté - Récupération des infos de l\'admin: $adminId');
            
            // Essayer d'abord directement dans le document admin
            try {
              final adminDocRef = FirebaseFirestore.instance.collection('users').doc(adminId);
              final adminDoc = await adminDocRef.get(const GetOptions(source: Source.server));
              
              if (adminDoc.exists) {
                final adminData = adminDoc.data() ?? {};
                if (_containsEnterpriseInfo(adminData)) {
                  print('✅ Informations d\'entreprise trouvées directement dans le document admin');
                  return _formatEnterpriseInfo(adminData);
                }
              }
            } catch (e) {
              print('⚠️ Erreur lors de la tentative d\'accès au document admin: $e');
            }
            
            // Ensuite essayer dans la sous-collection authentification de l'admin
            try {
              print('🔍 Tentative d\'accès à la sous-collection authentification de l\'admin...');
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
              print('⚠️ Erreur lors de la tentative d\'accès à l\'authentification admin: $e');
            }
            
            // Finalement essayer /company/{adminId}
            try {
              print('🔍 Tentative d\'accès à la collection company...');
              final companyDocRef = FirebaseFirestore.instance.collection('company').doc(adminId);
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
          }
          
          // Si c'est un admin ou si on n'a pas pu récupérer les données du collaborateur
          if (!isCollaborateur || adminId == null) {
            print('👥 C\'est un administrateur ou un utilisateur standard');
            
            // Essayer d'abord dans la sous-collection authentification
            try {
              print('🔍 Tentative d\'accès à la sous-collection authentification...');
              final authDocRef = FirebaseFirestore.instance
                    .collection('users')
                    .doc(uid)
                    .collection('authentification')
                    .doc(uid);
              
              final authDoc = await authDocRef.get(const GetOptions(source: Source.server));
              
              if (authDoc.exists) {
                final authData = authDoc.data() ?? {};
                print('✅ Document authentification trouvé!');
                return _formatEnterpriseInfo(authData);
              } else {
                print('❌ Document authentification non trouvé');
              }
            } catch (e) {
              print('⚠️ Erreur lors de la tentative d\'accès à l\'authentification: $e');
            }
            
            // Essayer ensuite directement dans le document utilisateur
            if (_containsEnterpriseInfo(userData)) {
              print('✅ Informations d\'entreprise trouvées directement dans le document utilisateur');
              return _formatEnterpriseInfo(userData);
            }
            
            // Essayer /company/{uid}
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
          }
        } else {
          print('❌ Document utilisateur principal non trouvé');
        }
        
        print('❌ Aucune information d\'entreprise n\'a pu être trouvée malgré toutes les tentatives');
        return {};
      } catch (e) {
        print('❌ Erreur pendant la récupération des données utilisateur: $e');
        return {};
      }
    } catch (e) {
      print('❌ Erreur globale lors de la récupération des informations d\'entreprise: $e');
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
