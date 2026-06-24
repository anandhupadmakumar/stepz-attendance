import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:stepz_attendance/core/theme/premium_background.dart';
import 'package:stepz_attendance/features/employee/presentation/controllers/employee_dashboard_controller.dart';
import '../controllers/attendance_regularization_controller.dart';

class AttendanceRegularizationRequestView extends GetView<AttendanceRegularizationController> {
  const AttendanceRegularizationRequestView({super.key});

  @override
  Widget build(BuildContext context) {
    final employeeDashboardCtrl = Get.find<EmployeeDashboardController>();

    return PremiumBackground(
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => Get.back(),
            ),
            title: Text(
              'Attendance Regularization',
              style: GoogleFonts.outfit(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            bottom: TabBar(
              indicatorColor: const Color(0xFF3B82F6),
              labelColor: Colors.white,
              unselectedLabelColor: const Color(0xFF94A3B8),
              labelStyle: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
              ),
              unselectedLabelStyle: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.normal,
              ),
              tabs: const [
                Tab(text: 'New Request'),
                Tab(text: 'Request History'),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              _buildNewRequestForm(context),
              _buildRequestHistory(context, employeeDashboardCtrl),
            ],
          ),
        ),
      ),
    );
  }

  // TAB 1: NEW REQUEST FORM
  Widget _buildNewRequestForm(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      child: Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: Colors.white.withOpacity(0.12),
            width: 1.2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Missed Checkout Regularization',
              style: GoogleFonts.inter(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              'Submit details to update your check-out and work hours.',
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                color: const Color(0xFF94A3B8),
              ),
            ),
            SizedBox(height: 20.h),

            // Date Picker Field
            Text(
              'Select Date',
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFCBD5E1),
              ),
            ),
            SizedBox(height: 8.h),
            Obx(() {
              final date = controller.selectedDate.value;
              final displayDate = date != null
                  ? DateFormat('EEEE, MMM dd, yyyy').format(date)
                  : 'Choose Date';
              return InkWell(
                onTap: () => _selectDate(context),
                borderRadius: BorderRadius.circular(12.r),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.15),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        displayDate,
                        style: GoogleFonts.inter(
                          fontSize: 14.sp,
                          color: date != null ? Colors.white : const Color(0xFF64748B),
                        ),
                      ),
                      const Icon(Icons.calendar_month_rounded, color: Color(0xFF3B82F6)),
                    ],
                  ),
                ),
              );
            }),
            SizedBox(height: 16.h),

            // Check-In Indicator (Fetched automatically when date is selected)
            Obx(() {
              final checkIn = controller.dbCheckIn.value;
              return Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.02),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.06),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.login_rounded, color: Color(0xFF10B981), size: 20),
                    SizedBox(width: 12.w),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Original Check-In Time',
                          style: GoogleFonts.inter(
                            fontSize: 10.sp,
                            color: const Color(0xFF94A3B8),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          checkIn,
                          style: GoogleFonts.inter(
                            fontSize: 14.sp,
                            color: checkIn != '--' ? Colors.white : const Color(0xFFEF4444),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
            SizedBox(height: 16.h),

            // Requested Check-Out Picker Field
            Text(
              'Requested Check-Out Time',
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFCBD5E1),
              ),
            ),
            SizedBox(height: 8.h),
            Obx(() {
              final time = controller.requestedCheckOut.value;
              final displayTime = time != null
                  ? controller.formatTimeOfDay(time)
                  : 'Choose Checkout Time';
              return InkWell(
                onTap: () => _selectTime(context),
                borderRadius: BorderRadius.circular(12.r),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.15),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        displayTime,
                        style: GoogleFonts.inter(
                          fontSize: 14.sp,
                          color: time != null ? Colors.white : const Color(0xFF64748B),
                        ),
                      ),
                      const Icon(Icons.access_time_rounded, color: Color(0xFF3B82F6)),
                    ],
                  ),
                ),
              );
            }),
            SizedBox(height: 16.h),

            // Reason Dropdown
            Text(
              'Reason for Request',
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFCBD5E1),
              ),
            ),
            SizedBox(height: 8.h),
            Obx(() => Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A).withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.15),
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: controller.selectedReason.value,
                      dropdownColor: const Color(0xFF0F172A),
                      icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        color: Colors.white,
                      ),
                      onChanged: (val) {
                        if (val != null) controller.setReason(val);
                      },
                      items: controller.reasons.map((r) {
                        return DropdownMenuItem<String>(
                          value: r,
                          child: Text(r),
                        );
                      }).toList(),
                    ),
                  ),
                )),
            SizedBox(height: 16.h),

            // Multiline Work Summary (Requirement)
            Text(
              'Work Summary (Shift accomplishments)',
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFCBD5E1),
              ),
            ),
            SizedBox(height: 8.h),
            TextFormField(
              controller: controller.workSummaryController,
              maxLines: 4,
              keyboardType: TextInputType.multiline,
              style: GoogleFonts.inter(fontSize: 14.sp, color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Describe what projects/tasks you completed during this shift...',
                hintStyle: GoogleFonts.inter(fontSize: 13.sp, color: const Color(0xFF64748B)),
                filled: true,
                fillColor: Colors.white.withOpacity(0.04),
                contentPadding: EdgeInsets.all(16.w),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
                ),
              ),
            ),
            SizedBox(height: 24.h),

            // Submit Button
            Obx(() {
              final isSubmitting = controller.isSubmitting.value;
              return ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  elevation: 0,
                ),
                onPressed: isSubmitting ? null : controller.submitRequest,
                child: isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        'SUBMIT REQUEST',
                        style: GoogleFonts.inter(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // TAB 2: REQUEST HISTORY
  Widget _buildRequestHistory(
    BuildContext context,
    EmployeeDashboardController employeeDashboardCtrl,
  ) {
    return Obx(() {
      final list = employeeDashboardCtrl.regularizationRequests;
      if (list.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.history_toggle_off_rounded,
                color: Color(0xFF475569),
                size: 64,
              ),
              SizedBox(height: 16.h),
              Text(
                'No requests found',
                style: GoogleFonts.inter(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF94A3B8),
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                'Your regularization request history will appear here.',
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final req = list[index];
          return _buildRequestCard(req);
        },
      );
    });
  }

  Widget _buildRequestCard(Map<String, dynamic> req) {
    final status = req['status'] as String? ?? 'pending';
    final date = req['attendanceDateFormatted'] as String? ?? 'Unknown Date';
    final checkIn = req['checkIn'] as String? ?? '--';
    final requestedCheckOut = req['requestedCheckOut'] as String? ?? '--';
    final reason = req['reason'] as String? ?? 'Forgot to Checkout';
    final workSummary = req['workSummary'] as String? ?? '';
    final remarks = req['adminRemarks'] as String? ?? '';

    Color statusColor;
    String statusLabel = status.toUpperCase();
    switch (status) {
      case 'approved':
        statusColor = const Color(0xFF10B981);
        break;
      case 'rejected':
        statusColor = const Color(0xFFEF4444);
        break;
      default:
        statusColor = const Color(0xFFF97316);
        statusLabel = 'PENDING';
    }

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                date,
                style: GoogleFonts.inter(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: statusColor.withOpacity(0.4),
                    width: 1,
                  ),
                ),
                child: Text(
                  statusLabel,
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),

          // Check-in and requested check-out info
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Original Check-In',
                      style: GoogleFonts.inter(
                        fontSize: 10.sp,
                        color: const Color(0xFF94A3B8),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      checkIn,
                      style: GoogleFonts.inter(
                        fontSize: 13.sp,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Requested Check-Out',
                      style: GoogleFonts.inter(
                        fontSize: 10.sp,
                        color: const Color(0xFF94A3B8),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      requestedCheckOut,
                      style: GoogleFonts.inter(
                        fontSize: 13.sp,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),

          // Reason details
          Text(
            'Reason: $reason',
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              color: const Color(0xFFCBD5E1),
              fontWeight: FontWeight.w500,
            ),
          ),
          if (workSummary.isNotEmpty) ...[
            SizedBox(height: 8.h),
            Text(
              'Work Summary:',
              style: GoogleFonts.inter(
                fontSize: 10.sp,
                color: const Color(0xFF94A3B8),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              workSummary,
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                color: const Color(0xFFE2E8F0),
              ),
            ),
          ],

          // Admin Remarks if present
          if (remarks.isNotEmpty) ...[
            SizedBox(height: 12.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(
                  color: Colors.white.withOpacity(0.06),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Admin Remarks:',
                    style: GoogleFonts.inter(
                      fontSize: 10.sp,
                      color: const Color(0xFF94A3B8),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    remarks,
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      color: Colors.white,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // HELPER: Select Date
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 1)),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF3B82F6),
              onPrimary: Colors.white,
              surface: Color(0xFF0F172A),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      await controller.setDate(picked);
    }
  }

  // HELPER: Select Time
  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 17, minute: 30),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF3B82F6),
              onPrimary: Colors.white,
              surface: Color(0xFF0F172A),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      controller.setRequestedCheckOut(picked);
    }
  }
}
