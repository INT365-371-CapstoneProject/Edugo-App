import 'dart:typed_data';

import 'package:edugo/config/api_config.dart';
import 'package:edugo/features/search/screens/search_list.dart';
import 'package:edugo/shared/utils/textStyle.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:edugo/services/footer.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:edugo/services/auth_service.dart';
import 'package:intl/intl.dart'; // นำเข้า DateFormat
import 'package:edugo/features/scholarship/screens/provider_detail.dart'; // เพิ่ม import
import 'package:edugo/main.dart'; // Import main.dart เพื่อเข้าถึง navigatorKey
import 'package:edugo/features/search/screens/filter.dart'; // Import filter.dart

import '../../../services/scholarship_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  int _currentIndex = 0;
  List<dynamic> scholarshipsForRecommended = [];
  List<dynamic> scholarshipsForAll = [];
  final AuthService authService =
      AuthService(navigatorKey: navigatorKey); // Instance of AuthService
  final TextEditingController _searchController = TextEditingController();
  final Map<String, Uint8List?> _imageCache = {};
  Map<String, Set<String>> _selectedFilters = {}; // Add state for filters
  String? providerName;
  final Map<String, Uint8List?> _imageAvatarCache = {};
  final Map<String, Future<Uint8List?>> _imageFutureCache = {};
  final Map<String, Future<Uint8List?>> _avatarFutureCache = {};
  final Map<String, Future<String?>> _providerNameFutureCache = {};

  bool showPaginationControls = false;
  int displayPage = 1;
  int displayTotal = 1;
  bool canGoPrev = false;
  bool canGoNext = false;
  int _currentPage = 1;
  int _totalPages = 1; // Total API pages
  int _totalScholarships = 0; // Overall total from API
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    // โหลดข้อมูลทุนการศึกษาเมื่อเริ่มต้น
    getAnswer();
    fetchAllScholarships();
  }

  Future<void> fetchScholarshipsForAnswer(
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

        // Education Levels
        if (filters.containsKey('educationLevels') &&
            filters['educationLevels']!.isNotEmpty) {
          final levels = filters['educationLevels']!.join(',');
          queryParams.add("education_level=$levels");
        }

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
          await fetchScholarshipsForAnswer(false, null);
          return; // ✅ This is valid in Future<void>
        }

        List<dynamic> scholarshipData = data['data'];

        setState(() {
          scholarshipsForRecommended = scholarshipData.map((scholarship) {
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

          scholarshipsForRecommended.sort(
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

  bool _countsCalculated = false;

  Future<void> fetchAllScholarships(
      {int page = 1, bool refreshCounts = false}) async {
    if (!mounted) return;
    setState(() {
      isLoading = true; // Loading indicator for API page data
      if (refreshCounts) {
        _countsCalculated = false;
        scholarshipsForAll.clear(); // Clear all data if refreshing counts
      }
      // Clear current API page list
      scholarshipsForAll.clear();
      // Don't clear useItem here, it will be updated by _applyFilterAndPagination or directly if "All"
    });
    try {
      String? token = await authService.getToken();
      Map<String, String> headers = {
        'Content-Type': 'application/json',
      };
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.announceUserUrl}?page=$page'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        List<dynamic> scholarshipData = data['data'] ?? [];

        setState(() {
          scholarshipsForAll =
              scholarshipData.map<Map<String, dynamic>>((item) {
            final String id = item['id'].toString();
            return {
              'id': item['id'],
              'image': item['image'] != null
                  ? "${ApiConfig.announceUserUrl}/$id/image"
                  : 'assets/images/scholarship_program.png',
              'title': item['title'] ?? 'No Title',
              'description': item['description'] ?? 'No Description Available',
              'published_date':
                  item['published_date'] ?? item['publish_date'] ?? '',
              'close_date': item['close_date'] ?? '',
              'provider_id': item['provider_id'] ?? '',
            };
          }).toList();

          scholarshipsForAll.sort((a, b) {
            final aDate = DateTime.tryParse(a['published_date']) ?? DateTime(0);
            final bDate = DateTime.tryParse(b['published_date']) ?? DateTime(0);
            return bDate.compareTo(aDate);
          });
          _currentPage = data['page'] ?? 1;
          _totalPages = data['last_page'] ?? 1;
          _totalScholarships = data['total'] ?? 0;
          showPaginationControls = _totalPages > 1;
        });
      } else {
        throw Exception('Failed to load scholarships: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {}); // Consider showing an error message instead
      print("Error fetching scholarships: $e");
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
        final List categories = data['categories'] ?? [];
        final List countries = data['countries'] ?? [];
        final educationLevel = data['education_level'];

        final isEmptyData =
            categories.isEmpty && countries.isEmpty && educationLevel == null;

        if (isEmptyData) {
          fetchScholarshipsForAnswer(false, null);
        } else {
          final filters = extractFiltersFromAnswerData(data);
          fetchScholarshipsForAnswer(true, filters);
        }

        return response;
      } else {
        fetchScholarshipsForAnswer(false, null);
      }
    } catch (e) {
      print("Error fetching answer: $e");
      fetchScholarshipsForAnswer(false, null);
    }

    return null;
  }

  // ฟังก์ชันแปลงข้อมูลจาก getAnswer ให้กลายเป็น filters
  Map<String, Set<String>> extractFiltersFromAnswerData(
      Map<String, dynamic> data) {
    final Set<String> countries = (data['countries'] as List)
        .map<String>((c) => c['name'].toString())
        .toSet();

    final String? educationLevel = data['education_level']?.toString();

    return {
      if (countries.isNotEmpty) 'countries': countries,
      if (educationLevel != null && educationLevel.isNotEmpty)
        'educationLevels': {educationLevel},
    };
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

  // Function to navigate to SearchList
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
    bool canGoPrev = false;
    bool canGoNext = false;
    int displayPage = 1;
    int displayTotal = 1;
    displayPage = _currentPage;
    displayTotal = _totalPages;
    canGoPrev = _currentPage > 1;
    canGoNext = _currentPage < _totalPages;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned.fill(
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
                                      hintStyle: TextStyleService.getDmSans(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w400,
                                        color: Color(0xFF94A2B8),
                                      ),
                                      border: InputBorder.none,
                                    ),
                                    onSubmitted: (value) {
                                      _navigateToSearchList(value);
                                    },
                                  ),
                                ),
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
                        Text(
                          "Discover Many Countries",
                          style: TextStyleService.getDmSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF000000),
                          ),
                        ),
                        SizedBox(height: 16),
                        GridView.count(
                          padding: EdgeInsets.zero,
                          crossAxisCount: 5,
                          mainAxisSpacing: 8.0, // ระยะห่างแนวตั้งระหว่าง items
                          crossAxisSpacing: 8.0, // ระยะห่างแนวนอนระหว่าง items
                          childAspectRatio:
                              0.8, // ปรับอัตราส่วน กว้าง/สูง ของแต่ละ item
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
                  const SizedBox(height: 10.0),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Recommended countries just for you",
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
                    height: 250,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      itemCount: scholarshipsForRecommended.length,
                      itemBuilder: (context, index) {
                        final scholarship = scholarshipsForRecommended[index];
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
                            };

                            // Fetch the image and update the cache if necessary
                            final cachedImage = await fetchImage(imageUrl);

                            // Add the cached image to existingData
                            existingData['cachedImage'] = cachedImage;
                            Navigator.push(
                              context,
                              PageRouteBuilder(
                                pageBuilder: (context, animation,
                                        secondaryAnimation) =>
                                    ProviderDetail(
                                        initialData: existingData,
                                        // Always treat navigation from home screen as non-provider view for edit/delete buttons
                                        isProvider: false,
                                        previousRouteName: 'search'),
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
                            padding: const EdgeInsets.only(right: 12.0),
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
                  SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Let's explore all the scholarship",
                        style: TextStyleService.getDmSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF000000)),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  // All Scholarship
                  GridView.builder(
                    shrinkWrap: true,
                    physics:
                        NeverScrollableScrollPhysics(), // ปิด scroll เพราะมี scroll ข้างนอกแล้ว
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: scholarshipsForAll.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, // จำนวนคอลัมน์ = 2
                      crossAxisSpacing: 16.0, // ระยะห่างระหว่างคอลัมน์
                      mainAxisSpacing: 12.0, // ระยะห่างระหว่างแถว
                      childAspectRatio:
                          0.63, // สัดส่วนความสูง/กว้าง ของแต่ละ item
                    ),
                    itemBuilder: (context, index) {
                      final scholarship = scholarshipsForAll[index];
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
                          padding: const EdgeInsets.only(right: 0.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12.0),
                                child: _imageCache.containsKey(imageUrl)
                                    ? (_imageCache[imageUrl] != null
                                        ? Image.memory(
                                            _imageCache[imageUrl]!,
                                            width: 200,
                                            height: 230,
                                            fit: BoxFit.cover,
                                          )
                                        : Image.asset(
                                            "assets/images/scholarship_program.png",
                                            width: 200,
                                            height: 230,
                                            fit: BoxFit.cover,
                                          ))
                                    : FutureBuilder<Uint8List?>(
                                        future: fetchImage(imageUrl),
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState ==
                                              ConnectionState.waiting) {
                                            return const SizedBox(
                                              width: 200,
                                              height: 230,
                                              child: Center(
                                                  child:
                                                      CircularProgressIndicator()),
                                            );
                                          }
                                          if (snapshot.data == null) {
                                            return Image.asset(
                                              "assets/images/scholarship_program.png",
                                              width: 200,
                                              height: 230,
                                              fit: BoxFit.cover,
                                            );
                                          }
                                          return Image.memory(
                                            snapshot.data!,
                                            width: 200,
                                            height: 230,
                                            fit: BoxFit.cover,
                                          );
                                        },
                                      ),
                              ),
                              const SizedBox(height: 6.0),
                              SizedBox(
                                width: 144,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                                            if (snapshot.data ==
                                                                null) {
                                                              return ClipOval(
                                                                child:
                                                                    Image.asset(
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
                                                FutureBuilder<String?>(
                                                  future: getProviderNameFuture(
                                                      providerName),
                                                  builder: (context, snapshot) {
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
                                                        snapshot.data == null) {
                                                      return Text(
                                                        "Unknown",
                                                        style: TextStyleService
                                                            .getDmSans(
                                                          fontSize: 9.415,
                                                          fontWeight:
                                                              FontWeight.w400,
                                                          color:
                                                              Color(0xFF000000),
                                                        ),
                                                      );
                                                    }

                                                    return Text(
                                                      snapshot.data!,
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: TextStyleService
                                                          .getDmSans(
                                                        fontSize: 9.415,
                                                        fontWeight:
                                                            FontWeight.w400,
                                                        color:
                                                            Color(0xFF000000),
                                                      ),
                                                    );
                                                  },
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
                  // Pagination Controls
                  if (showPaginationControls)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 16.0, horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ElevatedButton.icon(
                            onPressed: canGoPrev
                                ? () {
                                    fetchAllScholarships(
                                        page: _currentPage - 1,
                                        refreshCounts: true);
                                  }
                                : null, // Disable if cannot go previous
                            icon: Icon(Icons.arrow_back_ios,
                                size: 16,
                                color: canGoPrev
                                    ? Colors.white
                                    : Colors.grey[400]),
                            label: Text("Prev",
                                style: TextStyle(
                                    color: canGoPrev
                                        ? Colors.white
                                        : Colors.grey[400])),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: canGoPrev
                                  ? Color(0xFF355FFF)
                                  : Colors.grey[300],
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              padding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                            ),
                          ),
                          Text(
                            'Page $displayPage of $displayTotal', // Use calculated display values
                            style: TextStyleService.getDmSans(
                                fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                          ElevatedButton.icon(
                            onPressed: canGoNext
                                ? () {
                                    fetchAllScholarships(
                                        page: _currentPage + 1,
                                        refreshCounts: true);
                                  }
                                : null, // Disable if cannot go next
                            icon: Icon(Icons.arrow_forward_ios,
                                size: 16,
                                color: canGoNext
                                    ? Colors.white
                                    : Colors.grey[400]),
                            label: Text("Next",
                                style: TextStyle(
                                    color: canGoNext
                                        ? Colors.white
                                        : Colors.grey[400])),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: canGoNext
                                  ? Color(0xFF355FFF)
                                  : Colors.grey[300],
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              padding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(
                      height: 90), // Add some spacing before the footer
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: MediaQuery.removeViewInsets(
              context: context,
              removeBottom: true,
              child: FooterNav(
                pageName: "search",
              ),
            ),
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
                fontWeight: FontWeight.w400,
              ),
              overflow: TextOverflow.ellipsis, // จัดการข้อความที่ยาวเกินไป
              textAlign: TextAlign.center, // จัดข้อความให้อยู่ตรงกลาง
            ),
          ),
        ],
      ),
    );
  }
}
