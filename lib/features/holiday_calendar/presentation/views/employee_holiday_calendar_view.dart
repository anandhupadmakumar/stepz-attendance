import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:stepz_attendance/core/theme/premium_background.dart';
import '../../models/holiday_model.dart';
import '../controllers/holiday_calendar_controller.dart';

class EmployeeHolidayCalendarView extends StatelessWidget {
  const EmployeeHolidayCalendarView({super.key});

  @override
  Widget build(BuildContext context) {
    // We register/find the HolidayCalendarController
    final controller = Get.find<HolidayCalendarController>();

    return PremiumBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: _buildAppBar(context),
        body: SafeArea(
          child: Obx(() {
            if (controller.isLoading.value) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF9061FF)),
              );
            }
            return Column(
              children: [
                // ── Stats Strip ──────────────────────────────────────────────
                _buildStatsStrip(controller),

                // ── Calendar & Details ────────────────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        SizedBox(height: 12.h),
                        _buildCalendarCard(context, controller),
                        SizedBox(height: 16.h),
                        _buildLegend(),
                        SizedBox(height: 16.h),
                        _buildMonthHolidayList(context, controller),
                        SizedBox(height: 32.h),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  // ─── AppBar ───────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        onPressed: () => Get.back(),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Holiday Calendar',
            style: GoogleFonts.outfit(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            'View upcoming company & public holidays',
            style: GoogleFonts.inter(
              fontSize: 10.sp,
              color: Colors.white60,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Stats Strip ─────────────────────────────────────────────────────────
  Widget _buildStatsStrip(HolidayCalendarController controller) {
    return Obx(() {
      final month = DateFormat('MMMM yyyy').format(controller.focusedDay.value);
      return Container(
        margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.07),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              month,
              style: GoogleFonts.outfit(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white70,
              ),
            ),
            SizedBox(height: 10.h),
            Row(
              children: [
                _buildStatChip(
                  label: 'Total',
                  value: controller.totalMonthHolidays,
                  color: const Color(0xFF9061FF),
                ),
                SizedBox(width: 10.w),
                _buildStatChip(
                  label: 'Public',
                  value: controller.publicCount,
                  color: const Color(0xFFEF4444),
                ),
                SizedBox(width: 10.w),
                _buildStatChip(
                  label: 'Optional',
                  value: controller.optionalCount,
                  color: const Color(0xFFF59E0B),
                ),
                SizedBox(width: 10.w),
                _buildStatChip(
                  label: 'Events',
                  value: controller.companyEventCount,
                  color: const Color(0xFF3B82F6),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildStatChip({
    required String label,
    required int value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 6.w),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(
              value.toString(),
              style: GoogleFonts.outfit(
                fontSize: 20.sp,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 9.sp,
                color: Colors.white60,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Calendar Card ────────────────────────────────────────────────────────
  Widget _buildCalendarCard(
    BuildContext context,
    HolidayCalendarController controller,
  ) {
    return Obx(() => Container(
          margin: EdgeInsets.symmetric(horizontal: 16.w),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20.r),
            child: TableCalendar(
              firstDay: DateTime(2024, 1, 1),
              lastDay: DateTime(2027, 12, 31),
              focusedDay: controller.focusedDay.value,
              selectedDayPredicate: (day) =>
                  controller.selectedDay.value != null &&
                  isSameDay(day, controller.selectedDay.value!),

              // ── Swipe left/right to change month ───────────────────────
              calendarFormat: CalendarFormat.month,
              availableCalendarFormats: const {
                CalendarFormat.month: 'Month',
              },
              startingDayOfWeek: StartingDayOfWeek.monday,

              onDaySelected: (selectedDay, focusedDay) {
                controller.selectedDay.value = selectedDay;
                controller.focusedDay.value = focusedDay;
                _onDayTapped(context, controller, selectedDay);
              },
              onPageChanged: (focusedDay) {
                controller.focusedDay.value = focusedDay;
                controller.selectedDay.value = null;
              },

              // ── Header styling ─────────────────────────────────────────
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: GoogleFonts.outfit(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                leftChevronIcon: const Icon(
                  Icons.chevron_left_rounded,
                  color: Colors.white70,
                ),
                rightChevronIcon: const Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white70,
                ),
                headerPadding: EdgeInsets.symmetric(vertical: 14.h),
                decoration: const BoxDecoration(color: Colors.transparent),
              ),

              // ── Day of week header ─────────────────────────────────────
              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle: GoogleFonts.inter(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white54,
                ),
                weekendStyle: GoogleFonts.inter(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFEF4444).withOpacity(0.8),
                ),
              ),

              // ── Custom day cell builder ────────────────────────────────
              calendarBuilders: CalendarBuilders(
                defaultBuilder: (context, day, focusedDay) =>
                    _buildDayCell(controller, day, isToday: false),
                todayBuilder: (context, day, focusedDay) =>
                    _buildDayCell(controller, day, isToday: true),
                selectedBuilder: (context, day, focusedDay) =>
                    _buildDayCell(controller, day,
                        isToday: isSameDay(day, DateTime.now()),
                        isSelected: true),
                outsideBuilder: (context, day, focusedDay) =>
                    _buildDayCell(controller, day, isOutside: true),
                dowBuilder: (context, day) {
                  final text = DateFormat.E().format(day);
                  final isSunHeader = day.weekday == DateTime.sunday;
                  return Center(
                    child: Text(
                      text,
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: isSunHeader
                            ? const Color(0xFFEF4444).withOpacity(0.8)
                            : Colors.white54,
                      ),
                    ),
                  );
                },
              ),

              calendarStyle: const CalendarStyle(
                outsideDaysVisible: true,
              ),
            ),
          ),
        ));
  }

  // ─── Square Day Cell ──────────────────────────────────────────────────────
  Widget _buildDayCell(
    HolidayCalendarController controller,
    DateTime day, {
    bool isToday = false,
    bool isSelected = false,
    bool isOutside = false,
  }) {
    final holiday = controller.getHoliday(day);
    final isHol = holiday != null;
    final isWeekend = day.weekday == DateTime.sunday ||
        (day.weekday == DateTime.saturday && day.day >= 8 && day.day <= 14);

    Color? bg;
    Color textColor;
    BoxBorder? border;
    List<BoxShadow>? shadows;

    if (isHol) {
      final c = controller.typeColor(holiday.type);
      bg = c;
      textColor = Colors.white;
      shadows = [
        BoxShadow(
          color: c.withOpacity(0.5),
          blurRadius: 8,
          offset: const Offset(0, 3),
        ),
      ];
    } else if (isToday) {
      bg = const Color(0xFF9061FF);
      textColor = Colors.white;
      shadows = [
        BoxShadow(
          color: const Color(0xFF9061FF).withOpacity(0.5),
          blurRadius: 8,
          offset: const Offset(0, 3),
        ),
      ];
    } else if (isSelected && !isHol) {
      bg = Colors.white.withOpacity(0.15);
      border = Border.all(color: const Color(0xFF9061FF), width: 1.5);
      textColor = Colors.white;
    } else if (isOutside) {
      textColor = Colors.white24;
    } else if (isWeekend) {
      textColor = const Color(0xFFEF4444).withOpacity(0.7);
    } else {
      textColor = Colors.white70;
    }

    return Padding(
      padding: EdgeInsets.all(3.w),
      child: AspectRatio(
        aspectRatio: 1,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(8.r),
            border: border,
            boxShadow: shadows,
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  day.day.toString(),
                  style: GoogleFonts.outfit(
                    fontSize: 13.sp,
                    fontWeight: isHol || isToday
                        ? FontWeight.w800
                        : FontWeight.w500,
                    color: textColor,
                  ),
                ),
                if (isHol) ...[
                  SizedBox(height: 1.h),
                  Container(
                    width: 4.w,
                    height: 4.w,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Legend ───────────────────────────────────────────────────────────────
  Widget _buildLegend() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _legendItem(const Color(0xFFEF4444), 'Public Holiday'),
          SizedBox(width: 16.w),
          _legendItem(const Color(0xFFF59E0B), 'Optional'),
          SizedBox(width: 16.w),
          _legendItem(const Color(0xFF3B82F6), 'Company Event'),
          SizedBox(width: 16.w),
          _legendItem(const Color(0xFF9061FF), 'Today'),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 10.w,
          height: 10.w,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3.r),
          ),
        ),
        SizedBox(width: 4.w),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 9.sp, color: Colors.white54),
        ),
      ],
    );
  }

  // ─── Month Holiday List ───────────────────────────────────────────────────
  Widget _buildMonthHolidayList(
    BuildContext context,
    HolidayCalendarController controller,
  ) {
    return Obx(() {
      final monthHolidays = controller.getHolidaysForMonth(
        controller.focusedDay.value.year,
        controller.focusedDay.value.month,
      );

      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.event_note_rounded,
                  color: Color(0xFF9061FF),
                  size: 16,
                ),
                SizedBox(width: 6.w),
                Text(
                  'Holidays This Month',
                  style: GoogleFonts.outfit(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.h),
            if (monthHolidays.isEmpty)
              Container(
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.celebration_rounded,
                        color: Colors.white30, size: 28),
                    SizedBox(width: 12.w),
                    Text(
                      'No holidays recorded this month.',
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        color: Colors.white38,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              )
            else
              ...monthHolidays
                  .map((h) => _buildHolidayTile(context, controller, h)),
          ],
        ),
      );
    });
  }

  Widget _buildHolidayTile(
    BuildContext context,
    HolidayCalendarController controller,
    HolidayModel holiday,
  ) {
    final color = controller.typeColor(holiday.type);
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: ListTile(
        contentPadding:
            EdgeInsets.symmetric(horizontal: 14.w, vertical: 4.h),
        leading: Container(
          width: 44.w,
          height: 44.w,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(10.r),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                DateFormat('dd').format(holiday.date),
                style: GoogleFonts.outfit(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1,
                ),
              ),
              Text(
                DateFormat('MMM').format(holiday.date).toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: 8.sp,
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        title: Text(
          holiday.title,
          style: GoogleFonts.outfit(
            fontSize: 13.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        subtitle: Row(
          children: [
            Container(
              margin: EdgeInsets.only(top: 3.h),
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: Text(
                holiday.type,
                style: GoogleFonts.inter(
                  fontSize: 9.sp,
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (holiday.description.isNotEmpty) ...[
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  holiday.description,
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    color: Colors.white38,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
        onTap: () => _showHolidayDetailSheet(context, controller, holiday),
      ),
    );
  }

  // ─── Day tap handler ──────────────────────────────────────────────────────
  void _onDayTapped(
    BuildContext context,
    HolidayCalendarController controller,
    DateTime day,
  ) {
    final holiday = controller.getHoliday(day);
    if (holiday != null) {
      _showHolidayDetailSheet(context, controller, holiday);
    }
  }

  // ─── Holiday Detail Sheet ──────────────────────────────────────────────────
  void _showHolidayDetailSheet(
    BuildContext context,
    HolidayCalendarController controller,
    HolidayModel holiday,
  ) {
    final color = controller.typeColor(holiday.type);
    final formattedDate = DateFormat('EEEE, d MMMM yyyy').format(holiday.date);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36.w,
                height: 4.h,
                margin: EdgeInsets.only(bottom: 20.h),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(Icons.celebration_rounded, color: color, size: 24),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        holiday.title,
                        style: GoogleFonts.outfit(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        holiday.type,
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          color: color,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 20.h),
            const Divider(color: Colors.white12),
            SizedBox(height: 12.h),
            Row(
              children: [
                const Icon(Icons.calendar_today_rounded,
                    color: Colors.white38, size: 16),
                SizedBox(width: 8.w),
                Text(
                  formattedDate,
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            if (holiday.description.isNotEmpty) ...[
              SizedBox(height: 16.h),
              Text(
                'Description',
                style: GoogleFonts.outfit(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white38,
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                holiday.description,
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  color: Colors.white70,
                  height: 1.5,
                ),
              ),
            ],
            SizedBox(height: 24.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.08),
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    side: BorderSide(color: Colors.white.withOpacity(0.12)),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Close',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14.sp,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
