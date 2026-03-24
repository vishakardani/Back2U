import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();

    return Obx(() {
      final isAdmin = authController.isAdmin.value;
      final activeColor = isAdmin ? const Color(0xFFE11D48) : const Color(0xFF0D9488);

      return Container(
        margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        height: 70,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _navItem(
              index: 0,
              icon: Icons.home_outlined,
              activeIcon: Icons.home,
              activeColor: activeColor,
            ),
            _navItem(
              index: 1,
              icon: Icons.add_circle_outline,
              activeIcon: Icons.add_circle,
              activeColor: activeColor,
            ),
            _navItem(
              index: 2,
              icon: Icons.person_outline,
              activeIcon: Icons.person,
              activeColor: activeColor,
            ),
          ],
        ),
      );
    });
  }

  Widget _navItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required Color activeColor,
  }) {
    final isActive = currentIndex == index;

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isActive
              ? [
            BoxShadow(
              color: activeColor.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ]
              : [],
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, animation) {
            return ScaleTransition(
              scale: animation,
              child: child,
            );
          },
          child: Icon(
            isActive ? activeIcon : icon,
            key: ValueKey(isActive),
            color: isActive ? Colors.white : Colors.grey[600],
            size: 24,
          ),
        ),
      ),
    );
  }
}
