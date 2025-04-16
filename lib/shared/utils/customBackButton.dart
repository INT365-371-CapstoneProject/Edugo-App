import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CustomBackButton extends StatelessWidget {
  final Widget pageToNavigate;

  const CustomBackButton({
    super.key,
    required this.pageToNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 63.0,
      left: 16.0,
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
            onTap: () {
              Navigator.pushReplacement(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      pageToNavigate,
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                    const begin = 0.0;
                    const end = 1.0;
                    const curve = Curves.easeOut;
                    var tween = Tween(begin: begin, end: end)
                        .chain(CurveTween(curve: curve));
                    return FadeTransition(
                        opacity: animation.drive(tween), child: child);
                  },
                  transitionDuration: const Duration(milliseconds: 300),
                ),
              );
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
