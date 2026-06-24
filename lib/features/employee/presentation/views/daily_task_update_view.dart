import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stepz_attendance/core/theme/premium_background.dart';
import '../controllers/daily_task_update_controller.dart';

class DailyTaskUpdateView extends GetView<DailyTaskUpdateController> {
  const DailyTaskUpdateView({super.key});

  @override
  Widget build(BuildContext context) {
    // Forcing dark theme styles since PremiumBackground is always a dark gradient base
    const isDark = true;
    final glassColor = Colors.white.withOpacity(0.06);
    final borderColor = Colors.white.withOpacity(0.12);
    const textColor = Colors.white;
    const subTextColor = Color(0xFF94A3B8);
    final inputFillColor = Colors.white.withOpacity(0.08);
    const inputHintColor = Color(0xFF64748B);

    return PremiumBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor),
            onPressed: () => Get.back(),
          ),
          title: Text(
            'Daily Task Update',
            style: GoogleFonts.outfit(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(
                Icons.delete_outline_rounded,
                color: Colors.red.shade400,
              ),
              tooltip: 'Clear Draft',
              onPressed: () {
                Get.defaultDialog(
                  title: 'Clear Draft?',
                  titleStyle: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                  middleText:
                      'Are you sure you want to clear this task update draft?',
                  middleTextStyle: GoogleFonts.inter(color: subTextColor),
                  textConfirm: 'Clear',
                  textCancel: 'Cancel',
                  confirmTextColor: Colors.white,
                  cancelTextColor: textColor,
                  buttonColor: const Color(0xFFBA1A1A),
                  onConfirm: () {
                    controller.clearDraft();
                    Get.back();
                  },
                );
              },
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Check-in Gate Status Banner
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
                child: _buildCheckInBanner(borderColor, subTextColor),
              ),

              // Main scrollable content (Form + Staged List)
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 8.h,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. Log Input Form Card
                      Container(
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color: glassColor,
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(color: borderColor, width: 1.2),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.add_task_rounded,
                                  color: Color(0xFF3B82F6),
                                  size: 18,
                                ),
                                SizedBox(width: 8.w),
                                Text(
                                  'Add Work Log Entry',
                                  style: GoogleFonts.outfit(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 14.h),

                            // --- Task Selection Dropdown ---
                            _fieldLabel('Select Task *', subTextColor),
                            SizedBox(height: 6.h),
                            _buildTaskDropdown(
                              borderColor,
                              textColor,
                              inputFillColor,
                              inputHintColor,
                              isDark,
                            ),
                            SizedBox(height: 12.h),

                            // --- Custom Task Title input (Visible only if unassigned 'other' task is selected) ---
                            Obx(() {
                              if (controller.selectedTaskId.value == 'other') {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _fieldLabel(
                                      'Unassigned Task Title *',
                                      subTextColor,
                                    ),
                                    SizedBox(height: 6.h),
                                    TextFormField(
                                      controller:
                                          controller.projectNameController,
                                      style: GoogleFonts.inter(
                                        fontSize: 13.sp,
                                        color: textColor,
                                      ),
                                      decoration: _inputDecoration(
                                        hint:
                                            'e.g. Server Maintenance or Admin Work',
                                        borderColor: borderColor,
                                        fillColor: inputFillColor,
                                        hintColor: inputHintColor,
                                        prefixIcon: Icons.edit_note_rounded,
                                      ),
                                    ),
                                    SizedBox(height: 12.h),
                                  ],
                                );
                              }
                              return const SizedBox.shrink();
                            }),

                            // --- Start Time & End Time ---
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _fieldLabel('Start Time *', subTextColor),
                                      SizedBox(height: 6.h),
                                      _buildTimePickerButton(
                                        context,
                                        true,
                                        borderColor,
                                        textColor,
                                        inputFillColor,
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: 12.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _fieldLabel('End Time *', subTextColor),
                                      SizedBox(height: 6.h),
                                      _buildTimePickerButton(
                                        context,
                                        false,
                                        borderColor,
                                        textColor,
                                        inputFillColor,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12.h),

                            // --- Task Progress Slider (Visible only for real assigned tasks) ---
                            Obx(() {
                              final selId = controller.selectedTaskId.value;
                              if (selId != null && selId != 'other') {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        _fieldLabel(
                                          'Task Completion Progress',
                                          subTextColor,
                                        ),
                                        Text(
                                          '${controller.progressPercentage.value.toInt()}%',
                                          style: GoogleFonts.inter(
                                            fontSize: 12.sp,
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFF3B82F6),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Slider(
                                      value:
                                          controller.progressPercentage.value,
                                      min: 0,
                                      max: 100,
                                      divisions: 20,
                                      activeColor: const Color(0xFF3B82F6),
                                      inactiveColor: Colors.white.withOpacity(
                                        0.12,
                                      ),
                                      onChanged: (val) {
                                        controller.progressPercentage.value =
                                            val;
                                      },
                                    ),
                                    SizedBox(height: 6.h),
                                  ],
                                );
                              }
                              return const SizedBox.shrink();
                            }),

                            // --- Task Status Selection ---
                            _fieldLabel('Task Status', subTextColor),
                            SizedBox(height: 6.h),
                            _buildStatusDropdown(
                              borderColor,
                              textColor,
                              inputFillColor,
                              inputHintColor,
                              isDark,
                            ),
                            SizedBox(height: 12.h),

                            // --- Single Details Input Field (Malayalam speech dictated + translated inside) ---
                            _fieldLabel(
                              'Task Details Description *',
                              subTextColor,
                            ),
                            SizedBox(height: 6.h),
                            _buildTaskDetailsField(
                              borderColor,
                              textColor,
                              subTextColor,
                              inputFillColor,
                              inputHintColor,
                            ),
                            SizedBox(height: 16.h),

                            // --- Add Log to List Button ---
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF3B82F6),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.r),
                                ),
                                padding: EdgeInsets.symmetric(vertical: 12.h),
                              ),
                              onPressed: controller.addLogToList,
                              icon: const Icon(
                                Icons.add_rounded,
                                color: Colors.white,
                              ),
                              label: Text(
                                'Add Log Entry',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20.h),

                      // 2. Staging / Added Logs Header
                      Obx(
                        () => Row(
                          children: [
                            const Icon(
                              Icons.playlist_add_check_rounded,
                              color: Colors.white70,
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              'Staged Logs (${controller.tempLogs.length})',
                              style: GoogleFonts.outfit(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 10.h),

                      // 3. Staged Logs List View
                      _buildStagedLogsList(
                        borderColor,
                        textColor,
                        subTextColor,
                      ),
                      SizedBox(height: 32.h),
                    ],
                  ),
                ),
              ),

              // 4. Main Submit Action Button
              _buildFinalSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  // --- Helper Labels & Borders ---
  Widget _fieldLabel(String label, Color subTextColor) {
    return Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 11.sp,
        fontWeight: FontWeight.w600,
        color: subTextColor.withOpacity(0.8),
        letterSpacing: 0.2,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required Color borderColor,
    required Color fillColor,
    required Color hintColor,
    IconData? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(color: hintColor, fontSize: 12.sp),
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, color: hintColor, size: 16.sp)
          : null,
      suffixIcon: suffixIcon,
      contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      filled: true,
      fillColor: fillColor,
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: borderColor),
        borderRadius: BorderRadius.circular(10.r),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
        borderRadius: BorderRadius.circular(10.r),
      ),
      border: OutlineInputBorder(
        borderSide: BorderSide(color: borderColor),
        borderRadius: BorderRadius.circular(10.r),
      ),
    );
  }

  // --- Check-in Status Banner ---
  Widget _buildCheckInBanner(Color borderColor, Color subTextColor) {
    return Obx(() {
      if (controller.isLoadingCheckIn.value) {
        return Container(
          height: 44.h,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(color: borderColor),
          ),
          child: const Center(
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white24,
              ),
            ),
          ),
        );
      }

      final checkedIn = controller.hasCheckedIn.value;
      final timeStr = controller.checkInTime.value;

      return Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: checkedIn
              ? const Color(0xFF10B981).withOpacity(0.08)
              : const Color(0xFFF59E0B).withOpacity(0.08),
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(
            color: checkedIn
                ? const Color(0xFF10B981).withOpacity(0.3)
                : const Color(0xFFF59E0B).withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              checkedIn ? Icons.login_rounded : Icons.warning_amber_rounded,
              size: 14.sp,
              color: checkedIn
                  ? const Color(0xFF34D399)
                  : const Color(0xFFFBBF24),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                checkedIn
                    ? 'Punch status: Checked In ($timeStr)'
                    : 'Check-in is required to submit daily updates.',
                style: GoogleFonts.inter(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  color: checkedIn
                      ? const Color(0xFF34D399)
                      : const Color(0xFFFBBF24),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  // --- Task Selection Dropdown ---
  Widget _buildTaskDropdown(
    Color borderColor,
    Color textColor,
    Color fillColor,
    Color hintColor,
    bool isDark,
  ) {
    return Obx(() {
      if (controller.isLoadingTasks.value) {
        return const Center(
          child: LinearProgressIndicator(color: Color(0xFF3B82F6)),
        );
      }

      return DropdownButtonFormField<String>(
        value: controller.selectedTaskId.value,
        dropdownColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        isExpanded: true,
        hint: Text(
          'Choose assigned task or select unassigned',
          style: GoogleFonts.inter(color: hintColor, fontSize: 13.sp),
        ),
        onChanged: (val) {
          controller.selectedTaskId.value = val;
        },
        decoration:
            _inputDecoration(
              hint: 'Choose assigned task or select unassigned',
              borderColor: borderColor,
              fillColor: fillColor,
              hintColor: hintColor,
              prefixIcon: Icons.assignment_outlined,
            ).copyWith(
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12.w,
                vertical: 2.h,
              ),
            ),
        style: GoogleFonts.inter(fontSize: 13.sp, color: textColor),
        items: [
          // Assigned Tasks List
          ...controller.employeeTasks.map((t) {
            return DropdownMenuItem(
              value: t.taskId,
              child: Text(
                t.taskTitle,
                style: GoogleFonts.inter(color: textColor, fontSize: 13.sp),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }),
          // Other Task Option
          DropdownMenuItem(
            value: 'other',
            child: Text(
              'Other / Unassigned Task',
              style: GoogleFonts.inter(
                color: const Color(0xFFF59E0B),
                fontSize: 13.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      );
    });
  }

  // --- Time Picker Button ---
  Widget _buildTimePickerButton(
    BuildContext context,
    bool isStart,
    Color borderColor,
    Color textColor,
    Color fillColor,
  ) {
    return Obx(() {
      final TimeOfDay? tod = isStart
          ? controller.startTime.value
          : controller.endTime.value;
      final display = tod != null ? controller.formatTimeOfDay(tod) : '--:--';

      return InkWell(
        onTap: () => controller.pickTime(context, isStart),
        borderRadius: BorderRadius.circular(10.r),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 12.w),
          decoration: BoxDecoration(
            color: fillColor,
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Icon(
                Icons.access_time_rounded,
                color: Colors.white30,
                size: 16.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                display,
                style: GoogleFonts.inter(
                  fontSize: 13.sp,
                  color: display == '--:--' ? Colors.white30 : textColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  // --- Status Dropdown ---
  Widget _buildStatusDropdown(
    Color borderColor,
    Color textColor,
    Color fillColor,
    Color hintColor,
    bool isDark,
  ) {
    final statuses = ['In Progress', 'Completed', 'Pending'];
    final statusColors = {
      'In Progress': const Color(0xFF3B82F6),
      'Completed': const Color(0xFF10B981),
      'Pending': const Color(0xFFF59E0B),
    };

    return Obx(() {
      return DropdownButtonFormField<String>(
        value: controller.selectedStatus.value,
        dropdownColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        isExpanded: true,
        onChanged: (val) {
          if (val != null) controller.selectedStatus.value = val;
        },
        decoration:
            _inputDecoration(
              hint: 'Select status',
              borderColor: borderColor,
              fillColor: fillColor,
              hintColor: hintColor,
              prefixIcon: Icons.flag_outlined,
            ).copyWith(
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12.w,
                vertical: 2.h,
              ),
            ),
        style: GoogleFonts.inter(fontSize: 13.sp, color: textColor),
        items: statuses.map((status) {
          return DropdownMenuItem(
            value: status,
            child: Row(
              children: [
                Container(
                  width: 8.w,
                  height: 8.w,
                  decoration: BoxDecoration(
                    color: statusColors[status],
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 8.w),
                Text(
                  status,
                  style: GoogleFonts.inter(color: textColor, fontSize: 13.sp),
                ),
              ],
            ),
          );
        }).toList(),
      );
    });
  }

  // --- Task Details field with inline mic dictation button ---
  Widget _buildTaskDetailsField(
    Color borderColor,
    Color textColor,
    Color subTextColor,
    Color fillColor,
    Color hintColor,
  ) {
    return Obx(() {
      final recording = controller.isRecording.value;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            children: [
              TextFormField(
                controller: controller.taskDetailsController,
                maxLines: 4,
                style: GoogleFonts.inter(
                  fontSize: 13.sp,
                  color: textColor,
                  height: 1.4,
                ),
                decoration:
                    _inputDecoration(
                      hint:
                          'Describe what you worked on today (Speak Malayalam / type English)...',
                      borderColor: recording
                          ? const Color(0xFFEF4444)
                          : borderColor,
                      fillColor: fillColor,
                      hintColor: hintColor,
                    ).copyWith(
                      contentPadding: EdgeInsets.fromLTRB(
                        12.w,
                        12.h,
                        48.w,
                        12.h,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: recording
                              ? const Color(0xFFEF4444)
                              : borderColor,
                          width: recording ? 1.5 : 1.0,
                        ),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: recording
                              ? const Color(0xFFEF4444)
                              : const Color(0xFF3B82F6),
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                    ),
              ),

              // Mic dictation bubble button in top-right inside field
              Positioned(
                top: 6.h,
                right: 6.w,
                child: GestureDetector(
                  onTap: controller.toggleRecording,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 32.w,
                    height: 32.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: recording
                          ? const Color(0xFFEF4444)
                          : const Color(0xFF3B82F6),
                      boxShadow: [
                        BoxShadow(
                          color:
                              (recording
                                      ? const Color(0xFFEF4444)
                                      : const Color(0xFF3B82F6))
                                  .withOpacity(0.35),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      recording ? Icons.stop_rounded : Icons.mic_none_rounded,
                      color: Colors.white,
                      size: 16.sp,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Listening strip
          if (recording) ...[
            SizedBox(height: 6.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withOpacity(0.08),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                  color: const Color(0xFFEF4444).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.circle, color: Color(0xFFEF4444), size: 6),
                  SizedBox(width: 8.w),
                  Text(
                    'Listening... Speak Malayalam now',
                    style: GoogleFonts.inter(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFEF4444),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Translation loading strip
          if (controller.isTranslating.value) ...[
            SizedBox(height: 6.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withOpacity(0.08),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                  color: const Color(0xFF3B82F6).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 10.w,
                    height: 10.w,
                    child: const CircularProgressIndicator(
                      strokeWidth: 1.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF3B82F6),
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    'Translating speech to English summary...',
                    style: GoogleFonts.inter(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF3B82F6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      );
    });
  }

  // --- Staged Logs List View ---
  Widget _buildStagedLogsList(
    Color borderColor,
    Color textColor,
    Color subTextColor,
  ) {
    return Obx(() {
      final logs = controller.tempLogs;

      if (logs.isEmpty) {
        return Container(
          padding: EdgeInsets.all(24.w),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: borderColor, width: 1.0),
          ),
          child: Column(
            children: [
              Icon(Icons.notes_rounded, color: Colors.white24, size: 36.sp),
              SizedBox(height: 8.h),
              Text(
                'No logs added for today yet.',
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  color: Colors.white30,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                'Fill details above and tap "Add Log Entry" to build your daily report.',
                style: GoogleFonts.inter(
                  fontSize: 10.sp,
                  color: Colors.white24,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }

      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: logs.length,
        separatorBuilder: (_, __) => SizedBox(height: 10.h),
        itemBuilder: (context, index) {
          final log = logs[index];
          final String title = log['taskTitle'] ?? 'Task Log';
          final String start = log['startTime'] ?? '';
          final String end = log['endTime'] ?? '';
          final String details = log['taskDetails'] ?? '';
          final String status = log['taskStatus'] ?? 'In Progress';
          final double progress = (log['progressPercentage'] as num? ?? 0.0)
              .toDouble();
          final bool isAssigned = (log['taskId'] as String? ?? '').isNotEmpty;

          Color badgeColor;
          switch (status) {
            case 'Completed':
              badgeColor = const Color(0xFF10B981);
              break;
            case 'Pending':
              badgeColor = const Color(0xFFF59E0B);
              break;
            default:
              badgeColor = const Color(0xFF3B82F6);
          }

          return Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(
                color: badgeColor.withOpacity(0.25),
                width: 1.0,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: GoogleFonts.outfit(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 6.w,
                              vertical: 2.h,
                            ),
                            decoration: BoxDecoration(
                              color: badgeColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                            child: Text(
                              status,
                              style: GoogleFonts.inter(
                                fontSize: 9.sp,
                                color: badgeColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      Row(
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            color: Colors.white38,
                            size: 12.sp,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            '$start - $end',
                            style: GoogleFonts.inter(
                              fontSize: 10.sp,
                              color: Colors.white60,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (isAssigned) ...[
                            SizedBox(width: 12.w),
                            Icon(
                              Icons.trending_up_rounded,
                              color: const Color(0xFF3B82F6),
                              size: 12.sp,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              'Progress: ${progress.toInt()}%',
                              style: GoogleFonts.inter(
                                fontSize: 10.sp,
                                color: const Color(0xFF60A5FA),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        details,
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          color: Colors.white70,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.redAccent,
                    size: 18,
                  ),
                  onPressed: () => controller.removeLogFromList(index),
                ),
              ],
            ),
          );
        },
      );
    });
  }

  // --- Final Submit Action Button ---
  Widget _buildFinalSubmitButton() {
    return Obx(() {
      final saving = controller.isSaving.value;
      final canSubmit =
          controller.hasCheckedIn.value && controller.tempLogs.isNotEmpty;

      return Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A).withOpacity(0.9),
          border: Border(
            top: BorderSide(color: Colors.white.withOpacity(0.08), width: 1.0),
          ),
        ),
        child: saving
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
                ),
              )
            : Opacity(
                opacity: canSubmit ? 1.0 : 0.5,
                child: Container(
                  height: 48.h,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: canSubmit
                          ? [const Color(0xFF0F52BA), const Color(0xFF1E3A8A)]
                          : [const Color(0xFF475569), const Color(0xFF334155)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12.r),
                    boxShadow: canSubmit
                        ? [
                            BoxShadow(
                              color: const Color(0xFF0F52BA).withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : [],
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    onPressed: canSubmit ? controller.submitDailyUpdate : null,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.send_rounded, color: Colors.white),
                        SizedBox(width: 8.w),
                        Text(
                          'Submit Daily updates',
                          style: GoogleFonts.inter(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      );
    });
  }
}
