import 'package:edugo/config/api_config.dart';
import 'package:edugo/features/scholarship/screens/provider_add.dart';
import 'package:edugo/features/scholarship/screens/provider_detail.dart';
import 'package:edugo/features/profile/screens/profile.dart';
import 'package:edugo/features/subject/subject_manage.dart';
import 'package:edugo/services/scholarship_card.dart';
import 'package:edugo/services/status_box.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:edugo/services/auth_service.dart';

class ProviderManagement extends StatefulWidget {
  const ProviderManagement({super.key});

  @override
  State<ProviderManagement> createState() => _ProviderManagementState();
}

class _ProviderManagementState extends State<ProviderManagement> {
  List<dynamic> filterPending = [];
  List<dynamic> filterOpened = [];
  List<dynamic> filterClosed = [];
  List<dynamic> scholarships = [];
  List<dynamic> useItem = [];
  bool isLoading = true;
  String selectedStatus = "All";
  final AuthService authService = AuthService(); // Instance of AuthService

  @override
  void initState() {
    super.initState();
    _delayedLoad(); // เรียกใช้งานฟังก์ชัน _delayedLoad
  }

  Future<void> fetchScholarships() async {
    try {
      String? token = await authService.getToken();
      Map<String, String> headers = {}; // Explicitly type the map
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response =
          await http.get(Uri.parse(ApiConfig.announceUrl), headers: headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data =
            json.decode(response.body); // Handle the response as a map
        List<dynamic> scholarshipData =
            data['data']; // Get the 'data' part, which is a list

        setState(() {
          scholarships = scholarshipData.map((scholarship) {
            // ignore: prefer_interpolation_to_compose_strings
            scholarship['image'] =
                ApiConfig.announceUrl + scholarship['id'].toString() + "/image";

            scholarship['title'] = scholarship['title'] ?? 'No Title';
            scholarship['description'] =
                scholarship['description'] ?? 'No Description Available';
            scholarship['published_date'] =
                scholarship['published_date'] ?? scholarship['publish_date'];
            scholarship['close_date'] =
                scholarship['close_date'] ?? scholarship['close_date'];
            return scholarship;
          }).toList();

          scholarships.sort(
              (a, b) => b['published_date'].compareTo(a['published_date']));

          filterPending = scholarships.where((s) {
            DateTime publishDate = DateTime.parse(s['published_date']);
            return publishDate.isAfter(DateTime.now());
          }).toList();

          filterOpened = scholarships.where((s) {
            DateTime publishDate = DateTime.parse(s['published_date']);
            DateTime closeDate = DateTime.parse(s['close_date']);
            return publishDate.isBefore(DateTime.now()) &&
                closeDate.isAfter(DateTime.now());
          }).toList();

          filterClosed = scholarships.where((s) {
            DateTime closeDate = DateTime.parse(s['close_date']);
            return closeDate.isBefore(DateTime.now());
          }).toList();

          isLoading = false;
          useItem = scholarships;
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

  Future<void> _delayedLoad() async {
    await Future.delayed(const Duration(seconds: 3)); // Delay 3 seconds
    fetchScholarships();
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
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          PageRouteBuilder(
                            pageBuilder:
                                (context, animation, secondaryAnimation) =>
                                    const ProviderProfile(),
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
                          'assets/images/back_button.png',
                          width: 20.0,
                          height: 20.0,
                          color: const Color(0xFF355FFF),
                          colorBlendMode: BlendMode.srcIn,
                        ),
                      ),
                    ),
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: const Color(0xFFC0CDFF),
                      child: Image.asset(
                        'assets/images/brower.png',
                        width: 40.0,
                        height: 40.0,
                      ),
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
                : RefreshIndicator(
                    onRefresh:
                        _delayedLoad, // Callback ฟังก์ชันเมื่อเลื่อนรีเฟรช
                    child: SingleChildScrollView(
                      physics:
                          const AlwaysScrollableScrollPhysics(), // เปิดให้เลื่อนเสมอ
                      padding: const EdgeInsets.only(top: 16, bottom: 16),
                      child: Column(
                        children: [
                          // StatusBox row
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      selectedStatus = "All";
                                      // Update the filtered list based on the selected status
                                      useItem = scholarships;
                                    });
                                  },
                                  child: StatusBox(
                                    title: "All",
                                    color: const Color(0xFF355FFF),
                                    count: scholarships.length.toString(),
                                  ),
                                ),
                                // Pending StatusBox
                                // Update the onTap for StatusBox
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      selectedStatus = "Pending";
                                      // Update the filtered list based on the selected status
                                      useItem = filterPending;
                                    });
                                  },
                                  child: StatusBox(
                                    title: "Pending",
                                    color: const Color(0xFFD9D9D9),
                                    count: scholarships
                                        .where((s) =>
                                            DateTime.parse(s['publish_date'])
                                                .isAfter(DateTime.now()))
                                        .length
                                        .toString(),
                                  ),
                                ),

                                // Repeat for other status boxes (Opened, Closed, All) with proper filtered data
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      selectedStatus = "Opened";
                                      useItem = filterOpened;
                                    });
                                  },
                                  child: StatusBox(
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
                                ),

                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      selectedStatus = "Closed";
                                      useItem = filterClosed;
                                    });
                                  },
                                  child: StatusBox(
                                    title: "Closed",
                                    color: const Color(0xFFD5448E),
                                    count: scholarships
                                        .where((s) =>
                                            DateTime.parse(s['close_date'])
                                                .isBefore(DateTime.now()))
                                        .length
                                        .toString(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16.0),

                          // List of Scholarships
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const ClampingScrollPhysics(),
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16.0),
                            itemCount: useItem.length,
                            itemBuilder: (context, index) {
                              final scholarship = useItem[index];
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
                                  "${DateFormat('d MMM').format(publishedDate)} - ${DateFormat('d MMM yyyy').format(closeDate)}";

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
                                          initialData: existingData,
                                          isProvider:
                                              true, // ส่ง existingData ไปยังหน้าแก้ไข
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
