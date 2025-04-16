import 'dart:typed_data';
import 'package:edugo/config/api_config.dart';
import 'package:edugo/features/notification/screens/notification_management.dart';
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

final Map<String, Uint8List?> _imageAvatarCache = {};

class SubjectManagement extends StatefulWidget {
  const SubjectManagement({super.key});

  @override
  State<SubjectManagement> createState() => _SubjectManagementState();
}

class _SubjectManagementState extends State<SubjectManagement> {
  List<dynamic> subject = [];
  List<dynamic> useItem = [];
  bool isLoading = true;
  Uint8List? _imageBytes;
  Uint8List? imageAvatar;
  final AuthService authService = AuthService(); // Instance of AuthService
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final Map<String, Uint8List?> _imageCache = {};
  final Map<String, Uint8List?> _imageAvatarCache = {};
  Map<String, dynamic>? profile;

  @override
  void initState() {
    super.initState();
    _delayedLoad(); // เรียกใช้งานฟังก์ชัน _delayedLoad
    fetchAvatarImage();
    fetchProfile();
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
      throw Exception('Failed to load country data');
    }
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
        final Map<String, dynamic> profileData =
            data['profile']; // ดึงข้อมูลโปรไฟล์

        setState(() {
          profile = {
            'id': profileData['id'],
            'first_name': profileData['first_name'] ?? '',
            'last_name': profileData['last_name'] ?? '',
            'role': profileData['role'],
            'company_name': profileData['company_name'] ?? '',
          };
        });
      } else {
        throw Exception('Failed to load profile');
      }
    } catch (e) {
      setState(() {});
      print("Error fetching profile: $e");
    }
  }

  Future<Uint8List?> fetchPostImage(String url) async {
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

  Future<void> fetchsubject() async {
    String? token = await authService.getToken();
    Map<String, String> headers = {}; // Explicitly type the map
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    try {
      final response =
          await http.get(Uri.parse(ApiConfig.subjectUrl), headers: headers);
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        // ดึงข้อมูลเฉพาะ "data" มาใช้งาน
        final List<dynamic> data = responseData['data'];

        setState(() {
          subject = data.map((subject) {
            subject['id'] = subject['id'];

            subject['title'] = subject['title'] ?? 'No Title';
            subject['description'] =
                subject['description'] ?? 'No Description Available';
            subject['published_date'] =
                subject['published_date'] ?? subject['publish_date'];
            subject['fullname'] = subject['fullname'] ?? 'No Name';
            subject['account_id'] = subject['account_id'];

            return subject;
          }).toList();
          subject.sort(
              (a, b) => b['published_date'].compareTo(a['published_date']));
          isLoading = false;
          useItem = subject;
        });
      } else {
        throw Exception('Failed to load subject');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print("Error fetching subject: $e");
    }
  }

  Future<void> _delayedLoad() async {
    await Future.delayed(const Duration(seconds: 3)); // Delay 3 seconds
    fetchsubject();
  }

  void confirmDelete(BuildContext context, int id) {
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
                width: 275,
                height: 227,
              ),
              const SizedBox(height: 16),
              Text(
                'Are you sure you want to delete this post?',
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF000000),
                ),
              ),
            ],
          ),
          actions: [
            // ปุ่ม Cancel
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  0, 0, 0, 0), // ระยะห่าง ซ้าย-บน-ขวา-ล่าง
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
                        await submitDeleteData(id); // ดำเนินการลบข้อมูล
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

  Future<void> submitDeleteData(int id) async {
    final String apiUrl = "${ApiConfig.subjectUrl}/${id}";

    String? token = await authService.getToken();
    Map<String, String> headers = {};
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
            builder: (context) => SubjectManagement(),
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

  void _showAddSubjectDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          child: Container(
            width: 320, // กำหนดความกว้างเป็น 320
            child: Column(
              mainAxisSize: MainAxisSize.min, // ปรับขนาดความสูงให้อัตโนมัติ
              children: [
                Container(
                  width: double.infinity,
                  height: 40.0,
                  decoration: BoxDecoration(
                    color: const Color(0xFF355FFF),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(15.0),
                      topRight: Radius.circular(15.0),
                    ),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 24.0,
                        ),
                        onPressed: () {
                          titleController.clear();
                          descriptionController.clear();
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add New Post',
                          style: GoogleFonts.dmSans(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF355FFF),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: titleController,
                          decoration: InputDecoration(
                            labelText: 'Title',
                            labelStyle: GoogleFonts.dmSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[600],
                            ),
                            hintText: 'Enter title',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: descriptionController,
                          decoration: InputDecoration(
                            labelText: 'Description',
                            labelStyle: GoogleFonts.dmSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[600],
                            ),
                            hintText: 'Enter description',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          maxLines: 3,
                          keyboardType: TextInputType.multiline,
                        ),
                        const SizedBox(height: 16),
                        if (_imageBytes != null) // แสดงภาพถ้ามี
                          Image.memory(
                            _imageBytes!,
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                          ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.image_search,
                          color: Color(0xFF355FFF),
                          size: 30.0,
                        ),
                        onPressed: () async {
                          // ใช้ ImagePicker เพื่อเลือกภาพ
                          final ImagePicker _picker = ImagePicker();
                          final XFile? pickedFile = await _picker.pickImage(
                            source: ImageSource.gallery, // เลือกจากแกลเลอรี
                            imageQuality: 100, // ปรับคุณภาพภาพ
                          );

                          if (pickedFile != null) {
                            // โหลดภาพเป็น Uint8List และเก็บในตัวแปร
                            final bytes = await pickedFile.readAsBytes();
                            setState(() {
                              _imageBytes = bytes; // เก็บภาพ
                            });
                          }
                        },
                      ),
                      ElevatedButton(
                        onPressed: () {
                          String title = titleController.text;
                          String description = descriptionController.text;

                          Navigator.of(context).pop();
                          titleController.clear();
                          descriptionController.clear();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF355FFF),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25.0),
                          ),
                          padding: const EdgeInsets.symmetric(
                              vertical: 12.0, horizontal: 20.0),
                        ),
                        child: Text(
                          'Post',
                          style: GoogleFonts.dmSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Blue header block
          Container(
            height: 138,
            color: const Color(0xFF355FFF),
            padding: const EdgeInsets.only(
              top: 72.0,
              right: 16,
              left: 16,
              bottom: 22,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 20,
                      child: ClipOval(
                        child: imageAvatar != null
                            ? Image.memory(
                                imageAvatar!,
                                width: 40, // กำหนดขนาดให้พอดีกับ avatar
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
                    SizedBox(width: 16), // เพิ่มช่องว่างระหว่าง Avatar กับ Text
                    Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start, // ทำให้ข้อความชิดซ้าย
                      children: [
                        Text(
                          "What’s on your mind ?",
                          style: GoogleFonts.dmSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w300,
                            color: Color(0xFFFFFFFF),
                          ),
                        ),
                        Text(
                          "Share your thoughts here ...",
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w200,
                            color: Color(0xFFFFFFFF),
                          ),
                        ),
                      ],
                    ),
                    Spacer(), // ใช้ Spacer เพื่อให้ notification ชิดขวา
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder:
                                (context, animation, secondaryAnimation) =>
                                    NotificationList(
                              id: profile?['id'],
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
                )
              ],
            ),
          ),
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _delayedLoad,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(top: 16, bottom: 16),
                      child: Column(
                        children: [
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const ClampingScrollPhysics(),
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16.0),
                            itemCount: useItem.length,
                            itemBuilder: (context, index) {
                              final subject = useItem[index];
                              final id = subject['id'];
                              final description = subject['description'] ??
                                  'No Description Available';
                              final publishedDate = DateTime.tryParse(
                                  subject['published_date'] ?? '');
                              final formattedDate = publishedDate != null
                                  ? DateFormat('dd MMMM yyyy  hh:mm a')
                                      .format(publishedDate)
                                  : 'N/A';
                              final String imageUrl =
                                  "${ApiConfig.subjectUrl}/$id/image";

                              final String avatarImageUrl =
                                  "${ApiConfig.subjectUrl}/$id/avatar";

                              final String userName =
                                  subject['fullname'] ?? 'No Name';

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16.0),
                                child: GestureDetector(
                                  onTap: () {
                                    final existingData = {
                                      'id': subject['id'],
                                      'title': subject['title'],
                                      'account_id': subject['account_id'],
                                      'description': subject['description'],
                                      'published_date':
                                          subject['published_date'],
                                      'fullname': userName,
                                    };

                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => SubjectDetail(
                                          initialData: existingData,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(10.0),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.withOpacity(0.2),
                                          spreadRadius: 2,
                                          blurRadius: 5,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(22.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            crossAxisAlignment: CrossAxisAlignment
                                                .start, // ทำให้ Column ชิดขอบบนสุด
                                            mainAxisAlignment: MainAxisAlignment
                                                .spaceBetween, // กระจายเนื้อหาทั้งสองด้าน
                                            children: [
                                              Row(
                                                children: [
                                                  CircleAvatar(
                                                    radius: 20,
                                                    backgroundImage: _imageCache
                                                                .containsKey(
                                                                    avatarImageUrl) &&
                                                            _imageCache[
                                                                    avatarImageUrl] !=
                                                                null
                                                        ? MemoryImage(_imageCache[
                                                            avatarImageUrl]!) // ใช้ภาพจากแคช
                                                        : null, // ถ้าไม่มีภาพในแคช
                                                    child: !_imageCache
                                                            .containsKey(
                                                                avatarImageUrl)
                                                        ? FutureBuilder<
                                                            Uint8List?>(
                                                            future: fetchPostAvatar(
                                                                avatarImageUrl),
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
                                                                return Image
                                                                    .asset(
                                                                  "assets/images/avatar.png",
                                                                  fit: BoxFit
                                                                      .cover,
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
                                                  SizedBox(
                                                      width:
                                                          24), // เพิ่มช่องว่างระหว่าง Avatar กับ Column
                                                  Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start, // ทำให้ Text ชิดซ้าย
                                                    children: [
                                                      Text(
                                                        userName,
                                                        style:
                                                            GoogleFonts.dmSans(
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.w400,
                                                          color: const Color(
                                                              0xFF111111),
                                                        ),
                                                      ),
                                                      Text(
                                                        formattedDate,
                                                        style:
                                                            GoogleFonts.dmSans(
                                                          fontSize: 10,
                                                          fontWeight:
                                                              FontWeight.w400,
                                                          color: const Color(
                                                              0xFF94A2B8),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                              if (subject['account_id'] ==
                                                  profile?['id'])
                                                GestureDetector(
                                                  onTap: () {
                                                    showModalBottomSheet(
                                                      context: context,
                                                      shape:
                                                          RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .vertical(
                                                          top: Radius.circular(
                                                              16),
                                                        ),
                                                      ),
                                                      builder: (BuildContext
                                                          context) {
                                                        return Container(
                                                          padding:
                                                              const EdgeInsets
                                                                  .all(16.0),
                                                          decoration:
                                                              BoxDecoration(
                                                            color: Color(
                                                                0xFFEBEFFF), // สีพื้นหลังของ modal
                                                            borderRadius:
                                                                BorderRadius
                                                                    .vertical(
                                                              top: Radius
                                                                  .circular(16),
                                                            ),
                                                          ),
                                                          child: Column(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .min,
                                                            children: [
                                                              Container(
                                                                width:
                                                                    42, // Ensures the container takes up full width
                                                                height:
                                                                    5, // You can specify the height you want
                                                                decoration:
                                                                    BoxDecoration(
                                                                  color: Color(
                                                                      0xFFCBD5E0), // Set the background color to red
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              25), // Set the border radius to 25 for rounded corners
                                                                ),
                                                              ),
                                                              SizedBox(
                                                                  height: 10),
                                                              // เพิ่ม Container รอบๆ Column เพื่อกำหนดพื้นหลัง
                                                              Container(
                                                                color: const Color
                                                                    .fromARGB(
                                                                    255,
                                                                    240,
                                                                    240,
                                                                    240), // กำหนดสีพื้นหลังที่นี่
                                                                child: Column(
                                                                  children: [
                                                                    // ListTile สำหรับ Edit
                                                                    Container(
                                                                      decoration:
                                                                          BoxDecoration(
                                                                        color: Colors
                                                                            .white, // พื้นหลังของแต่ละรายการ
                                                                        borderRadius:
                                                                            BorderRadius.only(
                                                                          topLeft:
                                                                              Radius.circular(12), // มุมบนซ้าย
                                                                          topRight:
                                                                              Radius.circular(12), // มุมบนขวา
                                                                        ),
                                                                      ),
                                                                      child:
                                                                          ListTile(
                                                                        leading:
                                                                            SvgPicture.asset(
                                                                          'assets/images/edit_svg.svg', // ไฟล์ SVG
                                                                          fit: BoxFit
                                                                              .cover,
                                                                          color:
                                                                              const Color(0xff355FFF), // สีของไอคอน
                                                                        ),
                                                                        title:
                                                                            Text(
                                                                          'Edit post',
                                                                          style:
                                                                              GoogleFonts.dmSans(
                                                                            fontSize:
                                                                                14,
                                                                            fontWeight:
                                                                                FontWeight.w400,
                                                                            color:
                                                                                Color(0xFF000000),
                                                                          ),
                                                                        ),
                                                                        onTap:
                                                                            () {
                                                                          final existingData =
                                                                              {
                                                                            'id':
                                                                                subject['id'],
                                                                            'description':
                                                                                subject['description'],
                                                                            'image':
                                                                                subject['image'],
                                                                            'dateTime':
                                                                                subject['published_date']
                                                                          };

                                                                          Navigator
                                                                              .push(
                                                                            context,
                                                                            MaterialPageRoute(
                                                                              builder: (context) => SubjectAddEdit(
                                                                                isEdit: true,
                                                                                initialData: existingData,
                                                                              ),
                                                                            ),
                                                                          );
                                                                        },
                                                                      ),
                                                                    ),

                                                                    // ListTile สำหรับ Delete
                                                                    Container(
                                                                      decoration:
                                                                          BoxDecoration(
                                                                        color: Colors
                                                                            .white, // พื้นหลังของแต่ละรายการ
                                                                        borderRadius:
                                                                            BorderRadius.only(
                                                                          bottomLeft:
                                                                              Radius.circular(12), // มุมบนซ้าย
                                                                          bottomRight:
                                                                              Radius.circular(12), // มุมบนขวา
                                                                        ),
                                                                      ),
                                                                      child:
                                                                          ListTile(
                                                                        leading:
                                                                            SvgPicture.asset(
                                                                          'assets/images/delete_svg.svg', // ไฟล์ SVG
                                                                          fit: BoxFit
                                                                              .cover,
                                                                          color:
                                                                              const Color(0xffED4B9E), // สีของไอคอน
                                                                        ),
                                                                        title:
                                                                            Text(
                                                                          'Delete post',
                                                                          style:
                                                                              GoogleFonts.dmSans(
                                                                            fontSize:
                                                                                14,
                                                                            fontWeight:
                                                                                FontWeight.w400,
                                                                            color:
                                                                                Color(0xFF000000),
                                                                          ),
                                                                        ),
                                                                        onTap:
                                                                            () {
                                                                          confirmDelete(
                                                                              context,
                                                                              subject['id']);
                                                                        },
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        );
                                                      },
                                                    );
                                                  },
                                                  child: SvgPicture.asset(
                                                    'assets/images/dot.svg', // ไฟล์ SVG
                                                    fit: BoxFit.cover,
                                                    color: const Color(
                                                        0xff94A2B8), // สีของไอคอน
                                                  ),
                                                ),
                                            ],
                                          ),
                                          SizedBox(
                                            height: 15,
                                          ),
                                          Text(
                                            description,
                                            style: GoogleFonts.dmSans(
                                              fontSize: 14,
                                              fontWeight: FontWeight.normal,
                                              color: Colors.grey[700],
                                            ),
                                            maxLines: 4,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(top: 15),
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(12.0),
                                              child: _imageCache.containsKey(
                                                          imageUrl) &&
                                                      _imageCache[imageUrl] !=
                                                          null
                                                  ? Image.memory(
                                                      _imageCache[imageUrl]!,
                                                      width: double
                                                          .infinity, // Use double.infinity for full width or specify a fixed width
                                                      height: 200,
                                                      fit: BoxFit.cover,
                                                    )
                                                  : FutureBuilder<Uint8List?>(
                                                      future: fetchPostImage(
                                                          imageUrl),
                                                      builder:
                                                          (context, snapshot) {
                                                        if (snapshot
                                                                .connectionState ==
                                                            ConnectionState
                                                                .waiting) {
                                                          return const SizedBox(
                                                            width:
                                                                double.infinity,
                                                            height: 200,
                                                            child: Center(
                                                                child:
                                                                    CircularProgressIndicator()),
                                                          );
                                                        }
                                                        if (snapshot.hasData &&
                                                            snapshot.data !=
                                                                null) {
                                                          return Image.memory(
                                                            snapshot.data!,
                                                            width:
                                                                double.infinity,
                                                            height: 200,
                                                            fit: BoxFit.cover,
                                                          );
                                                        }
                                                        return const SizedBox
                                                            .shrink(); // ไม่แสดงอะไรเลยถ้า snapshot.data เป็น null
                                                      },
                                                    ),
                                            ),
                                          ),
                                          SizedBox(height: 22),
                                          Container(
                                            width: double
                                                .infinity, // Ensures the container takes up full width
                                            height:
                                                35, // You can specify the height you want
                                            decoration: BoxDecoration(
                                              color: Color(
                                                  0xFFF0F0F0), // Set the background color to red
                                              borderRadius: BorderRadius.circular(
                                                  25), // Set the border radius to 25 for rounded corners
                                            ),
                                            child: Align(
                                              alignment: Alignment
                                                  .centerLeft, // Align the text to the left
                                              child: Padding(
                                                padding: const EdgeInsets
                                                    .symmetric(
                                                    horizontal: 4,
                                                    vertical:
                                                        6), // Optional padding for some space from the left
                                                child: Row(
                                                  children: [
                                                    CircleAvatar(
                                                      child: ClipOval(
                                                        child:
                                                            imageAvatar != null
                                                                ? Image.memory(
                                                                    imageAvatar!,
                                                                    width:
                                                                        20, // กำหนดขนาดให้พอดีกับ avatar
                                                                    height: 20,
                                                                    fit: BoxFit
                                                                        .cover,
                                                                    colorBlendMode:
                                                                        BlendMode
                                                                            .srcIn,
                                                                  )
                                                                : Image.asset(
                                                                    'assets/images/avatar.png',
                                                                    width: 20,
                                                                    height: 20,
                                                                    fit: BoxFit
                                                                        .cover,
                                                                    colorBlendMode:
                                                                        BlendMode
                                                                            .srcIn,
                                                                  ),
                                                      ),
                                                    ),
                                                    SizedBox(width: 0),
                                                    Text(
                                                      'What about your opinion ?',
                                                      style: TextStyle(
                                                          fontSize: 11,
                                                          color:
                                                              Color(0xFF747474),
                                                          fontWeight:
                                                              FontWeight.w200),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          )
                        ],
                      ),
                    ),
                  ),
          ),
          FooterNav(
            pageName: "subject",
          ),
        ],
      ),
    );
  }
}
