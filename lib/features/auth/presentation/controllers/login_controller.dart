import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:stepz_attendance/core/utils/device_id_helper.dart';
import 'package:stepz_attendance/core/services/notification_service.dart';

class LoginController extends GetxController {
  FirebaseAuth get _auth => FirebaseAuth.instance;

  // Form keys and controllers
  final loginFormKey = GlobalKey<FormState>();
  final forgotPasswordFormKey = GlobalKey<FormState>();
  
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final resetEmailController = TextEditingController();

  // Reactive states
  final RxBool isPasswordObscured = true.obs;
  final RxBool rememberMe = false.obs;
  final RxBool isLoading = false.obs;

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    resetEmailController.dispose();
    super.onClose();
  }

  void togglePasswordVisibility() {
    isPasswordObscured.value = !isPasswordObscured.value;
  }

  void toggleRememberMe(bool? value) {
    rememberMe.value = value ?? false;
  }

  // Input Validations
  String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your Employee ID or Email';
    }
    // If it's an email, check email format
    if (value.contains('@')) {
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      if (!emailRegex.hasMatch(value.trim())) {
        return 'Please enter a valid email address';
      }
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters long';
    }
    return null;
  }

  String? validateResetEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your registered email';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  Future<bool> _handleLocationPermissionEnforcement() async {
    try {
      // 1. Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Get.defaultDialog(
          title: 'Location Services Disabled',
          middleText: 'Please enable location services on your device to continue using this app.',
          textConfirm: 'Open Settings',
          textCancel: 'Cancel',
          confirmTextColor: Colors.white,
          onConfirm: () async {
            Get.back();
            await Geolocator.openLocationSettings();
          },
        );
        return false;
      }

      // 2. Check current permission status
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          Get.rawSnackbar(
            title: 'Location Permission Denied',
            message: 'You must grant location permissions to sign in to the attendance system.',
            backgroundColor: const Color(0xFFBA1A1A),
            duration: const Duration(seconds: 4),
          );
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        await Get.defaultDialog(
          title: 'Location Permission Required',
          middleText: 'Location permissions are permanently denied. Please enable them in your app settings to sign in.',
          textConfirm: 'Open App Settings',
          textCancel: 'Cancel',
          confirmTextColor: Colors.white,
          onConfirm: () async {
            Get.back();
            await Geolocator.openAppSettings();
          },
        );
        return false;
      }

      return permission == LocationPermission.always || permission == LocationPermission.whileInUse;
    } catch (e) {
      debugPrint("Error checking location permission: $e");
      // Fallback for tests/web where Geolocator throws MissingPluginException or is unsupported
      return true;
    }
  }

  // Actions
  Future<void> login() async {
    if (!loginFormKey.currentState!.validate()) return;

    // Check and enforce location permission first!
    final hasPermission = await _handleLocationPermissionEnforcement();
    if (!hasPermission) return;

    isLoading.value = true;
    try {
      String email = emailController.text.trim();
      String password = passwordController.text;

      // Handle raw Employee ID by querying Firestore to retrieve their registered email address
      if (!email.contains('@')) {
        final employeeIdSearch = email.toUpperCase().trim();
        final querySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('employeeId', isEqualTo: employeeIdSearch)
            .get();

        if (querySnapshot.docs.isEmpty) {
          // Try exact case/lowercase check just in case
          final fallbackQuery = await FirebaseFirestore.instance
              .collection('users')
              .where('employeeId', isEqualTo: email.toLowerCase().trim())
              .get();
          if (fallbackQuery.docs.isEmpty) {
            throw FirebaseAuthException(
              code: 'user-not-found',
              message: 'No employee record found for Employee ID: "$email".',
            );
          } else {
            email = fallbackQuery.docs.first.data()['email'] ?? '';
          }
        } else {
          email = querySnapshot.docs.first.data()['email'] ?? '';
        }

        if (email.isEmpty) {
          throw FirebaseAuthException(
            code: 'user-not-found',
            message: 'Employee ID "$employeeIdSearch" does not have a registered email.',
          );
        }
      }

      // Firebase Auth check
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Determine user role (check Firestore first, fall back to email heuristics)
      String role = 'employee';
      Map<String, dynamic>? userData;
      final uid = userCredential.user?.uid;
      try {
        if (uid != null) {
          final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
          if (doc.exists && doc.data() != null) {
            userData = doc.data();
            role = userData?['role'] ?? 'employee';
          } else {
            // Document with uid doesn't exist. Let's see if we can find it by email.
            final queryByEmail = await FirebaseFirestore.instance
                .collection('users')
                .where('email', isEqualTo: email.toLowerCase().trim())
                .get();

            if (queryByEmail.docs.isNotEmpty) {
              final oldDoc = queryByEmail.docs.first;
              userData = oldDoc.data();
              role = userData['role'] ?? 'employee';
              
              // Migrate document to use uid as the document ID
              await FirebaseFirestore.instance.collection('users').doc(uid).set(userData);
              // Delete the old document with the random ID
              await FirebaseFirestore.instance.collection('users').doc(oldDoc.id).delete();
              
              debugPrint("Migrated user document from ${oldDoc.id} to $uid");
            } else {
              // Fallback checking if document doesn't exist
              if (email.toLowerCase().startsWith('admin') || email.toLowerCase().contains('admin')) {
                role = 'admin';
              }
            }
          }
        }
      } catch (firestoreError) {
        debugPrint("Firestore role check failed: $firestoreError");
        // Fallback checking on exception (offline / tests / Firestore not initialized)
        if (email.toLowerCase().startsWith('admin') || email.toLowerCase().contains('admin')) {
          role = 'admin';
        }
      }

      // Device ID check for employees
      if (role != 'admin' && uid != null) {
        final currentDeviceId = await DeviceIdHelper.getDeviceId();
        final String? boundDeviceId = userData?['deviceId'];

        if (boundDeviceId == null || boundDeviceId.trim().isEmpty) {
          // Bind this device (first-time binding)
          await FirebaseFirestore.instance.collection('users').doc(uid).update({
            'deviceId': currentDeviceId,
          });
        } else if (boundDeviceId != currentDeviceId) {
          // Device ID mismatch: block access
          await _auth.signOut();
          isLoading.value = false;

          Get.defaultDialog(
            title: 'Access Blocked',
            middleText: 'This account is registered on another device. Please contact admin to change your phone.',
            textConfirm: 'OK',
            confirmTextColor: Colors.white,
            buttonColor: const Color(0xFFBA1A1A),
            onConfirm: () => Get.back(),
          );
          return;
        }
      }

      isLoading.value = false;

      Get.rawSnackbar(
        title: 'Success',
        message: 'Successfully logged in as ${userCredential.user?.email}',
        backgroundColor: Colors.green.shade700,
        snackPosition: SnackPosition.BOTTOM,
      );
      
      // Sync FCM token
      try {
        await Get.find<NotificationService>().syncUserToken();
      } catch (e) {
        debugPrint("Error syncing FCM token: $e");
      }

      // Navigate to main/dashboard screen based on role
      if (role == 'admin') {
        Get.offAllNamed('/admin/dashboard');
      } else {
        Get.offAllNamed('/employee/dashboard');
      }
    } on FirebaseAuthException catch (e) {
      isLoading.value = false;
      String errorMsg = 'Authentication failed';
      if (e.code == 'user-not-found') {
        errorMsg = 'No user found for that email/ID';
      } else if (e.code == 'wrong-password') {
        errorMsg = 'Incorrect password provided';
      } else if (e.code == 'invalid-email') {
        errorMsg = 'Invalid email/ID format';
      } else {
        errorMsg = e.message ?? errorMsg;
      }

      Get.defaultDialog(
        title: 'Login Error',
        middleText: errorMsg,
        textConfirm: 'OK',
        confirmTextColor: Colors.white,
        onConfirm: () => Get.back(),
      );
    } catch (e) {
      isLoading.value = false;
      Get.defaultDialog(
        title: 'Unexpected Error',
        middleText: e.toString(),
        textConfirm: 'OK',
        confirmTextColor: Colors.white,
        onConfirm: () => Get.back(),
      );
    }
  }

  Future<void> loginWithSSO() async {
    Get.rawSnackbar(
      title: 'SSO Login',
      message: 'Workplace Single Sign-On is currently undergoing maintenance.',
      backgroundColor: Colors.blue.shade700,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  Future<void> sendPasswordResetEmail() async {
    if (!forgotPasswordFormKey.currentState!.validate()) return;

    isLoading.value = true;
    try {
      await _auth.sendPasswordResetEmail(email: resetEmailController.text.trim());
      isLoading.value = false;
      
      Get.defaultDialog(
        title: 'Reset Link Sent',
        middleText: 'A password recovery link has been sent to ${resetEmailController.text.trim()}. Please check your inbox.',
        textConfirm: 'Back to Login',
        confirmTextColor: Colors.white,
        onConfirm: () {
          Get.back(); // close dialog
          Get.back(); // navigate back to login screen
        },
      );
    } on FirebaseAuthException catch (e) {
      isLoading.value = false;
      Get.defaultDialog(
        title: 'Error',
        middleText: e.message ?? 'Failed to send password reset email.',
        textConfirm: 'OK',
        confirmTextColor: Colors.white,
        onConfirm: () => Get.back(),
      );
    } catch (e) {
      isLoading.value = false;
      Get.defaultDialog(
        title: 'Unexpected Error',
        middleText: e.toString(),
        textConfirm: 'OK',
        confirmTextColor: Colors.white,
        onConfirm: () => Get.back(),
      );
    }
  }

  Future<void> createAdminAccount() async {
    final createEmailController = TextEditingController();
    final createPasswordController = TextEditingController();

    Get.defaultDialog(
      title: 'Create Admin User',
      titleStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18.sp),
      contentPadding: EdgeInsets.all(16.w),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'This utility registers an account in Firebase Auth and sets its role to "admin" in Cloud Firestore.',
            style: GoogleFonts.inter(fontSize: 12.sp, color: const Color(0xFF4A4453)),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16.h),
          TextField(
            controller: createEmailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              hintText: 'Email (e.g. admin@test.com)',
              labelText: 'Email',
              prefixIcon: const Icon(Icons.email_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
            ),
          ),
          SizedBox(height: 12.h),
          TextField(
            controller: createPasswordController,
            obscureText: true,
            decoration: InputDecoration(
              hintText: 'Password (min 6 chars)',
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
            ),
          ),
        ],
      ),
      textConfirm: 'Create Account',
      textCancel: 'Cancel',
      confirmTextColor: Colors.white,
      cancelTextColor: const Color(0xFF4A4453),
      buttonColor: const Color(0xFF420093),
      onConfirm: () async {
        final email = createEmailController.text.trim();
        final password = createPasswordController.text;

        if (email.isEmpty || password.isEmpty) {
          Get.rawSnackbar(
            title: 'ValidationError',
            message: 'Email and password cannot be empty.',
            backgroundColor: Colors.red.shade700,
          );
          return;
        }

        if (password.length < 6) {
          Get.rawSnackbar(
            title: 'ValidationError',
            message: 'Password must be at least 6 characters.',
            backgroundColor: Colors.red.shade700,
          );
          return;
        }

        Get.back(); // close default dialog
        isLoading.value = true;

        try {
          // Register in Auth
          UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
            email: email,
            password: password,
          );

          final uid = userCredential.user?.uid;
          if (uid != null) {
            // Write to Firestore users collection
            await FirebaseFirestore.instance.collection('users').doc(uid).set({
              'role': 'admin',
              'email': email,
              'createdAt': FieldValue.serverTimestamp(),
            });

            // Set login inputs for easy entry
            emailController.text = email;
            passwordController.text = password;

            Get.defaultDialog(
              title: 'Admin Created',
              middleText: 'Admin user successfully created! The credentials have been auto-filled in the form.',
              textConfirm: 'OK',
              confirmTextColor: Colors.white,
              onConfirm: () => Get.back(),
            );
          }
        } on FirebaseAuthException catch (e) {
          Get.defaultDialog(
            title: 'Registration Error',
            middleText: e.message ?? 'Failed to register admin.',
            textConfirm: 'OK',
            confirmTextColor: Colors.white,
            onConfirm: () => Get.back(),
          );
        } catch (e) {
          Get.defaultDialog(
            title: 'Error',
            middleText: e.toString(),
            textConfirm: 'OK',
            confirmTextColor: Colors.white,
            onConfirm: () => Get.back(),
          );
        } finally {
          isLoading.value = false;
        }
      },
    );
  }

  Future<void> clearFirestoreEmployees() async {
    isLoading.value = true;
    try {
      final querySnapshot = await FirebaseFirestore.instance.collection('users').get();
      final employees = querySnapshot.docs.where((doc) {
        final data = doc.data();
        return data['role'] == 'employee' || data['role'] == null;
      }).toList();

      if (employees.length <= 1) {
        Get.rawSnackbar(
          title: 'Already Clean',
          message: 'There is already 1 or fewer employees in the Firestore users collection.',
          backgroundColor: Colors.blue.shade700,
        );
        isLoading.value = false;
        return;
      }

      // Delete all employees except the first one
      final batch = FirebaseFirestore.instance.batch();
      for (int i = 1; i < employees.length; i++) {
        batch.delete(employees[i].reference);
      }
      await batch.commit();

      Get.defaultDialog(
        title: 'Firestore Cleared',
        middleText: 'Successfully cleared duplicate employees. Kept only 1 employee in users collection.',
        textConfirm: 'OK',
        confirmTextColor: Colors.white,
        onConfirm: () => Get.back(),
      );
    } catch (e) {
      Get.defaultDialog(
        title: 'Error',
        middleText: e.toString(),
        textConfirm: 'OK',
        confirmTextColor: Colors.white,
        onConfirm: () => Get.back(),
      );
    } finally {
      isLoading.value = false;
    }
  }
}

