import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CustomBackButton extends StatelessWidget {
  final VoidCallback? onPressed; // Add optional callback

  const CustomBackButton({
    super.key,
    this.onPressed, // Initialize in constructor
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 63.0,
      left: 22.0,
      child: Container(
        width: 32.0,
        height: 32.0,
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(4.0),
          border: Border.all(
            color: const Color(0xFFCBD5E0),
            width: 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(4.0),
            onTap: onPressed ?? // Use provided callback or default pop
                () {
                  // Default behavior: pop the current route
                  Navigator.pop(context);
                },
            child: Align(
              alignment: Alignment.center,
              child: SizedBox(
                width: 9.0,
                height: 15.0,
                child: SvgPicture.asset(
                  'assets/images/back.svg',
                  fit: BoxFit.cover,
                  color: const Color(0xFF000000),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
