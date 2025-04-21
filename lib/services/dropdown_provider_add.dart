import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomDropdownExample extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final String type;
  final Color validColor;
  final String? initialValue; // Expects display name or hint
  final ValueChanged<String?> onSelected; // Returns the selected ID
  final TextStyle? hintStyle;

  const CustomDropdownExample({
    Key? key,
    required this.items,
    required this.type,
    required this.validColor,
    this.initialValue,
    required this.onSelected,
    this.hintStyle,
  }) : super(key: key);

  @override
  _CustomDropdownExampleState createState() => _CustomDropdownExampleState();
}

class _CustomDropdownExampleState extends State<CustomDropdownExample> {
  String? _selectedValue; // This will hold the ID
  late String displayNameKey;
  // Initialize hintText with a default value
  String hintText = 'Select an option';

  @override
  void initState() {
    super.initState();
    _setKeys(); // This will now overwrite the default hintText
    _updateSelectedValueFromInitial();
  }

  @override
  void didUpdateWidget(CustomDropdownExample oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != oldWidget.initialValue ||
        widget.items != oldWidget.items) {
      _setKeys(); // Re-set keys in case type changed (unlikely but safe)
      _updateSelectedValueFromInitial();
    }
  }

  void _setKeys() {
    // Determine the key for the display name based on the type
    if (widget.type == 'category') {
      displayNameKey = 'category_name';
      hintText = 'Select type of scholarship';
    } else if (widget.type == 'country') {
      displayNameKey = 'country_name';
      hintText = 'Select country of scholarship';
    } else if (widget.type == 'education level') {
      displayNameKey = 'education_name';
      hintText = 'Select education level of scholarship';
    } else {
      displayNameKey = 'name'; // Default key
      hintText = 'Select an option';
    }
  }

  void _updateSelectedValueFromInitial() {
    _selectedValue = null; // Reset
    if (widget.initialValue != null && widget.initialValue != hintText) {
      try {
        // Find the item whose display name matches the initialValue
        final selectedItem = widget.items.firstWhere(
          (item) => item[displayNameKey] == widget.initialValue,
          // orElse: () => null, // Not needed with try-catch
        );
        _selectedValue = selectedItem['id']?.toString();
      } catch (e) {
        // Handle case where initialValue doesn't match any item's display name
        print(
            "Warning: Initial value '${widget.initialValue}' not found in dropdown items for type '${widget.type}'.");
        _selectedValue = null;
      }
    }
    // If initialValue is the hint or null, _selectedValue remains null
    // Trigger a rebuild if the value changed during init/update
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Find the display name for the currently selected ID (_selectedValue)
    String? currentDisplayValue = hintText; // Default to hint
    if (_selectedValue != null) {
      try {
        final selectedItemData = widget.items.firstWhere(
          (item) => item['id'].toString() == _selectedValue,
        );
        currentDisplayValue = selectedItemData[displayNameKey];
      } catch (e) {
        // Selected ID no longer exists? Fallback to hint.
        print(
            "Warning: Selected value '$_selectedValue' not found in dropdown items for type '${widget.type}'.");
        currentDisplayValue = hintText;
        // Optionally reset _selectedValue = null; here if needed
      }
    }

    return DropdownButtonFormField<String>(
      isExpanded: true, // Allow the dropdown to expand
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 12.0, vertical: 10.0), // Consistent padding
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6.0),
          borderSide: BorderSide(color: widget.validColor, width: 1.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6.0),
          borderSide: BorderSide(color: widget.validColor, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6.0),
          borderSide: BorderSide(color: widget.validColor, width: 1.0),
        ),
      ),
      hint: Text(
        // Hint is displayed when value is null
        hintText,
        style: widget.hintStyle ??
            GoogleFonts.dmSans(fontSize: 14, color: const Color(0xFFCBD5E0)),
        overflow: TextOverflow.ellipsis,
      ),
      value: _selectedValue, // Use the ID as the value
      onChanged: (String? newValue) {
        // newValue is the ID
        setState(() {
          _selectedValue = newValue;
        });
        widget.onSelected(newValue); // Pass the selected ID back
      },
      selectedItemBuilder: (BuildContext context) {
        // Builds the widget shown in the button when an item is selected
        // We need to return a list of widgets, one for each possible item value.
        // Flutter uses this to render the selected item *in place* of the hint.
        return widget.items.map<Widget>((Map<String, dynamic> item) {
          // This widget is only *displayed* if its corresponding ID is selected.
          return Align(
            // Use Align or Container for positioning if needed
            alignment: Alignment.centerLeft,
            child: Text(
              item[displayNameKey] ?? 'N/A',
              style: GoogleFonts.dmSans(
                // Style for selected item text
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Colors.black, // Color when selected
              ),
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList();
      },
      items: widget.items
          .map<DropdownMenuItem<String>>((Map<String, dynamic> item) {
        // Builds the items shown in the dropdown list when opened
        return DropdownMenuItem<String>(
          value: item['id'].toString(), // The value of the item MUST be the ID
          child: Text(
            // The child is what's displayed in the list
            item[displayNameKey] ?? 'N/A',
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF6B7280)),
      iconSize: 24,
      elevation: 16,
      style: GoogleFonts.dmSans(
        // Default style for items in the list
        fontSize: 14,
        color: Colors.black,
      ),
    );
  }
}
