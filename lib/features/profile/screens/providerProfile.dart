import 'dart:convert';
import 'dart:typed_data';
import 'package:edugo/config/api_config.dart';
import 'package:edugo/features/account/screens/manage_account.dart';
import 'package:edugo/features/bookmark/screens/bookmark_management.dart';
import 'package:edugo/features/login&register/login.dart';
import 'package:edugo/features/notification/screens/notification_management.dart';
import 'package:edugo/features/scholarship/screens/provider_detail.dart';
import 'package:edugo/shared/utils/textStyle.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:edugo/features/profile/screens/edit_profile.dart';
import 'package:edugo/features/scholarship/screens/provider_management.dart';
import 'package:edugo/features/subject/subject_add_edit.dart';
import 'package:edugo/features/subject/subject_manage.dart';
import 'package:edugo/services/auth_service.dart';
import 'package:edugo/services/footer.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:edugo/main.dart'; // Import main.dart เพื่อเข้าถึง navigatorKey
import 'package:edugo/features/profile/screens/change_password.dart'; // Import the new screen
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart'; // นำเข้า DateFormat

class ProviderProfile extends StatefulWidget {
  final Map<String, dynamic>? initialData;
  const ProviderProfile({
    super.key,
    this.initialData,
  });

  @override
  State<ProviderProfile> createState() => _ProviderProfileState();
}

final double coverHeight = 152;
final double profileHeight = 90;

class _ProviderProfileState extends State<ProviderProfile> {
  // แก้ไขการสร้าง AuthService instance
  final AuthService authService = AuthService(navigatorKey: navigatorKey);
  final top = coverHeight - profileHeight / 2;
  final bottom = profileHeight / 2;
  final arrow = const Icon(Icons.arrow_forward_ios, size: 15);
  List<dynamic> providerScholarship = [];

  @override
  void initState() {
    super.initState();
    authService.checkSessionValidity(); // เพิ่มการตรวจสอบ session ที่นี่
    fetchProviderDetail(widget.initialData?['provider_id']);
    fetchProviderAvatar(widget.initialData?['provider_id']);
    fetchProviderScholarships();
  }

  Uint8List? imageAvatar;

  String? providerCompanyName;
  String? providerUsername;
  String? providerUrl;

  Future<void> fetchProviderDetail(int id) async {
    String? token = await authService.getToken();

    final response = await http.get(
      Uri.parse("${ApiConfig.providerUrl}/$id"),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> providerData = json.decode(response.body);
      providerCompanyName = providerData['company_name'];
      providerUsername = providerData['username'];
      providerUrl = providerData['url'];
      setState(() {});
    } else {
      throw Exception('Failed to load country data');
    }
  }

  Future<void> fetchProviderAvatar(int id) async {
    String? token = await authService.getToken();

    final response = await http.get(
      Uri.parse("${ApiConfig.providerAvatarUrl}/$id"),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        imageAvatar = response.bodyBytes; // แปลง response เป็น Uint8List
      });
    } else {}
  }

  bool isLoading = true;
  bool showPaginationControls = false;
  int displayPage = 1;
  int displayTotal = 1;
  bool canGoPrev = false;
  bool canGoNext = false;
  int _currentPage = 1;
  int _totalPages = 1; // Total API pages
  int _totalScholarships = 0; // Overall total from API

  final Map<String, Uint8List?> _imageCache = {};

  Future<void> fetchProviderScholarships(
      {int page = 1, bool refreshCounts = false}) async {
    if (!mounted) return;
    setState(() {
      isLoading = true; // Loading indicator for API page data
      if (refreshCounts) {
        providerScholarship.clear(); // Clear all data if refreshing counts
      }
      // Clear current API page list
      providerScholarship.clear();

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
        Uri.parse(
            '${ApiConfig.announceUserUrl}/provider/${widget.initialData?['provider_id']}?page=$page'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        List<dynamic> scholarshipData = data['data'] ?? [];

        setState(() {
          providerScholarship =
              scholarshipData.map<Map<String, dynamic>>((item) {
            final String AnnounceId = item['id'].toString();
            return {
              'id': item['id'],
              'image': item['image'] != null
                  ? "${ApiConfig.announceUserUrl}/$AnnounceId/image"
                  : 'assets/images/scholarship_program.png',
              'title': item['title'] ?? 'No Title',
              'description': item['description'] ?? 'No Description Available',
              'published_date':
                  item['published_date'] ?? item['publish_date'] ?? '',
              'close_date': item['close_date'] ?? '',
              'provider_id': item['provider_id'] ?? '',
            };
          }).toList();

          providerScholarship.sort((a, b) {
            final aDate = DateTime.tryParse(a['published_date']) ?? DateTime(0);
            final bDate = DateTime.tryParse(b['published_date']) ?? DateTime(0);
            return bDate.compareTo(aDate);
          });
          _currentPage = data['page'] ?? 1;
          _totalPages = data['last_page'] ?? 1;
          _totalScholarships = data['total'] ?? 0;
        });
      } else {
        throw Exception('Failed to load scholarships: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {}); // Consider showing an error message instead
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
    int? id = widget.initialData?['provider_id'];

    return Scaffold(
      backgroundColor: Color(0xFFFFFFFF),
      body: Stack(
        children: [
          Positioned.fill(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // Cover Image Section
                Container(
                  color: Colors.white, // Background color
                  child: Column(
                    children: [
                      SizedBox(
                        height: coverHeight,
                        child: Container(
                          color: const Color(0xFF355FFF),
                          child: Stack(
                            clipBehavior: Clip.none,
                            alignment: Alignment.center,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        final existingData = {
                                          'id': id,
                                        };

                                        Navigator.pushReplacement(
                                          context,
                                          PageRouteBuilder(
                                            pageBuilder: (context, animation,
                                                    secondaryAnimation) =>
                                                ProviderDetail(
                                                    isProvider: false,
                                                    initialData: existingData),
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
                                            transitionDuration: const Duration(
                                                milliseconds: 300),
                                          ),
                                        );
                                      },
                                      child: CircleAvatar(
                                        backgroundColor:
                                            const Color(0xFFDAFB59),
                                        child: Image.asset(
                                          'assets/images/back_button.png',
                                          width: 20.0,
                                          height: 20.0,
                                          color: const Color(0xFF355FFF),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Positioned(
                                top: top,
                                child: Container(
                                  margin: EdgeInsets.only(bottom: bottom),
                                  width: profileHeight,
                                  height: profileHeight,
                                  decoration: BoxDecoration(
                                    color: Colors.grey, // Background color
                                    borderRadius: BorderRadius.circular(
                                        profileHeight / 2),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(
                                        profileHeight / 2),
                                    child: imageAvatar == null
                                        ? Image.asset(
                                            'assets/images/avatar.png',
                                            fit: BoxFit
                                                .cover, // สำคัญ! เพื่อให้รูปเต็มวงกลม
                                          )
                                        : Image.memory(
                                            imageAvatar!,
                                            fit: BoxFit.cover, // เช่นเดียวกัน
                                          ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Profile Options Section
                Container(
                  margin: EdgeInsets.only(top: bottom),
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Text(
                          providerCompanyName ?? "No Name Available",
                          style: GoogleFonts.dmSans(
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF000000)),
                        ),
                      ),
                      // Center(
                      //   child: Text(
                      //     "@$providerUsername",
                      //     style: GoogleFonts.dmSans(
                      //         fontSize: 12,
                      //         fontWeight: FontWeight.w400,
                      //         color: Color(0xFF94A2B8)),
                      //   ),
                      // ),
                      if (providerUrl != null && providerUrl != '')
                        if (providerUrl?.isNotEmpty == true)
                          Center(
                            child: GestureDetector(
                              onTap: () async {
                                final Uri url = Uri.parse(providerUrl!);

                                try {
                                  await launchUrl(url,
                                      mode: LaunchMode.externalApplication);
                                } catch (e) {
                                  print('เกิดข้อผิดพลาดในการเปิด URL: $e');
                                }
                              },
                              child: Text(
                                providerUrl!,
                                style: GoogleFonts.dmSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xFF94A2B8),
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
                      SizedBox(height: 20),
                      Text(
                        "All Provider Scholarship",
                        style: TextStyleService.getDmSans(
                            color: Color(0xFF000000),
                            fontSize: 16,
                            fontWeight: FontWeight.w400),
                      ),
                      SizedBox(height: 16),
                      GridView.builder(
                        shrinkWrap: true,
                        physics:
                            NeverScrollableScrollPhysics(), // ปิด scroll เพราะมี scroll ข้างนอกแล้ว
                        padding: const EdgeInsets.symmetric(horizontal: 0.0),
                        itemCount: providerScholarship.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2, // จำนวนคอลัมน์ = 2
                          crossAxisSpacing: 16.0, // ระยะห่างระหว่างคอลัมน์
                          mainAxisSpacing: 12.0, // ระยะห่างระหว่างแถว
                          childAspectRatio:
                              0.63, // สัดส่วนความสูง/กว้าง ของแต่ละ item
                        ),
                        itemBuilder: (context, index) {
                          final scholarship = providerScholarship[index];

                          final int = scholarship['id'];

                          final DateTime publishedDate = DateTime.tryParse(
                                  scholarship['published_date']) ??
                              DateTime.now();
                          final DateTime closeDate =
                              DateTime.tryParse(scholarship['close_date']) ??
                                  DateTime.now();
                          final String imageUrl =
                              "${ApiConfig.announceUserUrl}/${scholarship['id']}/image";
                          final duration =
                              "${DateFormat('d MMM').format(publishedDate)} - ${DateFormat('d MMM yyyy').format(closeDate)}";

                          return GestureDetector(
                            onTap: () async {
                              final existingData = {'id': scholarship['id']};

                              Navigator.pushReplacement(
                                context,
                                PageRouteBuilder(
                                  pageBuilder: (context, animation,
                                          secondaryAnimation) =>
                                      ProviderDetail(
                                          isProvider: false,
                                          initialData: existingData),
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
                                                height: 240,
                                                fit: BoxFit.cover,
                                              )
                                            : Image.asset(
                                                "assets/images/scholarship_program.png",
                                                width: 200,
                                                height: 240,
                                                fit: BoxFit.cover,
                                              ))
                                        : FutureBuilder<Uint8List?>(
                                            future: fetchImage(imageUrl),
                                            builder: (context, snapshot) {
                                              if (snapshot.connectionState ==
                                                  ConnectionState.waiting) {
                                                return const SizedBox(
                                                  width: 200,
                                                  height: 240,
                                                  child: Center(
                                                      child:
                                                          CircularProgressIndicator()),
                                                );
                                              }
                                              if (snapshot.data == null) {
                                                return Image.asset(
                                                  "assets/images/scholarship_program.png",
                                                  width: 200,
                                                  height: 240,
                                                  fit: BoxFit.cover,
                                                );
                                              }
                                              return Image.memory(
                                                snapshot.data!,
                                                width: 200,
                                                height: 240,
                                                fit: BoxFit.cover,
                                              );
                                            },
                                          ),
                                  ),
                                  const SizedBox(height: 10.0),
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
                                                style:
                                                    TextStyleService.getDmSans(
                                                        fontSize: 11,
                                                        color:
                                                            Color(0xFF2A4CCC),
                                                        fontWeight:
                                                            FontWeight.w400),
                                              ),
                                              const SizedBox(height: 4.0),
                                              Text(
                                                scholarship['title'],
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style:
                                                    TextStyleService.getDmSans(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: Color(0xFF000000),
                                                ),
                                              ),
                                              // const SizedBox(height: 4.0),
                                              // SizedBox(
                                              //   width: double.infinity,
                                              //   child: Row(
                                              //     crossAxisAlignment:
                                              //         CrossAxisAlignment.center,
                                              //     children: [
                                              //       CircleAvatar(
                                              //         radius: 6,
                                              //         backgroundImage: _imageCache
                                              //                     .containsKey(
                                              //                         providerImage) &&
                                              //                 _imageCache[
                                              //                         providerImage] !=
                                              //                     null
                                              //             ? MemoryImage(_imageCache[
                                              //                 providerImage]!) // ใช้ภาพจากแคช
                                              //             : null, // ถ้าไม่มีภาพในแคช
                                              //         child: !_imageCache
                                              //                 .containsKey(
                                              //                     providerImage)
                                              //             ? FutureBuilder<
                                              //                 Uint8List?>(
                                              //                 future: getAvatarFuture(
                                              //                     providerImage),
                                              //                 builder: (context,
                                              //                     snapshot) {
                                              //                   if (snapshot
                                              //                           .connectionState ==
                                              //                       ConnectionState
                                              //                           .waiting) {
                                              //                     return const Center(
                                              //                       child:
                                              //                           CircularProgressIndicator(),
                                              //                     );
                                              //                   }
                                              //                   if (snapshot
                                              //                           .data ==
                                              //                       null) {
                                              //                     return ClipOval(
                                              //                       child: Image
                                              //                           .asset(
                                              //                         "assets/images/avatar.png",
                                              //                         fit: BoxFit
                                              //                             .cover,
                                              //                         width: 40,
                                              //                         height:
                                              //                             40,
                                              //                       ),
                                              //                     );
                                              //                   }
                                              //                   return CircleAvatar(
                                              //                     radius: 20,
                                              //                     backgroundImage:
                                              //                         MemoryImage(
                                              //                             snapshot
                                              //                                 .data!),
                                              //                   );
                                              //                 },
                                              //               )
                                              //             : null,
                                              //       ),
                                              //       const SizedBox(width: 4.0),
                                              //       Expanded(
                                              //         child: FutureBuilder<
                                              //             String?>(
                                              //           future:
                                              //               getProviderNameFuture(
                                              //                   providerName),
                                              //           builder: (context,
                                              //               snapshot) {
                                              //             if (snapshot
                                              //                     .connectionState ==
                                              //                 ConnectionState
                                              //                     .waiting) {
                                              //               return const SizedBox(
                                              //                 width: 60,
                                              //                 height: 10,
                                              //                 child:
                                              //                     LinearProgressIndicator(),
                                              //               );
                                              //             }
                                              //             if (snapshot
                                              //                     .hasError ||
                                              //                 snapshot.data ==
                                              //                     null) {
                                              //               return Text(
                                              //                 "Unknown",
                                              //                 style:
                                              //                     TextStyleService
                                              //                         .getDmSans(
                                              //                   fontSize: 9.415,
                                              //                   fontWeight:
                                              //                       FontWeight
                                              //                           .w400,
                                              //                   color: Color(
                                              //                       0xFF000000),
                                              //                 ),
                                              //               );
                                              //             }

                                              //             return Text(
                                              //               snapshot.data!,
                                              //               maxLines: 1,
                                              //               overflow:
                                              //                   TextOverflow
                                              //                       .ellipsis,
                                              //               style:
                                              //                   TextStyleService
                                              //                       .getDmSans(
                                              //                 fontSize: 9.415,
                                              //                 fontWeight:
                                              //                     FontWeight
                                              //                         .w400,
                                              //                 color: Color(
                                              //                     0xFF000000),
                                              //               ),
                                              //             );
                                              //           },
                                              //         ),
                                              //       ),
                                              //     ],
                                              //   ),
                                              // ),
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
                                        fetchProviderScholarships(
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
                                        fetchProviderScholarships(
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
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      // Footer Navigation Bar
    );
  }
}
