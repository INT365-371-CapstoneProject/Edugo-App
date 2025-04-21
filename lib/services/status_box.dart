import 'package:edugo/shared/utils/textStyle.dart';
import 'package:flutter/material.dart';

class StatusBox extends StatelessWidget {
  final String title;
  final Color color;
  final String count;

  const StatusBox({
    super.key,
    required this.title,
    required this.color,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 78, // Reduced width from 82 to 78
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5.0),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(2),
                bottomRight: Radius.circular(2),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(
                left: 8,
                right: 8,
                top: 8,
                bottom: 8,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyleService.getDmSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                      height: 1.1,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1),
                  Text(
                    count,
                    style: TextStyleService.getDmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
