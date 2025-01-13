import 'package:flutter/material.dart';
import 'dart:io';

class Tampon extends StatelessWidget {
  final String logoPath;
  final String nomEntreprise;
  final String adresse;
  final String telephone;
  final String siret;

  const Tampon({
    Key? key,
    required this.logoPath,
    required this.nomEntreprise,
    required this.adresse,
    required this.telephone,
    required this.siret,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(16.0),
        margin: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.black, width: 2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (logoPath.isNotEmpty)
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 200,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: logoPath.startsWith('http')
                          ? DecorationImage(
                              image: NetworkImage(logoPath),
                              fit: BoxFit.cover,
                            )
                          : DecorationImage(
                              image: FileImage(File(logoPath)),
                              fit: BoxFit.cover,
                            ),
                    ),
                  ),
                ],
              ),
            if (logoPath.isNotEmpty) const SizedBox(height: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  nomEntreprise,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  adresse,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  "Téléphone : $telephone",
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  "SIRET : $siret",
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
