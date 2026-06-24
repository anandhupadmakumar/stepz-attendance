import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:stepz_attendance/core/theme/premium_background.dart';
import 'employee_details_view.dart';

import '../controllers/admin_dashboard_controller.dart';
import '../../../../work_management/presentation/controllers/work_task_controller.dart';

class AdminDashboardView extends GetView<AdminDashboardController> {
  const AdminDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return PremiumBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        // 1. Header TopAppBar Shell
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'STEPZ',
                style: GoogleFonts.outfit(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 2.0,
                ),
              ),
              Text(
                'INVENTION',
                style: GoogleFonts.outfit(
                  fontSize: 8.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.5),
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          actions: [
            // Refresh Button
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
              tooltip: 'Refresh Data',
              onPressed: controller.refreshData,
            ),
            // Notification alerts button
            _buildNotificationIconWithBadge(),
            // Work Management shortcut
            IconButton(
              icon: const Icon(
                Icons.business_center_outlined,
                color: Colors.white70,
              ),
              tooltip: 'Work Console',
              onPressed: () => Get.toNamed('/work-management/menu'),
            ),
            SizedBox(width: 8.w),
            // User Avatar matching Figma profile Avatar style
            Container(
              width: 36.w,
              height: 36.h,
              margin: EdgeInsets.only(right: 16.w),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
                ),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Text(
                  'A',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14.sp,
                  ),
                ),
              ),
            ),
          ],
        ),

        // 2. Tab-switching Body
        body: SafeArea(
          child: Obx(() {
            switch (controller.activeTabIndex.value) {
              case 0:
                return _buildDashboardOverview(context);
              case 1:
                return _buildEmployeeDirectory(context);
              case 2:
                return _buildAttendanceRegistry(context);
              case 3:
                return _buildLeavesOverview(context);
              case 4:
                return _buildProfileOverview(context);
              default:
                return _buildDashboardOverview(context);
            }
          }),
        ),

        // 3. Bottom Navigation Bar Shell
        bottomNavigationBar: Obx(
          () => BottomNavigationBar(
            currentIndex: controller.activeTabIndex.value,
            onTap: controller.changeTab,
            type: BottomNavigationBarType.fixed,
            backgroundColor: const Color(0xFF040A18).withOpacity(0.95),
            selectedItemColor: const Color(0xFF9061FF),
            unselectedItemColor: Colors.white54,
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
                icon: Icon(Icons.people_outline),
                activeIcon: Icon(Icons.people),
                label: 'Employees',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.fact_check_outlined),
                activeIcon: Icon(Icons.fact_check),
                label: 'Attendance',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.time_to_leave_outlined),
                activeIcon: Icon(Icons.time_to_leave),
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
    );
  }

  // Helper: Bento Grid Summary Cards
  Widget _buildBentoGrid() {
    return Obx(
      () => Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  title: 'TOTAL EMPLOYEES',
                  value: controller.totalEmployees.value,
                  subtitle: 'All registered staff',
                  icon: Icons.people_rounded,
                  gradientColors: [
                    const Color(0xFF5B21B6),
                    const Color(0xFF420093),
                  ],
                  accentColor: const Color(0xFF7C3AED),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildSummaryCard(
                  title: 'PRESENT TODAY',
                  value: controller.presentToday.value,
                  subtitle: '94% attendance rate',
                  icon: Icons.check_circle_rounded,
                  gradientColors: [
                    const Color(0xFF059669),
                    const Color(0xFF047857),
                  ],
                  accentColor: const Color(0xFF10B981),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  title: 'ABSENT TODAY',
                  value: controller.absentToday.value,
                  subtitle: 'Needs follow-up',
                  icon: Icons.person_off_rounded,
                  gradientColors: [
                    const Color(0xFFDC2626),
                    const Color(0xFFB91C1C),
                  ],
                  accentColor: const Color(0xFFEF4444),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildSummaryCard(
                  title: 'WFH TODAY',
                  value: controller.wfhToday.value,
                  subtitle: 'Remote workers',
                  icon: Icons.home_work_rounded,
                  gradientColors: [
                    const Color(0xFF4338CA),
                    const Color(0xFF3730A3),
                  ],
                  accentColor: const Color(0xFF6366F1),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper: Premium Summary Card
  Widget _buildSummaryCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required List<Color> gradientColors,
    required Color accentColor,
  }) {
    return Container(
      height: 200.h,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: gradientColors[1].withOpacity(0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative large icon watermark
          Positioned(
            right: -8.w,
            bottom: -8.h,
            child: Icon(icon, size: 80, color: Colors.white.withOpacity(0.08)),
          ),
          // Decorative circle
          Positioned(
            right: 16.w,
            top: -20.h,
            child: Container(
              width: 70.w,
              height: 70.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          // Content
          Padding(
            padding: EdgeInsets.all(10.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Icon badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withOpacity(0.75),
                          letterSpacing: 0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Icon(icon, size: 18, color: Colors.white),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Main value
                    Text(
                      value,
                      style: GoogleFonts.inter(
                        fontSize: 32.sp,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -1,
                        height: 1,
                      ),
                    ),
                    SizedBox(height: 2.h),

                    // Title label
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper: Weekly Trend Chart Card
  Widget _buildTrendChart() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.white.withOpacity(0.12), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header details
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Weekly Attendance Trend',
                      style: GoogleFonts.inter(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Data aggregated from last 7 days',
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withOpacity(0.6),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),

          // Legends Row
          Row(
            children: [
              _buildChartLegend('Office', const Color(0xFF3B82F6)),
              SizedBox(width: 16.w),
              _buildChartLegend('WFH', const Color(0xFF8B5CF6)),
            ],
          ),
          SizedBox(height: 24.h),

          // Simulated Chart Columns Mon to Sun
          SizedBox(
            height: 150.h,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildBarColumn('Mon', officeRatio: 0.6, wfhRatio: 0.3),
                _buildBarColumn('Tue', officeRatio: 0.7, wfhRatio: 0.2),
                _buildBarColumn('Wed', officeRatio: 0.65, wfhRatio: 0.25),
                _buildBarColumn('Thu', officeRatio: 0.8, wfhRatio: 0.15),
                _buildBarColumn('Fri', officeRatio: 0.5, wfhRatio: 0.4),
                _buildBarColumn('Sat', officeRatio: 0.2, wfhRatio: 0.1),
                _buildBarColumn('Sun', officeRatio: 0.1, wfhRatio: 0.05),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper: Chart Legend Item
  Widget _buildChartLegend(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12.w,
          height: 12.h,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: 6.w),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11.sp,
            fontWeight: FontWeight.w400,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  // Helper: Chart Single Stacked Bar Column
  Widget _buildBarColumn(
    String day, {
    required double officeRatio,
    required double wfhRatio,
  }) {
    final double totalHeight = 120.h;
    final double officeHeight = totalHeight * officeRatio;
    final double wfhHeight = totalHeight * wfhRatio;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Stacked double container
        Container(
          width: 20.w,
          height: officeHeight + wfhHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4.r),
            color: Colors.transparent,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // WFH bar (Top)
              Container(
                width: 20.w,
                height: wfhHeight,
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6),
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(4.r),
                  ),
                ),
              ),
              // Office bar (Bottom)
              Container(
                width: 20.w,
                height: officeHeight,
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6),
                  borderRadius: wfhHeight > 0
                      ? BorderRadius.zero
                      : BorderRadius.vertical(top: Radius.circular(4.r)),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          day,
          style: GoogleFonts.inter(
            fontSize: 11.sp,
            fontWeight: FontWeight.w400,
            color: Colors.white.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  // Helper: Quick Actions Card
  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            Text(
              'Quick Actions',
              style: GoogleFonts.inter(
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: -0.3,
              ),
            ),
            const Spacer(),
            Text(
              'Shortcuts',
              style: GoogleFonts.inter(
                fontSize: 11.sp,
                fontWeight: FontWeight.w500,
                color: Colors.white.withOpacity(0.6),
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        // Action buttons grid
        Row(
          children: [
            Expanded(
              child: _buildPremiumActionTile(
                title: 'Add Staff',
                subtitle: 'Onboard employee',
                icon: Icons.person_add_rounded,
                gradientColors: [
                  const Color(0xFF5B21B6),
                  const Color(0xFF420093),
                ],
                onTap: () => _openAddEmployeeSheet(context),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _buildPremiumActionTile(
                title: 'Geofence',
                subtitle: 'Office settings',
                icon: Icons.my_location_rounded,
                gradientColors: [
                  const Color(0xFF047857),
                  const Color(0xFF065F46),
                ],
                onTap: () => Get.toNamed('/admin/office-settings'),
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        Row(
          children: [
            Expanded(
              child: _buildPremiumActionTile(
                title: 'Message',
                subtitle: 'Notify all staff',
                icon: Icons.campaign_rounded,
                gradientColors: [
                  const Color(0xFFB45309),
                  const Color(0xFF92400E),
                ],
                onTap: controller.broadcastMessage,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _buildPremiumActionTile(
                title: 'Reports',
                subtitle: 'Export insights',
                icon: Icons.analytics_rounded,
                gradientColors: [
                  const Color(0xFF0369A1),
                  const Color(0xFF075985),
                ],
                onTap: () => _showGenerateReportSheet(context),
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        Row(
          children: [
            Expanded(
              child: _buildPremiumActionTile(
                title: 'Assign Work',
                subtitle: 'Tasks & Projects',
                icon: Icons.business_center_rounded,
                gradientColors: [
                  const Color(0xFF0F52BA),
                  const Color(0xFF1E3A8A),
                ],
                onTap: () => Get.toNamed('/work-management/menu'),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _buildPremiumActionTile(
                title: 'Holidays',
                subtitle: 'Mark & manage',
                icon: Icons.calendar_month_rounded,
                gradientColors: [
                  const Color(0xFFEF4444),
                  const Color(0xFF991B1B),
                ],
                onTap: () => Get.toNamed('/admin/holiday-calendar'),
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        Row(
          children: [
            Expanded(
              child: _buildPremiumActionTile(
                title: 'Requests',
                subtitle: 'Regularizations',
                icon: Icons.history_toggle_off_rounded,
                gradientColors: [
                  const Color(0xFFF97316),
                  const Color(0xFFEA580C),
                ],
                onTap: () => Get.toNamed('/admin/attendance-requests'),
              ),
            ),
            SizedBox(width: 12.w),
            const Expanded(
              child: SizedBox(),
            ),
          ],
        ),
      ],
    );
  }

  // Premium action tile for Quick Actions grid
  Widget _buildPremiumActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: Colors.white.withOpacity(0.12), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12.r),
                boxShadow: [
                  BoxShadow(
                    color: gradientColors[1].withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(icon, size: 20, color: Colors.white),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 10.sp,
                      color: Colors.white.withOpacity(0.6),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper: System Status Alert Card
  Widget _buildSystemStatus() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.white.withOpacity(0.12), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon Container
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: const Icon(Icons.sensors, size: 28, color: Colors.white),
          ),
          SizedBox(width: 16.w),

          // Status Messages
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SYSTEM STATUS',
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withOpacity(0.55),
                    letterSpacing: 1.0,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Biometric Servers Online',
                  style: GoogleFonts.inter(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Last sync: 2 mins ago',
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper: Recent Clock-ins List/Table
  Widget _buildRecentClockIns() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.white.withOpacity(0.12), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Recent Clock-ins',
                  style: GoogleFonts.inter(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: 8.w),
              GestureDetector(
                onTap: () {},
                child: Text(
                  'View All Logs',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF3B82F6),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),

          // Column Headers Row
          Container(
            padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 8.w),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    'Employee',
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Date',
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Time',
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Status',
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 8.h),

          // Table Body Rows
          Obx(
            () => ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: controller.recentClockIns.length,
              separatorBuilder: (context, index) =>
                  Divider(height: 16, color: Colors.white.withOpacity(0.08)),
              itemBuilder: (context, index) {
                final log = controller.recentClockIns[index];
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.w),
                  child: Row(
                    children: [
                      // Employee info with Avatar
                      Expanded(
                        flex: 3,
                        child: Row(
                          children: [
                            Container(
                              width: 32.w,
                              height: 32.h,
                              decoration: BoxDecoration(
                                color: log.avatarBgColor.withOpacity(0.15),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: log.avatarBgColor.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  log.initials,
                                  style: GoogleFonts.inter(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.bold,
                                    color: log.avatarBgColor,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    log.name,
                                    style: GoogleFonts.inter(
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    log.role,
                                    style: GoogleFonts.inter(
                                      fontSize: 10.sp,
                                      fontWeight: FontWeight.w400,
                                      color: Colors.white.withOpacity(0.55),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Date
                      Expanded(
                        flex: 2,
                        child: Text(
                          log.date,
                          style: GoogleFonts.inter(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w400,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      // Time
                      Expanded(
                        flex: 2,
                        child: Text(
                          log.time,
                          style: GoogleFonts.inter(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w400,
                            color: Colors.white,
                          ),
                        ),
                      ),

                      // Status Badge
                      Expanded(
                        flex: 2,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 4.h,
                            ),
                            decoration: BoxDecoration(
                              color: log.status == 'on_time'
                                  ? const Color(0xFF065F46)
                                  : const Color(0xFF7F1D1D),
                              borderRadius: BorderRadius.circular(100.r),
                            ),
                            child: Text(
                              log.status == 'on_time' ? 'On Time' : 'Late',
                              style: GoogleFonts.inter(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w700,
                                color: log.status == 'on_time'
                                    ? const Color(0xFF34D399)
                                    : const Color(0xFFFCA5A5),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Dashboard Overview Widget
  Widget _buildDashboardOverview(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: 16.h),

          // Page Title & Header
          Text(
            'Dashboard Overview',
            style: GoogleFonts.inter(
              fontSize: 32.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              letterSpacing: -0.32,
              height: 40 / 32,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            "Welcome back, Admin. Here's what's happening today.",
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w400,
              color: Colors.white.withOpacity(0.7),
              height: 20 / 14,
            ),
          ),
          SizedBox(height: 16.h),

          // Export PDF Button
          // SizedBox(
          //   width: double.infinity,
          //   child: Container(
          //     decoration: BoxDecoration(
          //       gradient: const LinearGradient(
          //         colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
          //       ),
          //       borderRadius: BorderRadius.circular(12.r),
          //       boxShadow: [
          //         BoxShadow(
          //           color: const Color(0xFF3B82F6).withOpacity(0.3),
          //           blurRadius: 12,
          //           offset: const Offset(0, 4),
          //         ),
          //       ],
          //     ),
          //     child: ElevatedButton.icon(
          //       style: ElevatedButton.styleFrom(
          //         backgroundColor: Colors.transparent,
          //         shadowColor: Colors.transparent,
          //         padding: EdgeInsets.symmetric(vertical: 12.h),
          //         shape: RoundedRectangleBorder(
          //           borderRadius: BorderRadius.circular(12.r),
          //         ),
          //       ),
          //       icon: const Icon(
          //         Icons.file_download_outlined,
          //         size: 16,
          //         color: Colors.white,
          //       ),
          //       label: Text(
          //         'Export PDF',
          //         style: GoogleFonts.inter(
          //           fontSize: 14.sp,
          //           fontWeight: FontWeight.bold,
          //           color: Colors.white,
          //         ),
          //       ),
          //       onPressed: controller.exportPDF,
          //     ),
          //   ),
          // ),
          // SizedBox(height: 24.h),

          // Bento Grid Summary Cards (Total, Present, Absent, WFH)
          _buildBentoGrid(),
          SizedBox(height: 28.h),

          // Quick Actions
          _buildQuickActions(context),
          SizedBox(height: 28.h),

          // Work Management Summary Dashboard Widget
          _buildWorkManagementSummaryWidget(context),
          SizedBox(height: 28.h),

          _buildRegularizationSummaryWidget(context),
          SizedBox(height: 28.h),

          // Weekly Attendance Trend Chart
          // _buildTrendChart(),
          // SizedBox(height: 28.h),

          // Recent Clock-ins Table
          // _buildRecentClockIns(),
          // SizedBox(height: 28.h),

          // System Status Card
          // _buildSystemStatus(),
          // SizedBox(height: 28.h),

          // Work Updates Teaser Card
          _buildWorkUpdatesTeaserCard(context),
          SizedBox(height: 48.h),
        ],
      ),
    );
  }

  // Work Updates Teaser Card (shown on Home tab, navigates to full page)
  Widget _buildWorkUpdatesTeaserCard(BuildContext context) {
    return Obx(() {
      final count = controller.dailyWorkUpdates.length;
      return GestureDetector(
        onTap: () => Get.toNamed('/admin/work-updates'),
        child: Container(
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF420093), Color(0xFF4E45D5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF420093).withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon bubble
              Container(
                width: 52.w,
                height: 52.h,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: const Icon(
                  Icons.assignment_outlined,
                  size: 28,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 16.w),
              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Work Updates',
                      style: GoogleFonts.inter(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      count > 0
                          ? '$count update${count == 1 ? '' : 's'} in selected range'
                          : 'View employee task submissions',
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              // Arrow
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  size: 20,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildRegularizationSummaryWidget(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.white.withOpacity(0.12), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Regularization Requests',
                    style: GoogleFonts.inter(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'Checkout correction reviews',
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
                onPressed: () => Get.toNamed('/admin/attendance-requests'),
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          SizedBox(height: 20.h),
          Obx(() => Row(
                children: [
                  Expanded(
                    child: _buildSummaryGridItem(
                      label: 'Pending',
                      value: '${controller.pendingRegularizationsCount.value}',
                      color: const Color(0xFFF97316),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: _buildSummaryGridItem(
                      label: 'Approved Today',
                      value: '${controller.approvedRegularizationsTodayCount.value}',
                      color: const Color(0xFF10B981),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: _buildSummaryGridItem(
                      label: 'Rejected Today',
                      value: '${controller.rejectedRegularizationsTodayCount.value}',
                      color: const Color(0xFFEF4444),
                    ),
                  ),
                ],
              )),
        ],
      ),
    );
  }

  Widget _buildSummaryGridItem({required String label, required String value, required Color color}) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 8.w),
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
              fontSize: 22.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10.sp,
              color: const Color(0xFFCBD5E1),
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Navigate to add employee page
  void _openAddEmployeeSheet(BuildContext context) {
    Get.toNamed('/admin/add-employee');
  }

  // =====================================================================
  // ATTENDANCE REGISTRY TAB
  // =====================================================================

  Widget _buildAttendanceRegistry(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: 16.h),

          // ---- Header ----
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Attendance Registry',
                      style: GoogleFonts.inter(
                        fontSize: 28.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Track presence, absences & late arrivals',
                      style: GoogleFonts.inter(
                        fontSize: 13.sp,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              // Export button
              Obx(
                () => controller.isExporting.value
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : GestureDetector(
                        onTap: controller.exportAttendanceToExcel,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 8.h,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF420093),
                            borderRadius: BorderRadius.circular(8.r),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF420093).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.download_outlined,
                                size: 14,
                                color: Colors.white,
                              ),
                              SizedBox(width: 6.w),
                              Text(
                                'Export Excel',
                                style: GoogleFonts.inter(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
              ),
            ],
          ),
          SizedBox(height: 16.h),

          // ---- Date Range Selector ----
          _buildDateRangeSelector(context),
          SizedBox(height: 12.h),

          // ---- Search Bar ----
          Container(
            height: 44.h,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: Colors.white.withOpacity(0.15)),
            ),
            child: TextField(
              onChanged: (val) {
                controller.attendanceSearchQuery.value = val;
                controller.applyAttendanceFilters();
              },
              style: GoogleFonts.inter(fontSize: 14.sp, color: Colors.black),
              decoration: InputDecoration(
                hintText: 'Search by name or employee ID...',
                hintStyle: GoogleFonts.inter(
                  color: Colors.white54,
                  fontSize: 13.sp,
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  color: Colors.white70,
                  size: 20,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 10.h),
              ),
            ),
          ),
          SizedBox(height: 12.h),

          // ---- Status Filter Chips ----
          _buildAttendanceFilterChips(),
          SizedBox(height: 16.h),

          // ---- Summary Stats Row ----
          _buildAttendanceSummaryStats(),
          SizedBox(height: 16.h),

          // ---- Attendance List ----
          _buildAttendanceList(),
          SizedBox(height: 48.h),
        ],
      ),
    );
  }

  Widget _buildAttendanceFilterChips() {
    final filters = ['All', 'Present', 'WFH', 'Late', 'Absent'];
    return Obx(
      () => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: filters.map((filter) {
            final isSelected =
                controller.attendanceStatusFilter.value == filter;

            Color chipBg = Colors.white.withOpacity(0.08);
            Color chipText = Colors.white70;
            Color chipBorder = Colors.white.withOpacity(0.12);

            if (isSelected) {
              switch (filter) {
                case 'Present':
                  chipBg = const Color(0xFF16A34A);
                  chipText = Colors.white;
                  chipBorder = Colors.transparent;
                  break;
                case 'WFH':
                  chipBg = const Color(0xFF4E45D5);
                  chipText = Colors.white;
                  chipBorder = Colors.transparent;
                  break;
                case 'Late':
                  chipBg = const Color(0xFFD97706);
                  chipText = Colors.white;
                  chipBorder = Colors.transparent;
                  break;
                case 'Absent':
                  chipBg = const Color(0xFFDC2626);
                  chipText = Colors.white;
                  chipBorder = Colors.transparent;
                  break;
                default:
                  chipBg = const Color(0xFF420093);
                  chipText = Colors.white;
                  chipBorder = Colors.transparent;
              }
            }

            return Padding(
              padding: EdgeInsets.only(right: 8.w),
              child: GestureDetector(
                onTap: () {
                  controller.attendanceStatusFilter.value = filter;
                  controller.applyAttendanceFilters();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 7.h,
                  ),
                  decoration: BoxDecoration(
                    color: chipBg,
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(color: chipBorder),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: chipBg.withOpacity(0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : [],
                  ),
                  child: Text(
                    filter,
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: chipText,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildDateRangeSelector(BuildContext context) {
    final ranges = ['Day', 'Week', 'Month', 'Custom'];
    return Obx(() {
      final selected = controller.selectedFilterRange.value;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Range tabs row
          Row(
            children: [
              ...ranges.map((range) {
                final isActive = selected == range;
                return Padding(
                  padding: EdgeInsets.only(right: 8.w),
                  child: GestureDetector(
                    onTap: () {
                      controller.selectedFilterRange.value = range;
                      if (range == 'Custom') {
                        controller.selectCustomDateRange(context);
                      } else {
                        controller.updateFilteredData();
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: EdgeInsets.symmetric(
                        horizontal: 14.w,
                        vertical: 7.h,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? const Color(0xFF420093)
                            : Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(
                          color: isActive
                              ? Colors.transparent
                              : Colors.white.withOpacity(0.15),
                        ),
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color: const Color(
                                    0xFF420093,
                                  ).withOpacity(0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : [],
                      ),
                      child: Text(
                        range,
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          fontWeight: isActive
                              ? FontWeight.w700
                              : FontWeight.w400,
                          color: isActive ? Colors.white : Colors.white70,
                        ),
                      ),
                    ),
                  ),
                );
              }),
              const Spacer(),
              // Date label / picker button
              GestureDetector(
                onTap: () => controller.handleDateSelection(context),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 7.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(color: Colors.white.withOpacity(0.15)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.calendar_today_rounded,
                        size: 13,
                        color: Colors.white70,
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        controller.formattedRangeLabel,
                        style: GoogleFonts.inter(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    });
  }

  Widget _buildAttendanceSummaryStats() {
    return Obx(() {
      final rows = controller.rawAttendanceRows;
      final presentCount = rows.where((r) => r['status'] == 'Present').length;
      final wfhCount = rows.where((r) => r['status'] == 'WFH').length;
      final lateCount = rows.where((r) => r['status'] == 'Late').length;
      final absentCount = rows.where((r) => r['status'] == 'Absent').length;
      final rangeLabel = controller.formattedRangeLabel;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Period label
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: Colors.white.withOpacity(0.10)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.bar_chart_rounded,
                  size: 13,
                  color: Color(0xFF9061FF),
                ),
                SizedBox(width: 5.w),
                Text(
                  'Summary for: $rangeLabel',
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 10.h),
          Row(
            children: [
              Expanded(
                child: _buildAttendanceStatChip(
                  'Present',
                  presentCount,
                  const Color(0xFF16A34A).withOpacity(0.15),
                  const Color(0xFF4ADE80),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _buildAttendanceStatChip(
                  'WFH',
                  wfhCount,
                  const Color(0xFF4E45D5).withOpacity(0.15),
                  const Color(0xFF818CF8),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _buildAttendanceStatChip(
                  'Late',
                  lateCount,
                  const Color(0xFFD97706).withOpacity(0.15),
                  const Color(0xFFFBBF24),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _buildAttendanceStatChip(
                  'Absent',
                  absentCount,
                  const Color(0xFFDC2626).withOpacity(0.15),
                  const Color(0xFFF87171),
                ),
              ),
            ],
          ),
        ],
      );
    });
  }

  Widget _buildAttendanceStatChip(String label, int count, Color bg, Color fg) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10.h),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Column(
        children: [
          Text(
            '$count',
            style: GoogleFonts.inter(
              fontSize: 18.sp,
              fontWeight: FontWeight.w800,
              color: fg,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10.sp,
              fontWeight: FontWeight.w600,
              color: fg.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceList() {
    return Obx(() {
      final rows = controller.filteredAttendanceRows;

      if (rows.isEmpty) {
        return Container(
          padding: EdgeInsets.symmetric(vertical: 48.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: const Color(0xFFF0EDEC)),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.event_busy_outlined,
                size: 48,
                color: Color(0xFFCCC3D6),
              ),
              SizedBox(height: 12.h),
              Text(
                'No attendance records found.',
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  color: const Color(0xFF7B7485),
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                'Try changing the date range or filter.',
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  color: const Color(0xFFCCC3D6),
                ),
              ),
            ],
          ),
        );
      }

      return Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            // Table Header
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      'Employee',
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Date',
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Check-In',
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Check-Out',
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Status',
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Table Rows
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: rows.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: Colors.white10),
              itemBuilder: (context, index) {
                final row = rows[index];
                final String name = row['name'] ?? 'Employee';
                final String empId = row['employeeId'] ?? '';
                final String date = row['date'] ?? '--';
                final String checkIn = row['checkIn'] ?? '--';
                final String checkOut = row['checkOut'] ?? '--';
                final String status = row['status'] ?? '--';

                // Avatar initials
                String initials = 'E';
                if (name.trim().isNotEmpty) {
                  final parts = name.trim().split(' ');
                  if (parts.length > 1) {
                    initials = '${parts[0][0]}${parts[1][0]}'.toUpperCase();
                  } else {
                    initials = parts[0]
                        .substring(0, parts[0].length > 1 ? 2 : 1)
                        .toUpperCase();
                  }
                }
                final List<Color> avatarColors = [
                  const Color(0xFF420093),
                  const Color(0xFF4E45D5),
                  const Color(0xFF7C3AED),
                  const Color(0xFF16A34A),
                ];
                final avatarColor =
                    avatarColors[empId.hashCode % avatarColors.length];

                final bool isHolidayRow =
                    row['isHoliday'] == true || status.startsWith('Holiday');

                // Status badge styling
                Color badgeBg;
                Color badgeFg;
                if (isHolidayRow) {
                  badgeBg = const Color(0xFFEF4444).withOpacity(0.2);
                  badgeFg = const Color(0xFFF87171);
                } else {
                  switch (status) {
                    case 'Present':
                      badgeBg = const Color(0xFF16A34A).withOpacity(0.15);
                      badgeFg = const Color(0xFF4ADE80);
                      break;
                    case 'WFH':
                      badgeBg = const Color(0xFF4E45D5).withOpacity(0.15);
                      badgeFg = const Color(0xFF818CF8);
                      break;
                    case 'Late':
                      badgeBg = const Color(0xFFD97706).withOpacity(0.15);
                      badgeFg = const Color(0xFFFBBF24);
                      break;
                    case 'Absent':
                      badgeBg = const Color(0xFFDC2626).withOpacity(0.15);
                      badgeFg = const Color(0xFFF87171);
                      break;
                    default:
                      badgeBg = Colors.white.withOpacity(0.1);
                      badgeFg = Colors.white70;
                  }
                }

                return Container(
                  decoration: BoxDecoration(
                    color: isHolidayRow
                        ? const Color(0xFFEF4444).withOpacity(0.06)
                        : Colors.transparent,
                    border: isHolidayRow
                        ? Border(
                            left: BorderSide(
                              color: const Color(0xFFEF4444),
                              width: 3.w,
                            ),
                          )
                        : null,
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: isHolidayRow ? 13.w : 16.w,
                    vertical: 10.h,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Employee column
                      Expanded(
                        flex: 3,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _showEmployeeAttendanceHistory(
                            context,
                            row['uid'] ?? '',
                            name,
                            empId,
                            row['designation'] ?? '',
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 30.w,
                                height: 30.h,
                                decoration: BoxDecoration(
                                  color: avatarColor.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    initials,
                                    style: GoogleFonts.inter(
                                      fontSize: 11.sp,
                                      fontWeight: FontWeight.bold,
                                      color: avatarColor,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: GoogleFonts.inter(
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      empId,
                                      style: GoogleFonts.inter(
                                        fontSize: 10.sp,
                                        color: Colors.white.withOpacity(0.6),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Date
                      Expanded(
                        flex: 2,
                        child: Text(
                          date,
                          style: GoogleFonts.inter(
                            fontSize: 11.sp,
                            color: Colors.white.withOpacity(0.8),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      // Check-In
                      Expanded(
                        flex: 2,
                        child: Text(
                          checkIn,
                          style: GoogleFonts.inter(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w500,
                            color: checkIn == '--'
                                ? Colors.white24
                                : Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      // Check-Out
                      Expanded(
                        flex: 2,
                        child: Text(
                          checkOut,
                          style: GoogleFonts.inter(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w500,
                            color: checkOut == '--'
                                ? Colors.white24
                                : Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      // Status Badge
                      Expanded(
                        flex: 2,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 7.w,
                            vertical: 3.h,
                          ),
                          decoration: BoxDecoration(
                            color: badgeBg,
                            borderRadius: BorderRadius.circular(100.r),
                          ),
                          child: Text(
                            status,
                            style: GoogleFonts.inter(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w700,
                              color: badgeFg,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      );
    });
  }

  void _showEmployeeAttendanceHistory(
    BuildContext context,
    String uid,
    String name,
    String empId,
    String designation,
  ) {
    // 1. Filter raw records for this employee
    final logs = controller.rawAttendanceRows
        .where((r) => r['uid'] == uid)
        .toList();

    // 2. Count statistics for summary
    int present = 0;
    int wfh = 0;
    int late = 0;
    int absent = 0;
    double totalHours = 0.0;

    for (final log in logs) {
      final status = log['status'] ?? '';
      if (status == 'Present') {
        present++;
      } else if (status == 'WFH') {
        wfh++;
      } else if (status == 'Late') {
        late++;
      } else if (status == 'Absent') {
        absent++;
      }

      final String whStr = log['workedHours'] ?? '';
      if (whStr.isNotEmpty && whStr != '--') {
        final sanitizedWh = whStr
            .replaceAll(' hrs', '')
            .replaceAll(' hr', '')
            .trim();
        final hoursVal = double.tryParse(sanitizedWh) ?? 0.0;
        totalHours += hoursVal;
      }
    }

    final avatarColors = [
      const Color(0xFF420093),
      const Color(0xFF4E45D5),
      const Color(0xFF7C3AED),
      const Color(0xFF16A34A),
    ];
    final avatarColor = avatarColors[empId.hashCode % avatarColors.length];

    // Initial calculation
    String initials = 'E';
    if (name.trim().isNotEmpty) {
      final parts = name.trim().split(' ');
      if (parts.length > 1) {
        initials = '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      } else {
        initials = parts[0]
            .substring(0, parts[0].length > 1 ? 2 : 1)
            .toUpperCase();
      }
    }

    Get.bottomSheet(
      Container(
        height: 600.h,
        decoration: BoxDecoration(
          color: const Color(0xFF0F0F1A), // deep dark color matching theme
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          border: Border.all(color: Colors.white.withOpacity(0.12), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Close indicator bar
            Center(
              child: Container(
                margin: EdgeInsets.only(top: 10.h, bottom: 8.h),
                width: 48.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
            ),

            // Header Row: Avatar, Name, Title, and Close Button
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 10.h),
              child: Row(
                children: [
                  Container(
                    width: 48.w,
                    height: 48.h,
                    decoration: BoxDecoration(
                      color: avatarColor.withOpacity(0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: avatarColor.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        initials,
                        style: GoogleFonts.inter(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: avatarColor,
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
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          '$designation • ID: $empId',
                          style: GoogleFonts.inter(
                            fontSize: 11.sp,
                            color: Colors.white.withOpacity(0.6),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.white60,
                    ),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
            ),

            const Divider(color: Colors.white10, height: 1),

            // Range label & Stats summaries
            Padding(
              padding: EdgeInsets.fromLTRB(18.w, 16.h, 18.w, 12.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'PERIOD ATTENDANCE SUMMARY',
                        style: GoogleFonts.inter(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white.withOpacity(0.5),
                          letterSpacing: 1.2,
                        ),
                      ),
                      Text(
                        controller.formattedRangeLabel,
                        style: GoogleFonts.inter(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF9061FF),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Row(
                    children: [
                      Expanded(
                        child: _buildLogStatChip(
                          'Present',
                          present,
                          const Color(0xFF16A34A).withOpacity(0.15),
                          const Color(0xFF4ADE80),
                        ),
                      ),
                      SizedBox(width: 6.w),
                      Expanded(
                        child: _buildLogStatChip(
                          'WFH',
                          wfh,
                          const Color(0xFF4E45D5).withOpacity(0.15),
                          const Color(0xFF818CF8),
                        ),
                      ),
                      SizedBox(width: 6.w),
                      Expanded(
                        child: _buildLogStatChip(
                          'Late',
                          late,
                          const Color(0xFFD97706).withOpacity(0.15),
                          const Color(0xFFFBBF24),
                        ),
                      ),
                      SizedBox(width: 6.w),
                      Expanded(
                        child: _buildLogStatChip(
                          'Absent',
                          absent,
                          const Color(0xFFDC2626).withOpacity(0.15),
                          const Color(0xFFF87171),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 8.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Worked Hours',
                          style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            color: Colors.white70,
                          ),
                        ),
                        Text(
                          '${totalHours.toStringAsFixed(1)} hrs',
                          style: GoogleFonts.inter(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Divider(color: Colors.white10, height: 1),

            // Detailed logs title
            Padding(
              padding: EdgeInsets.fromLTRB(18.w, 14.h, 18.w, 8.h),
              child: Text(
                'DAILY WORK LOGS',
                style: GoogleFonts.inter(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withOpacity(0.5),
                  letterSpacing: 1.2,
                ),
              ),
            ),

            // Logs List
            Expanded(
              child: logs.isEmpty
                  ? Center(
                      child: Text(
                        'No records for the selected period.',
                        style: GoogleFonts.inter(
                          color: Colors.white38,
                          fontSize: 13.sp,
                        ),
                      ),
                    )
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.symmetric(
                        horizontal: 18.w,
                        vertical: 4.h,
                      ),
                      itemCount: logs.length,
                      itemBuilder: (context, index) {
                        final log = logs[index];
                        final date = log['date'] ?? '';
                        final checkIn = log['checkIn'] ?? '--';
                        final checkOut = log['checkOut'] ?? '--';
                        final workedHours = log['workedHours'] ?? '--';
                        final status = log['status'] ?? '--';
                        final location = log['location'] ?? '--';
                        final project = log['projectName'] ?? '--';
                        final task = log['taskStatus'] ?? '--';

                        Color statusColor;
                        switch (status) {
                          case 'Present':
                            statusColor = const Color(0xFF4ADE80);
                            break;
                          case 'WFH':
                            statusColor = const Color(0xFF818CF8);
                            break;
                          case 'Late':
                            statusColor = const Color(0xFFFBBF24);
                            break;
                          case 'Absent':
                            statusColor = const Color(0xFFF87171);
                            break;
                          default:
                            statusColor = Colors.white70;
                        }

                        return Container(
                          margin: EdgeInsets.only(bottom: 10.h),
                          padding: EdgeInsets.all(12.w),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(14.r),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.08),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    date,
                                    style: GoogleFonts.inter(
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8.w,
                                      vertical: 3.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(
                                        100.r,
                                      ),
                                    ),
                                    child: Text(
                                      status.toUpperCase(),
                                      style: GoogleFonts.inter(
                                        fontSize: 9.sp,
                                        fontWeight: FontWeight.bold,
                                        color: statusColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 10.h),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildLogItem('Check-In', checkIn),
                                  ),
                                  Expanded(
                                    child: _buildLogItem('Check-Out', checkOut),
                                  ),
                                  Expanded(
                                    child: _buildLogItem('Hours', workedHours),
                                  ),
                                  Expanded(
                                    child: _buildLogItem('Location', location),
                                  ),
                                ],
                              ),
                              if (project != '--' || task != '--') ...[
                                const Divider(
                                  color: Colors.white10,
                                  height: 16,
                                ),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildLogItem(
                                        'Project Name',
                                        project,
                                      ),
                                    ),
                                    Expanded(
                                      child: _buildLogItem('Task Status', task),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
            ),
            SizedBox(height: 16.h),
          ],
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  Widget _buildLogStatChip(String label, int count, Color bg, Color fg) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Column(
        children: [
          Text(
            '$count',
            style: GoogleFonts.inter(
              fontSize: 15.sp,
              fontWeight: FontWeight.w800,
              color: fg,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 9.sp,
              fontWeight: FontWeight.w600,
              color: fg.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 8.sp,
            fontWeight: FontWeight.w600,
            color: Colors.white30,
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 11.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white.withOpacity(0.9),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  // Employee Directory Body
  Widget _buildEmployeeDirectory(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: 16.h),

          // Header
          Text(
            'Employee Directory',
            style: GoogleFonts.inter(
              fontSize: 28.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          SizedBox(height: 4.h),
          Obx(
            () => Text(
              "${controller.filteredEmployees.length} active team members",
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                fontWeight: FontWeight.w400,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ),
          SizedBox(height: 20.h),

          // Premium Stats Row
          _buildDirectoryStats(),
          SizedBox(height: 20.h),

          // Search Bar & Add Button
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 46.h,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(color: Colors.white.withOpacity(0.15)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: TextField(
                    onChanged: (val) {
                      controller.searchQuery.value = val;
                      controller.applyFilters();
                    },
                    style: GoogleFonts.inter(
                      fontSize: 13.sp,
                      color: Colors.black,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search employees...',
                      hintStyle: GoogleFonts.inter(
                        color: Colors.white54,
                        fontSize: 13.sp,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: Colors.white70,
                        size: 20,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 12.h),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              GestureDetector(
                onTap: () => _openAddEmployeeSheet(context),
                child: Container(
                  height: 46.h,
                  width: 46.h,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF5B21B6), Color(0xFF420093)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14.r),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF420093).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.person_add_rounded,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),

          // Filter Chips
          _buildFilterChipsRow(),
          SizedBox(height: 20.h),

          // Employee Grid
          _buildEmployeeGrid(context),
          SizedBox(height: 24.h),

          // Pagination
          _buildPaginationBar(),
          SizedBox(height: 48.h),
        ],
      ),
    );
  }

  // Mini Stats row — premium gradient cards matching dashboard
  Widget _buildDirectoryStats() {
    return Obx(
      () => Row(
        children: [
          Expanded(
            child: _buildDirStatCard(
              label: 'Total',
              value: controller.totalEmployees.value,
              icon: Icons.people_rounded,
              gradientColors: [
                const Color(0xFF5B21B6),
                const Color(0xFF420093),
              ],
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: _buildDirStatCard(
              label: 'Present',
              value: controller.presentToday.value,
              icon: Icons.check_circle_rounded,
              gradientColors: [
                const Color(0xFF059669),
                const Color(0xFF047857),
              ],
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: _buildDirStatCard(
              label: 'WFH',
              value: controller.wfhToday.value,
              icon: Icons.home_work_rounded,
              gradientColors: [
                const Color(0xFF4338CA),
                const Color(0xFF3730A3),
              ],
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: _buildDirStatCard(
              label: 'Absent',
              value: controller.absentToday.value,
              icon: Icons.person_off_rounded,
              gradientColors: [
                const Color(0xFFDC2626),
                const Color(0xFFB91C1C),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDirStatCard({
    required String label,
    required String value,
    required IconData icon,
    required List<Color> gradientColors,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 12.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: gradientColors[1].withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(6.w),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(icon, size: 14, color: Colors.white),
          ),
          SizedBox(height: 8.h),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 22.sp,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
              height: 1,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10.sp,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.75),
            ),
          ),
        ],
      ),
    );
  }

  // Filter Selector Chips — premium animated pills
  Widget _buildFilterChipsRow() {
    final filters = ['All', 'Present', 'WFH', 'Absent'];
    final Map<String, List<Color>> filterGradients = {
      'All': [const Color(0xFF5B21B6), const Color(0xFF420093)],
      'Present': [const Color(0xFF059669), const Color(0xFF047857)],
      'WFH': [const Color(0xFF4338CA), const Color(0xFF3730A3)],
      'Absent': [const Color(0xFFDC2626), const Color(0xFFB91C1C)],
    };
    return Obx(
      () => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: filters.map((filter) {
            final isSelected = controller.selectedStatusFilter.value == filter;
            final grad = filterGradients[filter]!;
            return Padding(
              padding: EdgeInsets.only(right: 8.w),
              child: GestureDetector(
                onTap: () {
                  controller.selectedStatusFilter.value = filter;
                  controller.applyFilters();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 8.h,
                  ),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? LinearGradient(
                            colors: grad,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: isSelected ? null : Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(24.r),
                    border: Border.all(
                      color: isSelected
                          ? Colors.transparent
                          : Colors.white.withOpacity(0.12),
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: grad[1].withOpacity(0.28),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : [],
                  ),
                  child: Text(
                    filter,
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: isSelected ? Colors.white : Colors.white70,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // Employee Cards Grid
  Widget _buildEmployeeGrid(BuildContext context) {
    return Obx(() {
      final items = controller.paginatedEmployees;

      // Calculate item count (including the "New Position" card on the first page)
      final showNewPosition = controller.currentPage.value == 1;
      final itemCount = items.length + (showNewPosition ? 1 : 0);

      if (items.isEmpty && !showNewPosition) {
        return Container(
          padding: EdgeInsets.symmetric(vertical: 40.h),
          alignment: Alignment.center,
          child: Text(
            'No employees found matching the filters.',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              color: const Color(0xFF7B7485),
            ),
          ),
        );
      }

      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.72,
          crossAxisSpacing: 12.w,
          mainAxisSpacing: 12.h,
        ),
        itemBuilder: (context, index) {
          // If first item on page 1, show "New Position" empty placeholder card
          if (showNewPosition && index == 0) {
            return _buildNewPositionCard(context);
          }

          // Otherwise adjust index if page 1 to account for New Position card
          final employeeIndex = showNewPosition ? index - 1 : index;
          final employee = items[employeeIndex];

          return _buildEmployeeCard(employee);
        },
      );
    });
  }

  // Helper New Position empty card — premium dashed gradient
  Widget _buildNewPositionCard(BuildContext context) {
    return GestureDetector(
      onTap: () => _openAddEmployeeSheet(context),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: Colors.white.withOpacity(0.15), width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(14.w),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF5B21B6), Color(0xFF420093)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF420093).withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.person_add_rounded,
                size: 26,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 14.h),
            Text(
              'New Position',
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              'Onboard new staff',
              style: GoogleFonts.inter(
                fontSize: 10.sp,
                color: Colors.white.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Single Employee grid card — premium redesign
  Widget _buildEmployeeCard(EmployeeProfile employee) {
    String statusLabel = 'Present';
    List<Color> avatarGrad = [const Color(0xFF5B21B6), const Color(0xFF420093)];

    if (employee.status == 'wfh') {
      statusLabel = 'WFH';
      avatarGrad = [const Color(0xFF4338CA), const Color(0xFF3730A3)];
    } else if (employee.status == 'absent') {
      statusLabel = 'Absent';
      avatarGrad = [const Color(0xFFDC2626), const Color(0xFFB91C1C)];
    } else {
      avatarGrad = [const Color(0xFF059669), const Color(0xFF047857)];
    }

    return GestureDetector(
      onTap: () => Get.to(() => EmployeeDetailsView(employee: employee)),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(color: Colors.white.withOpacity(0.12), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Gradient Header Band with avatar
            Container(
              height: 80.h,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: avatarGrad,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Watermark icon
                  Positioned(
                    right: -8.w,
                    bottom: -8.h,
                    child: Icon(
                      Icons.person_rounded,
                      size: 60,
                      color: Colors.white.withOpacity(0.07),
                    ),
                  ),
                  // Status badge top-right
                  Positioned(
                    top: 8.h,
                    right: 10.w,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 7.w,
                        vertical: 3.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.22),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Text(
                        statusLabel,
                        style: GoogleFonts.inter(
                          fontSize: 9.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  // Avatar circle
                  Container(
                    width: 46.w,
                    height: 46.h,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.22),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        employee.initials,
                        style: GoogleFonts.inter(
                          fontSize: 17.sp,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Body content
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name
                    Text(
                      employee.name,
                      style: GoogleFonts.inter(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2.h),
                    // Designation
                    Text(
                      employee.designation,
                      style: GoogleFonts.inter(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withOpacity(0.6),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.h),
                    // Employee ID chip
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 6.w,
                        vertical: 2.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(
                        employee.id,
                        style: GoogleFonts.inter(
                          fontSize: 9.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFC3C0FF),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // View Profile CTA
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(20.r),
                ),
              ),
              padding: EdgeInsets.symmetric(vertical: 9.h),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'View Profile',
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFC3C0FF),
                      ),
                    ),
                    SizedBox(width: 4.w),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 13,
                      color: Color(0xFFC3C0FF),
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

  // Pagination bar widget
  Widget _buildPaginationBar() {
    return Obx(() {
      final total = controller.totalPages;
      if (total <= 1) return const SizedBox.shrink();

      final current = controller.currentPage.value;

      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: current > 1 ? controller.previousPage : null,
          ),
          ...List.generate(total, (index) {
            final page = index + 1;
            final isSelected = current == page;
            return InkWell(
              onTap: () => controller.currentPage.value = page,
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 4.w),
                width: 32.w,
                height: 32.h,
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF420093)
                      : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? Colors.transparent
                        : const Color(0xFFCCC3D6),
                  ),
                ),
                child: Center(
                  child: Text(
                    '$page',
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF1C1B1B),
                    ),
                  ),
                ),
              ),
            );
          }),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: current < total ? controller.nextPage : null,
          ),
        ],
      );
    });
  }

  // Placeholder views for other tabs
  Widget _buildLeavesOverview(BuildContext context) {
    final rejectionReasonController = TextEditingController();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Title & Description
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Leave Approvals',
                style: GoogleFonts.outfit(
                  fontSize: 26.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                'Review and process organization-wide leave requests.',
                style: GoogleFonts.inter(
                  fontSize: 13.sp,
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),

        // Status Filter Row (Pending, Approved, Rejected, All)
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          child: Obx(() {
            final activeFilter = controller.selectedLeaveStatusFilter.value;
            final filters = ['Pending', 'Approved', 'Rejected', 'All'];

            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: filters.map((filter) {
                final isSelected =
                    activeFilter.toLowerCase() == filter.toLowerCase();
                return Expanded(
                  child: GestureDetector(
                    onTap: () => controller.filterLeaves(filter.toLowerCase()),
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 4.w),
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF9061FF)
                            : Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF9061FF)
                              : Colors.white.withOpacity(0.12),
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          filter,
                          style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected ? Colors.white : Colors.white70,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          }),
        ),

        // Leaves Request List
        Expanded(
          child: Obx(() {
            if (controller.isLoadingLeaves.value) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF9061FF)),
              );
            }
            if (controller.filteredLeaveRequests.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.time_to_leave_outlined,
                      size: 48,
                      color: Colors.white30,
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      'No leave requests found.',
                      style: GoogleFonts.inter(
                        color: Colors.white38,
                        fontSize: 14.sp,
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              itemCount: controller.filteredLeaveRequests.length,
              itemBuilder: (context, index) {
                final request = controller.filteredLeaveRequests[index];
                final String id = request['id'] ?? '';
                final String userId = request['userId'] ?? '';
                final String empName = request['employeeName'] ?? 'Employee';
                final String empId = request['employeeId'] ?? 'EMP-000';
                final String designation =
                    request['designation'] ?? 'Staff Member';
                final String leaveType = request['leaveType'] ?? 'Annual Leave';
                final String startStr = request['startDate'] ?? '';
                final String endStr = request['endDate'] ?? '';
                final String reason = request['reason'] ?? '';
                final String status = request['status'] ?? 'pending';
                final String rejection = request['rejectionReason'] ?? '';

                final start = DateTime.tryParse(startStr) ?? DateTime.now();
                final end = DateTime.tryParse(endStr) ?? DateTime.now();
                final durationDays = end.difference(start).inDays + 1;

                Color statusColor = const Color(0xFFFBBF24);
                if (status == 'approved') {
                  statusColor = const Color(0xFF10B981);
                } else if (status == 'rejected') {
                  statusColor = const Color(0xFFEF4444);
                }

                return Container(
                  margin: EdgeInsets.only(bottom: 12.h),
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
                      // Employee info
                      Row(
                        children: [
                          Container(
                            width: 38.w,
                            height: 38.h,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF9061FF).withOpacity(0.2),
                              border: Border.all(
                                color: const Color(0xFF9061FF).withOpacity(0.4),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                empName.isNotEmpty
                                    ? empName[0].toUpperCase()
                                    : 'E',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
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
                                  empName,
                                  style: GoogleFonts.inter(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  '$designation  •  $empId',
                                  style: GoogleFonts.inter(
                                    fontSize: 11.sp,
                                    color: Colors.white38,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 3.h,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8.r),
                              border: Border.all(
                                color: statusColor.withOpacity(0.4),
                                width: 1,
                              ),
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
                      const Divider(color: Colors.white10, height: 20),

                      // Request details
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            leaveType,
                            style: GoogleFonts.inter(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white70,
                            ),
                          ),
                          Text(
                            '$durationDays Day(s)',
                            style: GoogleFonts.inter(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF60A5FA),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        '$startStr  →  $endStr',
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          color: Colors.white54,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'Reason: $reason',
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),

                      if (status == 'rejected' && rejection.isNotEmpty) ...[
                        SizedBox(height: 10.h),
                        Container(
                          padding: EdgeInsets.all(10.w),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(
                              color: const Color(0xFFEF4444).withOpacity(0.2),
                            ),
                          ),
                          child: Text(
                            'Rejection Reason: $rejection',
                            style: GoogleFonts.inter(
                              fontSize: 12.sp,
                              color: const Color(0xFFF87171),
                            ),
                          ),
                        ),
                      ],

                      // Action Buttons (Pending state)
                      if (status == 'pending') ...[
                        const Divider(color: Colors.white10, height: 24),
                        Row(
                          children: [
                            // Reject Button
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(
                                    0xFFEF4444,
                                  ).withOpacity(0.2),
                                  foregroundColor: const Color(0xFFF87171),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10.r),
                                    side: BorderSide(
                                      color: const Color(
                                        0xFFEF4444,
                                      ).withOpacity(0.4),
                                    ),
                                  ),
                                  padding: EdgeInsets.symmetric(vertical: 10.h),
                                ),
                                icon: const Icon(
                                  Icons.cancel_outlined,
                                  size: 16,
                                ),
                                label: Text(
                                  'Reject',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                onPressed: () {
                                  rejectionReasonController.clear();
                                  Get.defaultDialog(
                                    title: 'Reject Request',
                                    titleStyle: GoogleFonts.inter(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      fontSize: 16.sp,
                                    ),
                                    backgroundColor: const Color(0xFF0F172A),
                                    contentPadding: EdgeInsets.all(16.w),
                                    content: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Text(
                                          'Please enter a reason for rejecting the leave request:',
                                          style: GoogleFonts.inter(
                                            color: Colors.white70,
                                            fontSize: 13.sp,
                                          ),
                                        ),
                                        SizedBox(height: 12.h),
                                        TextField(
                                          controller: rejectionReasonController,
                                          maxLines: 2,
                                          style: GoogleFonts.inter(
                                            color: Colors.white,
                                            fontSize: 13.sp,
                                          ),
                                          decoration: InputDecoration(
                                            hintText:
                                                'Enter rejection comments...',
                                            hintStyle: GoogleFonts.inter(
                                              color: Colors.white38,
                                            ),
                                            fillColor: Colors.white.withOpacity(
                                              0.05,
                                            ),
                                            filled: true,
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8.r),
                                              borderSide: BorderSide(
                                                color: Colors.white.withOpacity(
                                                  0.1,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    textConfirm: 'REJECT',
                                    textCancel: 'CANCEL',
                                    confirmTextColor: Colors.white,
                                    cancelTextColor: Colors.white54,
                                    buttonColor: const Color(0xFFEF4444),
                                    onConfirm: () {
                                      Get.back(); // close dialog
                                      controller.updateLeaveStatus(
                                        id,
                                        userId,
                                        'rejected',
                                        rejectionReason:
                                            rejectionReasonController.text,
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                            SizedBox(width: 12.w),
                            // Approve Button
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(
                                    0xFF10B981,
                                  ).withOpacity(0.2),
                                  foregroundColor: const Color(0xFF34D399),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10.r),
                                    side: BorderSide(
                                      color: const Color(
                                        0xFF10B981,
                                      ).withOpacity(0.4),
                                    ),
                                  ),
                                  padding: EdgeInsets.symmetric(vertical: 10.h),
                                ),
                                icon: const Icon(
                                  Icons.check_circle_outline,
                                  size: 16,
                                ),
                                label: Text(
                                  'Approve',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                onPressed: () {
                                  Get.defaultDialog(
                                    title: 'Approve Request',
                                    middleText:
                                        'Are you sure you want to approve this leave request?',
                                    middleTextStyle: GoogleFonts.inter(
                                      color: Colors.white70,
                                    ),
                                    backgroundColor: const Color(0xFF0F172A),
                                    textConfirm: 'APPROVE',
                                    textCancel: 'CANCEL',
                                    confirmTextColor: Colors.white,
                                    cancelTextColor: Colors.white54,
                                    buttonColor: const Color(0xFF10B981),
                                    onConfirm: () {
                                      Get.back();
                                      controller.updateLeaveStatus(
                                        id,
                                        userId,
                                        'approved',
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                );
              },
            );
          }),
        ),
      ],
    );
  }

  Widget _buildBackgroundSwitcher() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'DASHBOARD BACKGROUND',
          style: GoogleFonts.inter(
            fontSize: 11.sp,
            fontWeight: FontWeight.w700,
            color: Colors.white.withOpacity(0.6),
            letterSpacing: 1.2,
          ),
        ),
        SizedBox(height: 12.h),
        SizedBox(
          height: 70.h,
          child: Obx(() {
            final selectedIndex = controller.selectedBgIndex.value;
            return ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: controller.bgImages.length,
              itemBuilder: (context, index) {
                final bgPath = controller.bgImages[index];
                final isSelected = selectedIndex == index;
                final labels = ['Premium Dark', 'Abstract Glass', 'Neon Mesh'];
                return GestureDetector(
                  onTap: () => controller.changeBackground(index),
                  child: Container(
                    margin: EdgeInsets.only(right: 12.w),
                    width: 110.w,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF9061FF)
                            : Colors.white.withOpacity(0.15),
                        width: isSelected ? 2.w : 1.w,
                      ),
                      image: DecorationImage(
                        image: AssetImage(bgPath),
                        fit: BoxFit.cover,
                        colorFilter: ColorFilter.mode(
                          Colors.black.withOpacity(0.4),
                          BlendMode.darken,
                        ),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        labels[index],
                        style: GoogleFonts.inter(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            const Shadow(color: Colors.black, blurRadius: 4),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          }),
        ),
      ],
    );
  }

  Widget _buildProfileOverview(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Admin Profile Card
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF420093), Color(0xFF4E45D5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20.r),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF420093).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30.r,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  child: const Icon(
                    Icons.admin_panel_settings,
                    size: 32,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 16.w),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Administrator',
                      style: GoogleFonts.inter(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Full system access',
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 24.h),

          // Dynamic Background Switcher
          _buildBackgroundSwitcher(),
          SizedBox(height: 28.h),

          // Settings Section Label
          Text(
            'SETTINGS',
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white.withOpacity(0.6),
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: 12.h),

          // Settings Card
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: Colors.white.withOpacity(0.12)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Office Geofence — highlighted prominently
                _buildSettingsRow(
                  title: 'Office Geofence Settings',
                  subtitle: 'Configure office location & check-in radius',
                  icon: Icons.my_location,
                  iconBg: const Color(0xFFDCFCE7).withOpacity(0.15),
                  iconColor: const Color(0xFF4ADE80),
                  onTap: () => Get.toNamed('/admin/office-settings'),
                  hasBadge: true,
                  badgeText: 'Required',
                ),
                const Divider(height: 1, color: Colors.white10, indent: 60),
                _buildSettingsRow(
                  title: 'Add New Staff',
                  subtitle: 'Onboard a new employee into the system',
                  icon: Icons.person_add_alt_outlined,
                  iconBg: const Color(0xFFEBDDFF).withOpacity(0.15),
                  iconColor: const Color(0xFFC3C0FF),
                  onTap: () => Get.toNamed('/admin/add-employee'),
                ),
                const Divider(height: 1, color: Colors.white10, indent: 60),
                _buildSettingsRow(
                  title: 'Broadcast Message',
                  subtitle: 'Send a notification to all employees',
                  icon: Icons.campaign_outlined,
                  iconBg: const Color(0xFFFEF3C7).withOpacity(0.15),
                  iconColor: const Color(0xFFFBBF24),
                  onTap: controller.broadcastMessage,
                ),
                const Divider(height: 1, color: Colors.white10, indent: 60),
                _buildSettingsRow(
                  title: 'Generate Report',
                  subtitle: 'Export monthly attendance insights',
                  icon: Icons.analytics_outlined,
                  iconBg: const Color(0xFFEFF6FF).withOpacity(0.15),
                  iconColor: const Color(0xFF60A5FA),
                  onTap: controller.generateReport,
                ),
                const Divider(height: 1, color: Colors.white10, indent: 60),
                _buildSettingsRow(
                  title: 'Reset Password',
                  subtitle: 'Send recovery link to registered email',
                  icon: Icons.lock_reset_rounded,
                  iconBg: const Color(0xFFFFEAEA).withOpacity(0.15),
                  iconColor: const Color(0xFFF87171),
                  onTap: () {
                    Get.defaultDialog(
                      title: 'Reset Password',
                      titleStyle: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 18.sp,
                      ),
                      middleText:
                          'Do you want to send a secure password reset link to ${controller.adminEmail.value}?',
                      middleTextStyle: GoogleFonts.inter(fontSize: 14.sp),
                      textConfirm: 'Send Link',
                      textCancel: 'Cancel',
                      confirmTextColor: Colors.white,
                      cancelTextColor: const Color(0xFF4A4453),
                      buttonColor: const Color(0xFF420093),
                      onConfirm: () {
                        Get.back();
                        controller.sendPasswordResetEmail();
                      },
                    );
                  },
                ),
              ],
            ),
          ),
          SizedBox(height: 28.h),

          // Danger Zone
          Text(
            'ACCOUNT',
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white.withOpacity(0.6),
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: 12.h),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: Colors.white.withOpacity(0.12)),
            ),
            child: _buildSettingsRow(
              title: 'Log Out',
              subtitle: 'Sign out of administrator account',
              icon: Icons.logout,
              iconBg: const Color(0xFFFEE2E2).withOpacity(0.15),
              iconColor: const Color(0xFFF87171),
              onTap: () => Get.offAllNamed('/login'),
              isDestructive: true,
            ),
          ),
          SizedBox(height: 48.h),
        ],
      ),
    );
  }

  Widget _buildSettingsRow({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required VoidCallback onTap,
    bool hasBadge = false,
    String badgeText = '',
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        child: Row(
          children: [
            Container(
              width: 42.w,
              height: 42.w,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: isDestructive
                              ? const Color(0xFFEF4444)
                              : Colors.white,
                        ),
                      ),
                      if (hasBadge) ...[
                        SizedBox(width: 8.w),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6.w,
                            vertical: 2.h,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF16A34A),
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: Text(
                            badgeText,
                            style: GoogleFonts.inter(
                              fontSize: 9.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: isDestructive ? const Color(0xFFEF4444) : Colors.white70,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkManagementSummaryWidget(BuildContext context) {
    final WorkTaskController taskController = Get.put(
      WorkTaskController(isTesting: controller.isTesting),
    );
    final glassColor = Colors.white.withOpacity(0.06);
    final borderColor = Colors.white.withOpacity(0.12);
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
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.business_center_rounded,
                color: const Color(0xFF3B82F6),
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  'Work & Task Metrics',
                  style: GoogleFonts.inter(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Divider(height: 24, color: Colors.white10),

          Obx(() {
            return Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TOTAL TASKS',
                        style: GoogleFonts.inter(
                          fontSize: 10.sp,
                          color: subTextColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        taskController.reportAssigned.value.toString(),
                        style: GoogleFonts.inter(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
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
                        'COMPLETED',
                        style: GoogleFonts.inter(
                          fontSize: 10.sp,
                          color: const Color(0xFF10B981),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        taskController.reportCompleted.value.toString(),
                        style: GoogleFonts.inter(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }),
          SizedBox(height: 16.h),
          Obx(() {
            return Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ACTIVE / PENDING',
                        style: GoogleFonts.inter(
                          fontSize: 10.sp,
                          color: const Color(0xFFF59E0B),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        taskController.reportPending.value.toString(),
                        style: GoogleFonts.inter(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFF59E0B),
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
                        'OVERDUE',
                        style: GoogleFonts.inter(
                          fontSize: 10.sp,
                          color: const Color(0xFFEF4444),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        taskController.reportOverdue.value.toString(),
                        style: GoogleFonts.inter(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFEF4444),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }),

          const Divider(height: 24, color: Colors.white10),
          ElevatedButton(
            onPressed: () => Get.toNamed('/work-management/menu'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 10.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
            child: const Text('Open Work Console'),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationIconWithBadge() {
    if (controller.isTesting) {
      return IconButton(
        icon: const Icon(
          Icons.notifications_none_outlined,
          color: Colors.white70,
        ),
        onPressed: () => Get.toNamed('/notifications'),
      );
    }
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return IconButton(
        icon: const Icon(
          Icons.notifications_none_outlined,
          color: Colors.white70,
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
            if (targetRole == 'admin') return true;
            return false;
          }).length;
        }

        return Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(
                Icons.notifications_none_outlined,
                color: Colors.white70,
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

  void _showGenerateReportSheet(BuildContext context) {
    controller.selectAllEmployees(true);
    controller.calculateCustomReportPreview();

    Get.bottomSheet(
      Obx(() {
        final currentType = controller.reportRangeType.value;
        final selectedMonth = controller.reportSelectedMonth.value;
        final selectedRange = controller.reportSelectedDateRange.value;
        final selectedUids = controller.reportSelectedEmployeeUids;
        final searchQuery = controller.reportEmployeeSearchQuery.value;

        final filteredList = controller.allEmployees.where((emp) {
          final q = searchQuery.toLowerCase();
          return emp.name.toLowerCase().contains(q) ||
              emp.id.toLowerCase().contains(q);
        }).toList();

        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: const Color(0xFF0F0F1A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
            border: Border.all(
              color: Colors.white.withOpacity(0.12),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  margin: EdgeInsets.only(top: 10.h, bottom: 8.h),
                  width: 48.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
              ),

              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: const Color(0xFF9061FF).withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.analytics_rounded,
                        color: Color(0xFF9061FF),
                        size: 24,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Generate Report Console',
                            style: GoogleFonts.inter(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Configure date limits & employee filters',
                            style: GoogleFonts.inter(
                              fontSize: 12.sp,
                              color: Colors.white38,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white60,
                      ),
                      onPressed: () => Get.back(),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white10, height: 1),

              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.all(20.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildReportToggleBtn(
                              label: 'Month Wise',
                              isActive: currentType == 'Month',
                              onTap: () {
                                controller.reportRangeType.value = 'Month';
                                controller.calculateCustomReportPreview();
                              },
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: _buildReportToggleBtn(
                              label: 'Date Range',
                              isActive: currentType == 'Date',
                              onTap: () {
                                controller.reportRangeType.value = 'Date';
                                controller.calculateCustomReportPreview();
                              },
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16.h),

                      if (currentType == 'Month') ...[
                        Text(
                          'SELECT MONTH',
                          style: GoogleFonts.inter(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white54,
                            letterSpacing: 1.0,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        SizedBox(
                          height: 38.h,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            children: List.generate(6, (index) {
                              final d = DateTime(
                                DateTime.now().year,
                                DateTime.now().month - index,
                                1,
                              );
                              final label = DateFormat('MMM yyyy').format(d);
                              final isSelected =
                                  selectedMonth.year == d.year &&
                                  selectedMonth.month == d.month;
                              return Padding(
                                padding: EdgeInsets.only(right: 8.w),
                                child: ChoiceChip(
                                  label: Text(label),
                                  selected: isSelected,
                                  onSelected: (val) {
                                    if (val) {
                                      controller.reportSelectedMonth.value = d;
                                      controller.calculateCustomReportPreview();
                                    }
                                  },
                                  labelStyle: GoogleFonts.inter(
                                    fontSize: 12.sp,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.white70,
                                  ),
                                  selectedColor: const Color(0xFF420093),
                                  backgroundColor: Colors.black.withOpacity(
                                    0.6,
                                  ),
                                  checkmarkColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20.r),
                                    side: BorderSide(
                                      color: isSelected
                                          ? const Color(0xFF9061FF)
                                          : Colors.white10,
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                      ] else ...[
                        Text(
                          'SELECT DATE RANGE',
                          style: GoogleFonts.inter(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white54,
                            letterSpacing: 1.0,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        GestureDetector(
                          onTap: () async {
                            final picked = await showDateRangePicker(
                              context: context,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                              initialDateRange: selectedRange,
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: const ColorScheme.light(
                                      primary: Color(0xFF420093),
                                      onPrimary: Colors.white,
                                      surface: Color(0xFF0F0F1A),
                                      onSurface: Colors.white,
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (picked != null) {
                              controller.reportSelectedDateRange.value = picked;
                              controller.calculateCustomReportPreview();
                            }
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 12.h,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(10.r),
                              border: Border.all(color: Colors.white12),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.date_range_rounded,
                                  color: Color(0xFF9061FF),
                                  size: 18,
                                ),
                                SizedBox(width: 10.w),
                                Text(
                                  selectedRange == null
                                      ? 'Choose Custom Date Range...'
                                      : '${DateFormat('yyyy-MM-dd').format(selectedRange.start)}  to  ${DateFormat('yyyy-MM-dd').format(selectedRange.end)}',
                                  style: GoogleFonts.inter(
                                    fontSize: 13.sp,
                                    color: selectedRange == null
                                        ? Colors.white38
                                        : Colors.white,
                                  ),
                                ),
                                const Spacer(),
                                const Icon(
                                  Icons.arrow_drop_down_rounded,
                                  color: Colors.white38,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      SizedBox(height: 24.h),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'FILTER BY EMPLOYEE',
                            style: GoogleFonts.inter(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white54,
                              letterSpacing: 1.0,
                            ),
                          ),
                          Text(
                            '${selectedUids.length} Selected',
                            style: GoogleFonts.inter(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF9061FF),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8.h),

                      Container(
                        height: 40.h,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(10.r),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: TextField(
                          onChanged: (val) {
                            controller.reportEmployeeSearchQuery.value = val;
                          },
                          style: GoogleFonts.inter(
                            fontSize: 13.sp,
                            color: Colors.black,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Search employee name or ID...',
                            hintStyle: GoogleFonts.inter(
                              color: Colors.black54,
                              fontSize: 12.sp,
                            ),
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              color: Colors.white38,
                              size: 16,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 8.h),
                          ),
                        ),
                      ),
                      SizedBox(height: 10.h),

                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => controller.selectAllEmployees(true),
                            child: _buildPillActionBtn('Select All'),
                          ),
                          SizedBox(width: 8.w),
                          GestureDetector(
                            onTap: () => controller.selectAllEmployees(false),
                            child: _buildPillActionBtn('Clear Selection'),
                          ),
                        ],
                      ),
                      SizedBox(height: 10.h),

                      Container(
                        height: 160.h,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.03),
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: filteredList.isEmpty
                            ? Center(
                                child: Text(
                                  'No employees found.',
                                  style: GoogleFonts.inter(
                                    color: Colors.white38,
                                    fontSize: 12.sp,
                                  ),
                                ),
                              )
                            : ListView.builder(
                                physics: const BouncingScrollPhysics(),
                                itemCount: filteredList.length,
                                itemBuilder: (context, idx) {
                                  final emp = filteredList[idx];
                                  final isChecked = selectedUids.contains(
                                    emp.uid,
                                  );
                                  return CheckboxListTile(
                                    value: isChecked,
                                    onChanged: (val) => controller
                                        .toggleEmployeeSelection(emp.uid),
                                    title: Text(
                                      emp.name,
                                      style: GoogleFonts.inter(
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '${emp.designation} • ID: ${emp.id}',
                                      style: GoogleFonts.inter(
                                        fontSize: 10.sp,
                                        color: Colors.white38,
                                      ),
                                    ),
                                    activeColor: const Color(0xFF9061FF),
                                    checkColor: Colors.white,
                                    dense: true,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12.w,
                                    ),
                                  );
                                },
                              ),
                      ),
                      SizedBox(height: 24.h),

                      Text(
                        'REPORT PREVIEW (${controller.customReportPreviewRows.length} ROWS)',
                        style: GoogleFonts.inter(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white54,
                          letterSpacing: 1.0,
                        ),
                      ),
                      SizedBox(height: 10.h),

                      _buildReportPreviewTable(),
                    ],
                  ),
                ),
              ),

              const Divider(color: Colors.white10, height: 1),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                child: Obx(
                  () => controller.isExporting.value
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF9061FF),
                          ),
                        )
                      : Container(
                          height: 48.h,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14.r),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF8B5CF6).withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: controller.exportCustomReportToExcel,
                              borderRadius: BorderRadius.circular(14.r),
                              child: Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.download_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    SizedBox(width: 8.w),
                                    Text(
                                      'Export Multi-Tab Excel',
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
                        ),
                ),
              ),
            ],
          ),
        );
      }),
      isScrollControlled: true,
      ignoreSafeArea: true,
    );
  }

  Widget _buildReportToggleBtn({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(vertical: 10.h),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF420093)
              : Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isActive ? const Color(0xFF9061FF) : Colors.white10,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13.sp,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isActive ? Colors.white : Colors.white70,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPillActionBtn(String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.white12),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 10.sp,
          fontWeight: FontWeight.bold,
          color: Colors.white70,
        ),
      ),
    );
  }

  Widget _buildReportPreviewTable() {
    return Obx(() {
      final rows = controller.customReportPreviewRows;
      if (rows.isEmpty) {
        return Container(
          padding: EdgeInsets.symmetric(vertical: 36.h),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.02),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: Colors.white10),
          ),
          child: Center(
            child: Text(
              'No data selected or found.',
              style: GoogleFonts.inter(color: Colors.white38, fontSize: 13.sp),
            ),
          ),
        );
      }

      return Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          children: [
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: rows.length > 50 ? 50 : rows.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: Colors.white10),
              itemBuilder: (context, idx) {
                final r = rows[idx];
                final String name = r['name'] ?? '';
                final String date = r['date'] ?? '';
                final String checkIn = r['checkIn'] ?? '--';
                final String checkOut = r['checkOut'] ?? '--';
                final String status = r['status'] ?? '';
                final bool isHoliday = r['isHoliday'] == true;

                Color statusColor = Colors.white70;
                if (isHoliday) {
                  statusColor = const Color(0xFFF87171);
                } else if (status == 'Present') {
                  statusColor = const Color(0xFF4ADE80);
                } else if (status == 'WFH') {
                  statusColor = const Color(0xFF818CF8);
                } else if (status == 'Late') {
                  statusColor = const Color(0xFFFBBF24);
                } else if (status == 'Absent') {
                  statusColor = const Color(0xFFF87171);
                }

                return Container(
                  color: isHoliday
                      ? const Color(0xFFEF4444).withOpacity(0.05)
                      : Colors.transparent,
                  padding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 10.h,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: GoogleFonts.inter(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            date,
                            style: GoogleFonts.inter(
                              fontSize: 10.sp,
                              color: Colors.white38,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      Row(
                        children: [
                          Text(
                            'In: $checkIn  •  Out: $checkOut',
                            style: GoogleFonts.inter(
                              fontSize: 11.sp,
                              color: Colors.white70,
                            ),
                          ),
                          const Spacer(),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isHoliday) ...[
                                const Icon(
                                  Icons.star_rounded,
                                  color: Color(0xFFF87171),
                                  size: 12,
                                ),
                                SizedBox(width: 3.w),
                              ],
                              Text(
                                status,
                                style: GoogleFonts.inter(
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.bold,
                                  color: statusColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (isHoliday && r['projectName'] != '--') ...[
                        SizedBox(height: 4.h),
                        Text(
                          'Event: ${r['projectName']}',
                          style: GoogleFonts.inter(
                            fontSize: 10.sp,
                            fontStyle: FontStyle.italic,
                            color: const Color(0xFFF87171).withOpacity(0.8),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
            if (rows.length > 50)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 12.h),
                child: Text(
                  'Showing first 50 rows of preview',
                  style: GoogleFonts.inter(
                    color: Colors.white38,
                    fontSize: 11.sp,
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }
}
