import 'package:edugo/config/api_config.dart';
import 'package:edugo/features/scholarship/models/provider_add_model.dart';
import 'package:edugo/features/scholarship/screens/provider_detail.dart';
import 'package:edugo/features/scholarship/screens/provider_management.dart';
import 'package:edugo/features/scholarship/services/provider_add_service.dart';
import 'package:edugo/services/auth_service.dart';
import 'package:edugo/services/datetime_provider_add.dart';
import 'package:edugo/services/dropdown_provider_add.dart';
import 'package:edugo/services/file_upload.dart';
import 'package:edugo/services/top_provider_add.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'package:http_parser/http_parser.dart';

class ProviderAddEdit extends StatefulWidget {
  final bool isEdit;
  final Map<String, dynamic>? initialData;

  const ProviderAddEdit({
    Key? key,
    required this.isEdit,
    this.initialData,
  }) : super(key: key);

  @override
  State<ProviderAddEdit> createState() => _ProviderAddEditState();
}

class _ProviderAddEditState extends State<ProviderAddEdit> {
  // ตัวแปรเก็บค่าจากฟอร์ม
  int? id;
  String? title; // สำหรับ Scholarship Name
  String? description; // สำหรับ Description
  String? url; // สำหรับ Web URL
  Uint8List? cancalImage;
  String? selectedScholarshipType; // สำหรับ Scholarship Type
  String? selectedCountry;
  String? selectedCountryId; // ตัวแปรเก็บ country_id
  String? selectedCategory;
  String? selectedCategoryId;
  String? selectedEducationLevel; // สำหรับ Education Level
  String? selectedEducationLevelId;
  DateTime? selectedStartDate;
  DateTime? selectedEndDate;
  Uint8List? _imageBytes; // Holds the selected image data
  Uint8List? _pdfFileBytes;
  String? pdfFileName;
  String? selectedFileName; // เก็บชื่อไฟล์ที่เลือก
  bool isLoading = false;
  bool isSuccessful = false;
  Color dropdownBorderColor = Color(0xFFCBD5E0);
  String? titleError;
  Color titleBorderColor = Color(0xFFCBD5E0);
  bool isValidTitle = false;
  String? categoryError;
  bool isValidCategory = false;
  String? countryError;
  bool isValidCountry = false;
  String? educationLevelError;
  bool isValidEducationLevel = false;
  bool isValidDescription = false;
  String? descriptionError;
  Color descriptionBorderColor = Color(0xFFCBD5E0);
  String? dateTimeError;
  bool isValidDateTime = false;
  Color dateTimeBorder = Color(0xFFCBD5E0);
  Color uploadFileBorder = Color(0xFFCBD5E0);
  String? urlError;
  bool isValidUrl = false;
  Color urlBorderColor = const Color(0xFFCBD5E0);
  final ApiService apiService = ApiService(); // สร้าง Instance ของ ApiService
  final AuthService authService = AuthService(); // Instance of AuthService

  // สร้าง controller สำหรับ TextField
  TextEditingController titleController = TextEditingController();
  TextEditingController urlController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();

  List<Map<String, dynamic>> countryList = []; // Store country data here
  List<Map<String, dynamic>> categoryList = []; // Store country data here
  List<Map<String, dynamic>> educationLevelList = [
    {"id": 1, "education_name": "Undergraduate"},
    {"id": 2, "education_name": "Master"},
    {"id": 3, "education_name": "Doctorate"},
  ];

  Map<String, dynamic> originalValues = {};

  static const urlPattern =
      r'^(https?:\/\/)' // ต้องเริ่มต้นด้วย http:// หรือ https://
      r'(([a-zA-Z\d]([a-zA-Z\d-]*[a-zA-Z\d])*)\.)+[a-zA-Z]{2,}' // โดเมน
      r'(:\d+)?(\/[-a-zA-Z\d%_.~+]*)*' // พาธ
      r'(\?[;&a-zA-Z\d%_.~+=-]*)?' // คิวรีสตริง
      r'(#[-a-zA-Z\d_]*)?$'; // แฟรกเมนต์

  void validateUrl(String value) {
    final urlRegExp = RegExp(urlPattern);

    setState(() {
      if (value.isEmpty) {
        urlError = null; // ไม่แสดงข้อความข้อผิดพลาดหากฟิลด์ว่าง
        isValidUrl = true; // ถือว่าฟอร์มนี้ผ่าน
        urlBorderColor = const Color(0xFFCBD5E0);
        url = value;
      } else if (!urlRegExp.hasMatch(value)) {
        urlError = "Please enter a valid URL (e.g., https://example.com)";
        isValidUrl = false;
        urlBorderColor = Colors.red;
      } else {
        urlError = null;
        isValidUrl = true;
        urlBorderColor = const Color(0xFFCBD5E0);
        url = value;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    fetchCountryData();
    fetchCategoryData();

    print(widget.initialData);

    if (widget.isEdit && widget.initialData != null) {
      final data = widget.initialData!;
      id = data['id'] ?? '';
      title = data['title'] ?? '';
      description = data['description'] ?? '';
      url = data['url'];
      selectedCountry = data['country'] ?? '';
      selectedCategory = data['category'] ?? '';
      selectedStartDate = data['published_date'] != null
          ? DateTime.tryParse(data['published_date'])
          : null;
      selectedEndDate = data['close_date'] != null
          ? DateTime.tryParse(data['close_date'])
          : null;
      cancalImage = data['image'] ?? '';
      _imageBytes = data['image'] ?? '';
      selectedFileName = data['attach_file'];

      selectedEducationLevel = data['education_level'];
      titleController.text = title ?? '';
      urlController.text = url ?? '';
      descriptionController.text = description ?? '';

      originalValues = {
        'title': title,
        'description': description,
        'url': url,
        'country': selectedCountry,
        'category': selectedCategory,
        'publish_date': selectedStartDate?.toIso8601String(),
        'close_date': selectedEndDate?.toIso8601String(),
        'image': cancalImage,
        'attach_file': selectedFileName,
        'education_level': selectedEducationLevel,
      };
    } else {
      // กำหนดค่าเริ่มต้นหากไม่ได้อยู่ในโหมดแก้ไข
      title = '';
      description = '';
      url = '';
      selectedCountry = null;
      selectedCategory = null;
      selectedStartDate = null;
      selectedEndDate = null;
      titleController.text = '';
      urlController.text = '';
      descriptionController.text = '';
      selectedFileName = '';
    }
  }

  Future<void> fetchCountryData() async {
    String? token = await authService.getToken();
    Map<String, String> headers = {}; // Explicitly type the map
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    try {
      var response =
          await http.get(Uri.parse(ApiConfig.countryUrl), headers: headers);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          countryList = List<Map<String, dynamic>>.from(data);
        });
      }
    } catch (e) {
      showError("Failed to load country data");
    }
  }

  Future<void> fetchCategoryData() async {
    String? token = await authService.getToken();
    Map<String, String> headers = {}; // Explicitly type the map
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    try {
      var response =
          await http.get(Uri.parse(ApiConfig.categoryUrl), headers: headers);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          categoryList = List<Map<String, dynamic>>.from(data);
        });
      }
    } catch (e) {
      showError("Failed to load category data");
    }
  }

  // void handleCountrySelection(String? countryId) {
  //   setState(() {
  //     selectedCountry = countryId; // Store the selected country ID
  //   });
  // }

  // void handleCategorySelection(String? categoryId) {
  //   setState(() {
  //     selectedCategory = categoryId; // Store the selected country ID
  //   });
  // }

  // void handleEducationLevelSelection(String? educationId) {
  //   setState(() {
  //     selectedEducationLevel = educationId; // Store the selected country ID
  //   });
  // }

  void _onImagePicked(Uint8List? image) {
    if (image != null) {
      // ตรวจสอบประเภทของรูป เช่น JPEG หรือ PNG
      if (!_isValidImage(image)) {
        showError("Invalid image type. Please upload a JPEG or PNG file.");
        return;
      }
      // ตรวจสอบขนาดไฟล์ เช่น ต้องไม่เกิน 5MB
      if (image.length > 5 * 1024 * 1024) {
        showError(
            "Image is too large. Please upload an image smaller than 5MB.");
        return;
      }
    }
    setState(() {
      _imageBytes = image;
    });
  }

// ฟังก์ชันสำหรับตรวจสอบประเภทของรูป
  bool _isValidImage(Uint8List imageBytes) {
    // ตรวจสอบ MIME type ของรูป
    final header =
        imageBytes.sublist(0, 4); // ใช้ bytes แรกเพื่อตรวจสอบประเภทไฟล์
    if (header[0] == 0xFF && header[1] == 0xD8 && header[2] == 0xFF) {
      return true; // JPEG
    } else if (header[0] == 0x89 &&
        header[1] == 0x50 &&
        header[2] == 0x4E &&
        header[3] == 0x47) {
      return true; // PNG
    }
    return false;
  }

  _attachPdfFile(Uint8List? fileBytes, String? filename) {
    setState(() {
      _pdfFileBytes = fileBytes;
      pdfFileName = filename; // เก็บชื่อไฟล์ที่ถูกเลือก
    });
  }

  void updateStartDateTime(DateTime? dateTime) {
    setState(() {
      selectedStartDate = dateTime;
    });
  }

  void updateEndDateTime(DateTime? dateTime) {
    setState(() {
      selectedEndDate = dateTime;
    });
  }

  Future<void> submitAddData() async {
    String? token = await authService.getToken();
    Map<String, String> headers = {}; // Explicitly type the map
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    var request =
        http.MultipartRequest('POST', Uri.parse(ApiConfig.announceUrl));
    request.headers.addAll(headers);

    request.fields['title'] = title ?? '';
    request.fields['description'] = description ?? '';
    request.fields['posts_type'] = 'Announce';
    request.fields['publish_date'] =
        '${selectedStartDate?.toIso8601String().split('.')[0]}Z';
    request.fields['close_date'] =
        '${selectedEndDate?.toIso8601String().split('.')[0]}Z';
    request.fields['category_id'] = selectedCategoryId!;
    request.fields['country_id'] = selectedCountryId!;
    request.fields['education_level'] = selectedEducationLevel!;

    if (_imageBytes != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          _imageBytes!,
          filename: 'image.jpg',
          contentType: MediaType('image', 'jpeg'),
        ),
      );
    }

    if (_pdfFileBytes != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'attach_file',
          _pdfFileBytes!,
          filename: pdfFileName!,
          contentType: MediaType('application', 'pdf'),
        ),
      );
    }

    if (url != null && url != '') {
      request.fields['url'] = url.toString();
    }

    showDialog(
      context: context,
      barrierDismissible: false, // ไม่ให้ปิด Dialog โดยการคลิกนอกพื้นที่
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: SizedBox(
            height: 301, // กำหนดความสูงของ Dialog
            width: 298,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        height: 100,
                        width: 100,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                              const Color.fromARGB(249, 84, 83, 83)),
                          strokeWidth: 18.0, // ความหนาของเส้น
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 40),
                  Text(
                    "Waiting for Posting",
                    style: GoogleFonts.dmSans(
                        fontSize: 24, // ปรับขนาดฟอนต์ที่นี่
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF000000)),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    try {
      // เพิ่มการหน่วงเวลา 3 วินาที
      await Future.delayed(Duration(seconds: 1));

      var response = await request.send();

      Navigator.of(context).pop(); // ปิด Loading Dialog

      if (response.statusCode == 200 || response.statusCode == 201) {
        showSuccessDialog(context, false);
      } else {
        showError("Failed to submit data. Status code: ${response.statusCode}");
      }
    } catch (e) {
      Navigator.of(context).pop(); // ปิด Loading Dialog
      showError("Error occurred: $e");
    }
  }

  Future<void> submitEditData() async {
    String? token = await authService.getToken();
    Map<String, String> headers = {}; // Explicitly type the map
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    final String apiUrl = "${ApiConfig.announceUrl}/$id";

    var request = http.MultipartRequest('PUT', Uri.parse(apiUrl));
    request.headers.addAll(headers);

    Map<String, String> updatedFields = {};
    Map<String, int> updatedFieldsInt = {};

    if (title != originalValues['title']) updatedFields['title'] = title ?? '';
    if (description != originalValues['description']) {
      updatedFields['description'] = description ?? '';
    }
    if (url != originalValues['url'] && url != null && url!.isNotEmpty)
      updatedFields['url'] = url!;

    var selectedCountryObj = countryList.firstWhere(
        (country) => country['country_name'].toString() == selectedCountry);
    updatedFieldsInt['country_id'] = selectedCountryObj['id'];

    var selectedCategoryObj = categoryList.firstWhere(
        (country) => country['category_name'].toString() == selectedCategory);
    updatedFieldsInt['category_id'] = selectedCategoryObj['id'];

    if (selectedEducationLevel != originalValues['education_level']) {
      updatedFields['education_level'] = selectedEducationLevel!;
    }
    if (selectedStartDate?.toIso8601String() !=
        originalValues['publish_date']) {
      updatedFields['publish_date'] =
          '${selectedStartDate?.toIso8601String().split('.')[0]}Z';
    }
    if (selectedEndDate?.toIso8601String() != originalValues['close_date']) {
      updatedFields['close_date'] =
          '${selectedEndDate?.toIso8601String().split('.')[0]}Z';
    }

    // เพิ่มไฟล์ถ้ามีการเปลี่ยนแปลง
    if (_imageBytes != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          _imageBytes!,
          filename: 'image.jpg',
          contentType: MediaType('image', 'jpeg'),
        ),
      );
    }

    if (_pdfFileBytes != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'attach_file',
          _pdfFileBytes!,
          filename: pdfFileName!,
          contentType: MediaType('application', 'pdf'),
        ),
      );
    }

    // เพิ่มเฉพาะฟิลด์ที่เปลี่ยนแปลง
    request.fields.addAll(updatedFields);
    updatedFieldsInt.forEach((key, value) {
      request.fields[key] = value.toString();
    });

    // Print ค่าทั้งหมดที่จะส่งไป
    print('=== Request Details ===');
    print('URL: ${request.url}');
    print('Headers: ${request.headers}');
    print('Fields: ${request.fields}');
    print(
        'Files: ${request.files.map((f) => 'Filename: ${f.filename}, Length: ${f.length} bytes')}');
    print('Updated Fields: $updatedFields');
    print('Original Values: $originalValues');
    print('Current Values:');
    print('  Title: $title');
    print('  Description: $description');
    print('  URL: $url');
    print('  Country: $selectedCountry');
    print('  Category: $selectedCategory');
    print('  Education Level: $selectedEducationLevel');
    print('  Start Date: $selectedStartDate');
    print('  End Date: $selectedEndDate');
    print('====================');

    // แสดง Loading Dialog
    showDialog(
      context: context,
      barrierDismissible: false, // ไม่ให้ปิด Dialog โดยการคลิกนอกพื้นที่
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: SizedBox(
            height: 301, // กำหนดความสูงของ Dialog
            width: 298,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        height: 100,
                        width: 100,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                              const Color.fromARGB(249, 84, 83, 83)),
                          strokeWidth: 18.0, // ความหนาของเส้น
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 40),
                  Text(
                    "Waiting for Updating",
                    style: GoogleFonts.dmSans(
                        fontSize: 24, // ปรับขนาดฟอนต์ที่นี่
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF000000)),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    try {
      // เพิ่มการหน่วงเวลา 3 วินาที
      await Future.delayed(Duration(seconds: 3));

      var response = await request.send();

      Navigator.of(context).pop(); // ปิด Loading Dialog

      if (response.statusCode == 200 || response.statusCode == 201) {
        showSuccessDialog(context, true);
      } else {
        showError("Failed to submit data. Status code: ${response.statusCode}");
      }
    } catch (e) {
      Navigator.of(context).pop(); // ปิด Loading Dialog
      showError("Error occurred: $e");
    }
  }

// Helper to show success messages
  void showSuccessDialog(BuildContext context, bool isEdit) {
    showDialog(
      context: context,
      barrierDismissible: false, // ไม่ให้ปิดโดยการแตะด้านนอก
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: SizedBox(
            height: 370, // กำหนดความสูงของ Dialog
            width: 298,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/images/success.png',
                    height: 190,
                    width: 220, // ปรับขนาดรูปที่นี่
                  ),
                  const SizedBox(height: 20),
                  Text(
                    isEdit ? "Update Successful" : "Post Successful!",
                    style: GoogleFonts.dmSans(
                      fontSize: 24, // ปรับขนาดฟอนต์ที่นี่
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProviderManagement(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF355FFF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      "Back to Home",
                      style: TextStyle(
                        color: Colors.white, // กำหนดสีข้อความเป็นสีขาว
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Helper to show error messages
  void showError(String message) {
    // Replace with your preferred error handling method
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

// Helper to show success messages
  void showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFFFFF),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: <Widget>[
                HeaderProviderAdd(
                    isEdit: widget.isEdit,
                    onImagePicked: _onImagePicked,
                    initialImage: _imageBytes),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Scholarship Name*',
                        style: GoogleFonts.dmSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          fontStyle: FontStyle.normal,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 50,
                        width: double.infinity,
                        child: TextField(
                          controller: titleController,
                          onChanged: (value) {
                            setState(() {
                              title = value;
                              if (value.replaceAll(RegExp(r'\s+'), '').length <
                                      5 ||
                                  value.replaceAll(RegExp(r'\s+'), '').length >
                                      100) {
                                titleBorderColor = Colors.red;
                                titleError =
                                    "Minimum 5 characters, maximum 100 characters";
                                isValidTitle = false;
                              } else {
                                titleBorderColor = Color(0xFFCBD5E0);
                                titleError = null;
                                isValidTitle = true; // ฟอร์มถูกต้อง
                              }
                            });
                          },
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6.0),
                              borderSide: BorderSide(
                                color: titleBorderColor,
                                width: 1.0,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6.0),
                              borderSide: BorderSide(
                                color: titleBorderColor,
                                width: 1.0,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6.0),
                              borderSide: BorderSide(
                                color: titleBorderColor,
                                width: 2.0,
                              ),
                            ),
                            hintText: 'Fill scholarship name (required)',
                            hintStyle: GoogleFonts.dmSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              fontStyle: FontStyle.normal,
                              color: Color(0xFFCBD5E0),
                            ),
                          ),
                        ),
                      ),
                      if (titleError != null) // แสดงข้อความข้อผิดพลาด
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            titleError!,
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      Text(
                        'Website (url)',
                        style: GoogleFonts.dmSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          fontStyle: FontStyle.normal,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 50, // กำหนดความสูงที่แน่นอน
                        width:
                            double.infinity, // ขยายเต็มความกว้างของ Container
                        child: TextField(
                          controller: urlController,
                          onChanged: (value) => validateUrl(value),
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(6.0), // มุมโค้ง 6
                              borderSide: BorderSide(
                                color: urlBorderColor, // สีขอบ
                                width: 1.0,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(6.0), // มุมโค้ง 6
                              borderSide: BorderSide(
                                color: urlBorderColor, // สีขอบเมื่อไม่ได้โฟกัส
                                width: 1.0,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(6.0), // มุมโค้ง 6
                              borderSide: BorderSide(
                                color: urlBorderColor, // สีขอบเมื่อโฟกัส
                                width: 1.0,
                              ),
                            ),
                            hintText: 'Fill your website’s company',
                            hintStyle: GoogleFonts.dmSans(
                              fontSize: 14, // กำหนดขนาดฟอนต์
                              fontWeight: FontWeight.w400, // น้ำหนักฟอนต์ 400
                              fontStyle: FontStyle.normal, // สไตล์ปกติ
                              color: Color(0xFFCBD5E0), // สีข้อความ
                            ),
                          ),
                        ),
                      ),
                      if (urlError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            urlError!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      Text(
                        'Type of Scholarship*',
                        style: GoogleFonts.dmSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      CustomDropdownExample(
                        items: categoryList,
                        type: 'category',
                        validColor: dropdownBorderColor,
                        initialValue:
                            selectedCategory ?? "Select type of scholarship",
                        onSelected: (String? value) {
                          if (value != null) {
                            // Find the category object from categoryList using the ID
                            var selectedCategoryObj = categoryList.firstWhere(
                              (category) => category['id'].toString() == value,
                              orElse: () => {},
                            );

                            setState(() {
                              selectedCategoryId = value; // Store the ID
                              selectedCategory = selectedCategoryObj[
                                  'category_name']; // Store the display name
                              if (value != null) {
                                categoryError = null;
                                isValidCategory = true;
                              }
                            });
                          }
                        },
                        hintStyle: GoogleFonts.dmSans(
                          fontSize: 14,
                          color: const Color(0xFFCBD5E0),
                        ),
                      ),
                      if (categoryError != null) // แสดงข้อความข้อผิดพลาด
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            categoryError!,
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      Text(
                        'Educational Level*',
                        style: GoogleFonts.dmSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      CustomDropdownExample(
                        items: educationLevelList,
                        type: 'education level',
                        validColor: dropdownBorderColor,
                        initialValue: selectedEducationLevel ??
                            "Select education level of scholarship",
                        onSelected: (String? value) {
                          if (value != null) {
                            // Find the education level object
                            var selectedEducationObj =
                                educationLevelList.firstWhere(
                              (education) =>
                                  education['id'].toString() == value,
                              orElse: () => {},
                            );

                            setState(() {
                              selectedEducationLevelId = value; // Store the ID
                              selectedEducationLevel = selectedEducationObj[
                                  'education_name']; // Store the display name
                              educationLevelError = null;
                              isValidEducationLevel = true;
                            });
                          }
                        },
                        hintStyle: GoogleFonts.dmSans(
                          fontSize: 14,
                          color: const Color(0xFFCBD5E0),
                        ),
                      ),
                      if (educationLevelError != null) // แสดงข้อความข้อผิดพลาด
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            educationLevelError!,
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      Text(
                        'Country*',
                        style: GoogleFonts.dmSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      CustomDropdownExample(
                        items: countryList,
                        type: 'country',
                        validColor: dropdownBorderColor,
                        initialValue:
                            selectedCountry ?? "Select country of scholarship",
                        onSelected: (String? value) {
                          if (value != null) {
                            // Find the country object
                            var selectedCountryObj = countryList.firstWhere(
                              (country) => country['id'].toString() == value,
                              orElse: () => {},
                            );

                            setState(() {
                              selectedCountryId = value; // Store the ID
                              selectedCountry = selectedCountryObj[
                                  'country_name']; // Store the display name
                              countryError = null;
                              isValidCountry = true;
                            });
                          }
                        },
                        hintStyle: GoogleFonts.dmSans(
                          fontSize: 14,
                          color: const Color(0xFFCBD5E0),
                        ),
                      ),
                      if (countryError != null) // แสดงข้อความข้อผิดพลาด
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            countryError!,
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      const SizedBox(height: 24),
                      // Date
                      Container(
                        height: 190,
                        width: double.infinity,
                        padding: const EdgeInsets.only(
                            top: 15, left: 16, right: 16, bottom: 11),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: dateTimeBorder,
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: // ในส่วนของการเลือกวันที่
                            DateSelector(
                          isDetail: false,
                          onStartDateTimeChanged: (startDate) {
                            setState(() {
                              selectedStartDate = startDate;
                              // ตรวจสอบว่า selectedStartDate และ selectedEndDate ไม่เป็น null พร้อมกัน
                              if (selectedStartDate != null &&
                                  selectedEndDate != null) {
                                dateTimeBorder = Color(0xFFCBD5E0);
                                dateTimeError = null; // ล้างข้อผิดพลาด
                                isValidDateTime = true;
                              }
                              if (selectedStartDate == null &&
                                  selectedEndDate != null) {
                                dateTimeError = "select Start Date";
                              } else if (selectedStartDate != null &&
                                  selectedEndDate == null) {
                                dateTimeError = "select End Date";
                              }
                            });
                          },
                          onEndDateTimeChanged: (endDate) {
                            setState(() {
                              selectedEndDate = endDate;
                              // ตรวจสอบว่า selectedStartDate และ selectedEndDate ไม่เป็น null พร้อมกัน
                              if (selectedStartDate != null &&
                                  selectedEndDate != null) {
                                dateTimeBorder = Color(
                                    0xFFCBD5E0); // เปลี่ยนสี border เป็นเขียว
                                dateTimeError = null; // ล้างข้อผิดพลาด
                                isValidDateTime = true;
                              }
                              if (selectedStartDate == null &&
                                  selectedEndDate != null) {
                                dateTimeError = "Select Start Date";
                              } else if (selectedStartDate != null &&
                                  selectedEndDate == null) {
                                dateTimeError = "Select End Date";
                              }
                            });
                          },
                          initialStartDate: selectedStartDate,
                          initialEndDate: selectedEndDate,
                        ),
                      ),
                      if (dateTimeError != null) // แสดงข้อความข้อผิดพลาด
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            dateTimeError!,
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      const SizedBox(height: 24),
                      // Attach File
                      Container(
                        height: 146,
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: uploadFileBorder,
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: AttachFile(
                          isEdit: widget.isEdit,
                          onFileSelected: _attachPdfFile,
                          initialFileName: selectedFileName,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        height: 414,
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: descriptionBorderColor,
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Description*',
                              style: GoogleFonts.dmSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            // TextField
                            Container(
                              height:
                                  332, // Adjust this height to fit your design
                              width: double.infinity,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Color(0xFFCBD5E0),
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: TextField(
                                maxLines: null,
                                controller: descriptionController,
                                onChanged: (value) {
                                  setState(() {
                                    description = value;
                                    if (value
                                                .replaceAll(RegExp(r'\s+'), '')
                                                .length <
                                            10 ||
                                        value
                                                .replaceAll(RegExp(r'\s+'), '')
                                                .length >
                                            3000) {
                                      descriptionBorderColor = Colors.red;
                                      descriptionError =
                                          "Minimum 10 characters, maximum 3000 characters";
                                      isValidDescription = false;
                                    } else {
                                      descriptionBorderColor =
                                          Color(0xFFCBD5E0);
                                      descriptionError = null;
                                      isValidDescription = true; // ฟอร์มถูกต้อง
                                    }
                                  });
                                }, // Allow multiple lines
                                decoration: InputDecoration(
                                  border: InputBorder
                                      .none, // Remove the default border
                                  contentPadding: EdgeInsets.all(11),
                                  hintText: 'Add description here ...',
                                  hintStyle: GoogleFonts.dmSans(
                                    fontSize: 14, // กำหนดขนาดฟอนต์
                                    fontWeight:
                                        FontWeight.w400, // น้ำหนักฟอนต์ 400
                                    fontStyle: FontStyle.normal, // สไตล์ปกติ
                                    color: Color(0xFFCBD5E0), // สีข้อความ
                                  ),
                                ),
                              ),
                            ),
                            if (descriptionError !=
                                null) // แสดงข้อความข้อผิดพลาด
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  descriptionError!,
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // ปุ่มด้านล่าง
          Container(
            color: const Color(0xFFFFFFFF),
            padding: const EdgeInsets.all(28),
            height: 113,
            child: Align(
              alignment: Alignment.topCenter, // ชิดด้านบน
              child: SizedBox(
                width: double.infinity,
                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween, // ชิดซ้ายขวา
                  children: [
                    SizedBox(
                      width: 170, // กำหนดความกว้างของปุ่ม Cancel
                      height: 48, // กำหนดความสูงของปุ่ม Cancel
                      child: ElevatedButton(
                        onPressed: () {
                          bool hasAddScholarshipUnsavedChanges = (urlController
                                  .text.isNotEmpty ||
                              title != null && title!.isNotEmpty ||
                              selectedCategoryId != null &&
                                  selectedCategoryId!.isNotEmpty ||
                              selectedCountry != null &&
                                  selectedCountry!.isNotEmpty ||
                              description != null && description!.isNotEmpty ||
                              selectedStartDate != null ||
                              selectedEndDate != null);

                          if (hasAddScholarshipUnsavedChanges) {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return Dialog(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                        12), // มุมโค้งของ Dialog
                                  ),
                                  child: SizedBox(
                                    height: 382, // กำหนดความสูง
                                    width: 320, // กำหนดความกว้าง
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 29),
                                          child: Image.asset(
                                            'assets/images/success.png',
                                            height: 166,
                                            width: 216, // ปรับขนาดรูปที่นี่
                                          ),
                                        ),
                                        const SizedBox(height: 18),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 24),
                                          child: Text(
                                            widget.isEdit
                                                ? "Are you sure you want to discard Edit?"
                                                : "Are you sure you want to discard this Draft?",
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.dmSans(
                                              fontWeight: FontWeight.w500,
                                              fontSize: 18,
                                              color: const Color(0xFF000000),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 24.0),
                                          child: Text(
                                            "The progress will not be saved.",
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.dmSans(
                                              fontWeight: FontWeight.w400,
                                              fontSize: 12,
                                              color: const Color(0xFF6B7280),
                                            ),
                                          ),
                                        ),
                                        const Spacer(), // ดันปุ่มลงไปด้านล่าง
                                        Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              SizedBox(
                                                width: 134, // ความกว้างของปุ่ม
                                                height: 41, // ความสูงของปุ่ม
                                                child: ElevatedButton(
                                                  onPressed: () {
                                                    Navigator.of(context)
                                                        .pop(); // ปิด Dialog
                                                  },
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    backgroundColor: const Color(
                                                        0xFF94A2B8), // สีปุ่ม
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8), // มุมโค้ง
                                                    ),
                                                  ),
                                                  child: Text(
                                                    "Cancel",
                                                    style: GoogleFonts.dmSans(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      fontSize:
                                                          10, // ขนาดตัวหนังสือ
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              SizedBox(
                                                width: 134,
                                                height: 41,
                                                child: ElevatedButton(
                                                  onPressed: () {
                                                    widget.isEdit
                                                        ? Navigator
                                                            .pushReplacement(
                                                            context,
                                                            PageRouteBuilder(
                                                              pageBuilder: (context,
                                                                      animation,
                                                                      secondaryAnimation) =>
                                                                  ProviderDetail(
                                                                // ส่ง initialData เดิมที่มีอยู่
                                                                initialData: {
                                                                  ...widget
                                                                      .initialData!, // คัดลอกข้อมูลเดิมทั้งหมด
                                                                  // อัพเดทข้อมูลใหม่ที่ต้องการ (ถ้ามี)

                                                                  'cachedImage':
                                                                      cancalImage,
                                                                  'attach_name':
                                                                      selectedFileName
                                                                },
                                                                isProvider:
                                                                    true,
                                                              ),
                                                              transitionsBuilder:
                                                                  (context,
                                                                      animation,
                                                                      secondaryAnimation,
                                                                      child) {
                                                                const begin =
                                                                    0.0;
                                                                const end = 1.0;
                                                                const curve =
                                                                    Curves
                                                                        .easeOut;

                                                                var tween = Tween(
                                                                        begin:
                                                                            begin,
                                                                        end:
                                                                            end)
                                                                    .chain(CurveTween(
                                                                        curve:
                                                                            curve));
                                                                return FadeTransition(
                                                                  opacity: animation
                                                                      .drive(
                                                                          tween),
                                                                  child: child,
                                                                );
                                                              },
                                                              transitionDuration:
                                                                  const Duration(
                                                                      milliseconds:
                                                                          300),
                                                            ),
                                                          )
                                                        : Navigator
                                                            .pushReplacement(
                                                            context,
                                                            PageRouteBuilder(
                                                              pageBuilder: (context,
                                                                      animation,
                                                                      secondaryAnimation) =>
                                                                  const ProviderManagement(),
                                                              transitionsBuilder:
                                                                  (context,
                                                                      animation,
                                                                      secondaryAnimation,
                                                                      child) {
                                                                const begin =
                                                                    0.0;
                                                                const end = 1.0;
                                                                const curve =
                                                                    Curves
                                                                        .easeOut;

                                                                var tween = Tween(
                                                                        begin:
                                                                            begin,
                                                                        end:
                                                                            end)
                                                                    .chain(CurveTween(
                                                                        curve:
                                                                            curve));
                                                                return FadeTransition(
                                                                  opacity: animation
                                                                      .drive(
                                                                          tween),
                                                                  child: child,
                                                                );
                                                              },
                                                              transitionDuration:
                                                                  const Duration(
                                                                      milliseconds:
                                                                          300),
                                                            ),
                                                          );
                                                  },
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    backgroundColor: const Color(
                                                        0xFFD5448E), // สีปุ่ม
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8), // มุมโค้ง
                                                    ),
                                                  ),
                                                  child: Text(
                                                    "Yes, Discard this",
                                                    style: GoogleFonts.dmSans(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      fontSize:
                                                          10, // ขนาดตัวหนังสือ
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          } else {
                            Navigator.pushReplacement(
                              context,
                              PageRouteBuilder(
                                pageBuilder:
                                    (context, animation, secondaryAnimation) =>
                                        const ProviderManagement(),
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
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey, // สีสำหรับปุ่ม Cancel
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          "Cancel",
                          style: GoogleFonts.dmSans(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 170,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          validateUrl(urlController.text);

                          setState(() {
                            if (urlError != null) {
                              isValidUrl = false;
                            } else {
                              isValidUrl = true; // ฟอร์มทั้งหมดผ่านการตรวจสอบ
                              urlBorderColor = Color(0xFFCBD5E0);
                            }
                          });

                          setState(() {
                            // ตรวจสอบค่าของ selectedCategory
                            if (selectedCategory == null ||
                                selectedCategory!.isEmpty ||
                                selectedCategory ==
                                    "Select type of scholarship") {
                              categoryError =
                                  "Please select a type of scholarship";
                              isValidCategory = false;
                              dropdownBorderColor = Colors.red;
                            } else {
                              isValidCategory = true;
                            }

                            if (title == null ||
                                title!.isEmpty ||
                                title!.replaceAll(RegExp(r'\s+'), '').length <
                                    5 ||
                                title!.replaceAll(RegExp(r'\s+'), '').length >
                                    100) {
                              titleError =
                                  "Minimum 5 characters, maximum 100 characters";
                              isValidTitle = false;
                              titleBorderColor = Colors.red;
                            } else {
                              isValidTitle = true;
                            }

                            if (selectedCountry == null ||
                                selectedCountry!.isEmpty ||
                                selectedCountry ==
                                    "Select country of scholarship") {
                              countryError = "Please select a country";
                              isValidCountry = false;
                              dropdownBorderColor = Colors.red;
                            } else {
                              isValidCountry = true;
                            }

                            if (selectedEducationLevel == null ||
                                selectedEducationLevel!.isEmpty ||
                                selectedEducationLevel ==
                                    "Select country of scholarship") {
                              educationLevelError =
                                  "Please select a Education Level";
                              isValidEducationLevel = false;
                              dropdownBorderColor = Colors.red;
                            } else {
                              isValidEducationLevel = true;
                            }

                            if (description == null ||
                                description!
                                    .replaceAll(RegExp(r'\s+'), '')
                                    .isEmpty ||
                                description!
                                        .replaceAll(RegExp(r'\s+'), '')
                                        .length <
                                    10 ||
                                description!
                                        .replaceAll(RegExp(r'\s+'), '')
                                        .length >
                                    3000) {
                              descriptionError =
                                  "Minimum 10 characters, maximum 3000 characters";
                              isValidDescription = false;
                              descriptionBorderColor = Colors.red;
                            } else {
                              isValidDescription = true;
                            }

                            if (selectedEndDate == null &&
                                selectedStartDate == null) {
                              dateTimeError = "Select Start Date and End Date";
                              isValidDateTime = false;
                              dateTimeBorder = Colors.red;
                            } else if (selectedStartDate == null &&
                                selectedEndDate != null) {
                              dateTimeError = "Select Start Date";
                              isValidDateTime = false;
                              dateTimeBorder = Colors.red;
                            } else if (selectedStartDate != null &&
                                selectedEndDate == null) {
                              dateTimeError = "Select End Date";
                              isValidDateTime = false;
                              dateTimeBorder = Colors.red;
                            } else {
                              isValidDateTime = true;
                            }
                          });

                          // ถ้าฟอร์มถูกต้อง ให้ดำเนินการ
                          if (isValidUrl &&
                              isValidCategory &&
                              isValidTitle &&
                              isValidCountry &&
                              isValidEducationLevel &&
                              isValidDescription &&
                              isValidDateTime) {
                            if (widget.isEdit) {
                              submitEditData(); // เรียกใช้ API สำหรับแก้ไขข้อมูล
                            } else {
                              submitAddData(); // เรียกใช้ API สำหรับเพิ่มข้อมูลใหม่
                            }
                          } else {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: Text("Required fields"),
                                  content: Text(
                                      "Please fill in all the required fields."),
                                  actions: [
                                    TextButton(
                                      child: Text("OK"),
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                    ),
                                  ],
                                );
                              },
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              // isValidUrl &&
                              //         isValidTitle &&
                              //         isValidCategory &&
                              //         isValidCountry &&
                              //         isValidDescription &&
                              //         isValidDateTime ?
                              const Color(0xFF355FFF),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          widget.isEdit ? "Update" : "Post",
                          style: GoogleFonts.dmSans(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
