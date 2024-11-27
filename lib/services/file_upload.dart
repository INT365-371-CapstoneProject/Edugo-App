import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';

class AttachFile extends StatefulWidget {
  final Function(Uint8List? fileBytes, String? fileName)
      onFileSelected; // Callback to return selected file and file name
  final String? initialFileName;
  final bool isEdit;

  const AttachFile(
      {super.key,
      required this.onFileSelected,
      this.initialFileName,
      this.isEdit = false});

  @override
  _AttachFileState createState() => _AttachFileState();
}

class _AttachFileState extends State<AttachFile> {
  late String fileName = 'Select file to Upload';

  @override
  void initState() {
    super.initState();
    // หากมี initialFileName (กรณีการแก้ไข) ให้ตั้งค่าให้กับ fileName
    fileName = widget.isEdit && widget.initialFileName != null
        ? widget.initialFileName!
        : 'Select file to Upload';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Color(0xFFE5EDFB),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Image.asset(
                  'assets/images/attach_file.png',
                  width: 66.0,
                  height: 66.0,
                ),
              ),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Attach File',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 14,
                        fontStyle: FontStyle.normal,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF94A2B8),
                        height: 1.0,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      '*upload PDF file with maximum size 50 MB',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 12,
                        fontWeight: FontWeight.normal,
                        color: Color(0xFF94A2B8),
                      ),
                    ),
                    SizedBox(height: 4),
                    // File name with auto width
                    Container(
                      height: 28,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Color(0xFFC0CDFF),
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          fileName, // แสดงชื่อไฟล์ที่ถูกเลือก
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            fontStyle: FontStyle.italic,
                            color: Color(0xFF94A2B8),
                          ),
                          overflow:
                              TextOverflow.ellipsis, // หากชื่อไฟล์ยาวเกินไป
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Button Attach
          SizedBox(
            height: 36,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                // เปิด File Picker เมื่อกดปุ่ม
                FilePickerResult? result = await FilePicker.platform.pickFiles(
                  type: FileType.custom,
                  allowedExtensions: ['pdf'], // กำหนดเฉพาะไฟล์ PDF
                );

                if (result != null) {
                  // ได้ไฟล์จากการเลือก
                  Uint8List? fileBytes = result.files.single.bytes;
                  String? selectedFileName = result.files.single.name;
                  setState(() {
                    fileName = selectedFileName ??
                        'Select file to Upload'; // อัพเดตชื่อไฟล์
                  });
                  widget.onFileSelected(fileBytes,
                      selectedFileName); // ส่งทั้ง fileBytes และ fileName
                } else {
                  // ไม่มีไฟล์ถูกเลือก
                  setState(() {
                    fileName = 'Select file to Upload'; // ตั้งค่าชื่อไฟล์กลับ
                  });
                  widget.onFileSelected(null, null); // ส่ง null เมื่อไม่มีไฟล์
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF355FFF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Attach File",
                    style: GoogleFonts.dmSans(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Image.asset(
                    'assets/images/icon_attach_file.png',
                    width: 15.0,
                    height: 18.0,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
