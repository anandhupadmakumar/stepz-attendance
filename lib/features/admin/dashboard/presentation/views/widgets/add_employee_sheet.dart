import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stepz_attendance/core/constants/app_sizes.dart';
import 'package:stepz_attendance/features/admin/dashboard/presentation/controllers/admin_dashboard_controller.dart';

class AddEmployeeSheet extends StatefulWidget {
  const AddEmployeeSheet({super.key});

  @override
  State<AddEmployeeSheet> createState() => _AddEmployeeSheetState();
}

class _AddEmployeeSheetState extends State<AddEmployeeSheet> {
  final _formKey = GlobalKey<FormState>();
  final _controller = Get.find<AdminDashboardController>();

  // Input Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _idController = TextEditingController();
  final _dobController = TextEditingController();

  bool _isPasswordObscured = true;

  // Selected Dropdown values
  String _selectedDesignation = 'Software Engineer';
  String _selectedStatus = 'Present';
  String _selectedRole = 'Employee';

  final List<String> _designations = [
    'Software Engineer',
    'Senior Developer',
    'Lead UX Designer',
    'UX Designer',
    'Product Manager',
    'Product Owner',
    'Account Manager',
    'Operations Lead',
    'Finance Analyst',
    'HR Manager',
  ];

  final List<String> _statuses = ['Present', 'WFH', 'Absent'];
  final List<String> _roles = ['Employee', 'Admin'];

  @override
  void initState() {
    super.initState();
    _autoGenerateEmployeeId();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _idController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  void _autoGenerateEmployeeId() {
    final random = Random();
    final num = random.nextInt(9000) + 1000; // 4 digit number
    _idController.text = 'EMP-$num';
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await _controller.saveEmployee(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      employeeId: _idController.text.trim(),
      designation: _selectedDesignation,
      status: _selectedStatus.toLowerCase(),
      role: _selectedRole.toLowerCase(),
      dob: _dobController.text.trim(),
    );

    if (success) {
      Get.back(); // close bottom sheet
    }
  }

  @override
  Widget build(BuildContext context) {
    // Scaffold/Sheet wrapper with nice rounding
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      padding: EdgeInsets.only(
        left: 24.w,
        right: 24.w,
        top: 20.h,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24.h,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Grab Indicator
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCCC3D6),
                    borderRadius: BorderRadius.circular(100.r),
                  ),
                ),
              ),
              SizedBox(height: 16.h),

              // 2. Sheet Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Add New Employee',
                      style: GoogleFonts.inter(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1C1B1B),
                        letterSpacing: -0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFF4A4453)),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
              const Divider(color: Color(0xFFF0EDEC)),
              SizedBox(height: 16.h),

              // 3. Name Input
              Text(
                'Full Name',
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF4A4453),
                ),
              ),
              SizedBox(height: 4.h),
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                style: GoogleFonts.inter(fontSize: 15.sp, color: const Color(0xFF1C1B1B)),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter the employee\'s full name';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  hintText: 'e.g. John Doe',
                  hintStyle: GoogleFonts.inter(color: const Color(0xFFCCC3D6)),
                  prefixIcon: const Icon(Icons.person_outline),
                ),
              ),
              SizedBox(height: 16.h),

              // 4. Email Input
              Text(
                'Email Address',
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF4A4453),
                ),
              ),
              SizedBox(height: 4.h),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                style: GoogleFonts.inter(fontSize: 15.sp, color: const Color(0xFF1C1B1B)),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter the email address';
                  }
                  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                  if (!emailRegex.hasMatch(val.trim())) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  hintText: 'e.g. employee@company.com',
                  hintStyle: GoogleFonts.inter(color: const Color(0xFFCCC3D6)),
                  prefixIcon: const Icon(Icons.email_outlined),
                ),
              ),
              SizedBox(height: 16.h),

              // Password Input
              Text(
                'Password',
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF4A4453),
                ),
              ),
              SizedBox(height: 4.h),
              TextFormField(
                controller: _passwordController,
                obscureText: _isPasswordObscured,
                textInputAction: TextInputAction.next,
                style: GoogleFonts.inter(fontSize: 15.sp, color: const Color(0xFF1C1B1B)),
                validator: (val) {
                  if (val == null || val.isEmpty) {
                    return 'Please enter a password for the employee';
                  }
                  if (val.length < 6) {
                    return 'Password must be at least 6 characters long';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  hintText: 'Enter password (min 6 characters)',
                  hintStyle: GoogleFonts.inter(color: const Color(0xFFCCC3D6)),
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordObscured ? Icons.visibility_off : Icons.visibility,
                      color: const Color(0xFF7B7485),
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordObscured = !_isPasswordObscured;
                      });
                    },
                  ),
                ),
              ),
              SizedBox(height: 16.h),

              // 5. Employee ID Input with Generate button
              Text(
                'Employee ID',
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF4A4453),
                ),
              ),
              SizedBox(height: 4.h),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _idController,
                      textCapitalization: TextCapitalization.characters,
                      style: GoogleFonts.inter(fontSize: 15.sp, color: const Color(0xFF1C1B1B)),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Please specify the Employee ID';
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        hintText: 'e.g. EMP-1024',
                        hintStyle: GoogleFonts.inter(color: const Color(0xFFCCC3D6)),
                        prefixIcon: const Icon(Icons.badge_outlined),
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
                      side: const BorderSide(color: Color(0xFFCCC3D6)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.r8)),
                      backgroundColor: const Color(0xFFFCF9F8),
                    ),
                    icon: const Icon(Icons.refresh, size: 14, color: Color(0xFF420093)),
                    label: Text(
                      'Auto',
                      style: GoogleFonts.inter(fontSize: 12.sp, fontWeight: FontWeight.bold, color: const Color(0xFF420093)),
                    ),
                    onPressed: _autoGenerateEmployeeId,
                  ),
                ],
              ),
              SizedBox(height: 16.h),

              // Date of Birth
              Text(
                'Date of Birth',
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF4A4453),
                ),
              ),
              SizedBox(height: 4.h),
              TextFormField(
                controller: _dobController,
                readOnly: true,
                style: GoogleFonts.inter(fontSize: 15.sp, color: const Color(0xFF1C1B1B)),
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().subtract(const Duration(days: 365 * 22)),
                    firstDate: DateTime(1950),
                    lastDate: DateTime.now(),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.light(
                            primary: Color(0xFF420093),
                            onPrimary: Colors.white,
                            onSurface: Color(0xFF1C1B1B),
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null) {
                    final formatted = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                    setState(() {
                      _dobController.text = formatted;
                    });
                  }
                },
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please select a Date of Birth';
                  }
                  return null;
                },
                decoration: const InputDecoration(
                  hintText: 'YYYY-MM-DD',
                  prefixIcon: Icon(Icons.cake_outlined),
                  suffixIcon: Icon(Icons.calendar_today_outlined),
                ),
              ),
              SizedBox(height: 16.h),

              // 6. Designation Dropdown
              Text(
                'Designation',
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF4A4453),
                ),
              ),
              SizedBox(height: 4.h),
              DropdownButtonFormField<String>(
                value: _selectedDesignation,
                isExpanded: true,
                onChanged: (val) {
                  if (val != null) setState(() => _selectedDesignation = val);
                },
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.work_outline),
                ),
                style: GoogleFonts.inter(fontSize: 15.sp, color: const Color(0xFF1C1B1B)),
                items: _designations.map((designation) {
                  return DropdownMenuItem(
                    value: designation,
                    child: Text(designation),
                  );
                }).toList(),
              ),
              SizedBox(height: 16.h),

              // 7. Workplace Status Dropdown
              Text(
                'Workplace Status',
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF4A4453),
                ),
              ),
              SizedBox(height: 4.h),
              DropdownButtonFormField<String>(
                value: _selectedStatus,
                isExpanded: true,
                onChanged: (val) {
                  if (val != null) setState(() => _selectedStatus = val);
                },
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.check_circle_outline),
                ),
                style: GoogleFonts.inter(fontSize: 15.sp, color: const Color(0xFF1C1B1B)),
                items: _statuses.map((status) {
                  return DropdownMenuItem(
                    value: status,
                    child: Text(status),
                  );
                }).toList(),
              ),
              SizedBox(height: 16.h),

              // System Role Dropdown
              Text(
                'System Role',
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF4A4453),
                ),
              ),
              SizedBox(height: 4.h),
              DropdownButtonFormField<String>(
                value: _selectedRole,
                isExpanded: true,
                onChanged: (val) {
                  if (val != null) setState(() => _selectedRole = val);
                },
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.admin_panel_settings_outlined),
                ),
                style: GoogleFonts.inter(fontSize: 15.sp, color: const Color(0xFF1C1B1B)),
                items: _roles.map((role) {
                  return DropdownMenuItem(
                    value: role,
                    child: Text(role),
                  );
                }).toList(),
              ),
              SizedBox(height: 32.h),

              // 8. Actions Buttons
              Obx(
                () => _controller.isLoadingEmployees.value
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF420093)),
                        ),
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 14.h),
                                side: const BorderSide(color: Color(0xFFCCC3D6)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.r8)),
                              ),
                              onPressed: () => Get.back(),
                              child: Text(
                                'Cancel',
                                style: GoogleFonts.inter(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF4A4453),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF420093), Color(0xFF4E45D5)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(AppSizes.r8),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF420093).withOpacity(0.24),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  padding: EdgeInsets.symmetric(vertical: 14.h),
                                ),
                                onPressed: _submitForm,
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
              SizedBox(height: 16.h),
            ],
          ),
        ),
      ),
    );
  }
}
