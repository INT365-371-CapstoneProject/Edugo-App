import 'package:flutter/cupertino.dart';
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
            onTap: () {
              // Navigator.pop(context);
              Navigator.push(
                context,
                PageRouteBuilder(
                  // transitionDuration: Duration(microseconds: 350),
                  reverseTransitionDuration: Duration(milliseconds: 350),
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      pageToNavigate,
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                    // สร้างการเลื่อน Slide Out
                    var begin =
                        Offset(1.0, 0.0); // ให้หน้าใหม่เลื่อนจากขวามาซ้าย
                    var end = Offset.zero; // ปลายทางอยู่ที่ตำแหน่งเดิม
                    var curve = Curves.easeInOut;
                    var tween = Tween(begin: begin, end: end)
                        .chain(CurveTween(curve: curve));
                    var offsetAnimation = animation.drive(tween);

                    return SlideTransition(
                        position: offsetAnimation, child: child);
                  },
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

// import 'package:edugo/pages/provider_or_user.dart';
// import 'package:edugo/shared/utils/customPageRoute.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_svg/flutter_svg.dart';

// class CustomBackButton extends StatelessWidget {
//   final String routeName; // เปลี่ยนจาก Widget เป็น String routeName

//   const CustomBackButton({
//     super.key,
//     required this.routeName,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Positioned(
//       top: 63.0,
//       left: 22.0,
//       child: Container(
//         width: 32.0,
//         height: 32.0,
//         decoration: BoxDecoration(
//           color: const Color(0xFFFFFFFF),
//           borderRadius: BorderRadius.circular(4.0),
//           border: Border.all(
//             color: const Color(0xFFCBD5E0),
//             width: 1,
//           ),
//         ),
//         child: Material(
//           color: Colors.transparent,
//           child: InkWell(
//             borderRadius: BorderRadius.circular(4.0),
//             onTap: () {
//               Navigator.of(context).push(
//                 CustomPageRoute(
//                   builder: (context) =>
//                       ProviderOrUser(), // <- ต้อง import มาด้วย
//                 ),
//               );
//             },
//             child: Align(
//               alignment: Alignment.center,
//               child: SizedBox(
//                 width: 9.0,
//                 height: 15.0,
//                 child: SvgPicture.asset(
//                   'assets/images/back.svg',
//                   fit: BoxFit.cover,
//                   color: const Color(0xFF000000),
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
