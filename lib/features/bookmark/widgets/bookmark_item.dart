// widgets/bookmark_item.dart

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:google_fonts/google_fonts.dart';

class BookmarkItem extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onDelete;

  const BookmarkItem({super.key, required this.data, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        title: Text(
          data['title'] ?? 'No Title',
          style: GoogleFonts.dmSans(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          data['description'] ?? 'No Description',
          style: GoogleFonts.dmSans(fontSize: 14, color: Colors.grey[600]),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: onDelete,
        ),
      ),
    );
  }
}
