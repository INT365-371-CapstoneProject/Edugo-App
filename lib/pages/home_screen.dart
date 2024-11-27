import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';

class HomeScreenApp extends StatefulWidget {
  const HomeScreenApp({super.key});

  @override
  _HomeScreenAppState createState() => _HomeScreenAppState();
}

class _HomeScreenAppState extends State<HomeScreenApp> {
  int _currentIndex = 0;

  final List<String> carouselItems = [
    'assets/images/carousel_1.png',
    'assets/images/carousel_2.png',
    'assets/images/carousel_3.png',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Blue header block
          Container(
            height: 263,
            color: const Color(0xFF355FFF),
            padding: const EdgeInsets.only(
                top: 58.0, right: 16, left: 16, bottom: 27),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Image.asset(
                      'assets/images/avatar.png',
                      width: 40.0,
                      height: 40.0,
                    ),
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: const Color(0xFFDAFB59),
                      child: Image.asset(
                        'assets/images/notification.png',
                        width: 40.0,
                        height: 40.0,
                        color: const Color(0xFF355FFF),
                        colorBlendMode: BlendMode.srcIn,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Welcome text
                const Text(
                  "Hello, there",
                  style: TextStyle(
                    fontFamily: "DM Sans",
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.normal,
                  ),
                ),
                const SizedBox(height: 4.0),
                const Text(
                  "Discover community and experiences",
                  style: TextStyle(
                    fontFamily: "DM Sans",
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.0,
                    fontWeight: FontWeight.normal,
                  ),
                ),
                const SizedBox(height: 16.0),
                // Search bar
                SizedBox(
                  height: 56.0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Row(
                      children: [
                        Image.asset(
                          'assets/images/search.png',
                          width: 24.0,
                          height: 24.0,
                          color: const Color(0xFF8CA4FF),
                        ),
                        const SizedBox(width: 19.0),
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: "Search Experiences",
                              hintStyle: TextStyle(
                                fontFamily: "DM Sans",
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                color: Colors.grey[400],
                              ),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        Image.asset(
                          'assets/images/three-line.png',
                          width: 30.0,
                          height: 18.0,
                          color: const Color(0xFF8CA4FF),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16.0),
          // Carousel slider with dots indicator
          CarouselSlider(
            options: CarouselOptions(
              height: 195.0,
              enlargeCenterPage: true,
              autoPlay: true,
              aspectRatio: 13 / 9,
              autoPlayCurve: Curves.fastOutSlowIn,
              enableInfiniteScroll: true,
              autoPlayAnimationDuration: const Duration(milliseconds: 800),
              viewportFraction: 0.8,
              onPageChanged: (index, reason) {
                setState(() {
                  _currentIndex = index;
                });
              },
            ),
            items: carouselItems.map((item) {
              return Builder(
                builder: (BuildContext context) {
                  return Container(
                    width: MediaQuery.of(context).size.width,
                    margin: const EdgeInsets.symmetric(horizontal: 5.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10.0),
                      image: DecorationImage(
                        image: AssetImage(item),
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 10.0),
          // Dots indicator ที่สร้างตามจำนวนของ items
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(carouselItems.length, (index) {
              return Container(
                width: 8.0,
                height: 8.0,
                margin:
                    const EdgeInsets.symmetric(vertical: 10.0, horizontal: 4.0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentIndex == index
                      ? const Color(0xFFD992FA)
                      : const Color(0xFFD9D9D9),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
