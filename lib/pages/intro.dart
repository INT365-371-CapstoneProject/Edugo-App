import 'package:edugo/pages/provider_or_user.dart';
import 'package:flutter/material.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  _IntroScreenState createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  bool isIntro1 = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Logo at the top
          SizedBox(
            width: 175,
            height: 37.656,
            child: Image.asset(
              "assets/images/logoColor.png",
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 20.0), // Space between logo and text

          // Placeholder for the main image
          SizedBox(
            height: 300,
            width: 200,
            child: Transform.scale(
              scale: 1.5,
              child: Image.asset(isIntro1
                  ? "assets/images/intro1.png"
                  : "assets/images/intro2.png"),
            ),
          ),
          const SizedBox(height: 30.0),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 29,
                height: 8,
                decoration: BoxDecoration(
                  color: isIntro1
                      ? const Color(0xFF3056E6)
                      : const Color(0xFFD9D9D9),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(width: 5),
              Container(
                width: 29,
                height: 8,
                decoration: BoxDecoration(
                  color: isIntro1
                      ? const Color(0xFFD9D9D9)
                      : const Color(0xFF3056E6),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),

          // Title text
          Text(
            isIntro1 ? "Display" : "Join Our Community",
            style: const TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10.0),

          // Description text
          SizedBox(
            height: 72,
            width: 312,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Text(
                isIntro1
                    ? "Easily find international scholarships that match your needs and abilities, and get prepared for studying abroad with trusted information."
                    : "Share experiences and learn from peers who have gone through scholarship applications and studying abroad. Build a strong educational network with the support of our community.",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 14,
                  fontStyle: FontStyle.normal,
                  fontWeight: FontWeight.w200,
                  color: Color(0xFF465468),
                  height: 1.0,
                ),
              ),
            ),
          ),
          const SizedBox(height: 40.0),

          // Button Row
          Column(
            children: [
              FractionallySizedBox(
                widthFactor: 0.94,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      if (isIntro1) {
                        setState(() {
                          isIntro1 = false;
                        });
                      } else {
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder:
                                (context, animation, secondaryAnimation) =>
                                    const ProviderOrUser(),
                            transitionsBuilder: (context, animation,
                                secondaryAnimation, child) {
                              const begin = 0.0;
                              const end = 1.0;
                              const curve = Curves.easeOut;

                              var tween = Tween(begin: begin, end: end)
                                  .chain(CurveTween(curve: curve));
                              return FadeTransition(
                                opacity: animation.drive(tween),
                                child: child,
                              );
                            },
                            transitionDuration:
                                const Duration(milliseconds: 300),
                          ),
                        );
                      }
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3056E6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: const Text(
                    'Next',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10.0),

              // Skip/Back button
              FractionallySizedBox(
                widthFactor: 0.94,
                child: OutlinedButton(
                  onPressed: () {
                    // Set intro to true when Back is pressed
                    setState(() {
                      if (isIntro1) {
                        setState(() {
                          Navigator.push(
                            context,
                            PageRouteBuilder(
                              pageBuilder:
                                  (context, animation, secondaryAnimation) =>
                                      const ProviderOrUser(),
                              transitionsBuilder: (context, animation,
                                  secondaryAnimation, child) {
                                const begin = 0.0;
                                const end = 1.0;
                                const curve = Curves.easeOut;

                                var tween = Tween(begin: begin, end: end)
                                    .chain(CurveTween(curve: curve));
                                return FadeTransition(
                                  opacity: animation.drive(tween),
                                  child: child,
                                );
                              },
                              transitionDuration:
                                  const Duration(milliseconds: 300),
                            ),
                          );
                        });
                      } else {
                        isIntro1 = true;
                      }
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                      color: Color(0xFF3056E6),
                      width: 0.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: Text(
                    isIntro1 ? 'Skip' : 'Back',
                    style: const TextStyle(
                      fontSize: 18,
                      color: Color(0xFF3056E6),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
