import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stepz_attendance/core/theme/premium_background.dart';
import '../controllers/add_employee_controller.dart';

class AddEmployeeView extends GetView<AddEmployeeController> {
  const AddEmployeeView({super.key});

  @override
  Widget build(BuildContext context) {
    final List<String> designations = [
      'Software Engineer',
      'Digital Marketing Executive',
      'Graphic Designer',
      'Content Writer',
      'HR Executive',
      'Team Lead',
    ];

    final List<String> statuses = ['Present', 'WFH', 'Absent'];
    final List<String> roles = ['Employee', 'Admin'];

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
          title: Text(
            'Onboard Employee',
            style: GoogleFonts.inter(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
            child: Form(
              key: controller.formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Form Header / Tagline
                  Text(
                    'Create Employee Profile',
                    style: GoogleFonts.inter(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'Fill in the fields below to register and auto-provision the user account.',
                    style: GoogleFonts.inter(
                      fontSize: 13.sp,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                  SizedBox(height: 24.h),

                  // Card container for form inputs (Glass card)
                  Container(
                    padding: EdgeInsets.all(20.w),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.12),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Employee ID (Read Only / Sequential)
                        Text(
                          'Employee ID (Auto-Generated)',
                          style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        TextFormField(
                          controller: controller.idController,
                          readOnly: true,
                          enabled: false,
                          style: GoogleFonts.inter(
                            fontSize: 15.sp,
                            color: const Color(0xFF64748B),
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: InputDecoration(
                            prefixIcon: const Icon(
                              Icons.badge_outlined,
                              color: Color(0xFF64748B),
                            ),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.02),
                            border: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.white.withOpacity(0.08),
                              ),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            disabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.white.withOpacity(0.04),
                              ),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                          ),
                        ),
                        SizedBox(height: 16.h),

                        // Full Name
                        Text(
                          'Full Name',
                          style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        TextFormField(
                          controller: controller.nameController,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                          style: GoogleFonts.inter(
                            fontSize: 15.sp,
                            color: Colors.white,
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Please enter the employee\'s full name';
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            hintText: 'e.g. John Doe',
                            hintStyle: GoogleFonts.inter(
                              color: const Color(0xFF64748B),
                            ),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.02),
                            prefixIcon: const Icon(
                              Icons.person_outline,
                              color: Color(0xFF3B82F6),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.white.withOpacity(0.12),
                              ),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                color: Color(0xFF3B82F6),
                              ),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            border: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.white.withOpacity(0.12),
                              ),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                          ),
                        ),
                        SizedBox(height: 16.h),

                        // Email Address
                        Text(
                          'Email Address',
                          style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        TextFormField(
                          controller: controller.emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          style: GoogleFonts.inter(
                            fontSize: 15.sp,
                            color: Colors.white,
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Please enter the email address';
                            }
                            final emailRegex = RegExp(
                              r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                            );
                            if (!emailRegex.hasMatch(val.trim())) {
                              return 'Please enter a valid email address';
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            hintText: 'e.g. employee@company.com',
                            hintStyle: GoogleFonts.inter(
                              color: const Color(0xFF64748B),
                            ),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.02),
                            prefixIcon: const Icon(
                              Icons.email_outlined,
                              color: Color(0xFF3B82F6),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.white.withOpacity(0.12),
                              ),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                color: Color(0xFF3B82F6),
                              ),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            border: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.white.withOpacity(0.12),
                              ),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                          ),
                        ),
                        SizedBox(height: 16.h),

                        // Password
                        Text(
                          'Password',
                          style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Obx(
                          () => TextFormField(
                            controller: controller.passwordController,
                            obscureText: controller.isPasswordObscured.value,
                            textInputAction: TextInputAction.next,
                            style: GoogleFonts.inter(
                              fontSize: 15.sp,
                              color: Colors.white,
                            ),
                            validator: (val) {
                              if (val == null || val.isEmpty) {
                                return 'Please enter a password';
                              }
                              if (val.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                            decoration: InputDecoration(
                              hintText: 'Enter password',
                              hintStyle: GoogleFonts.inter(
                                color: const Color(0xFF64748B),
                              ),
                               filled: true,
                            fillColor: Colors.white.withOpacity(0.02),
                              prefixIcon: const Icon(
                                Icons.lock_outline,
                                color: Color(0xFF3B82F6),
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  controller.isPasswordObscured.value
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: const Color(0xFF64748B),
                                ),
                                onPressed: controller.togglePasswordObscured,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.white.withOpacity(0.12),
                                ),
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: const BorderSide(
                                  color: Color(0xFF3B82F6),
                                ),
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              border: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.white.withOpacity(0.12),
                                ),
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 16.h),

                        // Confirm Password
                        Text(
                          'Confirm Password',
                          style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Obx(
                          () => TextFormField(
                            controller: controller.confirmPasswordController,
                            obscureText:
                                controller.isConfirmPasswordObscured.value,
                            textInputAction: TextInputAction.done,
                            style: GoogleFonts.inter(
                              fontSize: 15.sp,
                              color: Colors.white,
                            ),
                            validator: (val) {
                              if (val == null || val.isEmpty) {
                                return 'Please confirm password';
                              }
                              if (val != controller.passwordController.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                            decoration: InputDecoration(
                              hintText: 'Confirm password',
                              hintStyle: GoogleFonts.inter(
                                color: const Color(0xFF64748B),
                              ),

                               filled: true,
                            fillColor: Colors.white.withOpacity(0.02),
                              prefixIcon: const Icon(
                                Icons.lock_outline,
                                color: Color(0xFF3B82F6),
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  controller.isConfirmPasswordObscured.value
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: const Color(0xFF64748B),
                                ),
                                onPressed:
                                    controller.toggleConfirmPasswordObscured,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.white.withOpacity(0.12),
                                ),
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: const BorderSide(
                                  color: Color(0xFF3B82F6),
                                ),
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              border: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.white.withOpacity(0.12),
                                ),
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 16.h),

                        // Date of Birth
                        Text(
                          'Date of Birth',
                          style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        TextFormField(
                          controller: controller.dobController,
                          readOnly: true,
                          style: GoogleFonts.inter(
                            fontSize: 15.sp,
                            color: Colors.white,
                          ),
                          onTap: () async {
                            final DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now().subtract(
                                const Duration(days: 365 * 22),
                              ),
                              firstDate: DateTime(1950),
                              lastDate: DateTime.now(),
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: const ColorScheme.dark(
                                      primary: Color(0xFF3B82F6),
                                      onPrimary: Colors.white,
                                      surface: Color(0xFF1E1B30),
                                      onSurface: Colors.white,
                                    ),
                                    dialogBackgroundColor: const Color(
                                      0xFF0F172A,
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (picked != null) {
                              final formatted =
                                  "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                              controller.dobController.text = formatted;
                            }
                          },
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Please select a Date of Birth';
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            hintText: 'YYYY-MM-DD',
                            hintStyle: GoogleFonts.inter(
                              color: const Color(0xFF64748B),
                            ),
                             filled: true,
                            fillColor: Colors.white.withOpacity(0.02),
                            prefixIcon: const Icon(
                              Icons.cake_outlined,
                              color: Color(0xFF3B82F6),
                            ),
                            suffixIcon: const Icon(
                              Icons.calendar_today_outlined,
                              color: Color(0xFF64748B),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.white.withOpacity(0.12),
                              ),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                color: Color(0xFF3B82F6),
                              ),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            border: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.white.withOpacity(0.12),
                              ),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                          ),
                        ),
                        SizedBox(height: 16.h),

                        // Designation
                        Text(
                          'Designation',
                          style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Obx(
                          () => DropdownButtonFormField<String>(
                            initialValue: controller.selectedDesignation.value,
                            dropdownColor: const Color(0xFF1E1B30),
                            isExpanded: true,
                            onChanged: (val) {
                              if (val != null) {
                                controller.selectedDesignation.value = val;
                              }
                            },
                            
                            decoration: InputDecoration(
                               filled: true,
                            fillColor: Colors.white.withOpacity(0.02),
                              prefixIcon: const Icon(
                                Icons.work_outline,
                                color: Color(0xFF3B82F6),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.white.withOpacity(0.12),
                                ),
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: const BorderSide(
                                  color: Color(0xFF3B82F6),
                                ),
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              border: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.white.withOpacity(0.12),
                                ),
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                            ),
                            
                            style: GoogleFonts.inter(
                              fontSize: 15.sp,
                              color: Colors.white,
                            ),
                            items: designations.map((designation) {
                              return DropdownMenuItem(
                                value: designation,
                                child: Text(
                                  designation,
                                  style: GoogleFonts.inter(
                                    fontSize: 15.sp,
                                    color: Colors.white,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        SizedBox(height: 16.h),

                        // Workplace Status
                        Text(
                          'Workplace Status',
                          style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Obx(
                          () => DropdownButtonFormField<String>(
                            initialValue: controller.selectedStatus.value,
                            dropdownColor: const Color(0xFF1E1B30),
                            isExpanded: true,
                            onChanged: (val) {
                              if (val != null) {
                                controller.selectedStatus.value = val;
                              }
                            },
                            decoration: InputDecoration(
                               filled: true,
                            fillColor: Colors.white.withOpacity(0.02),
                              prefixIcon: const Icon(
                                Icons.check_circle_outline,
                                color: Color(0xFF3B82F6),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.white.withOpacity(0.12),
                                ),
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: const BorderSide(
                                  color: Color(0xFF3B82F6),
                                ),
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              border: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.white.withOpacity(0.12),
                                ),
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                            ),
                            style: GoogleFonts.inter(
                              fontSize: 15.sp,
                              color: Colors.white,
                            ),
                            items: statuses.map((status) {
                              return DropdownMenuItem(
                                value: status,
                                child: Text(
                                  status,
                                  style: GoogleFonts.inter(
                                    fontSize: 15.sp,
                                    color: Colors.white,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        SizedBox(height: 16.h),

                        // System Role
                        Text(
                          'System Role',
                          style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Obx(
                          () => DropdownButtonFormField<String>(
                            initialValue: controller.selectedRole.value,
                            dropdownColor: const Color(0xFF1E1B30),
                            isExpanded: true,
                            onChanged: (val) {
                              if (val != null) {
                                controller.selectedRole.value = val;
                              }
                            },
                            decoration: InputDecoration(
                               filled: true,
                            fillColor: Colors.white.withOpacity(0.02),
                              prefixIcon: const Icon(
                                Icons.admin_panel_settings_outlined,
                                color: Color(0xFF3B82F6),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.white.withOpacity(0.12),
                                ),
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: const BorderSide(
                                  color: Color(0xFF3B82F6),
                                ),
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              border: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.white.withOpacity(0.12),
                                ),
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                            ),
                            style: GoogleFonts.inter(
                              fontSize: 15.sp,
                              color: Colors.white,
                            ),
                            items: roles.map((role) {
                              return DropdownMenuItem(
                                value: role,
                                child: Text(
                                  role,
                                  style: GoogleFonts.inter(
                                    fontSize: 15.sp,
                                    color: Colors.white,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 32.h),

                  // Actions Section
                  Obx(
                    () => controller.isLoading.value
                        ? const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF3B82F6),
                              ),
                            ),
                          )
                        : Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    padding: EdgeInsets.symmetric(
                                      vertical: 16.h,
                                    ),
                                    side: BorderSide(
                                      color: Colors.white.withOpacity(0.2),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8.r),
                                    ),
                                  ),
                                  onPressed: () => Get.back(),
                                  child: Text(
                                    'Cancel',
                                    style: GoogleFonts.inter(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Container(
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
                                    borderRadius: BorderRadius.circular(8.r),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(
                                          0xFF3B82F6,
                                        ).withOpacity(0.24),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      padding: EdgeInsets.symmetric(
                                        vertical: 16.h,
                                      ),
                                    ),
                                    onPressed: controller.submitForm,
                                    child: Text(
                                      'Save Employee',
                                      style: GoogleFonts.inter(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                  SizedBox(height: 24.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
