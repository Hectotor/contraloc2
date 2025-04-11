import 'package:intl/intl.dart';

class ContractUtils {
  /// Détermine le statut d'un contrat en fonction de sa date de début
  /// 
  /// Si la date de début est dans plus de 24h, le statut est 'réservé'
  /// Sinon, le statut est 'en_cours'
  static String determineContractStatus(String? dateDebutStr) {
    if (dateDebutStr == null || dateDebutStr.isEmpty) {
      return 'en_cours';
    }
    
    try {
      final now = DateTime.now();
      DateTime? dateDebut;
      
      // Essayer de parser la date au format 'EEEE d MMMM yyyy à HH:mm'
      try {
        dateDebut = DateFormat('EEEE d MMMM yyyy à HH:mm', 'fr_FR').parse(dateDebutStr);
      } catch (e) {
        // Si le premier format échoue, essayer un autre format
        try {
          // Format: 'dd/MM/yyyy HH:mm'
          dateDebut = DateFormat('dd/MM/yyyy HH:mm').parse(dateDebutStr);
        } catch (e2) {
          // Dernier essai avec un format plus simple
          final parts = dateDebutStr.split(' ');
          if (parts.length >= 4) {
            final day = int.tryParse(parts[1]);
            int month = 1;
            
            // Convertir le mois en français en numéro
            final months = ['janvier', 'février', 'mars', 'avril', 'mai', 'juin', 
                          'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'];
            for (int i = 0; i < months.length; i++) {
              if (parts[2].toLowerCase().contains(months[i])) {
                month = i + 1;
                break;
              }
            }
            
            final year = int.tryParse(parts[3]) ?? now.year;
            
            // Extraire l'heure si disponible
            int hour = 0, minute = 0;
            if (parts.length >= 6 && parts[4] == 'à') {
              final timeParts = parts[5].split(':');
              if (timeParts.length == 2) {
                hour = int.tryParse(timeParts[0]) ?? 0;
                minute = int.tryParse(timeParts[1]) ?? 0;
              }
            }
            
            if (day != null) {
              dateDebut = DateTime(year, month, day, hour, minute);
            }
          }
        }
      }
      
      if (dateDebut == null) {
        return 'en_cours';
      }
      
      // Ajuster l'année si nécessaire
      final dateWithCurrentYear = DateTime(
        now.year,
        dateDebut.month,
        dateDebut.day,
        dateDebut.hour,
        dateDebut.minute,
      );
      
      final dateToCompare = dateWithCurrentYear.isBefore(now) && 
                           dateDebut.month < now.month ? 
                           DateTime(now.year + 1, dateDebut.month, dateDebut.day, 
                                   dateDebut.hour, dateDebut.minute) : 
                           dateWithCurrentYear;
      
      // Calculer la différence en jours
      final difference = dateToCompare.difference(now).inHours;
      
      // Si la date est dans plus de 24h et pas le même jour, le statut est 'réservé'
      if (difference > 24 && 
          !(dateToCompare.year == now.year && 
            dateToCompare.month == now.month && 
            dateToCompare.day == now.day)) {
        return 'réservé';
      }
      
      return 'en_cours';
    } catch (e) {
      print('Erreur lors de la détermination du statut du contrat: $e');
      return 'en_cours';
    }
  }
}
