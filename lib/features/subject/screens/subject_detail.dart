import 'package:edugo/features/scholarship/screens/provider_management.dart';
import 'package:edugo/features/subject/screens/subject_add_edit.dart';
import 'package:edugo/features/subject/screens/subject_manage.dart';
import 'package:edugo/services/auth_service.dart';
import 'package:edugo/services/datetime_provider_add.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

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
  DateTime? selectedStartDate;
  List<dynamic> comments = []; // เก็บคอมเมนต์ที่ดึงมา
  final double coverHeight = 138;
  final AuthService authService = AuthService(); // Instance of AuthService
  TextEditingController _commentController = TextEditingController();

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

      image = data['image'] ?? '';
    }

    fetchComment();
  }

  Future<void> fetchComment() async {
    if (id == null) {
      print("ID is null, cannot fetch comments.");
      return;
    }

    String? token = await authService.getToken();
    Map<String, String> headers = {};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    final String url =
        "https://capstone24.sit.kmutt.ac.th/un2/api/comment/post/$id";

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

  Future<void> AddNewComment() async {
    if (id == null) {
      print("ID is null, cannot fetch comments.");
      return;
    }

    String? token = await authService.getToken();
    Map<String, String> headers = {
      'Content-Type': 'application/json', // กำหนด Content-Type
    };

    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    final String url = "https://capstone24.sit.kmutt.ac.th/un2/api/comment";
    final Map<String, dynamic> body = {
      "Comments_Text": _commentController.text,
      "publish_date": DateTime.now().toIso8601String(),
      "posts_id": id
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body), // แปลง Map เป็น JSON String
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("Comment added successfully.");
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

  void confirmDelete(BuildContext context, int? id) {
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

  Future<void> submitDeleteData(int? id) async {
    final String apiUrl =
        "https://capstone24.sit.kmutt.ac.th/un2/api/subject/delete/$id";

    var request = http.MultipartRequest('DELETE', Uri.parse(apiUrl));

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
                      child: Image.asset(
                        'assets/images/notification.png',
                        width: 40.0,
                        height: 40.0,
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
                                  CircleAvatar(
                                    radius: 20,
                                    child: Image.asset(
                                      'assets/images/avatar.png',
                                      width: 40.0,
                                      height: 40.0,
                                      colorBlendMode: BlendMode.srcIn,
                                    ),
                                  ),
                                  SizedBox(
                                      width:
                                          24), // เพิ่มช่องว่างระหว่าง Avatar กับ Column
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment
                                        .start, // ทำให้ Text ชิดซ้าย
                                    children: [
                                      Text(
                                        "User Name",
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
                                            borderRadius: BorderRadius.vertical(
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
                                                      BorderRadius.circular(25),
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
                                                      decoration: BoxDecoration(
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
                                                                FontWeight.w400,
                                                            color: Color(
                                                                0xFF000000),
                                                          ),
                                                        ),
                                                        onTap: () {
                                                          final existingData = {
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
                                                              builder: (context) =>
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
                                                      decoration: BoxDecoration(
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
                                                                FontWeight.w400,
                                                            color: Color(
                                                                0xFF000000),
                                                          ),
                                                        ),
                                                        onTap: () {
                                                          confirmDelete(
                                                              context, id);
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
                                  color: const Color(0xff94A2B8), // สีของไอคอน
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
                          if (image!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 15),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12.0),
                                child: Image.network(
                                  image.toString(),
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  errorBuilder: (context, error, stackTrace) {
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
                      comments.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.only(top: 16.0),
                              child: Center(
                                // ทำให้ข้อความอยู่ตรงกลาง
                                child: Text(
                                  "No comments",
                                  style: GoogleFonts.dmSans(
                                    fontSize: 36, // ปรับขนาดเป็น 72
                                    fontWeight: FontWeight
                                        .bold, // เพิ่มความหนาให้อ่านง่าย
                                    color: Colors
                                        .grey[400], // ใช้สีเทาอ่อนให้ดูดีขึ้น
                                  ),
                                  textAlign: TextAlign
                                      .center, // เผื่อกรณีข้อความยาวขึ้น
                                ),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: comments.length,
                              itemBuilder: (context, index) {
                                final comment = comments[index];

                                // แปลงวันที่ให้เป็นรูปแบบอ่านง่าย
                                DateTime publishDate = DateTime.tryParse(
                                        comment['publish_date']) ??
                                    DateTime.now();
                                String formattedDate =
                                    DateFormat('dd MMMM yyyy HH:mm')
                                        .format(publishDate);

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
                                        borderRadius:
                                            BorderRadius.circular(10.0),
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
                                                      child: Image.asset(
                                                        'assets/images/avatar.png',
                                                        width: 40.0,
                                                        height: 40.0,
                                                        colorBlendMode:
                                                            BlendMode.srcIn,
                                                      ),
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
                                                          "User Name",
                                                          style: GoogleFonts
                                                              .dmSans(
                                                            fontSize: 14,
                                                            fontWeight:
                                                                FontWeight.w400,
                                                            color: const Color(
                                                                0xFF111111),
                                                          ),
                                                        ),
                                                        Text(
                                                          formattedDate,
                                                          style: GoogleFonts
                                                              .dmSans(
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
                                                        return FractionallySizedBox(
                                                          heightFactor:
                                                              0.45, // กำหนดความสูงเป็น 60% ของหน้าจอ
                                                          child: Container(
                                                            padding:
                                                                const EdgeInsets
                                                                    .all(16.0),
                                                            decoration:
                                                                BoxDecoration(
                                                              color: Color(
                                                                  0xFFEBEFFF),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .vertical(
                                                                top: Radius
                                                                    .circular(
                                                                        16),
                                                              ),
                                                            ),
                                                            child: Column(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .min,
                                                              children: [
                                                                Container(
                                                                  width: 42,
                                                                  height: 5,
                                                                  decoration:
                                                                      BoxDecoration(
                                                                    color: Color(
                                                                        0xFFCBD5E0),
                                                                    borderRadius:
                                                                        BorderRadius.circular(
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
                                                                      Container(
                                                                        decoration:
                                                                            BoxDecoration(
                                                                          color:
                                                                              Colors.white,
                                                                          borderRadius:
                                                                              BorderRadius.only(
                                                                            topLeft:
                                                                                Radius.circular(12),
                                                                            topRight:
                                                                                Radius.circular(12),
                                                                          ),
                                                                        ),
                                                                        child:
                                                                            ListTile(
                                                                          leading:
                                                                              SvgPicture.asset(
                                                                            'assets/images/edit_svg.svg',
                                                                            fit:
                                                                                BoxFit.cover,
                                                                            color:
                                                                                const Color(0xff355FFF),
                                                                          ),
                                                                          title:
                                                                              Text(
                                                                            'Edit post',
                                                                            style:
                                                                                GoogleFonts.dmSans(
                                                                              fontSize: 14,
                                                                              fontWeight: FontWeight.w400,
                                                                              color: Color(0xFF000000),
                                                                            ),
                                                                          ),
                                                                          onTap:
                                                                              () {
                                                                            final existingData =
                                                                                {
                                                                              'id': id,
                                                                              'description': description,
                                                                              'image': image,
                                                                              'dateTime': selectedStartDate
                                                                            };

                                                                            Navigator.push(
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
                                                                          color:
                                                                              Colors.white,
                                                                          borderRadius:
                                                                              BorderRadius.only(
                                                                            bottomLeft:
                                                                                Radius.circular(12),
                                                                            bottomRight:
                                                                                Radius.circular(12),
                                                                          ),
                                                                        ),
                                                                        child:
                                                                            ListTile(
                                                                          leading:
                                                                              SvgPicture.asset(
                                                                            'assets/images/delete_svg.svg',
                                                                            fit:
                                                                                BoxFit.cover,
                                                                            color:
                                                                                const Color(0xffED4B9E),
                                                                          ),
                                                                          title:
                                                                              Text(
                                                                            'Delete post',
                                                                            style:
                                                                                GoogleFonts.dmSans(
                                                                              fontSize: 14,
                                                                              fontWeight: FontWeight.w400,
                                                                              color: Color(0xFF000000),
                                                                            ),
                                                                          ),
                                                                          onTap:
                                                                              () {
                                                                            confirmDelete(context,
                                                                                id);
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
                                                padding: const EdgeInsets.only(
                                                    top: 15),
                                                child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          12.0),
                                                  child: Image.network(
                                                    image.toString(),
                                                    fit: BoxFit.cover,
                                                    width: double.infinity,
                                                    errorBuilder: (context,
                                                        error, stackTrace) {
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
                          backgroundImage:
                              AssetImage('assets/images/avatar.png'),
                        ),
                        SizedBox(
                            width: 8), // ระยะห่างระหว่าง Avatar กับ TextField
                        Expanded(
                          child: TextField(
                            controller: _commentController,
                            decoration: InputDecoration(
                              hintText: 'What about your opinion?',
                              hintStyle: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF747474),
                                fontWeight: FontWeight.w200,
                              ),
                              border: InputBorder.none,
                              contentPadding:
                                  EdgeInsets.symmetric(vertical: 12),
                            ),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.black,
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
