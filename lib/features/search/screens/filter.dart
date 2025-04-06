import 'package:edugo/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class FilterDrawer extends StatefulWidget {
  @override
  _FilterDrawerState createState() => _FilterDrawerState();
}

class _FilterDrawerState extends State<FilterDrawer> {
  List<String> scholarshipTypes = [];
  final List<String> educationLevels = ["Undergraduate", "Master", "Doctorate"];
  final Set<String> selectedScholarshipTypes = {};
  final Set<String> selectedEducationLevels = {};
  final AuthService authService = AuthService();

  @override
  void initState() {
    super.initState();
    fetchScholarshipCategories();
    loadFilters();
  }

  Future<void> saveFilters() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        'selectedScholarshipTypes', selectedScholarshipTypes.toList());
    await prefs.setStringList(
        'selectedEducationLevels', selectedEducationLevels.toList());
  }

  Future<void> loadFilters() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      selectedScholarshipTypes
          .addAll(prefs.getStringList('selectedScholarshipTypes') ?? []);
      selectedEducationLevels
          .addAll(prefs.getStringList('selectedEducationLevels') ?? []);
    });
  }

  Future<void> fetchScholarshipCategories() async {
    String url = "https://capstone24.sit.kmutt.ac.th/un2/api/category";

    String? token = await authService.getToken();
    Map<String, String> headers = {};

    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    try {
      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          scholarshipTypes =
              data.map<String>((item) => item['category_name']).toList();
        });
      } else {
        throw Exception('Failed to load scholarship categories');
      }
    } catch (e) {
      print("Error loading categories: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "Search Details",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          Divider(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text("Type of Scholarship",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Wrap(
              spacing: 8,
              children: scholarshipTypes
                  .map((type) => FilterChip(
                        label: Text(type),
                        selected: selectedScholarshipTypes.contains(type),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              selectedScholarshipTypes.add(type);
                            } else {
                              selectedScholarshipTypes.remove(type);
                            }
                            saveFilters(); // บันทึกค่าหลังจากอัปเดต
                          });
                        },
                      ))
                  .toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text("Educational Level",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Wrap(
              spacing: 8,
              children: educationLevels
                  .map((level) => FilterChip(
                        label: Text(level),
                        selected: selectedEducationLevels.contains(level),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              selectedEducationLevels.add(level);
                            } else {
                              selectedEducationLevels.remove(level);
                            }
                            saveFilters(); // บันทึกค่าหลังจากอัปเดต
                          });
                        },
                      ))
                  .toList(),
            ),
          ),
          Spacer(),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Cancel"),
                ),
              ),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    saveFilters();
                    Navigator.pop(context, {
                      'scholarshipTypes': selectedScholarshipTypes.toSet(),
                      'educationLevels': selectedEducationLevels.toSet(),
                    });
                  },
                  child: Text("Seach"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Future<Map<String, Set<String>>?> openFilterDrawer(BuildContext context) async {
  return await showDialog<Map<String, Set<String>>>(
    context: context,
    builder: (context) {
      return Align(
        alignment: Alignment.centerRight, // ชิดขวา
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.85, // กำหนดความกว้าง
            height: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(blurRadius: 5, color: Colors.black26)],
            ),
            child: FilterDrawer(),
          ),
        ),
      );
    },
  );
}
