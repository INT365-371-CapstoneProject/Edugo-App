import 'package:edugo/config/api_config.dart';
import 'package:edugo/features/scholarship/screens/provider_detail.dart';
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

class BookmarkList extends StatefulWidget {
  final int id; // เพิ่มตัวแปร id

  const BookmarkList({super.key, required this.id});

  @override
  State<BookmarkList> createState() => _BookmarkListState();
}

class _BookmarkListState extends State<BookmarkList> {
  final AuthService authService = AuthService();
  List<dynamic> bookmarks = [];
  bool isFetching = false; // ป้องกันการโหลดซ้ำซ้อน

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

        print("Filtered announce_id list: $announceIds"); // Debug
        fetchAnnounceDetails();
      } else {
        throw Exception('Failed to load bookmarks');
      }
    } catch (e) {
      print("Error fetching bookmarks: $e");
    }
  }

  Future<void> fetchAnnounceDetails() async {
    String? token = await authService.getToken();

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.bookmarkUser),
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
          print(announceDetails); // Debug
        });
      } else {
        throw Exception('Failed to load announcement details');
      }
    } catch (e) {
      print("Error fetching announce details: $e");
    }
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
                            const ProviderProfile(),
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
                  onTap: () {
                    print(announceDetails);
                  },
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: const Color(0xFFDAFB59),
                    child: Image.asset(
                      'assets/images/notification.png',
                      width: 40.0,
                      height: 40.0,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // แสดงข้อมูล bookmarks
          Expanded(
            child: announceDetails.isNotEmpty && announceDetails['data'] != null
                ? ListView.builder(
                    itemCount: announceDetails['data'].length,
                    itemBuilder: (context, index) {
                      final item = announceDetails['data'][index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ListTile(
                          title: Text(
                            item['title'] ?? 'No Title',
                            style: GoogleFonts.dmSans(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            item['description'] ?? 'No Description',
                            style: GoogleFonts.dmSans(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          // trailing: IconButton(
                          //   icon: Icon(Icons.delete, color: Colors.red),
                          //   onPressed: () {
                          //     deleteBookmark(item['id']);
                          //   },
                          // ),
                          onTap: () async {
                            final existingData = {
                              'id': item['id'],
                              'title': item['title'],
                              'url': item['url'],
                              'category': item['category'],
                              'country': item['country'],
                              'description': item['description'],
                              'image': item['image'],
                              'attach_file': item['attach_file'],
                              'published_date': item['published_date'],
                              'close_date': item['close_date'],
                              'education_level': item['education_level'],
                              'attach_name': item['attach_name'],
                            };
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProviderDetail(
                                  initialData: existingData,
                                  isProvider:
                                      false, // ส่ง existingData ไปยังหน้าแก้ไข
                                ),
                              ),
                              // MaterialPageRoute(
                              //   builder: (context) => ProviderAddEdit(
                              //     isEdit: true,
                              //     initialData:
                              //         existingData, // ส่ง existingData ไปยังหน้าแก้ไข
                              //   ),
                              // ),
                            );
                          },
                        ),
                      );
                    },
                  )
                : const Center(
                    child: CircularProgressIndicator(),
                  ),
          ),
        ],
      ),
    );
  }
}
