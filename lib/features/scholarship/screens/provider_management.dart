import 'dart:typed_data';
import 'dart:math'; // Import dart:math for min/max

import 'package:edugo/config/api_config.dart';
import 'package:edugo/features/scholarship/screens/provider_add.dart';
import 'package:edugo/features/scholarship/screens/provider_detail.dart';
import 'package:edugo/features/profile/screens/profile.dart';
// import 'package:edugo/features/subject/subject_manage.dart'; // Removed unused import
import 'package:edugo/services/scholarship_card.dart';
import 'package:edugo/services/status_box.dart';
// import 'package:flutter/cupertino.dart'; // Removed unused import
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:edugo/services/auth_service.dart';
import 'package:edugo/main.dart'; // Import main.dart เพื่อเข้าถึง navigatorKey

class ProviderManagement extends StatefulWidget {
  const ProviderManagement({super.key});

  @override
  State<ProviderManagement> createState() => _ProviderManagementState();
}

class _ProviderManagementState extends State<ProviderManagement> {
  // Data lists
  List<dynamic> scholarships = []; // Holds data for the current API page
  List<dynamic> _allScholarships = []; // Holds all fetched data for filtering
  List<dynamic> useItem = []; // Holds items currently displayed in the list

  // Loading states
  bool isLoading = true; // Loading API page data
  bool _isLoadingCounts = true; // Loading all data for counts/filtering

  // Image cache
  final Map<String, Uint8List?> _imageCache = {};

  // Filter state
  String selectedStatus = "All";

  // Auth service
  final AuthService authService =
      AuthService(navigatorKey: navigatorKey); // Instance of AuthService

  // API Pagination state
  int _currentPage = 1; // Current API page
  int _totalPages = 1; // Total API pages
  int _totalScholarships = 0; // Overall total from API
  final int _itemsPerPage = 10; // Define items per page (from API)

  // Filtered Pagination state
  int _currentFilteredPage = 1; // Current page within filtered results
  int _totalFilteredPages = 1; // Total pages within filtered results

  // Count state
  int _totalPendingCount = 0;
  int _totalOpenedCount = 0;
  int _totalClosedCount = 0;
  bool _countsCalculated = false; // Flag to prevent recalculating counts

  @override
  void initState() {
    super.initState();
    authService.checkSessionValidity();
    _delayedLoad();
  }

  Future<Uint8List?> fetchImage(String url) async {
    // ... existing fetchImage code ...
    if (_imageCache.containsKey(url)) {
      return _imageCache[url];
    }

    try {
      final AuthService authService = AuthService(navigatorKey: navigatorKey);
      String? token = await authService.getToken();

      Map<String, String> headers = {};
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        _imageCache[url] = response.bodyBytes; // Cache the image
        return response.bodyBytes; // โหลดรูปสำเร็จ
      } else {
        debugPrint("Failed to load image: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error fetching image: $e");
    }
    _imageCache[url] = null; // Cache null if fetch failed
    return null; // โหลดรูปไม่ได้ ให้ใช้ภาพเริ่มต้นแทน
  }

  // Fetches data for a specific API page
  Future<void> fetchScholarships(
      {int page = 1, bool refreshCounts = false}) async {
    if (!mounted) return;
    setState(() {
      isLoading = true; // Loading indicator for API page data
      if (refreshCounts) {
        _isLoadingCounts = true;
        _countsCalculated = false;
        _allScholarships.clear(); // Clear all data if refreshing counts
      }
      // Clear current API page list
      scholarships.clear();
      // Don't clear useItem here, it will be updated by _applyFilterAndPagination or directly if "All"
    });

    try {
      String? token = await authService.getToken();
      Map<String, String> headers = {};
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final Uri uri = Uri.parse('${ApiConfig.announceUrl}?page=$page');
      final response = await http.get(uri, headers: headers);

      if (!mounted) return;

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        List<dynamic> scholarshipData = data['data'] ?? [];

        List<dynamic> newScholarships = scholarshipData.map((scholarship) {
          // ... (mapping logic remains the same) ...
          scholarship['image'] =
              "${ApiConfig.announceUrl}/${scholarship['id']}/image";
          scholarship['title'] = scholarship['title'] ?? 'No Title';
          scholarship['description'] =
              scholarship['description'] ?? 'No Description Available';
          scholarship['published_date'] =
              scholarship['publish_date']; // Correct key
          scholarship['close_date'] = scholarship['close_date']; // Correct key
          scholarship['education_level'] =
              scholarship['education_level'] ?? 'No Education Level';
          scholarship['attach_name'] =
              scholarship['attach_name'] ?? 'No Attach File Name';
          return scholarship;
        }).toList();

        newScholarships
            .sort((a, b) => b['published_date'].compareTo(a['published_date']));

        // Update API pagination state
        _currentPage = data['page'] ?? 1;
        _totalPages = data['last_page'] ?? 1;
        _totalScholarships = data['total'] ?? 0;
        scholarships = newScholarships; // Store current API page data

        // Trigger total count calculation if needed
        if (!_countsCalculated && _totalPages > 0) {
          // Don't await this, let it run in the background
          _calculateAllCounts();
        }

        // Update the displayed list
        _applyFilterAndPagination();
      } else {
        throw Exception('Failed to load scholarships: ${response.statusCode}');
      }
    } catch (e) {
      if (!mounted) return;
      print("Error fetching scholarships: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading scholarships: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false; // Done loading API page data
        });
      }
    }
  }

  // Function to fetch all pages, calculate total counts, and store all data
  Future<void> _calculateAllCounts() async {
    if (_countsCalculated || !mounted) return;

    // No need to set _isLoadingCounts = true here, it's set in fetchScholarships(refreshCounts: true)

    List<dynamic> tempAllScholarships = [];
    try {
      String? token = await authService.getToken();
      Map<String, String> headers = {};
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      // Use _totalPages determined by the first fetch
      if (_totalPages < 1) {
        if (mounted) {
          setState(() {
            _isLoadingCounts = false;
            _countsCalculated = true; // Mark as calculated even if no pages
          });
        }
        return;
      }

      for (int page = 1; page <= _totalPages; page++) {
        if (!mounted) return;
        final Uri uri = Uri.parse('${ApiConfig.announceUrl}?page=$page');
        final response = await http.get(uri, headers: headers);

        if (response.statusCode == 200) {
          final Map<String, dynamic> data = json.decode(response.body);
          List<dynamic> pageData = data['data'] ?? [];

          // Map keys consistently before adding to the list
          List<dynamic> processedPageData = pageData.map((scholarship) {
            scholarship['published_date'] =
                scholarship['publish_date']; // Map original key
            scholarship['close_date'] = scholarship[
                'close_date']; // Ensure this key exists or map if needed
            // Add other mappings if necessary
            scholarship['image'] =
                "${ApiConfig.announceUrl}/${scholarship['id']}/image";
            scholarship['title'] = scholarship['title'] ?? 'No Title';
            scholarship['description'] =
                scholarship['description'] ?? 'No Description Available';
            scholarship['education_level'] =
                scholarship['education_level'] ?? 'No Education Level';
            scholarship['attach_name'] =
                scholarship['attach_name'] ?? 'No Attach File Name';
            return scholarship;
          }).toList();

          tempAllScholarships.addAll(processedPageData); // Add processed data
        } else {
          print(
              "Error fetching page $page for count calculation: ${response.statusCode}");
        }
      }

      if (!mounted) return;

      // Calculate totals (using original keys as they exist in the raw data before processing)
      int tempPending = 0;
      int tempOpened = 0;
      int tempClosed = 0;

      for (var s in tempAllScholarships) {
        // Iterate over the processed list now
        // Use the standardized keys for calculation consistency
        DateTime? publishDate = DateTime.tryParse(s['published_date'] ?? '');
        DateTime? closeDate = DateTime.tryParse(s['close_date'] ?? '');

        if (publishDate != null && publishDate.isAfter(DateTime.now())) {
          tempPending++;
        } else if (publishDate != null &&
            closeDate != null &&
            publishDate.isBefore(DateTime.now()) &&
            closeDate.isAfter(DateTime.now())) {
          tempOpened++;
        } else if (closeDate != null && closeDate.isBefore(DateTime.now())) {
          tempClosed++;
        }
      }

      // Update state
      setState(() {
        _allScholarships = tempAllScholarships; // Store processed data
        _totalPendingCount = tempPending;
        _totalOpenedCount = tempOpened;
        _totalClosedCount = tempClosed;
        _countsCalculated = true;
        _isLoadingCounts = false;
        _applyFilterAndPagination();
      });
    } catch (e) {
      if (!mounted) return;
      print("Error calculating all counts: $e");
      setState(() {
        _isLoadingCounts = false;
      });
    }
  }

  // Applies the current filter and handles pagination (client-side or API-based)
  void _applyFilterAndPagination() {
    if (!_countsCalculated && selectedStatus != "All") {
      // If counts (and thus all data) aren't ready yet for filtering, show nothing or loading
      // isLoading should handle the main loading indicator
      // We might want a specific indicator if _isLoadingCounts is true
      setState(() {
        useItem = []; // Clear items until counts/all data are loaded
      });
      return;
    }

    List<dynamic> itemsToShow = [];
    int currentPageToShow = 1;
    int totalPagesToShow = 1;

    if (selectedStatus == "All") {
      itemsToShow = scholarships; // Use current API page data
      currentPageToShow = _currentPage;
      totalPagesToShow = _totalPages;
      _totalFilteredPages = _totalPages; // Sync total filtered pages
    } else {
      // Filter from all data
      List<dynamic> filteredList = _allScholarships.where((s) {
        // Use standardized keys for filtering
        DateTime? publishDate = DateTime.tryParse(s['published_date'] ?? '');
        DateTime? closeDate = DateTime.tryParse(s['close_date'] ?? '');

        switch (selectedStatus) {
          case "Pending":
            return publishDate != null && publishDate.isAfter(DateTime.now());
          case "Opened":
            return publishDate != null &&
                closeDate != null &&
                publishDate.isBefore(DateTime.now()) &&
                closeDate.isAfter(DateTime.now());
          case "Closed":
            return closeDate != null && closeDate.isBefore(DateTime.now());
          default:
            return false;
        }
      }).toList();

      // Sort the filtered list using standardized key
      filteredList.sort((a, b) =>
          (b['published_date'] ?? '').compareTo(a['published_date'] ?? ''));

      _totalFilteredPages = (filteredList.length / _itemsPerPage).ceil();
      if (_totalFilteredPages < 1) _totalFilteredPages = 1;

      // Ensure current filtered page is valid
      _currentFilteredPage =
          max(1, min(_currentFilteredPage, _totalFilteredPages));

      // Calculate client-side pagination slice
      int startIndex = (_currentFilteredPage - 1) * _itemsPerPage;
      int endIndex = min(startIndex + _itemsPerPage, filteredList.length);

      if (startIndex < filteredList.length) {
        itemsToShow = filteredList.sublist(startIndex, endIndex);
      } else {
        itemsToShow = []; // Handle case where startIndex is out of bounds
      }

      currentPageToShow = _currentFilteredPage;
      totalPagesToShow = _totalFilteredPages;
    }

    setState(() {
      useItem = itemsToShow;
      // Update display variables if needed (though calculation is now in build)
    });
  }

  Future<void> _delayedLoad() async {
    await Future.delayed(const Duration(seconds: 1));
    // Fetch first API page and trigger count calculation
    fetchScholarships(page: 1, refreshCounts: true);
  }

  @override
  Widget build(BuildContext context) {
    // Determine if pagination controls should be shown
    bool showPaginationControls = false;
    int displayPage = 1;
    int displayTotal = 1;
    bool canGoPrev = false;
    bool canGoNext = false;

    if (!_isLoadingCounts) {
      // Only determine after counts/all data potentially loaded
      if (selectedStatus == "All") {
        showPaginationControls = _totalPages > 1;
        displayPage = _currentPage;
        displayTotal = _totalPages;
        canGoPrev = _currentPage > 1;
        canGoNext = _currentPage < _totalPages;
      } else {
        // Calculate total filtered pages again here for safety, or rely on _totalFilteredPages state
        int countForStatus = 0;
        switch (selectedStatus) {
          case "Pending":
            countForStatus = _totalPendingCount;
            break;
          case "Opened":
            countForStatus = _totalOpenedCount;
            break;
          case "Closed":
            countForStatus = _totalClosedCount;
            break;
        }
        _totalFilteredPages = (countForStatus / _itemsPerPage).ceil();
        if (_totalFilteredPages < 1) _totalFilteredPages = 1;

        showPaginationControls = _totalFilteredPages > 1;
        displayPage = _currentFilteredPage;
        displayTotal = _totalFilteredPages;
        canGoPrev = _currentFilteredPage > 1;
        canGoNext = _currentFilteredPage < _totalFilteredPages;
      }
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Blue header block
          Container(
            // ... existing header code ...
            color: const Color(0xFF355FFF),
            padding: const EdgeInsets.only(
              top: 58.0, // Keep or adjust padding as needed
              right: 16,
              left: 16,
              bottom: 22,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize:
                  MainAxisSize.min, // Allow column to determine its height
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          PageRouteBuilder(
                            pageBuilder:
                                (context, animation, secondaryAnimation) =>
                                    const ProviderProfile(),
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
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: const Color(0xFFDAFB59),
                        child: Image.asset(
                          'assets/images/back_button.png',
                          width: 20.0,
                          height: 20.0,
                          color: const Color(0xFF355FFF),
                          colorBlendMode: BlendMode.srcIn,
                        ),
                      ),
                    ),
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: const Color(0xFFC0CDFF),
                      child: Image.asset(
                        'assets/images/brower.png',
                        width: 40.0,
                        height: 40.0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  "Scholarship Management",
                  style: GoogleFonts.dmSans(
                    fontSize: 20,
                    fontStyle: FontStyle.normal,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                    color: Color(0xFFFFFFFF),
                  ),
                ),
                const SizedBox(height: 16.0), // Keep or adjust spacing
                Container(
                  height: 47.0, // Keep fixed height for search bar consistency
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        Image.asset(
                          'assets/images/search.png',
                          width: 27.0,
                          height: 27.0,
                          color: const Color(0xFF8CA4FF),
                        ),
                        const SizedBox(width: 19.0),
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: "Search for scholarship",
                              hintStyle: GoogleFonts.dmSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                color: Colors.grey[400],
                              ),
                              border: InputBorder.none,
                              isDense:
                                  true, // Make TextField take less vertical space
                              contentPadding:
                                  EdgeInsets.zero, // Remove default padding
                            ),
                            textAlignVertical: TextAlignVertical
                                .center, // Center hint text vertically
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
          Expanded(
            // Show main loading indicator if either API page or counts are loading initially
            child: (isLoading || _isLoadingCounts) && !_countsCalculated
                ? Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () =>
                        fetchScholarships(page: 1, refreshCounts: true),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(top: 16, bottom: 16),
                      child: Column(
                        children: [
                          // StatusBox row
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    if (selectedStatus != "All") {
                                      setState(() {
                                        selectedStatus = "All";
                                        _currentFilteredPage =
                                            1; // Reset filtered page
                                        // Fetch API page 1 if not already loaded, otherwise just apply filter
                                        if (_currentPage != 1 ||
                                            scholarships.isEmpty) {
                                          fetchScholarships(page: 1);
                                        } else {
                                          _applyFilterAndPagination();
                                        }
                                      });
                                    }
                                  },
                                  child: StatusBox(
                                    title: "All",
                                    color: const Color(0xFF355FFF),
                                    count: _isLoadingCounts
                                        ? "..."
                                        : _totalScholarships.toString(),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    if (selectedStatus != "Pending") {
                                      setState(() {
                                        selectedStatus = "Pending";
                                        _currentFilteredPage = 1;
                                        _applyFilterAndPagination();
                                      });
                                    }
                                  },
                                  child: StatusBox(
                                    title: "Pending",
                                    color: const Color(0xFFD9D9D9),
                                    count: _isLoadingCounts
                                        ? "..."
                                        : _totalPendingCount.toString(),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    if (selectedStatus != "Opened") {
                                      setState(() {
                                        selectedStatus = "Opened";
                                        _currentFilteredPage = 1;
                                        _applyFilterAndPagination();
                                      });
                                    }
                                  },
                                  child: StatusBox(
                                    title: "Opened",
                                    color: const Color(0xFFC4E250),
                                    count: _isLoadingCounts
                                        ? "..."
                                        : _totalOpenedCount.toString(),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    if (selectedStatus != "Closed") {
                                      setState(() {
                                        selectedStatus = "Closed";
                                        _currentFilteredPage = 1;
                                        _applyFilterAndPagination();
                                      });
                                    }
                                  },
                                  child: StatusBox(
                                    title: "Closed",
                                    color: const Color(0xFFD5448E),
                                    count: _isLoadingCounts
                                        ? "..."
                                        : _totalClosedCount.toString(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16.0),

                          // Display loading indicator specifically for API page if counts are loaded but API page isn't
                          if (isLoading && _countsCalculated)
                            Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Center(child: CircularProgressIndicator()),
                            )
                          // Display empty message if not loading and useItem is empty
                          else if (!isLoading && useItem.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 50.0, horizontal: 16.0),
                              child: Center(
                                child: Text(
                                  'No scholarships found for "$selectedStatus" status${selectedStatus != "All" ? "" : " on this page"}.', // Adjusted message
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.dmSans(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ),
                            )
                          // Display the list
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const ClampingScrollPhysics(),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16.0),
                              itemCount: useItem.length,
                              itemBuilder: (context, index) {
                                final scholarship = useItem[index];
                                final imageUrl = scholarship['image'] ??
                                    'assets/images/scholarship_1.png';
                                final title =
                                    scholarship['title'] ?? 'No Title';
                                final description =
                                    scholarship['description'] ??
                                        'No Description Available';

                                // Use standardized keys here
                                final DateTime? publishedDate =
                                    DateTime.tryParse(
                                        scholarship['published_date'] ?? '');
                                final DateTime? closeDate = DateTime.tryParse(
                                    scholarship['close_date'] ?? '');

                                // Date formatting logic (should work now)
                                final duration = (publishedDate != null &&
                                        closeDate != null)
                                    ? "${DateFormat('d MMM').format(publishedDate)} - ${DateFormat('d MMM yyyy').format(closeDate)}"
                                    : 'N/A'; // Fallback if dates are null/invalid

                                // Status calculation logic (should be correct now with valid dates)
                                String status;
                                if (publishedDate != null &&
                                    DateTime.now().isBefore(publishedDate)) {
                                  status = "Pending";
                                } else if (publishedDate !=
                                        null && // Check publish date is not null here too
                                    closeDate != null &&
                                    DateTime.now().isAfter(
                                        publishedDate) && // Ensure it's after publish date
                                    DateTime.now().isBefore(closeDate)) {
                                  status = "Open";
                                } else {
                                  status =
                                      "Closed"; // Covers past close date or invalid dates
                                }

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16.0),
                                  child: GestureDetector(
                                    onTap: () async {
                                      // Ensure standardized keys are passed to detail page
                                      final existingData = {
                                        'id': scholarship['id'],
                                        'title': scholarship['title'],
                                        'url': scholarship['url'],
                                        'category': scholarship['category'],
                                        'country': scholarship['country'],
                                        'description':
                                            scholarship['description'],
                                        'image': scholarship['image'],
                                        'attach_file':
                                            scholarship['attach_file'],
                                        'published_date': scholarship[
                                            'published_date'], // Pass standardized key
                                        'close_date': scholarship[
                                            'close_date'], // Pass standardized key
                                        'education_level':
                                            scholarship['education_level'],
                                        'attach_name':
                                            scholarship['attach_name'],
                                      };
                                      final cachedImage =
                                          await fetchImage(imageUrl);
                                      existingData['cachedImage'] = cachedImage;
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ProviderDetail(
                                            initialData: existingData,
                                            isProvider: true,
                                          ),
                                        ),
                                      );
                                    },
                                    child: ScholarshipCard(
                                      image: imageUrl,
                                      tag: "", // Assuming tag is not needed
                                      title: title,
                                      date: duration, // Pass formatted duration
                                      status: status, // Pass calculated status
                                      description: description,
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: canGoPrev
                                        ? () {
                                            if (selectedStatus == "All") {
                                              fetchScholarships(
                                                  page: _currentPage - 1);
                                            } else {
                                              setState(() {
                                                _currentFilteredPage--;
                                              });
                                              _applyFilterAndPagination();
                                            }
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
                                          borderRadius:
                                              BorderRadius.circular(8)),
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 8),
                                    ),
                                  ),
                                  Text(
                                    'Page $displayPage of $displayTotal', // Use calculated display values
                                    style: GoogleFonts.dmSans(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: canGoNext
                                        ? () {
                                            if (selectedStatus == "All") {
                                              fetchScholarships(
                                                  page: _currentPage + 1);
                                            } else {
                                              setState(() {
                                                _currentFilteredPage++;
                                              });
                                              _applyFilterAndPagination();
                                            }
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
                      ),
                    ),
                  ),
          ),
          // Add New Scholarship Button
          SizedBox(
            // ... existing button code ...
            height: 113,
            // color: const Color.fromRGBO(104, 197, 123, 1),
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding:
                    const EdgeInsets.only(top: 15.0, left: 16.0, right: 16.0),
                child: SizedBox(
                  height: 48,
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder:
                              (context, animation, secondaryAnimation) =>
                                  const ProviderAddEdit(isEdit: false),
                          transitionsBuilder:
                              (context, animation, secondaryAnimation, child) {
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
                          transitionDuration: const Duration(milliseconds: 300),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF355FFF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Add New Scholarship",
                          style: GoogleFonts.dmSans(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Image.asset(
                          'assets/images/add_new_scholarship.png',
                          width: 21.0,
                          height: 21.0,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
