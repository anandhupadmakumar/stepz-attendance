import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stepz_attendance/core/theme/premium_background.dart';
import '../controllers/admin_dashboard_controller.dart';

class EmployeeDetailsView extends StatefulWidget {
  final EmployeeProfile employee;

  const EmployeeDetailsView({super.key, required this.employee});

  @override
  State<EmployeeDetailsView> createState() => _EmployeeDetailsViewState();
}

class _EmployeeDetailsViewState extends State<EmployeeDetailsView> {
  final AdminDashboardController controller = Get.find<AdminDashboardController>();
  
  bool isEditing = false;
  late TextEditingController nameController;
  late TextEditingController idController;
  late TextEditingController emailController;
  late TextEditingController dobController;
  final formKey = GlobalKey<FormState>();

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

  late String selectedDesignation;
  late String selectedStatus;
  late String selectedRole;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.employee.name);
    idController = TextEditingController(text: widget.employee.id);
    emailController = TextEditingController(text: widget.employee.email);
    dobController = TextEditingController(text: widget.employee.dob);

    selectedDesignation = widget.employee.designation;
    if (!designations.contains(selectedDesignation)) {
      designations.add(selectedDesignation);
    }

    selectedStatus = _capitalize(widget.employee.status);
    if (!statuses.contains(selectedStatus)) {
      statuses.add(selectedStatus);
    }

    selectedRole = _capitalize(widget.employee.role);
    if (!roles.contains(selectedRole)) {
      roles.add(selectedRole);
    }
  }

  String _capitalize(String value) {
    if (value.toLowerCase() == 'wfh') return 'WFH';
    if (value.isEmpty) return '';
    return value[0].toUpperCase() + value.substring(1).toLowerCase();
  }

  @override
  void dispose() {
    nameController.dispose();
    idController.dispose();
    emailController.dispose();
    dobController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final currentEmp = controller.allEmployees.firstWhereOrNull((e) => e.uid == widget.employee.uid) ?? widget.employee;
      
      Color badgeBgColor = const Color(0xFF10B981).withOpacity(0.2);
      Color badgeTextColor = const Color(0xFF34D399);
      Color badgeBorderColor = const Color(0xFF10B981).withOpacity(0.4);
      String statusLabel = 'Present';
      List<Color> avatarGrad = [const Color(0xFF0F52BA), const Color(0xFF1E3A8A)];

      if (currentEmp.status == 'wfh') {
        badgeBgColor = const Color(0xFF3B82F6).withOpacity(0.2);
        badgeTextColor = const Color(0xFF60A5FA);
        badgeBorderColor = const Color(0xFF3B82F6).withOpacity(0.4);
        statusLabel = 'WFH';
        avatarGrad = [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)];
      } else if (currentEmp.status == 'absent') {
        badgeBgColor = const Color(0xFFEF4444).withOpacity(0.2);
        badgeTextColor = const Color(0xFFF87171);
        badgeBorderColor = const Color(0xFFEF4444).withOpacity(0.4);
        statusLabel = 'Absent';
        avatarGrad = [const Color(0xFFEF4444), const Color(0xFFB91C1C)];
      }

      return PremiumBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
              onPressed: () => Get.back(),
            ),
            title: Text(
              isEditing ? 'Edit Profile' : 'Employee Details',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18.sp,
              ),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: Icon(
                  isEditing ? Icons.close_rounded : Icons.edit_rounded,
                  color: isEditing ? const Color(0xFFF87171) : const Color(0xFF3B82F6),
                ),
                onPressed: () {
                  setState(() {
                    isEditing = !isEditing;
                    if (!isEditing) {
                      nameController.text = currentEmp.name;
                      idController.text = currentEmp.id;
                      emailController.text = currentEmp.email;
                      dobController.text = currentEmp.dob;
                      selectedDesignation = currentEmp.designation;
                      if (!designations.contains(selectedDesignation)) {
                        designations.add(selectedDesignation);
                      }
                      selectedStatus = _capitalize(currentEmp.status);
                      if (!statuses.contains(selectedStatus)) {
                        statuses.add(selectedStatus);
                      }
                      selectedRole = _capitalize(currentEmp.role);
                      if (!roles.contains(selectedRole)) {
                        roles.add(selectedRole);
                      }
                    }
                  });
                },
              ),
              SizedBox(width: 8.w),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: 20.h),

                    // 1. Profile Header Badge Card
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 84.w,
                            height: 84.h,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: avatarGrad,
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withOpacity(0.2), width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: avatarGrad[1].withOpacity(0.3),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                currentEmp.initials,
                                style: GoogleFonts.inter(
                                  fontSize: 28.sp,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            currentEmp.name,
                            style: GoogleFonts.inter(
                              fontSize: 22.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            currentEmp.designation,
                            style: GoogleFonts.inter(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF94A3B8),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 12.h),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 5.h),
                            decoration: BoxDecoration(
                              color: badgeBgColor,
                              borderRadius: BorderRadius.circular(100.r),
                              border: Border.all(color: badgeBorderColor, width: 1),
                            ),
                            child: Text(
                              statusLabel.toUpperCase(),
                              style: GoogleFonts.inter(
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w800,
                                  color: badgeTextColor,
                                  letterSpacing: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 32.h),

                    // 2. Info Cards Block
                    if (!isEditing) ...[
                      // VIEW MODE
                      Text(
                        'INFORMATION',
                        style: GoogleFonts.inter(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF94A3B8),
                          letterSpacing: 1.2,
                        ),
                      ),
                      SizedBox(height: 12.h),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(color: Colors.white.withOpacity(0.12), width: 1.2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _buildDetailTile(
                              icon: Icons.badge_outlined,
                              title: 'Employee ID',
                              value: currentEmp.id,
                            ),
                            Divider(height: 1, color: Colors.white.withOpacity(0.08), indent: 56),
                            _buildDetailTile(
                              icon: Icons.email_outlined,
                              title: 'Email Address',
                              value: currentEmp.email,
                            ),
                            Divider(height: 1, color: Colors.white.withOpacity(0.08), indent: 56),
                            _buildDetailTile(
                              icon: Icons.work_outline_rounded,
                              title: 'Role / Privilege',
                              value: currentEmp.role.toUpperCase(),
                            ),
                            Divider(height: 1, color: Colors.white.withOpacity(0.08), indent: 56),
                            
                            // Device Binding Status Row
                            currentEmp.deviceId != null && currentEmp.deviceId!.isNotEmpty
                                ? ListTile(
                                    contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
                                    leading: Container(
                                      padding: EdgeInsets.all(8.w),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF3B82F6).withOpacity(0.15),
                                        shape: BoxShape.circle,
                                        border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.3)),
                                      ),
                                      child: const Icon(Icons.phone_android_rounded, color: Color(0xFF60A5FA), size: 20),
                                    ),
                                    title: Text(
                                      'Registered Device',
                                      style: GoogleFonts.inter(fontSize: 12.sp, color: const Color(0xFF94A3B8), fontWeight: FontWeight.w500),
                                    ),
                                    subtitle: Text(
                                      'Bound to account',
                                      style: GoogleFonts.inter(fontSize: 14.sp, color: Colors.white, fontWeight: FontWeight.w600),
                                    ),
                                    trailing: Tooltip(
                                      message: 'Reset Device Binding',
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(100.r),
                                          onTap: _showResetDeviceDialog,
                                          child: Container(
                                            padding: EdgeInsets.all(10.w),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFEF4444).withOpacity(0.2),
                                              shape: BoxShape.circle,
                                              border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.3)),
                                            ),
                                            child: const Icon(Icons.phonelink_erase_rounded, color: Color(0xFFF87171), size: 18),
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                : ListTile(
                                    contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
                                    leading: Container(
                                      padding: EdgeInsets.all(8.w),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.04),
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white.withOpacity(0.08)),
                                      ),
                                      child: const Icon(Icons.phone_android_rounded, color: Color(0xFF94A3B8), size: 20),
                                    ),
                                    title: Text(
                                      'Registered Device',
                                      style: GoogleFonts.inter(fontSize: 12.sp, color: const Color(0xFF94A3B8), fontWeight: FontWeight.w500),
                                    ),
                                    subtitle: Text(
                                      'No device bound (will bind on next login)',
                                      style: GoogleFonts.inter(fontSize: 14.sp, color: const Color(0xFF64748B), fontWeight: FontWeight.w500),
                                    ),
                                  ),
                          ],
                        ),
                      ),

                      SizedBox(height: 32.h),

                      // 3. Danger Zone Actions
                      Text(
                        'DANGER ZONE',
                        style: GoogleFonts.inter(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFF87171),
                          letterSpacing: 1.2,
                        ),
                      ),
                      SizedBox(height: 12.h),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.3)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: InkWell(
                          onTap: _showDeleteAccountDialog,
                          borderRadius: BorderRadius.circular(20.r),
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                            child: Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(8.w),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEF4444).withOpacity(0.2),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.3)),
                                  ),
                                  child: const Icon(Icons.delete_forever_rounded, color: Color(0xFFF87171), size: 20),
                                ),
                                SizedBox(width: 14.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Delete Account',
                                        style: GoogleFonts.inter(
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFFF87171),
                                        ),
                                      ),
                                      SizedBox(height: 2.h),
                                      Text(
                                        'Permanently remove employee credentials and profile',
                                        style: GoogleFonts.inter(
                                          fontSize: 11.sp,
                                          color: const Color(0xFF94A3B8),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right, color: Color(0xFFF87171), size: 20),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 48.h),
                    ] else ...[
                      // EDIT MODE FORM
                      Text(
                        'EDIT PROFILE FIELDS',
                        style: GoogleFonts.inter(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF94A3B8),
                          letterSpacing: 1.2,
                        ),
                      ),
                      SizedBox(height: 12.h),
                      Container(
                        padding: EdgeInsets.all(20.w),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(color: Colors.white.withOpacity(0.12)),
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
                            // Employee ID
                            Text(
                              'Employee ID',
                              style: GoogleFonts.inter(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 6.h),
                            TextFormField(
                              controller: idController,
                              style: GoogleFonts.inter(fontSize: 14.sp, color: Colors.white),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) return 'Employee ID is required';
                                return null;
                              },
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.02),
                                prefixIcon: const Icon(
                                  Icons.badge_outlined,
                                  color: Color(0xFF3B82F6),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(color: Color(0xFF3B82F6)),
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                border: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
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
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 6.h),
                            TextFormField(
                              controller: nameController,
                              style: GoogleFonts.inter(fontSize: 14.sp, color: Colors.white),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) return 'Name is required';
                                return null;
                              },
                              decoration: InputDecoration(
                                hintText: 'e.g. Alex Kim',
                                hintStyle: GoogleFonts.inter(color: const Color(0xFF64748B)),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.02),
                                prefixIcon: const Icon(
                                  Icons.person_outline,
                                  color: Color(0xFF3B82F6),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(color: Color(0xFF3B82F6)),
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                border: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
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
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 6.h),
                            TextFormField(
                              controller: emailController,
                              keyboardType: TextInputType.emailAddress,
                              style: GoogleFonts.inter(fontSize: 14.sp, color: Colors.white),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) return 'Email is required';
                                final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                                if (!emailRegex.hasMatch(val.trim())) {
                                  return 'Please enter a valid email address';
                                }
                                return null;
                              },
                              decoration: InputDecoration(
                                hintText: 'e.g. employee@company.com',
                                hintStyle: GoogleFonts.inter(color: const Color(0xFF64748B)),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.02),
                                prefixIcon: const Icon(
                                  Icons.email_outlined,
                                  color: Color(0xFF3B82F6),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(color: Color(0xFF3B82F6)),
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                border: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                              ),
                            ),
                            SizedBox(height: 16.h),

                            // Date of Birth
                            Text(
                              'Date of Birth',
                              style: GoogleFonts.inter(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 6.h),
                            TextFormField(
                              controller: dobController,
                              readOnly: true,
                              style: GoogleFonts.inter(fontSize: 14.sp, color: Colors.white),
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
                                        dialogBackgroundColor: const Color(0xFF0F172A),
                                      ),
                                      child: child!,
                                    );
                                  },
                                );
                                if (picked != null) {
                                  final formatted =
                                      "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                                  setState(() {
                                    dobController.text = formatted;
                                  });
                                }
                              },
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) return 'Date of Birth is required';
                                return null;
                              },
                              decoration: InputDecoration(
                                hintText: 'YYYY-MM-DD',
                                hintStyle: GoogleFonts.inter(color: const Color(0xFF64748B)),
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
                                  borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(color: Color(0xFF3B82F6)),
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                border: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                              ),
                            ),
                            SizedBox(height: 16.h),

                            // Designation Dropdown
                            Text(
                              'Designation',
                              style: GoogleFonts.inter(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 6.h),
                            DropdownButtonFormField<String>(
                              value: selectedDesignation,
                              dropdownColor: const Color(0xFF1E1B30),
                              isExpanded: true,
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    selectedDesignation = val;
                                  });
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
                                  borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(color: Color(0xFF3B82F6)),
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                border: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                              ),
                              style: GoogleFonts.inter(fontSize: 14.sp, color: Colors.white),
                              items: designations.map((designation) {
                                return DropdownMenuItem(
                                  value: designation,
                                  child: Text(
                                    designation,
                                    style: GoogleFonts.inter(fontSize: 14.sp, color: Colors.white),
                                  ),
                                );
                              }).toList(),
                            ),
                            SizedBox(height: 16.h),

                            // Workplace Status Dropdown
                            Text(
                              'Workplace Status',
                              style: GoogleFonts.inter(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 6.h),
                            DropdownButtonFormField<String>(
                              value: selectedStatus,
                              dropdownColor: const Color(0xFF1E1B30),
                              isExpanded: true,
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    selectedStatus = val;
                                  });
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
                                  borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(color: Color(0xFF3B82F6)),
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                border: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                              ),
                              style: GoogleFonts.inter(fontSize: 14.sp, color: Colors.white),
                              items: statuses.map((status) {
                                return DropdownMenuItem(
                                  value: status,
                                  child: Text(
                                    status,
                                    style: GoogleFonts.inter(fontSize: 14.sp, color: Colors.white),
                                  ),
                                );
                              }).toList(),
                            ),
                            SizedBox(height: 16.h),

                            // System Role Dropdown
                            Text(
                              'System Role',
                              style: GoogleFonts.inter(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 6.h),
                            DropdownButtonFormField<String>(
                              value: selectedRole,
                              dropdownColor: const Color(0xFF1E1B30),
                              isExpanded: true,
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    selectedRole = val;
                                  });
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
                                  borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(color: Color(0xFF3B82F6)),
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                border: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                              ),
                              style: GoogleFonts.inter(fontSize: 14.sp, color: Colors.white),
                              items: roles.map((role) {
                                return DropdownMenuItem(
                                  value: role,
                                  child: Text(
                                    role,
                                    style: GoogleFonts.inter(fontSize: 14.sp, color: Colors.white),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 28.h),

                      // Save Changes Button
                      Container(
                        height: 50.h,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0F52BA), Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12.r),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF3B82F6).withOpacity(0.24),
                              blurRadius: 12,
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
                          onPressed: () async {
                            if (!formKey.currentState!.validate()) return;
                            
                            await controller.updateEmployeeProfile(
                              uid: currentEmp.uid,
                              name: nameController.text.trim(),
                              designation: selectedDesignation,
                              employeeId: idController.text.trim(),
                              email: emailController.text.trim(),
                              dob: dobController.text.trim(),
                              status: selectedStatus.toLowerCase(),
                              role: selectedRole.toLowerCase(),
                            );
                            
                            setState(() {
                              isEditing = false;
                            });
                          },
                          child: Text(
                            'Save Changes',
                            style: GoogleFonts.inter(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 48.h),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildDetailTile({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      leading: Container(
        padding: EdgeInsets.all(8.w),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Icon(icon, color: const Color(0xFF3B82F6), size: 20),
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 12.sp,
          color: const Color(0xFF94A3B8),
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        value,
        style: GoogleFonts.inter(
          fontSize: 14.sp,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showResetDeviceDialog() {
    Get.defaultDialog(
      backgroundColor: const Color(0xFF0F172A),
      title: 'Reset Device Binding',
      titleStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16.sp, color: Colors.white),
      middleText: 'Are you sure you want to reset this employee\'s device binding? Their active session will be terminated immediately, and they can register a new phone on their next login.',
      middleTextStyle: GoogleFonts.inter(fontSize: 13.sp, color: const Color(0xFF94A3B8)),
      textConfirm: 'Reset',
      textCancel: 'Cancel',
      confirmTextColor: Colors.white,
      cancelTextColor: const Color(0xFF94A3B8),
      buttonColor: const Color(0xFFEF4444),
      onConfirm: () {
        Get.back(); // close dialog
        controller.resetDeviceBinding(widget.employee.uid);
      },
    );
  }

  void _showDeleteAccountDialog() {
    Get.defaultDialog(
      backgroundColor: const Color(0xFF0F172A),
      title: 'Delete Employee Account',
      titleStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16.sp, color: const Color(0xFFF87171)),
      middleText: 'WARNING: This action is permanent! The employee\'s attendance data, profiles, and login permissions will be completely removed. They will be forcefully logged out immediately and blocked from accessing this application.',
      middleTextStyle: GoogleFonts.inter(fontSize: 13.sp, color: const Color(0xFF94A3B8)),
      textConfirm: 'Delete Account',
      textCancel: 'Cancel',
      confirmTextColor: Colors.white,
      cancelTextColor: const Color(0xFF94A3B8),
      buttonColor: const Color(0xFFEF4444),
      onConfirm: () async {
        Get.back(); // close confirm dialog
        Get.back(); // close details page and return to directory
        await controller.deleteEmployeeAccount(widget.employee.uid);
      },
    );
  }
}
