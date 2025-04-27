import 'dart:typed_data';

import 'package:edugo/features/notification/screens/notification_management.dart';
import 'package:edugo/features/profile/screens/profile.dart';
import 'package:edugo/features/scholarship/screens/provider_detail.dart';
import 'package:edugo/features/search/screens/search_list.dart';
import 'package:edugo/shared/utils/textStyle.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:edugo/services/footer.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:edugo/services/auth_service.dart';
import 'package:intl/intl.dart';
import 'package:edugo/features/login&register/login.dart';
import 'package:edugo/main.dart'; // Import main.dart เพื่อเข้าถึง navigatorKey
import 'package:edugo/features/search/screens/filter.dart'; // Import filter.dart

import '../../../services/scholarship_card.dart';
import 'package:edugo/features/search/screens/search_screen.dart';
import 'package:edugo/config/api_config.dart';
import 'package:edugo/config/api_config.dart';

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
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => SearchList(
              searchQuery: "",
              selectedFilters: {
                'countries': {fullName}, // ใช้ fullName แทน name
              },
            ),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              const begin = 0.0;
              const end = 1.0;
              const curve = Curves.easeOut;
              var tween =
                  Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
              return FadeTransition(
                  opacity: animation.drive(tween), child: child);
            },
            transitionDuration: const Duration(milliseconds: 300),
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
                      style: TextStyleService.getDmSans(
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
          const SizedBox(height: 4.0), // ลดระยะห่างระหว่าง Avatar กับ Text
          Expanded(
            // เพิ่ม Expanded รอบ Text
            child: Text(
              name,
              style: TextStyleService.getDmSans(
                  fontSize: 11, // อาจจะลดขนาด font ลงเล็กน้อยถ้าจำเป็น
                  color: Color(0xFF64738B),
                  fontWeight: FontWeight.w400),
              overflow: TextOverflow.ellipsis, // จัดการข้อความที่ยาวเกินไป
              textAlign: TextAlign.center, // จัดข้อความให้อยู่ตรงกลาง
            ),
          ),
        ],
      ),
    );
  }
}

class HomeScreenApp extends StatefulWidget {
  const HomeScreenApp({super.key});

  @override
  _HomeScreenAppState createState() => _HomeScreenAppState();
}

class _HomeScreenAppState extends State<HomeScreenApp> {
  Map<String, dynamic>? profile; // Define the profile variable
  int _currentIndex = 0;
  bool _showAllCountries = false;
  List<dynamic> scholarships = [];
  final Map<String, Uint8List?> _imageCache = {};
  final AuthService authService = AuthService(navigatorKey: navigatorKey);
  bool isProvider = false;
  final TextEditingController _searchController = TextEditingController();
  Map<String, Set<String>> _selectedFilters = {};
  String? providerName;
  final Map<String, Uint8List?> _imageAvatarCache = {};
  final Map<String, Future<Uint8List?>> _imageFutureCache = {};
  final Map<String, Future<Uint8List?>> _avatarFutureCache = {};
  final Map<String, Future<String?>> _providerNameFutureCache = {};
  Uint8List? imageAvatar;
  int notReadCount = 0;
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
  ];

  @override
  void initState() {
    super.initState();
    authService.checkSessionValidity(); // เพิ่มการตรวจสอบ session ที่นี่
    _checkToken();
    fetchProfile();
    getAnswer();
    fetchAvatarImage();
  }

  Future<void> _checkToken() async {
    bool isValid = await authService.validateToken();
    if (!isValid) {
      // ถ้า token ไม่ถูกต้องหรือหมดอายุ ให้ลบ token และนำไปหน้า login
      await authService.removeToken();
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const Login()),
        );
      }
    }
  }

  Future<void> fetchAvatarImage() async {
    String? token = await authService.getToken();

    final response = await http.get(
      Uri.parse(ApiConfig.profileAvatarUrl),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        imageAvatar = response.bodyBytes; // แปลง response เป็น Uint8List
      });
    } else {
      // throw Exception('Failed to load country data');
      imageAvatar = null;
    }
  }

  Future<Uint8List?> getImageFuture(String url) {
    return _imageFutureCache.putIfAbsent(url, () => fetchImage(url));
  }

  Future<Uint8List?> getAvatarFuture(String url) {
    return _avatarFutureCache.putIfAbsent(url, () => fetchPostAvatar(url));
  }

  Future<String?> getProviderNameFuture(String url) {
    return _providerNameFutureCache.putIfAbsent(
        url, () => fetchProviderName(url));
  }

  Future<Uint8List?> fetchPostAvatar(String url) async {
    if (_imageAvatarCache.containsKey(url)) {
      return _imageAvatarCache[url];
    }

    try {
      String? token = await authService.getToken();
      Map<String, String> headers = {};
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        _imageAvatarCache[url] = response.bodyBytes;
        return response.bodyBytes;
      } else {
        debugPrint("Failed to load image: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error fetching image: $e");
    }
    _imageAvatarCache[url] = null;
    return null;
  }

  Future<void> fetchProfile() async {
    try {
      String? token = await authService.getToken();
      Map<String, String> headers = {};
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response =
          await http.get(Uri.parse(ApiConfig.profileUrl), headers: headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final Map<String, dynamic> profileData = data['profile'];

        // เก็บเฉพาะ id และ role
        setState(() {
          profile = {
            'id': profileData['id'],
            'role': profileData['role'],
          };

          // เช็ค role และตั้งค่า isProvider
          isProvider = profile!['role'] == 'provider';
        });

        fetchCountNotifications();
      } else {
        throw Exception('Failed to load profile');
      }
    } catch (e) {
      setState(() {});
      print("Error fetching profile: $e");
    }
  }

  Future<http.Response?> getAnswer() async {
    final url = Uri.parse(ApiConfig.answerUrl);
    String? token = await authService.getToken();

    Map<String, String> headers = {'Content-Type': 'application/json'};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    try {
      final response = await http.get(url, headers: headers);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> data = json.decode(response.body);
        // final List categories = data['categories'] ?? [];
        final List countries = data['countries'] ?? [];
        // final educationLevel = data['education_level'];

        final isEmptyData = countries.isEmpty;

        if (isEmptyData) {
          fetchScholarships(false, null);
        } else {
          final filters = extractFiltersFromAnswerData(data);
          fetchScholarships(true, filters);
        }

        return response;
      } else {
        fetchScholarships(false, null);
      }
    } catch (e) {
      print("Error fetching answer: $e");
      fetchScholarships(false, null);
    }

    return null;
  }

  Future<void> fetchScholarships(
      bool isAnswer, Map<String, Set<String>>? filters) async {
    try {
      String? token = await authService.getToken();
      Map<String, String> headers = {};
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      Uri uri;
      if (isAnswer && filters != null) {
        List<String> queryParams = [];

        // Countries
        if (filters.containsKey('countries') &&
            filters['countries']!.isNotEmpty) {
          final countries = filters['countries']!.join(',');
          queryParams.add("country=$countries");
        }

        String url = ApiConfig.searchAnnounceUrl;
        if (queryParams.isNotEmpty) {
          url += "?${queryParams.join('&')}";
        }

        uri = Uri.parse(url);
      } else {
        uri = Uri.parse(ApiConfig.announceUserUrl);
      }

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        // ✅ Retry with default fetch if filtered data is null
        if (data['data'] == null) {
          await fetchScholarships(false, null);
          return; // ✅ This is valid in Future<void>
        }

        List<dynamic> scholarshipData = data['data'];

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
            scholarship['provider_id'] =
                scholarship['provider_id'] ?? scholarship['provider_id'];
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

  Future<void> fetchCountNotifications() async {
    String? token = await authService.getToken();
    Map<String, String> headers = {};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    final url = "${ApiConfig.notificationUrl}/count/${profile?['id']}";

    try {
      final response = await http.get(Uri.parse(url), headers: headers);
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        setState(() {
          // เก็บค่าลง state หรือใช้งานได้เลย
          notReadCount = responseData['read_count'];
        });
      } else {
        throw Exception('Failed to load notifications');
      }
    } catch (e) {
      print("Error fetching notifications: $e");
    }
  }

  Future<Uint8List?> fetchImage(String url) async {
    if (_imageCache.containsKey(url)) {
      return _imageCache[url];
    }

    try {
      String? token = await authService.getToken();
      Map<String, String> headers = {};
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        _imageCache[url] = response.bodyBytes;
        return response.bodyBytes;
      } else {
        debugPrint("Failed to load image: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error fetching image: $e");
    }
    _imageCache[url] = null;
    return null;
  }

  // ฟังก์ชันแปลงข้อมูลจาก getAnswer ให้กลายเป็น filters
  Map<String, Set<String>> extractFiltersFromAnswerData(
      Map<String, dynamic> data) {
    final Set<String> countries = (data['countries'] as List)
        .map<String>((c) => c['name'].toString())
        .toSet();

    // จะ set เฉพาะ countries เท่านั้น
    return {
      if (countries.isNotEmpty) 'countries': countries,
    };
  }

  Future<String?> fetchProviderName(String url) async {
    try {
      String? token = await authService.getToken();
      Map<String, String> headers = {};
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        providerName = data['company_name'];
        return providerName;
      } else {
        debugPrint("Failed to load company name: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error fetching company name: $e");
    }
    providerName = null;
    return null;
  }

  final List<String> carouselItems = [
    'assets/images/carousel_1.png',
    'assets/images/carousel_2.png',
    'assets/images/carousel_3.png',
  ];

  void _navigateToSearchList(String query,
      {Map<String, Set<String>>? filters}) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => SearchList(
            searchQuery: query, selectedFilters: filters ?? _selectedFilters),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = 0.0;
          const end = 1.0;
          const curve = Curves.easeOut;
          var tween =
              Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          return FadeTransition(
            opacity: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Positioned.fill(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Header
                  Container(
                    // Removed fixed height to allow content to determine height
                    color: const Color(0xFF355FFF),
                    padding: const EdgeInsets.only(
                        top: 58.0,
                        right: 16,
                        left: 16,
                        bottom:
                            27), // Keep original padding or adjust slightly if needed
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize:
                          MainAxisSize.min, // Make column take minimum space
                      children: [
                        // Avatar and Notification Icon
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  PageRouteBuilder(
                                    pageBuilder: (context, animation,
                                            secondaryAnimation) =>
                                        const PersonalProfile(),
                                    transitionsBuilder: (context, animation,
                                        secondaryAnimation, child) {
                                      const begin = 0.0;
                                      const end = 1.0;
                                      const curve = Curves.easeOut;
                                      var tween = Tween(begin: begin, end: end)
                                          .chain(CurveTween(curve: curve));
                                      return FadeTransition(
                                          opacity: animation.drive(tween),
                                          child: child);
                                    },
                                    transitionDuration:
                                        const Duration(milliseconds: 300),
                                  ),
                                );
                              },
                              child: CircleAvatar(
                                radius: 20,
                                child: ClipOval(
                                  child: imageAvatar != null
                                      ? Image.memory(
                                          imageAvatar!,
                                          width: 40,
                                          height: 40,
                                          fit: BoxFit.cover,
                                        )
                                      : Image.asset(
                                          'assets/images/avatar.png',
                                          width: 40,
                                          height: 40,
                                          fit: BoxFit.cover,
                                        ),
                                ),
                              ),
                            ),
                            Image.asset(
                              'assets/images/brower.png',
                              width: 40.0,
                              height: 40.0,
                            ),
                            Stack(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: const Color(0xFFDAFB59),
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        PageRouteBuilder(
                                          pageBuilder: (context, animation,
                                                  secondaryAnimation) =>
                                              NotificationList(
                                            id: profile?['id'],
                                          ),
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
                                    child: Image.asset(
                                      'assets/images/notification.png',
                                      width: 40.0,
                                      height: 40.0,
                                      color: const Color(0xFF355FFF),
                                      colorBlendMode: BlendMode.srcIn,
                                    ),
                                  ),
                                ),
                                if (notReadCount > 0)
                                  Positioned(
                                    right: 0,
                                    top: 0,
                                    child: Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: Colors.pinkAccent,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                              ],
                            )
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Welcome Text
                        Text(
                          "Hello, there",
                          style: TextStyleService.getDmSans(
                              color: Color(0xFFFFFFFF),
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                              height: 1.4),
                        ),
                        const SizedBox(height: 4.0),
                        Text(
                          "Discover community and experiences",
                          style: TextStyleService.getDmSans(
                            color: Color(0xFFFFFFFF),
                            fontSize: 14,
                            height: 1.0,
                            fontWeight: FontWeight.w200,
                          ),
                        ),
                        const SizedBox(height: 16.0), // Keep or adjust spacing
                        // Search Bar
                        SizedBox(
                          // Keep SizedBox for consistent search bar height
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
                                        _searchController, // Use controller
                                    decoration: InputDecoration(
                                      hintText: "Search Experiences",
                                      hintStyle: TextStyleService.getDmSans(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w400,
                                        color: const Color(0xFF94A2B8),
                                      ),
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                    style: TextStyleService.getDmSans(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w400,
                                      color: Colors.black,
                                    ),
                                    textAlignVertical: TextAlignVertical.center,
                                    onSubmitted: (value) {
                                      // Navigate to SearchList with query
                                      _navigateToSearchList(value);
                                    },
                                  ),
                                ),
                                // Add Filter Icon
                                GestureDetector(
                                  onTap: () async {
                                    final filters =
                                        await openFilterDrawer(context);
                                    if (filters != null) {
                                      setState(() {
                                        _selectedFilters = filters;
                                      });
                                      _navigateToSearchList(
                                          _searchController.text,
                                          filters: _selectedFilters);
                                    }
                                  },
                                  child: Image.asset(
                                    'assets/images/three-line.png', // Make sure this asset exists
                                    width: 30.0,
                                    height: 18.0,
                                    color: const Color(0xFF8CA4FF),
                                  ),
                                ),
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
                            vertical: 8.0, horizontal: 4.0),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _currentIndex == index
                              ? const Color(0xFFD992FA)
                              : const Color(0xFFD9D9D9),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 0.0),
                  // Discover Countries
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              // Wrap the Text with Expanded
                              child: Text(
                                "Discover Many Countries",
                                style: TextStyleService.getDmSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xFF000000),
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  PageRouteBuilder(
                                    pageBuilder: (context, animation,
                                            secondaryAnimation) =>
                                        const SearchScreen(),
                                    transitionsBuilder: (context, animation,
                                        secondaryAnimation, child) {
                                      const begin = 0.0;
                                      const end = 1.0;
                                      const curve = Curves.easeOut;
                                      var tween = Tween(begin: begin, end: end)
                                          .chain(CurveTween(curve: curve));
                                      return FadeTransition(
                                          opacity: animation.drive(tween),
                                          child: child);
                                    },
                                    transitionDuration:
                                        const Duration(milliseconds: 300),
                                  ),
                                );
                              },
                              child: Text(
                                _showAllCountries ? "See Less" : "See more >>",
                                style: TextStyleService.getDmSans(
                                    color: Color(0xFF355FFF),
                                    fontWeight: FontWeight.w500,
                                    fontSize: 11),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(
                            height: 10), // ลดระยะห่างจาก 8.0 เป็น 4.0
                        GridView.count(
                          padding: EdgeInsets.zero, // ลบ padding ของ GridView
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 5,
                          mainAxisSpacing: 8.0,
                          crossAxisSpacing: 8.0,
                          childAspectRatio: 0.8,
                          children: countryList.take(5).map((country) {
                            return CountryFilter(
                              name: country['name'],
                              fullName:
                                  country['fullName'], // เพิ่มการส่ง fullName
                              countryId: country['countryId'],
                              flagImage: country['flagImage'],
                              backgroundColor: country['backgroundColor'],
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Features & New Scholarships",
                        style: TextStyleService.getDmSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF000000)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Scholarships Section (Horizontal Scroll)
                  SizedBox(
                    height: 260,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      itemCount: scholarships.length,
                      itemBuilder: (context, index) {
                        final scholarship = scholarships[index];
                        final DateTime publishedDate =
                            DateTime.tryParse(scholarship['published_date']) ??
                                DateTime.now();
                        final DateTime closeDate =
                            DateTime.tryParse(scholarship['close_date']) ??
                                DateTime.now();
                        final String imageUrl =
                            "${ApiConfig.announceUserUrl}/${scholarship['id']}/image";
                        final duration =
                            "${DateFormat('d MMM').format(publishedDate)} - ${DateFormat('d MMM yyyy').format(closeDate)}";

                        final String providerName =
                            "${ApiConfig.providerUrl}/${scholarship['provider_id']}";

                        final String providerImage =
                            "${ApiConfig.providerUrl}/avatar/${scholarship['provider_id']}";

                        return GestureDetector(
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
                              'education_level': scholarship['education_level'],
                              'attach_name': scholarship['attach_name'],
                              'providerId': scholarship['providerId']
                            };

                            // Fetch the image and update the cache if necessary
                            final cachedImage = await fetchImage(imageUrl);

                            // Add the cached image to existingData
                            existingData['cachedImage'] = cachedImage;
                            Navigator.push(
                              context,
                              PageRouteBuilder(
                                pageBuilder:
                                    (context, animation, secondaryAnimation) =>
                                        ProviderDetail(
                                  initialData: existingData,
                                  // Always treat navigation from home screen as non-provider view for edit/delete buttons
                                  isProvider: false,
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
                          child: Padding(
                            padding: const EdgeInsets.only(right: 16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12.0),
                                  child: _imageCache.containsKey(imageUrl)
                                      ? (_imageCache[imageUrl] != null
                                          ? Image.memory(
                                              _imageCache[imageUrl]!,
                                              width: 144,
                                              height: 192,
                                              fit: BoxFit.cover,
                                            )
                                          : Image.asset(
                                              "assets/images/scholarship_program.png",
                                              width: 144,
                                              height: 192,
                                              fit: BoxFit.cover,
                                            ))
                                      : FutureBuilder<Uint8List?>(
                                          future: fetchImage(imageUrl),
                                          builder: (context, snapshot) {
                                            if (snapshot.connectionState ==
                                                ConnectionState.waiting) {
                                              return const SizedBox(
                                                width: 144,
                                                height: 192,
                                                child: Center(
                                                    child:
                                                        CircularProgressIndicator()),
                                              );
                                            }
                                            if (snapshot.data == null) {
                                              return Image.asset(
                                                "assets/images/scholarship_program.png",
                                                width: 144,
                                                height: 192,
                                                fit: BoxFit.cover,
                                              );
                                            }
                                            return Image.memory(
                                              snapshot.data!,
                                              width: 144,
                                              height: 192,
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
                                      SizedBox(
                                        width: 144,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              duration,
                                              style: TextStyleService.getDmSans(
                                                  fontSize: 8,
                                                  color: Color(0xFF2A4CCC),
                                                  fontWeight: FontWeight.w400),
                                            ),
                                            const SizedBox(height: 4.0),
                                            Text(
                                              scholarship['title'],
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyleService.getDmSans(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF000000),
                                              ),
                                            ),
                                            const SizedBox(height: 4.0),
                                            SizedBox(
                                              width: double.infinity,
                                              child: Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                children: [
                                                  CircleAvatar(
                                                    radius: 6,
                                                    backgroundImage: _imageCache
                                                                .containsKey(
                                                                    providerImage) &&
                                                            _imageCache[
                                                                    providerImage] !=
                                                                null
                                                        ? MemoryImage(_imageCache[
                                                            providerImage]!) // ใช้ภาพจากแคช
                                                        : null, // ถ้าไม่มีภาพในแคช
                                                    child: !_imageCache
                                                            .containsKey(
                                                                providerImage)
                                                        ? FutureBuilder<
                                                            Uint8List?>(
                                                            future:
                                                                getAvatarFuture(
                                                                    providerImage),
                                                            builder: (context,
                                                                snapshot) {
                                                              if (snapshot
                                                                      .connectionState ==
                                                                  ConnectionState
                                                                      .waiting) {
                                                                return const Center(
                                                                  child:
                                                                      CircularProgressIndicator(),
                                                                );
                                                              }
                                                              if (snapshot
                                                                      .data ==
                                                                  null) {
                                                                return ClipOval(
                                                                  child: Image
                                                                      .asset(
                                                                    "assets/images/avatar.png",
                                                                    fit: BoxFit
                                                                        .cover,
                                                                    width: 40,
                                                                    height: 40,
                                                                  ),
                                                                );
                                                              }
                                                              return CircleAvatar(
                                                                radius: 20,
                                                                backgroundImage:
                                                                    MemoryImage(
                                                                        snapshot
                                                                            .data!),
                                                              );
                                                            },
                                                          )
                                                        : null,
                                                  ),
                                                  const SizedBox(width: 4.0),
                                                  Expanded(
                                                    child:
                                                        FutureBuilder<String?>(
                                                      future:
                                                          getProviderNameFuture(
                                                              providerName),
                                                      builder:
                                                          (context, snapshot) {
                                                        if (snapshot
                                                                .connectionState ==
                                                            ConnectionState
                                                                .waiting) {
                                                          return const SizedBox(
                                                            width: 60,
                                                            height: 10,
                                                            child:
                                                                LinearProgressIndicator(),
                                                          );
                                                        }
                                                        if (snapshot.hasError ||
                                                            snapshot.data ==
                                                                null) {
                                                          return Text(
                                                            "Unknown",
                                                            style:
                                                                TextStyleService
                                                                    .getDmSans(
                                                              fontSize: 9.415,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w400,
                                                              color: Color(
                                                                  0xFF000000),
                                                            ),
                                                          );
                                                        }

                                                        return Text(
                                                          snapshot.data!,
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style:
                                                              TextStyleService
                                                                  .getDmSans(
                                                            fontSize: 9.415,
                                                            fontWeight:
                                                                FontWeight.w400,
                                                            color: Color(
                                                                0xFF000000),
                                                          ),
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
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
                  const SizedBox(height: 20),
                  // Add the new Discover More Opportunities section here
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Container(
                      height: 200, // Keep the height or adjust if needed
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12.0),
                        image: const DecorationImage(
                          image: AssetImage('assets/images/Footer.png'),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Discover More Opportunities",
                              textAlign: TextAlign.center,
                              style: TextStyleService.getDmSans(
                                fontSize: 12, // ลดขนาดตัวอักษรลงอีก
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(
                                height: 12), // ปรับระยะห่างตามความเหมาะสม
                            ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  PageRouteBuilder(
                                    pageBuilder: (context, animation,
                                            secondaryAnimation) =>
                                        const SearchScreen(),
                                    transitionsBuilder: (context, animation,
                                        secondaryAnimation, child) {
                                      const begin = 0.0;
                                      const end = 1.0;
                                      const curve = Curves.easeOut;
                                      var tween = Tween(begin: begin, end: end)
                                          .chain(CurveTween(curve: curve));
                                      return FadeTransition(
                                          opacity: animation.drive(tween),
                                          child: child);
                                    },
                                    transitionDuration:
                                        const Duration(milliseconds: 300),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF355FFF),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 40,
                                    vertical: 10), // ลด padding ของปุ่ม
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      8), // ปรับมุมปุ่มตามต้องการ
                                ),
                              ),
                              child: Text(
                                "See all",
                                style: TextStyleService.getDmSans(
                                  fontSize: 13, // ลดขนาดตัวอักษรปุ่มลงอีก
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 110), // Add space before FooterNav
                ],
              ),
            ),
          ),
          // Footer Navigation Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: MediaQuery.removeViewInsets(
              context: context,
              removeBottom: true,
              child: FooterNav(
                pageName: "home",
              ),
            ),
          ),
        ],
      ),
    );
  }
}
