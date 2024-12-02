import 'package:edugo/pages/provider_management.dart';
import 'package:edugo/pages/subject_add_edit.dart';
import 'package:edugo/pages/subject_manage.dart';
import 'package:edugo/services/footer.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ProviderProfile extends StatefulWidget {
  const ProviderProfile({super.key});

  @override
  State<ProviderProfile> createState() => _ProviderProfileState();
}

final double coverHeight = 152;
final double profileHeight = 90;

class _ProviderProfileState extends State<ProviderProfile> {
  final top = coverHeight - profileHeight / 2;
  final bottom = profileHeight / 2;
  final arrow = const Icon(Icons.arrow_forward_ios, size: 15);

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
                              child: Image.asset(
                                'assets/images/avatar_x3.png',
                                width: profileHeight,
                                height: profileHeight,
                                fit: BoxFit.cover, // Fill the container
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
                    "Alex Froster",
                    style: GoogleFonts.dmSans(
                        fontSize: 20, fontWeight: FontWeight.w500),
                  ),
                ),
                SizedBox(height: 16),
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
                          "assets/images/scholarship_management.png",
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildProfileOption(
                    icon: Icons.person,
                    label: "Edit Profile",
                    onTap: () {
                      // Perform action
                    }),
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
                      // Perform action
                    }),
                _buildProfileOption(
                    icon: Icons.notifications,
                    label: "Notification",
                    onTap: () {
                      // Perform action
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
                      // เพิ่มการทำงานเมื่อกด
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
