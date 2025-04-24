import 'dart:io';

import 'package:edugo/config/api_config.dart';
import 'package:edugo/features/scholarship/screens/provider_management.dart';
import 'package:edugo/features/subject/subject_add_edit.dart';
import 'package:edugo/features/subject/subject_manage.dart';
import 'package:edugo/services/auth_service.dart';
import 'package:edugo/services/datetime_provider_add.dart';
import 'package:edugo/shared/utils/textStyle.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:edugo/main.dart'; // Import main.dart เพื่อเข้าถึง navigatorKey

class SubjectDetail extends StatefulWidget {
  final Map<String, dynamic>? initialData;

  const SubjectDetail({
    Key? key,
    this.initialData,
  }) : super(key: key);

  @override
  State<SubjectDetail> createState() => _SubjectDetailState();
}

class _SubjectDetailState extends State<SubjectDetail> {
  int? id;
  String? title;
  String? description;
  String? image;
  String? fullname;
  DateTime? selectedStartDate;
  List<dynamic> comments = []; // เก็บคอมเมนต์ที่ดึงมา
  final double coverHeight = 138;
  final AuthService authService =
      AuthService(navigatorKey: navigatorKey); // Instance of AuthService
  TextEditingController _commentController = TextEditingController();
  final Map<String, Uint8List?> _imageAvatarCache = {};
  Uint8List? postImge;
  Map<String, dynamic>? profile;
  Uint8List? imageProfileAvatar;
  final Map<String, Uint8List?> _imageCache = {};

  @override
  void initState() {
    super.initState();

    if (widget.initialData != null) {
      final data = widget.initialData!;
      id = data['id'] ?? '';
      title = data['title'] ?? 'No Title';
      description = data['description'] ?? 'No Description';

      selectedStartDate = data['published_date'] != null
          ? DateTime.tryParse(data['published_date'])
          : null;
      fullname = data['fullname'] ?? 'No Name';

      image = data['image'] ?? '';
    }

    fetchComment();
    fetchPostImage();
    fetchProfile();
    fetchAvatarImage();
  }

  Future<void> fetchComment() async {
    if (id == null) {
      return;
    }

    String? token = await authService.getToken();
    Map<String, String> headers = {};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    final String url = "${ApiConfig.commentUrl}/post/$id";

    try {
      final response = await http.get(Uri.parse(url), headers: headers);
      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);

        // เรียงจากใหม่ไปเก่า โดยเปรียบเทียบ publish_date
        responseData
            .sort((a, b) => b['publish_date'].compareTo(a['publish_date']));

        setState(() {
          comments = responseData;
        });
      } else {
        throw Exception('Failed to load comments');
      }
    } catch (e) {
      setState(() {});
      print("Error fetching comments: $e");
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
        imageProfileAvatar = response.bodyBytes; // แปลง response เป็น Uint8List
      });
    } else {
      throw Exception('Failed to load country data');
    }
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

  Future<Uint8List?> fetchPostImage() async {
    try {
      String? token = await authService.getToken();
      Map<String, String> headers = {};
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.get(
        Uri.parse("${ApiConfig.subjectUrl}/$id/image"),
        headers: headers,
      );

      if (response.statusCode == 200) {
        // บันทึก response.bodyBytes ลงในไฟล์ชั่วคราว

        setState(() {
          postImge = response.bodyBytes; // เก็บไฟล์ใน _selectedImage
        });
        return response.bodyBytes;
      } else {
        debugPrint("Failed to load image: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error fetching image: $e");
    }

    setState(() {
      postImge = null; // ถ้าเกิดข้อผิดพลาดให้ตั้งค่าเป็น null
    });
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
        final Map<String, dynamic> profileData =
            data['profile']; // ดึงข้อมูลโปรไฟล์

        setState(() {
          profile = {'id': profileData['id']};
        });
      } else {
        throw Exception('Failed to load profile');
      }
    } catch (e) {
      setState(() {});
      print("Error fetching profile: $e");
    }
  }

  Future<void> AddNewComment() async {
    if (id == null) {
      return;
    }

    String? token = await authService.getToken();
    Map<String, String> headers = {
      'Content-Type': 'application/json', // กำหนด Content-Type
    };

    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    final Map<String, dynamic> body = {
      "Comments_Text": _commentController.text,
      "publish_date": DateTime.now().toIso8601String(),
      "posts_id": id
    };

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.commentUrl),
        headers: headers,
        body: jsonEncode(body), // แปลง Map เป็น JSON String
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _commentController.clear();
        fetchComment();
      } else {
        throw Exception('Failed to add comment: ${response.body}');
      }
    } catch (e) {
      setState(() {});
      print("Error adding comment: $e");
    }
  }

  void confirmDelete(BuildContext context, int? id, bool isComment) {
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
                isComment
                    ? 'Are you sure you want to delete this comment?'
                    : 'Are you sure you want to delete this post?',
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
                        await submitDeleteData(
                            id, isComment); // ดำเนินการลบข้อมูล
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

  Future<void> submitDeleteData(int? id, bool isComment) async {
    String apiUrl = isComment
        ? "${ApiConfig.commentUrl}/${id}"
        : "${ApiConfig.subjectUrl}/${id}";

    String? token = await authService.getToken();
    Map<String, String> headers = {};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    var request = http.MultipartRequest('DELETE', Uri.parse(apiUrl));
    request.headers.addAll(headers);

    try {
      var response = await request.send();

      if (isComment) {
        // Close both pop-ups and refresh the page
        Navigator.pop(context); // Close the first pop-up
        fetchComment();
      } else {
        showError("Failed to delete data. Status code: ${response.statusCode}");
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
    return Scaffold(
      backgroundColor: const Color(0xffFFFFFF),
      body: Column(
        children: [
          Container(
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          PageRouteBuilder(
                            pageBuilder:
                                (context, animation, secondaryAnimation) =>
                                    const SubjectManagement(),
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
                      "Post",
                      style: GoogleFonts.dmSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFFFFFFFF),
                      ),
                    ),
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: const Color(0xFFDAFB59),
                      child: GestureDetector(
                        onTap: () {
                          // Add notification functionality here
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('Notifications will be available soon!'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        child: Image.asset(
                          'assets/images/notification.png',
                          width: 40.0,
                          height: 40.0,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment
                                .start, // ทำให้ Column ชิดขอบบนสุด
                            mainAxisAlignment: MainAxisAlignment
                                .spaceBetween, // กระจายเนื้อหาทั้งสองด้าน
                            children: [
                              Row(
                                children: [
                                  FutureBuilder<Uint8List?>(
                                    future: fetchPostAvatar(
                                        "${ApiConfig.subjectUrl}/$id/avatar"),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return ClipOval(
                                          child: const CircleAvatar(
                                            radius: 20,
                                            child: CircularProgressIndicator(),
                                          ),
                                        );
                                      }
                                      if (snapshot.data == null) {
                                        return ClipOval(
                                          child: CircleAvatar(
                                            radius: 20,
                                            backgroundImage: AssetImage(
                                                "assets/images/avatar.png"),
                                          ),
                                        );
                                      }
                                      return ClipOval(
                                        child: CircleAvatar(
                                          radius: 20,
                                          backgroundImage:
                                              MemoryImage(snapshot.data!),
                                        ),
                                      );
                                    },
                                  ),
                                  SizedBox(
                                      width:
                                          24), // เพิ่มช่องว่างระหว่าง Avatar กับ Column
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment
                                        .start, // ทำให้ Text ชิดซ้าย
                                    children: [
                                      Text(
                                        fullname.toString(),
                                        style: GoogleFonts.dmSans(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w400,
                                          color: const Color(0xFF111111),
                                        ),
                                      ),
                                      Text(
                                        selectedStartDate.toString(),
                                        style: GoogleFonts.dmSans(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w400,
                                          color: const Color(0xFF94A2B8),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              if (widget.initialData?['account_id'] ==
                                  profile?['id'])
                                GestureDetector(
                                  onTap: () {
                                    showModalBottomSheet(
                                      context: context,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(16),
                                        ),
                                      ),
                                      builder: (BuildContext context) {
                                        return FractionallySizedBox(
                                          heightFactor:
                                              0.45, // กำหนดความสูงเป็น 60% ของหน้าจอ
                                          child: Container(
                                            padding: const EdgeInsets.all(16.0),
                                            decoration: BoxDecoration(
                                              color: Color(0xFFEBEFFF),
                                              borderRadius:
                                                  BorderRadius.vertical(
                                                top: Radius.circular(16),
                                              ),
                                            ),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Container(
                                                  width: 42,
                                                  height: 5,
                                                  decoration: BoxDecoration(
                                                    color: Color(0xFFCBD5E0),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            25),
                                                  ),
                                                ),
                                                SizedBox(height: 10),
                                                Container(
                                                  color: const Color.fromARGB(
                                                      255, 240, 240, 240),
                                                  child: Column(
                                                    children: [
                                                      // ListTile สำหรับ Edit
                                                      Container(
                                                        decoration:
                                                            BoxDecoration(
                                                          color: Colors.white,
                                                          borderRadius:
                                                              BorderRadius.only(
                                                            topLeft:
                                                                Radius.circular(
                                                                    12),
                                                            topRight:
                                                                Radius.circular(
                                                                    12),
                                                          ),
                                                        ),
                                                        child: ListTile(
                                                          leading:
                                                              SvgPicture.asset(
                                                            'assets/images/edit_svg.svg',
                                                            fit: BoxFit.cover,
                                                            color: const Color(
                                                                0xff355FFF),
                                                          ),
                                                          title: Text(
                                                            'Edit post',
                                                            style: GoogleFonts
                                                                .dmSans(
                                                              fontSize: 14,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w400,
                                                              color: Color(
                                                                  0xFF000000),
                                                            ),
                                                          ),
                                                          onTap: () {
                                                            final existingData =
                                                                {
                                                              'id': id,
                                                              'description':
                                                                  description,
                                                              'image': image,
                                                              'dateTime':
                                                                  selectedStartDate
                                                            };

                                                            Navigator.push(
                                                              context,
                                                              MaterialPageRoute(
                                                                builder:
                                                                    (context) =>
                                                                        SubjectAddEdit(
                                                                  isEdit: true,
                                                                  initialData:
                                                                      existingData,
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
                                                          color: Colors.white,
                                                          borderRadius:
                                                              BorderRadius.only(
                                                            bottomLeft:
                                                                Radius.circular(
                                                                    12),
                                                            bottomRight:
                                                                Radius.circular(
                                                                    12),
                                                          ),
                                                        ),
                                                        child: ListTile(
                                                          leading:
                                                              SvgPicture.asset(
                                                            'assets/images/delete_svg.svg',
                                                            fit: BoxFit.cover,
                                                            color: const Color(
                                                                0xffED4B9E),
                                                          ),
                                                          title: Text(
                                                            'Delete post',
                                                            style: GoogleFonts
                                                                .dmSans(
                                                              fontSize: 14,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w400,
                                                              color: Color(
                                                                  0xFF000000),
                                                            ),
                                                          ),
                                                          onTap: () {
                                                            confirmDelete(
                                                                context,
                                                                id,
                                                                false);
                                                          },
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
                                    );
                                  },
                                  child: SvgPicture.asset(
                                    'assets/images/dot.svg', // ไฟล์ SVG
                                    fit: BoxFit.cover,
                                    color:
                                        const Color(0xff94A2B8), // สีของไอคอน
                                  ),
                                ),
                            ],
                          ),
                          SizedBox(
                            height: 15,
                          ),
                          Text(
                            description.toString(),
                            style: GoogleFonts.dmSans(
                              fontSize: 14,
                              fontWeight: FontWeight.normal,
                              color: Colors.grey[700],
                            ),
                          ),
                          if (postImge != null && postImge!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 15),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12.0),
                                child: Image.memory(
                                  postImge!,
                                  fit: BoxFit
                                      .fitWidth, // ปรับให้รูปภาพแสดงตามความกว้าง
                                  width: double.infinity,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Image.asset(
                                      'assets/images/scholarship_program.png',
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                    );
                                  },
                                ),
                              ),
                            ),
                          SizedBox(height: 6),
                        ],
                      ),
                    ),
                  ),
                ),
                // Comment
                Padding(
                  padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "All Comments",
                        style: GoogleFonts.dmSans(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      // comments.isEmpty
                      //     ? Padding(
                      //         padding: const EdgeInsets.only(top: 16.0),
                      //         child: Center(
                      //           // ทำให้ข้อความอยู่ตรงกลาง
                      //           child: Text(
                      //             "No comments",
                      //             style: GoogleFonts.dmSans(
                      //               fontSize: 36, // ปรับขนาดเป็น 72
                      //               fontWeight: FontWeight
                      //                   .bold, // เพิ่มความหนาให้อ่านง่าย
                      //               color: Colors
                      //                   .grey[400], // ใช้สีเทาอ่อนให้ดูดีขึ้น
                      //             ),
                      //             textAlign: TextAlign
                      //                 .center, // เผื่อกรณีข้อความยาวขึ้น
                      //           ),
                      //         ),
                      //       )
                      //     :
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: comments.length,
                        itemBuilder: (context, index) {
                          final comment = comments[index];

                          int? commentId = comment['id'];

                          // แปลงวันที่ให้เป็นรูปแบบอ่านง่าย
                          DateTime publishDate =
                              DateTime.tryParse(comment['publish_date']) ??
                                  DateTime.now();
                          String formattedDate =
                              DateFormat('dd MMMM yyyy HH:mm')
                                  .format(publishDate);
                          final String avatarImageUrl =
                              "${ApiConfig.commentUrl}/${comment['id']}/avatar";
                          String fullname = comment['fullname'] ??
                              'No name'; // ใช้ชื่อที่ได้จาก API หรือข้อความเริ่มต้น

                          return Padding(
                            padding: const EdgeInsets.only(
                                top: 0.0,
                                bottom:
                                    16.0), // ลดระยะห่างของคอมเมนต์แต่ละอันให้ชิดขึ้น
                            child: Card(
                              margin: EdgeInsets.zero,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Color(0xFFECF0F6),
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
                                                child: !_imageCache.containsKey(
                                                        avatarImageUrl)
                                                    ? FutureBuilder<Uint8List?>(
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
                                                          if (snapshot.data ==
                                                              null) {
                                                            return Image.asset(
                                                              "assets/images/avatar.png",
                                                              fit: BoxFit.cover,
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
                                                    fullname,
                                                    style: GoogleFonts.dmSans(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w400,
                                                      color: const Color(
                                                          0xFF111111),
                                                    ),
                                                  ),
                                                  Text(
                                                    formattedDate,
                                                    style: GoogleFonts.dmSans(
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
                                          if (comment['account_id'] ==
                                              profile?['id'])
                                            GestureDetector(
                                              onTap: () {
                                                showModalBottomSheet(
                                                  context: context,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.vertical(
                                                      top: Radius.circular(16),
                                                    ),
                                                  ),
                                                  builder:
                                                      (BuildContext context) {
                                                    return FractionallySizedBox(
                                                      heightFactor:
                                                          0.45, // กำหนดความสูงเป็น 60% ของหน้าจอ
                                                      child: Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(16.0),
                                                        decoration:
                                                            BoxDecoration(
                                                          color:
                                                              Color(0xFFEBEFFF),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .vertical(
                                                            top:
                                                                Radius.circular(
                                                                    16),
                                                          ),
                                                        ),
                                                        child: Column(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            Container(
                                                              width: 42,
                                                              height: 5,
                                                              decoration:
                                                                  BoxDecoration(
                                                                color: Color(
                                                                    0xFFCBD5E0),
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            25),
                                                              ),
                                                            ),
                                                            SizedBox(
                                                                height: 10),
                                                            Container(
                                                              color: const Color
                                                                  .fromARGB(
                                                                  255,
                                                                  240,
                                                                  240,
                                                                  240),
                                                              child: Column(
                                                                children: [
                                                                  // ListTile สำหรับ Edit
                                                                  // Container(
                                                                  //   decoration:
                                                                  //       BoxDecoration(
                                                                  //     color: Colors
                                                                  //         .white,
                                                                  //     borderRadius:
                                                                  //         BorderRadius
                                                                  //             .only(
                                                                  //       topLeft:
                                                                  //           Radius.circular(12),
                                                                  //       topRight:
                                                                  //           Radius.circular(12),
                                                                  //     ),
                                                                  //   ),
                                                                  //   child:
                                                                  //       ListTile(
                                                                  //     leading:
                                                                  //         SvgPicture
                                                                  //             .asset(
                                                                  //       'assets/images/edit_svg.svg',
                                                                  //       fit: BoxFit
                                                                  //           .cover,
                                                                  //       color: const Color(
                                                                  //           0xff355FFF),
                                                                  //     ),
                                                                  //     title:
                                                                  //         Text(
                                                                  //       'Edit Comment',
                                                                  //       style: GoogleFonts
                                                                  //           .dmSans(
                                                                  //         fontSize:
                                                                  //             14,
                                                                  //         fontWeight:
                                                                  //             FontWeight.w400,
                                                                  //         color:
                                                                  //             Color(0xFF000000),
                                                                  //       ),
                                                                  //     ),
                                                                  //     onTap:
                                                                  //         () {},
                                                                  //   ),
                                                                  // ),

                                                                  // ListTile สำหรับ Delete
                                                                  Container(
                                                                    decoration:
                                                                        BoxDecoration(
                                                                      color: Colors
                                                                          .white,
                                                                      borderRadius:
                                                                          BorderRadius
                                                                              .only(
                                                                        bottomLeft:
                                                                            Radius.circular(12),
                                                                        bottomRight:
                                                                            Radius.circular(12),
                                                                      ),
                                                                    ),
                                                                    child:
                                                                        ListTile(
                                                                      leading:
                                                                          SvgPicture
                                                                              .asset(
                                                                        'assets/images/delete_svg.svg',
                                                                        fit: BoxFit
                                                                            .cover,
                                                                        color: const Color(
                                                                            0xffED4B9E),
                                                                      ),
                                                                      title:
                                                                          Text(
                                                                        'Delete Comment',
                                                                        style: GoogleFonts
                                                                            .dmSans(
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
                                                                            commentId,
                                                                            true);
                                                                      },
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
                                        comment['comments_text'] ??
                                            'No comment',
                                        style: GoogleFonts.dmSans(
                                          fontSize: 14,
                                          fontWeight: FontWeight.normal,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                      if (image!.isNotEmpty)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 15),
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(12.0),
                                            child: Image.network(
                                              image.toString(),
                                              fit: BoxFit.cover,
                                              width: double.infinity,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                return Image.asset(
                                                  'assets/images/scholarship_program.png', // รูปภาพ fallback
                                                  fit: BoxFit.cover,
                                                  width: double.infinity,
                                                  height: 200,
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                      // else
                                      //   ClipRRect(
                                      //     borderRadius:
                                      //         BorderRadius.circular(8.0),
                                      //     child: Image.asset(
                                      //       'assets/images/scholarship_program.png', // รูปภาพ fallback
                                      //       fit: BoxFit.cover,
                                      //       width: double.infinity,
                                      //       height: 200,
                                      //     ),
                                      //   ),
                                      SizedBox(height: 6),
                                    ],
                                  ),
                                ),
                              ),
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
          // Add Comment
          SizedBox(
            height: 88,
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding:
                    const EdgeInsets.only(top: 15.0, left: 16.0, right: 16.0),
                child: Container(
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Color(0xFFF0F0F0),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment
                          .center, // ให้จัดเรียงตรงกลางแนวตั้ง
                      children: [
                        CircleAvatar(
                          radius: 20, // ขนาด Avatar
                          backgroundImage: imageProfileAvatar != null
                              ? MemoryImage(
                                  imageProfileAvatar!) // ใช้ MemoryImage ถ้า imageProfileAvatar ไม่เป็น null
                              : AssetImage('assets/images/avatar.png')
                                  as ImageProvider, // ใช้ AssetImage ถ้าเป็น null
                        ),
                        SizedBox(
                            width: 8), // ระยะห่างระหว่าง Avatar กับ TextField
                        Expanded(
                          child: TextField(
                            controller: _commentController,
                            decoration: InputDecoration(
                              hintText: 'What about your opinion?',
                              hintStyle: TextStyleService.getDmSans(
                                fontSize: 11,
                                color: Color(0xFF747474),
                                fontWeight: FontWeight.w200,
                              ),
                              border: InputBorder.none,
                              contentPadding:
                                  EdgeInsets.symmetric(vertical: 12),
                            ),
                            style: TextStyleService.getDmSans(
                              fontSize: 13,
                              color: Colors.black,
                              fontWeight: FontWeight.w400,
                            ),
                            maxLines: 1,
                            keyboardType: TextInputType.text,
                          ),
                        ),
                        SizedBox(width: 8), // ร
                        GestureDetector(
                          onTap: () {
                            AddNewComment();
                          },
                          child: CircleAvatar(
                            radius: 20,
                            backgroundColor: const Color(
                                0xFF355FFF), // เปลี่ยนสีพื้นหลังตามต้องการ
                            child: Icon(Icons.send,
                                color: Colors.white), // ใช้ไอคอนส่ง
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
