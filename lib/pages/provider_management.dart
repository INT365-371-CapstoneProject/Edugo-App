import 'package:edugo/pages/provider_add.dart';
import 'package:edugo/pages/provider_detail.dart';
import 'package:edugo/services/scholarship_card.dart';
import 'package:edugo/services/status_box.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class ProviderManagement extends StatefulWidget {
  const ProviderManagement({super.key});

  @override
  State<ProviderManagement> createState() => _ProviderManagementState();
}

class _ProviderManagementState extends State<ProviderManagement> {
  List<dynamic> scholarships = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchScholarships();
  }

  Future<void> fetchScholarships() async {
    const baseImageUrl =
        "https://capstone24.sit.kmutt.ac.th/un2/api/public/images/";
    const url = "https://capstone24.sit.kmutt.ac.th/un2/api/announce";
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          scholarships = data.map((scholarship) {
            scholarship['image'] = scholarship['image'] != null
                ? baseImageUrl + scholarship['image']
                : 'assets/images/scholarship_program.png';
            scholarship['title'] = scholarship['title'] ?? 'No Title';
            scholarship['description'] =
                scholarship['description'] ?? 'No Description Available';
            scholarship['published_date'] =
                scholarship['published_date'] ?? DateTime.now().toString();
            scholarship['close_date'] =
                scholarship['close_date'] ?? DateTime.now().toString();
            return scholarship;
          }).toList();
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load scholarships');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print("Error fetching scholarships: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Blue header block
          Container(
            height: 227,
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: const Color(0xFFDAFB59),
                      child: Image.asset(
                        'assets/images/back_button.png',
                        width: 20.0,
                        height: 20.0,
                        color: const Color(0xFF355FFF),
                        colorBlendMode: BlendMode.srcIn,
                      ),
                    ),
                    Image.asset(
                      'assets/images/avatar.png',
                      width: 40.0,
                      height: 40.0,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  "Scholarship Management",
                  style: GoogleFonts.dmSans(
                    fontSize: 20,
                    fontStyle: FontStyle.normal,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                    color: Color(0xFFFFFFFF),
                  ),
                ),
                const SizedBox(height: 16.0),
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
                              hintText: "Search for scholarship",
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
                : SingleChildScrollView(
                    padding: const EdgeInsets.only(top: 16, bottom: 16),
                    child: Column(
                      children: [
                        // StatusBox row
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              StatusBox(
                                title: "All",
                                color: const Color(0xFF355FFF),
                                count: scholarships.length.toString(),
                              ),
                              StatusBox(
                                title: "Pending",
                                color: const Color(0xFFD9D9D9),
                                count: scholarships
                                    .where((s) =>
                                        DateTime.parse(s['publish_date'])
                                            .isAfter(DateTime.now()))
                                    .length
                                    .toString(),
                              ),
                              StatusBox(
                                title: "Opened",
                                color: const Color(0xFFC4E250),
                                count: scholarships
                                    .where((s) =>
                                        DateTime.parse(s['publish_date'])
                                            .isBefore(DateTime.now()) &&
                                        DateTime.parse(s['close_date'])
                                            .isAfter(DateTime.now()))
                                    .length
                                    .toString(),
                              ),
                              StatusBox(
                                title: "Closed",
                                color: const Color(0xFFD5448E),
                                count: scholarships
                                    .where((s) =>
                                        DateTime.parse(s['close_date'])
                                            .isBefore(DateTime.now()))
                                    .length
                                    .toString(),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16.0),

                        // List of Scholarships
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const ClampingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          itemCount: scholarships.length,
                          itemBuilder: (context, index) {
                            final scholarship = scholarships[index];
                            final imageUrl = scholarship['image'] ??
                                'assets/images/scholarship_1.png';
                            final title = scholarship['title'] ?? 'No Title';
                            final description = scholarship['description'] ??
                                'No Description Available';
                            final publishedDate =
                                DateTime.parse(scholarship['published_date']);
                            final closeDate =
                                DateTime.parse(scholarship['close_date']);
                            final duration =
                                "${DateFormat('MMM').format(publishedDate)} - ${DateFormat('MMM').format(closeDate)} ${closeDate.year}";

                            // สร้างแท็กจากลำดับที่ของรายการ
                            final formattedTag =
                                "#${(index + 1).toString().padLeft(5, '0')}";

                            // เช็คสถานะตามเงื่อนไข
                            String status;
                            if (DateTime.now().isBefore(publishedDate)) {
                              status = "Pending";
                            } else if (DateTime.now().isBefore(closeDate)) {
                              status = "Open";
                            } else {
                              status = "Closed";
                            }

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: GestureDetector(
                                onTap: () {
                                  final existingData = {
                                    'id': scholarship['id'],
                                    'title': scholarship['title'],
                                    'url': scholarship['url'],
                                    'category': scholarship['category'],
                                    'country': scholarship['country'],
                                    'description': scholarship['description'],
                                    'image': scholarship['image'],
                                    'attach_file': scholarship['attach_file'],
                                    'published_date':
                                        scholarship['published_date'],
                                    'close_date': scholarship['close_date'],
                                  };

                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ProviderDetail(
                                        initialData:
                                            existingData, // ส่ง existingData ไปยังหน้าแก้ไข
                                      ),
                                    ),
                                  );
                                },
                                child: ScholarshipCard(
                                  image: imageUrl,
                                  tag: formattedTag,
                                  title: title,
                                  date: duration,
                                  status: status,
                                  description: description,
                                ),
                              ),
                            );
                          },
                        )
                      ],
                    ),
                  ),
          ),
          // Add New Scholarship Button at the bottom
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
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder:
                              (context, animation, secondaryAnimation) =>
                                  const ProviderAddEdit(isEdit: false),
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
                          "Add New Scholarship",
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
