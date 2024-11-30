import 'dart:typed_data';
import 'dart:io'; // สำหรับ File I/O
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';

class AttachFile extends StatefulWidget {
  final Function(Uint8List? fileBytes, String? fileName) onFileSelected;
  final String? initialFileName;
  final bool isEdit;

  const AttachFile({
    super.key,
    required this.onFileSelected,
    this.initialFileName,
    this.isEdit = false,
  });

  @override
  _AttachFileState createState() => _AttachFileState();
}

class _AttachFileState extends State<AttachFile> {
  late String fileName = 'Select file to Upload';

  @override
  void initState() {
    super.initState();
    fileName = widget.isEdit && widget.initialFileName != null
        ? widget.initialFileName!
        : 'Select file to Upload';
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'], // กำหนดให้เลือกเฉพาะไฟล์ PDF
    );

    if (result != null) {
      String? selectedFileName = result.files.single.name;
      Uint8List? fileBytes = result.files.single.bytes;

      // ตรวจสอบว่าไฟล์ที่เลือกเป็น PDF หรือไม่
      if (selectedFileName != null && !selectedFileName.endsWith('.pdf')) {
        // แสดง Dialog ถ้าไฟล์ไม่ใช่ PDF
        _showOnlyPdfDialog();
        return;
      }

      // ถ้า bytes เป็น null แต่มี path ให้โหลดไฟล์
      if (fileBytes == null && result.files.single.path != null) {
        File file = File(result.files.single.path!);
        fileBytes = await file.readAsBytes(); // โหลดเนื้อหาไฟล์
      }

      // ตรวจสอบขนาดไฟล์ (5MB)
      if (fileBytes != null && fileBytes.lengthInBytes > 5 * 1024 * 1024) {
        _showFileSizeLimitDialog();
        return;
      }

      // อัพเดตสถานะและส่งไฟล์กลับ
      setState(() {
        fileName = selectedFileName ?? 'Select file to Upload';
      });
      widget.onFileSelected(fileBytes, selectedFileName);
    } else {
      // กรณีผู้ใช้ไม่เลือกไฟล์
      setState(() {
        fileName = 'Select file to Upload';
      });
      widget.onFileSelected(null, null);
    }
  }

  void _showFileSizeLimitDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('File Size Limit Exceeded'),
          content: Text(
              'File size exceeds the 5MB limit. Please select a smaller file.'),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop(); // ปิด dialog
              },
            ),
          ],
        );
      },
    );
  }

  // แสดง Dialog ถ้าไฟล์ไม่ใช่ PDF
  void _showOnlyPdfDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Invalid File Type'),
          content: Text('Only PDF files are allowed.'),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop(); // ปิด dialog
              },
            ),
          ],
        );
      },
    );
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
                          fileName,
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            fontStyle: FontStyle.italic,
                            color: Color(0xFF94A2B8),
                          ),
                          overflow: TextOverflow.ellipsis,
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
              onPressed: _pickFile, // เรียก method _pickFile
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
