import 'package:edugo/features/question/screens/animation.dart';
import 'package:edugo/shared/utils/textStyle.dart';
import 'package:flutter/material.dart';
import 'package:edugo/features/home/screens/home_screen.dart';
import 'package:flutter_svg/flutter_svg.dart';

class Question extends StatefulWidget {
  const Question({super.key});

  @override
  State<Question> createState() => _QuestionState();
}

class _QuestionState extends State<Question> {
  int currentPage = 0;

  final Map<int, String> countries = {
    9: 'Australia',
    186: 'America',
    31: 'Canada',
    84: 'Japan',
    185: 'UK',
    125: 'New Zealand',
    36: 'China',
    64: 'Germany',
    157: 'Singapore',
    82: 'Italy'
  };

  List<int> selectedCountries = []; // ใช้ List แทน Set
  String? selectedEducation; // เก็บการเลือก Education

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (currentPage == 1) {
          setState(() {
            currentPage = 0; // ย้อนกลับไปที่หน้าประเทศ
          });
          return false; // ป้องกันไม่ให้ปิดหน้า
        }
        return true; // ออกจากหน้าได้ปกติเมื่ออยู่หน้าประเทศ
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      height: 200,
                      color: const Color(0xFF355FFF),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 30),
                          Text(
                            currentPage == 0
                                ? "Which countries are\nyou interested in?"
                                : "Which education level\nare you seeking\na scholarship for?",
                            textAlign: TextAlign.center,
                            style: TextStyleService.getDmSans(
                              color: Colors.white,
                              fontSize: currentPage == 0 ? 32 : 24,
                              fontWeight: FontWeight.w600,
                              height: currentPage == 0 ? 1.5 : 1.2,
                            ),
                          ),
                          SizedBox(height: currentPage == 0 ? 16 : 8),
                          Text(
                            currentPage == 0
                                ? "Pick 3 countries you'd like us to feature for you!"
                                : "Select the one you are most interested in",
                            textAlign: TextAlign.center,
                            style: TextStyleService.getDmSans(
                              color: Colors.white70,
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    currentPage == 0
                        ? buildCountryGrid()
                        : buildEducationList(),
                  ],
                ),
              ),
            ),
            Container(
              width: double.infinity,
              height: 78,
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: ElevatedButton(
                  onPressed: currentPage == 0
                      ? selectedCountries.length >= 1 &&
                              selectedCountries.length <= 3
                          ? () {
                              setState(() {
                                currentPage = 1;
                              });
                            }
                          : null
                      : selectedEducation != null
                          ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AnimationQuestion(
                                    selectedCountries:
                                        selectedCountries, // ส่ง List แทน Set
                                    selectedEducation: selectedEducation,
                                  ),
                                ),
                              );
                            }
                          : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: selectedCountries.length >= 1 &&
                            selectedCountries.length <= 3
                        ? const Color.fromARGB(255, 44, 33, 243)
                        : Colors.grey,
                    minimumSize: const Size(double.infinity, 40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(40),
                    ),
                  ),
                  child: Text(
                    "Next",
                    style: TextStyleService.getDmSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildCountryGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 182 / 97,
      ),
      itemCount: countries.length,
      itemBuilder: (context, index) {
        int countryId = countries.keys.elementAt(index);
        String countryName = countries[countryId]!; // ชื่อประเทศ
        bool isSelected = selectedCountries.contains(countryId);

        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                selectedCountries.remove(countryId); // ลบจาก List
              } else if (selectedCountries.length < 3) {
                selectedCountries.add(countryId); // เพิ่มใน List
              }
            });
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // ภาพพื้นหลัง
                  Positioned.fill(
                      child: Image.asset(
                    'assets/images/${countryName.toLowerCase()}.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey,
                      child: Icon(Icons.flag, color: Colors.white),
                    ),
                  )),
                  // สีพื้นหลังแบบทับ
                  Positioned.fill(
                    child: Container(
                      color: isSelected
                          ? Color.fromARGB(115, 191, 225, 54)
                          : Color.fromARGB(128, 19, 33, 89),
                    ),
                  ),
                  // ข้อความบนพื้นหลัง
                  Center(
                    child: Text(
                      countryName,
                      textAlign: TextAlign.center,
                      style: TextStyleService.getDmSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget buildEducationList() {
    List<Map<String, dynamic>> educationOptions = [
      {
        "title": "Undergraduate",
        "selectedImage": "assets/images/undergraduate_selected.png",
        "unselectedImage": "assets/images/undergraduate_unselected.png",
      },
      {
        "title": "Master",
        "selectedImage": "assets/images/master_selected.png",
        "unselectedImage": "assets/images/master_unselected.png",
      },
      {
        "title": "Doctorate",
        "selectedImage": "assets/images/doctorate_selected.png",
        "unselectedImage": "assets/images/doctorate_unselected.png",
      },
    ];

    return Column(
      children: List.generate(educationOptions.length, (index) {
        final option = educationOptions[index];
        final isSelected = selectedEducation == option['title'];

        return Container(
          height: 172,
          margin: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: index == educationOptions.length - 1 ? 0 : 16,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  isSelected
                      ? option['selectedImage']!
                      : option['unselectedImage']!,
                  fit: BoxFit.cover,
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    setState(() {
                      selectedEducation = isSelected ? null : option['title'];
                    });
                  },
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  void _navigateToHome() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreenApp()),
      (route) => false,
    );
  }
}
