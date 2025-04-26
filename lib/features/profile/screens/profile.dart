import 'dart:convert';
import 'dart:typed_data';
import 'package:edugo/config/api_config.dart';
import 'package:edugo/features/account/screens/manage_account.dart';
import 'package:edugo/features/bookmark/screens/bookmark_management.dart';
import 'package:edugo/features/login&register/login.dart';
import 'package:edugo/features/notification/screens/notification_management.dart';
import 'package:edugo/features/profile/screens/help_center.dart';
import 'package:edugo/shared/utils/textStyle.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:edugo/features/profile/screens/edit_profile.dart';
import 'package:edugo/features/scholarship/screens/provider_management.dart';
import 'package:edugo/features/subject/subject_add_edit.dart';
import 'package:edugo/features/subject/subject_manage.dart';
import 'package:edugo/services/auth_service.dart';
import 'package:edugo/services/footer.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:edugo/main.dart'; // Import main.dart เพื่อเข้าถึง navigatorKey
import 'package:edugo/features/profile/screens/change_password.dart'; // Import the new screen

class PersonalProfile extends StatefulWidget {
  const PersonalProfile({super.key});

  @override
  State<PersonalProfile> createState() => _PersonalProfileState();
}

final double coverHeight = 152;
final double profileHeight = 90;

class _PersonalProfileState extends State<PersonalProfile> {
  // แก้ไขการสร้าง AuthService instance
  final AuthService authService = AuthService(navigatorKey: navigatorKey);
  final top = coverHeight - profileHeight / 2;
  final bottom = profileHeight / 2;
  final arrow = const Icon(Icons.arrow_forward_ios, size: 15);
  Map<String, dynamic>? profile; // ใช้ Map ไม่ใช่ List
  final GlobalKey _browserButtonKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    authService.checkSessionValidity(); // เพิ่มการตรวจสอบ session ที่นี่
    fetchProfile(); // โหลดข้อมูลโปรไฟล์ทันทีที่เปิดหน้านี้
    fetchAvatarImage();
  }

  Uint8List? imageData;

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
        imageData = response.bodyBytes; // แปลง response เป็น Uint8List
      });
    } else {}
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
    bool isProvider = profile != null && profile!['role'] == "provider";
    return Scaffold(
      backgroundColor: Color(0xFFFFFFFF),
      body: Stack(
        children: [
          Positioned.fill(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 80.0),
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
                              // Padding(
                              //   padding: const EdgeInsets.all(16.0),
                              //   child: Row(
                              //     mainAxisAlignment:
                              //         MainAxisAlignment.spaceBetween,
                              //     children: [
                              //       GestureDetector(
                              //         onTap: () {},
                              //         child: CircleAvatar(
                              //           backgroundColor:
                              //               const Color(0xFFDAFB59),
                              //           child: Image.asset(
                              //             'assets/images/back_button.png',
                              //             width: 20.0,
                              //             height: 20.0,
                              //             color: const Color(0xFF355FFF),
                              //           ),
                              //         ),
                              //       ),
                              //       CircleAvatar(
                              //         radius: 20,
                              //         backgroundColor: const Color(0xFFDAFB59),
                              //         child: GestureDetector(
                              //           onTap: () {
                              //             print(profile?["id"]);
                              //             Navigator.push(
                              //               context,
                              //               PageRouteBuilder(
                              //                 pageBuilder: (context, animation,
                              //                         secondaryAnimation) =>
                              //                     NotificationList(
                              //                   id: profile?['id'],
                              //                 ),
                              //                 transitionsBuilder: (context,
                              //                     animation,
                              //                     secondaryAnimation,
                              //                     child) {
                              //                   const begin = 0.0;
                              //                   const end = 1.0;
                              //                   const curve = Curves.easeOut;

                              //                   var tween = Tween(
                              //                           begin: begin, end: end)
                              //                       .chain(CurveTween(
                              //                           curve: curve));
                              //                   return FadeTransition(
                              //                     opacity:
                              //                         animation.drive(tween),
                              //                     child: child,
                              //                   );
                              //                 },
                              //                 transitionDuration:
                              //                     const Duration(
                              //                         milliseconds: 300),
                              //               ),
                              //             );
                              //           },
                              //           child: Image.asset(
                              //             'assets/images/notification.png',
                              //             width: 40.0,
                              //             height: 40.0,
                              //             color: const Color(0xFF355FFF),
                              //             colorBlendMode: BlendMode.srcIn,
                              //           ),
                              //         ),
                              //       ),
                              //     ],
                              //   ),
                              // ),
                              Positioned(
                                top: top,
                                child: Container(
                                  margin: EdgeInsets.only(bottom: bottom),
                                  width: profileHeight,
                                  height: profileHeight,
                                  decoration: BoxDecoration(
                                    color: Colors.grey, // Background color
                                    borderRadius: BorderRadius.circular(
                                        profileHeight / 2),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(
                                        profileHeight / 2),
                                    child: imageData != null
                                        ? Image.memory(
                                            imageData!,
                                            width: profileHeight,
                                            height: profileHeight,
                                            fit: BoxFit.cover,
                                          )
                                        : Image.asset(
                                            'assets/images/avatar.png',
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
                      if (profile != null &&
                          profile!['role'] == "provider") ...[
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24.0),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        backgroundColor:
                                            const Color(0xFFFFFFFF),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        contentPadding:
                                            const EdgeInsets.all(24),
                                        content: SizedBox(
                                          height: 530,
                                          width: 370,
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const SizedBox(height: 24),
                                              Image.asset(
                                                "assets/images/manage-your-scholdarship.png", // เปลี่ยนเป็นรูปที่เหมือนในภาพ
                                                height: 205,
                                                width: 262,
                                              ),
                                              const SizedBox(height: 20),
                                              Text(
                                                "Hey! We also have a\ndesktop-friendly\nversion of our site!",
                                                textAlign: TextAlign.center,
                                                style:
                                                    TextStyleService.getDmSans(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.w500,
                                                  height: 1.4,
                                                  color: Color(0xFF000000),
                                                ),
                                              ),
                                              const SizedBox(height: 15),
                                              Text(
                                                "You can simply copy this link and access it\ndirectly from your computer anytime!",
                                                textAlign: TextAlign.center,
                                                style:
                                                    TextStyleService.getDmSans(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w400,
                                                ),
                                              ),
                                              const SizedBox(height: 24),
                                              SizedBox(
                                                width: double.infinity,
                                                height: 50,
                                                child: ElevatedButton(
                                                  key: _browserButtonKey,
                                                  onPressed: () async {
                                                    await Clipboard.setData(
                                                        ClipboardData(
                                                            text:
                                                                "https://capstone24.sit.kmutt.ac.th/un2/Officialwebpage"));

                                                    final overlay =
                                                        Overlay.of(context);
                                                    final renderBox =
                                                        _browserButtonKey
                                                                .currentContext!
                                                                .findRenderObject()
                                                            as RenderBox;
                                                    final offset =
                                                        renderBox.localToGlobal(
                                                            Offset.zero);
                                                    final size = renderBox.size;

                                                    final overlayEntry =
                                                        OverlayEntry(
                                                      builder: (context) =>
                                                          Positioned(
                                                        top: offset.dy,
                                                        left: offset.dx,
                                                        width: size.width,
                                                        height: size.height,
                                                        child: Material(
                                                          color: Colors
                                                              .transparent,
                                                          child: Align(
                                                            alignment: Alignment
                                                                .topCenter,
                                                            child:
                                                                FractionalTranslation(
                                                              translation: Offset(
                                                                  0,
                                                                  -1.1), // ปรับให้ลอยขึ้นเหนือปุ่ม
                                                              child: SizedBox(
                                                                width: 73,
                                                                height: 37,
                                                                child: Stack(
                                                                  alignment:
                                                                      Alignment
                                                                          .center,
                                                                  children: [
                                                                    SvgPicture
                                                                        .asset(
                                                                      'assets/images/copied-manage-scholarship.svg',
                                                                      width: 73,
                                                                      height:
                                                                          37,
                                                                      fit: BoxFit
                                                                          .cover,
                                                                    ),
                                                                    Padding(
                                                                      padding: EdgeInsets.only(
                                                                          bottom:
                                                                              12.0),
                                                                      child:
                                                                          Text(
                                                                        'Copied!',
                                                                        style: TextStyleService
                                                                            .getDmSans(
                                                                          color:
                                                                              Color(0xFF355FFF),
                                                                          fontSize:
                                                                              13,
                                                                          fontWeight:
                                                                              FontWeight.w500,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    );

                                                    overlay
                                                        .insert(overlayEntry);
                                                    await Future.delayed(
                                                        Duration(seconds: 2));
                                                    overlayEntry.remove();
                                                  },
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        const Color(0xFFFFFFFF),
                                                    elevation: 0, // ไม่มีเงา
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                      side: const BorderSide(
                                                        // ขอบปุ่ม
                                                        color: Color(
                                                            0xFFC0CDFF), // สีขอบ
                                                        width: 1, // ความหนาขอบ
                                                      ),
                                                    ),
                                                  ),
                                                  child: Text(
                                                    "Copy website’s link",
                                                    style: TextStyleService
                                                        .getDmSans(
                                                      fontSize: 14,
                                                      color: const Color(
                                                          0xFF0E1729),
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 16),
                                              SizedBox(
                                                width: double.infinity,
                                                height: 50,
                                                child: ElevatedButton(
                                                  onPressed: () {
                                                    Navigator.pop(
                                                        context); // ปิด dialog
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) =>
                                                            ProviderManagement(),
                                                      ),
                                                    );
                                                  },
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        const Color(0xFF355FFF),
                                                    shape:
                                                        RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        8)),
                                                  ),
                                                  child: Text(
                                                      "Thanks, I'll continue on mobile",
                                                      style: TextStyleService
                                                          .getDmSans(
                                                              fontSize: 16,
                                                              color: Color(
                                                                  0xFFFFFFFF),
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600)),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                                child: Image.asset(
                                    "assets/images/scholarship_management.png"),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 0),
                      ],

                      _buildProfileOption(
                        icon: Icons.person,
                        label: "Edit Profile",
                        onTap: () {
                          if (profile != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    PersonalProfileEdit(profileData: profile!),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content:
                                      Text("Profile data is not available")),
                            );
                          }
                        },
                      ),
                      // if (profile != null && profile!['role'] == "provider") ...[
                      //   _buildProfileOption(
                      //       icon: Icons.verified,
                      //       label: "Get Verified Status",
                      //       onTap: () {
                      //         // Perform action
                      //       }),
                      // ],
                      _buildProfileOption(
                          icon: Icons.lock,
                          label: "Change Password",
                          onTap: () {
                            // Navigate to Change Password Screen
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const ChangePasswordScreen(),
                              ),
                            );
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
                          }),
                      // _buildProfileOption(
                      //     icon: Icons.notifications,
                      //     label: "Notification",
                      //     onTap: () {
                      //       Navigator.pushReplacement(
                      //         context,
                      //         PageRouteBuilder(
                      //           pageBuilder:
                      //               (context, animation, secondaryAnimation) =>
                      //                   NotificationList(id: profile!['id']),
                      //           transitionsBuilder: (context, animation,
                      //               secondaryAnimation, child) {
                      //             const begin = 0.0;
                      //             const end = 1.0;
                      //             const curve = Curves.easeOut;

                      //             var tween = Tween(begin: begin, end: end)
                      //                 .chain(CurveTween(curve: curve));
                      //             return FadeTransition(
                      //               opacity: animation.drive(tween),
                      //               child: child,
                      //             );
                      //           },
                      //           transitionDuration:
                      //               const Duration(milliseconds: 300),
                      //         ),
                      //       );
                      //     }),
                      _buildProfileOption(
                          icon: Icons.settings,
                          label: "Manage Account",
                          onTap: () {
                            Navigator.pushReplacement(
                              context,
                              PageRouteBuilder(
                                pageBuilder:
                                    (context, animation, secondaryAnimation) =>
                                        ManageAccount(id: profile!['id']),
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
                          }),
                      _buildProfileOption(
                          icon: Icons.info,
                          label: "Help Center",
                          onTap: () {
                            // Navigate to Change Password Screen
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const HelpCenterScreen(),
                              ),
                            );
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
                          onTap: _handleLogout,
                        ),
                      ),

                      // Conditional rendering of verification button only for providers
                      // isProvider
                      //     ? Padding(
                      //         padding: const EdgeInsets.only(top: 16.0),
                      //         child: SizedBox(
                      //           width: double.infinity,
                      //           height: 50.0,
                      //           child: ElevatedButton(
                      //             onPressed: () {
                      //               // Navigate to appropriate verification screen
                      //               Navigator.push(
                      //                 context,
                      //                 MaterialPageRoute(
                      //                     builder: (context) =>
                      //                         const ProviderManagement()),
                      //               );
                      //             },
                      //             style: ElevatedButton.styleFrom(
                      //               backgroundColor: const Color(0xFF355FFF),
                      //               shape: RoundedRectangleBorder(
                      //                 borderRadius: BorderRadius.circular(8),
                      //               ),
                      //             ),
                      //             child: Text(
                      //               "Get Verification",
                      //               style: GoogleFonts.dmSans(
                      //                 fontSize: 16.0,
                      //                 fontWeight: FontWeight.w500,
                      //                 color: Colors.white,
                      //               ),
                      //             ),
                      //           ),
                      //         ),
                      //       )
                      //     : Container(),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: MediaQuery.removeViewInsets(
              context: context,
              removeBottom: true,
              child: FooterNav(
                pageName: "profile",
              ),
            ),
          ),
        ],
      ),
      // Footer Navigation Bar
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

  void _handleLogout() async {
    try {
      // ไม่ต้องสร้าง AuthService ใหม่ ใช้ instance ที่มีอยู่
      // final AuthService authService = AuthService(navigatorKey: navigatorKey);
      String? token = await authService.getToken();

      // เรียก API logout
      if (token != null) {
        await http.post(
          Uri.parse(ApiConfig.logoutUrl),
          headers: {'Authorization': 'Bearer $token'},
        );
      }

      // ลบ token ทั้งหมด
      await authService.removeToken();
      await authService.removeFCMToken();

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const Login()),
          (route) => false,
        );
      }
    } catch (e) {
      print('Error during logout: $e');
    }
  }
}
