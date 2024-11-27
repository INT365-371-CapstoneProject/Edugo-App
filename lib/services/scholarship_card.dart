import 'package:flutter/material.dart';

class ScholarshipCard extends StatelessWidget {
  final String tag;
  final String image;
  final String title;
  final String date;
  final String status;
  final String description;

  const ScholarshipCard({
    super.key,
    required this.tag,
    required this.image,
    required this.title,
    required this.date,
    required this.status,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 359,
      height: 171,
      child: Container(
        decoration: BoxDecoration(
          // color: Colors.red, // Outer red border color
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.grey.withOpacity(0.3),
          ),
        ),
        padding: const EdgeInsets.all(14), // Outer padding
        child: Container(
          decoration: BoxDecoration(
            // color: Colors.blue[50], // Inner blue color
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: image.startsWith('http')
                    ? Image.network(
                        image,
                        width: 101,
                        height: 143,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      (loadingProgress.expectedTotalBytes ?? 1)
                                  : null,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.broken_image,
                          size: 101,
                          color: Colors.grey,
                        ),
                      )
                    : Image.asset(
                        image,
                        width: 101,
                        height: 143,
                        fit: BoxFit.cover,
                      ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 26,
                      // width: 219,
                      // color: const Color.fromARGB(255, 255, 6, 247),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            alignment: Alignment.center, // Center tag text
                            child: Text(
                              tag,
                              style: const TextStyle(
                                fontFamily: "DM Sans",
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF94A2B8),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Container(
                            width: 61,
                            height: 20,
                            decoration: BoxDecoration(
                              color: status == "Closed"
                                  ? Color(0xFFF9C7E1)
                                  : Colors.green[
                                      100], // พื้นหลังสี #F9C7E1 หากสถานะเป็น "Closed"
                              borderRadius: BorderRadius.circular(4),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              status,
                              style: TextStyle(
                                fontFamily: "DM Sans",
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: status == "Closed"
                                    ? Color(0xFFED4B9E)
                                    : Colors
                                        .green, // ฟอนต์สี #ED4B9E หากสถานะเป็น "Closed"
                              ),
                              textAlign: TextAlign.center,
                            ),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // detail
                    Container(
                      width: 178,
                      height: 107,
                      // color: const Color.fromARGB(255, 255, 6, 247),
                      child: Padding(
                        padding: const EdgeInsets.all(0.0),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start, // ชิดซ้าย
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontFamily: "DM Sans",
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                fontStyle: FontStyle.normal,
                                color: Color(0xFF000000),
                                height: 1.42857, // line-height equivalent
                              ),
                              maxLines: 2, // Limit to 2 lines
                              overflow: TextOverflow
                                  .ellipsis, // Ellipsis if text overflows
                            ),
                            const SizedBox(height: 4),
                            Text(
                              date,
                              style: const TextStyle(
                                fontFamily: "DM Sans",
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                fontStyle: FontStyle.normal,
                                color: Color(0xFF2A4CCC),
                              ),
                              maxLines: 2, // Limit to 2 lines
                              overflow: TextOverflow
                                  .ellipsis, // Ellipsis if text overflows
                            ),
                            const SizedBox(height: 8),
                            Text(
                              description,
                              style: const TextStyle(
                                fontFamily: "DM Sans",
                                fontSize: 11,
                                fontWeight: FontWeight.w400,
                                fontStyle: FontStyle.normal,
                                color: Color(0xFF94A2B8),
                              ),
                              maxLines: 2, // Limit to 2 lines
                              overflow: TextOverflow
                                  .ellipsis, // Ellipsis if text overflows
                            ),
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
