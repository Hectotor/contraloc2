import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../USERS/add_collab_screen.dart';

class CollaboratorPage extends StatelessWidget {
  final String adminId;

  CollaboratorPage({required this.adminId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Liste des Collaborateurs'),
        backgroundColor: const Color(0xFF0F056B),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(adminId)
            .collection('collaborateurs')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('Aucun collaborateur trouvé.'));
          }

          final collaborators = snapshot.data!.docs;

          return ListView.builder(
            itemCount: collaborators.length,
            itemBuilder: (context, index) {
              final collaborator = collaborators[index];
              return ListTile(
                subtitle: Text(collaborator['email'] ?? 'Email inconnu'),
              );
            },
          );
        },
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
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text(
            'Ajouter Collaborateur',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: const Color(0xFF0F056B),
        ),
      ),
    );
  }
}
