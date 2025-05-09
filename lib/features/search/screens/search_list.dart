import 'dart:typed_data';

import 'package:edugo/features/search/screens/filter.dart';
import 'package:edugo/services/auth_service.dart';
import 'package:edugo/services/scholarship_card.dart';
import 'package:edugo/shared/utils/endpoint.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class SearchList extends StatefulWidget {
  final String searchQuery;
  final Map<String, Set<String>>
      selectedFilters; // ✅ เพิ่มตัวแปร selectedFilters

  const SearchList({
    super.key,
    required this.searchQuery,
    this.selectedFilters = const {}, // ค่าเริ่มต้นเป็น {} (ป้องกัน null)
  });

  @override
  _SearchListState createState() => _SearchListState();
}

class _SearchListState extends State<SearchList> {
  late TextEditingController _searchController;
  List<dynamic> scholarships = [];
  final AuthService authService = AuthService();
  Map<String, Set<String>> selectedFilters = {};

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.searchQuery);

    // ✅ อัปเดตตัวแปร selectedFilters จาก widget.selectedFilters
    selectedFilters = Map.from(widget.selectedFilters);

    searchScholarships(widget.searchQuery, filters: selectedFilters);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> searchScholarships(String? query,
      {Map<String, Set<String>>? filters}) async {
    String searchQuery = (query == null || query.isEmpty) ? "" : query;
    List<String> queryParams = [];

    final activeFilters = filters ?? selectedFilters;
    print("Using filters: $activeFilters"); // Debug

    if (searchQuery.isNotEmpty) {
      queryParams.add("search=$searchQuery");
    }

    // เพิ่มค่าตัวกรองให้รองรับหลายค่า
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

    String url = Endpoints.searchAnnounceUser;
    if (queryParams.isNotEmpty) {
      url += "?${queryParams.join('&')}";
    }

    try {
      String? token = await authService.getToken();
      Map<String, String> headers = {};

      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      print("Fetching URL: $url"); // Debugging

      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        List<dynamic> results = data['data'] ?? [];

        setState(() {
          scholarships = results;
        });
      } else {
        throw Exception('Failed to search scholarships');
      }
    } catch (e) {
      print("Error searching scholarships: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
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
                              controller: _searchController,
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
                                            searchQuery: value,
                                            selectedFilters:
                                                selectedFilters), // ✅ ส่ง selectedFilters ไปด้วย
                                    transitionsBuilder: (context, animation,
                                        secondaryAnimation, child) {
                                      var tween = Tween(begin: 0.0, end: 1.0)
                                          .chain(CurveTween(
                                              curve: Curves.easeOut));
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
                          GestureDetector(
                            onTap: () async {
                              final filters = await openFilterDrawer(context);
                              if (filters != null) {
                                setState(() {
                                  selectedFilters = filters;
                                });
                                print(
                                    "Filters selected: $selectedFilters"); // Debug
                                searchScholarships(widget.searchQuery,
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
            Center(
              child: Text(
                "Showing results for: ${widget.searchQuery}",
                style: const TextStyle(fontSize: 18),
              ),
            ),
            scholarships.isNotEmpty
                ? ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: scholarships.length,
                    itemBuilder: (context, index) {
                      final scholarship = scholarships[index];
                      final formattedTag =
                          "#${(index + 1).toString().padLeft(5, '0')}";
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: ScholarshipCard(
                          tag: formattedTag,
                          image:
                              "${Endpoints.announce}/${scholarship['id']}/image",
                          title: scholarship['title'] ?? 'No title',
                          date: scholarship['date'] ?? 'No date available',
                          status: "",
                          description:
                              scholarship['description'] ?? 'No description',
                        ),
                      );
                    },
                  )
                : const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text("No results found"),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
