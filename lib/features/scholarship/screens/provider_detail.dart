import 'dart:io';

import 'package:edugo/config/api_config.dart';
import 'package:edugo/features/home/screens/home_screen.dart';
import 'package:edugo/features/scholarship/screens/provider_add.dart';
import 'package:edugo/features/scholarship/screens/provider_management.dart';
import 'package:edugo/features/search/screens/search_screen.dart'; // Import SearchScreen
import 'package:edugo/services/auth_service.dart';
import 'package:edugo/services/datetime_provider_add.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:open_file/open_file.dart';
import 'package:edugo/main.dart'; // Import main.dart เพื่อเข้าถึง navigatorKey

class ProviderDetail extends StatefulWidget {
  final bool isProvider;
  final Map<String, dynamic>? initialData;
  final String? previousRouteName; // Add previousRouteName parameter

  const ProviderDetail({
    Key? key,
    required this.isProvider,
    this.initialData,
    this.previousRouteName, // Initialize previousRouteName
  }) : super(key: key);

  @override
  State<ProviderDetail> createState() => _ProviderDetailState();
}

class _ProviderDetailState extends State<ProviderDetail> {
  // แก้ไขการสร้าง AuthService instance
  final AuthService authService = AuthService(navigatorKey: navigatorKey);
  int? id;
  String? title; // Scholarship Name
  String? description; // Description
  String? url; // Web URL
  Uint8List? image;
  String? attachFile;
  String? selectedScholarshipType; // Scholarship Type
  String? selectedCountry;
  String? educationLevel;
  DateTime? selectedStartDate;
  DateTime? selectedEndDate;
  final double coverHeight = 227;
  final double pictureHeight = 114;
  Map<String, dynamic>? profile; // Define the profile variable
  List<int> announceIds = []; // เก็บแค่ announce_id
  List<dynamic> bookmarks = [];
  bool isBookmarked = false;
  String? localPreviousRouteName; // Local variable to store route name

  @override
  void initState() {
    super.initState();
    // fetchScholarshipsDetail(widget.initialData?['id']);
    fetchProfile(); // เรียกใช้ฟังก์ชันนี้เพื่อดึงข้อมูลโปรไฟล์

    // Store previousRouteName locally
    localPreviousRouteName =
        widget.previousRouteName ?? widget.initialData?['previousRouteName'];

    if (widget.initialData != null) {
      // Print the received data
      print("Received initialData in ProviderDetail: ${widget.initialData}");

      final data = widget.initialData!;
      _initializeData(data);
    }
  }

  void _initializeData(Map<String, dynamic>? data) {
    if (data != null) {
      // Check the type of 'id' and parse if it's a String
      if (data['id'] is String) {
        id =
            int.tryParse(data['id']); // Use tryParse to handle potential errors
      } else if (data['id'] is int) {
        id = data['id'];
      } else {
        id = null; // Set to null if it's neither String nor int
      }

      title = data['title'] ?? 'No Title';
      description = data['description'] ?? 'No Description';
      url = data['url'] ?? 'No Website';
      selectedCountry = data['country'] ?? 'No Country';
      selectedScholarshipType = data['category'] ?? 'No Category';
      selectedStartDate = data['published_date'] != null
          ? DateTime.tryParse(data['published_date'])
          : null;
      selectedEndDate = data['close_date'] != null
          ? DateTime.tryParse(data['close_date'])
          : null;
      educationLevel = data['education_level'] ?? 'No Education Level';

      // Use 'attach_file' key consistently
      if (data['attach_file'] != null && data['attach_file'] is String) {
        attachFile = data['attach_file'];
      } else {
        attachFile = 'No Attach Files';
      }

      // Handle image, checking both 'image' and 'cachedImage' keys
      if (data['image'] != null && data['image'] is Uint8List) {
        image = data['image'];
      } else if (data['cachedImage'] != null &&
          data['cachedImage'] is Uint8List) {
        image = data['cachedImage'];
      } else {
        image = null; // Fallback if no valid image data is provided
      }
    }
  }

  void confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // ไม่ให้กดปิดนอกกรอบ Dialog
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12), // ปรับมุมโค้ง
          ),
          contentPadding: const EdgeInsets.all(20),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/confirm_delete.png', // ไอคอนรูปคนทิ้งขยะ
                width: 169,
                height: 151,
              ),
              const SizedBox(height: 16),
              Text(
                'Are you sure you want to delete this scholarship?',
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '"${title ?? "Scholarship"}"', // แสดงชื่อของทุน
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  fontStyle: FontStyle.italic,
                  color: const Color(0xFF64738B),
                ),
              ),
            ],
          ),
          actions: [
            // ปุ่ม Cancel
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  0, 34, 0, 0), // ระยะห่าง ซ้าย-บน-ขวา-ล่าง
              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween, // ระยะห่างระหว่างปุ่ม
                children: [
                  // ปุ่ม Cancel
                  SizedBox(
                    width: 134, // กำหนดความกว้าง
                    height: 41, // กำหนดความสูง
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop(); // ปิด Dialog
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFFFFFFF),
                        backgroundColor: const Color(0xFF94A2B8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  // ปุ่ม Delete
                  SizedBox(
                    width: 134, // กำหนดความกว้าง
                    height: 41, // กำหนดความสูง
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.of(dialogContext).pop(); // ปิด Dialog
                        await submitDeleteData(); // ดำเนินการลบข้อมูล
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD5448E),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Delete',
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
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
          };
        });
        print(profile);
        fetchBookmark(profile?['id']);
      } else {
        throw Exception('Failed to load profile');
      }
    } catch (e) {
      setState(() {});
      print("Error fetching profile: $e");
    }
  }

  // Future<void> fetchScholarshipsDetail(int id) async {
  //   try {
  //     String? token = await authService.getToken();
  //     Map<String, String> headers = {};
  //     if (token != null) {
  //       headers['Authorization'] = 'Bearer $token';
  //     }

  //     final response = await http.get(Uri.parse("${ApiConfig.announceUrl}/$id"),
  //         headers: headers);

  //     if (response.statusCode == 200) {
  //       final Map<String, dynamic> scholarshipData = json.decode(response.body);

  //       print('Raw publish_date: ${scholarshipData['publish_date']}');
  //       print('Raw close_date: ${scholarshipData['close_date']}');

  //       setState(() {
  //         title = scholarshipData['title'] ?? 'No Title';
  //         description =
  //             scholarshipData['description'] ?? 'No Description Available';
  //         url = scholarshipData['url'];
  //         selectedScholarshipType = scholarshipData['category'];
  //         selectedCountry = scholarshipData['country'];

  //         selectedStartDate = scholarshipData['publish_date'] != null
  //             ? DateTime.tryParse(scholarshipData['publish_date'])
  //             : null;

  //         if (scholarshipData['close_date'] != null) {
  //           try {
  //             selectedEndDate = DateTime.parse(scholarshipData['close_date']);
  //           } catch (e) {
  //             print('Error parsing close_date: $e');
  //             selectedEndDate = null;
  //           }
  //         }

  //         // Handle attachment
  //         attachFile = scholarshipData['attach_name'] ?? 'No Attach Files';
  //       });
  //     } else {
  //       throw Exception('Failed to load scholarship details');
  //     }
  //   } catch (e) {
  //     print("Error fetching scholarship details: $e");
  //   }
  // }

  Future<void> fetchBookmark(int id) async {
    String? token = await authService.getToken();
    Map<String, String> headers = {};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    final url = "${ApiConfig.bookmarkUrl}/acc/$id}";

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

          print(announceIds);
          if (widget.initialData?['id'] != null &&
              announceIds.contains(widget.initialData?['id'])) {
            isBookmarked = true;
          }
        });
      } else {
        throw Exception('Failed to load bookmarks');
      }
    } catch (e) {
      print("Error fetching bookmarks: $e");
    }
  }

  Future<void> fetchAndOpenPdf(int id) async {
    final url = Uri.parse(
        'https://capstone24.sit.kmutt.ac.th/un2/api/announce/$id/attach');

    String? token = await authService.getToken();
    Map<String, String> headers = {};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final bytes = response.bodyBytes;

      final dir = await getTemporaryDirectory();
      // Use attachFile which should now hold the correct filename
      final file = File('${dir.path}/${attachFile ?? "downloaded_file"}.pdf');
      await file.writeAsBytes(bytes);

      // เปิดไฟล์ PDF
      await OpenFile.open(file.path);
    } else {
      throw Exception('Failed to load PDF');
    }
  }

  Future<void> submitDeleteData() async {
    final String apiUrl = "${ApiConfig.announceUrl}/$id";

    String? token = await authService.getToken();

    Map<String, String> headers = {}; // Explicitly type the map
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    var request = http.MultipartRequest('DELETE', Uri.parse(apiUrl));
    request.headers.addAll(headers);

    try {
      var response = await request.send();

      if (response.statusCode == 200) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => ProviderManagement(),
          ),
          (route) => false, // ลบ stack ทั้งหมด
        );
      } else {
        showError("Failed to delete data. Status code: ${response.statusCode}");
      }
    } catch (e) {
      showError("Error occurred: $e");
    }
  }

  Future<void> toggleBookmark() async {
    final url = Uri.parse(ApiConfig.bookmarkUrl);

    String? token = await authService.getToken();
    Map<String, String> headers = {'Content-Type': 'application/json'};

    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    try {
      if (isBookmarked) {
        // Remove bookmark
        final response = await http.delete(
          Uri.parse("$url/ann/$id"),
          headers: headers,
        );

        if (response.statusCode == 200 || response.statusCode == 204) {
          setState(() {
            isBookmarked = false;
            announceIds.remove(id); // เอา id ออกจากรายการ
          });
          // showSuccess("Bookmark removed.");
        } else {
          // showError("Failed to remove bookmark.");
        }
      } else {
        // Add bookmark
        final response = await http.post(
          url,
          headers: headers,
          body: json.encode({"announce_id": id}),
        );

        if (response.statusCode == 201 || response.statusCode == 200) {
          setState(() {
            isBookmarked = true;
            announceIds.add(id!); // เพิ่ม id เข้าไปในรายการ
          });
          // showSuccess("Bookmark added.");
        } else {
          // showError("Failed to add bookmark.");
        }
      }
    } catch (e) {
      showError("Error occurred: $e");
    }
  }

  // Helper to show error messages
  void showError(String message) {
    // Replace with your preferred error handling method
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

// Helper to show success messages
  void showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final top = coverHeight - pictureHeight / 2;

    return WillPopScope(
      onWillPop: () async {
        // Navigate back based on previousRouteName
        Widget destination;
        if (localPreviousRouteName == 'search') {
          destination = const SearchScreen();
        } else if (widget.isProvider) {
          destination = const ProviderManagement();
        } else {
          destination = const HomeScreenApp();
        }
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => destination),
        );
        return false; // ป้องกันการย้อนกลับไปหน้าก่อนหน้า
      },
      child: Scaffold(
        backgroundColor: const Color(0xffFFFFFF),
        body: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(top: 0),
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        margin: EdgeInsets.only(bottom: pictureHeight * 2.5),
                        color: const Color(0xFF355FFF),
                        height: coverHeight,
                        padding: const EdgeInsets.only(
                          top: 58.0,
                          right: 16,
                          left: 16,
                          bottom: 22,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    // Navigate back based on previousRouteName
                                    Widget destination;
                                    if (localPreviousRouteName == 'search') {
                                      destination = const SearchScreen();
                                    } else if (widget.isProvider) {
                                      destination = const ProviderManagement();
                                    } else {
                                      destination = const HomeScreenApp();
                                    }
                                    Navigator.pushReplacement(
                                      context,
                                      PageRouteBuilder(
                                        pageBuilder: (context, animation,
                                                secondaryAnimation) =>
                                            destination,
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
                                GestureDetector(
                                  onTap: () {
                                    if (widget.isProvider) {
                                      confirmDelete(context);
                                    } else {
                                      // ใส่ action สำหรับผู้ใช้ทั่วไป เช่น กดถูกใจ
                                      toggleBookmark();
                                    }
                                  },
                                  child: CircleAvatar(
                                    radius: 20,
                                    backgroundColor: widget.isProvider
                                        ? const Color(0xFFED4B9E)
                                        : Colors.grey[300],
                                    child: widget.isProvider
                                        ? Image.asset(
                                            'assets/images/icon_delete.png',
                                            width: 20.0,
                                            height: 20.0,
                                            colorBlendMode: BlendMode.srcIn,
                                          )
                                        : Icon(
                                            isBookmarked
                                                ? Icons.favorite
                                                : Icons
                                                    .favorite_border, // หัวใจเต็มหรือขอบ
                                            color: isBookmarked
                                                ? Colors.red
                                                : Colors.grey, // สีแดงหรือสีเทา
                                            size: 24,
                                          ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Center(
                              child: Text(
                                title ?? "Scholarship",
                                style: GoogleFonts.dmSans(
                                  fontSize: 20,
                                  fontStyle: FontStyle.normal,
                                  fontWeight: FontWeight.w500,
                                  height: 1.4,
                                  color:
                                      const Color.fromARGB(255, 255, 255, 255),
                                ),
                                maxLines:
                                    1, // Add this line to limit the text to 1 line
                                overflow: TextOverflow
                                    .ellipsis, // Optional: Handles text overflow with ellipsis if the text is too long
                              ),
                            )
                          ],
                        ),
                      ),
                      Positioned(
                        top: top,
                        child: Center(
                          child: image != null ||
                                  image !=
                                      "assets/images/scholarship_program.png"
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.memory(
                                    image ?? Uint8List(0),
                                    width: 245,
                                    height: 338,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.asset(
                                        'assets/images/scholarship_program.png',
                                        width: 245,
                                        height: 338,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                )
                              : ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.asset(
                                    'assets/images/scholarship_program.png',
                                    width: 245,
                                    height: 338,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                        ),
                      )
                    ],
                  ),

                  const SizedBox(height: 22),

                  // Details Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Scholarship Name
                        Text(
                          'Scholarship Name*',
                          style: GoogleFonts.dmSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.only(left: 11),
                          child: Text(
                            title ?? "No title available.",
                            maxLines: 1, // จำกัดให้แสดงเพียง 1 บรรทัด
                            overflow: TextOverflow
                                .ellipsis, // แสดง "..." หากข้อความยาวเกิน
                            style: GoogleFonts.dmSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF64738B),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // // Web URL
                        Text(
                          'Web (URL)',
                          style: GoogleFonts.dmSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.only(left: 11.0),
                          child: Text(
                            url ?? "No URL available.",
                            maxLines: 1, // จำกัดให้แสดงเพียง 1 บรรทัด
                            overflow: TextOverflow
                                .ellipsis, // แสดง "..." หากข้อความยาวเกิน
                            style: GoogleFonts.dmSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF64738B),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Type of Scholarship and Country
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment
                              .start, // Align items to the top
                          children: [
                            Expanded(
                              // Wrap the first Column with Expanded
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Type of Scholarship*',
                                    style: GoogleFonts.dmSans(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 11),
                                    child: Text(
                                      // Removed the fixed-width Container
                                      selectedScholarshipType ??
                                          'Full Scholarship',
                                      maxLines: 1, // จำกัดแค่ 1 บรรทัด
                                      overflow: TextOverflow
                                          .ellipsis, // แสดง "..." หากข้อความยาวเกิน
                                      style: GoogleFonts.dmSans(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w400,
                                        color: Color(0xFF64738B),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(
                                width: 20), // Reduced spacing slightly
                            Expanded(
                              // Wrap the second Column with Expanded
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Country*',
                                    style: GoogleFonts.dmSans(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 0),
                                    child: Text(
                                      // Removed the fixed-width Container
                                      selectedCountry ?? 'Not Specified',
                                      maxLines: 1, // จำกัดแค่ 1 บรรทัด
                                      overflow: TextOverflow
                                          .ellipsis, // แสดง "..." หากข้อความยาวเกิน
                                      style: GoogleFonts.dmSans(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w400,
                                        color: Color(0xFF64738B),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        Text(
                          'Education Level',
                          style: GoogleFonts.dmSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.only(left: 11.0),
                          child: Text(
                            educationLevel ?? "No Education Level Available.",
                            maxLines: 1, // จำกัดให้แสดงเพียง 1 บรรทัด
                            overflow: TextOverflow
                                .ellipsis, // แสดง "..." หากข้อความยาวเกิน
                            style: GoogleFonts.dmSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF64738B),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Date Selector
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 11),
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFCBD5E0)),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: DateSelector(
                            isDetail: true,
                            initialStartDate: selectedStartDate,
                            initialEndDate: selectedEndDate,
                          ),
                        ),
                        const SizedBox(height: 24),

                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Color(0xFFCBD5E0),
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize
                                .min, // Added to prevent excessive height
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Color(0xFFE5EDFB),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Image.asset(
                                      'assets/images/attach_file.png',
                                      width: 66.0,
                                      height: 66.0,
                                    ),
                                  ),
                                  SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Attach File',
                                          style: TextStyle(
                                            fontFamily: 'DM Sans',
                                            fontSize: 14,
                                            fontStyle: FontStyle.normal,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF94A2B8),
                                            height: 1.0,
                                          ),
                                        ),
                                        SizedBox(height: 2),
                                        Text(
                                          '*upload PDF file with maximum size 50 MB',
                                          style: TextStyle(
                                            fontFamily: 'DM Sans',
                                            fontSize: 12,
                                            fontWeight: FontWeight.normal,
                                            color: Color(0xFF94A2B8),
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Container(
                                          height: 28,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8),
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: Color(0xFFC0CDFF),
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Align(
                                            alignment: Alignment.centerLeft,
                                            child: Text(
                                              attachFile.toString(), // ชื่อไฟล์
                                              style: GoogleFonts.dmSans(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w400,
                                                fontStyle: FontStyle.italic,
                                                color: Color(0xFF94A2B8),
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              // Button Attach
                              SizedBox(
                                height: 36,
                                width: double.infinity,
                                child: ElevatedButton(
                                  // Disable button if attachFile is null or indicates no file
                                  onPressed: (attachFile != null &&
                                          attachFile != 'No Attach Files')
                                      ? () async => await fetchAndOpenPdf(id!)
                                      : null, // เรียก method _pickFile
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF355FFF),
                                    disabledBackgroundColor: Colors
                                        .grey, // Optional: style for disabled state
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        "Download Attach File",
                                        style: GoogleFonts.dmSans(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 11,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Image.asset(
                                        'assets/images/icon_attach_file.png',
                                        width: 15.0,
                                        height: 18.0,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24), // Increased spacing

                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Color(0xFFCBD5E0),
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize
                                .min, // Added to prevent excessive height
                            children: [
                              Text(
                                'Description*',
                                style: GoogleFonts.dmSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              // Scrollable TextField (Keep its height for scrolling)
                              Container(
                                height:
                                    353, // Keep this height for the scrollable area
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Color(0xFFCBD5E0),
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: SingleChildScrollView(
                                    child: Text(
                                      description ?? 'Not Specified',
                                      style: GoogleFonts.dmSans(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w400,
                                        color: Color(0xFF64738B),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        widget.isProvider
                            ? const SizedBox(height: 24) // Adjusted spacing
                            : const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (widget.isProvider)
              Container(
                // Wrap the bottom button area in a Container
                color: Colors.white, // Ensure background color
                padding: const EdgeInsets.only(
                    bottom: 20,
                    top: 10,
                    left: 16,
                    right: 16), // Adjust padding as needed
                child: SizedBox(
                  height: 48,
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Prepare data to pass
                      final existingData = {
                        'id': id,
                        'title': title,
                        // Use null check for url before comparison
                        'url': (url == 'No Website') ? null : url,
                        'category': selectedScholarshipType,
                        'country': selectedCountry,
                        'description': description,
                        'image': image,
                        // Use null check for attachFile before comparison
                        'attach_file': (attachFile == 'No Attach Files')
                            ? null
                            : attachFile,
                        'published_date': selectedStartDate?.toIso8601String(),
                        'close_date': selectedEndDate?.toIso8601String(),
                        'education_level': educationLevel,
                      };

                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder:
                              (context, animation, secondaryAnimation) =>
                                  ProviderAddEdit(
                                      isEdit: true, initialData: existingData),
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
                          "Edit Scholarship",
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
          ],
        ),
      ),
    );
  }
}
