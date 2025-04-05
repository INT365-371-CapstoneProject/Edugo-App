import 'package:edugo/features/question/screens/animation.dart';
import 'package:flutter/material.dart';
import 'package:edugo/features/home/screens/home_screen.dart';

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
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: currentPage == 0 ? 32 : 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: currentPage == 0 ? 16 : 8),
                          Text(
                            currentPage == 0
                                ? "Pick 3 countries you'd like us to feature for you!"
                                : "Select the one you are most interested in",
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
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
                      ? selectedCountries.length == 3
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
                    backgroundColor: selectedCountries.length == 3
                        ? const Color.fromARGB(255, 44, 33, 243)
                        : Colors.grey,
                    minimumSize: const Size(double.infinity, 40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(40),
                    ),
                  ),
                  child: const Text(
                    "Next",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
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
        String countryName = countries[countryId]!;
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
              color: isSelected
                  ? const Color.fromARGB(255, 112, 223, 176)
                  : const Color(0xFF355FFF),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                countryName,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.black : Colors.white,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget buildEducationList() {
    List<Map<String, dynamic>> educationOptions = [
      {"title": "Undergraduate", "icon": Icons.school},
      {"title": "Master", "icon": Icons.workspace_premium},
      {"title": "Doctorate", "icon": Icons.military_tech},
    ];

    return Column(
      children: List.generate(educationOptions.length, (index) {
        bool isSelected = selectedEducation == educationOptions[index]['title'];

        return Container(
          height: 172,
          margin: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom:
                index == educationOptions.length - 1 ? 0 : 16, // เช็คอันสุดท้าย
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color.fromARGB(255, 112, 223, 176)
                : const Color(0xFF355FFF),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListTile(
            leading: Icon(educationOptions[index]['icon'],
                color: Colors.white, size: 30),
            title: Text(
              educationOptions[index]['title'],
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            onTap: () {
              setState(() {
                if (selectedEducation == educationOptions[index]['title']) {
                  // ถ้ากดที่ตัวเลือกเดิมให้ลบออก
                  selectedEducation = null;
                } else {
                  // ถ้ากดเลือกใหม่, ให้เอาอันเก่าออกก่อน
                  selectedEducation = educationOptions[index]['title'];
                }
              });
            },
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
