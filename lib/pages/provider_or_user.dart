import 'package:edugo/features/login&register/login.dart';
import 'package:edugo/pages/welcome_user_page.dart';
import 'package:flutter/material.dart';

class ProviderOrUser extends StatelessWidget {
  const ProviderOrUser({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Logo at the top
            Padding(
              padding: const EdgeInsets.only(top: 87.0, left: 40.0),
              child: SizedBox(
                width: 175,
                height: 37.656,
                child: Image.asset(
                  "assets/images/logoColor.png",
                  fit: BoxFit.contain, // Adjust the image to fit within the box
                ),
              ),
            ),
            // Add spacing of 50.34px below the logo
            const SizedBox(height: 50.34),
            // Heading text "Tell us who you are?"
            const Padding(
              padding: EdgeInsets.only(
                left: 39.0,
                right: 39.0,
              ), // Align text with the logo
              child: Text(
                "Tell us who you are?",
                style: TextStyle(
                  fontFamily: "DM Sans",
                  fontSize: 32.0,
                  fontWeight: FontWeight.w600,
                  color:
                      Color(0xFF000000), // color: var(--Labels-Primary, #000)
                ),
              ),
            ),
            // Container for the paragraph with 39px margin on both sides
            const Padding(
              padding: EdgeInsets.only(
                  left: 39.0,
                  right: 39.0,
                  top: 8.0), // Apply left and right margins of 39
              child: Text(
                "Tell us a little about yourself! You can easily select your role in this app. If you're a scholarship provider, please choose 'Provider' above. However, if you're looking for educational opportunities and additional experiences, please select 'User' below.",
                style: TextStyle(
                  fontFamily: "DM Sans",
                  fontSize: 14.0,
                  fontWeight: FontWeight.w200,
                  color:
                      Color(0xFF000000), // color: var(--Labels-Primary, #000)
                ),
              ),
            ),
            // Add some spacing between text and buttons
            const SizedBox(height: 40),
            // Button for "I'm providing scholarships"
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: GestureDetector(
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const WelcomeUserPage(isProvider: true),
                    ),
                  );
                },
                child: Container(
                  height: 128, // Set specific height
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.blueAccent),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.center, // Align vertically
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(
                            16.0), // Add padding around image
                        child: Image.asset("assets/images/provider.png"),
                      ),
                      const Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment
                              .center, // Center text vertically
                          crossAxisAlignment: CrossAxisAlignment
                              .start, // Align text to the left
                          children: [
                            Text(
                              "I'm providing scholarships",
                              style: TextStyle(
                                fontFamily: "DM Sans",
                                fontSize: 14.0,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF000000),
                              ),
                            ),
                            SizedBox(
                                height:
                                    8), // Spacing between title and subtitle
                            Text(
                              "For scholarship providers, you can share exciting and valuable scholarship opportunities with users in our app!",
                              style: TextStyle(
                                fontFamily: "DM Sans",
                                fontSize: 11.0,
                                fontWeight: FontWeight.w300,
                                color: Color(0xFF7A7A7A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Add spacing between buttons
            const SizedBox(height: 20),
            // Button for "I'm seeking scholarships"
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: GestureDetector(
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const WelcomeUserPage(isUser: true),
                    ),
                  );
                },
                child: Container(
                  height: 128, // Set specific height
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: const Color.fromARGB(255, 95, 113, 145)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.center, // Align vertically
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(
                            16.0), // Add padding around image
                        child: Image.asset("assets/images/user.png"),
                      ),
                      const Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment
                              .center, // Center text vertically
                          crossAxisAlignment: CrossAxisAlignment
                              .start, // Align text to the left
                          children: [
                            Text(
                              "I'm seeking scholarships",
                              style: TextStyle(
                                fontFamily: "DM Sans",
                                fontSize: 14.0,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF000000),
                              ),
                            ),
                            SizedBox(
                                height:
                                    8), // Spacing between title and subtitle
                            Text(
                              "If you're looking for reliable sources of knowledge and scholarship information, sign up now! Start exploring unlimited learning opportunities today!",
                              style: TextStyle(
                                fontFamily: "DM Sans",
                                fontSize: 11.0,
                                fontWeight: FontWeight.w300,
                                color: Color(0xFF7A7A7A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
