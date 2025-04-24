import 'package:edugo/config/api_config.dart';
import 'package:edugo/features/scholarship/screens/provider_detail.dart';
import 'package:edugo/shared/utils/textStyle.dart';
import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:edugo/features/scholarship/screens/provider_management.dart';
import 'package:edugo/features/profile/screens/profile.dart';
import 'package:edugo/features/subject/subject_add_edit.dart';
import 'package:edugo/features/subject/subject_detail.dart';
import 'package:edugo/services/auth_service.dart';
import 'package:edugo/services/footer.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http_parser/http_parser.dart';
import 'package:edugo/main.dart'; // Import main.dart เพื่อเข้าถึง navigatorKey

class BookmarkList extends StatefulWidget {
  final int id; // เพิ่มตัวแปร id

  const BookmarkList({super.key, required this.id});

  @override
  State<BookmarkList> createState() => _BookmarkListState();
}

class _BookmarkListState extends State<BookmarkList> {
  final AuthService authService = AuthService(navigatorKey: navigatorKey);
  List<dynamic> bookmarks = [];
  bool isFetching = false; // ป้องกันการโหลดซ้ำซ้อน
  final Map<String, Uint8List?> _imageCache = {};
  final Map<String, Uint8List?> _imageAvatarCache = {};
  final Map<String, Future<Uint8List?>> _avatarFutureCache = {};
  final Map<String, Future<String?>> _providerNameFutureCache = {};
  String? providerName;
  bool showPaginationControls = false;
  int displayPage = 1;
  int displayTotal = 1;
  bool canGoPrev = false;
  bool canGoNext = false;

  // API Pagination state
  int _currentPage = 1; // Current API page
  int _totalPages = 1; // Total API pages
  int _totalScholarships = 0; // Overall total from API
  final int _itemsPerPage = 10; // Define items per page (from API)

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    fetchBookmark(); // โหลดทุกครั้งที่เข้า
  }

  List<int> announceIds = []; // เก็บแค่ announce_id
  Map<String, dynamic> announceDetails = {};

  Future<void> fetchBookmark() async {
    String? token = await authService.getToken();
    Map<String, String> headers = {};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    final url = "${ApiConfig.bookmarkUrl}/acc/${widget.id}";

    try {
      final response = await http.get(Uri.parse(url), headers: headers);
      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);

        setState(() {
          bookmarks = responseData; // เก็บข้อมูลเต็ม

          // ใช้ Set เพื่อเก็บ announce_id ไม่ให้ซ้ำ
          announceIds = responseData
              .map<int>(
                  (item) => item['announce_id'] as int) // ดึงเฉพาะ announce_id
              .toSet() // ลบค่าซ้ำ
              .toList(); // แปลงกลับเป็น List
        });
        fetchAnnounceDetails();
      } else {
        throw Exception('Failed to load bookmarks');
      }
    } catch (e) {
      print("Error fetching bookmarks: $e");
    }
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

  Future<void> fetchAnnounceDetails(
      {page = 1, bool refreshCounts = false}) async {
    String? token = await authService.getToken();

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.bookmarkUser}?page=$page'),
        headers: {
          'Authorization': token != null ? 'Bearer $token' : '',
          'Content-Type': 'application/json',
        },
        body: json.encode({"announce_id": announceIds}), // ส่งเป็น JSON
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        setState(() {
          announceDetails = responseData; // เก็บข้อมูลที่ได้
          _currentPage = responseData['page'] ?? 1;
          _totalPages = responseData['last_page'] ?? 1;
          _totalScholarships = responseData['total'] ?? 0;
          showPaginationControls = _totalPages > 1;
        });
      } else {
        throw Exception('Failed to load announcement details');
      }
    } catch (e) {
      print("Error fetching announce details: $e");
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

  Future<void> deleteBookmark(int id) async {
    String? token = await authService.getToken();
    final url = "${ApiConfig.bookmarkUrl}/ann/${id}";

    try {
      final response = await http.delete(Uri.parse(url), headers: {
        'Authorization': token != null ? 'Bearer $token' : '',
        'Content-Type': 'application/json',
      });

      if (response.statusCode == 200) {
        fetchBookmark();
      } else {
        throw Exception('Failed to load announcement details');
      }
    } catch (e) {
      print("Error fetching announce details: $e");
    }
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
      body: Column(
        children: [
          // Header
          Container(
            color: const Color(0xFF355FFF),
            padding: const EdgeInsets.only(
              top: 72.0,
              right: 16,
              left: 16,
              bottom: 22,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            const PersonalProfile(),
                        transitionsBuilder:
                            (context, animation, secondaryAnimation, child) {
                          const begin = 0.0;
                          const end = 1.0;
                          const curve = Curves.easeOut;
                          var tween = Tween(begin: begin, end: end)
                              .chain(CurveTween(curve: curve));
                          return FadeTransition(
                              opacity: animation.drive(tween), child: child);
                        },
                        transitionDuration: const Duration(milliseconds: 300),
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
                    ),
                  ),
                ),
                Text(
                  "Bookmark",
                  style: GoogleFonts.dmSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFFFFFFFF),
                  ),
                ),
                GestureDetector(
                  onTap: () {},
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: const Color(0xFF355FFF),
                    // child: Image.asset(
                    //   'assets/images/notification.png',
                    //   width: 40.0,
                    //   height: 40.0,
                    // ),
                  ),
                ),
              ],
            ),
          ),

          // แสดงข้อมูล bookmarks
          Expanded(
            child: announceDetails.isNotEmpty && announceDetails['data'] != null
                ? Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          itemCount: announceDetails['data'].length,
                          itemBuilder: (context, index) {
                            final item = announceDetails['data'][index];
                            final title = item['title'];
                            final DateTime publishedDate =
                                DateTime.tryParse(item['publish_date']) ??
                                    DateTime.now();
                            final DateTime closeDate =
                                DateTime.tryParse(item['close_date']) ??
                                    DateTime.now();
                            final String imageUrl =
                                "${ApiConfig.announceUserUrl}/${item['id']}/image";
                            final duration =
                                "${DateFormat('d MMM').format(publishedDate)} - ${DateFormat('d MMM yyyy').format(closeDate)}";
                            final String providerNameUrl =
                                "${ApiConfig.providerUrl}/${item['provider_id']}";
                            final String providerImage =
                                "${ApiConfig.providerUrl}/avatar/${item['provider_id']}";

                            return Padding(
                              padding: const EdgeInsets.only(
                                  left: 25.0, right: 25.0, bottom: 25.0),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: InkWell(
                                  onTap: () async {
                                    final existingData = {'id': item['id']};
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ProviderDetail(
                                          initialData: existingData,
                                          isProvider: false,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    height: 192,
                                    width: double.infinity,
                                    color: const Color(0xFFECF0F6),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 22, vertical: 12),
                                      child: Row(
                                        children: [
                                          ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(12.0),
                                            child: _imageCache
                                                    .containsKey(imageUrl)
                                                ? (_imageCache[imageUrl] != null
                                                    ? Image.memory(
                                                        _imageCache[imageUrl]!,
                                                        width: 111,
                                                        height: 148,
                                                        fit: BoxFit.cover,
                                                      )
                                                    : Image.asset(
                                                        "assets/images/scholarship_program.png",
                                                        width: 111,
                                                        height: 148,
                                                        fit: BoxFit.cover,
                                                      ))
                                                : FutureBuilder<Uint8List?>(
                                                    future:
                                                        fetchImage(imageUrl),
                                                    builder:
                                                        (context, snapshot) {
                                                      if (snapshot
                                                              .connectionState ==
                                                          ConnectionState
                                                              .waiting) {
                                                        return const SizedBox(
                                                          width: 111,
                                                          height: 148,
                                                          child: Center(
                                                              child:
                                                                  CircularProgressIndicator()),
                                                        );
                                                      }
                                                      if (snapshot.data ==
                                                          null) {
                                                        return Image.asset(
                                                          "assets/images/scholarship_program.png",
                                                          width: 111,
                                                          height: 148,
                                                          fit: BoxFit.cover,
                                                        );
                                                      }
                                                      return Image.memory(
                                                        snapshot.data!,
                                                        width: 111,
                                                        height: 148,
                                                        fit: BoxFit.cover,
                                                      );
                                                    },
                                                  ),
                                          ),
                                          const SizedBox(width: 24),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  duration,
                                                  style: TextStyleService
                                                      .getDmSans(
                                                    color: Color(0xFF2A4CCC),
                                                    fontSize: 9.5,
                                                    fontWeight: FontWeight.w400,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  title,
                                                  style: TextStyleService
                                                      .getDmSans(
                                                    color: Color(0xFF000000),
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Row(
                                                  children: [
                                                    CircleAvatar(
                                                      radius: 6,
                                                      backgroundImage: _imageCache
                                                                  .containsKey(
                                                                      providerImage) &&
                                                              _imageCache[
                                                                      providerImage] !=
                                                                  null
                                                          ? MemoryImage(
                                                              _imageCache[
                                                                  providerImage]!)
                                                          : null,
                                                      child: !_imageCache
                                                              .containsKey(
                                                                  providerImage)
                                                          ? FutureBuilder<
                                                              Uint8List?>(
                                                              future: getAvatarFuture(
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
                                                                      height:
                                                                          40,
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
                                                      child: FutureBuilder<
                                                          String?>(
                                                        future:
                                                            getProviderNameFuture(
                                                                providerNameUrl),
                                                        builder: (context,
                                                            snapshot) {
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
                                                          if (snapshot
                                                                  .hasError ||
                                                              snapshot.data ==
                                                                  null) {
                                                            return Text(
                                                              "Unknown",
                                                              style:
                                                                  TextStyleService
                                                                      .getDmSans(
                                                                fontSize: 9.5,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w400,
                                                                color: Color(
                                                                    0xFF94A2B8),
                                                              ),
                                                            );
                                                          }
                                                          return Text(
                                                            snapshot.data!,
                                                            maxLines: 1,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            style:
                                                                TextStyleService
                                                                    .getDmSans(
                                                              fontSize: 9.5,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w400,
                                                              color: Color(
                                                                  0xFF94A2B8),
                                                            ),
                                                          );
                                                        },
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
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
                                        fetchAnnounceDetails(
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
                                      borderRadius: BorderRadius.circular(8)),
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                ),
                              ),
                              Text(
                                'Page $displayPage of $displayTotal',
                                style: TextStyleService.getDmSans(
                                    fontSize: 14, fontWeight: FontWeight.w500),
                              ),
                              ElevatedButton.icon(
                                onPressed: canGoNext
                                    ? () {
                                        fetchAnnounceDetails(
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
                                      borderRadius: BorderRadius.circular(8)),
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  )
                : const Center(child: CircularProgressIndicator()),
          )
        ],
      ),
    );
  }
}
