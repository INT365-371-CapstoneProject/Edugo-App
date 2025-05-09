import 'package:edugo/shared/utils/endpoint.dart';
import 'package:http/http.dart' as http;
import 'package:edugo/services/auth_service.dart';
import 'dart:convert';

class BookmarkService {
  final AuthService _authService = AuthService();

  String apiBaseUrl = Endpoints.baseUrl;

  Future<List<dynamic>> fetchBookmarks(int userId) async {
    final String? token = await _authService.getToken();
    final String url = "${Endpoints.getBookmarkByAccountID}/$userId";

    final headers = {
      if (token != null) 'Authorization': 'Bearer $token',
    };

    final response = await http.get(Uri.parse(url), headers: headers);

    if (response.statusCode == 200) {
      return json.decode(response.body) as List<dynamic>;
    } else {
      throw Exception(
          "Failed to load bookmarks (Status Code: ${response.statusCode})");
    }
  }

  Future<Map<String, dynamic>> fetchAnnounceDetails(
      List<int> announceIds) async {
    String? token = await _authService.getToken();
    final url = "$apiBaseUrl/announce-user/bookmark";

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Authorization': token != null ? 'Bearer $token' : '',
        'Content-Type': 'application/json',
      },
      body: json.encode({"announce_id": announceIds}),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception("Failed to load announcement details");
    }
  }

  Future<void> deleteBookmark(int id) async {
    String? token = await _authService.getToken();
    final url = "$apiBaseUrl/bookmark/ann/$id";

    final response = await http.delete(Uri.parse(url), headers: {
      'Authorization': token != null ? 'Bearer $token' : '',
      'Content-Type': 'application/json',
    });

    if (response.statusCode != 200) {
      fetchBookmarks(id);
      throw Exception("Failed to delete bookmark");
    }
  }
}
