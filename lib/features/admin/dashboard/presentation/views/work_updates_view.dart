import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stepz_attendance/core/theme/premium_background.dart';
import '../controllers/admin_dashboard_controller.dart';

class WorkUpdatesView extends StatefulWidget {
  const WorkUpdatesView({super.key});

  @override
  State<WorkUpdatesView> createState() => _WorkUpdatesViewState();
}

class _WorkUpdatesViewState extends State<WorkUpdatesView> {
  late AdminDashboardController controller;
  String _searchQuery = '';
  String _statusFilter = 'All';

  @override
  void initState() {
    super.initState();
    controller = Get.find<AdminDashboardController>();
  }

  List<Map<String, dynamic>> get _filtered {
    var list = controller.dailyWorkUpdates.toList();
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list
          .where((u) =>
              (u['name'] as String? ?? '').toLowerCase().contains(q) ||
              (u['employeeId'] as String? ?? '').toLowerCase().contains(q) ||
              (u['projectName'] as String? ?? '').toLowerCase().contains(q))
          .toList();
    }
    if (_statusFilter != 'All') {
      list = list
          .where((u) => (u['taskStatus'] as String? ?? '') == _statusFilter)
          .toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return PremiumBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: GestureDetector(
            onTap: () => Get.back(),
            child: Container(
              margin: EdgeInsets.only(left: 16.w, top: 8.h, bottom: 8.h),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: Colors.white.withOpacity(0.12)),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Colors.white),
            ),
          ),
          title: Text(
            'Work Updates',
            style: GoogleFonts.inter(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          actions: [
            Obx(() => controller.isExporting.value
                ? Padding(
                    padding: EdgeInsets.only(right: 16.w),
                    child: const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    ),
                  )
                : GestureDetector(
                    onTap: controller.exportWorkUpdatesToCSV,
                    child: Container(
                      margin: EdgeInsets.only(right: 16.w, top: 10.h, bottom: 10.h),
                      padding: EdgeInsets.symmetric(horizontal: 12.w),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0F52BA), Color(0xFF3B82F6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(8.r),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF3B82F6).withOpacity(0.2),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.download_outlined, size: 14, color: Colors.white),
                          SizedBox(width: 5.w),
                          Text(
                            'Export',
                            style: GoogleFonts.inter(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )),
          ],
        ),
        body: Obx(() {
          // rebuild when updates change (triggered by range changes)
          final _ = controller.dailyWorkUpdates.length;
          return Column(
            children: [
              // ── Top Controls ──────────────────────────────────
              Container(
                color: Colors.transparent,
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Column(
                  children: [
                    SizedBox(height: 4.h),
                    _buildRangeSelector(context),
                    _buildDateButton(context),
                    SizedBox(height: 10.h),
                    _buildSearchBar(),
                    SizedBox(height: 10.h),
                    _buildStatusChips(),
                    SizedBox(height: 12.h),
                    _buildSummaryRow(),
                    SizedBox(height: 8.h),
                  ],
                ),
              ),

              // ── List ──────────────────────────────────────────
              Expanded(
                child: Builder(builder: (_) {
                  final items = _filtered;
                  if (items.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.assignment_late_outlined, size: 60, color: Colors.white.withOpacity(0.3)),
                          SizedBox(height: 16.h),
                          Text(
                            'No work updates found',
                            style: GoogleFonts.inter(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 6.h),
                          Text(
                            'Try a different date range or filter',
                            style: GoogleFonts.inter(
                              fontSize: 13.sp,
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 32.h),
                    physics: const BouncingScrollPhysics(),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => SizedBox(height: 12.h),
                    itemBuilder: (context, index) => _buildUpdateCard(items[index]),
                  );
                }),
              ),
            ],
          );
        }),
      ),
    );
  }

  // ── Range selector ───────────────────────────────────────────────────────
  Widget _buildRangeSelector(BuildContext context) {
    final ranges = ['Day', 'Week', 'Month', 'Custom'];
    return Obx(() => Container(
          margin: EdgeInsets.only(bottom: 10.h),
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
          ),
          child: Row(
            children: ranges.map((range) {
              final isSelected = controller.selectedFilterRange.value == range;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    controller.selectedFilterRange.value = range;
                    if (range == 'Custom') {
                      controller.selectCustomDateRange(context);
                    } else {
                      controller.updateFilteredData();
                    }
                    setState(() {});
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: EdgeInsets.symmetric(vertical: 8.h),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF3B82F6) : Colors.transparent,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Center(
                      child: Text(
                        range,
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ));
  }

  // ── Date button ──────────────────────────────────────────────────────────
  Widget _buildDateButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 10.h),
          side: BorderSide(color: Colors.white.withOpacity(0.12)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
          backgroundColor: Colors.white.withOpacity(0.08),
        ),
        icon: const Icon(Icons.calendar_today_outlined, size: 14, color: Colors.white),
        label: Obx(() => Text(
              controller.formattedRangeLabel,
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )),
        onPressed: () async {
          await controller.handleDateSelection(context);
          setState(() {});
        },
      ),
    );
  }

  // ── Search bar ───────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Container(
      height: 44.h,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: TextField(
        onChanged: (v) => setState(() => _searchQuery = v),
        style: GoogleFonts.inter(fontSize: 14.sp, color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search by name, ID or project...',
          hintStyle: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 13.sp),
          prefixIcon: const Icon(Icons.search, color: Color(0xFF94A3B8), size: 20),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 10.h),
        ),
      ),
    );
  }

  // ── Status filter chips ──────────────────────────────────────────────────
  Widget _buildStatusChips() {
    final statuses = ['All', 'In Progress', 'Completed', 'Pending'];
    final chipColors = {
      'All': const Color(0xFF3B82F6),
      'In Progress': const Color(0xFF4F46E5),
      'Completed': const Color(0xFF10B981),
      'Pending': const Color(0xFFD97706),
    };
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: statuses.map((s) {
          final isSelected = _statusFilter == s;
          final color = chipColors[s] ?? const Color(0xFF3B82F6);
          return Padding(
            padding: EdgeInsets.only(right: 8.w),
            child: GestureDetector(
              onTap: () => setState(() => _statusFilter = s),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
                decoration: BoxDecoration(
                  color: isSelected ? color : Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: isSelected ? Colors.transparent : Colors.white.withOpacity(0.12),
                  ),
                  boxShadow: isSelected
                      ? [BoxShadow(color: color.withOpacity(0.28), blurRadius: 6, offset: const Offset(0, 2))]
                      : [],
                ),
                child: Text(
                  s,
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Summary stat row ─────────────────────────────────────────────────────
  Widget _buildSummaryRow() {
    final all = controller.dailyWorkUpdates;
    final inProgress = all.where((u) => u['taskStatus'] == 'In Progress').length;
    final completed = all.where((u) => u['taskStatus'] == 'Completed').length;
    final pending = all.where((u) => u['taskStatus'] == 'Pending').length;

    return Row(
      children: [
        _buildStat('Total', all.length.toString(), const Color(0xFF3B82F6).withOpacity(0.2), const Color(0xFF60A5FA)),
        SizedBox(width: 8.w),
        _buildStat('In Progress', inProgress.toString(), const Color(0xFF4F46E5).withOpacity(0.2), const Color(0xFF818CF8)),
        SizedBox(width: 8.w),
        _buildStat('Done', completed.toString(), const Color(0xFF10B981).withOpacity(0.2), const Color(0xFF34D399)),
        SizedBox(width: 8.w),
        _buildStat('Pending', pending.toString(), const Color(0xFFD97706).withOpacity(0.2), const Color(0xFFFBBF24)),
      ],
    );
  }

  Widget _buildStat(String label, String value, Color bg, Color fg) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10.h),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: fg.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(value, style: GoogleFonts.inter(fontSize: 18.sp, fontWeight: FontWeight.w800, color: fg)),
            SizedBox(height: 2.h),
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                    color: fg.withOpacity(0.75))),
          ],
        ),
      ),
    );
  }

  // ── Single update card ───────────────────────────────────────────────────
  Widget _buildUpdateCard(Map<String, dynamic> update) {
    final String name = update['name'] ?? 'Employee';
    final String employeeId = update['employeeId'] ?? 'EMP-000';
    final String designation = update['designation'] ?? 'Staff Member';
    final String date = update['date'] ?? '--';
    final String checkIn = update['checkIn'] ?? '--';
    final String checkOut = update['checkOut'] ?? '--';
    final String projectName = update['projectName'] ?? '--';
    final String taskDetails = update['taskDetails'] ?? '--';
    final String taskStatus = update['taskStatus'] ?? 'In Progress';
    final List<dynamic> workUpdates = update['workUpdates'] as List<dynamic>? ?? [];

    // Avatar
    String initials = 'E';
    if (name.trim().isNotEmpty) {
      final parts = name.trim().split(' ');
      initials = parts.length > 1
          ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
          : parts[0].substring(0, parts[0].length > 1 ? 2 : 1).toUpperCase();
    }
    final avatarColors = [
      const Color(0xFF3B82F6),
      const Color(0xFF4F46E5),
      const Color(0xFF10B981),
      const Color(0xFFD97706),
    ];
    final avatarColor = avatarColors[employeeId.hashCode % avatarColors.length];

    // Status badge
    Color badgeBg;
    Color badgeFg;
    switch (taskStatus) {
      case 'Completed':
        badgeBg = const Color(0xFF10B981).withOpacity(0.2);
        badgeFg = const Color(0xFF34D399);
        break;
      case 'Pending':
        badgeBg = const Color(0xFFD97706).withOpacity(0.2);
        badgeFg = const Color(0xFFFBBF24);
        break;
      default: // In Progress
        badgeBg = const Color(0xFF4F46E5).withOpacity(0.2);
        badgeFg = const Color(0xFF818CF8);
    }

    return Container(
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
          // ── Card Header ──────────────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 0),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 40.w,
                  height: 40.h,
                  decoration: BoxDecoration(
                    color: avatarColor.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: avatarColor.withOpacity(0.4)),
                  ),
                  child: Center(
                    child: Text(
                      initials,
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                // Name & designation
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: GoogleFonts.inter(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                      Text(
                        '$designation  •  $employeeId',
                        style: GoogleFonts.inter(fontSize: 11.sp, color: const Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(100.r),
                    border: Border.all(color: badgeFg.withOpacity(0.3)),
                  ),
                  child: Text(
                    taskStatus,
                    style: GoogleFonts.inter(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w700,
                        color: badgeFg),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 12.h),

          // ── Meta info grid ───────────────────────────────
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: Colors.white.withOpacity(0.06)),
              ),
              child: Row(
                children: [
                  Expanded(child: _metaCol('Date', date, Icons.calendar_today_outlined)),
                  _verticalDivider(),
                  Expanded(child: _metaCol('Project/Task', workUpdates.isNotEmpty ? '${workUpdates.length} Staged' : projectName, Icons.work_outline_rounded)),
                  _verticalDivider(),
                  Expanded(child: _metaCol('Check-In', checkIn, Icons.login_rounded)),
                  _verticalDivider(),
                  Expanded(child: _metaCol('Check-Out', checkOut, Icons.logout_rounded)),
                ],
              ),
            ),
          ),

          SizedBox(height: 12.h),

          // ── Task updates list ─────────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.notes_rounded, size: 14, color: Color(0xFF94A3B8)),
                    SizedBox(width: 6.w),
                    Text(
                      workUpdates.isNotEmpty ? 'Grouped Work Logs' : 'Task Details',
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                if (workUpdates.isNotEmpty)
                  ...workUpdates.map((item) => _buildSubUpdateRow(Map<String, dynamic>.from(item)))
                else
                  Text(
                    taskDetails,
                    style: GoogleFonts.inter(
                      fontSize: 13.sp,
                      color: Colors.white,
                      height: 1.5,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubUpdateRow(Map<String, dynamic> item) {
    final String proj = item['projectName'] ?? '--';
    final String title = item['taskTitle'] ?? '--';
    final String details = item['taskDetails'] ?? '--';
    final String status = item['taskStatus'] ?? 'In Progress';
    final String start = item['startTime'] ?? '';
    final String end = item['endTime'] ?? '';
    final double progress = (item['progressPercentage'] ?? 0.0).toDouble();

    Color color;
    switch (status) {
      case 'Completed':
        color = const Color(0xFF10B981);
        break;
      case 'Pending':
        color = const Color(0xFFF59E0B);
        break;
      default:
        color = const Color(0xFF3B82F6);
    }

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withOpacity(0.2), width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  proj != '--' && proj != 'Other Task' && proj != title
                      ? '$title ($proj)'
                      : title,
                  style: GoogleFonts.inter(
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
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  status,
                  style: GoogleFonts.inter(
                    fontSize: 9.sp,
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Row(
            children: [
              const Icon(Icons.schedule_rounded, color: Colors.white30, size: 12),
              SizedBox(width: 4.w),
              Text(
                '$start - $end',
                style: GoogleFonts.inter(fontSize: 10.sp, color: Colors.white60, fontWeight: FontWeight.w600),
              ),
              if (progress > 0) ...[
                SizedBox(width: 12.w),
                const Icon(Icons.trending_up_rounded, color: Color(0xFF3B82F6), size: 12),
                SizedBox(width: 4.w),
                Text(
                  'Progress: ${progress.toInt()}%',
                  style: GoogleFonts.inter(fontSize: 10.sp, color: const Color(0xFF60A5FA), fontWeight: FontWeight.w600),
                ),
              ],
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            details,
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              color: Colors.white.withOpacity(0.85),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _metaCol(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 14, color: const Color(0xFF94A3B8)),
        SizedBox(height: 4.h),
        Text(
          label,
          style: GoogleFonts.inter(
              fontSize: 9.sp,
              color: const Color(0xFF94A3B8),
              fontWeight: FontWeight.w500),
        ),
        SizedBox(height: 2.h),
        Text(
          value,
          style: GoogleFonts.inter(
              fontSize: 11.sp,
              color: Colors.white,
              fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _verticalDivider() {
    return Container(
      width: 1,
      height: 40.h,
      color: Colors.white.withOpacity(0.08),
      margin: EdgeInsets.symmetric(horizontal: 4.w),
    );
  }
}
