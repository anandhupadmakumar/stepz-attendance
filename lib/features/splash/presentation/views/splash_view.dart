import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/premium_background.dart';
import '../../../../core/utils/mesh_grid_wave_painter.dart';
import '../controllers/splash_controller.dart';

class SplashView extends GetView<SplashController> {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    return PremiumBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // Custom painted glowing mesh grid wave at the bottom
            Positioned.fill(child: CustomPaint(painter: MeshGridWavePainter())),

            // Main contents layout
            SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(), // Spacer top
                    // Centered Brand Logo & Typography Details
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // High-resolution corporate logo
                        Image.asset(
                          AppAssets.logoPng,
                          width: 120.w,
                          fit: BoxFit.contain,
                        ),
                        SizedBox(height: 16.h),

                        // Professional tagline
                        Text(
                          'Smart Attendance\nManagement',
                          style: GoogleFonts.inter(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withOpacity(0.95),
                            letterSpacing: 0.2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 12.h),

                        // Glowing accent indicator bar
                        Container(
                          width: 45.w,
                          height: 3.h,
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6),
                            borderRadius: BorderRadius.circular(1.5.r),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF3B82F6).withOpacity(0.8),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 24.h),

                        // Enterprise footer label
                        Text(
                          'POWERING ENTERPRISE PRODUCTIVITY',
                          style: GoogleFonts.inter(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withOpacity(0.55),
                            letterSpacing: 2.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),

                    // Bottom Loader & Version info
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Simulated progress line (Glowing Blue matching theme)
                        Obx(
                          () => Container(
                            width: double.infinity,
                            height: 4.h,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(100.r),
                            ),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: controller.progress.value,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF3B82F6),
                                  borderRadius: BorderRadius.circular(100.r),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF3B82F6,
                                      ).withOpacity(0.6),
                                      blurRadius: 10,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 24.h),

                        // Version string
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Workforce Pro v2.0',
                            style: GoogleFonts.inter(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w400,
                              color: Colors.white.withOpacity(0.5),
                              letterSpacing: 0,
                              height: 14 / 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
