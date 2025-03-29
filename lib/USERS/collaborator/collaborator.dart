import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_collab_screen.dart';

class CollaboratorPage extends StatelessWidget {
  final String adminId;

  CollaboratorPage({required this.adminId});

  // Fonction pour supprimer un collaborateur
  Future<void> _deleteCollaborator(BuildContext context, String collaboratorId, String collaboratorEmail) async {
    // Afficher une boîte de dialogue de confirmation
    bool confirm = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Confirmer la suppression',
              style: TextStyle(color: Color(0xFF08004D), fontWeight: FontWeight.bold)),
          content: Text(
            'Êtes-vous sûr de vouloir supprimer le collaborateur $collaboratorEmail ?',
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler',
                  style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                backgroundColor: Colors.red.withOpacity(0.1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Supprimer',
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    ) ?? false;

    if (confirm) {
      try {
        // Supprimer le collaborateur de la collection
        await FirebaseFirestore.instance
            .collection('users')
            .doc(adminId)
            .collection('collaborateurs')
            .doc(collaboratorId)
            .delete();

        // Afficher un message de succès
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Collaborateur supprimé avec succès'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
          ),
        );
      } catch (e) {
        // Afficher un message d'erreur en cas d'échec
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la suppression: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Mes collaborateurs',
            style: TextStyle(
                color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF08004D),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // En-tête avec texte explicatif
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF08004D).withOpacity(0.05),
            child: const Text(
              'Gérez vos collaborateurs et leurs accès à votre compte',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF08004D),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          // Liste des collaborateurs
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(adminId)
                  .collection('collaborateurs')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline, size: 80, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'Aucun collaborateur trouvé',
                          style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Ajoutez des collaborateurs pour qu\'ils puissent accéder à votre compte',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  );
                }

                final collaborators = snapshot.data!.docs;

                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ListView.builder(
                    itemCount: collaborators.length,
                    itemBuilder: (context, index) {
                      final collaborator = collaborators[index];
                      final collaboratorId = collaborator.id;
                      final email = collaborator['email'] ?? 'Email inconnu';
                      final nom = collaborator['nom'] ?? '';
                      final prenom = collaborator['prenom'] ?? '';
                      final displayName = (nom.isNotEmpty || prenom.isNotEmpty)
                          ? '$prenom $nom'
                          : email.split('@').first;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              // Avatar du collaborateur
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: const Color(0xFF08004D).withOpacity(0.1),
                                child: Text(
                                  displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF08004D),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Informations du collaborateur
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      displayName,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF08004D),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      email,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Bouton de suppression
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                onPressed: () => _deleteCollaborator(context, collaboratorId, email),
                                tooltip: 'Supprimer ce collaborateur',
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddCollaborateurScreen(),
              ),
            );
          },
          icon: const Icon(Icons.person_add, color: Colors.white),
          label: const Text(
            'Ajouter un collaborateur',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xFF0F056B),
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}
