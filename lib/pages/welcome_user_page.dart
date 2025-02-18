import 'package:edugo/features/login&register/login.dart';
import 'package:edugo/features/login&register/register.dart';
import 'package:flutter/material.dart';

// cf = change of Figma : {Scale on figma}

class WelcomeUserPage extends StatefulWidget {
  final bool isProvider;
  final bool isUser;
  const WelcomeUserPage(
      {super.key, this.isProvider = false, this.isUser = false});

  @override
  State<WelcomeUserPage> createState() => _WelcomeUserPageState();
}

class _WelcomeUserPageState extends State<WelcomeUserPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Logo
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 64.0), // cf : 111
                child: SizedBox(
                  width: 175,
                  height: 37.656,
                  child: Image.asset(
                    "assets/images/logoColor.png",
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30), // cf : 52

            // Illustration
            Center(
              child: Image.asset('assets/images/welcome.png',
                  height: 306, width: 296),
            ),

            const SizedBox(height: 25), // cf : 40

            // Title and Description centered, text left-aligned
            const Center(
              child: FractionallySizedBox(
                child: Padding(
                  padding: EdgeInsets.only(left: 15.0), // Add left margin of 10
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Let's Get Started!",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Welcome to EDUGO! Discover valuable educational information and opportunities. Register for access to reliable scholarships and resources. Join our community to uncover new knowledge and opportunities!',
                        textAlign: TextAlign.left,
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 14,
                          fontWeight: FontWeight.w200,
                          color: Color(0xFF465468),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),

            // Buttons
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FractionallySizedBox(
                    widthFactor: 0.98,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder:
                                (context, animation, secondaryAnimation) =>
                                    const Login(),
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
                      },
                      style: OutlinedButton.styleFrom(
                        backgroundColor: const Color(0xFF3056E6),
                        side: const BorderSide(
                          color: Color(0xFF3056E6),
                          width: 0.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        minimumSize: const Size.fromHeight(48),
                      ),
                      child: const Text(
                        'Login',
                        style: TextStyle(
                          fontSize: 18,
                          color: Color(0xFFFFFFFF),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12), // cd : 8
                  FractionallySizedBox(
                    widthFactor: 0.98,
                    child: OutlinedButton(
                      onPressed: () {
                        if (widget.isProvider) {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => Register(
                                        isProvider: true,
                                      )));
                        } else if (widget.isUser) {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => Register(
                                        isUser: true,
                                      )));
                        } else {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => Register()));
                        }
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
                      child: const Text(
                        'Register',
                        style: TextStyle(
                          fontSize: 18,
                          color: Color(0xFF0E1729),
                        ),
                      ),
                    ),
                  ),

                  // "Continue as a Guest" closer to "Register"
                  TextButton(
                    onPressed: () {
                      // Add action for guest access here
                    },
                    child: const Text(
                      'Continue as a Guest',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color:
                            Color(0xFF64738B), // Foundation-Grey-Normal-Active
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
