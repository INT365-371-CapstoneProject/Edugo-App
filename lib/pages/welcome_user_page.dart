import 'package:edugo/features/login&register/login.dart';
import 'package:edugo/features/login&register/register.dart';
import 'package:edugo/pages/provider_or_user.dart';
import 'package:edugo/shared/utils/customBackButton.dart';
import 'package:edugo/shared/utils/textStyle.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
  final isFirstTime = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF), // กำหนด Background เป็นสีขาว
      body: Stack(
        children: [
          SingleChildScrollView(
            // Wrap the Column with SingleChildScrollView
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 111), // Space at the top
                // Logo
                SizedBox(
                  width: 175,
                  height: 37.656,
                  child: Image.asset(
                    "assets/images/logoColor.png",
                    fit: BoxFit.contain,
                  ),
                ),

                const SizedBox(height: 52.34), // cf : 52

                // Illustration
                Center(
                  child: Image.asset('assets/images/welcome.png',
                      height: 256, width: 286),
                ),

                const SizedBox(height: 40.47), // cf : 40

                // Title and Description centered, text left-aligned
                Center(
                  child: FractionallySizedBox(
                    child: Padding(
                      padding: EdgeInsets.only(left: 25, right: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Let's Get Started!",
                            style: TextStyleService.getDmSans(
                              fontSize: 24.0,
                              fontWeight: FontWeight.w600,
                              height: 1.33333,
                              color: const Color(0xFF000000),
                            ),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Welcome to EDUGO! Discover valuable educational\ninformation and opportunities. Register for access to\nreliable scholarships and resources. Join our community\nto uncover new knowledge and opportunities!',
                            textAlign: TextAlign.left,
                            style: TextStyleService.getDmSans(
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
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          height: 48,
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                PageRouteBuilder(
                                  transitionDuration: Duration(
                                      milliseconds: 350), // ตั้ง 400ms ตรงนี้
                                  pageBuilder: (context, animation,
                                          secondaryAnimation) =>
                                      Login(),
                                  transitionsBuilder: (context, animation,
                                      secondaryAnimation, child) {
                                    return CupertinoPageTransition(
                                      primaryRouteAnimation: animation,
                                      secondaryRouteAnimation:
                                          secondaryAnimation,
                                      linearTransition: true,
                                      child: child,
                                    );
                                  },
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
                            child: Text(
                              'Login',
                              style: TextStyleService.getDmSans(
                                fontSize: 14,
                                color: Color(0xFFFFFFFF),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12), // cd : 8
                        SizedBox(
                          height: 48,
                          child: OutlinedButton(
                            onPressed: () {
                              if (widget.isProvider) {
                                Navigator.push(
                                  context,
                                  PageRouteBuilder(
                                    transitionDuration: Duration(
                                        milliseconds: 350), // ตั้ง 400ms ตรงนี้
                                    pageBuilder: (context, animation,
                                            secondaryAnimation) =>
                                        Register(
                                      isProvider: true,
                                    ),
                                    transitionsBuilder: (context, animation,
                                        secondaryAnimation, child) {
                                      return CupertinoPageTransition(
                                        primaryRouteAnimation: animation,
                                        secondaryRouteAnimation:
                                            secondaryAnimation,
                                        linearTransition: true,
                                        child: child,
                                      );
                                    },
                                  ),
                                );
                              } else {
                                Navigator.push(
                                  context,
                                  PageRouteBuilder(
                                    transitionDuration: Duration(
                                        milliseconds: 350), // ตั้ง 400ms ตรงนี้
                                    pageBuilder: (context, animation,
                                            secondaryAnimation) =>
                                        Register(
                                      isUser: true,
                                    ),
                                    transitionsBuilder: (context, animation,
                                        secondaryAnimation, child) {
                                      return CupertinoPageTransition(
                                        primaryRouteAnimation: animation,
                                        secondaryRouteAnimation:
                                            secondaryAnimation,
                                        linearTransition: true,
                                        child: child,
                                      );
                                    },
                                  ),
                                );
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              backgroundColor: const Color(0xFFFFFFFF),
                              side: const BorderSide(
                                color: Color(0xFFC0CDFF),
                                width: 1.0,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              minimumSize: const Size.fromHeight(48),
                            ),
                            child: Text(
                              'Register',
                              style: TextStyleService.getDmSans(
                                fontSize: 14,
                                color: Color(0xFF0E1729),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 20), // Add some padding at the bottom
              ],
            ),
          ),
          CustomBackButton(),
        ],
      ),
    );
  }
}
