import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class DateSelector extends StatefulWidget {
  final Function(DateTime?)? onStartDateTimeChanged;
  final Function(DateTime?)? onEndDateTimeChanged;
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;
  final bool? isDetail;

  const DateSelector({
    Key? key,
    this.onStartDateTimeChanged,
    this.onEndDateTimeChanged,
    this.initialStartDate,
    this.initialEndDate,
    this.isDetail,
  }) : super(key: key);

  @override
  State<DateSelector> createState() => _DateSelectorState();
}

class _DateSelectorState extends State<DateSelector> {
  DateTime? startDate;
  TimeOfDay? startTime;

  DateTime? endDate;
  TimeOfDay? endTime;

  bool? isDetail;

  @override
  void initState() {
    super.initState();
    // Initialize the start and end dates if they are provided
    startDate = widget.initialStartDate;
    endDate = widget.initialEndDate;
    isDetail = widget.isDetail;

    if (startDate != null) {
      startTime = TimeOfDay(hour: startDate!.hour, minute: startDate!.minute);
    }
    if (endDate != null) {
      endTime = TimeOfDay(hour: endDate!.hour, minute: endDate!.minute);
    }
  }

  DateTime? get startDateTime {
    if (startDate != null && startTime != null) {
      return DateTime(
        startDate!.year,
        startDate!.month,
        startDate!.day,
        startTime!.hour,
        startTime!.minute,
      );
    }
    return null;
  }

  DateTime? get endDateTime {
    if (endDate != null && endTime != null) {
      return DateTime(
        endDate!.year,
        endDate!.month,
        endDate!.day,
        endTime!.hour,
        endTime!.minute,
      );
    }
    return null;
  }

  void updateStartDateTime() {
    if (widget.onStartDateTimeChanged != null) {
      widget.onStartDateTimeChanged!(startDateTime); // ส่งค่ากลับไปที่ Parent
    }
  }

  void updateEndDateTime() {
    if (widget.onEndDateTimeChanged != null) {
      widget.onEndDateTimeChanged!(endDateTime); // ส่งค่ากลับไปที่ Parent
    }
  }

  void showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Invalid Selection'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Start Date and Time
        Text(
          'Start Date',
          style: GoogleFonts.dmSans(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: GestureDetector(
                onTap: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (pickedDate != null) {
                    setState(() {
                      startDate = pickedDate;
                    });
                    updateStartDateTime(); // อัปเดตค่าทันที
                  }
                },
                child: Container(
                  height: 45,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFCBD5E0)),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    startDate != null
                        ? DateFormat('d MMMM yyyy').format(startDate!)
                        : 'Select Date',
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      color: isDetail == true
                          ? const Color(0xFF64738B)
                          : startDate == null
                              ? const Color(0xFFCBD5E0)
                              : Colors.black,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 1,
              child: GestureDetector(
                onTap: () async {
                  final pickedTime = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (pickedTime != null) {
                    setState(() {
                      startTime = pickedTime;
                    });
                    updateStartDateTime(); // อัปเดตค่าทันที
                  }
                },
                child: Container(
                  height: 45,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFCBD5E0)),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    startTime != null
                        ? '${startTime!.format(context)}'
                        : 'Select Time',
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      color: isDetail == true
                          ? const Color(0xFF64738B)
                          : startTime == null
                              ? const Color(0xFFCBD5E0)
                              : Colors.black,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // End Date and Time
        Text(
          'End Date',
          style: GoogleFonts.dmSans(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: GestureDetector(
                onTap: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (pickedDate != null) {
                    if (startDate != null && pickedDate.isBefore(startDate!)) {
                      showErrorDialog(
                          'End Date cannot be earlier than Start Date.');
                    } else {
                      setState(() {
                        endDate = pickedDate;
                      });
                      updateEndDateTime(); // อัปเดตค่าทันที
                    }
                  }
                },
                child: Container(
                  height: 45,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFCBD5E0)),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    endDate != null
                        ? DateFormat('d MMMM yyyy').format(endDate!)
                        : 'Select Date',
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      color: isDetail == true
                          ? const Color(0xFF64738B)
                          : endDate == null
                              ? const Color(0xFFCBD5E0)
                              : Colors.black,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 1,
              child: GestureDetector(
                onTap: () async {
                  final pickedTime = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (pickedTime != null) {
                    // ตรวจสอบเฉพาะเวลาของ End Time เมื่อวันที่ตรงกับ Start Date
                    if (startDate != null &&
                        endDate != null &&
                        startDate!.isAtSameMomentAs(endDate!)) {
                      if (startTime != null &&
                          (pickedTime.hour < startTime!.hour ||
                              (pickedTime.hour == startTime!.hour &&
                                  pickedTime.minute <= startTime!.minute))) {
                        showErrorDialog(
                            'End Time must be later than Start Time.');
                      } else {
                        setState(() {
                          endTime = pickedTime;
                        });
                        updateEndDateTime(); // อัปเดตค่าทันที
                      }
                    } else {
                      // กรณีที่วันที่ไม่ตรงกัน ให้ไม่ตรวจสอบเวลา
                      setState(() {
                        endTime = pickedTime;
                      });
                      updateEndDateTime(); // อัปเดตค่าทันที
                    }
                  }
                },
                child: Container(
                  height: 45,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFCBD5E0)),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    endTime != null
                        ? '${endTime!.format(context)}'
                        : 'Select Time',
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      color: isDetail == true
                          ? const Color(0xFF64738B)
                          : endTime == null
                              ? const Color(0xFFCBD5E0)
                              : Colors.black,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
