import 'dart:convert';
import 'dart:typed_data';
import 'package:edugo/features/scholarship/models/category.dart';
import 'package:edugo/features/scholarship/models/country.dart';
import 'package:edugo/features/scholarship/models/provider_add_model.dart';
import 'package:edugo/features/scholarship/services/api_endpoint.dart';
import 'package:http/http.dart' as http;

class ApiService {
  Future<List<Country>> fetchCountries() async {
    final response = await http.get(Uri.parse(ApiEndpoints.fetchCountries));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Country.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch countries');
    }
  }

  Future<List<Category>> fetchCategories() async {
    final response = await http.get(Uri.parse(ApiEndpoints.fetchCategories));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Category.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch categories');
    }
  }

  Future<void> addAnnounce(Announce announce,
      {Uint8List? image, Uint8List? file}) async {
    var request =
        http.MultipartRequest('POST', Uri.parse(ApiEndpoints.addAnnounce));

    request.fields.addAll(
        announce.toJson().map((key, value) => MapEntry(key, value.toString())));

    if (image != null) {
      request.files.add(
        http.MultipartFile.fromBytes('image', image, filename: 'image.jpg'),
      );
    }

    if (file != null) {
      request.files.add(
        http.MultipartFile.fromBytes('attach_file', file, filename: 'file.pdf'),
      );
    }

    if (announce.url == null || announce.url == '') {
      request.fields.remove('url');
    }

    if (announce.image == null || announce.image == '') {
      request.fields.remove('image');
    }

    if (announce.attachFile == null || announce.attachFile == '') {
      request.fields.remove('attach_file');
    }

    print(request.fields);

    var response = await request.send();
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to add announce');
    }
  }

  Future<void> updateAnnounce(Announce announce,
      {Uint8List? image, Uint8List? file}) async {
    var request = http.MultipartRequest(
        'PUT', Uri.parse(ApiEndpoints.updateAnnounce(announce.id.toString()!)));

    request.fields.addAll(
        announce.toJson().map((key, value) => MapEntry(key, value.toString())));

    if (image != null) {
      request.files.add(
        http.MultipartFile.fromBytes('image', image, filename: 'image.jpg'),
      );
    }

    if (file != null) {
      request.files.add(
        http.MultipartFile.fromBytes('attach_file', file, filename: 'file.pdf'),
      );
    }

    var response = await request.send();
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to update announce');
    }
  }
}
