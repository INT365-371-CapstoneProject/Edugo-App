import 'package:edugo/config/api_config.dart';
import 'package:edugo/features/profile/screens/profile.dart';
import 'package:edugo/features/scholarship/screens/provider_detail.dart';
import 'package:edugo/shared/utils/textStyle.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:edugo/services/auth_service.dart';
import 'package:edugo/main.dart'; // Import main.dart เพื่อเข้าถึง navigatorKey

class NotificationList extends StatefulWidget {
  final int id; // รับค่า id ของ user

  const NotificationList({super.key, required this.id});

  @override
  State<NotificationList> createState() => _NotificationListState();
}

class _NotificationListState extends State<NotificationList> {
  final AuthService authService =
      AuthService(navigatorKey: navigatorKey); // Instance of AuthService
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

  Future<void> updateNotification(int id) async {
    String? token = await authService.getToken();
    Map<String, String> headers = {};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    final url = "${ApiConfig.notificationUrl}/$id";

    try {
      final response = await http.put(Uri.parse(url), headers: headers);
      if (response.statusCode == 200) {
        response;
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
              top: 58.0,
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
                      // Navigator.push(
                      //   context,
                      //   PageRouteBuilder(
                      //     pageBuilder:
                      //         (context, animation, secondaryAnimation) =>
                      //             const PersonalProfile(),
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
                            margin: EdgeInsets.zero, // เปลี่ยน margin เป็น zero
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Container(
                              height: 113,
                              color: item['is_read'] == 0
                                  ? Color(0xFFFFFFFF)
                                  : Color.fromARGB(255, 220, 240, 255),
                              child: Align(
                                alignment: Alignment.center,
                                child: ListTile(
                                  leading: CircleAvatar(
                                    radius: 30,
                                    child: ClipOval(
                                      child: Icon(
                                        Icons.notifications,
                                        color: Colors.red,
                                        size:
                                            30, // optional: adjust size as needed
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    item['title'] ?? 'No Title',
                                    style: TextStyleService.getDmSans(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF222222)),
                                    maxLines: 1,
                                  ),
                                  subtitle: Text(
                                    item['message'] ?? '',
                                    style: TextStyleService.getDmSans(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w400,
                                        color: Color(0xFF444444)),
                                    maxLines: 2,
                                  ),
                                  trailing: item['is_read'] == 0
                                      ? null
                                      : const Icon(Icons.circle,
                                          color: Color(0xFF355FFF), size: 12),
                                  onTap: () async {
                                    await updateNotification(
                                        item['id']); // รอให้อัปเดตเสร็จ

                                    final existingData = {
                                      'id': item['announce_id'],
                                    };

                                    final result = await Navigator.push(
                                      context,
                                      PageRouteBuilder(
                                        pageBuilder: (context, animation,
                                                secondaryAnimation) =>
                                            ProviderDetail(
                                          isProvider: false,
                                          initialData: existingData,
                                        ),
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
                                              child: child);
                                        },
                                        transitionDuration:
                                            const Duration(milliseconds: 300),
                                      ),
                                    );

                                    if (result == 'refresh') {
                                      fetchNotifications(); // รีเฟรชหลังกลับมา
                                    }
                                  },
                                ),
                              ),
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
