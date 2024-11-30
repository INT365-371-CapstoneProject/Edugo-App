import 'dart:typed_data';
import 'package:edugo/pages/subject_detail.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';

import 'package:http_parser/http_parser.dart';

class SubjectManagement extends StatefulWidget {
  const SubjectManagement({super.key});

  @override
  State<SubjectManagement> createState() => _SubjectManagementState();
}

class _SubjectManagementState extends State<SubjectManagement> {
  List<dynamic> subject = [];
  List<dynamic> useItem = [];
  bool isLoading = true;
  String selectedStatus = "All";
  Uint8List? _imageBytes;

  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _delayedLoad(); // เรียกใช้งานฟังก์ชัน _delayedLoad
  }

  Future<void> fetchsubject() async {
    const baseImageUrl =
        "https://capstone24.sit.kmutt.ac.th/un2/api/public/images/";
    const url = "https://capstone24.sit.kmutt.ac.th/un2/api/subject";
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          subject = data.map((subject) {
            subject['image'] = subject['image'] != null
                ? baseImageUrl + subject['image']
                : ''; // fallback ให้เป็นค่าว่างถ้าไม่มีรูป
            subject['title'] = subject['title'] ?? 'No Title';
            subject['description'] =
                subject['description'] ?? 'No Description Available';
            subject['published_date'] =
                subject['published_date'] ?? subject['publish_date'];
            return subject;
          }).toList();
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

  Future<void> submitAddData() async {
    final String apiUrl =
        "https://capstone24.sit.kmutt.ac.th/un2/api/subject/add";

    var request = http.MultipartRequest('POST', Uri.parse(apiUrl));

    request.fields['title'] = titleController.text;
    request.fields['description'] = descriptionController.text;
    request.fields['posts_type'] = 'Announce';
    request.fields['publish_date'] =
        '${DateTime.now().toUtc().toIso8601String().split('.')[0]}Z';

    request.fields['country_id'] = '1';

    if (_imageBytes != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          _imageBytes!,
          filename: 'image.jpg',
          contentType: MediaType('image', 'jpeg'),
        ),
      );
    }

    void showResponse(String message) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }

    try {
      // เพิ่มการหน่วงเวลา 3 วินาที
      await Future.delayed(Duration(seconds: 3));

      var response = await request.send();

      Navigator.of(context).pop(); // ปิด Loading Dialog

      if (response.statusCode == 200 || response.statusCode == 201) {
        showResponse("Success: ${response.statusCode}");
      } else {
        showResponse(
            "Failed to submit data. Status code: ${response.statusCode}");
      }
    } catch (e) {
      Navigator.of(context).pop(); // ปิด Loading Dialog
      showResponse("Error occurred: $e");
    }
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
            height: 190,
            width: double.infinity,
            color: const Color(0xFF355FFF),
            padding: const EdgeInsets.only(
              top: 58.0,
              right: 16,
              left: 16,
              bottom: 22,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Text(
                  "Post Subject List",
                  style: GoogleFonts.dmSans(
                    fontSize: 22,
                    fontStyle: FontStyle.normal,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                    color: Color(0xFFFFFFFF),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  height: 47.0,
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
                              hintText: "Search for ports",
                              hintStyle: GoogleFonts.dmSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                color: Colors.grey[400],
                              ),
                              border: InputBorder.none,
                            ),
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
                              final imageUrl = subject['image'];
                              final title = subject['title'] ?? 'No Title';
                              final description = subject['description'] ??
                                  'No Description Available';
                              final publishedDate = DateTime.tryParse(
                                  subject['published_date'] ?? '');
                              final formattedDate = publishedDate != null
                                  ? DateFormat('hh:mm a · dd/MM/yyyy')
                                      .format(publishedDate)
                                  : 'N/A';

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16.0),
                                child: GestureDetector(
                                  onTap: () {
                                    final existingData = {
                                      'id': subject['id'],
                                      'title': subject['title'],
                                      'description': subject['description'],
                                      'image': subject['image'],
                                      'published_date':
                                          subject['published_date'],
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
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            title,
                                            style: GoogleFonts.dmSans(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: const Color(0xFF355FFF),
                                            ),
                                          ),
                                          const SizedBox(height: 8.0),
                                          Text(
                                            description,
                                            style: GoogleFonts.dmSans(
                                              fontSize: 14,
                                              fontWeight: FontWeight.normal,
                                              color: Colors.grey[700],
                                            ),
                                            maxLines: 3,
                                          ),
                                          if (imageUrl.isNotEmpty)
                                            Padding(
                                              padding:
                                                  const EdgeInsets.only(top: 8),
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(8.0),
                                                child: Image.network(
                                                  imageUrl,
                                                  fit: BoxFit.cover,
                                                  width: double.infinity,
                                                  errorBuilder: (context, error,
                                                      stackTrace) {
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
                                          const SizedBox(height: 8.0),
                                          Text(
                                            formattedDate,
                                            style: GoogleFonts.dmSans(
                                              fontSize: 12,
                                              fontWeight: FontWeight.normal,
                                              color: Colors.grey[600],
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
          SizedBox(
            height: 113,
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding:
                    const EdgeInsets.only(top: 15.0, left: 16.0, right: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // ปุ่ม home อยู่ทางซ้าย
                    SizedBox(
                      height: 48,
                      width: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          // Action สำหรับปุ่ม home
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white, // สีพื้นหลังขาว
                          shape: CircleBorder(),
                          padding: EdgeInsets.zero,
                          side: BorderSide.none, // ไม่มีขอบ
                          elevation: 0, // ไม่ให้เงาปุ่ม
                        ),
                        child: Icon(
                          Icons.home, // ไอคอน home
                          color: const Color(0xFF355FFF),
                          size: 48,
                        ),
                      ),
                    ),
                    // ระยะห่างระหว่างปุ่ม home กับปุ่ม +
                    const SizedBox(width: 60), // ห่างกัน 24 หน่วย
                    // ปุ่ม + อยู่ตรงกลาง
                    SizedBox(
                      height: 48,
                      width: 84, // กำหนดความกว้างของปุ่ม
                      child: ElevatedButton(
                        onPressed: _showAddSubjectDialog, // แสดง Dialog
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color(0xFF355FFF), // สีพื้นหลังฟ้า
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24), // มุมโค้ง
                          ),
                          padding: EdgeInsets.zero,
                          elevation: 0, // ไม่ให้เงาปุ่ม
                        ),
                        child: Icon(
                          Icons.add, // ไอคอน +
                          color: Colors.white,
                          size: 28, // ขนาดไอคอน
                        ),
                      ),
                    ),
                    // ระยะห่างระหว่างปุ่ม + กับปุ่ม profile
                    const SizedBox(width: 60), // ห่างกัน 24 หน่วย
                    // ปุ่ม profile อยู่ทางขวา
                    SizedBox(
                      height: 48,
                      width: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          // Action สำหรับปุ่ม profile
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white, // สีพื้นหลังขาว
                          shape: CircleBorder(),
                          padding: EdgeInsets.zero,
                          side: BorderSide.none, // ไม่มีขอบ
                          elevation: 0, // ไม่ให้เงาปุ่ม
                        ),
                        child: Icon(
                          Icons.person, // ไอคอน profile
                          color: const Color(0xFF355FFF),
                          size: 48,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
