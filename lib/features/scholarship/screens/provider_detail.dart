import 'package:edugo/features/home/screens/home_screen.dart';
import 'package:edugo/features/scholarship/screens/provider_add.dart';
import 'package:edugo/features/scholarship/screens/provider_management.dart';
import 'package:edugo/services/auth_service.dart';
import 'package:edugo/services/datetime_provider_add.dart';
import 'package:edugo/shared/utils/endpoint.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ProviderDetail extends StatefulWidget {
  final bool isProvider;
  final Map<String, dynamic>? initialData;

  const ProviderDetail({
    Key? key,
    required this.isProvider,
    this.initialData,
  }) : super(key: key);

  @override
  State<ProviderDetail> createState() => _ProviderDetailState();
}

class _ProviderDetailState extends State<ProviderDetail> {
  final AuthService authService = AuthService();
  int? id;
  String? title; // Scholarship Name
  String? description; // Description
  String? url; // Web URL
  String? image;
  String? attachFile;
  String? selectedScholarshipType; // Scholarship Type
  String? selectedCountry;
  DateTime? selectedStartDate;
  DateTime? selectedEndDate;
  final double coverHeight = 227;
  final double pictureHeight = 114;

  @override
  void initState() {
    super.initState();

    if (widget.initialData != null) {
      final data = widget.initialData!;
      id = data['id'] ?? '';
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
      image = data['image'] ?? '';
      attachFile = data['attach_file'] ?? 'No Attach Files';
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

  Future<void> submitDeleteData() async {
    final String apiUrl = "${Endpoints.announce}/delete/${id}";

    var request = http.MultipartRequest('DELETE', Uri.parse(apiUrl));

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

  Future<void> addBookmark() async {
    final url = Uri.parse(Endpoints.bookmark);

    String? token = await authService.getToken();

    // Create headers map
    Map<String, String> headers = {'Content-Type': 'application/json'};

    // Add Authorization header if token is available
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    try {
      final response = await http.post(
        url,
        headers: headers, // Use the headers with the token
        body: json.encode({"announce_id": id}),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        print("Success");
      } else {
        print(response);
      }
    } catch (e) {
      print(e);
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

    return Scaffold(
      backgroundColor: const Color(0xffFFFFFF),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
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
                                  Navigator.pushReplacement(
                                    context,
                                    PageRouteBuilder(
                                      pageBuilder: (context, animation,
                                              secondaryAnimation) =>
                                          widget.isProvider
                                              ? const ProviderManagement()
                                              : const HomeScreenApp(),
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
                                    addBookmark();
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
                                          Icons.favorite,
                                          color: Colors
                                              .red, // กำหนดสีให้ไอคอนหัวใจ
                                          size: 24, // ขนาดของไอคอน
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
                                color: const Color.fromARGB(255, 255, 255, 255),
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
                                image != "assets/images/scholarship_program.png"
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  image ?? '',
                                  width: 245,
                                  height: 338,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
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
                  padding: const EdgeInsets.symmetric(horizontal: 14.0),
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
                        children: [
                          Column(
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
                                child: Container(
                                  width: 150, // กำหนดความกว้างเป็น 150px
                                  child: Text(
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
                              ),
                            ],
                          ),
                          const SizedBox(width: 49),
                          Column(
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
                                padding: const EdgeInsets.only(left: 11),
                                child: Container(
                                  width: 160, // กำหนดความกว้างเป็น 150px
                                  child: Text(
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
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Date Selector
                      Container(
                        height: 190,
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

                      // Attach_file
                      Container(
                        height: 96,
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Color(0xFFCBD5E0),
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
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
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        attachFile
                                            .toString(), // แสดงชื่อไฟล์ที่ถูกเลือก
                                        style: GoogleFonts.dmSans(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w400,
                                          fontStyle: FontStyle.italic,
                                          color: Color(0xFF94A2B8),
                                        ),
                                        overflow: TextOverflow
                                            .ellipsis, // หากชื่อไฟล์ยาวเกินไป
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),

                      Container(
                        height: 414,
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
                          children: [
                            Text(
                              'Description*',
                              style: GoogleFonts.dmSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            // Scrollable TextField
                            Container(
                              height: 353,
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
                          ? const SizedBox(height: 200)
                          : const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (widget.isProvider)
            SizedBox(
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
                        // Prepare data to pass
                        final existingData = {
                          'id': id,
                          'title': title,
                          if (url == null || url == 'No Website')
                            'url':
                                null, // This will only add the key 'url' with null value if the condition is met
                          if (url != null && url != 'No Website')
                            'url':
                                url, // This will add 'url' with the given value if the condition is met
                          'category': selectedScholarshipType,
                          'country': selectedCountry,
                          'description': description,
                          'image': image,
                          'attach_file': attachFile,
                          'published_date':
                              selectedStartDate?.toIso8601String(),
                          'close_date': selectedEndDate?.toIso8601String(),
                        };

                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (context, animation,
                                    secondaryAnimation) =>
                                ProviderAddEdit(
                                    isEdit: true, initialData: existingData),
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
              ),
            ),
        ],
      ),
    );
  }
}
