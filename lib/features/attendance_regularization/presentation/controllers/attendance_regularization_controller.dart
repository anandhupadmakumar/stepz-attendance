import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:stepz_attendance/core/services/notification_service.dart';
import 'package:stepz_attendance/features/employee/presentation/controllers/employee_dashboard_controller.dart';

class AttendanceRegularizationController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Form fields
  final Rxn<DateTime> selectedDate = Rxn<DateTime>();
  final RxString originalCheckIn = ''.obs;
  final Rxn<TimeOfDay> requestedCheckOut = Rxn<TimeOfDay>();
  final RxString selectedReason = 'Forgot to Checkout'.obs;
  final workSummaryController = TextEditingController();

  final RxBool isSubmitting = false.obs;
  final RxString attendanceDocId = ''.obs;

  // Selected date's details from database if any
  final RxString dbCheckIn = '--'.obs;
  final RxString dbCheckOut = '--'.obs;

  final List<String> reasons = [
    'Forgot to Checkout',
    'Application Closed',
    'Network Issue',
    'Battery Drained',
    'Emergency Leave',
    'Other',
  ];

  @override
  void onInit() {
    super.onInit();
    // Check if passed from dashboard banner
    if (Get.arguments != null && Get.arguments['missedPunch'] != null) {
      final missed = Get.arguments['missedPunch'] as Map<String, dynamic>;
      final dateKeyStr = missed['dateKey'] as String;
      try {
        selectedDate.value = DateFormat('yyyy-MM-dd').parse(dateKeyStr);
        originalCheckIn.value = missed['checkIn'] as String;
        attendanceDocId.value = missed['docId'] as String;
        dbCheckIn.value = missed['checkIn'] as String;
        dbCheckOut.value = '--';
      } catch (e) {
        debugPrint('Error parsing missed punch date: $e');
      }
    }
  }

  @override
  void onClose() {
    workSummaryController.dispose();
    super.onClose();
  }

  // Set date and search for existing attendance record
  Future<void> setDate(DateTime date) async {
    selectedDate.value = date;
    originalCheckIn.value = '';
    attendanceDocId.value = '';
    dbCheckIn.value = '--';
    dbCheckOut.value = '--';

    final user = _auth.currentUser;
    if (user == null) return;

    final dateKeyStr = DateFormat('yyyy-MM-dd').format(date);
    try {
      final snapshot = await _firestore
          .collection('attendance')
          .where('userId', isEqualTo: user.uid)
          .get();

      final matchingDocs = snapshot.docs.where((doc) {
        return doc.data()['dateKey'] == dateKeyStr;
      }).toList();

      if (matchingDocs.isNotEmpty) {
        final data = matchingDocs.first.data();
        attendanceDocId.value = matchingDocs.first.id;
        dbCheckIn.value = data['checkIn'] as String? ?? '--';
        dbCheckOut.value = data['checkOut'] as String? ?? '--';
        originalCheckIn.value = dbCheckIn.value;
      }
    } catch (e) {
      debugPrint('Error fetching attendance for date: $e');
    }
  }

  void setRequestedCheckOut(TimeOfDay time) {
    requestedCheckOut.value = time;
  }

  void setReason(String reason) {
    selectedReason.value = reason;
  }

  Future<void> submitRequest() async {
    if (selectedDate.value == null) {
      Get.rawSnackbar(
        title: 'Validation Error',
        message: 'Please select a date.',
        backgroundColor: Colors.red.shade700,
      );
      return;
    }

    if (dbCheckIn.value == '--') {
      Get.rawSnackbar(
        title: 'No Punch-In Record',
        message: 'There is no attendance record with a Check-In for this date.',
        backgroundColor: Colors.red.shade700,
      );
      return;
    }

    if (dbCheckOut.value != '--') {
      Get.rawSnackbar(
        title: 'Already Checked Out',
        message: 'You have already checked out on this date. Regularization is not required.',
        backgroundColor: Colors.red.shade700,
      );
      return;
    }

    if (requestedCheckOut.value == null) {
      Get.rawSnackbar(
        title: 'Validation Error',
        message: 'Please select a requested check-out time.',
        backgroundColor: Colors.red.shade700,
      );
      return;
    }

    if (workSummaryController.text.trim().isEmpty) {
      Get.rawSnackbar(
        title: 'Validation Error',
        message: 'Please provide a summary of work completed.',
        backgroundColor: Colors.red.shade700,
      );
      return;
    }

    isSubmitting.value = true;

    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final employeeCtrl = Get.find<EmployeeDashboardController>();

      // Check if a request already exists for this date and is not rejected
      final existingRequests = employeeCtrl.regularizationRequests;
      final dateKeyStr = DateFormat('yyyy-MM-dd').format(selectedDate.value!);
      final hasActiveRequest = existingRequests.any((req) =>
          req['attendanceDate'] == dateKeyStr &&
          (req['status'] == 'pending' || req['status'] == 'approved'));

      if (hasActiveRequest) {
        Get.rawSnackbar(
          title: 'Duplicate Request',
          message: 'A regularization request is already pending or approved for this date.',
          backgroundColor: Colors.red.shade700,
        );
        return;
      }

      final formattedDate = DateFormat('MMM dd, yyyy').format(selectedDate.value!);
      final formattedCheckOut = formatTimeOfDay(requestedCheckOut.value!);

      final requestData = {
        'employeeId': user.uid,
        'employeeName': employeeCtrl.employeeName.value,
        'employeeEmail': employeeCtrl.employeeEmail.value,
        'designation': employeeCtrl.employeeDesignation.value,
        'attendanceDocId': attendanceDocId.value,
        'attendanceDate': dateKeyStr,
        'attendanceDateFormatted': formattedDate,
        'checkIn': originalCheckIn.value,
        'requestedCheckOut': formattedCheckOut,
        'reason': selectedReason.value,
        'workSummary': workSummaryController.text.trim(),
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'adminRemarks': '',
        'processedAt': null,
        'approvedCheckIn': originalCheckIn.value,
        'approvedCheckOut': formattedCheckOut,
      };

      await _firestore.collection('attendance_regularization_requests').add(requestData);

      // Trigger notification to admin
      try {
        final pushBody = '${employeeCtrl.employeeName.value} submitted a checkout regularization request for $formattedDate';
        await Get.find<NotificationService>().sendNotification(
          targetRole: 'admin',
          title: 'New Regularization Request 📝',
          body: pushBody,
          type: 'regularization_request',
        );
      } catch (e) {
        debugPrint('Error sending regularization request notification: $e');
      }

      // Reset form
      selectedDate.value = null;
      originalCheckIn.value = '';
      requestedCheckOut.value = null;
      selectedReason.value = 'Forgot to Checkout';
      workSummaryController.clear();
      attendanceDocId.value = '';
      dbCheckIn.value = '--';
      dbCheckOut.value = '--';

      Get.back(); // Navigate back to list/dashboard
      Get.rawSnackbar(
        title: 'Success',
        message: 'Regularization request submitted successfully.',
        backgroundColor: Colors.green.shade700,
      );
    } catch (e) {
      debugPrint('Error submitting regularization request: $e');
      Get.rawSnackbar(
        title: 'Error',
        message: 'Failed to submit request: ${e.toString()}',
        backgroundColor: Colors.red.shade700,
      );
    } finally {
      isSubmitting.value = false;
    }
  }

  String formatTimeOfDay(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat('hh:mm a').format(dt);
  }
}
