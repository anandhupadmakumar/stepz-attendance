import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:stepz_attendance/core/utils/csv_export_helper.dart'
    as csv_helper;
import 'package:stepz_attendance/core/utils/excel_export_helper.dart'
    as excel_helper;
import 'package:excel/excel.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stepz_attendance/firebase_options.dart';
import 'package:stepz_attendance/core/theme/theme_controller.dart';
import 'package:stepz_attendance/core/services/notification_service.dart';
import 'package:stepz_attendance/features/holiday_calendar/models/holiday_model.dart';

class ClockInRecord {
  final String name;
  final String role;
  final String time;
  final String date;
  final String location;
  final String status; // 'on_time', 'late'
  final String initials;
  final Color avatarBgColor;

  ClockInRecord({
    required this.name,
    required this.role,
    required this.time,
    required this.date,
    required this.location,
    required this.status,
    required this.initials,
    required this.avatarBgColor,
  });
}

class EmployeeProfile {
  final String uid; // Firestore Document ID / Firebase Auth UID
  final String id; // e.g. EMP-8291
  final String name;
  final String email;
  final String designation;
  final String status; // 'present', 'wfh', 'absent'
  final String role; // 'employee', 'admin'
  final String? imageUrl;
  final String initials;
  final Color avatarBgColor;
  final String? deviceId;
  final String dob;

  EmployeeProfile({
    required this.uid,
    required this.id,
    required this.name,
    required this.email,
    required this.designation,
    required this.status,
    required this.role,
    this.imageUrl,
    required this.initials,
    required this.avatarBgColor,
    this.deviceId,
    required this.dob,
  });

  EmployeeProfile copyWith({
    String? status,
    String? deviceId,
    bool clearDeviceId = false,
  }) {
    return EmployeeProfile(
      uid: uid,
      id: id,
      name: name,
      email: email,
      designation: designation,
      status: status ?? this.status,
      role: role,
      imageUrl: imageUrl,
      initials: initials,
      avatarBgColor: avatarBgColor,
      deviceId: clearDeviceId ? null : (deviceId ?? this.deviceId),
      dob: dob,
    );
  }
}

class AdminDashboardController extends GetxController {
  final bool isTesting;
  late final Rx<DateTime> selectedDate;

  AdminDashboardController({this.isTesting = false}) {
    selectedDate = (isTesting ? DateTime(2023, 10, 24) : DateTime.now()).obs;
  }

  // Date range selection state
  final RxString selectedFilterRange =
      "Day".obs; // "Day", "Week", "Month", "Custom"
  final Rx<DateTime?> customStartDate = Rx<DateTime?>(null);
  final Rx<DateTime?> customEndDate = Rx<DateTime?>(null);

  // Expose daily work updates reactively
  final RxList<Map<String, dynamic>> dailyWorkUpdates =
      <Map<String, dynamic>>[].obs;

  // Attendance Registry reactive states
  final RxString attendanceSearchQuery = "".obs;
  final RxString attendanceStatusFilter = "All".obs;
  final RxList<Map<String, dynamic>> rawAttendanceRows =
      <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> filteredAttendanceRows =
      <Map<String, dynamic>>[].obs;
  final RxInt lateComingsCount = 0.obs;

  int get attendancePresentCount => rawAttendanceRows
      .where((r) => r['status'] == 'Present' || r['status'] == 'Late')
      .length;
  int get attendanceWfhCount =>
      rawAttendanceRows.where((r) => r['status'] == 'WFH').length;
  int get attendanceAbsentCount =>
      rawAttendanceRows.where((r) => r['status'] == 'Absent').length;
  int get attendanceLateCount =>
      rawAttendanceRows.where((r) => r['status'] == 'Late').length;

  // Store all attendance records for filtering
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _allAttendanceRecords = [];

  // Directory state
  final RxBool isLoadingEmployees = false.obs;
  final RxList<EmployeeProfile> allEmployees = <EmployeeProfile>[].obs;
  final RxList<EmployeeProfile> filteredEmployees = <EmployeeProfile>[].obs;
  final RxString searchQuery = "".obs;
  final RxString selectedStatusFilter =
      "All".obs; // "All", "Present", "WFH", "Absent"
  final RxInt currentPage = 1.obs;
  final int itemsPerPage = 6; // Matching Figma's 6 slots

  // Navigation active tab index (Home = 0)
  final RxInt activeTabIndex = 0.obs;

  // Background selection state (delegated to global ThemeController)
  RxInt get selectedBgIndex => Get.find<ThemeController>().selectedBgIndex;
  List<String> get bgImages => Get.find<ThemeController>().bgImages;
  String get currentBgImage => Get.find<ThemeController>().currentBgImage;
  void changeBackground(int index) =>
      Get.find<ThemeController>().changeBackground(index);

  // Loading states
  final RxBool isExporting = false.obs;

  // Reactive Stats data matching Figma summary cards
  final RxString totalEmployees = "1,284".obs;
  final RxString presentToday = "1,120".obs;
  final RxString absentToday = "64".obs;
  final RxString wfhToday = "100".obs;

  // Active user's basic info
  final RxString adminName = "Admin User".obs;
  final RxString adminEmail = "admin@company.com".obs;

  // Reactive Recent logs list
  final RxList<ClockInRecord> recentClockIns = <ClockInRecord>[].obs;

  StreamSubscription? _attendanceSubscription;
  StreamSubscription? _usersSubscription;
  StreamSubscription? _holidaysSubscription;
  final RxList<HolidayModel> holidays = <HolidayModel>[].obs;

  // Regularization requests stats
  final RxInt pendingRegularizationsCount = 0.obs;
  final RxInt approvedRegularizationsTodayCount = 0.obs;
  final RxInt rejectedRegularizationsTodayCount = 0.obs;
  StreamSubscription? _adminRegularizationSubscription;

  // Custom Report Generation Reactive States
  final RxString reportRangeType = 'Month'.obs; // 'Month' or 'Date'
  final Rx<DateTime> reportSelectedMonth = DateTime.now().obs;
  final Rx<DateTimeRange?> reportSelectedDateRange = Rx<DateTimeRange?>(null);
  final RxList<String> reportSelectedEmployeeUids = <String>[].obs;
  final RxString reportEmployeeSearchQuery = ''.obs;
  final RxList<Map<String, dynamic>> customReportPreviewRows =
      <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    // _loadDashboardData();
    if (!isTesting) {
      _loadAdminData();
      listenToEmployees();
      listenToTodayAttendance();
      _listenToLeaveRequests();
      _listenToHolidays();
      _listenToAdminRegularizationRequests();
      // Auto-trigger birthday check greeting
      Future.delayed(const Duration(seconds: 2), () {
        Get.find<NotificationService>().checkAndSendBirthdays();
      });
    } else {
      _loadMockEmployees();
    }
  }

  @override
  void onClose() {
    _attendanceSubscription?.cancel();
    _usersSubscription?.cancel();
    _leavesSubscription?.cancel();
    _holidaysSubscription?.cancel();
    _adminRegularizationSubscription?.cancel();
    super.onClose();
  }

  Future<void> _loadAdminData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        adminEmail.value = user.email ?? '';
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          adminName.value = data['name'] ?? 'Admin User';
        }
      }
    } catch (e) {
      debugPrint("Error loading admin profile: $e");
    }
  }

  void _listenToAdminRegularizationRequests() {
    _adminRegularizationSubscription?.cancel();
    _adminRegularizationSubscription = FirebaseFirestore.instance
        .collection('attendance_regularization_requests')
        .snapshots()
        .listen((snapshot) {
          int pending = 0;
          int approvedToday = 0;
          int rejectedToday = 0;
          final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

          for (var doc in snapshot.docs) {
            final data = doc.data();
            final status = data['status'] as String? ?? 'pending';

            if (status == 'pending') {
              pending++;
            } else {
              final processedAtTs = data['processedAt'] as Timestamp?;
              if (processedAtTs != null) {
                final processedDateStr = DateFormat('yyyy-MM-dd').format(processedAtTs.toDate());
                if (processedDateStr == todayStr) {
                  if (status == 'approved') {
                    approvedToday++;
                  } else if (status == 'rejected') {
                    rejectedToday++;
                  }
                }
              }
            }
          }

          pendingRegularizationsCount.value = pending;
          approvedRegularizationsTodayCount.value = approvedToday;
          rejectedRegularizationsTodayCount.value = rejectedToday;
        }, onError: (e) {
          debugPrint('Error listening to regularization requests in admin dashboard: $e');
        });
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _lastTodayRecords = [];

  void _updateStatsFromRecords(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> filteredRecords,
  ) {
    _lastTodayRecords = filteredRecords;

    final employeeUids = allEmployees.map((e) => e.uid).toSet();

    // 1. Determine the date range limits
    final refDate = selectedDate.value;
    DateTime startDate;
    DateTime endDate;

    if (selectedFilterRange.value == 'Day') {
      startDate = DateTime(refDate.year, refDate.month, refDate.day);
      endDate = startDate;
    } else if (selectedFilterRange.value == 'Week') {
      final weekday = refDate.weekday;
      final monday = refDate.subtract(Duration(days: weekday - 1));
      startDate = DateTime(monday.year, monday.month, monday.day);
      final sunday = monday.add(const Duration(days: 6));
      endDate = DateTime(sunday.year, sunday.month, sunday.day);
    } else if (selectedFilterRange.value == 'Month') {
      startDate = DateTime(refDate.year, refDate.month, 1);
      endDate = DateTime(
        refDate.year,
        refDate.month + 1,
        0,
      ); // last day of month
    } else {
      // Custom
      if (customStartDate.value == null || customEndDate.value == null) {
        startDate = refDate;
        endDate = refDate;
      } else {
        startDate = DateTime(
          customStartDate.value!.year,
          customStartDate.value!.month,
          customStartDate.value!.day,
        );
        endDate = DateTime(
          customEndDate.value!.year,
          customEndDate.value!.month,
          customEndDate.value!.day,
        );
      }
    }

    // 2. Build date list descending (latest first for registry view)
    final List<DateTime> datesInRange = [];
    var currentDate = endDate;
    while (currentDate.isAfter(startDate) ||
        currentDate.isAtSameMomentAs(startDate)) {
      datesInRange.add(currentDate);
      currentDate = DateTime(
        currentDate.year,
        currentDate.month,
        currentDate.day - 1,
      );
    }

    // Sort filtered records ascending by checkInTimestamp so later check-ins override earlier ones
    final sortedRecords =
        List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(filteredRecords)
          ..sort((a, b) {
            final tsA =
                (a.data()['checkInTimestamp'] as Timestamp?)
                    ?.millisecondsSinceEpoch ??
                0;
            final tsB =
                (b.data()['checkInTimestamp'] as Timestamp?)
                    ?.millisecondsSinceEpoch ??
                0;
            return tsA.compareTo(tsB);
          });

    // 3. Build lookup map from the records (key: "userId_dateKey")
    final Map<String, Map<String, dynamic>> recordLookup = {};
    for (var doc in sortedRecords) {
      final data = doc.data();
      final userId = data['userId'] as String?;
      final dateKey = data['dateKey'] as String?;
      if (userId != null && dateKey != null) {
        recordLookup['${userId}_$dateKey'] = data;
      }
    }

    // 4. Generate rows for every employee on every date in the range
    final List<Map<String, dynamic>> attendanceRows = [];
    int lateCount = 0;

    for (final date in datesInRange) {
      final String dateKey = DateFormat('yyyy-MM-dd').format(date);
      final String readableDate = DateFormat('MMM dd, yyyy').format(date);
      final holiday = holidays.firstWhereOrNull((h) => h.isSameDay(date));

      for (final emp in allEmployees) {
        final record = recordLookup['${emp.uid}_$dateKey'];
        if (record == null) {
          if (holiday != null) {
            attendanceRows.add({
              'uid': emp.uid,
              'name': emp.name,
              'employeeId': emp.id,
              'designation': emp.designation,
              'date': readableDate,
              'checkIn': '--',
              'checkOut': '--',
              'workedHours': '--',
              'location': '--',
              'projectName': holiday.title,
              'taskStatus': holiday.type,
              'status': 'Holiday',
              'isHoliday': true,
            });
          } else {
            attendanceRows.add({
              'uid': emp.uid,
              'name': emp.name,
              'employeeId': emp.id,
              'designation': emp.designation,
              'date': readableDate,
              'checkIn': '--',
              'checkOut': '--',
              'workedHours': '--',
              'location': '--',
              'projectName': '--',
              'taskStatus': '--',
              'status': 'Absent',
              'isHoliday': false,
            });
          }
        } else {
          final checkIn = record['checkIn'] as String? ?? '--';
          final checkOut = record['checkOut'] as String? ?? '--';
          final workedHours = record['workedHours'] as String? ?? '--';
          final location = record['location'] as String? ?? 'Office';
          final projectName = record['projectName'] as String? ?? '--';
          final taskStatus = record['taskStatus'] as String? ?? '--';
          final late = _checkIsLate(checkIn);
          final String status;
          if (location == 'WFH') {
            status = 'WFH';
          } else if (late) {
            status = 'Late';
            lateCount++;
          } else {
            status = 'Present';
          }

          attendanceRows.add({
            'uid': emp.uid,
            'name': emp.name,
            'employeeId': emp.id,
            'designation': emp.designation,
            'date': record['date'] ?? readableDate,
            'checkIn': checkIn,
            'checkOut': checkOut,
            'workedHours': workedHours,
            'location': location,
            'projectName': holiday != null
                ? '${holiday.title} / $projectName'
                : projectName,
            'taskStatus': holiday != null
                ? '${holiday.type} / $taskStatus'
                : taskStatus,
            'status': holiday != null ? 'Holiday ($status)' : status,
            'isHoliday': holiday != null,
          });
        }
      }
    }

    lateComingsCount.value = lateCount;
    rawAttendanceRows.assignAll(attendanceRows);
    applyAttendanceFilters();

    // 5. Build lookup map for TODAY's employee status in directory
    final String todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final Map<String, String> todayAttendanceLocations = {};
    final Map<String, String> todayAttendanceCheckOuts = {};

    for (var doc in _allAttendanceRecords) {
      final data = doc.data();
      final userId = data['userId'] as String?;
      final dateKey = data['dateKey'] as String?;
      if (userId != null &&
          dateKey == todayStr &&
          employeeUids.contains(userId)) {
        todayAttendanceLocations[userId] =
            data['location'] as String? ?? 'Office';
        final co = data['checkOut'] as String?;
        if (co != null) {
          todayAttendanceCheckOuts[userId] = co;
        }
      }
    }

    // 6. Update employee list with today's status
    final List<EmployeeProfile> updatedEmployees = allEmployees.map((emp) {
      final userId = emp.uid;
      if (todayAttendanceLocations.containsKey(userId)) {
        final location = todayAttendanceLocations[userId];
        final checkOut = todayAttendanceCheckOuts[userId];
        if (checkOut != null && checkOut != '--') {
          return emp.copyWith(status: 'absent');
        } else {
          return emp.copyWith(status: location == 'WFH' ? 'wfh' : 'present');
        }
      } else {
        return emp.copyWith(status: 'absent');
      }
    }).toList();

    allEmployees.assignAll(updatedEmployees);
    applyFilters();

    // Expose work updates list
    final List<Map<String, dynamic>> updates = [];
    for (var doc in sortedRecords) {
      final data = doc.data();
      final String? projName = data['projectName'] as String?;
      final String? taskDet = data['taskDetails'] as String?;
      if ((projName != null && projName.isNotEmpty) ||
          (taskDet != null && taskDet.isNotEmpty)) {
        final userId = data['userId'] as String?;
        final employee = allEmployees.firstWhereOrNull((e) => e.uid == userId);

        final List<dynamic>? rawUpdates = data['workUpdates'] as List<dynamic>?;
        final List<Map<String, dynamic>> subUpdates = [];
        if (rawUpdates != null && rawUpdates.isNotEmpty) {
          for (var item in rawUpdates) {
            if (item is Map) {
              subUpdates.add({
                'projectName': item['projectName'] ?? '--',
                'taskTitle': item['taskTitle'] ?? '--',
                'taskDetails': item['taskDetails'] ?? '--',
                'taskStatus': item['taskStatus'] ?? 'In Progress',
                'startTime': item['startTime'] ?? '',
                'endTime': item['endTime'] ?? '',
                'progressPercentage': (item['progressPercentage'] ?? 0.0)
                    .toDouble(),
              });
            }
          }
        }

        updates.add({
          'date': data['date'] ?? (data['dateKey'] ?? '--'),
          'name': data['name'] ?? 'Employee',
          'employeeId': employee?.id ?? data['employeeId'] ?? 'EMP-000',
          'designation': employee?.designation ?? 'Staff Member',
          'projectName': projName ?? '--',
          'taskDetails': taskDet ?? '--',
          'taskStatus': data['taskStatus'] ?? 'In Progress',
          'checkIn': data['checkIn'] ?? '--',
          'checkOut': data['checkOut'] ?? '--',
          'workUpdates': subUpdates,
        });
      }
    }
    dailyWorkUpdates.assignAll(updates);

    // Calculate overall stats counts
    final int total = allEmployees.length;
    int presentCount = 0;
    int wfhCount = 0;
    for (var userId in todayAttendanceLocations.keys) {
      final location = todayAttendanceLocations[userId];
      if (location == 'WFH') {
        wfhCount++;
      } else {
        presentCount++;
      }
    }

    final int absentCount = (total - presentCount - wfhCount).clamp(0, total);

    totalEmployees.value = NumberFormat('#,###').format(total);
    presentToday.value = NumberFormat('#,###').format(presentCount);
    wfhToday.value = NumberFormat('#,###').format(wfhCount);
    absentToday.value = NumberFormat('#,###').format(absentCount);
  }

  bool _checkIsLate(String? checkInTime) {
    if (checkInTime == null ||
        checkInTime == '--' ||
        checkInTime.trim().isEmpty)
      return false;
    final cleaned = checkInTime.trim().toUpperCase();
    try {
      // 1. Attempt regex parse for 12-hour AM/PM (e.g. 09:30 AM or 9:30 AM)
      final match = RegExp(
        r'^(\d{1,2}):(\d{2})\s*(AM|PM)$',
      ).firstMatch(cleaned);
      if (match != null) {
        int hour = int.parse(match.group(1)!);
        final int minute = int.parse(match.group(2)!);
        final String ampm = match.group(3)!;

        if (ampm == 'PM' && hour != 12) {
          hour += 12;
        } else if (ampm == 'AM' && hour == 12) {
          hour = 0;
        }

        if (hour > 9) return true;
        if (hour == 9 && minute > 45) return true;
        return false;
      }

      // 2. Attempt regex parse for 24-hour (e.g. 09:30 or 9:30)
      final match24 = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(cleaned);
      if (match24 != null) {
        final int hour = int.parse(match24.group(1)!);
        final int minute = int.parse(match24.group(2)!);
        if (hour > 9) return true;
        if (hour == 9 && minute > 45) return true;
        return false;
      }

      // 3. DateFormat fallbacks
      final format = DateFormat('hh:mm a');
      final time = format.parse(cleaned);
      final cutOff = format.parse('09:45 AM');
      return time.isAfter(cutOff);
    } catch (_) {
      try {
        final format2 = DateFormat('h:mm a');
        final time = format2.parse(cleaned);
        final cutOff = format2.parse('9:45 AM');
        return time.isAfter(cutOff);
      } catch (e) {
        debugPrint("Error parsing check-in time '$checkInTime': $e");
        return false;
      }
    }
  }

  void listenToTodayAttendance() {
    _attendanceSubscription = FirebaseFirestore.instance
        .collection('attendance')
        .snapshots()
        .listen(
          (snapshot) {
            _allAttendanceRecords = snapshot.docs;

            // Update stats and updates
            updateFilteredData();

            // Update recent clock-ins from Firestore (global recent check-ins)
            final sortedDocs = snapshot.docs.toList()
              ..sort((a, b) {
                final tsA =
                    (a.data()['checkInTimestamp'] as Timestamp?)
                        ?.millisecondsSinceEpoch ??
                    0;
                final tsB =
                    (b.data()['checkInTimestamp'] as Timestamp?)
                        ?.millisecondsSinceEpoch ??
                    0;
                return tsB.compareTo(tsA);
              });

            final List<ClockInRecord> records = [];
            for (var doc in sortedDocs.take(5)) {
              final data = doc.data();
              final String name = data['name'] ?? 'Employee';
              final String checkInTime = data['checkIn'] ?? '--';
              final String location = data['location'] ?? 'Office';
              final String empId = data['employeeId'] ?? 'EMP-000';

              final employee = allEmployees.firstWhereOrNull(
                (e) =>
                    e.id.toLowerCase() == empId.toLowerCase() ||
                    e.name.toLowerCase() == name.toLowerCase(),
              );
              final String role = employee?.designation ?? 'Staff Member';

              final String status = _checkIsLate(checkInTime)
                  ? 'late'
                  : 'on_time';

              String initials = 'E';
              if (name.isNotEmpty) {
                final parts = name.trim().split(' ');
                if (parts.length > 1) {
                  initials = '${parts[0][0]}${parts[1][0]}'.toUpperCase();
                } else {
                  initials = parts[0]
                      .substring(0, parts[0].length > 1 ? 2 : 1)
                      .toUpperCase();
                }
              }

              final List<Color> colors = [
                const Color(0xFF420093),
                const Color(0xFF4E45D5),
                const Color(0xFF7C3AED),
                const Color(0xFF16A34A),
              ];
              final color = colors[empId.hashCode % colors.length];

              records.add(
                ClockInRecord(
                  name: name,
                  role: role,
                  time: checkInTime,
                  date: data['date'] ?? (data['dateKey'] ?? '--'),
                  location: location == 'WFH' ? 'Remote' : 'Office',
                  status: status,
                  initials: initials,
                  avatarBgColor: color,
                ),
              );
            }

            if (records.isNotEmpty) {
              recentClockIns.assignAll(records);
            } else {
              _loadDashboardData();
            }
          },
          onError: (e) {
            debugPrint('Error listening to today attendance: $e');
          },
        );
  }

  void _loadDashboardData() {
    // Populate mock data matching the exact Figma entries
    recentClockIns.assignAll([
      ClockInRecord(
        name: 'Jane Doe',
        role: 'Software Engineer',
        time: '08:54 AM',
        date: 'Oct 24, 2023',
        location: 'Main Office - Gate A',
        status: 'on_time',
        initials: 'JD',
        avatarBgColor: const Color(0xFF420093),
      ),
      ClockInRecord(
        name: 'Mark Smith',
        role: 'Product Manager',
        time: '09:15 AM',
        date: 'Oct 24, 2023',
        location: 'Remote - London',
        status: 'late',
        initials: 'MS',
        avatarBgColor: const Color(0xFF4E45D5),
      ),
      ClockInRecord(
        name: 'Alex Kim',
        role: 'UX Designer',
        time: '08:45 AM',
        date: 'Oct 24, 2023',
        location: 'Main Office - Gate B',
        status: 'on_time',
        initials: 'AK',
        avatarBgColor: const Color(0xFF410094),
      ),
    ]);
  }

  // Get formatted date for display matching the exact Figma date label "Oct 24, 2023"
  String get formattedSelectedDate =>
      DateFormat('MMM dd, yyyy').format(selectedDate.value);

  // Pick Date Action
  Future<void> selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate.value,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF420093), // header background color
              onPrimary: Colors.white, // header text color
              onSurface: Color(0xFF1C1B1B), // body text color
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != selectedDate.value) {
      selectedDate.value = picked;
      // In production, we would fetch data for the selected date from Firestore
    }
  }

  // Update navigation tab
  void changeTab(int index) {
    activeTabIndex.value = index;
  }

  // Export PDF Action
  Future<void> exportPDF() async {
    isExporting.value = true;
    Get.rawSnackbar(
      title: 'Exporting PDF',
      message: 'Generating attendance report logs...',
      backgroundColor: const Color(0xFF4E45D5),
      showProgressIndicator: true,
      snackPosition: SnackPosition.BOTTOM,
    );

    // Simulate generation delay
    await Future.delayed(const Duration(seconds: 2));

    isExporting.value = false;
    Get.rawSnackbar(
      title: 'Success',
      message: 'Attendance report exported successfully.',
      backgroundColor: const Color(0xFF16A34A),
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  // Quick Action triggers
  void broadcastMessage() {
    final titleController = TextEditingController();
    final messageController = TextEditingController();

    Get.defaultDialog(
      title: 'Broadcast Announcement',
      titleStyle: GoogleFonts.inter(
        fontWeight: FontWeight.bold,
        color: Colors.white,
        fontSize: 18.sp,
      ),
      backgroundColor: const Color(0xFF0F172A),
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'NEWS TITLE',
            style: GoogleFonts.inter(
              fontSize: 10.sp,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF64748B),
            ),
          ),
          SizedBox(height: 6.h),
          TextField(
            controller: titleController,
            style: GoogleFonts.inter(color: Colors.white, fontSize: 14.sp),
            decoration: InputDecoration(
              hintText: 'e.g. System Maintenance Update',
              hintStyle: GoogleFonts.inter(color: Colors.white38),
              fillColor: Colors.white.withOpacity(0.05),
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'ANNOUNCEMENT MESSAGE',
            style: GoogleFonts.inter(
              fontSize: 10.sp,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF64748B),
            ),
          ),
          SizedBox(height: 6.h),
          TextField(
            controller: messageController,
            maxLines: 4,
            style: GoogleFonts.inter(color: Colors.white, fontSize: 13.sp),
            decoration: InputDecoration(
              hintText: 'Enter the important news description here...',
              hintStyle: GoogleFonts.inter(color: Colors.white38),
              fillColor: Colors.white.withOpacity(0.05),
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
      textConfirm: 'BROADCAST',
      textCancel: 'CANCEL',
      confirmTextColor: Colors.white,
      cancelTextColor: const Color(0xFF94A3B8),
      buttonColor: const Color(0xFF9061FF),
      onConfirm: () async {
        final title = titleController.text.trim();
        final body = messageController.text.trim();

        if (title.isEmpty || body.isEmpty) {
          Get.rawSnackbar(
            title: 'Validation Error',
            message: 'Please fill in both title and message.',
            backgroundColor: Colors.red.shade700,
          );
          return;
        }

        Get.back(); // close dialog

        try {
          await Get.find<NotificationService>().sendNotification(
            targetRole: 'all', // Send to all employees and admins
            title: title,
            body: body,
            type: 'broadcast',
          );

          Get.rawSnackbar(
            title: 'Broadcast Sent',
            message: 'Announcements have been broadcasted successfully.',
            backgroundColor: const Color(0xFF16A34A),
          );
        } catch (e) {
          Get.rawSnackbar(
            title: 'Error',
            message: 'Failed to broadcast message: $e',
            backgroundColor: Colors.red.shade700,
          );
        }
      },
    );
  }

  void generateReport() {
    Get.rawSnackbar(
      title: 'Report Generation',
      message: 'Compiling monthly attendance statistics reports...',
      backgroundColor: const Color(0xFF4E45D5),
    );
  }

  void addNewStaff() {
    // Will be overridden to open bottom sheet in the view
  }

  List<EmployeeProfile> _mapEmployeesStatus(
    List<EmployeeProfile> employees,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> attendanceRecords,
  ) {
    if (employees.isEmpty) return [];

    final Map<String, Map<String, dynamic>> latestRecordPerUser = {};
    final employeeUids = employees.map((e) => e.uid).toSet();

    final sortedRecords =
        List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(
          attendanceRecords,
        )..sort((a, b) {
          final tsA =
              (a.data()['checkInTimestamp'] as Timestamp?)
                  ?.millisecondsSinceEpoch ??
              0;
          final tsB =
              (b.data()['checkInTimestamp'] as Timestamp?)
                  ?.millisecondsSinceEpoch ??
              0;
          return tsA.compareTo(tsB);
        });

    for (var doc in sortedRecords) {
      final data = doc.data();
      final userId = data['userId'] as String?;
      if (userId != null && employeeUids.contains(userId)) {
        latestRecordPerUser[userId] = data;
      }
    }

    return employees.map((emp) {
      final userId = emp.uid;
      if (latestRecordPerUser.containsKey(userId)) {
        final record = latestRecordPerUser[userId]!;
        final location = record['location'] as String? ?? 'Office';
        final checkOut = record['checkOut'] as String?;
        if (checkOut != null && checkOut != '--') {
          return emp.copyWith(status: 'absent');
        } else {
          return emp.copyWith(status: location == 'WFH' ? 'wfh' : 'present');
        }
      } else {
        return emp.copyWith(status: 'absent');
      }
    }).toList();
  }

  void _listenToHolidays() {
    _holidaysSubscription = FirebaseFirestore.instance
        .collection('holidays')
        .snapshots()
        .listen(
          (snapshot) {
            holidays.value = snapshot.docs
                .map((doc) => HolidayModel.fromMap(doc.data(), doc.id))
                .toList();
            if (_lastTodayRecords.isNotEmpty) {
              _updateStatsFromRecords(_lastTodayRecords);
            }
            if (reportSelectedEmployeeUids.isNotEmpty) {
              calculateCustomReportPreview();
            }
          },
          onError: (e) {
            debugPrint("Error listening to holidays: $e");
          },
        );
  }

  void listenToEmployees() {
    isLoadingEmployees.value = true;
    _usersSubscription = FirebaseFirestore.instance
        .collection('users')
        .snapshots()
        .listen(
          (snapshot) {
            final List<EmployeeProfile> mockupList = [
              EmployeeProfile(
                uid: 'mock-uid-1',
                id: 'EMP-8291',
                name: 'Alex Rivers',
                email: 'alex.rivers@company.com',
                designation: 'Lead UX Designer',
                status: 'present',
                role: 'employee',
                initials: 'AR',
                avatarBgColor: const Color(0xFF420093),
                deviceId: null,
                dob: '1995-10-15',
              ),
            ];

            List<EmployeeProfile> firestoreList = [];
            for (var doc in snapshot.docs) {
              final data = doc.data();
              final String name =
                  data['name'] ?? data['email']?.split('@')[0] ?? 'User';
              final String id =
                  data['employeeId'] ??
                  'EMP-${doc.id.substring(0, 4).toUpperCase()}';
              final String designation = data['designation'] ?? 'Staff';
              final String status = data['status'] ?? 'present';
              final String role = data['role'] ?? 'employee';
              final String email = data['email'] ?? '';
              final String? deviceId = data['deviceId'];

              // Skip administrators in the employee directory
              if (role == 'admin') continue;

              // Clean initials
              String initials = 'U';
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

              // Pick avatar background
              final List<Color> colors = [
                const Color(0xFF420093),
                const Color(0xFF4E45D5),
                const Color(0xFF7C3AED),
                const Color(0xFF16A34A),
              ];
              final color = colors[id.hashCode % colors.length];

              // Check if this employee ID already exists in mockupList to avoid duplicates
              if (!mockupList.any(
                (m) =>
                    m.id.toLowerCase() == id.toLowerCase() ||
                    m.email.toLowerCase() == email.toLowerCase(),
              )) {
                firestoreList.add(
                  EmployeeProfile(
                    uid: doc.id,
                    id: id,
                    name: name,
                    email: email,
                    designation: designation,
                    status: status,
                    role: role,
                    initials: initials,
                    avatarBgColor: color,
                    deviceId: deviceId,
                    dob: data['dob'] ?? '',
                  ),
                );
              }
            }

            List<EmployeeProfile> finalList = firestoreList.isNotEmpty
                ? firestoreList
                : mockupList;
            finalList = _mapEmployeesStatus(finalList, _lastTodayRecords);
            allEmployees.assignAll(finalList);
            applyFilters();

            if (_lastTodayRecords.isNotEmpty) {
              _updateStatsFromRecords(_lastTodayRecords);
            } else {
              _updateStatsCounts();
            }
            isLoadingEmployees.value = false;
          },
          onError: (e) {
            debugPrint("Error listening to employees: $e");
            isLoadingEmployees.value = false;
          },
        );
  }

  Future<void> resetDeviceBinding(String userId) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'deviceId': FieldValue.delete(),
      });
      Get.rawSnackbar(
        title: 'Success',
        message: 'Device binding reset successfully.',
        backgroundColor: const Color(0xFF16A34A),
      );
      // Reload directory to update local state
      await fetchEmployees();
    } catch (e) {
      Get.rawSnackbar(
        title: 'Error',
        message: 'Failed to reset device binding: $e',
        backgroundColor: Colors.red.shade700,
      );
    }
  }

  Future<void> updateEmployeeProfile({
    required String uid,
    required String name,
    required String designation,
    required String employeeId,
    required String email,
    required String dob,
    required String status,
    required String role,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'name': name.trim(),
        'designation': designation.trim(),
        'employeeId': employeeId.trim().toUpperCase(),
        'email': email.trim().toLowerCase(),
        'dob': dob.trim(),
        'status': status.toLowerCase(),
        'role': role.toLowerCase(),
      });
      Get.rawSnackbar(
        title: 'Success',
        message: 'Employee profile updated successfully.',
        backgroundColor: const Color(0xFF16A34A),
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.rawSnackbar(
        title: 'Update Error',
        message: e.toString(),
        backgroundColor: Colors.red.shade700,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> deleteEmployeeAccount(String uid) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).delete();
      Get.rawSnackbar(
        title: 'Deleted',
        message: 'Employee account deleted successfully.',
        backgroundColor: const Color(0xFF16A34A),
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.rawSnackbar(
        title: 'Deletion Error',
        message: e.toString(),
        backgroundColor: Colors.red.shade700,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> fetchEmployees() async {
    isLoadingEmployees.value = true;
    try {
      // 1. Initialise the Figma mockup list
      final List<EmployeeProfile> mockupList = [
        EmployeeProfile(
          uid: 'mock-uid-1',
          id: 'EMP-8291',
          name: 'Alex Rivers',
          email: 'alex.rivers@company.com',
          designation: 'Lead UX Designer',
          status: 'present',
          role: 'employee',
          initials: 'AR',
          avatarBgColor: const Color(0xFF420093),
          deviceId: null,
          dob: '1995-10-15',
        ),
      ];

      // 2. Query Firestore database users collection
      List<EmployeeProfile> firestoreList = [];
      try {
        final querySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .get();
        for (var doc in querySnapshot.docs) {
          final data = doc.data();
          final String name =
              data['name'] ?? data['email']?.split('@')[0] ?? 'User';
          final String id =
              data['employeeId'] ??
              'EMP-${doc.id.substring(0, 4).toUpperCase()}';
          final String designation = data['designation'] ?? 'Staff';
          final String status = data['status'] ?? 'present';
          final String role = data['role'] ?? 'employee';
          final String email = data['email'] ?? '';
          final String? deviceId = data['deviceId'];

          // Skip administrators in the employee directory
          if (role == 'admin') continue;

          // Clean initials
          String initials = 'U';
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

          // Pick avatar background
          final List<Color> colors = [
            const Color(0xFF420093),
            const Color(0xFF4E45D5),
            const Color(0xFF7C3AED),
            const Color(0xFF16A34A),
          ];
          final color = colors[id.hashCode % colors.length];

          // Check if this employee ID already exists in mockupList to avoid duplicates
          if (!mockupList.any(
            (m) =>
                m.id.toLowerCase() == id.toLowerCase() ||
                m.email.toLowerCase() == email.toLowerCase(),
          )) {
            firestoreList.add(
              EmployeeProfile(
                uid: doc.id,
                id: id,
                name: name,
                email: email,
                designation: designation,
                status: status,
                role: role,
                initials: initials,
                avatarBgColor: color,
                deviceId: deviceId,
                dob: data['dob'] ?? '',
              ),
            );
          }
        }
      } catch (firestoreError) {
        debugPrint("Firestore fetch error: $firestoreError");
      }

      // 3. Combine list
      List<EmployeeProfile> finalList = firestoreList.isNotEmpty
          ? firestoreList
          : mockupList;
      finalList = _mapEmployeesStatus(finalList, _lastTodayRecords);
      allEmployees.assignAll(finalList);
      applyFilters();
      if (_lastTodayRecords.isNotEmpty) {
        _updateStatsFromRecords(_lastTodayRecords);
      } else {
        _updateStatsCounts();
      }
    } finally {
      isLoadingEmployees.value = false;
    }
  }

  void applyFilters() {
    List<EmployeeProfile> list = List.from(allEmployees);

    // Apply Search Query
    if (searchQuery.value.trim().isNotEmpty) {
      final query = searchQuery.value.toLowerCase().trim();
      list = list.where((e) {
        return e.name.toLowerCase().contains(query) ||
            e.id.toLowerCase().contains(query) ||
            e.designation.toLowerCase().contains(query) ||
            e.email.toLowerCase().contains(query);
      }).toList();
    }

    // Apply Status Filter
    if (selectedStatusFilter.value != 'All') {
      final filter = selectedStatusFilter.value.toLowerCase();
      list = list.where((e) => e.status == filter).toList();
    }

    filteredEmployees.assignAll(list);
    currentPage.value = 1; // reset page to 1
  }

  /// Filters [rawAttendanceRows] by search query and status chip into [filteredAttendanceRows].
  void applyAttendanceFilters() {
    List<Map<String, dynamic>> list = List.from(rawAttendanceRows);

    // Search by name or employee ID
    final query = attendanceSearchQuery.value.trim().toLowerCase();
    if (query.isNotEmpty) {
      list = list.where((r) {
        final name = (r['name'] as String? ?? '').toLowerCase();
        final id = (r['employeeId'] as String? ?? '').toLowerCase();
        return name.contains(query) || id.contains(query);
      }).toList();
    }

    // Filter by status chip
    final statusFilter = attendanceStatusFilter.value;
    if (statusFilter != 'All') {
      list = list.where((r) => r['status'] == statusFilter).toList();
    }

    filteredAttendanceRows.assignAll(list);
  }

  List<EmployeeProfile> get paginatedEmployees {
    final startIndex = (currentPage.value - 1) * itemsPerPage;
    final endIndex = startIndex + itemsPerPage;
    if (startIndex >= filteredEmployees.length) return [];
    return filteredEmployees.sublist(
      startIndex,
      endIndex > filteredEmployees.length ? filteredEmployees.length : endIndex,
    );
  }

  int get totalPages => (filteredEmployees.length / itemsPerPage).ceil();

  void nextPage() {
    if (currentPage.value < totalPages) {
      currentPage.value++;
    }
  }

  void previousPage() {
    if (currentPage.value > 1) {
      currentPage.value--;
    }
  }

  String getNextEmployeeId() {
    int maxId = 0;
    final regex = RegExp(r'^EMP(\d{3})$', caseSensitive: false);
    for (var emp in allEmployees) {
      final match = regex.firstMatch(emp.id.trim());
      if (match != null) {
        final idNum = int.tryParse(match.group(1) ?? '0') ?? 0;
        if (idNum > maxId) {
          maxId = idNum;
        }
      }
    }
    final nextId = maxId + 1;
    return 'EMP${nextId.toString().padLeft(3, '0')}';
  }

  void _updateStatsCounts() {
    final int total = allEmployees.length;
    final int present = allEmployees.where((e) => e.status == 'present').length;
    final int wfh = allEmployees.where((e) => e.status == 'wfh').length;
    final int absent = allEmployees.where((e) => e.status == 'absent').length;

    // Format them for the summary view
    totalEmployees.value = NumberFormat('#,###').format(total);
    presentToday.value = NumberFormat('#,###').format(present);
    wfhToday.value = NumberFormat('#,###').format(wfh);
    absentToday.value = NumberFormat('#,###').format(absent);
  }

  void _loadMockEmployees() {
    allEmployees.assignAll([
      EmployeeProfile(
        uid: 'mock-uid-1',
        id: 'EMP-8291',
        name: 'Alex Rivers',
        email: 'alex.rivers@company.com',
        designation: 'Lead UX Designer',
        status: 'present',
        role: 'employee',
        initials: 'AR',
        avatarBgColor: const Color(0xFF420093),
        deviceId: null,
        dob: '1995-10-15',
      ),
    ]);
    applyFilters();
    _updateStatsCounts();
  }

  Future<bool> saveEmployee({
    required String name,
    required String email,
    required String password,
    required String employeeId,
    required String designation,
    required String status,
    required String role,
    required String dob,
  }) async {
    isLoadingEmployees.value = true;
    try {
      final idExists = allEmployees.any(
        (e) => e.id.toLowerCase() == employeeId.toLowerCase().trim(),
      );
      final emailExists = allEmployees.any(
        (e) => e.email.toLowerCase() == email.toLowerCase().trim(),
      );

      if (idExists) {
        Get.rawSnackbar(
          title: 'Error',
          message: 'An employee with ID "$employeeId" already exists.',
          backgroundColor: Colors.red.shade700,
        );
        return false;
      }

      if (emailExists) {
        Get.rawSnackbar(
          title: 'Error',
          message: 'An employee with email "$email" already exists.',
          backgroundColor: Colors.red.shade700,
        );
        return false;
      }

      // 1. Create authentication user in Firebase Auth using a secondary app instance
      String newUid;
      try {
        FirebaseApp tempApp = await Firebase.initializeApp(
          name: 'tempRegisterApp',
          options: DefaultFirebaseOptions.currentPlatform,
        );
        UserCredential tempUserCred =
            await FirebaseAuth.instanceFor(
              app: tempApp,
            ).createUserWithEmailAndPassword(
              email: email.trim().toLowerCase(),
              password: password,
            );
        newUid = tempUserCred.user!.uid;
        await tempApp.delete();
      } catch (authError) {
        debugPrint("Secondary auth creation error: $authError");
        // Fallback for tests/environments without real Firebase setup
        newUid = FirebaseFirestore.instance.collection('users').doc().id;
      }

      // 2. Save user profile document to Cloud Firestore
      await FirebaseFirestore.instance.collection('users').doc(newUid).set({
        'name': name.trim(),
        'email': email.trim().toLowerCase(),
        'employeeId': employeeId.trim().toUpperCase(),
        'designation': designation.trim(),
        'status': status.toLowerCase(),
        'role': role.toLowerCase(),
        'password': password,
        'dob': dob.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      Get.rawSnackbar(
        title: 'Success',
        message: 'Employee "$name" added successfully.',
        backgroundColor: Colors.green.shade700,
      );

      // Reload directory
      await fetchEmployees();
      return true;
    } catch (e) {
      Get.rawSnackbar(
        title: 'Save Error',
        message: e.toString(),
        backgroundColor: Colors.red.shade700,
      );
      return false;
    } finally {
      isLoadingEmployees.value = false;
    }
  }

  // Date range filters and work task updates methods
  bool isRecordInSelectedRange(Map<String, dynamic> data) {
    final String? dateKeyStr = data['dateKey'] as String?;
    if (dateKeyStr == null) return false;

    try {
      final recordDate = DateFormat('yyyy-MM-dd').parse(dateKeyStr);
      final refDate = selectedDate.value;

      if (selectedFilterRange.value == 'Day') {
        return recordDate.year == refDate.year &&
            recordDate.month == refDate.month &&
            recordDate.day == refDate.day;
      } else if (selectedFilterRange.value == 'Week') {
        final weekday = refDate.weekday;
        final monday = refDate.subtract(Duration(days: weekday - 1));
        final sunday = monday.add(const Duration(days: 6));

        final start = DateTime(monday.year, monday.month, monday.day);
        final end = DateTime(sunday.year, sunday.month, sunday.day, 23, 59, 59);

        return recordDate.isAfter(start.subtract(const Duration(seconds: 1))) &&
            recordDate.isBefore(end.add(const Duration(seconds: 1)));
      } else if (selectedFilterRange.value == 'Month') {
        return recordDate.year == refDate.year &&
            recordDate.month == refDate.month;
      } else if (selectedFilterRange.value == 'Custom') {
        if (customStartDate.value == null || customEndDate.value == null)
          return false;

        final start = DateTime(
          customStartDate.value!.year,
          customStartDate.value!.month,
          customStartDate.value!.day,
        );
        final end = DateTime(
          customEndDate.value!.year,
          customEndDate.value!.month,
          customEndDate.value!.day,
          23,
          59,
          59,
        );

        return recordDate.isAfter(start.subtract(const Duration(seconds: 1))) &&
            recordDate.isBefore(end.add(const Duration(seconds: 1)));
      }
    } catch (e) {
      debugPrint("Error parsing date in range filter: $e");
    }
    return false;
  }

  void updateFilteredData() {
    final filteredRecords = _allAttendanceRecords.where((doc) {
      return isRecordInSelectedRange(doc.data());
    }).toList();

    _updateStatsFromRecords(filteredRecords);
  }

  String get formattedRangeLabel {
    final refDate = selectedDate.value;
    if (selectedFilterRange.value == 'Day') {
      return DateFormat('MMM dd, yyyy').format(refDate);
    } else if (selectedFilterRange.value == 'Week') {
      final weekday = refDate.weekday;
      final monday = refDate.subtract(Duration(days: weekday - 1));
      final sunday = monday.add(const Duration(days: 6));
      return 'Week: ${DateFormat('MMM dd').format(monday)} - ${DateFormat('MMM dd, yyyy').format(sunday)}';
    } else if (selectedFilterRange.value == 'Month') {
      return DateFormat('MMMM yyyy').format(refDate);
    } else {
      if (customStartDate.value == null || customEndDate.value == null) {
        return 'Select custom range';
      }
      return 'Range: ${DateFormat('MMM dd').format(customStartDate.value!)} - ${DateFormat('MMM dd, yyyy').format(customEndDate.value!)}';
    }
  }

  Future<void> selectCustomDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange:
          customStartDate.value != null && customEndDate.value != null
          ? DateTimeRange(
              start: customStartDate.value!,
              end: customEndDate.value!,
            )
          : DateTimeRange(
              start: DateTime.now().subtract(const Duration(days: 7)),
              end: DateTime.now(),
            ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF420093),
              onPrimary: Colors.white,
              onSurface: Color(0xFF1C1B1B),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      customStartDate.value = picked.start;
      customEndDate.value = picked.end;
      updateFilteredData();
    } else {
      if (customStartDate.value == null) {
        selectedFilterRange.value = 'Day';
        updateFilteredData();
      }
    }
  }

  Future<void> handleDateSelection(BuildContext context) async {
    if (selectedFilterRange.value == 'Custom') {
      await selectCustomDateRange(context);
    } else {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: selectedDate.value,
        firstDate: DateTime(2020),
        lastDate: DateTime(2030),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: Color(0xFF420093),
                onPrimary: Colors.white,
                onSurface: Color(0xFF1C1B1B),
              ),
            ),
            child: child!,
          );
        },
      );
      if (picked != null) {
        selectedDate.value = picked;
        updateFilteredData();
      }
    }
  }

  /// Exports the current filteredAttendanceRows to a CSV file — salary ready.
  Future<void> exportAttendanceToCsv() async {
    isExporting.value = true;
    Get.rawSnackbar(
      title: 'Exporting Attendance',
      message: 'Generating salary-ready attendance spreadsheet...',
      backgroundColor: const Color(0xFF420093),
      showProgressIndicator: true,
      snackPosition: SnackPosition.BOTTOM,
    );

    try {
      final csvBuffer = StringBuffer();
      // Salary-ready header
      csvBuffer.writeln(
        'Date,Employee ID,Employee Name,Designation,Check-In,Check-Out,Worked Hours,Location,Status,Project Name,Task Status',
      );

      for (final row in filteredAttendanceRows) {
        final date = row['date'] ?? '';
        final empId = row['employeeId'] ?? '';
        final name = row['name'] ?? '';
        final designation = (row['designation'] ?? '').toString().replaceAll(
          ',',
          ';',
        );
        final checkIn = row['checkIn'] ?? '--';
        final checkOut = row['checkOut'] ?? '--';
        final workedHours = row['workedHours'] ?? '--';
        final location = row['location'] ?? '--';
        final status = row['status'] ?? '--';
        final projectName = (row['projectName'] ?? '--').toString().replaceAll(
          ',',
          ';',
        );
        final taskStatus = row['taskStatus'] ?? '--';
        csvBuffer.writeln(
          '"$date","$empId","$name","$designation","$checkIn","$checkOut","$workedHours","$location","$status","$projectName","$taskStatus"',
        );
      }

      // Build a clean filename from the formatted range label
      final rangeLabel = formattedRangeLabel
          .replaceAll(': ', '_')
          .replaceAll(' - ', '_to_')
          .replaceAll(', ', '_')
          .replaceAll(' ', '_')
          .replaceAll('/', '-');
      final filename = 'attendance_$rangeLabel.csv';
      csv_helper.saveCsvFile(csvBuffer.toString(), filename);

      Get.rawSnackbar(
        title: 'Export Complete ✓',
        message: kIsWeb
            ? 'Download started — open the CSV in Excel for salary calculations.'
            : 'Report saved as $filename',
        backgroundColor: const Color(0xFF16A34A),
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 5),
      );
    } catch (e) {
      debugPrint('Error exporting attendance CSV: $e');
      Get.rawSnackbar(
        title: 'Export Error',
        message: e.toString(),
        backgroundColor: Colors.red.shade700,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isExporting.value = false;
    }
  }

  /// Exports the current rawAttendanceRows to a multi-tab Excel spreadsheet.
  Future<void> exportAttendanceToExcel() async {
    isExporting.value = true;
    Get.rawSnackbar(
      title: 'Exporting Attendance',
      message: 'Generating multi-tab Excel spreadsheet...',
      backgroundColor: const Color(0xFF420093),
      showProgressIndicator: true,
      snackPosition: SnackPosition.BOTTOM,
    );

    try {
      final excel = Excel.createExcel();

      // Rename default Sheet1 to Summary
      excel.rename('Sheet1', 'Summary');
      final summarySheet = excel['Summary'];

      // Add Headers to Summary tab
      summarySheet.appendRow([
        TextCellValue('Employee ID'),
        TextCellValue('Employee Name'),
        TextCellValue('Designation'),
        TextCellValue('Present Days'),
        TextCellValue('WFH Days'),
        TextCellValue('Late Days'),
        TextCellValue('Absent Days'),
        TextCellValue('Total Worked Hours'),
      ]);

      // Map to keep track of employee sheets to write detailed logs
      final Map<String, List<Map<String, dynamic>>> employeeRowsMap = {};

      // Initialize map for all active employees so they all get a tab even if they have no records
      for (final emp in allEmployees) {
        employeeRowsMap[emp.uid] = [];
      }

      // Group filtered attendance records by employee
      for (final row in rawAttendanceRows) {
        final uid = row['uid'] as String? ?? '';
        if (employeeRowsMap.containsKey(uid)) {
          employeeRowsMap[uid]!.add(row);
        }
      }

      // Write Summary Rows and create Tab sheets
      for (final emp in allEmployees) {
        final logs = employeeRowsMap[emp.uid] ?? [];

        int presentCount = 0;
        int wfhCount = 0;
        int lateCount = 0;
        int absentCount = 0;
        double totalHours = 0.0;

        for (final log in logs) {
          final status = log['status'] ?? '--';
          if (status == 'Present') {
            presentCount++;
          } else if (status == 'WFH') {
            wfhCount++;
          } else if (status == 'Late') {
            lateCount++;
          } else if (status == 'Absent') {
            absentCount++;
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

        // Add row to Summary sheet
        summarySheet.appendRow([
          TextCellValue(emp.id),
          TextCellValue(emp.name),
          TextCellValue(emp.designation),
          IntCellValue(presentCount),
          IntCellValue(wfhCount),
          IntCellValue(lateCount),
          IntCellValue(absentCount),
          TextCellValue('${totalHours.toStringAsFixed(1)} hrs'),
        ]);

        // Create individual tab sheet for this employee
        // Limit sheet name to 31 chars (Excel requirement)
        final String sheetName = emp.name.length > 30
            ? emp.name.substring(0, 30)
            : emp.name;
        final empSheet = excel[sheetName];

        // Headers
        empSheet.appendRow([
          TextCellValue('Date'),
          TextCellValue('Check-In'),
          TextCellValue('Check-Out'),
          TextCellValue('Worked Hours'),
          TextCellValue('Location'),
          TextCellValue('Status'),
          TextCellValue('Project Name'),
          TextCellValue('Task Status'),
        ]);

        if (logs.isEmpty) {
          empSheet.appendRow([
            TextCellValue('No attendance records for this period.'),
            null,
            null,
            null,
            null,
            null,
            null,
            null,
          ]);
        } else {
          // Sort logs by date to display chronologically
          logs.sort((a, b) {
            final dateAStr = a['date'] ?? '';
            final dateBStr = b['date'] ?? '';
            try {
              final dateA = DateFormat('MMM dd, yyyy').parse(dateAStr);
              final dateB = DateFormat('MMM dd, yyyy').parse(dateBStr);
              return dateA.compareTo(dateB);
            } catch (_) {
              return dateAStr.compareTo(dateBStr);
            }
          });

          for (final log in logs) {
            empSheet.appendRow([
              TextCellValue(log['date'] ?? ''),
              TextCellValue(log['checkIn'] ?? '--'),
              TextCellValue(log['checkOut'] ?? '--'),
              TextCellValue(log['workedHours'] ?? '--'),
              TextCellValue(log['location'] ?? '--'),
              TextCellValue(log['status'] ?? '--'),
              TextCellValue(log['projectName'] ?? '--'),
              TextCellValue(log['taskStatus'] ?? '--'),
            ]);
          }
        }
      }

      // Generate file bytes
      final fileBytes = excel.save();
      if (fileBytes != null) {
        final rangeLabel = formattedRangeLabel
            .replaceAll(': ', '_')
            .replaceAll(' - ', '_to_')
            .replaceAll(', ', '_')
            .replaceAll(' ', '_')
            .replaceAll('/', '-');
        final filename = 'attendance_$rangeLabel.xlsx';

        excel_helper.saveExcelFile(fileBytes, filename);

        Get.rawSnackbar(
          title: 'Excel Export Complete ✓',
          message: kIsWeb
              ? 'Multi-tab spreadsheet download started.'
              : 'Report saved as $filename',
          backgroundColor: const Color(0xFF16A34A),
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 5),
        );
      }
    } catch (e, stack) {
      debugPrint('Error exporting Excel: $e\n$stack');
      Get.rawSnackbar(
        title: 'Export Error',
        message: e.toString(),
        backgroundColor: Colors.red.shade700,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isExporting.value = false;
    }
  }

  Future<void> exportWorkUpdatesToCSV() async {
    isExporting.value = true;
    Get.rawSnackbar(
      title: 'Exporting Excel',
      message: 'Generating work updates spreadsheet...',
      backgroundColor: const Color(0xFF420093),
      showProgressIndicator: true,
      snackPosition: SnackPosition.BOTTOM,
    );

    try {
      final filteredRecords = _allAttendanceRecords.where((doc) {
        return isRecordInSelectedRange(doc.data());
      }).toList();

      final csvBuffer = StringBuffer();
      csvBuffer.writeln(
        'Date,Employee ID,Employee Name,Designation,Check-in Time,Check-out Time,Project Name,Task Details,Task Status',
      );

      for (var doc in filteredRecords) {
        final data = doc.data();
        final String userId = data['userId'] ?? '';
        final employee = allEmployees.firstWhereOrNull((e) => e.uid == userId);
        final String empId = employee?.id ?? data['employeeId'] ?? '';
        final String designation = employee?.designation ?? 'Staff';

        final String date = data['date'] ?? (data['dateKey'] ?? '');
        final String name = data['name'] ?? '';
        final String checkIn = data['checkIn'] ?? '--';
        final String checkOut = data['checkOut'] ?? '--';
        final String projectName = data['projectName'] ?? '--';
        final String taskDetails = (data['taskDetails'] ?? '--')
            .replaceAll('\n', ' ')
            .replaceAll(',', ';');
        final String taskStatus = data['taskStatus'] ?? '--';

        csvBuffer.writeln(
          '"$date","$empId","$name","$designation","$checkIn","$checkOut","$projectName","$taskDetails","$taskStatus"',
        );
      }

      final rangeLabel = selectedFilterRange.value.toLowerCase();
      final filename = 'work_updates_export_$rangeLabel.csv';
      csv_helper.saveCsvFile(csvBuffer.toString(), filename);

      Get.rawSnackbar(
        title: 'Success',
        message: kIsWeb
            ? 'Report download started successfully.'
            : 'Report exported to: $filename',
        backgroundColor: const Color(0xFF16A34A),
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 5),
      );
    } catch (e) {
      debugPrint("Error exporting to CSV: $e");
      Get.rawSnackbar(
        title: 'Export Error',
        message: e.toString(),
        backgroundColor: Colors.red.shade700,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isExporting.value = false;
    }
  }

  Future<void> sendPasswordResetEmail() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null || user.email!.isEmpty) {
        Get.rawSnackbar(
          title: 'Error',
          message: 'No authenticated email address found.',
          backgroundColor: Colors.red.shade700,
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      await FirebaseAuth.instance.sendPasswordResetEmail(email: user.email!);

      Get.defaultDialog(
        title: 'Reset Link Sent',
        titleStyle: GoogleFonts.inter(
          fontWeight: FontWeight.bold,
          fontSize: 18.sp,
        ),
        contentPadding: EdgeInsets.all(16.w),
        middleText:
            'A secure password recovery link has been sent to:\n${user.email}\n\nPlease check your inbox to reset your password.',
        middleTextStyle: GoogleFonts.inter(
          fontSize: 13.sp,
          color: const Color(0xFF4A4453),
        ),
        textConfirm: 'OK',
        confirmTextColor: Colors.white,
        buttonColor: const Color(0xFF420093),
        onConfirm: () => Get.back(),
      );
    } catch (e) {
      Get.rawSnackbar(
        title: 'Reset Error',
        message: e.toString(),
        backgroundColor: Colors.red.shade700,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> refreshData() async {
    isLoadingEmployees.value = true;
    try {
      await _loadAdminData();

      // Cancel existing real-time stream subscriptions
      await _usersSubscription?.cancel();
      await _attendanceSubscription?.cancel();

      // Perform a manual one-time query to be absolutely sure
      await fetchEmployees();

      // Re-establish subscriptions
      listenToEmployees();
      listenToTodayAttendance();

      Get.rawSnackbar(
        title: 'Refreshed',
        message:
            'All employee profiles and attendance lists have been synchronized.',
        backgroundColor: const Color(0xFF16A34A),
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.rawSnackbar(
        title: 'Refresh Error',
        message: e.toString(),
        backgroundColor: Colors.red.shade700,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoadingEmployees.value = false;
    }
  }

  // --- Admin Leave Management Logic ---
  final RxList<Map<String, dynamic>> leaveRequests =
      <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> filteredLeaveRequests =
      <Map<String, dynamic>>[].obs;
  final RxString selectedLeaveStatusFilter =
      "pending".obs; // pending, approved, rejected, all
  final RxBool isLoadingLeaves = false.obs;
  StreamSubscription? _leavesSubscription;

  void _listenToLeaveRequests() {
    try {
      isLoadingLeaves.value = true;
      _leavesSubscription?.cancel();
      _leavesSubscription = FirebaseFirestore.instance
          .collection('leave_requests')
          .snapshots()
          .listen(
            (snapshot) {
              final List<Map<String, dynamic>> list = [];
              for (var doc in snapshot.docs) {
                final data = doc.data();
                list.add({
                  'id': doc.id,
                  'userId': data['userId'] ?? '',
                  'employeeName': data['employeeName'] ?? 'Employee',
                  'employeeId': data['employeeId'] ?? 'EMP-000',
                  'designation': data['designation'] ?? 'Staff Member',
                  'leaveType': data['leaveType'] ?? 'Annual Leave',
                  'startDate': data['startDate'] ?? '',
                  'endDate': data['endDate'] ?? '',
                  'reason': data['reason'] ?? '',
                  'status': data['status'] ?? 'pending',
                  'requestedAt': data['requestedAt'],
                  'rejectionReason': data['rejectionReason'] ?? '',
                });
              }

              // Sort by requestedAt descending
              list.sort((a, b) {
                final tsA =
                    (a['requestedAt'] as Timestamp?)?.millisecondsSinceEpoch ??
                    0;
                final tsB =
                    (b['requestedAt'] as Timestamp?)?.millisecondsSinceEpoch ??
                    0;
                return tsB.compareTo(tsA);
              });

              leaveRequests.assignAll(list);
              applyLeaveFilters();
              isLoadingLeaves.value = false;
            },
            onError: (e) {
              debugPrint("Error listening to leave requests: $e");
              isLoadingLeaves.value = false;
            },
          );
    } catch (e) {
      debugPrint("Error setting up leaves listener: $e");
      isLoadingLeaves.value = false;
    }
  }

  void filterLeaves(String status) {
    selectedLeaveStatusFilter.value = status;
    applyLeaveFilters();
  }

  void applyLeaveFilters() {
    final filter = selectedLeaveStatusFilter.value.toLowerCase();
    if (filter == 'all') {
      filteredLeaveRequests.assignAll(leaveRequests);
    } else {
      filteredLeaveRequests.assignAll(
        leaveRequests
            .where((r) => (r['status'] as String).toLowerCase() == filter)
            .toList(),
      );
    }
  }

  Future<void> updateLeaveStatus(
    String docId,
    String employeeUid,
    String status, {
    String? rejectionReason,
  }) async {
    try {
      final updates = <String, dynamic>{
        'status': status,
        'processedAt': FieldValue.serverTimestamp(),
        'processedBy': FirebaseAuth.instance.currentUser?.uid,
        'processedByName': adminName.value,
      };

      if (rejectionReason != null && rejectionReason.trim().isNotEmpty) {
        updates['rejectionReason'] = rejectionReason.trim();
      }

      await FirebaseFirestore.instance
          .collection('leave_requests')
          .doc(docId)
          .update(updates);

      // Send push notification back to the employee
      try {
        final request = leaveRequests.firstWhereOrNull((r) => r['id'] == docId);
        final leaveType = request?['leaveType'] ?? 'Leave';
        final statusLabel = status == 'approved' ? 'Approved' : 'Rejected';
        var msg = 'Your request for $leaveType has been $statusLabel.';
        if (status == 'rejected' &&
            rejectionReason != null &&
            rejectionReason.isNotEmpty) {
          msg += ' Reason: $rejectionReason';
        }

        await Get.find<NotificationService>().sendNotification(
          targetUid: employeeUid,
          title: 'Leave Status Updated',
          body: msg,
          type: status == 'approved' ? 'leave_approved' : 'leave_rejected',
        );
      } catch (e) {
        debugPrint("Error sending leave response push notification: $e");
      }

      Get.rawSnackbar(
        title: 'Status Updated',
        message: 'Leave request was successfully $status.',
        backgroundColor: Colors.green.shade700,
      );
    } catch (e) {
      debugPrint("Error updating leave request: $e");
      Get.rawSnackbar(
        title: 'Error',
        message: 'Failed to update leave request status.',
        backgroundColor: Colors.red.shade700,
      );
    }
  }

  void toggleEmployeeSelection(String uid) {
    if (reportSelectedEmployeeUids.contains(uid)) {
      reportSelectedEmployeeUids.remove(uid);
    } else {
      reportSelectedEmployeeUids.add(uid);
    }
    calculateCustomReportPreview();
  }

  void selectAllEmployees(bool select) {
    if (select) {
      reportSelectedEmployeeUids.assignAll(
        allEmployees.map((e) => e.uid).toList(),
      );
    } else {
      reportSelectedEmployeeUids.clear();
    }
    calculateCustomReportPreview();
  }

  void calculateCustomReportPreview() {
    DateTime startDate;
    DateTime endDate;

    if (reportRangeType.value == 'Month') {
      final year = reportSelectedMonth.value.year;
      final month = reportSelectedMonth.value.month;
      startDate = DateTime(year, month, 1);
      endDate = DateTime(year, month + 1, 0); // last day of month
    } else {
      if (reportSelectedDateRange.value == null) {
        startDate = DateTime.now();
        endDate = DateTime.now();
      } else {
        startDate = reportSelectedDateRange.value!.start;
        endDate = reportSelectedDateRange.value!.end;
      }
    }

    startDate = DateTime(startDate.year, startDate.month, startDate.day);
    endDate = DateTime(endDate.year, endDate.month, endDate.day);

    final List<DateTime> dates = [];
    var curr = endDate;
    while (curr.isAfter(startDate) || curr.isAtSameMomentAs(startDate)) {
      dates.add(curr);
      curr = DateTime(curr.year, curr.month, curr.day - 1);
    }

    final Map<String, Map<String, dynamic>> recordLookup = {};
    for (var doc in _allAttendanceRecords) {
      final data = doc.data();
      final userId = data['userId'] as String?;
      final dateKey = data['dateKey'] as String?;
      if (userId != null && dateKey != null) {
        recordLookup['${userId}_$dateKey'] = data;
      }
    }

    final List<Map<String, dynamic>> rows = [];
    for (final date in dates) {
      final String dateKey = DateFormat('yyyy-MM-dd').format(date);
      final String readableDate = DateFormat('MMM dd, yyyy').format(date);

      final holiday = holidays.firstWhereOrNull((h) => h.isSameDay(date));
      final bool isSun = date.weekday == DateTime.sunday;
      final bool is2ndSat =
          date.weekday == DateTime.saturday && date.day >= 8 && date.day <= 14;
      final bool isRedDate = holiday != null || isSun || is2ndSat;
      String specialLabel = '';
      if (holiday != null) {
        specialLabel = holiday.title;
      } else if (isSun) {
        specialLabel = 'Sunday';
      } else if (is2ndSat) {
        specialLabel = '2nd Saturday';
      }

      for (final empUid in reportSelectedEmployeeUids) {
        final emp = allEmployees.firstWhereOrNull((e) => e.uid == empUid);
        if (emp == null) continue;

        final record = recordLookup['${emp.uid}_$dateKey'];
        if (record == null) {
          if (isRedDate) {
            rows.add({
              'uid': emp.uid,
              'name': emp.name,
              'employeeId': emp.id,
              'designation': emp.designation,
              'date': readableDate,
              'checkIn': '--',
              'checkOut': '--',
              'workedHours': '--',
              'location': '--',
              'projectName': specialLabel,
              'taskStatus': holiday != null ? holiday.type : 'Weekend',
              'status': specialLabel,
              'isHoliday': true,
            });
          } else {
            rows.add({
              'uid': emp.uid,
              'name': emp.name,
              'employeeId': emp.id,
              'designation': emp.designation,
              'date': readableDate,
              'checkIn': '--',
              'checkOut': '--',
              'workedHours': '--',
              'location': '--',
              'projectName': '--',
              'taskStatus': '--',
              'status': 'Absent',
              'isHoliday': false,
            });
          }
        } else {
          final checkIn = record['checkIn'] as String? ?? '--';
          final checkOut = record['checkOut'] as String? ?? '--';
          final workedHours = record['workedHours'] as String? ?? '--';
          final location = record['location'] as String? ?? 'Office';
          final projectName = record['projectName'] as String? ?? '--';
          final taskStatus = record['taskStatus'] as String? ?? '--';
          final late = _checkIsLate(checkIn);
          String status;
          if (location == 'WFH') {
            status = 'WFH';
          } else if (late) {
            status = 'Late';
          } else {
            status = 'Present';
          }

          rows.add({
            'uid': emp.uid,
            'name': emp.name,
            'employeeId': emp.id,
            'designation': emp.designation,
            'date': record['date'] ?? readableDate,
            'checkIn': checkIn,
            'checkOut': checkOut,
            'workedHours': workedHours,
            'location': location,
            'projectName': isRedDate
                ? '$specialLabel / $projectName'
                : projectName,
            'taskStatus': isRedDate
                ? '${holiday != null ? holiday.type : 'Weekend'} / $taskStatus'
                : taskStatus,
            'status': isRedDate ? '$specialLabel ($status)' : status,
            'isHoliday': isRedDate,
          });
        }
      }
    }

    customReportPreviewRows.assignAll(rows);
  }

  Future<void> exportCustomReportToExcel() async {
    if (reportSelectedEmployeeUids.isEmpty) {
      Get.rawSnackbar(
        title: 'Selection Empty',
        message: 'Please select at least one employee to export.',
        backgroundColor: Colors.amber.shade700,
      );
      return;
    }

    isExporting.value = true;
    Get.rawSnackbar(
      title: 'Exporting Report',
      message: 'Generating custom Excel report with holiday highlights...',
      backgroundColor: const Color(0xFF420093),
      showProgressIndicator: true,
      snackPosition: SnackPosition.BOTTOM,
    );

    try {
      final excel = Excel.createExcel();
      excel.rename('Sheet1', 'Summary');
      final summarySheet = excel['Summary'];

      summarySheet.appendRow([
        TextCellValue('Employee ID'),
        TextCellValue('Employee Name'),
        TextCellValue('Designation'),
        TextCellValue('Present Days'),
        TextCellValue('WFH Days'),
        TextCellValue('Late Days'),
        TextCellValue('Absent Days'),
        TextCellValue('Holidays & Weekends'),
        TextCellValue('Total Worked Hours'),
      ]);

      // Apply beautiful header style to Summary sheet
      final summaryHeaderStyle = CellStyle(
        backgroundColorHex: ExcelColor.fromHexString('#2563EB'), // Vibrant blue
        fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
        bold: true,
        fontSize: 11,
      );
      for (int i = 0; i < 9; i++) {
        final cell = summarySheet.cell(
          CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
        );
        cell.cellStyle = summaryHeaderStyle;
      }

      // Set column widths for Summary sheet
      summarySheet.setColumnWidth(0, 16.0);
      summarySheet.setColumnWidth(1, 24.0);
      summarySheet.setColumnWidth(2, 20.0);
      summarySheet.setColumnWidth(3, 14.0);
      summarySheet.setColumnWidth(4, 14.0);
      summarySheet.setColumnWidth(5, 14.0);
      summarySheet.setColumnWidth(6, 14.0);
      summarySheet.setColumnWidth(7, 22.0); // wider for "Holidays & Weekends"
      summarySheet.setColumnWidth(8, 20.0);

      DateTime startDate;
      DateTime endDate;

      if (reportRangeType.value == 'Month') {
        final year = reportSelectedMonth.value.year;
        final month = reportSelectedMonth.value.month;
        startDate = DateTime(year, month, 1);
        endDate = DateTime(year, month + 1, 0);
      } else {
        if (reportSelectedDateRange.value == null) {
          startDate = DateTime.now();
          endDate = DateTime.now();
        } else {
          startDate = reportSelectedDateRange.value!.start;
          endDate = reportSelectedDateRange.value!.end;
        }
      }

      startDate = DateTime(startDate.year, startDate.month, startDate.day);
      endDate = DateTime(endDate.year, endDate.month, endDate.day);

      final List<DateTime> dateList = [];
      var curr = startDate;
      while (curr.isBefore(endDate) || curr.isAtSameMomentAs(endDate)) {
        dateList.add(curr);
        curr = DateTime(curr.year, curr.month, curr.day + 1);
      }

      final Map<String, Map<String, dynamic>> recordLookup = {};
      for (var doc in _allAttendanceRecords) {
        final data = doc.data();
        final userId = data['userId'] as String?;
        final dateKey = data['dateKey'] as String?;
        if (userId != null && dateKey != null) {
          recordLookup['${userId}_$dateKey'] = data;
        }
      }

      final empHeaderStyle = CellStyle(
        backgroundColorHex: ExcelColor.fromHexString(
          '#4F46E5',
        ), // Vibrant indigo
        fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
        bold: true,
        fontSize: 11,
      );

      for (final empUid in reportSelectedEmployeeUids) {
        final emp = allEmployees.firstWhereOrNull((e) => e.uid == empUid);
        if (emp == null) continue;

        int presentCount = 0;
        int wfhCount = 0;
        int lateCount = 0;
        int absentCount = 0;
        int holidayCount = 0;
        double totalHours = 0.0;

        final String sheetName = emp.name.length > 30
            ? emp.name.substring(0, 30)
            : emp.name;
        final empSheet = excel[sheetName];

        empSheet.appendRow([
          TextCellValue('Date'),
          TextCellValue('Check-In'),
          TextCellValue('Check-Out'),
          TextCellValue('Worked Hours'),
          TextCellValue('Location'),
          TextCellValue('Status'),
          TextCellValue('Project Name'),
          TextCellValue('Task Details'),
          TextCellValue('Task Status'),
        ]);

        // Style header row of employee sheet
        for (int i = 0; i < 9; i++) {
          final cell = empSheet.cell(
            CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
          );
          cell.cellStyle = empHeaderStyle;
        }

        // Set column widths for employee sheet
        empSheet.setColumnWidth(0, 18.0);
        empSheet.setColumnWidth(1, 12.0);
        empSheet.setColumnWidth(2, 12.0);
        empSheet.setColumnWidth(3, 15.0);
        empSheet.setColumnWidth(4, 12.0);
        empSheet.setColumnWidth(5, 24.0);
        empSheet.setColumnWidth(6, 32.0);
        empSheet.setColumnWidth(7, 40.0); // Wide for task details
        empSheet.setColumnWidth(8, 28.0);

        for (final date in dateList) {
          final String dateKey = DateFormat('yyyy-MM-dd').format(date);
          final String readableDate = DateFormat('MMM dd, yyyy').format(date);
          final holiday = holidays.firstWhereOrNull((h) => h.isSameDay(date));
          final record = recordLookup['${emp.uid}_$dateKey'];

          final bool isSun = date.weekday == DateTime.sunday;
          final bool is2ndSat =
              date.weekday == DateTime.saturday &&
              date.day >= 8 &&
              date.day <= 14;
          final bool isRedDate = holiday != null || isSun || is2ndSat;
          String specialLabel = '';
          if (holiday != null) {
            specialLabel = holiday.title;
          } else if (isSun) {
            specialLabel = 'Sunday';
          } else if (is2ndSat) {
            specialLabel = '2nd Saturday';
          }

          String checkIn = '--';
          String checkOut = '--';
          String workedHours = '--';
          String location = '--';
          String projectName = '--';
          String taskDetails = '--';
          String taskStatus = '--';
          String status = 'Absent';

          if (record != null) {
            checkIn = record['checkIn'] as String? ?? '--';
            checkOut = record['checkOut'] as String? ?? '--';
            workedHours = record['workedHours'] as String? ?? '--';
            location = record['location'] as String? ?? 'Office';

            // Extract multiple work updates if present
            final List<dynamic>? rawUpdates =
                record['workUpdates'] as List<dynamic>?;
            final List<Map<String, dynamic>> subUpdates = [];
            if (rawUpdates != null && rawUpdates.isNotEmpty) {
              for (var item in rawUpdates) {
                if (item is Map) {
                  subUpdates.add({
                    'projectName': item['projectName'] ?? '--',
                    'taskTitle': item['taskTitle'] ?? '--',
                    'taskDetails': item['taskDetails'] ?? '--',
                    'taskStatus': item['taskStatus'] ?? 'In Progress',
                    'startTime': item['startTime'] ?? '',
                    'endTime': item['endTime'] ?? '',
                    'progressPercentage': item['progressPercentage'] ?? 0.0,
                  });
                }
              }
            }

            if (subUpdates.isNotEmpty) {
              final List<String> projects = subUpdates
                  .map((e) => e['projectName'].toString())
                  .where((p) => p.isNotEmpty && p != '--')
                  .toSet()
                  .toList();
              projectName = projects.isNotEmpty ? projects.join(', ') : '--';

              final List<String> detailsList = [];
              for (var i = 0; i < subUpdates.length; i++) {
                final upd = subUpdates[i];
                final pName = upd['projectName'];
                final tTitle = upd['taskTitle'];
                final tDet = upd['taskDetails'];
                final sTime = upd['startTime'];
                final eTime = upd['endTime'];
                final progress = upd['progressPercentage'];

                String timeStr = '';
                if (sTime.toString().isNotEmpty &&
                    eTime.toString().isNotEmpty) {
                  timeStr = ' ($sTime - $eTime)';
                }

                String progressStr = '';
                if (progress != null && progress > 0) {
                  progressStr = ' [Progress: ${progress.toString()}%]';
                }

                detailsList.add(
                  '${i + 1}. [$pName] $tTitle: $tDet$timeStr$progressStr',
                );
              }
              taskDetails = detailsList.join('\n');

              final List<String> statusList = [];
              for (var upd in subUpdates) {
                final pName = upd['projectName'];
                final tTitle = upd['taskTitle'];
                final tStatus = upd['taskStatus'];
                statusList.add('[$pName] $tTitle: $tStatus');
              }
              taskStatus = statusList.join(', ');
            } else {
              projectName = record['projectName'] as String? ?? '--';
              taskDetails = record['taskDetails'] as String? ?? '--';
              taskStatus = record['taskStatus'] as String? ?? '--';
            }

            final late = _checkIsLate(checkIn);
            if (location == 'WFH') {
              status = 'WFH';
              wfhCount++;
            } else if (late) {
              status = 'Late';
              lateCount++;
            } else {
              status = 'Present';
              presentCount++;
            }

            if (workedHours.isNotEmpty && workedHours != '--') {
              final sanitizedWh = workedHours
                  .replaceAll(' hrs', '')
                  .replaceAll(' hr', '')
                  .trim();
              totalHours += double.tryParse(sanitizedWh) ?? 0.0;
            }

            if (isRedDate) {
              holidayCount++;
              status = '$specialLabel ($status)';
              projectName = '$specialLabel / $projectName';
              taskDetails = '$specialLabel / $taskDetails';
              taskStatus =
                  '${holiday != null ? holiday.type : 'Weekend'} / $taskStatus';
            }
          } else {
            if (isRedDate) {
              holidayCount++;
              status = specialLabel;
              projectName = specialLabel;
              taskDetails = specialLabel;
              taskStatus = holiday != null ? holiday.type : 'Weekend';
            } else {
              absentCount++;
            }
          }

          empSheet.appendRow([
            TextCellValue(readableDate),
            TextCellValue(checkIn),
            TextCellValue(checkOut),
            TextCellValue(workedHours),
            TextCellValue(location),
            TextCellValue(status),
            TextCellValue(projectName),
            TextCellValue(taskDetails),
            TextCellValue(taskStatus),
          ]);

          if (isRedDate) {
            final int rowIndex = empSheet.maxRows - 1;
            for (int colIndex = 0; colIndex < 9; colIndex++) {
              final cell = empSheet.cell(
                CellIndex.indexByColumnRow(
                  columnIndex: colIndex,
                  rowIndex: rowIndex,
                ),
              );
              cell.cellStyle = CellStyle(
                backgroundColorHex: ExcelColor.fromHexString('#FFCDD2'),
                fontColorHex: ExcelColor.fromHexString('#B71C1C'),
              );
            }
          } else {
            // Apply text colors to status cells in the employee worksheet
            final int rowIndex = empSheet.maxRows - 1;
            final cell = empSheet.cell(
              CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex),
            );

            if (status == 'Present') {
              cell.cellStyle = CellStyle(
                fontColorHex: ExcelColor.fromHexString('#1B5E20'), // Dark Green
                bold: true,
              );
            } else if (status == 'Late') {
              cell.cellStyle = CellStyle(
                fontColorHex: ExcelColor.fromHexString(
                  '#E65100',
                ), // Dark Orange
                bold: true,
              );
            } else if (status == 'Absent') {
              cell.cellStyle = CellStyle(
                fontColorHex: ExcelColor.fromHexString('#B71C1C'), // Dark Red
                bold: true,
              );
            } else if (status == 'WFH') {
              cell.cellStyle = CellStyle(
                fontColorHex: ExcelColor.fromHexString('#0D47A1'), // Dark Blue
                bold: true,
              );
            }
          }
        }

        // Append an empty row for spacing
        empSheet.appendRow([]);

        // Append Late Days Total Row
        empSheet.appendRow([
          TextCellValue(''),
          TextCellValue(''),
          TextCellValue(''),
          TextCellValue(''),
          TextCellValue(''),
          TextCellValue(''),
          TextCellValue(''),
          TextCellValue('Total Late Days:'),
          IntCellValue(lateCount),
        ]);

        final lateRowIdx = empSheet.maxRows - 1;
        final lateLabelCell = empSheet.cell(
          CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: lateRowIdx),
        );
        final lateValueCell = empSheet.cell(
          CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: lateRowIdx),
        );

        final lateTotalStyle = CellStyle(
          backgroundColorHex: ExcelColor.fromHexString('#FFF3E0'),
          fontColorHex: ExcelColor.fromHexString('#E65100'),
          bold: true,
          fontSize: 12,
        );
        lateLabelCell.cellStyle = lateTotalStyle;
        lateValueCell.cellStyle = lateTotalStyle;

        // Append Absent Days Total Row
        empSheet.appendRow([
          TextCellValue(''),
          TextCellValue(''),
          TextCellValue(''),
          TextCellValue(''),
          TextCellValue(''),
          TextCellValue(''),
          TextCellValue(''),
          TextCellValue('Total Absent Days (excl. Holidays):'),
          IntCellValue(absentCount),
        ]);

        final absentRowIdx = empSheet.maxRows - 1;
        final absentLabelCell = empSheet.cell(
          CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: absentRowIdx),
        );
        final absentValueCell = empSheet.cell(
          CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: absentRowIdx),
        );

        final absentTotalStyle = CellStyle(
          backgroundColorHex: ExcelColor.fromHexString('#FFEBEE'),
          fontColorHex: ExcelColor.fromHexString('#C62828'),
          bold: true,
          fontSize: 12,
        );
        absentLabelCell.cellStyle = absentTotalStyle;
        absentValueCell.cellStyle = absentTotalStyle;

        summarySheet.appendRow([
          TextCellValue(emp.id),
          TextCellValue(emp.name),
          TextCellValue(emp.designation),
          IntCellValue(presentCount),
          IntCellValue(wfhCount),
          IntCellValue(lateCount),
          IntCellValue(absentCount),
          IntCellValue(holidayCount),
          TextCellValue('${totalHours.toStringAsFixed(1)} hrs'),
        ]);

        // Style the numeric metrics columns in the Summary sheet row dynamically
        final int summaryRowIndex = summarySheet.maxRows - 1;
        // Present Days
        summarySheet
            .cell(
              CellIndex.indexByColumnRow(
                columnIndex: 3,
                rowIndex: summaryRowIndex,
              ),
            )
            .cellStyle = CellStyle(
          fontColorHex: ExcelColor.fromHexString('#1B5E20'),
          bold: true,
        );
        // WFH Days
        summarySheet
            .cell(
              CellIndex.indexByColumnRow(
                columnIndex: 4,
                rowIndex: summaryRowIndex,
              ),
            )
            .cellStyle = CellStyle(
          fontColorHex: ExcelColor.fromHexString('#0D47A1'),
          bold: true,
        );
        // Late Days
        summarySheet
            .cell(
              CellIndex.indexByColumnRow(
                columnIndex: 5,
                rowIndex: summaryRowIndex,
              ),
            )
            .cellStyle = CellStyle(
          fontColorHex: ExcelColor.fromHexString('#E65100'),
          bold: true,
        );
        // Absent Days
        summarySheet
            .cell(
              CellIndex.indexByColumnRow(
                columnIndex: 6,
                rowIndex: summaryRowIndex,
              ),
            )
            .cellStyle = CellStyle(
          fontColorHex: ExcelColor.fromHexString('#B71C1C'),
          bold: true,
        );
        // Holidays & Weekends
        summarySheet
            .cell(
              CellIndex.indexByColumnRow(
                columnIndex: 7,
                rowIndex: summaryRowIndex,
              ),
            )
            .cellStyle = CellStyle(
          fontColorHex: ExcelColor.fromHexString('#7B1FA2'), // Purple
          bold: true,
        );
      }

      final fileBytes = excel.save();
      if (fileBytes != null) {
        String rangeLabel;
        if (reportRangeType.value == 'Month') {
          rangeLabel = DateFormat(
            'MMMM_yyyy',
          ).format(reportSelectedMonth.value);
        } else {
          final startStr = DateFormat('yyyy-MM-dd').format(startDate);
          final endStr = DateFormat('yyyy-MM-dd').format(endDate);
          rangeLabel = '${startStr}_to_$endStr';
        }
        final filename = 'attendance_report_$rangeLabel.xlsx';
        excel_helper.saveExcelFile(fileBytes, filename);

        Get.rawSnackbar(
          title: 'Excel Export Complete ✓',
          message: kIsWeb
              ? 'Spreadsheet download started.'
              : 'Report saved as $filename',
          backgroundColor: const Color(0xFF16A34A),
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 5),
        );
      }
    } catch (e, stack) {
      debugPrint('Error exporting Custom Report Excel: $e\n$stack');
      Get.rawSnackbar(
        title: 'Export Error',
        message: e.toString(),
        backgroundColor: Colors.red.shade700,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isExporting.value = false;
    }
  }
}
