import 'dart:typed_data';

import 'package:edugo/config/api_config.dart';
import 'package:edugo/features/search/screens/search_list.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:edugo/services/footer.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:edugo/services/auth_service.dart';
import 'package:intl/intl.dart'; // นำเข้า DateFormat
import 'package:edugo/features/scholarship/screens/provider_detail.dart'; // เพิ่ม import
import 'package:edugo/features/search/screens/search_screen.dart'; // เพิ่ม import SearchScreen
import 'package:edugo/main.dart'; // Import main.dart เพื่อเข้าถึง navigatorKey

import '../../../services/scholarship_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  int _currentIndex = 0;
  List<dynamic> scholarships = [];
  final AuthService authService =
      AuthService(navigatorKey: navigatorKey); // Instance of AuthService
  final TextEditingController _searchController = TextEditingController();
  final Map<String, Uint8List?> _imageCache = {};

  @override
  void initState() {
    super.initState();
    fetchScholarships(); // โหลดข้อมูลทุนการศึกษาเมื่อเริ่มต้น
  }

  Future<void> fetchScholarships() async {
    try {
      String? token = await authService.getToken();
      Map<String, String> headers = {}; // Explicitly type the map
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.get(Uri.parse(ApiConfig.announceUserUrl),
          headers: headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data =
            json.decode(response.body); // Handle the response as a map
        List<dynamic> scholarshipData =
            data['data']; // Get the 'data' part, which is a list

        setState(() {
          scholarships = scholarshipData.map((scholarship) {
            scholarship['image'] = scholarship['image'] != null
                ? "${ApiConfig.announceUserUrl}/${scholarship['id']}/image"
                : 'assets/images/scholarship_program.png';
            scholarship['title'] = scholarship['title'] ?? 'No Title';
            scholarship['description'] =
                scholarship['description'] ?? 'No Description Available';
            scholarship['published_date'] =
                scholarship['published_date'] ?? scholarship['publish_date'];
            scholarship['close_date'] =
                scholarship['close_date'] ?? scholarship['close_date'];
            return scholarship;
          }).toList();

          scholarships.sort(
              (a, b) => b['published_date'].compareTo(a['published_date']));
        });
      } else {
        throw Exception('Failed to load scholarships');
      }
    } catch (e) {
      setState(() {});
      print("Error fetching scholarships: $e");
    }
  }

  Future<Uint8List?> fetchImage(String url) async {
    if (_imageCache.containsKey(url)) {
      return _imageCache[url]; // ดึงจากแคชถ้ามีอยู่แล้ว
    }

    try {
      String? token = await authService.getToken();

      Map<String, String> headers = {};
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        _imageCache[url] = response.bodyBytes; // บันทึกลงแคช
        return response.bodyBytes; // โหลดรูปสำเร็จ
      } else {
        debugPrint("Failed to load image: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error fetching image: $e");
    }
    _imageCache[url] = null; // ถ้าโหลดไม่สำเร็จ ให้แคชเป็น null
    return null; // โหลดรูปไม่ได้ ให้ใช้ภาพเริ่มต้นแทน
  }

  final List<String> carouselItems = [
    'assets/images/carousel_1.png',
    'assets/images/carousel_2.png',
    'assets/images/carousel_3.png',
  ];

  final List<Map<String, String>> countries = [
    {'name': 'Australia', 'flag': 'assets/images/brower.png'},
    {'name': 'Italy', 'flag': 'assets/images/brower.png'},
    {'name': 'America', 'flag': 'assets/images/brower.png'},
    {'name': 'Canada', 'flag': 'assets/images/brower.png'},
    {'name': 'Japan', 'flag': 'assets/images/brower.png'},
  ];

  final List<Map<String, dynamic>> countryList = [
    {
      'name': 'Australia',
      'fullName': 'Australia',
      'countryId': 9,
      'flagImage': 'assets/images/flags/australia.png',
      'backgroundColor': const Color(0xFFAAD2DB)
    },
    {
      'name': 'Italy',
      'fullName': 'Italy',
      'countryId': 82,
      'flagImage': 'assets/images/flags/italy.png',
      'backgroundColor': const Color(0xFFD7E4A8)
    },
    {
      'name': 'America',
      'fullName': 'United States',
      'countryId': 186,
      'flagImage': 'assets/images/flags/usa.png',
      'backgroundColor': const Color(0xFF7F97F2)
    },
    {
      'name': 'Canada',
      'fullName': 'Canada',
      'countryId': 31,
      'flagImage': 'assets/images/flags/canada.png',
      'backgroundColor': const Color(0xFFD1B2DF)
    },
    {
      'name': 'Japan',
      'fullName': 'Japan',
      'countryId': 84,
      'flagImage': 'assets/images/flags/japan.png',
      'backgroundColor': const Color(0xFFE4B58A)
    },
    {
      'name': 'New Zealand',
      'fullName': 'New Zealand',
      'countryId': 125,
      'flagImage': 'assets/images/flags/new_zealand.png',
      'backgroundColor': const Color(0xFFD1B2DF)
    },
    {
      'name': 'China',
      'fullName': 'China',
      'countryId': 36,
      'flagImage': 'assets/images/flags/china.png',
      'backgroundColor': const Color(0xFFAAD2DB)
    },
    {
      'name': 'UK',
      'fullName': 'United Kingdom',
      'countryId': 185,
      'flagImage': 'assets/images/flags/uk.png',
      'backgroundColor': const Color(0xFFE4B58A)
    },
    {
      'name': 'Singapore',
      'fullName': 'Singapore',
      'countryId': 157,
      'flagImage': 'assets/images/flags/singapore.png',
      'backgroundColor': const Color(0xFFD7E4A8)
    },
    {
      'name': 'Germany',
      'fullName': 'Germany',
      'countryId': 64,
      'flagImage': 'assets/images/flags/germany.png',
      'backgroundColor': const Color(0xFF7F97F2)
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // ส่วน Header
                  Container(
                    height: 141,
                    color: const Color(0xFF355FFF),
                    padding: const EdgeInsets.only(
                        top: 58.0, right: 16, left: 16, bottom: 27),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Search Bar
                        SizedBox(
                          height: 56.0,
                          child: Container(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16.0),
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
                                    controller:
                                        _searchController, // ใช้ controller

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
                                    onSubmitted: (value) {
                                      Navigator.push(
                                        context,
                                        PageRouteBuilder(
                                          pageBuilder: (context, animation,
                                                  secondaryAnimation) =>
                                              SearchList(
                                                  searchQuery:
                                                      value), // ✅ Use 'value' instead of 'query'
                                          transitionsBuilder: (context,
                                              animation,
                                              secondaryAnimation,
                                              child) {
                                            const begin = 0.0;
                                            const end = 1.0;
                                            const curve = Curves.easeOut;

                                            var tween = Tween(
                                                    begin: begin, end: end)
                                                .chain(
                                                    CurveTween(curve: curve));
                                            return FadeTransition(
                                              opacity: animation.drive(tween),
                                              child: child,
                                            );
                                          },
                                          transitionDuration:
                                              const Duration(milliseconds: 300),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                // Image.asset(
                                //   'assets/images/three-line.png',
                                //   width: 30.0,
                                //   height: 18.0,
                                //   color: const Color(0xFF8CA4FF),
                                // ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  // Carousel Slider
                  CarouselSlider(
                    options: CarouselOptions(
                      height: 120.0,
                      enlargeCenterPage: true,
                      autoPlay: true,
                      aspectRatio: 13 / 9,
                      autoPlayCurve: Curves.fastOutSlowIn,
                      enableInfiniteScroll: true,
                      autoPlayAnimationDuration:
                          const Duration(milliseconds: 800),
                      viewportFraction: 0.6,
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
                  // Dots Indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(carouselItems.length, (index) {
                      return Container(
                        width: 8.0,
                        height: 8.0,
                        margin: const EdgeInsets.symmetric(
                            vertical: 10.0, horizontal: 4.0),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _currentIndex == index
                              ? const Color(0xFFD992FA)
                              : const Color(0xFFD9D9D9),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 10.0),
                  // Discover Countries
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Discover Many Countries",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12.0),
                        GridView.count(
                          crossAxisCount: 5,
                          mainAxisSpacing: 8.0,
                          crossAxisSpacing: 8.0,
                          childAspectRatio: 0.8,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          children: countryList.map((country) {
                            return CountryFilter(
                              name: country['name'],
                              fullName: country['fullName'],
                              countryId: country['countryId'],
                              flagImage: country['flagImage'],
                              backgroundColor: country['backgroundColor'],
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Features & New Scholarships",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Scholarships Section (Horizontal Scroll)
                  SizedBox(
                    height: 240, // เพิ่มความสูงให้รองรับ Text
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal, // ให้เลื่อนไปทางแนวนอน
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      itemCount: scholarships.length,
                      itemBuilder: (context, index) {
                        final scholarship = scholarships[index];

                        // แปลงวันที่เป็น DateTime และตรวจสอบ null
                        final DateTime publishedDate =
                            DateTime.tryParse(scholarship['published_date']) ??
                                DateTime.now();
                        final DateTime closeDate =
                            DateTime.tryParse(scholarship['close_date']) ??
                                DateTime.now();

                        final String imageUrl =
                            "${ApiConfig.announceUserUrl}/${scholarship['id']}/image";

                        // แปลงวันที่เป็นรูปแบบที่ต้องการ
                        final duration =
                            "${DateFormat('d MMM').format(publishedDate)} - ${DateFormat('d MMM yyyy').format(closeDate)}";

                        return Padding(
                          padding: const EdgeInsets.only(
                              right: 12.0), // เพิ่มระยะห่างระหว่างรูป
                          child: GestureDetector(
                            // Wrap with GestureDetector
                            onTap: () async {
                              final existingData = {
                                'id': scholarship['id'],
                                'title': scholarship['title'],
                                'url': scholarship['url'],
                                'category': scholarship['category'],
                                'country': scholarship['country'],
                                'description': scholarship['description'],
                                'image': scholarship['image'],
                                'attach_file': scholarship['attach_file'],
                                'published_date': scholarship['published_date'],
                                'close_date': scholarship['close_date'],
                                'education_level':
                                    scholarship['education_level'],
                                'attach_name': scholarship['attach_name'],
                              };

                              // Fetch the image and update the cache if necessary
                              final cachedImage = await fetchImage(imageUrl);

                              // Add the cached image to existingData
                              existingData['cachedImage'] = cachedImage;
                              // --- Start Modification ---
                              // Pass previousRouteName
                              existingData['previousRouteName'] = 'search';
                              // --- End Modification ---

                              Navigator.push(
                                // Use push instead of pushReplacement if you want back button functionality
                                context,
                                PageRouteBuilder(
                                  pageBuilder: (context, animation,
                                          secondaryAnimation) =>
                                      ProviderDetail(
                                    initialData: existingData,
                                    isProvider: false, // User is seeking
                                    // --- Start Modification ---
                                    // Pass previousRouteName as a separate parameter as well
                                    previousRouteName: 'search',
                                    // --- End Modification ---
                                  ),
                                  transitionsBuilder: (context, animation,
                                      secondaryAnimation, child) {
                                    const begin = 0.0;
                                    const end = 1.0;
                                    const curve = Curves.easeOut;
                                    var tween = Tween(begin: begin, end: end)
                                        .chain(CurveTween(curve: curve));
                                    return FadeTransition(
                                      opacity: animation.drive(tween),
                                      child: child,
                                    );
                                  },
                                  transitionDuration:
                                      const Duration(milliseconds: 300),
                                ),
                              );
                            },
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start, // จัด text ชิดซ้าย
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12.0),
                                  child: _imageCache.containsKey(imageUrl)
                                      ? (_imageCache[imageUrl] != null
                                          ? Image.memory(
                                              _imageCache[imageUrl]!,
                                              width: 144, // กำหนดขนาดของรูป
                                              height:
                                                  160, // ปรับความสูงให้พอดีกับ Container
                                              fit: BoxFit.cover,
                                            )
                                          : Image.asset(
                                              "assets/images/scholarship_program.png",
                                              width: 144,
                                              height: 160,
                                              fit: BoxFit.cover,
                                            ))
                                      : FutureBuilder<Uint8List?>(
                                          future: fetchImage(imageUrl),
                                          builder: (context, snapshot) {
                                            if (snapshot.connectionState ==
                                                ConnectionState.waiting) {
                                              return Container(
                                                width: 144,
                                                height: 160,
                                                color: Colors.grey[200],
                                                child: const Center(
                                                    child:
                                                        CircularProgressIndicator()),
                                              );
                                            }
                                            if (snapshot.data == null) {
                                              return Image.asset(
                                                "assets/images/scholarship_program.png",
                                                width: 144,
                                                height: 160,
                                                fit: BoxFit.cover,
                                              );
                                            }
                                            return Image.memory(
                                              snapshot.data!,
                                              width: 144,
                                              height: 160,
                                              fit: BoxFit.cover,
                                            );
                                          },
                                        ),
                                ),
                                const SizedBox(height: 6.0),
                                SizedBox(
                                  width: 144,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        duration,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color:
                                              Color.fromARGB(255, 79, 77, 228),
                                        ),
                                      ),
                                      const SizedBox(height: 4.0),
                                      Text(
                                        scholarship['title'],
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(
                      height: 20), // Add some spacing before the footer
                ],
              ),
            ),
          ),
          FooterNav(
            pageName: "search",
          ),
        ],
      ),
    );
  }
}

class CountryFilter extends StatelessWidget {
  final String name;
  final String fullName; // เพิ่ม property
  final int countryId;
  final String flagImage;
  final Color backgroundColor;

  const CountryFilter({
    Key? key,
    required this.name,
    required this.fullName, // เพิ่ม parameter
    required this.countryId,
    required this.flagImage,
    required this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        print("Selected country: $fullName");
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SearchList(
              searchQuery: "",
              selectedFilters: {
                'countries': {fullName}, // ใช้ fullName
              },
            ),
          ),
        );
      },
      child: Column(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: backgroundColor,
            child: ClipOval(
              child: Image.asset(
                flagImage,
                width: 32,
                height: 32,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Text(
                      name.substring(0, 1),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 6.0),
          Text(
            name,
            style: const TextStyle(fontSize: 12),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
