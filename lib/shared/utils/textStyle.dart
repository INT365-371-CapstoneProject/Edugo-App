import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TextStyleService {
  static TextStyle getDmSans({
    required double fontSize,
    required FontWeight fontWeight,
    Color color = Colors.black, // ค่าเริ่มต้นเป็นสีดำ
    double? height,
    FontStyle fontStyle = FontStyle.normal, // เพิ่ม fontStyle พร้อมค่าเริ่มต้น
  }) {
    return GoogleFonts.dmSans(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      fontStyle: fontStyle, // ใช้ fontStyle ที่เพิ่มเข้ามา
    );
  }
}
