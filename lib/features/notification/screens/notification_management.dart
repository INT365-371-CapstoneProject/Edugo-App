import 'package:edugo/config/api_config.dart';
import 'package:edugo/features/profile/screens/profile.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:edugo/services/auth_service.dart';

class NotificationList extends StatefulWidget {
  final int id; // รับค่า id ของ user

  const NotificationList({super.key, required this.id});

  @override
  State<NotificationList> createState() => _NotificationListState();
}

class _NotificationListState extends State<NotificationList> {
  final AuthService authService = AuthService();
  List<dynamic> notifications = []; // เก็บข้อมูลแจ้งเตือน
  bool isFetching = false; // ป้องกันโหลดซ้ำ

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    fetchNotifications(); // โหลดข้อมูล
  }

  Future<void> fetchNotifications() async {
    if (isFetching) return; // ถ้ากำลังโหลดอยู่ ไม่ต้องโหลดซ้ำ
    setState(() => isFetching = true);

    String? token = await authService.getToken();
    Map<String, String> headers = {};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    final url = "${ApiConfig.notificationUrl}/acc/${widget.id}";

    try {
      final response = await http.get(Uri.parse(url), headers: headers);
      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);
        setState(() {
          notifications = responseData;
        });
      } else {
        throw Exception('Failed to load notifications');
      }
    } catch (e) {
      print("Error fetching notifications: $e");
    } finally {
      setState(() => isFetching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Header
          Container(
            color: const Color(0xFF355FFF),
            padding: const EdgeInsets.only(
              top: 72.0,
              right: 16,
              left: 16,
              bottom: 22,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.center,
                  child: Text(
                    "Your Notifications",
                    style: GoogleFonts.dmSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFFFFFFFF),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      // Navigator.pushReplacement(
                      //   context,
                      //   PageRouteBuilder(
                      //     pageBuilder:
                      //         (context, animation, secondaryAnimation) =>
                      //             const ProviderProfile(),
                      //     transitionsBuilder:
                      //         (context, animation, secondaryAnimation, child) {
                      //       const begin = 0.0;
                      //       const end = 1.0;
                      //       const curve = Curves.easeOut;
                      //       var tween = Tween(begin: begin, end: end)
                      //           .chain(CurveTween(curve: curve));
                      //       return FadeTransition(
                      //           opacity: animation.drive(tween), child: child);
                      //     },
                      //     transitionDuration: const Duration(milliseconds: 300),
                      //   ),
                      // );
                    },
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: const Color(0xFFF9C7E1),
                      child: SvgPicture.asset(
                        'assets/images/X.svg',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // แสดงผลรายการแจ้งเตือน
          Expanded(
            child: isFetching
                ? const Center(child: CircularProgressIndicator())
                : notifications.isEmpty
                    ? const Center(child: Text("No notifications available"))
                    : ListView.builder(
                        itemCount: notifications.length,
                        itemBuilder: (context, index) {
                          final item = notifications[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ListTile(
                              title: Text(
                                item['title'] ?? 'No Title',
                                style: GoogleFonts.dmSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                item['message'] ?? '',
                                style: GoogleFonts.dmSans(fontSize: 14),
                              ),
                              trailing: item['is_read'] == 0
                                  ? const Icon(Icons.circle,
                                      color: Colors.red, size: 12)
                                  : null,
                              onTap: () {
                                print("Tapped on: ${item['title']}");
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
