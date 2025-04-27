import 'dart:typed_data';

import 'package:edugo/features/search/screens/filter.dart';
import 'package:edugo/services/auth_service.dart';
import 'package:edugo/services/scholarship_card.dart';
import 'package:edugo/shared/utils/textStyle.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:edugo/config/api_config.dart';
import 'package:edugo/main.dart'; // Import main.dart เพื่อเข้าถึง navigatorKey
import 'package:edugo/features/scholarship/screens/provider_detail.dart'; // Import ProviderDetail
import 'package:intl/intl.dart'; // Import DateFormat

class SearchList extends StatefulWidget {
  final String searchQuery;
  final Map<String, Set<String>>? selectedFilters;

  const SearchList({
    Key? key,
    required this.searchQuery,
    this.selectedFilters,
  }) : super(key: key);

  @override
  State<SearchList> createState() => _SearchListState(); // เพิ่มส่วนนี้
}

class _SearchListState extends State<SearchList> {
  late TextEditingController _searchController;
  List<dynamic> scholarships = [];
  final AuthService authService =
      AuthService(navigatorKey: navigatorKey); // Instance of AuthService
  Map<String, Set<String>> selectedFilters = {};
  final Map<String, Uint8List?> _imageCache = {}; // Add image cache

  // API Pagination state
  int _currentPage = 1; // Current API page
  int _totalPages = 1; // Total API pages
  int _totalScholarships = 0; // Overall total from API
  final int _itemsPerPage = 10; // Define items per page (from API)
  bool showPaginationControls = false;
  int displayPage = 1;
  int displayTotal = 1;
  bool canGoPrev = false;
  bool canGoNext = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.searchQuery);

    selectedFilters = Map.from(widget.selectedFilters ?? {});

    searchScholarships(query: widget.searchQuery, filters: selectedFilters);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
        final imageBytes = response.bodyBytes;
        _imageCache[url] = imageBytes;
        return imageBytes;
      } else {
        debugPrint("Failed to load image: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error fetching image: $e");
    }
    _imageCache[url] = null; // Cache null if failed
    return null;
  }

  Future<void> searchScholarships({
    int page = 1,
    bool refreshCounts = false,
    String? query,
    Map<String, Set<String>>? filters,
  }) async {
    String searchQuery = (query == null || query.isEmpty) ? "" : query;
    List<String> queryParams = [];

    final activeFilters = filters ?? selectedFilters;

    if (searchQuery.isNotEmpty) {
      queryParams.add("search=$searchQuery");
    }

    if (activeFilters.containsKey('educationLevels') &&
        activeFilters['educationLevels']!.isNotEmpty) {
      queryParams.addAll(activeFilters['educationLevels']!
          .map((level) => "education_level=$level"));
    }

    if (activeFilters.containsKey('scholarshipTypes') &&
        activeFilters['scholarshipTypes']!.isNotEmpty) {
      queryParams.addAll(
          activeFilters['scholarshipTypes']!.map((type) => "category=$type"));
    }

    if (activeFilters.containsKey('countries') &&
        activeFilters['countries']!.isNotEmpty) {
      queryParams.add("country=${activeFilters['countries']!.first}");
    }

    String url = ApiConfig.searchAnnounceUrl;
    if (queryParams.isNotEmpty) {
      url += "?${queryParams.join('&')}";
    }

    String paginatedUrl =
        url.contains('?') ? '$url&page=$page' : '$url?page=$page';

    try {
      String? token = await authService.getToken();
      Map<String, String> headers = {};

      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response =
          await http.get(Uri.parse(paginatedUrl), headers: headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        List<dynamic> results = data['data'] ?? [];

        _currentPage = data['page'] ?? 1;
        _totalPages = data['last_page'] ?? 1;
        _totalScholarships = data['total'] ?? 0;

        setState(() {
          scholarships = results.map((scholarship) {
            scholarship['image'] = scholarship['image'] != null
                ? "${ApiConfig.announceUserUrl}/${scholarship['id']}/image"
                : 'assets/images/scholarship_program.png'; // Keep image URL logic
            scholarship['title'] = scholarship['title'] ?? 'No Title';
            scholarship['description'] =
                scholarship['description'] ?? 'No Description Available';
            // Ensure dates are correctly mapped or handled if null
            scholarship['published_date'] =
                scholarship['published_date'] ?? scholarship['publish_date'];
            scholarship['close_date'] = scholarship[
                'close_date']; // Assuming close_date is the correct key
            scholarship['url'] = scholarship['url']; // Add URL if available
            scholarship['category'] =
                scholarship['category']; // Add category if available
            scholarship['country'] =
                scholarship['country']; // Add country if available
            scholarship['education_level'] = scholarship[
                'education_level']; // Add education level if available
            scholarship['attach_file'] =
                scholarship['attach_file']; // Add attach_file if available
            scholarship['attach_name'] =
                scholarship['attach_name']; // Add attach_name if available
            return scholarship;
          }).toList();

          // Optional: Sort results if needed
          scholarships.sort((a, b) {
            DateTime? dateA = DateTime.tryParse(a['published_date'] ?? '');
            DateTime? dateB = DateTime.tryParse(b['published_date'] ?? '');
            if (dateA == null && dateB == null) return 0;
            if (dateA == null) return 1; // Put nulls last
            if (dateB == null) return -1; // Put nulls last

            showPaginationControls = _totalPages > 1;
            return dateB.compareTo(dateA); // Sort descending by date
          });
        });
      } else {
        throw Exception('Failed to search scholarships');
      }
    } catch (e) {
      print("Error searching scholarships: $e");
      setState(() {
        scholarships = []; // Clear scholarships on error
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    displayPage = _currentPage;
    displayTotal = _totalPages;
    canGoPrev = _currentPage > 1;
    canGoNext = _currentPage < _totalPages;

    return Scaffold(
      body: Column(
        // Changed to Column to include FooterNav
        children: [
          Expanded(
            // Wrap SingleChildScrollView with Expanded
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    height: 141,
                    color: const Color(0xFF355FFF),
                    padding: const EdgeInsets.only(
                        top: 58.0, right: 16, left: 16, bottom: 27),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                                GestureDetector(
                                  onTap: () =>
                                      Navigator.pop(context), // Go back
                                  child: Icon(Icons.arrow_back_ios,
                                      color: Color(0xFF8CA4FF)),
                                ),
                                const SizedBox(
                                    width: 10.0), // Spacing after back button
                                Expanded(
                                  child: TextField(
                                    controller: _searchController,
                                    decoration: InputDecoration(
                                      hintText: "Search Experiences",
                                      hintStyle: TextStyleService.getDmSans(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w400,
                                        color:
                                            Color.fromARGB(255, 130, 130, 132),
                                      ),
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                    style: TextStyleService.getDmSans(
                                      // Added style
                                      fontSize: 16,
                                      fontWeight: FontWeight.w400,
                                      color: Colors.black,
                                    ),
                                    textAlignVertical: TextAlignVertical
                                        .center, // Added alignment
                                    onSubmitted: (value) {
                                      // Trigger search when submitted
                                      searchScholarships(
                                          query: value,
                                          filters: selectedFilters);
                                    },
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () async {
                                    final filters =
                                        await openFilterDrawer(context);
                                    if (filters != null) {
                                      setState(() {
                                        selectedFilters = filters;
                                      });
                                      searchScholarships(
                                          query: _searchController
                                              .text, // Use current text
                                          filters: selectedFilters);
                                    }
                                  },
                                  child: Image.asset(
                                    'assets/images/three-line.png',
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
                  scholarships.isNotEmpty
                      ? Column(
                          children: [
                            ListView.builder(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16.0),
                              itemCount: scholarships.length,
                              itemBuilder: (context, index) {
                                final scholarship = scholarships[index];
                                final formattedTag =
                                    "#${(index + 1).toString().padLeft(5, '0')}"; // Keep tag if needed

                                // Prepare data for navigation
                                final String imageUrl = scholarship['image'] ??
                                    'assets/images/scholarship_program.png';
                                final DateTime? publishedDate =
                                    DateTime.tryParse(
                                        scholarship['published_date'] ?? '');
                                final DateTime? closeDate = DateTime.tryParse(
                                    scholarship['close_date'] ?? '');
                                final String duration = (publishedDate !=
                                            null &&
                                        closeDate != null)
                                    ? "${DateFormat('d MMM').format(publishedDate)} - ${DateFormat('d MMM yyyy').format(closeDate)}"
                                    : 'Date N/A'; // Handle null dates

                                return GestureDetector(
                                  // Wrap with GestureDetector
                                  onTap: () async {
                                    final existingData = {
                                      'id': scholarship['id'],
                                      'title': scholarship['title'],
                                      'url': scholarship['url'],
                                      'category': scholarship['category'],
                                      'country': scholarship['country'],
                                      'description': scholarship['description'],
                                      'image': scholarship[
                                          'image'], // Pass the original image URL or path
                                      'attach_file': scholarship['attach_file'],
                                      'published_date':
                                          scholarship['published_date'],
                                      'close_date': scholarship['close_date'],
                                      'education_level':
                                          scholarship['education_level'],
                                      'attach_name': scholarship['attach_name'],
                                    };

                                    // Fetch and add cached image
                                    final cachedImage =
                                        await fetchImage(imageUrl);
                                    existingData['cachedImage'] = cachedImage;
                                    existingData['previousRouteName'] =
                                        'search_list'; // Indicate source

                                    Navigator.push(
                                      context,
                                      PageRouteBuilder(
                                        pageBuilder: (context, animation,
                                                secondaryAnimation) =>
                                            ProviderDetail(
                                          initialData: existingData,
                                          isProvider: false, // User is seeking
                                          previousRouteName:
                                              'search_list', // Pass separately
                                          searchQuery: _searchController
                                              .text, // Pass current search query
                                          selectedFilters:
                                              selectedFilters, // Pass current filters
                                        ),
                                        transitionsBuilder: (context, animation,
                                            secondaryAnimation, child) {
                                          const begin = 0.0;
                                          const end = 1.0;
                                          const curve = Curves.easeOut;
                                          var tween = Tween(
                                                  begin: begin, end: end)
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
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 8.0),
                                    child: ScholarshipCard(
                                      // Use the existing card
                                      // tag:
                                      //     formattedTag, // Pass tag if needed by card
                                      tag: "",
                                      image: imageUrl, // Pass image URL
                                      title: scholarship['title'] ?? 'No title',
                                      date:
                                          duration, // Pass formatted date string
                                      status:
                                          "", // Determine status based on dates if needed
                                      description: scholarship['description'] ??
                                          'No description',
                                    ),
                                  ),
                                );
                              },
                            ),
                            if (showPaginationControls)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 16.0, horizontal: 16.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: canGoPrev
                                          ? () {
                                              searchScholarships(
                                                  page: _currentPage - 1,
                                                  refreshCounts: true);
                                            }
                                          : null,
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
                                            borderRadius:
                                                BorderRadius.circular(8)),
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 8),
                                      ),
                                    ),
                                    Text(
                                      'Page $displayPage of $displayTotal',
                                      style: TextStyleService.getDmSans(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500),
                                    ),
                                    ElevatedButton.icon(
                                      onPressed: canGoNext
                                          ? () {
                                              searchScholarships(
                                                  page: _currentPage + 1,
                                                  refreshCounts: true);
                                            }
                                          : null,
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
                                            borderRadius:
                                                BorderRadius.circular(8)),
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        )
                      : const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text("No results found"),
                          ),
                        ),
                  const SizedBox(height: 20), // Add spacing at the bottom
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
