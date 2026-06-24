import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:stepz_attendance/core/theme/premium_background.dart';
import '../controllers/admin_attendance_requests_controller.dart';

class AdminRequestDetailsView extends StatefulWidget {
  const AdminRequestDetailsView({super.key});

  @override
  State<AdminRequestDetailsView> createState() => _AdminRequestDetailsViewState();
}

class _AdminRequestDetailsViewState extends State<AdminRequestDetailsView> {
  final AdminAttendanceRequestsController _controller = Get.find<AdminAttendanceRequestsController>();
  late Map<String, dynamic> _request;
  late String _checkInTime;
  late String _checkOutTime;
  final TextEditingController _remarksController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _request = Get.arguments as Map<String, dynamic>;
    _checkInTime = _request['checkIn'] as String? ?? '--';
    _checkOutTime = _request['requestedCheckOut'] as String? ?? '--';
    _remarksController.text = _request['adminRemarks'] as String? ?? '';
  }

  @override
  void dispose() {
    _remarksController.dispose();
    super.dispose();
  }

  TimeOfDay _parseTimeString(String timeStr) {
    try {
      final cleaned = timeStr.trim().toUpperCase();
      final match = RegExp(r'^(\d{1,2}):(\d{2})\s*(AM|PM)$').firstMatch(cleaned);
      if (match != null) {
        int hour = int.parse(match.group(1)!);
        final int minute = int.parse(match.group(2)!);
        final String ampm = match.group(3)!;

        if (ampm == 'PM' && hour != 12) {
          hour += 12;
        } else if (ampm == 'AM' && hour == 12) {
          hour = 0;
        }
        return TimeOfDay(hour: hour, minute: minute);
      }
    } catch (e) {
      debugPrint('Error parsing time string $timeStr: $e');
    }
    return const TimeOfDay(hour: 9, minute: 0);
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat('hh:mm a').format(dt);
  }

  Future<void> _selectTime(bool isCheckIn) async {
    final initialStr = isCheckIn ? _checkInTime : _checkOutTime;
    final initialTime = _parseTimeString(initialStr == '--' ? '09:00 AM' : initialStr);

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
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
      setState(() {
        if (isCheckIn) {
          _checkInTime = _formatTimeOfDay(picked);
        } else {
          _checkOutTime = _formatTimeOfDay(picked);
        }
      });
    }
  }

  Future<void> _approve() async {
    if (_checkInTime == '--' || _checkOutTime == '--') {
      Get.rawSnackbar(
        title: 'Validation Error',
        message: 'Both Check-In and Check-Out times must be specified to approve.',
        backgroundColor: Colors.red.shade700,
      );
      return;
    }

    setState(() => _isSaving = true);
    final success = await _controller.approveRequest(
      requestId: _request['id'],
      employeeId: _request['employeeId'],
      dateKey: _request['attendanceDate'],
      checkIn: _checkInTime,
      checkOut: _checkOutTime,
      remarks: _remarksController.text.trim(),
    );
    setState(() => _isSaving = false);

    if (success) {
      Get.back();
    }
  }

  Future<void> _reject() async {
    if (_remarksController.text.trim().isEmpty) {
      Get.rawSnackbar(
        title: 'Remarks Required',
        message: 'Please provide rejection remarks/reason.',
        backgroundColor: Colors.red.shade700,
      );
      return;
    }

    setState(() => _isSaving = true);
    final success = await _controller.rejectRequest(
      requestId: _request['id'],
      employeeId: _request['employeeId'],
      dateKey: _request['attendanceDate'],
      remarks: _remarksController.text.trim(),
    );
    setState(() => _isSaving = false);

    if (success) {
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _request['status'] as String? ?? 'pending';
    final name = _request['employeeName'] as String? ?? 'Employee';
    final email = _request['employeeEmail'] as String? ?? '';
    final designation = _request['designation'] as String? ?? 'Staff';
    final date = _request['attendanceDateFormatted'] as String? ?? 'Unknown Date';
    final workSummary = _request['workSummary'] as String? ?? '';

    Color statusColor;
    switch (status) {
      case 'approved':
        statusColor = const Color(0xFF10B981);
        break;
      case 'rejected':
        statusColor = const Color(0xFFEF4444);
        break;
      default:
        statusColor = const Color(0xFFF97316);
    }

    return PremiumBackground(
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
            'Request Details',
            style: GoogleFonts.outfit(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Employee Info Card
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48.w,
                      height: 48.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF1E3A8A),
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: Center(
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : 'E',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18.sp,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: GoogleFonts.inter(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            designation,
                            style: GoogleFonts.inter(
                              fontSize: 12.sp,
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                          if (email.isNotEmpty)
                            Text(
                              email,
                              style: GoogleFonts.inter(
                                fontSize: 11.sp,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(color: statusColor.withOpacity(0.4)),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16.h),

              // Request Details & Editing Card
              Container(
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: Colors.white.withOpacity(0.12), width: 1.2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Request Parameters',
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 16.h),

                    // Date
                    _buildDetailRow('Shift Date', date),
                    const Divider(color: Colors.white10, height: 24),

                    // Reason
                    _buildDetailRow('Submitted Reason', _request['reason'] as String? ?? ''),
                    const Divider(color: Colors.white10, height: 24),

                    // Check-In (Editable if pending)
                    Text(
                      'Check-In Time',
                      style: GoogleFonts.inter(fontSize: 11.sp, color: const Color(0xFF94A3B8), fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 6.h),
                    status == 'pending'
                        ? InkWell(
                            onTap: () => _selectTime(true),
                            borderRadius: BorderRadius.circular(10.r),
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.04),
                                borderRadius: BorderRadius.circular(10.r),
                                border: Border.all(color: Colors.white24),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _checkInTime,
                                    style: GoogleFonts.inter(fontSize: 14.sp, color: Colors.white, fontWeight: FontWeight.w600),
                                  ),
                                  const Icon(Icons.edit_calendar_rounded, color: Color(0xFF3B82F6), size: 18),
                                ],
                              ),
                            ),
                          )
                        : Text(
                            _checkInTime,
                            style: GoogleFonts.inter(fontSize: 14.sp, color: Colors.white, fontWeight: FontWeight.w600),
                          ),
                    const Divider(color: Colors.white10, height: 24),

                    // Check-Out (Editable if pending)
                    Text(
                      'Check-Out Time',
                      style: GoogleFonts.inter(fontSize: 11.sp, color: const Color(0xFF94A3B8), fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 6.h),
                    status == 'pending'
                        ? InkWell(
                            onTap: () => _selectTime(false),
                            borderRadius: BorderRadius.circular(10.r),
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.04),
                                borderRadius: BorderRadius.circular(10.r),
                                border: Border.all(color: Colors.white24),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _checkOutTime,
                                    style: GoogleFonts.inter(fontSize: 14.sp, color: Colors.white, fontWeight: FontWeight.w600),
                                  ),
                                  const Icon(Icons.edit_calendar_rounded, color: Color(0xFF3B82F6), size: 18),
                                ],
                              ),
                            ),
                          )
                        : Text(
                            _checkOutTime,
                            style: GoogleFonts.inter(fontSize: 14.sp, color: Colors.white, fontWeight: FontWeight.w600),
                          ),
                    const Divider(color: Colors.white10, height: 24),

                    // Work Summary
                    Text(
                      'Employee Work Summary',
                      style: GoogleFonts.inter(fontSize: 11.sp, color: const Color(0xFF94A3B8), fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 6.h),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Text(
                        workSummary,
                        style: GoogleFonts.inter(fontSize: 13.sp, color: const Color(0xFFE2E8F0), height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16.h),

              // Admin Remarks & Actions Card
              Container(
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: Colors.white.withOpacity(0.12), width: 1.2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      status == 'pending' ? 'Review Remarks' : 'Remarks Details',
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    status == 'pending'
                        ? TextFormField(
                            controller: _remarksController,
                            maxLines: 3,
                            style: GoogleFonts.inter(fontSize: 14.sp, color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Enter approval or rejection remarks here...',
                              hintStyle: GoogleFonts.inter(fontSize: 13.sp, color: const Color(0xFF64748B)),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.04),
                              contentPadding: EdgeInsets.all(12.w),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.r),
                                borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.r),
                                borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
                              ),
                            ),
                          )
                        : Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(12.w),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10.r),
                              border: Border.all(color: Colors.white.withOpacity(0.05)),
                            ),
                            child: Text(
                              _remarksController.text.isNotEmpty
                                  ? _remarksController.text
                                  : 'No remarks provided.',
                              style: GoogleFonts.inter(
                                fontSize: 13.sp,
                                color: Colors.white,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                    if (status == 'pending') ...[
                      SizedBox(height: 20.h),
                      _isSaving
                          ? const Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
                              ),
                            )
                          : Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFFEF4444),
                                      side: const BorderSide(color: Color(0xFFEF4444)),
                                      padding: EdgeInsets.symmetric(vertical: 12.h),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                                    ),
                                    onPressed: _reject,
                                    child: Text(
                                      'REJECT',
                                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13.sp),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12.w),
                                Expanded(
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF10B981),
                                      foregroundColor: Colors.white,
                                      padding: EdgeInsets.symmetric(vertical: 12.h),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                                      elevation: 0,
                                    ),
                                    onPressed: _approve,
                                    child: Text(
                                      'APPROVE',
                                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13.sp),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: GoogleFonts.inter(fontSize: 12.sp, color: const Color(0xFF94A3B8), fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: GoogleFonts.inter(fontSize: 13.sp, color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
