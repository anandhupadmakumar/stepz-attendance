import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'theme_controller.dart';

class PremiumBackground extends StatelessWidget {
  final Widget child;
  const PremiumBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    return Obx(() {
      return Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(themeController.currentBgImage),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF040A18).withValues(alpha: 0.75),
                const Color(0xFF070F24).withValues(alpha: 0.96),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: child,
        ),
      );
    });
  }
}
