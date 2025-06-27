import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

class PopupVehiculeClient extends StatefulWidget {
  final Function(String, String, List<File>) onSave;
  final String? immatriculationVehiculeClient;
  final String? kilometrageVehiculeClient;
  final List<File>? existingPhotos;

  const PopupVehiculeClient({
    Key? key,
    required this.onSave,
    this.immatriculationVehiculeClient,
    this.kilometrageVehiculeClient,
    this.existingPhotos,
  }) : super(key: key);

  @override
  State<PopupVehiculeClient> createState() => _PopupVehiculeClientState();
}

class _PopupVehiculeClientState extends State<PopupVehiculeClient> {
  final TextEditingController _immatriculationVehiculeClientController = TextEditingController();
  final TextEditingController _kilometrageVehiculeClientController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  List<File> _photos = [];
  final int _maxPhotos = 5;

  @override
  void initState() {
    super.initState();
    _immatriculationVehiculeClientController.text = widget.immatriculationVehiculeClient ?? '';
    _kilometrageVehiculeClientController.text = widget.kilometrageVehiculeClient ?? '';
    _photos = widget.existingPhotos?.toList() ?? [];
  }

  @override
  void dispose() {
    _immatriculationVehiculeClientController.dispose();
    _kilometrageVehiculeClientController.dispose();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    if (_photos.length >= _maxPhotos) {
      return;
    }

    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      final File imageFile = File(image.path);
      print('Photo prise: ${imageFile.path}');
      setState(() {
        _photos.add(imageFile);
      });
      print('Nombre de photos après ajout: ${_photos.length}');
    }
  }
  
  Future<void> _pickPhotoFromGallery() async {
    if (_photos.length >= _maxPhotos) {
      return;
    }

    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final File imageFile = File(image.path);
      print('Photo sélectionnée: ${imageFile.path}');
      setState(() {
        _photos.add(imageFile);
      });
      print('Nombre de photos après ajout: ${_photos.length}');
    }
  }

  void _removePhoto(int index) {
    setState(() {
      _photos.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.20),
              blurRadius: 4,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF08004D).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.directions_car, color: Color(0xFF08004D), size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Véhicule du client",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF08004D),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _immatriculationVehiculeClientController,
                    decoration: InputDecoration(
                      labelText: 'Modèle,Immatriculation...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    textCapitalization: TextCapitalization.characters,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _kilometrageVehiculeClientController,
                    decoration: InputDecoration(
                      labelText: 'Kilométrage',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      suffixText: "km",
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Photos du véhicule (${_photos.length}/$_maxPhotos)',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF08004D),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    height: 120,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _photos.isEmpty
                        ? Center(
                            child: Text(
                              'Aucune photo',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          )
                        : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _photos.length,
                            itemBuilder: (context, index) {
                              return Stack(
                                children: [
                                  Container(
                                    margin: const EdgeInsets.all(8),
                                    width: 100,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      image: DecorationImage(
                                        image: FileImage(_photos[index]),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 0,
                                    right: 0,
                                    child: GestureDetector(
                                      onTap: () => _removePhoto(index),
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 10),
                  Visibility(
                    visible: _photos.length < _maxPhotos,
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _takePhoto,
                            icon: const Icon(Icons.camera_alt, color: Colors.white),
                            label: const Text(
                              'Photo',
                              style: TextStyle(color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF08004D).withOpacity(0.8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _pickPhotoFromGallery,
                            icon: const Icon(Icons.photo_library, color: Colors.white),
                            label: const Text(
                              'Galerie',
                              style: TextStyle(color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF08004D).withOpacity(0.8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      print('Enregistrement des photos du véhicule client: ${_photos.length} photos');
                      for (int i = 0; i < _photos.length; i++) {
                        print('Photo ${i+1}: ${_photos[i].path}');
                      }
                      widget.onSave(
                        _immatriculationVehiculeClientController.text.trim(),
                        _kilometrageVehiculeClientController.text.trim(),
                        List<File>.from(_photos), // Créer une nouvelle liste pour éviter les problèmes de référence
                      );
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF08004D),
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 2,
                    ),
                    child: const Text(
                      "Enregistrer",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Function to show the vehicle dialog
Future<void> showVehiculeClientDialog({
  required BuildContext context,
  required Function(String, String, List<File>) onSave,
  String? immatriculationVehiculeClient,
  String? kilometrageVehiculeClient,
  List<File>? existingPhotos,
}) async {
  return showDialog(
    context: context,
    builder: (BuildContext context) {
      return PopupVehiculeClient(
        onSave: onSave,
        immatriculationVehiculeClient: immatriculationVehiculeClient,
        kilometrageVehiculeClient: kilometrageVehiculeClient,
        existingPhotos: existingPhotos,
      );
    },
  );
}
