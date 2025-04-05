import 'dart:convert';
import 'dart:typed_data';
import 'package:edugo/features/bookmark/screens/bookmark_list.dart';
import 'package:edugo/features/login&register/login.dart';
import 'package:edugo/features/notification/screens/notification_management.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:edugo/features/profile/screens/edit_profile.dart';
import 'package:edugo/features/scholarship/screens/provider_management.dart';
import 'package:edugo/features/subject/screens/subject_add_edit.dart';
import 'package:edugo/features/subject/screens/subject_manage.dart';
import 'package:edugo/services/auth_service.dart';
import 'package:edugo/services/footer.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;

class ProviderProfile extends StatefulWidget {
  const ProviderProfile({super.key});

  @override
  State<ProviderProfile> createState() => _ProviderProfileState();
}

final double coverHeight = 152;
final double profileHeight = 90;

class _ProviderProfileState extends State<ProviderProfile> {
  final AuthService authService = AuthService();
  final top = coverHeight - profileHeight / 2;
  final bottom = profileHeight / 2;
  final arrow = const Icon(Icons.arrow_forward_ios, size: 15);
  Map<String, dynamic>? profile; // ใช้ Map ไม่ใช่ List

  @override
  void initState() {
    super.initState();
    fetchProfile(); // โหลดข้อมูลโปรไฟล์ทันทีที่เปิดหน้านี้
    fetchAvatarImage();
  }

  Uint8List? imageData;

  Future<void> fetchAvatarImage() async {
    String? token = await authService.getToken();

    final response = await http.get(
      Uri.parse('https://capstone24.sit.kmutt.ac.th/un2/api/profile/avatar'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        imageData = response.bodyBytes; // แปลง response เป็น Uint8List
      });
    } else {
      throw Exception('Failed to load country data');
    }
  }

  Future<void> fetchProfile() async {
    const url = "https://capstone24.sit.kmutt.ac.th/un2/api/profile";

    try {
      String? token = await authService.getToken();
      Map<String, String> headers = {};
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final Map<String, dynamic> profileData =
            data['profile']; // ดึงข้อมูลโปรไฟล์

        setState(() {
          profile = {
            'id': profileData['id'],
            'email': profileData['email'],
            'username': profileData['username'],
            'first_name': profileData['first_name'] ?? '',
            'last_name': profileData['last_name'] ?? '',
            'role': profileData['role'],
            'company_name': profileData['company_name'] ?? '',
            'phone': profileData['phone'] ?? '',
            'phone_person': profileData['phone_person'] ?? '',
            'address': profileData['address'] ?? '',
            'city': profileData['city'] ?? '',
            'country': profileData['country'] ?? '',
            'postal_code': profileData['postal_code'] ?? '',
          };
        });
        print(profile);
        print(profile);
      } else {
        throw Exception('Failed to load profile');
      }
    } catch (e) {
      setState(() {});
      print("Error fetching profile: $e");
    }
  }

  Future<void> _delayedLoad() async {
    await Future.delayed(const Duration(seconds: 3)); // Delay 3 seconds
    fetchProfile();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFFFFF),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Cover Image Section
          Container(
            color: Colors.white, // Background color
            child: Column(
              children: [
                SizedBox(
                  height: coverHeight,
                  child: Container(
                    color: const Color(0xFF355FFF),
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              GestureDetector(
                                onTap: () {},
                                child: CircleAvatar(
                                  backgroundColor: const Color(0xFFDAFB59),
                                  child: Image.asset(
                                    'assets/images/back_button.png',
                                    width: 20.0,
                                    height: 20.0,
                                    color: const Color(0xFF355FFF),
                                  ),
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
                        ),
                        Positioned(
                          top: top,
                          child: Container(
                            margin: EdgeInsets.only(bottom: bottom),
                            width: profileHeight,
                            height: profileHeight,
                            decoration: BoxDecoration(
                              color: Colors.grey, // Background color
                              borderRadius:
                                  BorderRadius.circular(profileHeight / 2),
                            ),
                            child: ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(profileHeight / 2),
                              child: imageData != null
                                  ? Image.memory(imageData!)
                                  : Image.asset(
                                      'assets/images/welcome.png',
                                      width: profileHeight,
                                      height: profileHeight,
                                      fit: BoxFit.cover,
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Profile Options Section
          Container(
            margin: EdgeInsets.only(top: bottom),
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    profile != null
                        ? (profile!['role'] == "provider"
                            ? (profile!['company_name'].isNotEmpty
                                ? profile!['company_name']
                                : "No Company Name")
                            : "${profile!['first_name']} ${profile!['last_name']}"
                                    .trim()
                                    .isNotEmpty
                                ? "${profile!['first_name']} ${profile!['last_name']}"
                                : "No Name Available")
                        : "Loading...",
                    style: GoogleFonts.dmSans(
                        fontSize: 20, fontWeight: FontWeight.w500),
                  ),
                ),
                SizedBox(height: 16),
                // For role provider
                if (profile != null && profile!['role'] == "provider") ...[
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProviderManagement(),
                              ),
                            );
                          },
                          child: Image.asset(
                              "assets/images/scholarship_management.png"),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                _buildProfileOption(
                  icon: Icons.person,
                  label: "Edit Profile",
                  onTap: () {
                    print(profile);
                    if (profile != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ProviderProfileEdit(profileData: profile!),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text("Profile data is not available")),
                      );
                    }
                  },
                ),
                _buildProfileOption(
                    icon: Icons.verified,
                    label: "Get Verified Status",
                    onTap: () {
                      // Perform action
                    }),
                _buildProfileOption(
                    icon: Icons.lock,
                    label: "Change Password",
                    onTap: () {
                      // Perform action
                    }),
                _buildProfileOption(
                    icon: Icons.bookmark,
                    label: "Bookmark",
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        PageRouteBuilder(
                          pageBuilder:
                              (context, animation, secondaryAnimation) =>
                                  BookmarkList(id: profile!['id']),
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
                    }),
                _buildProfileOption(
                    icon: Icons.notifications,
                    label: "Notification",
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        PageRouteBuilder(
                          pageBuilder:
                              (context, animation, secondaryAnimation) =>
                                  NotificationList(id: profile!['id']),
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
                    }),
                _buildProfileOption(
                    icon: Icons.settings,
                    label: "Manage Account",
                    onTap: () {
                      // Perform action
                    }),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 8.0), // เพิ่มระยะห่างแนวตั้ง
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16.0), // เพิ่ม padding ด้านซ้าย-ขวา
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFFEBEFFF),
                      child: Icon(
                        Icons.logout, // ใช้ไอคอน Logout
                        color: const Color(0xFF355FFF), // กำหนดสีของไอคอน
                      ),
                    ),
                    title: Text("Logout"),
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        PageRouteBuilder(
                          pageBuilder:
                              (context, animation, secondaryAnimation) =>
                                  const Login(),
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
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      // Footer Navigation Bar
      bottomNavigationBar: FooterNav(
        pageName: "profile",
      ),
    );
  }

  Widget _buildProfileOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(vertical: 8.0), // เพิ่มระยะห่างแนวตั้ง
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 16.0), // เพิ่ม padding ด้านซ้าย-ขวา
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFEBEFFF),
          child: Icon(icon, color: const Color(0xFF355FFF)),
        ),
        title: Text(label),
        trailing: arrow,
        onTap: onTap,
      ),
    );
  }
}
