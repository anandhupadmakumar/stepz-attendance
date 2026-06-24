import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:stepz_attendance/core/theme/premium_background.dart';
import '../../models/holiday_model.dart';
import '../controllers/holiday_calendar_controller.dart';

class AdminHolidayCalendarView extends StatelessWidget {
  const AdminHolidayCalendarView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HolidayCalendarController>();

    return PremiumBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: _buildAppBar(context, controller),
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

                // ── Calendar ──────────────────────────────────────────────
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
        floatingActionButton: _buildFAB(controller),
      ),
    );
  }

  // ─── AppBar ───────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    HolidayCalendarController controller,
  ) {
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
            'Admin — Mark & manage company holidays',
            style: GoogleFonts.inter(
              fontSize: 10.sp,
              color: Colors.white60,
            ),
          ),
        ],
      ),
      actions: [
        // Seed Indian holidays button
        Obx(
          () => IconButton(
            tooltip: 'Seed Indian Holidays',
            icon: controller.isSaving.value
                ? SizedBox(
                    height: 18.w,
                    width: 18.w,
                    child: const CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.download_rounded, color: Colors.white70),
            onPressed: controller.isSaving.value
                ? null
                : () => _showSeedConfirmDialog(controller),
          ),
        ),
        SizedBox(width: 8.w),
      ],
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
                      'No holidays this month.\nTap any date to add one.',
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
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline_rounded,
              color: Colors.white38, size: 20),
          onPressed: () => _showDeleteConfirm(context, controller, holiday),
        ),
      ),
    );
  }

  // ─── FAB — Jump to Today ──────────────────────────────────────────────────
  Widget _buildFAB(HolidayCalendarController controller) {
    return FloatingActionButton.extended(
      backgroundColor: const Color(0xFF9061FF),
      elevation: 6,
      icon: const Icon(Icons.today_rounded, color: Colors.white),
      label: Text(
        'Today',
        style: GoogleFonts.outfit(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      onPressed: () {
        controller.focusedDay.value = DateTime.now();
        controller.selectedDay.value = null;
      },
    );
  }

  // ─── Day tap handler ──────────────────────────────────────────────────────
  void _onDayTapped(
    BuildContext context,
    HolidayCalendarController controller,
    DateTime day,
  ) {
    final existing = controller.getHoliday(day);
    if (existing != null) {
      _showHolidayDetailSheet(context, controller, existing);
    } else {
      _showAddHolidaySheet(context, controller, day);
    }
  }

  // ─── Add Holiday Bottom Sheet ─────────────────────────────────────────────
  void _showAddHolidaySheet(
    BuildContext context,
    HolidayCalendarController controller,
    DateTime day,
  ) {
    controller.clearForm();
    final formatted = DateFormat('EEEE, d MMMM yyyy').format(day);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Obx(() => Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 24.h,
              top: 24.h,
              left: 20.w,
              right: 20.w,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
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
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: const Icon(Icons.calendar_today_rounded,
                          color: Color(0xFFEF4444), size: 20),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mark as Holiday',
                            style: GoogleFonts.outfit(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            formatted,
                            style: GoogleFonts.inter(
                              fontSize: 11.sp,
                              color: const Color(0xFFEF4444),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20.h),

                // Holiday Name
                Text(
                  'Holiday Name *',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    color: Colors.white60,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 6.h),
                TextField(
                  controller: controller.titleController,
                  style: GoogleFonts.inter(color: Colors.white),
                  cursorColor: const Color(0xFF9061FF),
                  decoration: InputDecoration(
                    hintText: 'e.g. Christmas Day',
                    hintStyle: GoogleFonts.inter(color: Colors.white30),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.06),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: const BorderSide(
                          color: Color(0xFF9061FF), width: 1.5),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                        horizontal: 14.w, vertical: 12.h),
                  ),
                ),
                SizedBox(height: 14.h),

                // Type chips
                Text(
                  'Holiday Type',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    color: Colors.white60,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 8.h),
                Row(
                  children: HolidayCalendarController.holidayTypes.map((t) {
                    final color = controller.typeColor(t);
                    final isSelected = controller.selectedType.value == t;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => controller.selectedType.value = t,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          margin: EdgeInsets.only(
                              right:
                                  t != HolidayCalendarController.holidayTypes.last
                                      ? 8.w
                                      : 0),
                          padding: EdgeInsets.symmetric(vertical: 10.h),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? color.withOpacity(0.2)
                                : Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(10.r),
                            border: Border.all(
                              color: isSelected
                                  ? color
                                  : Colors.white.withOpacity(0.1),
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Container(
                                width: 10.w,
                                height: 10.w,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                t,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontSize: 9.sp,
                                  color: isSelected ? color : Colors.white54,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                SizedBox(height: 14.h),

                // Description
                Text(
                  'Description (optional)',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    color: Colors.white60,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 6.h),
                TextField(
                  controller: controller.descriptionController,
                  style: GoogleFonts.inter(color: Colors.white),
                  cursorColor: const Color(0xFF9061FF),
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Add any notes...',
                    hintStyle: GoogleFonts.inter(color: Colors.white30),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.06),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: const BorderSide(
                          color: Color(0xFF9061FF), width: 1.5),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                        horizontal: 14.w, vertical: 12.h),
                  ),
                ),
                SizedBox(height: 20.h),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                      elevation: 6,
                      shadowColor: const Color(0xFFEF4444).withOpacity(0.4),
                    ),
                    onPressed: controller.isSaving.value
                        ? null
                        : () async {
                            await controller.addHoliday(
                              date: day,
                              title: controller.titleController.text,
                              type: controller.selectedType.value,
                              description:
                                  controller.descriptionController.text,
                            );
                            if (Get.isBottomSheetOpen ?? false) {
                              Get.back();
                            }
                          },
                    child: controller.isSaving.value
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            'MARK AS HOLIDAY',
                            style: GoogleFonts.outfit(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          )),
    );
  }

  // ─── Holiday Detail Sheet (Admin — with delete) ───────────────────────────
  void _showHolidayDetailSheet(
    BuildContext context,
    HolidayCalendarController controller,
    HolidayModel holiday,
  ) {
    final color = controller.typeColor(holiday.type);
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
                  width: 56.w,
                  height: 56.w,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(14.r),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        DateFormat('dd').format(holiday.date),
                        style: GoogleFonts.outfit(
                          fontSize: 22.sp,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1,
                        ),
                      ),
                      Text(
                        DateFormat('MMM').format(holiday.date).toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 9.sp,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
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
                      SizedBox(height: 4.h),
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8.w, vertical: 3.h),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                            child: Text(
                              holiday.type,
                              style: GoogleFonts.inter(
                                fontSize: 10.sp,
                                color: color,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            DateFormat('EEEE').format(holiday.date),
                            style: GoogleFonts.inter(
                              fontSize: 11.sp,
                              color: Colors.white54,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            if (holiday.description.isNotEmpty) ...[
              SizedBox(height: 16.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(14.w),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  holiday.description,
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    color: Colors.white60,
                    height: 1.5,
                  ),
                ),
              ),
            ],

            SizedBox(height: 24.h),

            // Delete Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 13.h),
                  side: BorderSide(
                      color: const Color(0xFFEF4444).withOpacity(0.5)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                ),
                icon: const Icon(Icons.delete_rounded,
                    color: Color(0xFFEF4444), size: 18),
                label: Text(
                  'REMOVE HOLIDAY',
                  style: GoogleFonts.outfit(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFEF4444),
                    letterSpacing: 0.5,
                  ),
                ),
                onPressed: () {
                  Get.back();
                  _showDeleteConfirm(context, controller, holiday);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Delete confirmation ──────────────────────────────────────────────────
  void _showDeleteConfirm(
    BuildContext context,
    HolidayCalendarController controller,
    HolidayModel holiday,
  ) {
    Get.defaultDialog(
      title: 'Remove Holiday?',
      titleStyle: GoogleFonts.outfit(
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      middleText:
          'Are you sure you want to remove "${holiday.title}" from the calendar?',
      middleTextStyle: GoogleFonts.inter(color: Colors.white60, fontSize: 13.sp),
      textConfirm: 'Remove',
      textCancel: 'Cancel',
      confirmTextColor: Colors.white,
      cancelTextColor: Colors.white70,
      buttonColor: const Color(0xFFEF4444),
      backgroundColor: const Color(0xFF0F172A),
      onConfirm: () {
        controller.deleteHoliday(holiday.holidayId);
        Get.back();
      },
    );
  }

  // ─── Seed confirm ─────────────────────────────────────────────────────────
  void _showSeedConfirmDialog(HolidayCalendarController controller) {
    Get.defaultDialog(
      title: 'Seed Indian Holidays?',
      titleStyle: GoogleFonts.outfit(
          fontWeight: FontWeight.bold, color: Colors.white),
      middleText:
          'This will add all Indian public holidays for 2025 & 2026 to the calendar. Existing dates will not be duplicated.',
      middleTextStyle:
          GoogleFonts.inter(color: Colors.white60, fontSize: 13.sp),
      textConfirm: 'Seed Now',
      textCancel: 'Cancel',
      confirmTextColor: Colors.white,
      cancelTextColor: Colors.white70,
      buttonColor: const Color(0xFF059669),
      backgroundColor: const Color(0xFF0F172A),
      onConfirm: () {
        Get.back();
        controller.seedIndianHolidays();
      },
    );
  }
}
