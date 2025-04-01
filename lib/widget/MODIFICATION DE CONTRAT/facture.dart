import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class FactureScreen extends StatefulWidget {
  final Map<String, dynamic> data;
  final Function(Map<String, dynamic>) onFraisUpdated;
  final double kilometrageInitial;
  final double kilometrageActuel;
  final double tarifKilometrique;
  final String dateFinEffective;

  const FactureScreen({
    Key? key,
    required this.data,
    required this.onFraisUpdated,
    required this.kilometrageInitial,
    required this.kilometrageActuel,
    required this.tarifKilometrique,
    required this.dateFinEffective,
  }) : super(key: key);

  @override
  State<FactureScreen> createState() => _FactureScreenState();
}

class _FactureScreenState extends State<FactureScreen> {
  // Contrôleurs pour les champs de texte
  late TextEditingController _cautionController;
  late TextEditingController _fraisNettoyageIntController;
  late TextEditingController _fraisNettoyageExtController;
  late TextEditingController _fraisCarburantController;
  late TextEditingController _fraisRayuresController;
  late TextEditingController _fraisAutreController;
  late TextEditingController _remiseController; // Nouveau contrôleur pour la remise

  // Contrôleurs spécifiques pour les champs calculés automatiquement
  late TextEditingController _kmSuppDisplayController;
  late TextEditingController _coutTotalController;

  // Contrôleurs pour les champs de kilométrage
  late TextEditingController _kmDepartController;
  late TextEditingController _kmAutoriseController;
  late TextEditingController _kmSuppController;
  late TextEditingController _kmRetourController;

  // Type de paiement
  String _typePaiement = 'Carte bancaire';
  final List<String> _typesPaiement = ['Carte bancaire', 'Espèces', 'Virement'];

  // Total calculé
  double _total = 0.0;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('fr_FR', null); // Initialisation des locales françaises
    
    // Initialiser les contrôleurs avec des valeurs par défaut à 0
    _kmSuppDisplayController = TextEditingController(text: "0");
    _coutTotalController = TextEditingController(text: "0");
    _cautionController = TextEditingController(text: "0");
    _fraisNettoyageIntController = TextEditingController(text: "0");
    _fraisNettoyageExtController = TextEditingController(text: "0");
    _fraisCarburantController = TextEditingController(text: "0");
    _fraisRayuresController = TextEditingController(text: "0");
    _fraisAutreController = TextEditingController(text: "0");
    _remiseController = TextEditingController(text: "0"); // Initialisation du contrôleur de remise

    // Initialiser les contrôleurs de kilométrage
    _kmDepartController = TextEditingController(
      text: widget.data['kilometrageDepart'] != null && 
          widget.data['kilometrageDepart'].toString().isNotEmpty 
          ? widget.data['kilometrageDepart'].toString() 
          : 'Non indiqué au départ du contrat',
    );
    
    _kmAutoriseController = TextEditingController(
      text: widget.data['kilometrageAutorise'] != null && 
          widget.data['kilometrageAutorise'].toString().isNotEmpty 
          ? widget.data['kilometrageAutorise'].toString() 
          : 'Non indiqué au départ du contrat',
    );
    
    _kmSuppController = TextEditingController(
      text: widget.data['kilometrageSupp'] != null && 
          widget.data['kilometrageSupp'].toString().isNotEmpty 
          ? widget.data['kilometrageSupp'].toString() 
          : 'Non indiqué au départ du contrat',
    );

    // Initialiser le contrôleur du kilométrage de retour
    _kmRetourController = TextEditingController(
      // Utiliser la valeur de kilometrageActuel passée en paramètre
      text: widget.kilometrageActuel.toString(),
    );

    // Charger les valeurs existantes depuis widget.data
    if (widget.data.isNotEmpty) {
      _cautionController.text = widget.data['factureCaution']?.toString() ?? "0";
      _fraisNettoyageIntController.text = widget.data['factureFraisNettoyageInt']?.toString() ?? "0";
      _fraisNettoyageExtController.text = widget.data['factureFraisNettoyageExt']?.toString() ?? "0";
      _fraisCarburantController.text = widget.data['factureFraisCarburant']?.toString() ?? "0";
      _fraisRayuresController.text = widget.data['factureFraisRayuresDommages']?.toString() ?? "0";
      _fraisAutreController.text = widget.data['factureFraisAutre']?.toString() ?? "0";
      _coutTotalController.text = widget.data['facturePrixLocation']?.toString() ?? "0";

      // Charger le type de paiement s'il existe
      if (widget.data['factureTypePaiement'] != null && _typesPaiement.contains(widget.data['factureTypePaiement'])) {
        _typePaiement = widget.data['factureTypePaiement'];
      }
    }

    _calculerTotal();
  }

  @override
  void dispose() {
    _kmSuppDisplayController.dispose();
    _coutTotalController.dispose();
    _cautionController.dispose();
    _fraisNettoyageIntController.dispose();
    _fraisNettoyageExtController.dispose();
    _fraisCarburantController.dispose();
    _fraisRayuresController.dispose();
    _fraisAutreController.dispose();
    _kmDepartController.dispose();
    _kmAutoriseController.dispose();
    _kmSuppController.dispose();
    _kmRetourController.dispose();
    _remiseController.dispose(); // Dispose du contrôleur de remise
    super.dispose();
  }

  // Méthode pour notifier le parent des changements

  // Calculer le total des frais
  void _calculerTotal() {
    setState(() {
      double total = 0.0;

      // Calcul du prix de location basé sur la durée
      try {
        // Récupérer les dates
        String dateDebutStr = (widget.data['dateDebut'] as String?) ?? '';
        String dateFinStr = widget.dateFinEffective;
        String prixLocationStr = (widget.data['prixLocation'] as String?) ?? '0';
        
        // Convertir le prix de location en double
        double prixLocationJournalier = double.tryParse(prixLocationStr.replaceAll(',', '.')) ?? 0.0;
        
        if (dateDebutStr.isNotEmpty && dateFinStr.isNotEmpty && prixLocationJournalier > 0) {
          // Extraire les dates en garantissant différents formats possibles
          DateTime? dateDebut;
          DateTime? dateFin;
          
          // Essayer de parser le format complet avec heure (ex: "mardi 1 avril 2025 à 17:19")
          try {
            // Extraire la date et l'heure
            RegExp regExpDate = RegExp(r'\d{1,2}\s+\w+\s+\d{4}');
            RegExp regExpHeure = RegExp(r'\d{1,2}:\d{2}');
            
            // Pour la date de début
            var matchDate = regExpDate.firstMatch(dateDebutStr);
            var matchHeure = regExpHeure.firstMatch(dateDebutStr);
            
            if (matchDate != null) {
              String simplifiedDate = matchDate.group(0)!;
              String heure = matchHeure != null ? matchHeure.group(0)! : "00:00";
              
              // Combiner la date et l'heure
              dateDebut = DateFormat('d MMMM yyyy HH:mm', 'fr_FR').parse("$simplifiedDate $heure");
            }
            
            // Pour la date de fin
            matchDate = regExpDate.firstMatch(dateFinStr);
            matchHeure = regExpHeure.firstMatch(dateFinStr);
            
            if (matchDate != null) {
              String simplifiedDate = matchDate.group(0)!;
              String heure = matchHeure != null ? matchHeure.group(0)! : "00:00";
              
              // Combiner la date et l'heure
              dateFin = DateFormat('d MMMM yyyy HH:mm', 'fr_FR').parse("$simplifiedDate $heure");
            }
          } catch (e) {
            print('Erreur lors de l\'extraction de la date et de l\'heure: $e');
          }
          
          // Si l'extraction a échoué, essayer d'autres formats courants
          if (dateDebut == null) {
            try {
              // Essayer le format dd/MM/yyyy
              dateDebut = DateFormat('dd/MM/yyyy').parse(dateDebutStr);
            } catch (e) {
              print('Impossible de parser la date de début: $e');
            }
          }
          
          if (dateFin == null) {
            try {
              // Essayer le format dd/MM/yyyy
              dateFin = DateFormat('dd/MM/yyyy').parse(dateFinStr);
            } catch (e) {
              print('Impossible de parser la date de fin: $e');
            }
          }
          
          // Si les deux dates sont valides, calculer la durée
          if (dateDebut != null && dateFin != null) {
            // Calculer la durée en heures
            int dureeHeures = dateFin.difference(dateDebut).inHours;
            
            // Calculer le nombre de tranches de 24h (arrondi au supérieur)
            double dureeJours = dureeHeures / 24.0;
            dureeJours = (dureeHeures % 24 == 0) ? dureeJours : dureeJours.ceilToDouble();
            dureeJours = dureeJours <= 0 ? 1.0 : dureeJours; // Au moins 1 tranche de 24h
            
            // Calculer le prix total de location (100€ pour 24h)
            double prixLocationTotal = dureeJours * prixLocationJournalier;
            
            // Mettre à jour le champ du prix de location total
            _coutTotalController.text = prixLocationTotal.toStringAsFixed(2).replaceAll('.', ',');
            
            // Afficher les informations de calcul pour le débogage
            print('Date de début: $dateDebut, Date de fin: $dateFin, Durée: $dureeHeures heures ($dureeJours tranches de 24h), Prix par 24h: $prixLocationJournalier€, Total: ${prixLocationTotal}€');
          }
        }
      } catch (e) {
        // En cas d'erreur, garder la valeur actuelle
        print('Erreur lors du calcul de la durée de location: $e');
      }

      // Calcul des frais kilométriques
      double kmDepart = double.tryParse(widget.data['kilometrageDepart']?.toString() ?? '0') ?? 0;
      double kmAutorise = double.tryParse(widget.data['kilometrageAutorise']?.toString() ?? '0') ?? 0;
      double kmRetour = double.tryParse(_kmRetourController.text) ?? 0;
      double kmSupp = double.tryParse(widget.data['kilometrageSupp']?.toString() ?? '0') ?? 0;

      // Calcul : (kmRetour - (kmDepart + kmAutorise)) * kmSupp
      double fraisKm = (kmRetour - (kmDepart + kmAutorise)) * kmSupp;
      
      // Assurer que le résultat est positif
      fraisKm = fraisKm < 0 ? 0 : fraisKm;
      
      _kmSuppDisplayController.text = fraisKm.toStringAsFixed(2).replaceAll('.', ',');

      // Ajouter tous les frais qui ont une valeur non nulle
      total += double.tryParse(_coutTotalController.text.replaceAll(',', '.')) ?? 0.0;
      total += double.tryParse(_kmSuppDisplayController.text.replaceAll(',', '.')) ?? 0.0;
      total += double.tryParse(_fraisNettoyageIntController.text.replaceAll(',', '.')) ?? 0.0;
      total += double.tryParse(_fraisNettoyageExtController.text.replaceAll(',', '.')) ?? 0.0;
      total += double.tryParse(_fraisCarburantController.text.replaceAll(',', '.')) ?? 0.0;
      total += double.tryParse(_fraisRayuresController.text.replaceAll(',', '.')) ?? 0.0;
      total += double.tryParse(_fraisAutreController.text.replaceAll(',', '.')) ?? 0.0;
      total += double.tryParse(_cautionController.text.replaceAll(',', '.')) ?? 0.0;
      
      // Appliquer la remise (soustraire du total)
      double remise = double.tryParse(_remiseController.text.replaceAll(',', '.')) ?? 0.0;
      total -= remise;
      
      // S'assurer que le total n'est pas négatif
      total = total < 0 ? 0 : total;
      
      _total = total;
    });
  }

  void _sauvegarderFacture() async {
    try {
      // Préparer les données à sauvegarder
      final data = {
        'facturePrixLocation': double.tryParse(_coutTotalController.text.replaceAll(',', '.')) ?? 0,
        'factureCaution': double.tryParse(_cautionController.text.replaceAll(',', '.')) ?? 0,
        'factureFraisNettoyageInterieur': double.tryParse(_fraisNettoyageIntController.text.replaceAll(',', '.')) ?? 0,
        'factureFraisNettoyageExterieur': double.tryParse(_fraisNettoyageExtController.text.replaceAll(',', '.')) ?? 0,
        'factureFraisCarburantManquant': double.tryParse(_fraisCarburantController.text.replaceAll(',', '.')) ?? 0,
        'factureFraisRayuresDommages': double.tryParse(_fraisRayuresController.text.replaceAll(',', '.')) ?? 0,
        'factureFraisAutre': double.tryParse(_fraisAutreController.text.replaceAll(',', '.')) ?? 0,
        'factureRemise': double.tryParse(_remiseController.text.replaceAll(',', '.')) ?? 0, // Ajouter la remise
        'factureTotalFrais': _total,
        'factureTypePaiement': _typePaiement,
        'kilometrageRetour': double.tryParse(_kmRetourController.text) ?? 0,
      };

      // Mettre à jour les données du widget
      widget.data.addAll(data);

      // Notifier le parent des changements
      widget.onFraisUpdated(data);

      // Afficher un message de succès
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Facture sauvegardée avec succès'),
          backgroundColor: Colors.green,
        ),
      );

      // Fermer le formulaire et renvoyer les données mises à jour
      Navigator.pop(context, data);
    } catch (e) {
      // Afficher un message d'erreur
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la sauvegarde : ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Logs pour déboguer les valeurs des champs de kilométrage
    debugPrint('Kilométrage de départ: ${widget.data['kilometrageDepart']}');
    debugPrint('Kilométrage autorisé: ${widget.data['kilometrageAutorise']}');
    debugPrint('Kilométrage supplémentaire: ${widget.data['kilometrageSupp']}');
    debugPrint('Kilométrage de retour: ${_kmRetourController.text}');
    debugPrint('Frais kilométriques: ${_kmSuppDisplayController.text}');

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Facture',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF08004D),
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // En-tête avec description
                  _buildHeader(),
                  const SizedBox(height: 24),

                  // Section des frais principaux
                  _buildSection(
                    title: "Prix de location (Prix / 24h)",
                    icon: Icons.attach_money,
                    color: Colors.green[700]!,
                    children: [
                      // Champ de date de début
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: TextFormField(
                          initialValue: widget.data['dateDebut'] ?? '',
                          decoration: InputDecoration(
                            labelText: "Date de début",
                            labelStyle: const TextStyle(color: Color(0xFF08004D)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          readOnly: true,
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                      
                      // Champ de date de fin effective
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: TextFormField(
                          initialValue: widget.dateFinEffective,
                          decoration: InputDecoration(
                            labelText: "Date de fin effective",
                            labelStyle: const TextStyle(color: Color(0xFF08004D)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          readOnly: true,
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                      
                      // Champ du prix de location initial
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: TextFormField(
                          initialValue: widget.data['prixLocation'] ?? '',
                          decoration: InputDecoration(
                            labelText: "Prix de location initial",
                            labelStyle: const TextStyle(color: Color(0xFF08004D)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            prefixText: '€',
                          ),
                          readOnly: true,
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                      
                      _buildTextField("Prix de location total", _coutTotalController),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Section des frais kilométriques
                  _buildSection(
                    title: "Frais kilométriques",
                    icon: Icons.directions_car,
                    color: Colors.blue[700]!,
                    children: [
                      // Champ de kilométrage de départ
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: TextFormField(
                          controller: _kmDepartController,
                          decoration: InputDecoration(
                            labelText: "Kilométrage de départ",
                            labelStyle: const TextStyle(color: Color(0xFF08004D)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            suffixText: 'km',
                          ),
                          readOnly: true,
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                        ),
                      ),

                      // Champ de kilométrage autorisé
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: TextFormField(
                          controller: _kmAutoriseController,
                          decoration: InputDecoration(
                            labelText: "Kilométrage autorisé",
                            labelStyle: const TextStyle(color: Color(0xFF08004D)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            suffixText: 'km',
                          ),
                          readOnly: true,
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                        ),
                      ),

                      // Champ du tarif kilométrique
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: TextFormField(
                          controller: _kmSuppController,
                          decoration: InputDecoration(
                            labelText: "Tarif kilométrique",
                            labelStyle: const TextStyle(color: Color(0xFF08004D)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            suffixText: '€/km',
                          ),
                          readOnly: true,
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                      
                      // Champ du kilométrage de retour
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: TextFormField(
                          controller: _kmRetourController,
                          decoration: InputDecoration(
                            labelText: "Kilométrage de retour",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.check_circle),
                              onPressed: () {
                                // Fermer le clavier
                                FocusScope.of(context).unfocus();
                              },
                            ),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _calculerTotal();
                            });
                          },
                        ),
                      ),
                      
                      // Champ des frais kilométriques
                      _buildTextField("Frais kilométriques", _kmSuppDisplayController),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Section des frais additionnels
                  _buildSection(
                    title: "Frais additionnels",
                    icon: Icons.add_circle_outline,
                    color: Colors.orange[700]!,
                    children: [
                      _buildTextField("Frais nettoyage intérieur", _fraisNettoyageIntController),
                      _buildTextField("Frais nettoyage extérieur", _fraisNettoyageExtController),
                      _buildTextField("Frais carburant manquant", _fraisCarburantController),
                      _buildTextField("Frais rayures/dommages", _fraisRayuresController),
                      _buildTextField("Frais autres", _fraisAutreController),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Section de la caution
                  _buildSection(
                    title: "Caution",
                    icon: Icons.security,
                    color: Colors.blue[700]!,
                    children: [
                      _buildTextField("Frais caution", _cautionController),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Section de la remise
                  _buildSection(
                    title: "Remise",
                    icon: Icons.discount,
                    color: Colors.purple[700]!,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: TextFormField(
                          controller: _remiseController,
                          decoration: InputDecoration(
                            labelText: "Remise",
                            labelStyle: const TextStyle(color: Color(0xFF08004D)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            suffixText: '€',
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d*\,?\d{0,2}')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _calculerTotal();
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Section du type de paiement
                  _buildSection(
                    title: "Type de paiement",
                    icon: Icons.payment,
                    color: Colors.purple[700]!,
                    children: [
                      DropdownButtonFormField<String>(
                        value: _typePaiement,
                        decoration: InputDecoration(
                          labelText: "Type de paiement",
                          labelStyle: const TextStyle(color: Color(0xFF08004D)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        items: _typesPaiement.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _typePaiement = newValue ?? 'Carte bancaire';
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Section du total
                  _buildSection(
                    title: "Total",
                    icon: Icons.attach_money,
                    color: Colors.green[700]!,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${_total.toStringAsFixed(2).replaceAll('.', ',')} €',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.green[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Bouton de validation
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Center(
                      child: SizedBox(
                        width: 350, // Largeur fixe du bouton
                        child: ElevatedButton(
                          onPressed: _sauvegarderFacture,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF08004D),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Valider',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Gestion de la facture',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF08004D),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Saisissez les éléments pour générer la facture',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête de section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          // Contenu de la section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Color(0xFF08004D)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          prefixText: '€',
        ),
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
        ],
        onChanged: (value) {
          _calculerTotal();
        },
      ),
    );
  }
}
