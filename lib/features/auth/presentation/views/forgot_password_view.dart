import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/premium_background.dart';
import '../controllers/login_controller.dart';

class ForgotPasswordView extends GetView<LoginController> {
  const ForgotPasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    return PremiumBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Get.back(),
          ),
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Brand Logo Area
                  Align(
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        Image.asset(AppAssets.logoPng, width: 150.w, fit: BoxFit.contain),
                        SizedBox(height: 8.h),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // Glassmorphic Password Reset Card
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
                            color: const Color(0xFF3B82F6).withOpacity(0.24),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.4),
                              blurRadius: 24,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Form(
                          key: controller.forgotPasswordFormKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Typography details
                              Text(
                                'Reset Password',
                                style: GoogleFonts.inter(
                                  fontSize: 24.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: -0.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 8.h),
                              Text(
                                'Enter your registered email to receive a password reset link.',
                                style: GoogleFonts.inter(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w400,
                                  color: const Color(0xFF94A3B8),
                                  height: 1.4,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 28.h),

                              // Email Address Field Label
                              Text(
                                'Registered Email',
                                style: GoogleFonts.inter(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              SizedBox(height: 8.h),

                              // Email Input Field
                              Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F172A).withOpacity(0.4),
                                  borderRadius: BorderRadius.circular(12.r),
                                  border: Border.all(
                                    color: const Color(0xFF3B82F6).withOpacity(0.16),
                                    width: 1.2,
                                  ),
                                ),
                                child: TextFormField(
                                  controller: controller.resetEmailController,
                                  validator: controller.validateResetEmail,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) => controller.sendPasswordResetEmail(),
                                  style: GoogleFonts.inter(
                                    fontSize: 14.sp,
                                    color: Colors.white,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'name@company.com',
                                    hintStyle: GoogleFonts.inter(
                                      color: const Color(0xFF64748B),
                                      fontSize: 14.sp,
                                    ),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16.w,
                                      vertical: 14.h,
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.email_outlined,
                                      color: Color(0xFF3B82F6),
                                    ),
                                    border: InputBorder.none,
                                  ),
                                ),
                              ),
                              SizedBox(height: 24.h),

                              // CTA Action Button with Gradient
                              Obx(
                                () => controller.isLoading.value
                                    ? Center(
                                        child: Container(
                                          padding: EdgeInsets.symmetric(vertical: 8.h),
                                          child: const CircularProgressIndicator(
                                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
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
                                          borderRadius: BorderRadius.circular(12.r),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFF3B82F6).withOpacity(0.3),
                                              blurRadius: 16,
                                              offset: const Offset(0, 6),
                                            ),
                                          ],
                                        ),
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.transparent,
                                            shadowColor: Colors.transparent,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12.r),
                                            ),
                                          ),
                                          onPressed: controller.sendPasswordResetEmail,
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                'Send Reset Link',
                                                style: GoogleFonts.inter(
                                                  fontSize: 16.sp,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              SizedBox(width: 8.w),
                                              const Icon(Icons.send_outlined, size: 16, color: Colors.white),
                                            ],
                                          ),
                                        ),
                                      ),
                              ),
                              SizedBox(height: 24.h),

                              // Back to Login Link
                              GestureDetector(
                                onTap: () => Get.back(),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.arrow_back_ios_rounded, size: 12, color: Color(0xFF3B82F6)),
                                    SizedBox(width: 8.w),
                                    Text(
                                      'Back to Login',
                                      style: GoogleFonts.inter(
                                        fontSize: 13.sp,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF3B82F6),
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
                  ),
                  SizedBox(height: 36.h),

                  // Help Area
                  Text(
                    'Having trouble? Contact Support',
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF64748B),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
