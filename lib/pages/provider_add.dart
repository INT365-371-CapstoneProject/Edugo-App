import 'package:edugo/pages/provider_management.dart';
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
  String? image;
  String? selectedScholarshipType; // สำหรับ Scholarship Type
  String? selectedCountry;
  String? selectedCountryId; // ตัวแปรเก็บ country_id
  String? selectedCategory;
  String? selectedCategoryId;
  DateTime? selectedStartDate;
  DateTime? selectedEndDate;
  Uint8List? _imageBytes; // Holds the selected image data
  Uint8List? _pdfFileBytes;
  String? pdfFileName;
  String? selectedFileName; // เก็บชื่อไฟล์ที่เลือก

  // สร้าง controller สำหรับ TextField
  TextEditingController titleController = TextEditingController();
  TextEditingController urlController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();

  List<Map<String, dynamic>> countryList = []; // Store country data here
  List<Map<String, dynamic>> categoryList = []; // Store country data here

  Map<String, dynamic> originalValues = {};

  @override
  void initState() {
    super.initState();
    fetchCountryData();
    fetchCategoryData();

    if (widget.isEdit && widget.initialData != null) {
      final data = widget.initialData!;
      id = data['id'] ?? '';
      title = data['title'] ?? '';
      description = data['description'] ?? '';
      url = data['url'] ?? '';
      selectedCountry = data['country'] ?? '';
      selectedCategory = data['category'] ?? '';
      selectedStartDate = data['published_date'] != null
          ? DateTime.tryParse(data['published_date'])
          : null;
      selectedEndDate = data['close_date'] != null
          ? DateTime.tryParse(data['close_date'])
          : null;
      image = data['image'] ?? '';
      selectedFileName = data['attach_file'];

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
        'image': image,
        'attach_file': selectedFileName,
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
    const apiUrl = "https://capstone24.sit.kmutt.ac.th/un2/api/country";
    try {
      var response = await http.get(Uri.parse(apiUrl));
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
    const apiUrl = "https://capstone24.sit.kmutt.ac.th/un2/api/category";
    try {
      var response = await http.get(Uri.parse(apiUrl));
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

  void handleCountrySelection(String? countryId) {
    setState(() {
      selectedCountry = countryId; // Store the selected country ID
    });
  }

  void handleCategorySelection(String? categoryId) {
    setState(() {
      selectedCategory = categoryId; // Store the selected country ID
    });
  }

  void _onImagePicked(Uint8List? image) {
    setState(() {
      _imageBytes = image;
    });
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
    final String apiUrl =
        "https://capstone24.sit.kmutt.ac.th/un2/api/announce/add";

    var request = http.MultipartRequest('POST', Uri.parse(apiUrl));

    request.fields['title'] = title ?? '';
    request.fields['description'] = description ?? '';
    request.fields['posts_type'] = 'Announce';
    request.fields['publish_date'] =
        '${selectedStartDate?.toUtc().toIso8601String().split('.')[0]}Z';
    request.fields['close_date'] =
        '${selectedEndDate?.toUtc().toIso8601String().split('.')[0]}Z';
    request.fields['category_id'] = selectedCategory ?? '1';
    request.fields['country_id'] = selectedCountry ?? '1';

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

    try {
      var response = await request.send();

      if (response.statusCode == 200 || response.statusCode == 201) {
        showSuccess("Data submitted successfully");
      } else {
        showError("Failed to submit data. Status code: ${response.statusCode}");
      }
    } catch (e) {
      showError("Error occurred: $e");
    }
  }

  Future<void> submitEditData() async {
    final String apiUrl =
        "https://capstone24.sit.kmutt.ac.th/un2/api/announce/update/${id}";

    var request = http.MultipartRequest('PUT', Uri.parse(apiUrl));

    Map<String, String> updatedFields = {};

    if (title != originalValues['title']) updatedFields['title'] = title ?? '';
    if (description != originalValues['description']) {
      updatedFields['description'] = description ?? '';
    }
    if (url != originalValues['url']) updatedFields['url'] = url ?? '';

    if (selectedCountry != originalValues['country']) {
      updatedFields['country_id'] = selectedCountry ?? '1';
    }
    if (selectedCategory != originalValues['category']) {
      updatedFields['category_id'] = selectedCategory ?? '1';
    }
    if (selectedStartDate?.toIso8601String() !=
        originalValues['publish_date']) {
      updatedFields['publish_date'] =
          '${selectedStartDate?.toUtc().toIso8601String().split('.')[0]}Z';
    }
    if (selectedEndDate?.toIso8601String() != originalValues['close_date']) {
      updatedFields['close_date'] =
          '${selectedEndDate?.toUtc().toIso8601String().split('.')[0]}Z';
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

    try {
      var response = await request.send();

      if (response.statusCode == 200 || response.statusCode == 201) {
        showSuccess("Data submitted successfully");
      } else {
        showError("Failed to submit data. Status code: ${response.statusCode}");
      }
    } catch (e) {
      showError("Error occurred: $e");
    }
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
                    initialImage: image),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
                          controller:
                              titleController, // ใช้ controller ที่กำหนด
                          onChanged: (value) {
                            setState(() {
                              title = value;
                            });
                          },
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6.0),
                              borderSide: BorderSide(
                                color: Color(0xFFCBD5E0),
                                width: 1.0,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6.0),
                              borderSide: BorderSide(
                                color: Color(0xFFCBD5E0),
                                width: 1.0,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6.0),
                              borderSide: BorderSide(
                                color: Color(0xFFCBD5E0),
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
                      const SizedBox(height: 8),
                      Text(
                        'web (url)',
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
                          onChanged: (value) {
                            setState(() {
                              url = value;
                            });
                          },
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(6.0), // มุมโค้ง 6
                              borderSide: BorderSide(
                                color: Color(0xFFCBD5E0), // สีขอบ
                                width: 1.0,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(6.0), // มุมโค้ง 6
                              borderSide: BorderSide(
                                color:
                                    Color(0xFFCBD5E0), // สีขอบเมื่อไม่ได้โฟกัส
                                width: 1.0,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(6.0), // มุมโค้ง 6
                              borderSide: BorderSide(
                                color: Color(0xFFCBD5E0), // สีขอบเมื่อโฟกัส
                                width: 2.0,
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
                        items: categoryList, // categoryList for type 'category'
                        type: 'category',
                        initialValue:
                            selectedCategory ?? "Select type of scholarship",
                        onSelected: (value) {
                          setState(() {
                            selectedCategory = value;
                          });
                        },
                        hintStyle: GoogleFonts.dmSans(
                          fontSize: 14,
                          color: const Color(0xFFCBD5E0), // Hint color
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
                        initialValue:
                            selectedCountry ?? "Select country of scholarship",
                        onSelected: (value) {
                          setState(() {
                            selectedCountry = value;
                          });
                        },
                        hintStyle: GoogleFonts.dmSans(
                          fontSize: 14,
                          color: const Color(0xFFCBD5E0), // Hint color
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
                            color: Color(0xFFCBD5E0),
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: DateSelector(
                          isDetail: false,
                          onStartDateTimeChanged: updateStartDateTime,
                          onEndDateTimeChanged: updateEndDateTime,
                          initialStartDate: selectedStartDate,
                          initialEndDate: selectedEndDate,
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
                            color: Color(0xFFCBD5E0),
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
                            color: Color(0xFFCBD5E0),
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
                                  353, // Adjust this height to fit your design
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
                          ],
                        ),
                      ),
                      const SizedBox(height: 200),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // ปุ่มด้านล่าง
          Container(
            color: const Color(0xFFFFFFFF),
            padding: const EdgeInsets.all(16),
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
                          Navigator.push(
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
                      width: 170, // กำหนดความกว้างของปุ่ม Post
                      height: 48, // กำหนดความสูงของปุ่ม Post
                      child: ElevatedButton(
                        onPressed: () {
                          if (widget.isEdit) {
                            submitEditData(); // เรียกใช้ API สำหรับแก้ไขข้อมูล
                          } else {
                            submitAddData(); // เรียกใช้ API สำหรับเพิ่มข้อมูลใหม่
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color(0xFF355FFF), // สีสำหรับปุ่ม Post
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          widget.isEdit
                              ? "Update"
                              : "Post", // เปลี่ยนข้อความปุ่มตามสถานะ
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
