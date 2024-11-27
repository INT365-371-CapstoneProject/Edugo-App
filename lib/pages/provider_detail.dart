import 'package:edugo/pages/provider_management.dart';
import 'package:edugo/services/datetime_provider_add.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ProviderDetail extends StatefulWidget {
  final Map<String, dynamic>? initialData;

  const ProviderDetail({
    Key? key,
    this.initialData,
  }) : super(key: key);

  @override
  State<ProviderDetail> createState() => _ProviderDetailState();
}

class _ProviderDetailState extends State<ProviderDetail> {
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

  Future<void> submitDeleteData() async {
    final String apiUrl =
        "https://capstone24.sit.kmutt.ac.th/un2/api/announce/delete/${id}";

    var request = http.MultipartRequest('DELETE', Uri.parse(apiUrl));

    try {
      var response = await request.send();

      if (response.statusCode == 200) {
        showSuccess("Data deleted successfully");
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
      body: ListView(
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
                            Navigator.pop(context); // Go back
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
                            submitDeleteData(); // ไม่ต้องมี Navigator.pop ตรงนี้
                          },
                          child: CircleAvatar(
                            radius: 20,
                            backgroundColor: const Color(0xFFED4B9E),
                            child: Image.asset(
                              'assets/images/icon_delete.png',
                              width: 20.0,
                              height: 20.0,
                              colorBlendMode: BlendMode.srcIn,
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
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: top,
                child: Center(
                  child: image != null
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
                    overflow:
                        TextOverflow.ellipsis, // แสดง "..." หากข้อความยาวเกิน
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
                    overflow:
                        TextOverflow.ellipsis, // แสดง "..." หากข้อความยาวเกิน
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
                              selectedScholarshipType ?? 'Full Scholarship',
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
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
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
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

                // Description
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
                      // TextField
                      Container(
                        height: 353, // Adjust this height to fit your design
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Color(0xFFCBD5E0),
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
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
                    ],
                  ),
                ),

                const SizedBox(height: 200),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
