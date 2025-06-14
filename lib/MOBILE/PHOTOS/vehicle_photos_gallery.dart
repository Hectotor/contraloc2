import 'dart:io';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';

/// Écran pour afficher une galerie de photos de véhicule avec défilement
class VehiclePhotosGallery extends StatefulWidget {
  final Map<String, String> photos;
  final int initialIndex;

  const VehiclePhotosGallery({
    Key? key,
    required this.photos,
    required this.initialIndex,
  }) : super(key: key);

  @override
  State<VehiclePhotosGallery> createState() => _VehiclePhotosGalleryState();
}

class _VehiclePhotosGalleryState extends State<VehiclePhotosGallery> {
  late int _currentIndex;
  late List<MapEntry<String, String>> _photosList;

  @override
  void initState() {
    super.initState();
    _photosList = widget.photos.entries.toList();
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF08004D)),
        title: Text(
          _photosList[_currentIndex].key,
          style: const TextStyle(color: Color(0xFF08004D), fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: CarouselSlider(
                // Suppression du paramètre carouselController qui cause une erreur de type
                options: CarouselOptions(
                  height: double.infinity,
                  viewportFraction: 1.0,
                  enlargeCenterPage: false,
                  initialPage: _currentIndex,
                  enableInfiniteScroll: false,
                  onPageChanged: (index, reason) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                ),
                items: _photosList.map((entry) {
                  return Builder(
                    builder: (BuildContext context) {
                      return Container(
                        width: MediaQuery.of(context).size.width,
                        margin: const EdgeInsets.symmetric(horizontal: 5.0),
                        child: InteractiveViewer(
                          minScale: 0.5,
                          maxScale: 3.0,
                          child: Center(
                            child: AspectRatio(
                              aspectRatio: 4 / 3, // Format horizontal standard (16:9)
                              child: Image.file(
                                File(entry.value),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }).toList(),
              ),
            ),
            // Indicateurs et légendes
            Container(
              padding: const EdgeInsets.all(16.0),
              color: Colors.white,
              child: Column(
                children: [
                  // Indicateurs de position
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: _photosList.asMap().entries.map((entry) {
                      return Container(
                        width: 8.0,
                        height: 8.0,
                        margin: const EdgeInsets.symmetric(horizontal: 4.0),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _currentIndex == entry.key
                              ? const Color(0xFF08004D)
                              : const Color(0xFF08004D).withOpacity(0.4),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  // Légende avec le titre de la vue
                  Text(
                    '${_currentIndex + 1}/${_photosList.length} - ${_photosList[_currentIndex].key}',
                    style: const TextStyle(
                      color: Color(0xFF08004D),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
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
