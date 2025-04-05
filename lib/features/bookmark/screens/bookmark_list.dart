import 'package:edugo/features/bookmark/services/%E0%B8%B4bookmark_service.dart';
import 'package:edugo/features/bookmark/widgets/bookmark_item.dart';
import 'package:edugo/features/profile/screens/profile.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BookmarkList extends StatefulWidget {
  final int id;

  const BookmarkList({super.key, required this.id});

  @override
  State<BookmarkList> createState() => _BookmarkListState();
}

class _BookmarkListState extends State<BookmarkList> {
  final BookmarkService _bookmarkService = BookmarkService();
  List<dynamic> bookmarks = [];
  Map<String, dynamic> announceDetails = {};
  bool isLoading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    loadData();
  }

  Future<void> loadData() async {
    try {
      final data = await _bookmarkService.fetchBookmarks(widget.id);
      final ids =
          data.map<int>((e) => e['announce_id'] as int).toSet().toList();
      final details = await _bookmarkService.fetchAnnounceDetails(ids);

      setState(() {
        bookmarks = data;
        announceDetails = details;
        isLoading = false;
      });
    } catch (e) {
      print("Error loading data: $e");
    }
  }

  void handleDelete(int id) async {
    await _bookmarkService.deleteBookmark(id);
    loadData(); // รีโหลดใหม่หลังลบ
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: announceDetails['data']?.length ?? 0,
                    itemBuilder: (context, index) {
                      final item = announceDetails['data'][index];
                      return BookmarkItem(
                        data: item,
                        onDelete: () => handleDelete(item['id']),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      color: const Color(0xFF355FFF),
      padding:
          const EdgeInsets.only(top: 72.0, right: 16, left: 16, bottom: 22),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _circleIcon('assets/images/back_button.png', () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const ProviderProfile()),
            );
          }),
          Text("Bookmark",
              style: GoogleFonts.dmSans(fontSize: 20, color: Colors.white)),
          _circleIcon('assets/images/notification.png', () {
            print(announceDetails);
          }),
        ],
      ),
    );
  }

  Widget _circleIcon(String assetPath, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        radius: 20,
        backgroundColor: const Color(0xFFDAFB59),
        child: Image.asset(assetPath, width: 20, height: 20),
      ),
    );
  }
}
