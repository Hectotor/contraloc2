import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';

class PartnersCarousel extends StatelessWidget {
  const PartnersCarousel({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<String> partnerImages = [
      'assets/icon/ad.jpg',
      'assets/icon/axial.jpg',
      'assets/icon/citroen.jpg',
      'assets/icon/peugeot.jpg',
    ];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 16),
          child: Text(
            "Nos partenaires engagés",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF08004D),
            ),
          ),
        ),
        Container(
          width: double.infinity,
          height: 100,
          child: CarouselSlider(
            options: CarouselOptions(
              height: 100,
              aspectRatio: 16/9,
              viewportFraction: 0.3,
              initialPage: 0,
              enableInfiniteScroll: true,
              reverse: false,
              autoPlay: true,
              autoPlayInterval: Duration(seconds: 2),
              autoPlayAnimationDuration: Duration(milliseconds: 800),
              autoPlayCurve: Curves.fastOutSlowIn,
              enlargeCenterPage: true,
              scrollDirection: Axis.horizontal,
            ),
            items: partnerImages.map((imagePath) {
              return Builder(
                builder: (BuildContext context) {
                  return Container(
                    width: MediaQuery.of(context).size.width,
                    margin: EdgeInsets.symmetric(horizontal: 5.0, vertical: 5.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.3),
                          spreadRadius: 1,
                          blurRadius: 5,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        imagePath,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Center(child: Icon(Icons.error, color: Colors.grey));
                        },
                      ),
                    ),
                  );
                },
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
