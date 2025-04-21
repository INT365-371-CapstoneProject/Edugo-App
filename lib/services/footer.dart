import 'dart:ui';
import 'package:edugo/features/home/screens/home_screen.dart';
import 'package:edugo/features/scholarship/screens/provider_management.dart';
import 'package:edugo/features/profile/screens/profile.dart';
import 'package:edugo/features/search/screens/search_screen.dart';
import 'package:edugo/features/subject/subject_add_edit.dart';
import 'package:edugo/features/subject/subject_manage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class FooterNav extends StatefulWidget {
  final String pageName;

  const FooterNav({
    super.key,
    required this.pageName,
  });

  @override
  State<FooterNav> createState() => _FooterNavState();
}

class _FooterNavState extends State<FooterNav> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFFFFFF).withOpacity(0.5),
              borderRadius: BorderRadius.circular(32),
            ),
            height: 72,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildIconButton(
                    onTap: () => _navigateTo(context, const HomeScreenApp()),
                    iconPath: 'assets/images/home_icon.png',
                    isSvg: false,
                    isActive: widget.pageName == 'home',
                  ),
                  _buildIconButton(
                    onTap: () => _navigateTo(context, const SearchScreen()),
                    iconPath: 'assets/images/search.svg',
                    isSvg: true,
                    isActive: widget.pageName == 'search',
                  ),
                  SizedBox(
                    height: 32,
                    width: 64,
                    child: ElevatedButton(
                      onPressed: () {
                        _navigateTo(
                            context, const SubjectAddEdit(isEdit: false));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF355FFF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        padding: EdgeInsets.zero,
                        elevation: 0,
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Color(0xFFDAFB59),
                        size: 28,
                      ),
                    ),
                  ),
                  _buildIconButton(
                    onTap: () =>
                        _navigateTo(context, const SubjectManagement()),
                    iconPath: 'assets/images/community_icon.png',
                    isSvg: false,
                    isActive: widget.pageName == 'subject',
                  ),
                  _buildIconButton(
                    onTap: () => _navigateTo(context, const ProviderProfile()),
                    iconPath: 'assets/images/profile_icon.png',
                    isSvg: false,
                    isActive: widget.pageName == 'profile',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _navigateTo(BuildContext context, Widget page) {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = 0.0;
          const end = 1.0;
          const curve = Curves.easeOut;

          var tween =
              Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          return FadeTransition(
            opacity: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  Widget _buildIconButton({
    required VoidCallback onTap,
    required String iconPath,
    required bool isSvg,
    required bool isActive,
  }) {
    return SizedBox(
      height: 27.2,
      width: 26.2,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent, // ไม่มีพื้นหลังขาว
          shape: const CircleBorder(),
          padding: EdgeInsets.zero,
          elevation: 0,
          shadowColor: Colors.transparent,
        ),
        child: isSvg
            ? SvgPicture.asset(
                iconPath,
                fit: BoxFit.cover,
                color: isActive
                    ? const Color(0xffD992FA)
                    : const Color(0xff000000),
              )
            : Image.asset(
                iconPath,
                fit: BoxFit.cover,
                color: isActive
                    ? const Color(0xffD992FA)
                    : const Color(0xff000000),
              ),
      ),
    );
  }
}
