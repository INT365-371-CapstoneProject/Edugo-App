import 'package:edugo/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';

class ScholarshipCard extends StatelessWidget {
  final String tag;
  final String image;
  final String title;
  final String date;
  final String status;
  final String description;

  ScholarshipCard({
    super.key,
    required this.tag,
    required this.image,
    required this.title,
    required this.date,
    required this.status,
    required this.description,
  });

  final Map<String, Uint8List?> _imageCache = {};

  Future<Uint8List?> fetchImage(String url) async {
    if (_imageCache.containsKey(url)) {
      return _imageCache[url];
    }

    try {
      final AuthService authService = AuthService();
      String? token = await authService.getToken();

      Map<String, String> headers = {};
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        return response.bodyBytes; // โหลดรูปสำเร็จ
      } else {
        debugPrint("Failed to load image: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error fetching image: $e");
    }
    return null; // โหลดรูปไม่ได้ ให้ใช้ภาพเริ่มต้นแทน
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 359,
      height: 171,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.withOpacity(0.3)),
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12.0),
                child: _imageCache.containsKey(image)
                    ? (_imageCache[image] != null
                        ? Image.memory(
                            _imageCache[image]!,
                            width: 144,
                            height: 160,
                            fit: BoxFit.cover,
                          )
                        : Image.asset(
                            "assets/images/scholarship_program.png",
                            width: 144,
                            height: 160,
                            fit: BoxFit.cover,
                          ))
                    : FutureBuilder<Uint8List?>(
                        future: fetchImage(image),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const SizedBox(
                              width: 101,
                              height: 143,
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }
                          if (snapshot.data == null) {
                            return Image.asset(
                              "assets/images/scholarship_program.png",
                              width: 101,
                              height: 143,
                              fit: BoxFit.cover,
                            );
                          }
                          return Image.memory(
                            snapshot.data!,
                            width: 101,
                            height: 143,
                            fit: BoxFit.cover,
                          );
                        },
                      ),
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (tag.isNotEmpty)
                        Text(
                          tag,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF94A2B8),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      if (status.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: status == 'Pending'
                                ? const Color(0xFFECF0F6)
                                : status == "Closed"
                                    ? const Color(0xFFF9C7E1)
                                    : Colors.green[100],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: status == 'Pending'
                                  ? const Color(0xFF94A2B8)
                                  : status == "Closed"
                                      ? const Color(0xFFED4B9E)
                                      : Colors.green,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF000000),
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF2A4CCC),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF94A2B8),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
