import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/utils/mesh_grid_wave_painter.dart';
import '../../../../core/theme/premium_background.dart';
import '../controllers/login_controller.dart';

class LoginView extends GetView<LoginController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return PremiumBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // 1. Custom painted glowing mesh grid at the bottom (mocking wave lines)
            Positioned.fill(child: CustomPaint(painter: MeshGridWavePainter())),

            // 2. Main content layout
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(
                    horizontal: 24.w,
                    vertical: 16.h,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Brand Custom Logo Area
                      Center(child: _buildBrandLogo()),
                      // SizedBox(height: 16.h),

                      // Glassmorphic Login Card
                      ClipRRect(
                        borderRadius: BorderRadius.circular(24.r),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 24.w,
                              vertical: 28.h,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F172A).withOpacity(0.55),
                              borderRadius: BorderRadius.circular(24.r),
                              border: Border.all(
                                color: const Color(
                                  0xFF3B82F6,
                                ).withOpacity(0.24),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.4),
                                  blurRadius: 24,
                                  offset: const Offset(0, 10),
                                ),
                                BoxShadow(
                                  color: const Color(
                                    0xFF1E3A8A,
                                  ).withOpacity(0.15),
                                  blurRadius: 16,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Form(
                              key: controller.loginFormKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Welcome back header
                                  Row(
                                    children: [
                                      Container(
                                        width: 44.w,
                                        height: 44.h,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: const Color(
                                            0xFF1E3A8A,
                                          ).withOpacity(0.5),
                                          border: Border.all(
                                            color: const Color(
                                              0xFF3B82F6,
                                            ).withOpacity(0.3),
                                            width: 1.5,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.person_rounded,
                                          color: Color(0xFF3B82F6),
                                          size: 24,
                                        ),
                                      ),
                                      SizedBox(width: 16.w),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Welcome Back',
                                              style: GoogleFonts.inter(
                                                fontSize: 20.sp,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                                letterSpacing: -0.5,
                                              ),
                                            ),
                                            SizedBox(height: 2.h),
                                            Text(
                                              'Sign in to continue to your account',
                                              style: GoogleFonts.inter(
                                                fontSize: 11.5.sp,
                                                fontWeight: FontWeight.w400,
                                                color: const Color(0xFF94A3B8),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 28.h),

                                  // Employee ID Input Field
                                  Container(
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFF0F172A,
                                      ).withOpacity(0.4),
                                      borderRadius: BorderRadius.circular(12.r),
                                      border: Border.all(
                                        color: const Color(
                                          0xFF3B82F6,
                                        ).withOpacity(0.16),
                                        width: 1.2,
                                      ),
                                    ),
                                    child: TextFormField(
                                      controller: controller.emailController,
                                      validator: controller.validateEmail,
                                      keyboardType: TextInputType.emailAddress,
                                      textInputAction: TextInputAction.next,
                                      style: GoogleFonts.inter(
                                        fontSize: 14.sp,
                                        color: Colors.black,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: 'Employee ID / Email',
                                        hintStyle: GoogleFonts.inter(
                                          color: const Color(0xFF64748B),
                                          fontSize: 14.sp,
                                        ),
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 16.w,
                                          vertical: 14.h,
                                        ),
                                        prefixIcon: const Icon(
                                          Icons.person_outline_rounded,
                                          color: Color(0xFF3B82F6),
                                        ),
                                        border: InputBorder.none,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 16.h),

                                  // Password Input Field
                                  Obx(
                                    () => Container(
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFF0F172A,
                                        ).withOpacity(0.4),
                                        borderRadius: BorderRadius.circular(
                                          12.r,
                                        ),
                                        border: Border.all(
                                          color: const Color(
                                            0xFF3B82F6,
                                          ).withOpacity(0.16),
                                          width: 1.2,
                                        ),
                                      ),
                                      child: TextFormField(
                                        controller:
                                            controller.passwordController,
                                        validator: controller.validatePassword,
                                        obscureText:
                                            controller.isPasswordObscured.value,
                                        textInputAction: TextInputAction.done,
                                        onFieldSubmitted: (_) =>
                                            controller.login(),
                                        style: GoogleFonts.inter(
                                          fontSize: 14.sp,
                                          color: Colors.black,
                                        ),
                                        decoration: InputDecoration(
                                          hintText: 'Password',
                                          hintStyle: GoogleFonts.inter(
                                            color: const Color(0xFF64748B),
                                            fontSize: 14.sp,
                                          ),
                                          contentPadding: EdgeInsets.symmetric(
                                            horizontal: 16.w,
                                            vertical: 14.h,
                                          ),
                                          prefixIcon: const Icon(
                                            Icons.lock_outline_rounded,
                                            color: Color(0xFF3B82F6),
                                          ),
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              controller
                                                      .isPasswordObscured
                                                      .value
                                                  ? Icons
                                                        .visibility_off_outlined
                                                  : Icons.visibility_outlined,
                                              color: const Color(0xFF64748B),
                                              size: 20,
                                            ),
                                            onPressed: controller
                                                .togglePasswordVisibility,
                                          ),
                                          border: InputBorder.none,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 20.h),

                                  // Remember Me & Forgot Password Row
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Obx(
                                              () => Theme(
                                                data: ThemeData(
                                                  unselectedWidgetColor:
                                                      const Color(
                                                        0xFF3B82F6,
                                                      ).withOpacity(0.4),
                                                ),
                                                child: SizedBox(
                                                  width: 24.w,
                                                  height: 24.h,
                                                  child: Checkbox(
                                                    value: controller
                                                        .rememberMe
                                                        .value,
                                                    onChanged: controller
                                                        .toggleRememberMe,
                                                    activeColor: const Color(
                                                      0xFF3B82F6,
                                                    ),
                                                    checkColor: Colors.white,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            4.r,
                                                          ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            SizedBox(width: 8.w),
                                            Expanded(
                                              child: Text(
                                                'Remember Me',
                                                style: GoogleFonts.inter(
                                                  fontSize: 12.5.sp,
                                                  fontWeight: FontWeight.w500,
                                                  color: const Color(
                                                    0xFF94A3B8,
                                                  ),
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(width: 8.w),
                                      GestureDetector(
                                        onTap: () =>
                                            Get.toNamed('/forgot-password'),
                                        child: Text(
                                          'Forgot Password?',
                                          style: GoogleFonts.inter(
                                            fontSize: 12.5.sp,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF3B82F6),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 28.h),

                                  // Premium Sign In Button
                                  Obx(
                                    () => controller.isLoading.value
                                        ? Center(
                                            child: Container(
                                              padding: EdgeInsets.symmetric(
                                                vertical: 8.h,
                                              ),
                                              child:
                                                  const CircularProgressIndicator(
                                                    valueColor:
                                                        AlwaysStoppedAnimation<
                                                          Color
                                                        >(Color(0xFF3B82F6)),
                                                  ),
                                            ),
                                          )
                                        : Container(
                                            height: 50.h,
                                            decoration: BoxDecoration(
                                              gradient: const LinearGradient(
                                                colors: [
                                                  Color(0xFF0F52BA),
                                                  Color(0xFF1E3A8A),
                                                  Color(0xFF3B82F6),
                                                ],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(12.r),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: const Color(
                                                    0xFF3B82F6,
                                                  ).withOpacity(0.3),
                                                  blurRadius: 16,
                                                  offset: const Offset(0, 6),
                                                ),
                                              ],
                                            ),
                                            child: ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    Colors.transparent,
                                                shadowColor: Colors.transparent,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        12.r,
                                                      ),
                                                ),
                                              ),
                                              onPressed: controller.login,
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  const SizedBox(width: 20),
                                                  Expanded(
                                                    child: Center(
                                                      child: Text(
                                                        'Sign In',
                                                        style:
                                                            GoogleFonts.inter(
                                                              fontSize: 16.sp,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color:
                                                                  Colors.white,
                                                            ),
                                                      ),
                                                    ),
                                                  ),
                                                  const Icon(
                                                    Icons.arrow_forward_rounded,
                                                    color: Colors.white,
                                                    size: 20,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 36.h),

                      // Bento Grid Bottom Icons (3 items)
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildBentoFeatureCard(
                              Icons.calendar_today_outlined,
                              'Attendance\nTracking',
                            ),
                            _buildBentoFeatureCard(
                              Icons.people_outline_rounded,
                              'Employee\nManagement',
                            ),
                            _buildBentoFeatureCard(
                              Icons.bar_chart_rounded,
                              'Real-time\nReports',
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 36.h),

                      // Powered by Footer
                      Column(
                        children: [
                          Text(
                            'Powered by',
                            style: GoogleFonts.inter(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF64748B),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            'STEPZ INVENTION',
                            style: GoogleFonts.outfit(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF3B82F6),
                              letterSpacing: 2.0,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 6.h),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 30.w,
                                height: 1.h,
                                color: const Color(0xFF3B82F6).withOpacity(0.3),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8.w),
                                child: Text(
                                  'Version 1.0.0',
                                  style: GoogleFonts.inter(
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                              Container(
                                width: 30.w,
                                height: 1.h,
                                color: const Color(0xFF3B82F6).withOpacity(0.3),
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 16.h),
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

  // WIDGET: Brand custom logo generator
  Widget _buildBrandLogo() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(AppAssets.logoPng, width: 170.w, fit: BoxFit.contain),
        SizedBox(height: 8.h),
        Text(
          'Smart Workforce Management',
          style: GoogleFonts.inter(
            fontSize: 15.sp,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 12.h),
        Container(
          width: 40.w,
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
      ],
    );
  }

  // WIDGET: Bento highlight card generator
  Widget _buildBentoFeatureCard(IconData icon, String text) {
    return Expanded(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 6.w),
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 16.h),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A).withOpacity(0.4),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: const Color(0xFF3B82F6).withOpacity(0.12),
            width: 1.2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF1E3A8A).withOpacity(0.25),
                border: Border.all(
                  color: const Color(0xFF3B82F6).withOpacity(0.25),
                  width: 1,
                ),
              ),
              child: Icon(icon, color: const Color(0xFF3B82F6), size: 20.sp),
            ),
            SizedBox(height: 10.h),
            Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 10.5.sp,
                color: Colors.white.withOpacity(0.9),
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
