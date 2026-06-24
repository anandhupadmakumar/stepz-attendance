import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stepz_attendance/core/constants/app_colors.dart';
import 'package:stepz_attendance/core/utils/device_id_helper.dart';
import 'package:stepz_attendance/core/services/notification_service.dart';
import 'package:stepz_attendance/core/services/geofence_reminder_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EmployeeDashboardController extends GetxController {
  final bool isTesting;
  EmployeeDashboardController({this.isTesting = false});

  // Firebase Auth & Firestore instances
  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  // Clock state
  final RxString currentTime = ''.obs;
  final RxString currentDate = ''.obs;
  Timer? _clockTimer;

  // Active User data (reactive)
  final RxString employeeName = 'Marcus Wade'.obs;
  final RxString employeeId = 'EMP-8521'.obs;
  final RxString employeeDesignation = 'Operations Lead'.obs;
  final RxString employeeEmail = ''.obs;
  final RxString employeeStatus = 'Absent'.obs;

  // Local settings for reminders/notifications
  final RxBool enableAttendanceReminder = true.obs;
  final RxBool enableCheckoutReminder = true.obs;
  final RxBool enableGeofenceNotification = true.obs;
  final RxBool enablePushNotifications = true.obs;

  // Geofencing and location state — loaded dynamically from Firestore settings/office_location
  final RxDouble officeLatitude = 0.0.obs;
  final RxDouble officeLongitude = 0.0.obs;
  final RxDouble policyRangeMetres = 200.0.obs; // metres
  final RxString officeName = 'Office'.obs;
  final RxBool officeSettingsLoaded = false.obs;
  StreamSubscription? _officeSettingsSubscription;
  StreamSubscription<Position>? _positionStreamSubscription;
  StreamSubscription? _userDocSubscription;

  // Derived: policy range in KM for display
  double get policyRange => policyRangeMetres.value / 1000.0;

  final RxString currentLocationName = 'Fetching location...'.obs;
  final RxDouble distanceToBase = 999.0.obs; // In KM
  final RxBool isInsideGeofence = false.obs;
  final RxBool isSettingsConfigured =
      false.obs; // true once admin has saved settings

  // Attendance actions state
  final RxBool isCheckedIn = false.obs;
  final RxBool isCheckedOut = false.obs;
  final RxBool isWFH = false.obs;
  final RxString checkInTime = '--'.obs;
  final RxString checkOutTime = '--'.obs;
  final RxString hoursWorkedToday = '00h 00m 00s'.obs;

  // Active document ID for current check-in in Firestore
  String? currentAttendanceDocId;
  DateTime? checkInDateTime;
  Timer? _workHoursTimer;

  // Logs list
  final RxList<Map<String, dynamic>> recentLogs = <Map<String, dynamic>>[].obs;

  // Regularization variables
  final RxList<Map<String, dynamic>> regularizationRequests = <Map<String, dynamic>>[].obs;
  final Rxn<Map<String, dynamic>> unregularizedMissedPunch = Rxn<Map<String, dynamic>>();
  final RxInt pendingRequestsCount = 0.obs;
  final RxInt approvedRequestsCount = 0.obs;
  final RxInt rejectedRequestsCount = 0.obs;
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _rawAttendanceDocs = [];
  StreamSubscription? _regularizationSubscription;

  // History tab computed stats properties
  final RxInt totalActiveDays = 0.obs;
  final RxString averageWorkingHours = '0.0 hrs'.obs;
  final RxInt totalLateCheckIns = 0.obs;
  final RxInt totalWfhDays = 0.obs;

  // Navigation active tab (0: Home, 1: Attendance, 2: Leaves, 3: Profile)
  final RxInt activeTabIndex = 0.obs;

  // Work Task Update fields
  final taskFormKey = GlobalKey<FormState>();
  final projectNameController = TextEditingController();
  final taskDetailsController = TextEditingController();
  final rxProjectName = ''.obs;
  final rxTaskDetails = ''.obs;
  final RxString selectedTaskStatus = 'In Progress'.obs;
  final RxBool isSavingTask = false.obs;

  // Read-only text controllers
  final dateTextController = TextEditingController();
  final checkInTextController = TextEditingController();
  final checkOutTextController = TextEditingController();

  // Track loaded doc to prevent overwriting user input stream-side
  String? _loadedDocId;

  void _syncTextControllersToRx() {
    rxProjectName.value = projectNameController.text;
    rxTaskDetails.value = taskDetailsController.text;
  }

  @override
  void onInit() {
    super.onInit();
    projectNameController.addListener(_syncTextControllersToRx);
    taskDetailsController.addListener(_syncTextControllersToRx);
    _startClock();
    if (!isTesting) {
      _loadEmployeeSettings();
      _loadEmployeeData();
      _listenToOfficeSettings(); // Listen to admin-configured geofence in real-time
      _listenToTodayAttendance();
      _fetchAttendanceLogs();
      _listenToLeaveRequests();
      _listenToRegularizationRequests();
      
      // Request geofencing and notification permissions on dashboard load
      Future.delayed(const Duration(seconds: 1), () {
        Get.find<GeofenceReminderService>().requestPermissions();
      });

      // Auto-trigger birthday check greeting
      Future.delayed(const Duration(seconds: 2), () {
        Get.find<NotificationService>().checkAndSendBirthdays();
      });
    } else {
      _setMockLogs();
      officeSettingsLoaded.value = true;
      isSettingsConfigured.value = true;
      currentLocationName.value = 'Within Office Range';
      distanceToBase.value = 0.05;
      isInsideGeofence.value = true;
    }
  }

  @override
  void onClose() {
    _clockTimer?.cancel();
    _workHoursTimer?.cancel();
    _officeSettingsSubscription?.cancel();
    _positionStreamSubscription?.cancel();
    _userDocSubscription?.cancel();
    _leavesSubscription?.cancel();
    _regularizationSubscription?.cancel();
    projectNameController.dispose();
    taskDetailsController.dispose();
    dateTextController.dispose();
    checkInTextController.dispose();
    checkOutTextController.dispose();
    super.onClose();
  }

  // 1. Clock Updates
  void _startClock() {
    _updateClockValues();
    if (isTesting) return;
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateClockValues();
    });
  }

  void _updateClockValues() {
    final now = DateTime.now();
    currentTime.value = DateFormat('hh:mm:ss a').format(now);
    currentDate.value = DateFormat('EEEE, MMMM d, yyyy').format(now);
  }

  // 2. Load User Profile
  // 2. Load User Profile & Start User Listener (Real-time Force Logout & Changes)
  void _loadEmployeeData() {
    _userDocSubscription?.cancel();
    _startUserDocListener();
  }

  void _startUserDocListener() {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      employeeEmail.value = user.email ?? '';

      _userDocSubscription = _firestore
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .listen(
            (doc) async {
              if (!doc.exists || doc.data() == null) {
                // Document deleted by admin: Terminate login session instantly
                _userDocSubscription?.cancel();
                _stopWorkHoursTimer();
                await _auth.signOut();
                Get.offAllNamed('/login');

                Get.defaultDialog(
                  title: 'Account Deleted',
                  middleText:
                      'Your account has been deleted by the administrator. Please contact your admin for support.',
                  textConfirm: 'OK',
                  confirmTextColor: Colors.white,
                  buttonColor: const Color(0xFFBA1A1A),
                  onConfirm: () => Get.back(),
                );
                return;
              }

              final data = doc.data()!;

              // Check for device mismatch or reset
              final currentDeviceId = await DeviceIdHelper.getDeviceId();
              final String? boundDeviceId = data['deviceId'];

              if (boundDeviceId == null || boundDeviceId.trim().isEmpty) {
                // Device binding reset by admin: Terminate login session instantly
                _userDocSubscription?.cancel();
                _stopWorkHoursTimer();
                await _auth.signOut();
                Get.offAllNamed('/login');

                Get.defaultDialog(
                  title: 'Device Reset',
                  middleText:
                      'Your device binding has been reset by the administrator. Please log in again to register your device.',
                  textConfirm: 'OK',
                  confirmTextColor: Colors.white,
                  buttonColor: const Color(0xFF420093),
                  onConfirm: () => Get.back(),
                );
                return;
              }

              if (boundDeviceId != currentDeviceId) {
                // Device binding changed: Terminate login session instantly
                _userDocSubscription?.cancel();
                _stopWorkHoursTimer();
                await _auth.signOut();
                Get.offAllNamed('/login');

                Get.defaultDialog(
                  title: 'Access Blocked',
                  middleText:
                      'This account is registered on another device. Please contact admin to change your phone.',
                  textConfirm: 'OK',
                  confirmTextColor: Colors.white,
                  buttonColor: const Color(0xFFBA1A1A),
                  onConfirm: () => Get.back(),
                );
                return;
              }

              // Populate fields reactively
              employeeName.value = data['name'] ?? 'Employee';
              employeeId.value = data['employeeId'] ?? 'EMP-000';
              employeeDesignation.value = data['designation'] ?? 'Staff Member';
              employeeStatus.value = data['status'] ?? 'Absent';
            },
            onError: (e) {
              debugPrint("Error listening to user document: $e");
            },
          );
    } catch (e) {
      debugPrint("Error setting up user document listener: $e");
    }
  }

  // 3. Load Office Settings from Firestore
  void _listenToOfficeSettings() {
    try {
      _officeSettingsSubscription = _firestore
          .collection('settings')
          .doc('attendance_settings')
          .snapshots()
          .listen(
            (doc) async {
              if (doc.exists && doc.data() != null) {
                final data = doc.data()!;
                officeLatitude.value =
                    (data['officeLatitude'] as num?)?.toDouble() ?? 0.0;
                officeLongitude.value =
                    (data['officeLongitude'] as num?)?.toDouble() ?? 0.0;
                policyRangeMetres.value =
                    (data['officeRadius'] as num?)?.toDouble() ?? 200.0;
                officeName.value = data['officeName'] ?? 'Office';

                // Load reminder times and geofenceEnabled
                final morningTime = data['morningReminderTime'] as String? ?? '09:15 AM';
                final checkoutTime = data['checkoutReminderTime'] as String? ?? '05:30 PM';
                final geofenceEnabled = data['geofenceEnabled'] as bool? ?? true;

                // Save configurations to SharedPreferences for background service access
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('morning_reminder_time', morningTime);
                await prefs.setString('checkout_reminder_time', checkoutTime);
                await prefs.setBool('geofence_enabled_admin', geofenceEnabled);

                officeSettingsLoaded.value = true;
                isSettingsConfigured.value =
                    officeLatitude.value != 0.0 || officeLongitude.value != 0.0;

                // Sync/register geofence with OS
                if (isSettingsConfigured.value) {
                  _registerGeofence(geofenceEnabled);
                }

                // Re-evaluate location check details with updated coordinates
                useRealLocation();
              } else {
                // Fallback to legacy office_location
                _listenToLegacyOfficeSettings();
              }
            },
            onError: (e) {
              debugPrint('Error listening to office settings: $e');
              _listenToLegacyOfficeSettings();
            },
          );
    } catch (e) {
      debugPrint('Error setting up office settings listener: $e');
      officeSettingsLoaded.value = true;
    }
  }

  void _listenToLegacyOfficeSettings() {
    try {
      _firestore
          .collection('settings')
          .doc('office_location')
          .snapshots()
          .listen(
            (doc) async {
              if (doc.exists && doc.data() != null) {
                final data = doc.data()!;
                officeLatitude.value =
                    (data['latitude'] as num?)?.toDouble() ?? 0.0;
                officeLongitude.value =
                    (data['longitude'] as num?)?.toDouble() ?? 0.0;
                policyRangeMetres.value =
                    (data['radius'] as num?)?.toDouble() ?? 200.0;
                officeName.value = data['officeName'] ?? 'Office';

                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('morning_reminder_time', '09:15 AM');
                await prefs.setString('checkout_reminder_time', '05:30 PM');
                await prefs.setBool('geofence_enabled_admin', true);

                officeSettingsLoaded.value = true;
                isSettingsConfigured.value =
                    officeLatitude.value != 0.0 || officeLongitude.value != 0.0;

                if (isSettingsConfigured.value) {
                  _registerGeofence(true);
                }
                useRealLocation();
              } else {
                isSettingsConfigured.value = false;
                officeSettingsLoaded.value = true;
                currentLocationName.value = 'Office not configured by admin';
              }
            },
            onError: (e) {
              debugPrint('Error listening to legacy office settings: $e');
              isSettingsConfigured.value = false;
              officeSettingsLoaded.value = true;
              currentLocationName.value = 'Could not load office settings';
            },
          );
    } catch (e) {
      debugPrint('Error setting up legacy office settings listener: $e');
      officeSettingsLoaded.value = true;
    }
  }

  // Register geofence region helper
  void _registerGeofence(bool adminEnabled) async {
    final prefs = await SharedPreferences.getInstance();
    final bool employeeEnabled = prefs.getBool('geofence_notification_enabled') ?? true;
    final bool finalEnabled = adminEnabled && employeeEnabled;

    try {
      await Get.find<GeofenceReminderService>().registerOfficeGeofence(
        latitude: officeLatitude.value,
        longitude: officeLongitude.value,
        radius: policyRangeMetres.value,
        enabled: finalEnabled,
      );
    } catch (e) {
      debugPrint('Error registering geofence region: $e');
    }
  }

  // Load local settings for reminders/notifications
  void _loadEmployeeSettings() async {
    final prefs = await SharedPreferences.getInstance();
    enableAttendanceReminder.value = prefs.getBool('attendance_reminder_enabled') ?? true;
    enableCheckoutReminder.value = prefs.getBool('checkout_reminder_enabled') ?? true;
    enableGeofenceNotification.value = prefs.getBool('geofence_notification_enabled') ?? true;
    enablePushNotifications.value = prefs.getBool('push_notifications_enabled') ?? true;
  }

  // Update employee settings
  void updateEmployeeSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);

    if (key == 'attendance_reminder_enabled') {
      enableAttendanceReminder.value = value;
      if (!value) {
        await Get.find<GeofenceReminderService>().cancelMorningReminder();
      }
    } else if (key == 'checkout_reminder_enabled') {
      enableCheckoutReminder.value = value;
      if (!value) {
        await Get.find<GeofenceReminderService>().cancelEveningCheckoutReminder();
      }
    } else if (key == 'geofence_notification_enabled') {
      enableGeofenceNotification.value = value;
      final adminEnabled = prefs.getBool('geofence_enabled_admin') ?? true;
      _registerGeofence(adminEnabled);
    } else if (key == 'push_notifications_enabled') {
      enablePushNotifications.value = value;
    }
  }

  void _setNoLocationState(String reason) {
    distanceToBase.value = 999.0;
    isInsideGeofence.value = false;
    currentLocationName.value = reason;
  }

  void _evaluatePosition(Position position) {
    if (!isSettingsConfigured.value) return;

    double distanceInMeters = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      officeLatitude.value,
      officeLongitude.value,
    );

    distanceToBase.value = distanceInMeters / 1000.0;
    isInsideGeofence.value = distanceInMeters <= policyRangeMetres.value;

    if (isInsideGeofence.value) {
      currentLocationName.value = 'Within ${officeName.value} Range';
      // Schedule morning reminder in foreground if inside and not checked in
      if (!isCheckedIn.value) {
        Get.find<GeofenceReminderService>().scheduleMorningReminder();
      }
    } else {
      currentLocationName.value = 'Outside ${officeName.value} Range';
      // Cancel morning reminder if they left the range
      Get.find<GeofenceReminderService>().cancelMorningReminder();
    }
  }

  void _startRealLocationListening() async {
    _positionStreamSubscription?.cancel();
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _setNoLocationState('Location Service Disabled');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _setNoLocationState('Location Permission Denied');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _setNoLocationState('Location Permission Denied');
        return;
      }

      _positionStreamSubscription =
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 3, // recalculate on every 3 meters moved
            ),
          ).listen(
            (Position position) {
              _evaluatePosition(position);
            },
            onError: (e) {
              debugPrint("Error in position stream: $e");
            },
          );
    } catch (e) {
      debugPrint("Error starting location listener: $e");
    }
  }

  Future<void> useRealLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        Get.rawSnackbar(
          title: 'Location Service Disabled',
          message: 'Please enable location services in your system settings.',
          backgroundColor: Colors.orange.shade700,
        );
        _setNoLocationState('Location Service Disabled');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          Get.rawSnackbar(
            title: 'Permission Denied',
            message:
                'Location permissions are required to check in using actual GPS.',
            backgroundColor: Colors.orange.shade700,
          );
          _setNoLocationState('Location Permission Denied');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        Get.rawSnackbar(
          title: 'Permission Denied Forever',
          message: 'Location permissions are permanently denied.',
          backgroundColor: Colors.orange.shade700,
        );
        _setNoLocationState('Location Permission Denied');
        return;
      }

      if (!isSettingsConfigured.value) {
        Get.rawSnackbar(
          title: 'Office Not Configured',
          message: 'Admin has not set up the office geofence location yet.',
          backgroundColor: Colors.orange.shade700,
        );
        _setNoLocationState('Office Not Configured');
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      _evaluatePosition(position);
      _startRealLocationListening();
    } catch (e) {
      debugPrint("Error getting GPS location: $e");
      Get.rawSnackbar(
        title: 'GPS Error',
        message: 'Could not obtain device location.',
        backgroundColor: Colors.red.shade700,
      );
      _setNoLocationState('GPS Error');
    }
  }

  // 4. Listen to Today's Attendance
  // Uses a single-field where clause (userId only) to avoid needing a composite
  // Firestore index, then filters by dateKey on the client side.
  void _listenToTodayAttendance() {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

      _firestore
          .collection('attendance')
          .where('userId', isEqualTo: user.uid)
          .snapshots()
          .listen((snapshot) {
            // Filter today's record client-side to avoid composite index requirement
            final todayDocs = snapshot.docs.where((doc) {
              return doc.data()['dateKey'] == todayStr;
            }).toList();

            if (todayDocs.isNotEmpty) {
              final doc = todayDocs.first;
              final docId = doc.id;
              currentAttendanceDocId = docId;
              final data = doc.data();

              final cIn = data['checkIn'] as String? ?? '--';
              final cOut = data['checkOut'] as String? ?? '--';
              checkInTime.value = cIn;
              checkOutTime.value = cOut;

              checkInTextController.text = cIn;
              checkOutTextController.text = cOut;
              dateTextController.text =
                  data['date'] as String? ??
                  DateFormat('MMM dd, yyyy').format(DateTime.now());

              final hasCheckedIn = cIn != '--';
              isCheckedIn.value = hasCheckedIn;
              isWFH.value = data['location'] == 'WFH';

              if (hasCheckedIn) {
                if (cOut != '--') {
                  isCheckedOut.value = true;
                  _stopWorkHoursTimer();
                  hoursWorkedToday.value = data['workedHours'] ?? '00h 00m 00s';
                } else {
                  isCheckedOut.value = false;
                  final checkInStr = data['checkInTimestamp'] as Timestamp?;
                  if (checkInStr != null) {
                    checkInDateTime = checkInStr.toDate();
                    _startWorkHoursTimer();
                  }
                  if (data['location'] == 'Office') {
                    isInsideGeofence.value = true;
                    distanceToBase.value = 0.0;
                    currentLocationName.value =
                        'At ${officeName.value} (Checked In)';
                  }
                }
              } else {
                isCheckedOut.value = false;
                _stopWorkHoursTimer();
                hoursWorkedToday.value = '00h 00m 00s';
              }

              // Load task info only once when switching/loading today's document
              if (_loadedDocId != docId) {
                projectNameController.text = data['projectName'] ?? '';
                taskDetailsController.text = data['taskDetails'] ?? '';
                selectedTaskStatus.value = data['taskStatus'] ?? 'In Progress';
                _loadedDocId = docId;
              }
            } else {
              // No check-in record today
              isCheckedIn.value = false;
              isCheckedOut.value = false;
              isWFH.value = false;
              checkInTime.value = '--';
              checkOutTime.value = '--';
              hoursWorkedToday.value = '00h 00m 00s';
              currentAttendanceDocId = null;
              checkInDateTime = null;
              _stopWorkHoursTimer();

              // Clear task controllers
              projectNameController.clear();
              taskDetailsController.clear();
              selectedTaskStatus.value = 'In Progress';
              _loadedDocId = null;

              checkInTextController.text = '--';
              checkOutTextController.text = '--';
              dateTextController.text = DateFormat(
                'MMM dd, yyyy',
              ).format(DateTime.now());
            }
          });
    } catch (e) {
      debugPrint('Firestore today attendance setup failed: $e');
    }
  }

  // 5. Work Hours Timer
  void _startWorkHoursTimer() {
    _workHoursTimer?.cancel();
    _updateWorkHours();
    if (isTesting) return;
    _workHoursTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateWorkHours();
    });
  }

  void _stopWorkHoursTimer() {
    _workHoursTimer?.cancel();
  }

  void _updateWorkHours() {
    if (checkInDateTime == null || isCheckedOut.value) return;
    final diff = DateTime.now().difference(checkInDateTime!);
    final hours = diff.inHours;
    final minutes = diff.inMinutes.remainder(60);
    final seconds = diff.inSeconds.remainder(60);
    hoursWorkedToday.value =
        '${hours.toString().padLeft(2, '0')}h ${minutes.toString().padLeft(2, '0')}m ${seconds.toString().padLeft(2, '0')}s';
  }

  // 6. Action: Check In
  Future<void> checkIn() async {
    // Guard: office must be configured by admin
    if (!isSettingsConfigured.value) {
      Get.defaultDialog(
        title: 'Office Not Configured',
        middleText:
            'The admin has not yet set up the office location and geofence radius. Please contact your administrator.',
        textConfirm: 'OK',
        confirmTextColor: Colors.white,
        buttonColor: AppColors.primary,
        onConfirm: () => Get.back(),
      );
      return;
    }

    // Check constraints: Must be either inside range or working WFH
    if (!isInsideGeofence.value && !isWFH.value) {
      final rangeStr = policyRangeMetres.value >= 1000
          ? '${(policyRangeMetres.value / 1000).toStringAsFixed(2)} km'
          : '${policyRangeMetres.value.toStringAsFixed(0)} m';
      Get.defaultDialog(
        title: '🚫 Outside Geofence',
        middleText:
            'You are ${(distanceToBase.value * 1000).toStringAsFixed(0)} m from ${officeName.value}.\n\nYou must be within $rangeStr to check in.\n\nPlease move closer to the office or mark yourself as WFH.',
        textConfirm: 'Got it',
        confirmTextColor: Colors.white,
        buttonColor: Colors.red.shade700,
        onConfirm: () => Get.back(),
      );
      return;
    }

    final user = _auth.currentUser;
    if (user == null) return;

    final now = DateTime.now();
    final timeStr = DateFormat('hh:mm a').format(now);
    final dateKey = DateFormat('yyyy-MM-dd').format(now);
    final displayDate = DateFormat('MMM dd, yyyy').format(now);

    try {
      if (currentAttendanceDocId != null) {
        // Document already exists (created by task update), update it
        await _firestore
            .collection('attendance')
            .doc(currentAttendanceDocId)
            .update({
              'checkIn': timeStr,
              'location': isWFH.value ? 'WFH' : 'Office',
              'checkInTimestamp': FieldValue.serverTimestamp(),
            });
      } else {
        // Document does not exist, create it
        final docRef = await _firestore.collection('attendance').add({
          'userId': user.uid,
          'employeeId': employeeId.value,
          'name': employeeName.value,
          'dateKey': dateKey,
          'date': displayDate,
          'checkIn': timeStr,
          'checkOut': '--',
          'location': isWFH.value ? 'WFH' : 'Office',
          'checkInTimestamp': FieldValue.serverTimestamp(),
          'workedHours': '00h 00m 00s',
        });
        currentAttendanceDocId = docRef.id;
      }
      checkInDateTime = now;
      isCheckedIn.value = true;
      checkInTime.value = timeStr;

      // Update employee status to 'present' or 'wfh' in users doc
      await _firestore.collection('users').doc(user.uid).update({
        'status': isWFH.value ? 'wfh' : 'present',
      });

      employeeStatus.value = isWFH.value ? 'wfh' : 'present';

      // Cancel morning reminder and schedule evening checkout reminder
      await Get.find<GeofenceReminderService>().cancelMorningReminder();
      await Get.find<GeofenceReminderService>().scheduleEveningCheckoutReminder();

      Get.rawSnackbar(
        title: 'Checked In',
        message: 'Successfully checked in at $timeStr',
        backgroundColor: Colors.green.shade700,
      );

      _startWorkHoursTimer();
      _fetchAttendanceLogs();
    } catch (e) {
      Get.rawSnackbar(
        title: 'Check-in Error',
        message: e.toString(),
        backgroundColor: Colors.red.shade700,
      );
    }
  }

  // 7. Action: Check Out
  Future<void> checkOut() async {
    if (currentAttendanceDocId == null) {
      Get.rawSnackbar(
        title: 'Error',
        message: 'No active check-in record found for today.',
        backgroundColor: Colors.red.shade700,
      );
      return;
    }

    // Guard: Require daily work updates before allowing checkout
    if (projectNameController.text.trim().isEmpty ||
        taskDetailsController.text.trim().isEmpty) {
      Get.defaultDialog(
        title: 'Work Update Required',
        middleText:
            'You must fill in your daily work updates (Project Name and Task Details) in the form below before checking out.',
        textConfirm: 'OK',
        confirmTextColor: Colors.white,
        buttonColor: AppColors.primary,
        onConfirm: () => Get.back(),
      );
      return;
    }

    // Check geofence constraints: Must be either inside range or working WFH
    if (!isInsideGeofence.value && !isWFH.value) {
      final rangeStr = policyRangeMetres.value >= 1000
          ? '${(policyRangeMetres.value / 1000).toStringAsFixed(2)} km'
          : '${policyRangeMetres.value.toStringAsFixed(0)} m';
      Get.defaultDialog(
        title: '🚫 Outside Geofence',
        middleText:
            'You are ${(distanceToBase.value * 1000).toStringAsFixed(0)} m from ${officeName.value}.\n\nYou must be within $rangeStr to check out.\n\nPlease move closer to the office or mark yourself as WFH.',
        textConfirm: 'Got it',
        confirmTextColor: Colors.white,
        buttonColor: Colors.red.shade700,
        onConfirm: () => Get.back(),
      );
      return;
    }

    final user = _auth.currentUser;
    if (user == null) return;

    final now = DateTime.now();
    final timeStr = DateFormat('hh:mm a').format(now);

    try {
      _stopWorkHoursTimer();
      _updateWorkHours(); // get final computation

      // Automatically save/update the work task details along with checkout details
      await _firestore
          .collection('attendance')
          .doc(currentAttendanceDocId)
          .update({
            'checkOut': timeStr,
            'checkOutTimestamp': FieldValue.serverTimestamp(),
            'workedHours': hoursWorkedToday.value,
            'projectName': projectNameController.text.trim(),
            'taskDetails': taskDetailsController.text.trim(),
            'taskStatus': selectedTaskStatus.value,
            'taskUpdatedAt': FieldValue.serverTimestamp(),
          });

      isCheckedOut.value = true;
      checkOutTime.value = timeStr;

      // Update user status back to absent/checked out
      await _firestore.collection('users').doc(user.uid).update({
        'status': 'absent',
      });
      employeeStatus.value = 'absent';

      // Cancel evening checkout reminder
      await Get.find<GeofenceReminderService>().cancelEveningCheckoutReminder();

      Get.rawSnackbar(
        title: 'Checked Out',
        message:
            'Successfully checked out at $timeStr. Total: ${hoursWorkedToday.value}',
        backgroundColor: Colors.green.shade700,
      );

      _fetchAttendanceLogs();
    } catch (e) {
      Get.rawSnackbar(
        title: 'Check-out Error',
        message: e.toString(),
        backgroundColor: Colors.red.shade700,
      );
    }
  }

  // 8. Action: Mark WFH
  void markWFH() {
    if (isCheckedIn.value) {
      Get.rawSnackbar(
        title: 'Active Check-in',
        message: 'You have already checked in. WFH status cannot be modified.',
        backgroundColor: Colors.orange.shade700,
      );
      return;
    }

    isWFH.value = !isWFH.value;

    Get.rawSnackbar(
      title: isWFH.value ? 'WFH Mode Activated' : 'Office Mode Activated',
      message: isWFH.value
          ? 'You can now check in from any location.'
          : 'You must be within the geofenced office range to check in.',
      backgroundColor: const Color(0xFF4E45D5),
    );
  }

  // 9. Fetch logs history
  // Uses a single-field where clause only (userId) to avoid a composite index,
  // then sorts the results client-side by checkInTimestamp descending.
  bool _checkIsLate(String? checkInTime) {
    if (checkInTime == null || checkInTime == '--' || checkInTime.trim().isEmpty) return false;
    final cleaned = checkInTime.trim().toUpperCase();
    try {
      final match = RegExp(r'^(\d{1,2}):(\d{2})\s*(AM|PM)$').firstMatch(cleaned);
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

      final match24 = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(cleaned);
      if (match24 != null) {
        final int hour = int.parse(match24.group(1)!);
        final int minute = int.parse(match24.group(2)!);
        if (hour > 9) return true;
        if (hour == 9 && minute > 45) return true;
        return false;
      }

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

  // 9. Fetch logs history
  // Uses a single-field where clause only (userId) to avoid a composite index,
  // then sorts the results client-side by checkInTimestamp descending.
  Future<void> _fetchAttendanceLogs() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        _rawAttendanceDocs = [];
        recentLogs.clear();
        totalActiveDays.value = 0;
        totalLateCheckIns.value = 0;
        totalWfhDays.value = 0;
        averageWorkingHours.value = '0.0 hrs';
        unregularizedMissedPunch.value = null;
        return;
      }

      // Single-field query: no composite index required
      final snapshot = await _firestore
          .collection('attendance')
          .where('userId', isEqualTo: user.uid)
          .get();

      _rawAttendanceDocs = snapshot.docs;

      if (snapshot.docs.isEmpty) {
        recentLogs.clear();
        totalActiveDays.value = 0;
        totalLateCheckIns.value = 0;
        totalWfhDays.value = 0;
        averageWorkingHours.value = '0.0 hrs';
        unregularizedMissedPunch.value = null;
        return;
      }

      int totalDays = snapshot.docs.length;
      int lateDays = 0;
      int wfhDays = 0;
      double totalHours = 0.0;
      int hoursCount = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final checkIn = data['checkIn'] as String? ?? '--';
        final location = data['location'] as String? ?? 'Office';

        final isLate = _checkIsLate(checkIn);
        if (isLate && location != 'WFH') {
          lateDays++;
        }

        if (location == 'WFH') {
          wfhDays++;
        }

        final String whStr = data['workedHours'] as String? ?? '';
        if (whStr.isNotEmpty && whStr != '--' && whStr != '00h 00m 00s') {
          double hoursVal = 0.0;
          try {
            final match = RegExp(r'^(\d+)\s*h\s*(\d+)\s*m').firstMatch(whStr);
            if (match != null) {
              final int h = int.parse(match.group(1)!);
              final int m = int.parse(match.group(2)!);
              hoursVal = h + (m / 60.0);
            } else {
              final clean = whStr.replaceAll(' hrs', '').replaceAll(' hr', '').trim();
              hoursVal = double.tryParse(clean) ?? 0.0;
            }
          } catch (_) {}

          if (hoursVal > 0.0) {
            totalHours += hoursVal;
            hoursCount++;
          }
        }
      }

      totalActiveDays.value = totalDays;
      totalLateCheckIns.value = lateDays;
      totalWfhDays.value = wfhDays;

      if (hoursCount > 0) {
        final avg = totalHours / hoursCount;
        averageWorkingHours.value = '${avg.toStringAsFixed(1)} hrs';
      } else {
        averageWorkingHours.value = '0.0 hrs';
      }

      // Sort client-side by checkInTimestamp descending, take latest 10
      final sorted = snapshot.docs.toList()
        ..sort((a, b) {
          final tsA =
              (a.data()['checkInTimestamp'] as Timestamp?)
                  ?.millisecondsSinceEpoch ??
              0;
          final tsB =
              (b.data()['checkInTimestamp'] as Timestamp?)
                  ?.millisecondsSinceEpoch ??
              0;
          return tsB.compareTo(tsA); // descending
        });

      final limited = sorted.take(10);

      recentLogs.value = limited.map((doc) {
        final data = doc.data();
        final checkIn = data['checkIn'] as String? ?? '--';
        final isLate = _checkIsLate(checkIn) && data['location'] != 'WFH';
        return {
          'date': data['date'] ?? 'Unknown',
          'checkIn': checkIn,
          'checkOut': data['checkOut'] ?? '--',
          'location': data['location'] ?? 'Office',
          'isLate': isLate,
        };
      }).toList();

      _checkMissedPunches();
    } catch (e) {
      debugPrint('Error fetching logs: $e');
      _rawAttendanceDocs = [];
      recentLogs.clear();
      totalActiveDays.value = 0;
      totalLateCheckIns.value = 0;
      totalWfhDays.value = 0;
      averageWorkingHours.value = '0.0 hrs';
      unregularizedMissedPunch.value = null;
    }
  }

  void _setMockLogs() {
    recentLogs.value = [
      {
        'date': 'Oct 23, 2023',
        'checkIn': '08:55 AM',
        'checkOut': '05:45 PM',
        'location': 'Office',
        'isLate': false,
      },
      {
        'date': 'Oct 22, 2023',
        'checkIn': '09:02 AM',
        'checkOut': '06:12 PM',
        'location': 'WFH',
        'isLate': false,
      },
      {
        'date': 'Oct 21, 2023',
        'checkIn': '09:15 AM',
        'checkOut': '05:30 PM',
        'location': 'Office',
        'isLate': true,
      },
    ];

    totalActiveDays.value = 3;
    totalLateCheckIns.value = 1;
    totalWfhDays.value = 1;
    averageWorkingHours.value = '8.3 hrs';
  }

  Future<void> saveTaskUpdate() async {
    if (projectNameController.text.trim().isEmpty ||
        taskDetailsController.text.trim().isEmpty) {
      Get.rawSnackbar(
        title: 'Validation Error',
        message: 'Please fill in both Project Name and Task Details.',
        backgroundColor: Colors.red.shade700,
      );
      return;
    }

    if (checkInTime.value == '--' || checkInTime.value.trim().isEmpty) {
      Get.rawSnackbar(
        title: 'Check-in Required',
        message: 'Check-in time is required to submit a task update.',
        backgroundColor: Colors.red.shade700,
      );
      return;
    }

    isSavingTask.value = true;
    try {
      final user = _auth.currentUser;
      if (user == null) {
        Get.rawSnackbar(
          title: 'Error',
          message: 'User not authenticated.',
          backgroundColor: Colors.red.shade700,
        );
        return;
      }

      final now = DateTime.now();
      final dateKey = DateFormat('yyyy-MM-dd').format(now);
      final displayDate = DateFormat('MMM dd, yyyy').format(now);

      if (currentAttendanceDocId == null) {
        // Double check Firestore today's record
        final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
        final snapshot = await _firestore
            .collection('attendance')
            .where('userId', isEqualTo: user.uid)
            .get();

        final todayDocs = snapshot.docs.where((doc) {
          return doc.data()['dateKey'] == todayStr;
        }).toList();

        if (todayDocs.isNotEmpty) {
          final doc = todayDocs.first;
          currentAttendanceDocId = doc.id;

          await _firestore.collection('attendance').doc(doc.id).update({
            'projectName': projectNameController.text.trim(),
            'taskDetails': taskDetailsController.text.trim(),
            'taskStatus': selectedTaskStatus.value,
            'taskUpdatedAt': FieldValue.serverTimestamp(),
          });
        } else {
          // Create document
          final docRef = await _firestore.collection('attendance').add({
            'userId': user.uid,
            'employeeId': employeeId.value,
            'name': employeeName.value,
            'dateKey': dateKey,
            'date': displayDate,
            'checkIn': '--',
            'checkOut': '--',
            'location': '--',
            'checkInTimestamp': null,
            'workedHours': '00h 00m 00s',
            'projectName': projectNameController.text.trim(),
            'taskDetails': taskDetailsController.text.trim(),
            'taskStatus': selectedTaskStatus.value,
            'taskUpdatedAt': FieldValue.serverTimestamp(),
          });
          currentAttendanceDocId = docRef.id;
        }
      } else {
        await _firestore
            .collection('attendance')
            .doc(currentAttendanceDocId)
            .update({
              'projectName': projectNameController.text.trim(),
              'taskDetails': taskDetailsController.text.trim(),
              'taskStatus': selectedTaskStatus.value,
              'taskUpdatedAt': FieldValue.serverTimestamp(),
            });
      }

      Get.rawSnackbar(
        title: 'Success',
        message: 'Daily work task update saved successfully.',
        backgroundColor: Colors.green.shade700,
      );
    } catch (e) {
      debugPrint("Error saving task update: $e");
      Get.rawSnackbar(
        title: 'Error',
        message: 'Failed to save task update: ${e.toString()}',
        backgroundColor: Colors.red.shade700,
      );
    } finally {
      isSavingTask.value = false;
    }
  }

  // Logout utility
  void logout() async {
    await _auth.signOut();
    Get.offAllNamed('/login');
  }

  Future<void> sendPasswordResetEmail() async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null || user.email!.isEmpty) {
        Get.rawSnackbar(
          title: 'Error',
          message: 'No authenticated email address found.',
          backgroundColor: Colors.red.shade700,
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      await _auth.sendPasswordResetEmail(email: user.email!);
      
      Get.defaultDialog(
        title: 'Reset Link Sent',
        titleStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18.sp),
        contentPadding: EdgeInsets.all(16.w),
        middleText: 'A secure password recovery link has been sent to:\n${user.email}\n\nPlease check your inbox to reset your password.',
        middleTextStyle: GoogleFonts.inter(fontSize: 13.sp, color: const Color(0xFF4A4453)),
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
    try {
      _loadEmployeeData();
      await useRealLocation();
      await _fetchAttendanceLogs();

      Get.rawSnackbar(
        title: 'Status Refreshed',
        message:
            'Your geofence location and logs are successfully synchronized.',
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
    }
  }

  void changeTab(int index) {
    activeTabIndex.value = index;
  }

  // --- Leave Requests Logic ---
  final RxList<Map<String, dynamic>> leaveHistory = <Map<String, dynamic>>[].obs;
  final RxBool isLoadingLeaves = false.obs;
  final RxInt annualLeavesLeft = 14.obs;
  final RxInt sickLeavesLeft = 6.obs;
  final RxInt casualLeavesLeft = 8.obs;
  StreamSubscription? _leavesSubscription;

  void _listenToLeaveRequests() {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      isLoadingLeaves.value = true;
      _leavesSubscription?.cancel();
      _leavesSubscription = _firestore
          .collection('leave_requests')
          .where('userId', isEqualTo: user.uid)
          .snapshots()
          .listen((snapshot) {
            final List<Map<String, dynamic>> list = [];
            int approvedAnnual = 0;
            int approvedSick = 0;
            int approvedCasual = 0;

            for (var doc in snapshot.docs) {
              final data = doc.data();
              final id = doc.id;
              final status = data['status'] as String? ?? 'pending';
              final type = data['leaveType'] as String? ?? 'Annual Leave';
              
              // Calculate approved days
              if (status == 'approved') {
                final start = DateTime.tryParse(data['startDate'] ?? '') ?? DateTime.now();
                final end = DateTime.tryParse(data['endDate'] ?? '') ?? DateTime.now();
                final days = end.difference(start).inDays + 1;

                if (type == 'Annual Leave') {
                  approvedAnnual += days;
                } else if (type == 'Sick Leave') {
                  approvedSick += days;
                } else if (type == 'Casual Leave') {
                  approvedCasual += days;
                }
              }

              list.add({
                'id': id,
                'leaveType': type,
                'startDate': data['startDate'] ?? '',
                'endDate': data['endDate'] ?? '',
                'reason': data['reason'] ?? '',
                'status': status,
                'requestedAt': data['requestedAt'],
                'rejectionReason': data['rejectionReason'] ?? '',
              });
            }

            // Sort history by requestedAt descending
            list.sort((a, b) {
              final tsA = (a['requestedAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
              final tsB = (b['requestedAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
              return tsB.compareTo(tsA);
            });

            leaveHistory.assignAll(list);
            annualLeavesLeft.value = (14 - approvedAnnual).clamp(0, 14);
            sickLeavesLeft.value = (6 - approvedSick).clamp(0, 6);
            casualLeavesLeft.value = (8 - approvedCasual).clamp(0, 8);
            isLoadingLeaves.value = false;
          }, onError: (e) {
            debugPrint("Error listening to leave requests: $e");
            isLoadingLeaves.value = false;
          });
    } catch (e) {
      debugPrint("Error starting leaves listener: $e");
      isLoadingLeaves.value = false;
    }
  }

  Future<void> applyForLeave({
    required String type,
    required DateTime startDate,
    required DateTime endDate,
    required String reason,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    if (reason.trim().isEmpty) {
      Get.rawSnackbar(
        title: 'Validation Error',
        message: 'Please provide a reason for the leave.',
        backgroundColor: Colors.red.shade700,
      );
      return;
    }

    try {
      final days = endDate.difference(startDate).inDays + 1;
      if (days <= 0) {
        Get.rawSnackbar(
          title: 'Validation Error',
          message: 'End date must be on or after start date.',
          backgroundColor: Colors.red.shade700,
        );
        return;
      }

      final startStr = DateFormat('yyyy-MM-dd').format(startDate);
      final endStr = DateFormat('yyyy-MM-dd').format(endDate);

      // Save request
      await _firestore.collection('leave_requests').add({
        'userId': user.uid,
        'employeeName': employeeName.value,
        'employeeId': employeeId.value,
        'designation': employeeDesignation.value,
        'leaveType': type,
        'startDate': startStr,
        'endDate': endStr,
        'reason': reason.trim(),
        'status': 'pending',
        'requestedAt': FieldValue.serverTimestamp(),
      });

      // Send Notification to admin
      try {
        final pushBody = '${employeeName.value} requested $type for $days day(s) starting $startStr';
        await Get.find<NotificationService>().sendNotification(
          targetRole: 'admin',
          title: 'New Leave Request 📅',
          body: pushBody,
          type: 'leave_request',
        );
      } catch (e) {
        debugPrint("Error triggering leave request push notification: $e");
      }

      Get.back(); // close dialog
      Get.rawSnackbar(
        title: 'Success',
        message: 'Leave request submitted successfully.',
        backgroundColor: Colors.green.shade700,
      );
    } catch (e) {
      debugPrint("Error submitting leave request: $e");
      Get.rawSnackbar(
        title: 'Error',
        message: 'Failed to submit leave request: ${e.toString()}',
        backgroundColor: Colors.red.shade700,
      );
    }
  }

  // --- Attendance Regularization Methods ---
  void _listenToRegularizationRequests() {
    try {
      final user = _auth.currentUser;
      if (user == null) return;
      _regularizationSubscription?.cancel();
      _regularizationSubscription = _firestore
          .collection('attendance_regularization_requests')
          .where('employeeId', isEqualTo: user.uid)
          .snapshots()
          .listen((snapshot) {
            final List<Map<String, dynamic>> list = [];
            int pending = 0;
            int approved = 0;
            int rejected = 0;

            for (var doc in snapshot.docs) {
              final data = doc.data();
              list.add({
                'id': doc.id,
                ...data,
              });
              final status = data['status'] as String? ?? 'pending';
              if (status == 'pending') pending++;
              else if (status == 'approved') approved++;
              else if (status == 'rejected') rejected++;
            }

            // Sort by createdAt descending
            list.sort((a, b) {
              final tsA = (a['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
              final tsB = (b['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
              return tsB.compareTo(tsA);
            });

            regularizationRequests.assignAll(list);
            pendingRequestsCount.value = pending;
            approvedRequestsCount.value = approved;
            rejectedRequestsCount.value = rejected;

            // Re-evaluate missed punches since regularization requests changed
            _checkMissedPunches();
          }, onError: (e) {
            debugPrint('Error listening to regularization requests: $e');
          });
    } catch (e) {
      debugPrint('Error setting up regularization requests listener: $e');
    }
  }

  void _checkMissedPunches() {
    try {
      final user = _auth.currentUser;
      if (user == null || _rawAttendanceDocs.isEmpty) {
        unregularizedMissedPunch.value = null;
        return;
      }

      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

      // Find past records where checkIn is not '--' and checkOut is '--'
      final missedPunches = _rawAttendanceDocs.where((doc) {
        final data = doc.data();
        final dateKey = data['dateKey'] as String? ?? '';
        final checkIn = data['checkIn'] as String? ?? '--';
        final checkOut = data['checkOut'] as String? ?? '--';
        return dateKey != todayStr && checkIn != '--' && checkOut == '--';
      }).toList();

      if (missedPunches.isEmpty) {
        unregularizedMissedPunch.value = null;
        return;
      }

      // Sort them by checkInTimestamp descending to get the most recent past one
      missedPunches.sort((a, b) {
        final tsA = (a.data()['checkInTimestamp'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
        final tsB = (b.data()['checkInTimestamp'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
        return tsB.compareTo(tsA);
      });

      // Now find the most recent missed punch for which there is no approved or pending regularization request.
      Map<String, dynamic>? selectedMissedPunch;
      for (var doc in missedPunches) {
        final data = doc.data();
        final dateKey = data['dateKey'] as String? ?? '';

        // Check if a request already exists for this date and is not rejected
        final hasActiveRequest = regularizationRequests.any((req) =>
            req['attendanceDate'] == dateKey &&
            (req['status'] == 'pending' || req['status'] == 'approved'));

        if (!hasActiveRequest) {
          selectedMissedPunch = {
            'docId': doc.id,
            'date': data['date'] ?? 'Unknown Date',
            'dateKey': dateKey,
            'checkIn': data['checkIn'] ?? '--',
          };
          break;
        }
      }

      unregularizedMissedPunch.value = selectedMissedPunch;
    } catch (e) {
      debugPrint('Error checking missed punches: $e');
      unregularizedMissedPunch.value = null;
    }
  }
}
