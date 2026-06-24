import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:stepz_attendance/core/services/notification_service.dart';

class AdminAttendanceRequestsController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Streams of requests
  final RxList<Map<String, dynamic>> allRequests = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> pendingRequests = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> approvedRequests = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> rejectedRequests = <Map<String, dynamic>>[].obs;

  // Stats
  final RxInt pendingCount = 0.obs;
  final RxInt approvedTodayCount = 0.obs;
  final RxInt rejectedTodayCount = 0.obs;

  StreamSubscription? _requestsSubscription;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    _listenToRequests();
  }

  @override
  void onClose() {
    _requestsSubscription?.cancel();
    super.onClose();
  }

  void _listenToRequests() {
    isLoading.value = true;
    _requestsSubscription?.cancel();
    _requestsSubscription = _firestore
        .collection('attendance_regularization_requests')
        .snapshots()
        .listen((snapshot) {
          final List<Map<String, dynamic>> list = [];
          final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

          int pending = 0;
          int approvedToday = 0;
          int rejectedToday = 0;

          for (var doc in snapshot.docs) {
            final data = doc.data();
            final status = data['status'] as String? ?? 'pending';
            final id = doc.id;

            list.add({
              'id': id,
              ...data,
            });

            if (status == 'pending') {
              pending++;
            } else {
              // Check if processed today
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

          // Sort descending by createdAt
          list.sort((a, b) {
            final tsA = (a['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
            final tsB = (b['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
            return tsB.compareTo(tsA);
          });

          allRequests.assignAll(list);
          pendingRequests.assignAll(list.where((req) => req['status'] == 'pending').toList());
          approvedRequests.assignAll(list.where((req) => req['status'] == 'approved').toList());
          rejectedRequests.assignAll(list.where((req) => req['status'] == 'rejected').toList());

          pendingCount.value = pending;
          approvedTodayCount.value = approvedToday;
          rejectedTodayCount.value = rejectedToday;

          isLoading.value = false;
        }, onError: (e) {
          debugPrint('Error streaming regularization requests: $e');
          isLoading.value = false;
        });
  }

  // Calculate worked hours based on HH:MM AM/PM check-in and check-out
  String calculateWorkedHours(String checkIn, String checkOut) {
    try {
      final format = DateFormat('hh:mm a');
      final timeIn = format.parse(checkIn.trim().toUpperCase());
      final timeOut = format.parse(checkOut.trim().toUpperCase());
      
      Duration diff = timeOut.difference(timeIn);
      if (diff.isNegative) {
        // Handle shift cross midnight
        diff += const Duration(hours: 24);
      }
      final hours = diff.inHours;
      final minutes = diff.inMinutes.remainder(60);
      final seconds = diff.inSeconds.remainder(60);
      return '${hours.toString().padLeft(2, '0')}h ${minutes.toString().padLeft(2, '0')}m ${seconds.toString().padLeft(2, '0')}s';
    } catch (e) {
      debugPrint('Error calculating worked hours for $checkIn to $checkOut: $e');
      return '00h 00m 00s';
    }
  }

  // Approve request and update employee's attendance record
  Future<bool> approveRequest({
    required String requestId,
    required String employeeId,
    required String dateKey,
    required String checkIn,
    required String checkOut,
    required String remarks,
  }) async {
    try {
      final workedHours = calculateWorkedHours(checkIn, checkOut);

      // 1. Find corresponding attendance record
      final attendanceSnapshot = await _firestore
          .collection('attendance')
          .where('userId', isEqualTo: employeeId)
          .get();

      final matchingDocs = attendanceSnapshot.docs.where((doc) {
        return doc.data()['dateKey'] == dateKey;
      }).toList();

      if (matchingDocs.isEmpty) {
        Get.rawSnackbar(
          title: 'Error',
          message: 'Corresponding attendance log not found for this date.',
          backgroundColor: Colors.red.shade700,
        );
        return false;
      }

      final attendanceDocId = matchingDocs.first.id;

      // 2. Update attendance record
      await _firestore.collection('attendance').doc(attendanceDocId).update({
        'checkIn': checkIn,
        'checkOut': checkOut,
        'workedHours': workedHours,
        'regularized': true,
        'regularizedAt': FieldValue.serverTimestamp(),
      });

      // 3. Update regularization request status
      await _firestore
          .collection('attendance_regularization_requests')
          .doc(requestId)
          .update({
            'status': 'approved',
            'approvedCheckIn': checkIn,
            'approvedCheckOut': checkOut,
            'adminRemarks': remarks,
            'processedAt': FieldValue.serverTimestamp(),
          });

      // 4. Send notification to employee
      try {
        await Get.find<NotificationService>().sendNotification(
          targetUid: employeeId,
          title: 'Regularization Approved ✅',
          body: 'Your regularization request for $dateKey has been approved. Attendance record updated.',
          type: 'regularization_approved',
        );
      } catch (e) {
        debugPrint('Error sending approval notification: $e');
      }

      Get.rawSnackbar(
        title: 'Approved',
        message: 'Regularization approved and attendance updated.',
        backgroundColor: Colors.green.shade700,
      );
      return true;
    } catch (e) {
      debugPrint('Error approving regularization request: $e');
      Get.rawSnackbar(
        title: 'Error',
        message: 'Failed to approve: ${e.toString()}',
        backgroundColor: Colors.red.shade700,
      );
      return false;
    }
  }

  // Reject request
  Future<bool> rejectRequest({
    required String requestId,
    required String employeeId,
    required String dateKey,
    required String remarks,
  }) async {
    if (remarks.trim().isEmpty) {
      Get.rawSnackbar(
        title: 'Validation Error',
        message: 'Please provide rejection remarks/reason.',
        backgroundColor: Colors.red.shade700,
      );
      return false;
    }

    try {
      // 1. Update regularization request status
      await _firestore
          .collection('attendance_regularization_requests')
          .doc(requestId)
          .update({
            'status': 'rejected',
            'adminRemarks': remarks,
            'processedAt': FieldValue.serverTimestamp(),
          });

      // 2. Send notification to employee
      try {
        await Get.find<NotificationService>().sendNotification(
          targetUid: employeeId,
          title: 'Regularization Rejected ❌',
          body: 'Your regularization request for $dateKey was rejected. Reason: $remarks',
          type: 'regularization_rejected',
        );
      } catch (e) {
        debugPrint('Error sending rejection notification: $e');
      }

      Get.rawSnackbar(
        title: 'Rejected',
        message: 'Regularization request has been rejected.',
        backgroundColor: Colors.orange.shade700,
      );
      return true;
    } catch (e) {
      debugPrint('Error rejecting regularization request: $e');
      Get.rawSnackbar(
        title: 'Error',
        message: 'Failed to reject: ${e.toString()}',
        backgroundColor: Colors.red.shade700,
      );
      return false;
    }
  }
}
