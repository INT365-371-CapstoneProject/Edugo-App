import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import 'dart:io'; // เพิ่มการใช้งาน File

class HeaderProviderAdd extends StatefulWidget {
  final Function(Uint8List?) onImagePicked; // Callback to pass the image
  final bool isEdit; // Add/Edit mode flag
  final String? initialImage; // Initial image URL for Edit mode

  const HeaderProviderAdd({
    Key? key,
    required this.onImagePicked,
    this.isEdit = false, // Default is false (Add mode)
    this.initialImage,
  }) : super(key: key);

  @override
  _HeaderProviderAddState createState() => _HeaderProviderAddState();
}

class _HeaderProviderAddState extends State<HeaderProviderAdd> {
  Uint8List? _imageBytes; // Stores the currently selected image as bytes

  // Function to pick an image
  Future<void> _pickImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image, // เลือกเฉพาะไฟล์รูปภาพ
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final String extension =
          result.files.single.extension?.toLowerCase() ?? '';
      final int fileSize = await file.length(); // ขนาดไฟล์ในหน่วยไบต์

      // ตรวจสอบชนิดไฟล์
      if (extension != 'jpg' &&
          extension != 'jpeg' &&
          extension != 'png' &&
          extension != 'svg') {
        _showErrorDialog('กรุณาอัปโหลดไฟล์รูปแบบ JPG, PNG หรือ SVG เท่านั้น');
        return;
      }

      // ตรวจสอบขนาดไฟล์ (จำกัดไม่เกิน 4MB)
      if (fileSize > 4 * 1024 * 1024) {
        _showErrorDialog('ไฟล์มีขนาดใหญ่เกิน 4MB');
        return;
      }

      // อ่านไฟล์เป็น Bytes
      final bytes = await file.readAsBytes();

      setState(() {
        _imageBytes = bytes; // อัปเดต State ด้วยไฟล์ที่ผ่านการตรวจสอบแล้ว
      });

      widget.onImagePicked(_imageBytes); // ส่งข้อมูลกลับไปยัง widget หลัก
    }
  }

// ฟังก์ชันแสดงข้อความแจ้งเตือนเมื่อมีข้อผิดพลาด
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ข้อผิดพลาด'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('ตกลง'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double blueHeader = 227;
    final double picture = 338;
    final bottom = picture / 1.4;
    final top = blueHeader - picture / 3;

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        // Background container
        Container(
          height: blueHeader,
          color: const Color(0xFF355FFF),
          alignment: Alignment.topCenter,
          padding: const EdgeInsets.only(top: 63.0),
          margin: EdgeInsets.only(bottom: bottom),
          child: Text(
            widget.isEdit
                ? 'Edit Scholarship'
                : 'Add New Scholarship', // Check mode
            style: GoogleFonts.dmSans(
              color: const Color(0xFFFFFFFF),
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        // Positioned image with white faded overlay
        Positioned(
          top: top,
          child: SizedBox(
            width: 239,
            height: picture,
            child: Stack(
              children: [
                // Display selected image, initial image, or default asset image
                ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _imageBytes != null
                        ? Image.memory(
                            _imageBytes!,
                            width: 239,
                            height: picture,
                            fit: BoxFit.cover,
                          )
                        : (widget.initialImage != null &&
                                widget.initialImage !=
                                    'assets/images/scholarship_program.png')
                            ? Image.network(
                                widget.initialImage!,
                                width: 239,
                                height: picture,
                                fit: BoxFit.cover,
                              )
                            : Image.asset(
                                'assets/images/scholarship_program.png',
                                width: 239,
                                height: picture,
                                fit: BoxFit.cover,
                              )),
                // White faded overlay
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF636C8E).withOpacity(0.4),
                    ),
                  ),
                ),
                // Text and Button overlay
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Texts
                      Text(
                        'Maximum file size 4 MB',
                        style: GoogleFonts.dmSans(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          fontStyle: FontStyle.normal,
                        ),
                      ),
                      Text(
                        'Support format: JPG, PNG, SVG',
                        style: GoogleFonts.dmSans(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          fontStyle: FontStyle.normal,
                        ),
                      ),
                      const SizedBox(
                          height: 10), // Space between text and button
                      // Button
                      SizedBox(
                        width: 158,
                        height: 38,
                        child: ElevatedButton(
                          onPressed: _pickImage, // Trigger image picker
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF355FFF),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Upload Photo',
                                style: GoogleFonts.dmSans(
                                  fontSize: 14,
                                  color: const Color(0xFFFFFFFF),
                                ),
                              ),
                              const SizedBox(width: 7),
                              Image.asset(
                                'assets/images/icon_image.png', // Path to your icon
                                width: 14,
                                height: 14,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
