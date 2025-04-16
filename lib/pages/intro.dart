import 'package:edugo/pages/provider_or_user.dart';
import 'package:edugo/shared/utils/textStyle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  _IntroScreenState createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  bool isIntro1 = true;

  void _onNextPage() {
    if (isIntro1) {
      setState(() {
        isIntro1 = false;
      });
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const ProviderOrUser(),
        ),
      );
    }
  }

  void _onSkipOrBack() {
    if (isIntro1) {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const ProviderOrUser(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const curve = Curves.easeOut;
            var tween =
                Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: curve));
            return FadeTransition(
              opacity: animation.drive(tween),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
        ),
      );
    } else {
      setState(() {
        isIntro1 = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start, // ติดด้านบนสุด
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 87),
          // Logo at the top
          SizedBox(
            width: 175,
            height: 37.656,
            child: Image.asset(
              "assets/images/logoColor.png",
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 48.34),

          // Main image
          SizedBox(
            width: 302,
            height: 264,
            child: SvgPicture.asset(
              isIntro1
                  ? "assets/images/intro1.svg"
                  : "assets/images/intro2.svg",
            ),
          ),

          const SizedBox(height: 48.0),

          // Indicator dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildIndicator(isActive: isIntro1),
              const SizedBox(width: 5),
              _buildIndicator(isActive: !isIntro1),
            ],
          ),
          const SizedBox(height: 23.66),

          // Title text
          SizedBox(
            height: 48,
            width: 312,
            child: Text(
              textAlign: TextAlign.center,
              isIntro1 ? "Discover" : "Join Our Community",
              style: TextStyleService.getDmSans(
                fontSize: 32,
                fontWeight: FontWeight.w600,
                height: 1.5,
                color: const Color(0xFF000000), // ส่งสีดำ
              ),
            ),
          ),
          const SizedBox(height: 8.0),

          // Description text
          SizedBox(
            height: 54,
            width: 312,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0.0),
              child: Text(
                isIntro1
                    ? "Easily find international scholarships that match\n your needs and abilities, and get prepared for\n studying abroad with trusted information."
                    : "Share experiences and learn from peers who have gone through scholarship applications and studying abroad. Build a strong educational network with the support of our community.",
                textAlign: TextAlign.center,
                style: TextStyleService.getDmSans(
                  color: Color(0xFF465468),
                  fontSize: 14,
                  fontWeight: FontWeight.w200,
                  height: 1,
                ),
              ),
            ),
          ),
          const SizedBox(height: 48.34),

          // Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                FractionallySizedBox(
                  widthFactor: 1,
                  child: ElevatedButton(
                    onPressed: _onNextPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3056E6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: const Text(
                      'Next',
                      style: TextStyle(
                        fontFamily: "DM Sans",
                        color: Color(0xFFFFFFFF),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 7.66),
                FractionallySizedBox(
                  widthFactor: 1,
                  child: OutlinedButton(
                    onPressed: _onSkipOrBack,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: Color(0xFFC0CDFF),
                        width: 1.0,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: const Color(0xFFFFFFFF),
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: Text(
                      isIntro1 ? 'Skip' : 'Back',
                      style: const TextStyle(
                        fontFamily: "DM Sans",
                        color: Color(0xFF0E1729),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicator({required bool isActive}) {
    return Container(
      width: 29,
      height: 8,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF3056E6) : const Color(0xFFD9D9D9),
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}
