import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stepz_attendance/core/utils/device_id_helper.dart';

class SplashController extends GetxController {
  final RxDouble progress = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    _startProgressAnimation();
  }

  void _startProgressAnimation() async {
    // Simulate loading progress over 2.5 seconds
    const steps = 50;
    const stepDuration = Duration(milliseconds: 50); // 50 * 50 = 2500ms
    
    for (int i = 1; i <= steps; i++) {
      await Future.delayed(stepDuration);
      progress.value = i / steps;
    }
    
    await _checkUserSession();
  }

  Future<void> _checkUserSession() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        Get.offAllNamed('/login');
        return;
      }

      // Retrieve Firestore document to determine role and device binding status
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (!doc.exists || doc.data() == null) {
        // Sign out if employee document no longer exists
        await FirebaseAuth.instance.signOut();
        Get.offAllNamed('/login');
        return;
      }

      final data = doc.data()!;
      final String role = data['role'] ?? 'employee';

      if (role == 'admin') {
        Get.offAllNamed('/admin/dashboard');
        return;
      }

      // Enforce device binding check for employees
      final currentDeviceId = await DeviceIdHelper.getDeviceId();
      final String? boundDeviceId = data['deviceId'];

      if (boundDeviceId == null || boundDeviceId.trim().isEmpty) {
        // Device binding reset by admin: force logout
        await FirebaseAuth.instance.signOut();
        Get.offAllNamed('/login');
        
        Get.defaultDialog(
          title: 'Device Reset',
          middleText: 'Your device binding has been reset by the administrator. Please log in again to register your device.',
          textConfirm: 'OK',
          confirmTextColor: Colors.white,
          buttonColor: const Color(0xFF420093),
          onConfirm: () => Get.back(),
        );
      } else if (boundDeviceId == currentDeviceId) {
        // Bound device matches current device
        Get.offAllNamed('/employee/dashboard');
      } else {
        // Mismatch: sign out user and redirect to login with error
        await FirebaseAuth.instance.signOut();
        Get.offAllNamed('/login');
        
        Get.defaultDialog(
          title: 'Access Blocked',
          middleText: 'This account is registered on another device. Please contact admin to change your phone.',
          textConfirm: 'OK',
          confirmTextColor: Colors.white,
          buttonColor: const Color(0xFFBA1A1A),
          onConfirm: () => Get.back(),
        );
      }
    } catch (e) {
      debugPrint("Error checking splash user session: $e");
      Get.offAllNamed('/login');
    }
  }
}

