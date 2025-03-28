import 'package:cloud_firestore/cloud_firestore.dart';

class SearchFiltre {
  /// Filtre un document Firestore en fonction d'un texte de recherche
  /// 
  /// Recherche dans les informations du véhicule, du client et les dates
  /// Prend en charge différents formats de date, y compris les noms de jours et de mois en français
  static bool filterContract(DocumentSnapshot doc, String searchText) {
    if (searchText.isEmpty) return true;
    
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) return false;

    final searchLower = searchText.toLowerCase();
    
    // Recherche dans les informations du véhicule
    String vehiculeInfo = '';
    if (data.containsKey('vehiculeInfoStr') && data['vehiculeInfoStr'] != null) {
      vehiculeInfo = (data['vehiculeInfoStr'] as String).toLowerCase();
    } else if (data.containsKey('immatriculation')) {
      vehiculeInfo = (data['immatriculation'] as String? ?? '').toLowerCase();
    }
    
    if (vehiculeInfo.contains(searchLower)) {
      return true;
    }
    
    // Recherche dans les informations du client
    String clientInfo = '';
    if (data.containsKey('clientInfo') && data['clientInfo'] != null) {
      final client = data['clientInfo'] as Map<String, dynamic>?;
      if (client != null) {
        clientInfo = '${client['nom'] ?? ''} ${client['prenom'] ?? ''}'.toLowerCase();
      }
    } else {
      clientInfo = '${data['nom'] ?? ''} ${data['prenom'] ?? ''}'.toLowerCase();
    }
    
    if (clientInfo.contains(searchLower)) {
      return true;
    }
    
    // Recherche par date
    try {
      // Dates au format Timestamp ou DateTime
      List<dynamic> dates = [];
      
      if (data.containsKey('dateDebut')) {
        dates.add(data['dateDebut']);
      }
      
      if (data.containsKey('dateFin')) {
        dates.add(data['dateFin']);
      }
      
      if (data.containsKey('dateFinEffectif')) {
        dates.add(data['dateFinEffectif']);
      }
      
      if (data.containsKey('dateCreation')) {
        dates.add(data['dateCreation']);
      }
      
      for (var date in dates) {
        if (date == null) continue;
        
        DateTime dateTime;
        if (date is Timestamp) {
          dateTime = date.toDate();
        } else if (date is DateTime) {
          dateTime = date;
        } else {
          continue;
        }
        
        // Formats de date à vérifier
        final dateFormats = [
          '${dateTime.day}/${dateTime.month}/${dateTime.year}',
          '${dateTime.day}-${dateTime.month}-${dateTime.year}',
          '${dateTime.day}.${dateTime.month}.${dateTime.year}',
          '${dateTime.day}/${dateTime.month}',
          '${dateTime.month}/${dateTime.year}',
          '${dateTime.year}',
        ];
        
        // Noms des jours en français
        final joursSemaine = [
          'lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi', 'dimanche'
        ];
        
        // Noms des mois en français
        final moisAnnee = [
          'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
          'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'
        ];
        
        // Obtenir le jour de la semaine (0 = lundi, 6 = dimanche)
        final jourSemaine = (dateTime.weekday - 1) % 7;
        
        // Obtenir le mois (0 = janvier, 11 = décembre)
        final mois = dateTime.month - 1;
        
        // Format avec nom du jour et du mois
        final formatAvecNoms = '${joursSemaine[jourSemaine]} ${dateTime.day} ${moisAnnee[mois]}';
        final formatAvecNomsEtAnnee = '${joursSemaine[jourSemaine]} ${dateTime.day} ${moisAnnee[mois]} ${dateTime.year}';
        
        // Ajouter les formats avec noms
        dateFormats.add(formatAvecNoms.toLowerCase());
        dateFormats.add(formatAvecNomsEtAnnee.toLowerCase());
        dateFormats.add('${dateTime.day} ${moisAnnee[mois]}'.toLowerCase());
        dateFormats.add('${moisAnnee[mois]} ${dateTime.year}'.toLowerCase());
        
        for (var format in dateFormats) {
          if (format.toLowerCase().contains(searchLower)) {
            return true;
          }
        }
      }
    } catch (e) {
      // Ignorer les erreurs de parsing de date
    }
    
    return false;
  }
}
