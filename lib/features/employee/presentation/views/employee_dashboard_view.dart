import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stepz_attendance/core/theme/premium_background.dart';
import '../controllers/employee_dashboard_controller.dart';

class EmployeeDashboardView extends GetView<EmployeeDashboardController> {
  const EmployeeDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return PremiumBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        drawer: _buildEmployeeDrawer(context),

        // 1. Top AppBar Shell
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu_rounded, color: Colors.white),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'STEPZ',
            style: GoogleFonts.outfit(
              fontSize: 24.sp,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.6,
            ),
          ),
          actions: [
            // Refresh Button
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              tooltip: 'Refresh Status',
              onPressed: controller.refreshData,
            ),
            // Notification alerts button
            _buildNotificationIconWithBadge(),
            // Work Management shortcut
            IconButton(
              icon: const Icon(
                Icons.business_center_outlined,
                color: Colors.white,
              ),
              tooltip: 'Work Workspace',
              onPressed: () => Get.toNamed('/work-management/menu'),
            ),
            SizedBox(width: 8.w),
            // User Avatar
            Obx(() {
              final name = controller.employeeName.value;
              final initial = name.isNotEmpty ? name[0].toUpperCase() : 'E';
              return Container(
                width: 36.w,
                height: 36.h,
                margin: EdgeInsets.only(right: 16.w),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF1E3A8A),
                  border: Border.all(
                    color: const Color(0xFF3B82F6).withOpacity(0.5),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14.sp,
                    ),
                  ),
                ),
              );
            }),
          ],
        ),

        // 2. Tab-switching Body
        body: SafeArea(
          child: Obx(() {
            switch (controller.activeTabIndex.value) {
              case 0:
                return _buildDashboardOverview(context);
              case 1:
                return _buildAttendanceTab(context);
              case 2:
                return _buildLeavesTab(context);
              case 3:
                return _buildProfileTab(context);
              default:
                return _buildDashboardOverview(context);
            }
          }),
        ),

        // 3. Bottom Navigation Bar Shell
        bottomNavigationBar: Obx(
          () => Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Colors.white.withOpacity(0.08),
                  width: 1.2,
                ),
              ),
            ),
            child: BottomNavigationBar(
              currentIndex: controller.activeTabIndex.value,
              onTap: controller.changeTab,
              type: BottomNavigationBarType.fixed,
              backgroundColor: const Color(0xFF0F172A).withOpacity(0.85),
              selectedItemColor: const Color(0xFF3B82F6),
              unselectedItemColor: const Color(0xFF94A3B8),
              selectedLabelStyle: GoogleFonts.inter(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: GoogleFonts.inter(
                fontSize: 11.sp,
                fontWeight: FontWeight.w400,
              ),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  activeIcon: Icon(Icons.home),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.history_toggle_off),
                  activeIcon: Icon(Icons.history),
                  label: 'Attendance',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.leave_bags_at_home_outlined),
                  activeIcon: Icon(Icons.leave_bags_at_home),
                  label: 'Leaves',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline),
                  activeIcon: Icon(Icons.person),
                  label: 'Profile',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // TAB 0: HOME / CHECK-IN & GEOFENCING DASHBOARD
  Widget _buildDashboardOverview(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: 16.h),

          // Welcome Header Section
          Obx(
            () => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Attendance Center',
                  style: GoogleFonts.inter(
                    fontSize: 28.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Welcome back, ${controller.employeeName.value}. Manage your daily punch in.',
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20.h),

          // Missed Punch Banner
          Obx(() {
            final missedPunch = controller.unregularizedMissedPunch.value;
            if (missedPunch == null) return const SizedBox.shrink();
            return Container(
              margin: EdgeInsets.only(bottom: 16.h),
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFEF4444).withOpacity(0.15),
                    const Color(0xFFF97316).withOpacity(0.15),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: const Color(0xFFF97316).withOpacity(0.3),
                  width: 1.2,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF97316).withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      color: Color(0xFFF97316),
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Missed Punch Detected',
                          style: GoogleFonts.inter(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          'Date: ${missedPunch['date']}\nChecked-In: ${missedPunch['checkIn']}',
                          style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            color: const Color(0xFFCBD5E1),
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8.w),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF97316),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () {
                      Get.toNamed(
                        '/employee/attendance-regularization',
                        arguments: {'missedPunch': missedPunch},
                      );
                    },
                    child: Text(
                      'Submit',
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),


          // 1. Live Clock Card
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
              children: [
                Obx(
                  () => Text(
                    controller.currentTime.value,
                    style: GoogleFonts.inter(
                      fontSize: 44.sp,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -1.0,
                    ),
                  ),
                ),
                SizedBox(height: 4.h),
                Obx(
                  () => Text(
                    controller.currentDate.value,
                    style: GoogleFonts.inter(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),

          // 2. Bento Grid: Map & Geofencing Card
          _buildGeofencingCard(),
          SizedBox(height: 16.h),

          // 3. Bento Grid: Daily Actions Card
          _buildActionsCard(),
          SizedBox(height: 16.h),

          // 4. Hours Worked Summary Chip
          _buildHoursSummaryCard(),
          SizedBox(height: 24.h),

          // Work Workspace Shortcut
          _buildWorkWorkspaceShortcut(context),
          SizedBox(height: 24.h),

          // Holiday Calendar Shortcut
          _buildHolidayCalendarShortcut(context),
          SizedBox(height: 24.h),

          // 5. Daily Work Task Update Card
          _buildWorkTaskUpdateCard(context),
          SizedBox(height: 24.h),

          // 6. Recent Logs List
          _buildRecentLogsSection(),
          SizedBox(height: 32.h),
        ],
      ),
    );
  }

  // WIDGET: Map & Geofencing Card
  Widget _buildGeofencingCard() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16.r),
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Office Status',
                  style: GoogleFonts.inter(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Obx(() {
                final isInside = controller.isInsideGeofence.value;
                return Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 4.h,
                  ),
                  decoration: BoxDecoration(
                    color: isInside
                        ? const Color(0xFF10B981).withOpacity(0.2)
                        : const Color(0xFFEF4444).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: isInside
                          ? const Color(0xFF10B981).withOpacity(0.4)
                          : const Color(0xFFEF4444).withOpacity(0.4),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    isInside ? 'Within Range' : 'Outside Geofence',
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.bold,
                      color: isInside
                          ? const Color(0xFF34D399)
                          : const Color(0xFFF87171),
                    ),
                  ),
                );
              }),
            ],
          ),
          SizedBox(height: 12.h),

          Text(
            'CURRENT LOCATION',
            style: GoogleFonts.inter(
              fontSize: 10.sp,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF64748B),
              letterSpacing: 0.8,
            ),
          ),
          SizedBox(height: 2.h),
          Obx(
            () => Text(
              controller.currentLocationName.value,
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF3B82F6),
              ),
            ),
          ),
          SizedBox(height: 16.h),

          // Circular pulsing radar mock-map visualizer
          Obx(
            () => _buildRadarVisualization(
              distance: controller.distanceToBase.value,
              isInside: controller.isInsideGeofence.value,
            ),
          ),
          SizedBox(height: 16.h),

          // Distance Details
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    vertical: 10.h,
                    horizontal: 12.w,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.06),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Distance to Base',
                        style: GoogleFonts.inter(
                          fontSize: 10.sp,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Obx(
                        () => Text(
                          '${controller.distanceToBase.value.toStringAsFixed(2)} KM',
                          style: GoogleFonts.inter(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF3B82F6),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    vertical: 10.h,
                    horizontal: 12.w,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.06),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Policy Range',
                        style: GoogleFonts.inter(
                          fontSize: 10.sp,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Obx(() {
                        final r = controller.policyRangeMetres.value;
                        final display = r >= 1000
                            ? '${(r / 1000).toStringAsFixed(2)} KM'
                            : '${r.toStringAsFixed(0)} M';
                        return Text(
                          display,
                          style: GoogleFonts.inter(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // WIDGET: Radar View
  Widget _buildRadarVisualization({
    required double distance,
    required bool isInside,
  }) {
    return Container(
      height: 120.h,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Concentric Rings
          Container(
            width: 100.w,
            height: 100.h,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF3B82F6).withOpacity(0.12),
                width: 1.5,
              ),
            ),
          ),
          Container(
            width: 60.w,
            height: 60.h,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF3B82F6).withOpacity(0.22),
                width: 1.5,
              ),
            ),
          ),

          // Office Base Hub (Center)
          Container(
            width: 24.w,
            height: 24.h,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF3B82F6).withOpacity(0.2),
            ),
            child: Center(
              child: Container(
                width: 10.w,
                height: 10.h,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF3B82F6),
                ),
              ),
            ),
          ),

          // User Dot (Position shifts based on simulation state)
          AnimatedAlign(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
            alignment: isInside
                ? const Alignment(0.0, 0.35)
                : const Alignment(0.85, -0.65),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 3.h,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A).withOpacity(0.9),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color: const Color(0xFF3B82F6),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      isInside
                          ? 'You (In Base)'
                          : 'You (${(distance * 1000).toInt()}m away)',
                      style: GoogleFonts.inter(
                        fontSize: 9.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Container(
                    width: 12.w,
                    height: 12.h,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isInside
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444),
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color:
                              (isInside
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFFEF4444))
                                  .withOpacity(0.4),
                          blurRadius: 6,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // WIDGET: Daily Actions Card
  Widget _buildActionsCard() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16.r),
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Daily Actions',
            style: GoogleFonts.inter(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 12.h),

          // Display warnings/status indicators
          Obx(() {
            final isInside = controller.isInsideGeofence.value;
            final isWfh = controller.isWFH.value;
            final isConfigured = controller.isSettingsConfigured.value;
            final settingsLoaded = controller.officeSettingsLoaded.value;

            if (!settingsLoaded) {
              return Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: const Color(0xFFFCD34D).withOpacity(0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.hourglass_empty,
                        color: Color(0xFFFCD34D),
                        size: 18,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'Loading office geofence settings...',
                          style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            color: const Color(0xFFFCD34D),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (!isConfigured) {
              return Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: const Color(0xFFEF4444).withOpacity(0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: Color(0xFFF87171),
                        size: 18,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'Office geofence not configured. Contact your admin to set up the office location.',
                          style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            color: const Color(0xFFF87171),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (!isInside && !isWfh && !controller.isCheckedIn.value) {
              final r = controller.policyRangeMetres.value;
              final rangeStr = r >= 1000
                  ? '${(r / 1000).toStringAsFixed(2)} km'
                  : '${r.toStringAsFixed(0)} m';
              return Container(
                padding: EdgeInsets.all(12.w),
                margin: EdgeInsets.only(bottom: 12.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: const Color(0xFFEF4444).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.location_off_outlined,
                      color: Color(0xFFF87171),
                      size: 18,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        'You are outside the office geofence. Move within $rangeStr of ${controller.officeName.value} to check in.',
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          color: const Color(0xFFF87171),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          }),

          // Punch Actions
          Obx(() {
            final isCheckedIn = controller.isCheckedIn.value;
            final isCheckedOut = controller.isCheckedOut.value;

            int mode = 0;
            if (isCheckedIn && !isCheckedOut) {
              mode = 1;
            } else if (isCheckedIn && isCheckedOut) {
              mode = 2;
            }

            final bool isInsideOrWfh =
                controller.isInsideGeofence.value || controller.isWFH.value;
            final String actionText = mode == 0
                ? 'PUNCH IN'
                : (mode == 1 ? 'PUNCH OUT' : 'COMPLETED');

            final IconData icon = mode == 2
                ? Icons.check_circle_outline
                : Icons.fingerprint;

            void onTap() {
              if (mode == 0) {
                if (isInsideOrWfh) {
                  controller.checkIn();
                } else {
                  final r = controller.policyRangeMetres.value;
                  final rangeStr = r >= 1000
                      ? '${(r / 1000).toStringAsFixed(2)} km'
                      : '${r.toStringAsFixed(0)} m';
                  Get.rawSnackbar(
                    title: 'Outside Geofence',
                    message: controller.isSettingsConfigured.value
                        ? 'Please move within $rangeStr of ${controller.officeName.value} or enable WFH to check in.'
                        : 'Office geofence settings are not configured yet.',
                    backgroundColor: const Color(0xFFBA1A1A),
                    snackPosition: SnackPosition.BOTTOM,
                    duration: const Duration(seconds: 4),
                  );
                }
              } else if (mode == 1) {
                controller.checkOut();
              } else {
                Get.rawSnackbar(
                  title: 'Shift Completed',
                  message:
                      'You have already checked out for today. See you tomorrow!',
                  backgroundColor: const Color(0xFF16A34A),
                  snackPosition: SnackPosition.BOTTOM,
                );
              }
            }

            LinearGradient gradient;
            Color shadowColor;
            Color glowColor;

            if (mode == 0) {
              if (isInsideOrWfh) {
                gradient = const LinearGradient(
                  colors: [Color(0xFF0F52BA), Color(0xFF3B82F6)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                );
                shadowColor = const Color(0xFF0F52BA);
                glowColor = const Color(0xFF3B82F6);
              } else {
                gradient = const LinearGradient(
                  colors: [Color(0xFF1E293B), Color(0xFF334155)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                );
                shadowColor = const Color(0xFF0F172A);
                glowColor = const Color(0xFF1E293B);
              }
            } else if (mode == 1) {
              gradient = const LinearGradient(
                colors: [Color(0xFFEF4444), Color(0xFFF87171)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              );
              shadowColor = const Color(0xFFDC2626);
              glowColor = const Color(0xFFF87171);
            } else {
              gradient = const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF34D399)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              );
              shadowColor = const Color(0xFF059669);
              glowColor = const Color(0xFF34D399);
            }

            final timeStr = _formatTimeToDisplay(controller.currentTime.value);

            return Column(
              children: [
                SizedBox(height: 16.h),
                // Circular Punch Button
                Center(
                  child: Container(
                    width: 190.w,
                    height: 190.h,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: gradient,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.35),
                        width: 4.w,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: shadowColor.withOpacity(0.35),
                          blurRadius: 30.r,
                          spreadRadius: 3.r,
                          offset: const Offset(0, 14),
                        ),
                        BoxShadow(
                          color: glowColor.withOpacity(0.25),
                          blurRadius: 15.r,
                          spreadRadius: 1.r,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: onTap,
                        customBorder: const CircleBorder(),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(icon, color: Colors.white, size: 48.sp),
                            SizedBox(height: 12.h),
                            Text(
                              timeStr,
                              style: GoogleFonts.inter(
                                fontSize: 28.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                            SizedBox(height: 6.h),
                            Text(
                              actionText,
                              style: GoogleFonts.inter(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w800,
                                color: Colors.white.withOpacity(0.95),
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 24.h),

                // Status Pill
                _buildStatusPill(mode),

                if (mode == 0 && !isInsideOrWfh)
                  Padding(
                    padding: EdgeInsets.only(top: 12.h),
                    child: Obx(() {
                      final r = controller.policyRangeMetres.value;
                      final rangeStr = r >= 1000
                          ? '${(r / 1000).toStringAsFixed(2)} km'
                          : '${r.toStringAsFixed(0)} m';
                      return Text(
                        controller.isSettingsConfigured.value
                            ? 'Move within $rangeStr of office to check in'
                            : 'Office settings not configured',
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          color: const Color(0xFFF87171),
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      );
                    }),
                  ),
                if (mode == 1)
                  Padding(
                    padding: EdgeInsets.only(top: 12.h),
                    child: Text(
                      'Checked In at: ${controller.checkInTime.value}',
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        color: const Color(0xFF34D399),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                if (mode == 2)
                  Padding(
                    padding: EdgeInsets.only(top: 12.h),
                    child: Text(
                      'Checked In: ${controller.checkInTime.value}  •  Checked Out: ${controller.checkOutTime.value}',
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        color: const Color(0xFF94A3B8),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            );
          }),

          // Divider & WFH toggle
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(child: Divider(color: Colors.white.withOpacity(0.12))),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.w),
                child: Text(
                  'OR REMOTE WORK',
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ),
              Expanded(child: Divider(color: Colors.white.withOpacity(0.12))),
            ],
          ),
          SizedBox(height: 12.h),

          Obx(
            () => OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(
                  color: controller.isWFH.value
                      ? const Color(0xFF3B82F6)
                      : Colors.white.withOpacity(0.12),
                  width: 1.5,
                ),
                backgroundColor: controller.isWFH.value
                    ? const Color(0xFF3B82F6).withOpacity(0.2)
                    : Colors.white.withOpacity(0.04),
                padding: EdgeInsets.symmetric(vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              onPressed: () => controller.markWFH(),
              icon: Icon(
                controller.isWFH.value
                    ? Icons.home_work
                    : Icons.home_work_outlined,
                size: 18.sp,
                color: controller.isWFH.value
                    ? const Color(0xFF3B82F6)
                    : Colors.white,
              ),
              label: Text(
                controller.isWFH.value ? 'Marked WFH' : 'Mark WFH',
                style: GoogleFonts.inter(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.bold,
                  color: controller.isWFH.value
                      ? const Color(0xFF3B82F6)
                      : Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // WIDGET: Hours Worked Summary Card
  Widget _buildHoursSummaryCard() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F52BA), Color(0xFF1E3A8A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F52BA).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.timer_outlined,
              color: Colors.white,
              size: 28,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'HOURS TODAY',
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white.withOpacity(0.8),
                    letterSpacing: 0.8,
                  ),
                ),
                SizedBox(height: 2.h),
                Obx(
                  () => Text(
                    controller.hoursWorkedToday.value,
                    style: GoogleFonts.inter(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 40.h,
            width: 1.w,
            color: Colors.white.withOpacity(0.2),
          ),
          SizedBox(width: 16.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'REQUIRED',
                style: GoogleFonts.inter(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white.withOpacity(0.8),
                  letterSpacing: 0.8,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                '08h 00m',
                style: GoogleFonts.inter(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // WIDGET: Recent Logs Section
  Widget _buildRecentLogsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Recent Logs',
                style: GoogleFonts.inter(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TextButton(
              onPressed: () {
                controller.changeTab(1); // Go to logs tab
              },
              child: Text(
                'View All Records',
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF3B82F6),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),

        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: Colors.white.withOpacity(0.12),
              width: 1.2,
            ),
          ),
          child: Column(
            children: [
              // Table Header
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(15.r),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        'DATE',
                        style: GoogleFonts.inter(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'CHECK IN',
                        style: GoogleFonts.inter(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'CHECK OUT',
                        style: GoogleFonts.inter(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'LOCATION',
                        style: GoogleFonts.inter(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF94A3B8),
                        ),
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
              ),

              // Table Body
              Obx(() {
                if (controller.recentLogs.isEmpty) {
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: 20.h),
                    child: Center(
                      child: Text(
                        'No check-in logs found.',
                        style: GoogleFonts.inter(
                          fontSize: 13.sp,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: controller.recentLogs.take(3).length,
                  separatorBuilder: (context, index) =>
                      Divider(height: 1, color: Colors.white.withOpacity(0.08)),
                  itemBuilder: (context, index) {
                    final log = controller.recentLogs[index];
                    final isWfh = log['location'] == 'WFH';

                    return Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 14.h,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(
                              log['date'] ?? 'Oct 23, 2023',
                              style: GoogleFonts.inter(
                                fontSize: 13.sp,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              log['checkIn'] ?? '--',
                              style: GoogleFonts.inter(
                                fontSize: 13.sp,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              log['checkOut'] ?? '--',
                              style: GoogleFonts.inter(
                                fontSize: 13.sp,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8.w,
                                  vertical: 3.h,
                                ),
                                decoration: BoxDecoration(
                                  color: isWfh
                                      ? const Color(0xFF3B82F6).withOpacity(0.2)
                                      : const Color(
                                          0xFF10B981,
                                        ).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8.r),
                                  border: Border.all(
                                    color: isWfh
                                        ? const Color(
                                            0xFF3B82F6,
                                          ).withOpacity(0.4)
                                        : const Color(
                                            0xFF10B981,
                                          ).withOpacity(0.4),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  log['location'] ?? 'Office',
                                  style: GoogleFonts.inter(
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.bold,
                                    color: isWfh
                                        ? const Color(0xFF60A5FA)
                                        : const Color(0xFF34D399),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  // TAB 1: ATTENDANCE HISTORY LIST & STATS
  Widget _buildAttendanceTab(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: 16.h),
          Text(
            'Attendance History',
            style: GoogleFonts.inter(
              fontSize: 28.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'Check your daily logs and working stats details.',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              color: const Color(0xFF94A3B8),
            ),
          ),
          SizedBox(height: 20.h),

          // Total Stats Bento
          Obx(
            () => Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildLogSummaryStatCard(
                        'Total Logs',
                        '${controller.totalActiveDays.value} Days',
                        Icons.assignment_outlined,
                        const Color(0xFF3B82F6),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: _buildLogSummaryStatCard(
                        'Avg Hours',
                        controller.averageWorkingHours.value,
                        Icons.schedule_outlined,
                        const Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                Row(
                  children: [
                    Expanded(
                      child: _buildLogSummaryStatCard(
                        'Late Check-ins',
                        '${controller.totalLateCheckIns.value} Days',
                        Icons.warning_amber_rounded,
                        const Color(0xFFD97706),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: _buildLogSummaryStatCard(
                        'WFH Days',
                        '${controller.totalWfhDays.value} Days',
                        Icons.home_work_outlined,
                        const Color(0xFF8B5CF6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 20.h),

          // Full Logs List Container
          Text(
            'All Logs',
            style: GoogleFonts.inter(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8.h),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: Colors.white.withOpacity(0.12),
                width: 1.2,
              ),
            ),
            child: Obx(() {
              if (controller.recentLogs.isEmpty) {
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 30.h),
                  child: Center(
                    child: Text(
                      'No check-in logs found.',
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ),
                );
              }
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: controller.recentLogs.length,
                separatorBuilder: (context, index) =>
                    Divider(height: 1, color: Colors.white.withOpacity(0.08)),
                itemBuilder: (context, index) {
                  final log = controller.recentLogs[index];
                  final isWfh = log['location'] == 'WFH';
                  final isLate = log['isLate'] == true;
                  return ListTile(
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 8.h,
                    ),
                    title: Text(
                      log['date'] ?? '',
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    subtitle: Row(
                      children: [
                        Text(
                          'Punch: ${log['checkIn']} - ${log['checkOut']}',
                          style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                        if (isLate) ...[
                          SizedBox(width: 8.w),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 6.w,
                              vertical: 2.h,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD97706).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                            child: Text(
                              'LATE',
                              style: GoogleFonts.inter(
                                fontSize: 9.sp,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFFBBF24),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    trailing: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: isWfh
                            ? const Color(0xFF3B82F6).withOpacity(0.2)
                            : const Color(0xFF10B981).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(
                          color: isWfh
                              ? const Color(0xFF3B82F6).withOpacity(0.4)
                              : const Color(0xFF10B981).withOpacity(0.4),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        log['location'] ?? 'Office',
                        style: GoogleFonts.inter(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.bold,
                          color: isWfh
                              ? const Color(0xFF60A5FA)
                              : const Color(0xFF34D399),
                        ),
                      ),
                    ),
                  );
                },
              );
            }),
          ),
          SizedBox(height: 32.h),
        ],
      ),
    );
  }

  Widget _buildLogSummaryStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.white.withOpacity(0.12), width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20.sp),
          ),
          SizedBox(width: 12.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 10.sp,
                  color: const Color(0xFF94A3B8),
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // TAB 2: LEAVES
  Widget _buildLeavesTab(BuildContext context) {
    // Leave Application Form states
    final RxString selectedType = 'Annual Leave'.obs;
    final Rx<DateTime> selectedStartDate = DateTime.now().obs;
    final Rx<DateTime> selectedEndDate = DateTime.now()
        .add(const Duration(days: 1))
        .obs;
    final reasonController = TextEditingController();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: 16.h),
          Text(
            'Leaves & Timeoff',
            style: GoogleFonts.inter(
              fontSize: 28.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'Apply for leave or check status of requests.',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              color: const Color(0xFF94A3B8),
            ),
          ),
          SizedBox(height: 24.h),

          // Leave Balance Cards
          Obx(
            () => Row(
              children: [
                Expanded(
                  child: _buildLeaveBalanceCard(
                    'Annual Leave',
                    '${controller.annualLeavesLeft.value} Left',
                    const Color(0xFF3B82F6),
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: _buildLeaveBalanceCard(
                    'Sick Leave',
                    '${controller.sickLeavesLeft.value} Left',
                    const Color(0xFF10B981),
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: _buildLeaveBalanceCard(
                    'Casual Leave',
                    '${controller.casualLeavesLeft.value} Left',
                    const Color(0xFFFBBF24),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20.h),

          // Request Leave Button
          Container(
            height: 50.h,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F52BA), Color(0xFF1E3A8A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12.r),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F52BA).withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              onPressed: () {
                reasonController.clear();
                selectedStartDate.value = DateTime.now();
                selectedEndDate.value = DateTime.now().add(
                  const Duration(days: 1),
                );

                Get.defaultDialog(
                  title: 'Apply for Leave',
                  titleStyle: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 18.sp,
                    color: Colors.white,
                  ),
                  backgroundColor: const Color(0xFF0F172A),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 12.h,
                  ),
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Dropdown for Leave Type
                      Text(
                        'LEAVE TYPE',
                        style: GoogleFonts.inter(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12.w),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                        child: Obx(
                          () => DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              dropdownColor: const Color(0xFF1E293B),
                              value: selectedType.value,
                              icon: const Icon(
                                Icons.arrow_drop_down,
                                color: Colors.white,
                              ),
                              items:
                                  <String>[
                                    'Annual Leave',
                                    'Sick Leave',
                                    'Casual Leave',
                                  ].map<DropdownMenuItem<String>>((
                                    String value,
                                  ) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(
                                        value,
                                        style: GoogleFonts.inter(
                                          color: Colors.white,
                                          fontSize: 14.sp,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                              onChanged: (String? newValue) {
                                if (newValue != null) {
                                  selectedType.value = newValue;
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 16.h),

                      // Start & End Dates Pickers
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'START DATE',
                                  style: GoogleFonts.inter(
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                                SizedBox(height: 6.h),
                                InkWell(
                                  onTap: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: selectedStartDate.value,
                                      firstDate: DateTime.now().subtract(
                                        const Duration(days: 30),
                                      ),
                                      lastDate: DateTime.now().add(
                                        const Duration(days: 365),
                                      ),
                                    );
                                    if (picked != null) {
                                      selectedStartDate.value = picked;
                                    }
                                  },
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      vertical: 10.h,
                                      horizontal: 12.w,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(8.r),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.1),
                                      ),
                                    ),
                                    child: Obx(
                                      () => Text(
                                        DateFormat(
                                          'yyyy-MM-dd',
                                        ).format(selectedStartDate.value),
                                        style: GoogleFonts.inter(
                                          color: Colors.white,
                                          fontSize: 13.sp,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'END DATE',
                                  style: GoogleFonts.inter(
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                                SizedBox(height: 6.h),
                                InkWell(
                                  onTap: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: selectedEndDate.value,
                                      firstDate: selectedStartDate.value,
                                      lastDate: DateTime.now().add(
                                        const Duration(days: 365),
                                      ),
                                    );
                                    if (picked != null) {
                                      selectedEndDate.value = picked;
                                    }
                                  },
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      vertical: 10.h,
                                      horizontal: 12.w,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(8.r),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.1),
                                      ),
                                    ),
                                    child: Obx(
                                      () => Text(
                                        DateFormat(
                                          'yyyy-MM-dd',
                                        ).format(selectedEndDate.value),
                                        style: GoogleFonts.inter(
                                          color: Colors.white,
                                          fontSize: 13.sp,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16.h),

                      // Reason TextField
                      Text(
                        'REASON',
                        style: GoogleFonts.inter(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      SizedBox(height: 6.h),
                      TextField(
                        controller: reasonController,
                        maxLines: 3,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 13.sp,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Describe why you need leave...',
                          hintStyle: GoogleFonts.inter(color: Colors.white38),
                          fillColor: Colors.white.withOpacity(0.05),
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r),
                            borderSide: BorderSide(
                              color: Colors.white.withOpacity(0.1),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r),
                            borderSide: BorderSide(
                              color: Colors.white.withOpacity(0.1),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r),
                            borderSide: const BorderSide(
                              color: Color(0xFF3B82F6),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  textConfirm: 'SUBMIT',
                  textCancel: 'CANCEL',
                  confirmTextColor: Colors.white,
                  cancelTextColor: const Color(0xFF94A3B8),
                  buttonColor: const Color(0xFF0F52BA),
                  onConfirm: () {
                    controller.applyForLeave(
                      type: selectedType.value,
                      startDate: selectedStartDate.value,
                      endDate: selectedEndDate.value,
                      reason: reasonController.text,
                    );
                  },
                );
              },
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text(
                'Request Leave',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          SizedBox(height: 24.h),

          // Leave Requests
          Text(
            'Request History',
            style: GoogleFonts.inter(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8.h),

          Obx(() {
            if (controller.isLoadingLeaves.value) {
              return Padding(
                padding: EdgeInsets.symmetric(vertical: 24.h),
                child: const Center(
                  child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
                ),
              );
            }
            if (controller.leaveHistory.isEmpty) {
              return Container(
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: Colors.white.withOpacity(0.06)),
                ),
                child: Center(
                  child: Text(
                    'No leave request history found.',
                    style: GoogleFonts.inter(
                      fontSize: 13.sp,
                      color: Colors.white38,
                    ),
                  ),
                ),
              );
            }
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: controller.leaveHistory.length,
              separatorBuilder: (context, index) => SizedBox(height: 12.h),
              itemBuilder: (context, index) {
                final request = controller.leaveHistory[index];
                final String status = request['status'] ?? 'pending';
                final String type = request['leaveType'] ?? 'Annual Leave';
                final String startStr = request['startDate'] ?? '';
                final String endStr = request['endDate'] ?? '';
                final String reason = request['reason'] ?? '';
                final String rejection = request['rejectionReason'] ?? '';

                Color statusColor;
                String statusLabel;
                if (status == 'approved') {
                  statusColor = const Color(0xFF10B981);
                  statusLabel = 'Approved';
                } else if (status == 'rejected') {
                  statusColor = const Color(0xFFEF4444);
                  statusLabel = 'Rejected';
                } else {
                  statusColor = const Color(0xFFFBBF24);
                  statusLabel = 'Pending';
                }

                return Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.12),
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
                            type,
                            style: GoogleFonts.inter(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10.w,
                              vertical: 4.h,
                            ),
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
                                fontSize: 11.sp,
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        '$startStr  →  $endStr',
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          color: const Color(0xFF94A3B8),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'Reason: $reason',
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          color: Colors.white70,
                        ),
                      ),
                      if (status == 'rejected' && rejection.isNotEmpty) ...[
                        SizedBox(height: 8.h),
                        Container(
                          padding: EdgeInsets.all(8.w),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(
                              color: const Color(0xFFEF4444).withOpacity(0.2),
                            ),
                          ),
                          child: Text(
                            'Reason for Rejection: $rejection',
                            style: GoogleFonts.inter(
                              fontSize: 11.sp,
                              color: const Color(0xFFF87171),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            );
          }),
          SizedBox(height: 32.h),
        ],
      ),
    );
  }

  Widget _buildLeaveBalanceCard(String type, String count, Color color) {
    return Container(
      padding: EdgeInsets.all(5.w),
    
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.white.withOpacity(0.12), width: 1.2),
      ),
      child: Column(
        mainAxisAlignment:MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            type,
            style: GoogleFonts.inter(
              fontSize: 10.sp,
              color: const Color(0xFF94A3B8),
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            count,
            style: GoogleFonts.inter(
              fontSize: 10.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // TAB 3: PROFILE
  Widget _buildProfileTab(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: 32.h),

          // Profile Photo & Intro
          Center(
            child: Column(
              children: [
                Container(
                  width: 90.w,
                  height: 90.h,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF1E3A8A),
                    border: Border.all(
                      color: const Color(0xFF3B82F6).withOpacity(0.5),
                      width: 3,
                    ),
                  ),
                  child: Center(
                    child: Obx(() {
                      final name = controller.employeeName.value;
                      final initial = name.isNotEmpty
                          ? name[0].toUpperCase()
                          : 'E';
                      return Text(
                        initial,
                        style: GoogleFonts.inter(
                          fontSize: 32.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      );
                    }),
                  ),
                ),
                SizedBox(height: 16.h),
                Obx(
                  () => Text(
                    controller.employeeName.value,
                    style: GoogleFonts.inter(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(height: 4.h),
                Obx(
                  () => Text(
                    controller.employeeDesignation.value,
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      color: const Color(0xFF94A3B8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 32.h),

          // User Info Fields
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: Colors.white.withOpacity(0.12),
                width: 1.2,
              ),
            ),
            child: Column(
              children: [
                _buildProfileDetailRow('Employee ID', controller.employeeId),
                Divider(height: 24, color: Colors.white.withOpacity(0.08)),
                _buildProfileDetailRow('Gmail/Email', controller.employeeEmail),
                Divider(height: 24, color: Colors.white.withOpacity(0.08)),
                _buildProfileDetailRow(
                  'Workplace Role',
                  RxString('Standard Employee'),
                ),
              ],
            ),
          ),
          SizedBox(height: 24.h),

          // Attendance Reminder Settings Card
          _buildSettingsCard(context),
          SizedBox(height: 24.h),

          _buildRegularizationStatsWidget(),
          SizedBox(height: 24.h),

          // Reset Password Button
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: BorderSide(color: const Color(0xFF3B82F6), width: 1.5),
              backgroundColor: const Color(0xFF3B82F6).withOpacity(0.1),
              padding: EdgeInsets.symmetric(vertical: 14.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            onPressed: () {
              Get.defaultDialog(
                title: 'Reset Password',
                titleStyle: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 18.sp,
                ),
                middleText:
                    'Do you want to send a secure password reset link to ${controller.employeeEmail.value}?',
                middleTextStyle: GoogleFonts.inter(fontSize: 14.sp),
                textConfirm: 'Send Link',
                textCancel: 'Cancel',
                confirmTextColor: Colors.white,
                cancelTextColor: const Color(0xFF94A3B8),
                buttonColor: const Color(0xFF1E3A8A),
                onConfirm: () {
                  Get.back();
                  controller.sendPasswordResetEmail();
                },
              );
            },
            icon: const Icon(
              Icons.lock_reset_rounded,
              color: Color(0xFF3B82F6),
            ),
            label: Text(
              'Reset Password',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          SizedBox(height: 12.h),

          // Logout Button
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 14.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              elevation: 0,
            ),
            onPressed: () => controller.logout(),
            icon: const Icon(Icons.logout),
            label: Text(
              'Log Out',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(height: 48.h),
        ],
      ),
    );
  }

  Widget _buildProfileDetailRow(String label, RxString value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13.sp,
            color: const Color(0xFF94A3B8),
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: Obx(
            () => Text(
              value.value,
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }

  // WIDGET: Daily Work Task Update Card
  Widget _buildWorkTaskUpdateCard(BuildContext context) {
    final glassColor = Colors.white.withOpacity(0.08);
    final borderColor = Colors.white.withOpacity(0.12);
    const textColor = Colors.white;
    const subTextColor = Color(0xFF94A3B8);

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: glassColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: borderColor, width: 1.2),
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
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  Icons.auto_awesome,
                  color: const Color(0xFF3B82F6),
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Daily Task Update',
                      style: GoogleFonts.inter(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'Voice translation standup reports',
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        color: subTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),

          Obx(() {
            final hasUpdate =
                controller.rxProjectName.value.trim().isNotEmpty &&
                controller.rxTaskDetails.value.trim().isNotEmpty;

            if (hasUpdate) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(color: borderColor.withOpacity(0.5)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              controller.rxProjectName.value,
                              style: GoogleFonts.inter(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8.w,
                                vertical: 3.h,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(
                                  controller.selectedTaskStatus.value,
                                ).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6.r),
                              ),
                              child: Text(
                                controller.selectedTaskStatus.value,
                                style: GoogleFonts.inter(
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.bold,
                                  color: _getStatusColor(
                                    controller.selectedTaskStatus.value,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          controller.rxTaskDetails.value,
                          style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            color: textColor.withOpacity(0.8),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),
                  _buildActionButton(
                    label: 'Edit Task Update',
                    icon: Icons.mic_none_rounded,
                    isEdit: true,
                  ),
                ],
              );
            } else {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'No status update submitted for today yet. Use premium AI speech translation to submit your task report naturally in Malayalam.',
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      color: subTextColor,
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  _buildActionButton(
                    label: 'Speak Task Update',
                    icon: Icons.mic_rounded,
                    isEdit: false,
                  ),
                ],
              );
            }
          }),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return const Color(0xFF10B981);
      case 'pending':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF3B82F6);
    }
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required bool isEdit,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isEdit
              ? [const Color(0xFF475569), const Color(0xFF334155)]
              : [const Color(0xFF0F52BA), const Color(0xFF1E3A8A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: (isEdit ? Colors.black : const Color(0xFF0F52BA))
                .withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: EdgeInsets.symmetric(vertical: 12.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
        onPressed: () => Get.toNamed('/employee/daily-task-update'),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 16.sp),
            SizedBox(width: 8.w),
            Flexible(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusPill(int mode) {
    String statusText = 'Status: Not In';
    Color dotColor = const Color(0xFFEF4444);

    if (mode == 1) {
      statusText = 'Status: Checked In';
      dotColor = const Color(0xFF10B981);
    } else if (mode == 2) {
      statusText = 'Status: Checked Out';
      dotColor = const Color(0xFF94A3B8);
    }

    return Center(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(100.r),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8.w,
              height: 8.h,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: 8.w),
            Text(
              statusText,
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkWorkspaceShortcut(BuildContext context) {
    final glassColor = Colors.white.withOpacity(0.08);
    final borderColor = Colors.white.withOpacity(0.12);
    const textColor = Colors.white;
    const subTextColor = Color(0xFF94A3B8);

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: glassColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: borderColor, width: 1.2),
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
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  Icons.business_center_rounded,
                  color: const Color(0xFF3B82F6),
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Work & Tasks Workspace',
                      style: GoogleFonts.inter(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'Manage assignments & voice reports',
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        color: subTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Text(
            'Access your projects, check assigned tasks, submit Malayalam standup reports rewritten by AI, and view performance logs.',
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              color: subTextColor,
              height: 1.4,
            ),
          ),
          SizedBox(height: 16.h),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12.r),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3B82F6).withOpacity(0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: EdgeInsets.symmetric(vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              onPressed: () => Get.toNamed('/work-management/menu'),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 16.sp,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    'Open Workspace',
                    style: GoogleFonts.inter(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimeToDisplay(String timeStr) {
    if (timeStr.isEmpty) return '--:--';
    try {
      final parts = timeStr.split(' ');
      final timeParts = parts[0].split(':');
      if (timeParts.length >= 2) {
        return '${timeParts[0]}:${timeParts[1]} ${parts.last}';
      }
    } catch (e) {
      debugPrint('Error formatting time: $e');
    }
    return timeStr;
  }

  // WIDGET: Holiday Calendar Shortcut Card
  Widget _buildHolidayCalendarShortcut(BuildContext context) {
    final glassColor = Colors.white.withOpacity(0.08);
    final borderColor = Colors.white.withOpacity(0.12);
    const textColor = Colors.white;
    const subTextColor = Color(0xFF94A3B8);

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: glassColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: borderColor, width: 1.2),
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
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  Icons.calendar_month_rounded,
                  color: const Color(0xFFEF4444),
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Holiday Calendar',
                      style: GoogleFonts.inter(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'View company & public holidays',
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        color: subTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Text(
            'Keep track of upcoming national, regional, and company-specific holidays to plan your tasks and leaves accordingly.',
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              color: subTextColor,
              height: 1.4,
            ),
          ),
          SizedBox(height: 16.h),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFEF4444), Color(0xFFB91C1C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12.r),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFEF4444).withOpacity(0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: EdgeInsets.symmetric(vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              onPressed: () => Get.toNamed('/employee/holiday-calendar'),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 16.sp,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    'Open Calendar',
                    style: GoogleFonts.inter(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // WIDGET: Premium Side Drawer (Glassmorphic)
  Widget _buildEmployeeDrawer(BuildContext context) {
    const textColor = Colors.white;
    const subTextColor = Colors.white54;

    return Drawer(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A).withOpacity(0.45),
              border: Border(
                right: BorderSide(
                  color: Colors.white.withOpacity(0.1),
                  width: 1.0,
                ),
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Drawer Header
                  Obx(() {
                    final name = controller.employeeName.value;
                    final email = controller.employeeEmail.value;
                    final initial = name.isNotEmpty
                        ? name[0].toUpperCase()
                        : 'E';
                    return Container(
                      padding: EdgeInsets.all(24.w),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.white.withOpacity(0.08),
                            width: 1.2,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48.w,
                            height: 48.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF3B82F6),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 1.5,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                initial,
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
                                  name.isNotEmpty ? name : 'Employee',
                                  style: GoogleFonts.outfit(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  email.isNotEmpty
                                      ? email
                                      : 'employee@stepz.com',
                                  style: GoogleFonts.inter(
                                    fontSize: 11.sp,
                                    color: subTextColor,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                  // Drawer List Items
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.symmetric(
                        vertical: 16.h,
                        horizontal: 12.w,
                      ),
                      children: [
                        _buildDrawerItem(
                          icon: Icons.home_rounded,
                          title: 'Dashboard',
                          color: const Color(0xFF3B82F6),
                          onTap: () {
                            Get.back();
                            controller.activeTabIndex.value = 0;
                          },
                          textColor: textColor,
                        ),
                        _buildDrawerItem(
                          icon: Icons.business_center_rounded,
                          title: 'Work Workspace',
                          color: const Color(0xFF10B981),
                          onTap: () {
                            Get.back();
                            Get.toNamed('/work-management/menu');
                          },
                          textColor: textColor,
                        ),
                        _buildDrawerItem(
                          icon: Icons.calendar_month_rounded,
                          title: 'Holiday Calendar',
                          color: const Color(0xFFEF4444),
                          onTap: () {
                            Get.back();
                            Get.toNamed('/employee/holiday-calendar');
                          },
                          textColor: textColor,
                        ),
                        _buildDrawerItem(
                          icon: Icons.notifications_rounded,
                          title: 'Notifications',
                          color: const Color(0xFFF59E0B),
                          onTap: () {
                            Get.back();
                            Get.toNamed('/notifications');
                          },
                          textColor: textColor,
                        ),
                        _buildDrawerItem(
                          icon: Icons.history_toggle_off_rounded,
                          title: 'Attendance Regularization',
                          color: const Color(0xFFF97316),
                          onTap: () {
                            Get.back();
                            Get.toNamed('/employee/attendance-regularization');
                          },
                          textColor: textColor,
                        ),
                      ],
                    ),
                  ),

                  // Logout Footer
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: Colors.white.withOpacity(0.08),
                          width: 1.2,
                        ),
                      ),
                    ),
                    child: _buildDrawerItem(
                      icon: Icons.logout_rounded,
                      title: 'Log Out',
                      color: Colors.redAccent,
                      onTap: () {
                        Get.back();
                        controller.logout();
                      },
                      textColor: textColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
    required Color textColor,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(6.w),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(icon, color: color, size: 18.sp),
        ),
        title: Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: Colors.white30,
          size: 18,
        ),
        onTap: onTap,
        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 2.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
    );
  }

  Widget _buildNotificationIconWithBadge() {
    if (controller.isTesting) {
      return IconButton(
        icon: const Icon(
          Icons.notifications_none_outlined,
          color: Colors.white,
        ),
        onPressed: () => Get.toNamed('/notifications'),
      );
    }
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return IconButton(
        icon: const Icon(
          Icons.notifications_none_outlined,
          color: Colors.white,
        ),
        onPressed: () => Get.toNamed('/notifications'),
      );
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('notifications')
          .snapshots(),
      builder: (context, snapshot) {
        int unreadCount = 0;
        if (snapshot.hasData) {
          final docs = snapshot.data!.docs;
          unreadCount = docs.where((doc) {
            final data = doc.data();
            final targetUid = data['targetUid'] as String?;
            final targetRole = data['targetRole'] as String?;
            final List<dynamic> readBy = data['readBy'] as List<dynamic>? ?? [];
            final bool isRead =
                data['read'] == true || readBy.contains(currentUser.uid);

            if (isRead) return false;

            if (targetUid == currentUser.uid) return true;
            if (targetRole == 'all') return true;
            if (targetRole == 'employee') return true;
            return false;
          }).length;
        }

        return Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(
                Icons.notifications_none_outlined,
                color: Colors.white,
              ),
              onPressed: () => Get.toNamed('/notifications'),
            ),
            if (unreadCount > 0)
              Positioned(
                right: 6.w,
                top: 6.h,
                child: Container(
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF0F172A),
                      width: 1.5,
                    ),
                  ),
                  constraints: BoxConstraints(minWidth: 16.w, minHeight: 16.w),
                  child: Center(
                    child: Text(
                      unreadCount > 9 ? '9+' : '$unreadCount',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 8.sp,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildSettingsCard(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: Colors.white.withOpacity(0.12),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.notifications_active_outlined, color: const Color(0xFF3B82F6), size: 20.sp),
              SizedBox(width: 8.w),
              Text(
                'Attendance Reminder Settings',
                style: GoogleFonts.inter(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          _buildSwitchRow(
            title: 'Attendance Reminder',
            subtitle: 'Remind to mark attendance when inside office',
            value: controller.enableAttendanceReminder,
            onChanged: (val) => controller.updateEmployeeSetting('attendance_reminder_enabled', val),
          ),
          Divider(height: 24, color: Colors.white.withOpacity(0.08)),
          _buildSwitchRow(
            title: 'Checkout Reminder',
            subtitle: 'Remind to mark checkout at end of shift',
            value: controller.enableCheckoutReminder,
            onChanged: (val) => controller.updateEmployeeSetting('checkout_reminder_enabled', val),
          ),
          Divider(height: 24, color: Colors.white.withOpacity(0.08)),
          _buildSwitchRow(
            title: 'Geofence Notification',
            subtitle: 'Notify on entering geofenced office area',
            value: controller.enableGeofenceNotification,
            onChanged: (val) => controller.updateEmployeeSetting('geofence_notification_enabled', val),
          ),
          Divider(height: 24, color: Colors.white.withOpacity(0.08)),
          _buildSwitchRow(
            title: 'Push Notifications',
            subtitle: 'Receive company broadcasts and announcements',
            value: controller.enablePushNotifications,
            onChanged: (val) => controller.updateEmployeeSetting('push_notifications_enabled', val),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchRow({
    required String title,
    required String subtitle,
    required RxBool value,
    required Function(bool) onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 13.sp,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 10.sp,
                  color: const Color(0xFF94A3B8),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
        Obx(
          () => Switch.adaptive(
            value: value.value,
            onChanged: onChanged,
            activeColor: const Color(0xFF3B82F6),
            activeTrackColor: const Color(0xFF3B82F6).withOpacity(0.3),
            inactiveThumbColor: const Color(0xFF94A3B8),
            inactiveTrackColor: Colors.white.withOpacity(0.1),
          ),
        ),
      ],
    );
  }

  Widget _buildRegularizationStatsWidget() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: Colors.white.withOpacity(0.12),
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
                'Regularization Requests',
                style: GoogleFonts.inter(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
                onPressed: () => Get.toNamed('/employee/attendance-regularization'),
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Obx(
            () => Row(
              children: [
                Expanded(
                  child: _buildStatTile(
                    'Pending',
                    '${controller.pendingRequestsCount.value}',
                    const Color(0xFFF97316),
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: _buildStatTile(
                    'Approved',
                    '${controller.approvedRequestsCount.value}',
                    const Color(0xFF10B981),
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: _buildStatTile(
                    'Rejected',
                    '${controller.rejectedRequestsCount.value}',
                    const Color(0xFFEF4444),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatTile(String label, String value, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: Colors.white.withOpacity(0.06),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              color: const Color(0xFF94A3B8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
