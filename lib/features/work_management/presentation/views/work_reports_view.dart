import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:stepz_attendance/core/theme/premium_background.dart';
import '../controllers/work_task_controller.dart';

class WorkReportsView extends StatefulWidget {
  const WorkReportsView({super.key});

  @override
  State<WorkReportsView> createState() => _WorkReportsViewState();
}

class _WorkReportsViewState extends State<WorkReportsView> {
  final WorkTaskController controller = Get.put(WorkTaskController());

  @override
  void initState() {
    super.initState();
    controller.fetchTasks();
  }

  @override
  Widget build(BuildContext context) {
    const textColor = Colors.white;

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
            'Work Reports',
            style: GoogleFonts.outfit(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.refresh_rounded, color: textColor),
              onPressed: () {
                controller.fetchTasks();
                controller.updateReportMetrics();
              },
            ),
          ],
        ),
        body: SafeArea(
          child: Obx(() {
            if (controller.isLoadingTasks.value) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
                ),
              );
            }

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Range Selection Bar
                  _buildRangeSelector(context),
                  SizedBox(height: 20.h),

                  // Key Metrics Grid
                  _buildMetricsGrid(context),
                  SizedBox(height: 20.h),

                  // Project Progress Chart
                  _buildProjectProgressCard(context),
                  SizedBox(height: 16.h),

                  // Employee Productivity Card
                  _buildEmployeeProductivityCard(context),
                  SizedBox(height: 16.h),

                  // Company Distribution Card
                  _buildCompanyDistributionCard(context),
                  SizedBox(height: 32.h),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildRangeSelector(BuildContext context) {
    const textColor = Colors.black;
    final ranges = ['Today', 'Weekly', 'Monthly', 'All', 'Custom'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Analysis Duration',
          style: GoogleFonts.inter(
            fontSize: 13.sp,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        SizedBox(height: 8.h),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: ranges.map((range) {
              final isSelected = controller.selectedReportRange.value == range;
              return Padding(
                padding: EdgeInsets.only(right: 8.w),
                child: ChoiceChip(
                  label: Text(range),
                  selected: isSelected,
                  labelStyle: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: isSelected ? Colors.white : textColor,
                  ),
                  selectedColor: const Color(0xFF3B82F6),
                  backgroundColor: Colors.white.withOpacity(0.06),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  onSelected: (selected) async {
                    if (selected) {
                      if (range == 'Custom') {
                        final picked = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                          initialDateRange:
                              controller.reportCustomDateRange.value,
                        );
                        if (picked != null) {
                          controller.reportCustomDateRange.value = picked;
                          controller.selectedReportRange.value = range;
                          controller.updateReportMetrics();
                        }
                      } else {
                        controller.selectedReportRange.value = range;
                        controller.updateReportMetrics();
                      }
                    }
                  },
                ),
              );
            }).toList(),
          ),
        ),
        if (controller.selectedReportRange.value == 'Custom' &&
            controller.reportCustomDateRange.value != null) ...[
          SizedBox(height: 6.h),
          Text(
            'Range: ${DateFormat('yyyy-MM-dd').format(controller.reportCustomDateRange.value!.start)} to ${DateFormat('yyyy-MM-dd').format(controller.reportCustomDateRange.value!.end)}',
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              color: Colors.blue.shade400,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMetricsGrid(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12.w,
      mainAxisSpacing: 12.h,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.4,
      children: [
        _buildMetricTile(
          context,
          title: 'Total Tasks',
          value: controller.reportAssigned.value.toString(),
          icon: Icons.assignment_rounded,
          color: const Color(0xFF3B82F6),
        ),
        _buildMetricTile(
          context,
          title: 'Completed',
          value: controller.reportCompleted.value.toString(),
          icon: Icons.task_alt_rounded,
          color: const Color(0xFF10B981),
        ),
        _buildMetricTile(
          context,
          title: 'Active / Pending',
          value: controller.reportPending.value.toString(),
          icon: Icons.pending_actions_rounded,
          color: const Color(0xFFF59E0B),
        ),
        _buildMetricTile(
          context,
          title: 'Overdue Tasks',
          value: controller.reportOverdue.value.toString(),
          icon: Icons.error_outline_rounded,
          color: const Color(0xFFEF4444),
        ),
      ],
    );
  }

  Widget _buildMetricTile(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final glassColor = Colors.white.withOpacity(0.08);
    final borderColor = Colors.white.withOpacity(0.12);
    const textColor = Colors.white;
    const subTextColor = Color(0xFF94A3B8);

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: glassColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.all(6.w),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(icon, color: color, size: 18.sp),
              ),
              Text(
                value,
                style: GoogleFonts.outfit(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              color: subTextColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectProgressCard(BuildContext context) {
    final glassColor = Colors.white.withOpacity(0.08);
    final borderColor = Colors.white.withOpacity(0.12);
    const textColor = Colors.white;
    const subTextColor = Color(0xFF94A3B8);

    final list = controller.projectProgress;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: glassColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.bar_chart_rounded,
                color: const Color(0xFF8B5CF6),
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                'Project Completion Rates',
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
          const Divider(height: 20, color: Colors.white10),
          if (list.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20.h),
                child: Text(
                  'No project task data available.',
                  style: TextStyle(color: subTextColor, fontSize: 12.sp),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: list.length,
              separatorBuilder: (_, __) => SizedBox(height: 12.h),
              itemBuilder: (context, index) {
                final proj = list[index];
                final name = proj['projectName'] as String;
                final progress = proj['progress'] as double;
                final taskCount = proj['taskCount'] as int;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: GoogleFonts.inter(
                              fontSize: 12.sp,
                              color: textColor,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${progress.toInt()}% ($taskCount tasks)',
                          style: GoogleFonts.inter(
                            fontSize: 11.sp,
                            color: subTextColor,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6.h),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4.r),
                      child: LinearProgressIndicator(
                        value: progress / 100.0,
                        backgroundColor: Colors.white12,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF8B5CF6),
                        ),
                        minHeight: 6.h,
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildEmployeeProductivityCard(BuildContext context) {
    final glassColor = Colors.white.withOpacity(0.08);
    final borderColor = Colors.white.withOpacity(0.12);
    const textColor = Colors.white;
    const subTextColor = Color(0xFF94A3B8);

    final list = controller.employeeProductivity;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: glassColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.star_purple500_rounded,
                color: const Color(0xFFF59E0B),
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                'Team Task Completion Rates',
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
          const Divider(height: 20, color: Colors.white10),
          if (list.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20.h),
                child: Text(
                  'No team productivity data logged.',
                  style: TextStyle(color: subTextColor, fontSize: 12.sp),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: list.length,
              separatorBuilder: (_, __) => SizedBox(height: 12.h),
              itemBuilder: (context, index) {
                final emp = list[index];
                final name = emp['name'] as String;
                final code = emp['employeeId'] as String;
                final total = emp['totalTasks'] as int;
                final completed = emp['completedTasks'] as int;
                final rate = emp['rate'] as double;

                return Row(
                  children: [
                    CircleAvatar(
                      radius: 14.r,
                      backgroundColor: const Color(
                        0xFFF59E0B,
                      ).withOpacity(0.15),
                      child: Text(
                        name[0].toUpperCase(),
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: const Color(0xFFF59E0B),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: GoogleFonts.inter(
                              fontSize: 12.sp,
                              color: textColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'ID: $code | $completed/$total completed',
                            style: GoogleFonts.inter(
                              fontSize: 10.sp,
                              color: subTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${rate.toInt()}%',
                          style: GoogleFonts.inter(
                            fontSize: 13.sp,
                            color: rate >= 70.0
                                ? Colors.green.shade400
                                : Colors.amber.shade400,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Container(
                          width: 60.w,
                          height: 4.h,
                          decoration: BoxDecoration(
                            color: Colors.white12,
                            borderRadius: BorderRadius.circular(2.r),
                          ),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              width: (60 * (rate / 100)).w,
                              color: rate >= 70.0 ? Colors.green : Colors.amber,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildCompanyDistributionCard(BuildContext context) {
    final glassColor = Colors.white.withOpacity(0.08);
    final borderColor = Colors.white.withOpacity(0.12);
    const textColor = Colors.white;
    const subTextColor = Color(0xFF94A3B8);

    final list = controller.companyDistribution;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: glassColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.business_rounded,
                color: const Color(0xFF10B981),
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                'Task Share by Company Client',
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
          const Divider(height: 20, color: Colors.white10),
          if (list.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20.h),
                child: Text(
                  'No company distribution logged.',
                  style: TextStyle(color: subTextColor, fontSize: 12.sp),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: list.length,
              separatorBuilder: (_, __) => SizedBox(height: 10.h),
              itemBuilder: (context, index) {
                final comp = list[index];
                final name = comp['companyName'] as String;
                final count = comp['count'] as int;

                return Row(
                  children: [
                    Icon(
                      Icons.business_rounded,
                      size: 14.sp,
                      color: subTextColor,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        name,
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          color: textColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(
                        '$count tasks',
                        style: GoogleFonts.inter(
                          fontSize: 10.sp,
                          color: const Color(0xFF34D399),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}
