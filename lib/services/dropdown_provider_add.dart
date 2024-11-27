import 'package:flutter/material.dart';

class CustomDropdownExample extends StatefulWidget {
  final String? initialValue;
  final List<Map<String, dynamic>> items;
  final ValueChanged<String?> onSelected;
  final TextStyle hintStyle;
  final String type;

  const CustomDropdownExample({
    super.key,
    required this.items,
    this.initialValue,
    required this.onSelected,
    required this.hintStyle,
    required this.type,
  });

  @override
  State<CustomDropdownExample> createState() => _CustomDropdownExampleState();
}

class _CustomDropdownExampleState extends State<CustomDropdownExample> {
  final GlobalKey _key = GlobalKey();
  OverlayEntry? _overlayEntry;
  String? selectedValue;
  bool _isDropdownOpen = false;

  @override
  void initState() {
    super.initState();
    selectedValue = widget.initialValue;
  }

  void _showDropdown() {
    final renderBox = _key.currentContext?.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: offset.dx,
        top: offset.dy + size.height + 3,
        width: size.width,
        child: Material(
          color: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFCBD5E0)),
              borderRadius: BorderRadius.circular(6),
            ),
            child: ListView(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              children: widget.items.map((item) {
                String displayText = widget.type == 'category'
                    ? item['category_name'] ?? 'Unknown Category'
                    : item['country_name'] ?? 'Unknown Country';

                return ListTile(
                  title: Text(displayText),
                  onTap: () {
                    setState(() {
                      selectedValue = displayText;
                    });
                    widget.onSelected(item['id'].toString());
                    _removeDropdown();
                  },
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    setState(() {
      _isDropdownOpen = true;
    });
  }

  void _removeDropdown() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    setState(() {
      _isDropdownOpen = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: _key,
      onTap: () {
        if (_overlayEntry == null) {
          _showDropdown();
        } else {
          _removeDropdown();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFCBD5E0)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              selectedValue ??
                  (widget.type == 'category'
                      ? 'Select type of scholarship'
                      : 'Select country of scholarship'),
              style: TextStyle(
                color: (selectedValue == 'Select type of scholarship' ||
                        selectedValue == 'Select country of scholarship')
                    ? const Color(0xFFCBD5E0)
                    : const Color(0xFF000000),
              ),
            ),
            Transform.rotate(
              angle: _isDropdownOpen ? 3.14 : 0,
              child: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
