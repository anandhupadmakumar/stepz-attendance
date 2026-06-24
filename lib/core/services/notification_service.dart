import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService extends GetxService {
  static NotificationService get to => Get.find();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? _fcmToken;
  final DateTime _serviceStartTime = DateTime.now();
  final Set<String> _notifiedDocIds = {};
  bool _birthdayCheckDone = false;

  Future<NotificationService> init() async {
    if (!kIsWeb) {
      await _requestPermissions();
      await _createNotificationChannel();
    }
    await _setupToken();
    _setupForegroundListeners();
    _setupBackgroundAndClickListeners();
    _setupFirestoreRealtimeListener();
    return this;
  }

  // 1. Request OS Permissions
  Future<void> _requestPermissions() async {
    try {
      NotificationSettings settings = await _fcm.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      debugPrint('User granted notification permission: ${settings.authorizationStatus}');
    } catch (e) {
      debugPrint('Error requesting notification permissions: $e');
    }
  }

  // Create Android notification channel programmatically to support high importance heads-up notifications
  Future<void> _createNotificationChannel() async {
    try {
      final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
      
      const androidNotificationChannel = AndroidNotificationChannel(
        'high_importance_channel', // must match the channelId sent by Vercel
        'High Importance Notifications',
        description: 'This channel is used for important push notifications.',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );

      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(androidNotificationChannel);
          
      debugPrint('FCM High Importance Notification Channel created successfully.');
    } catch (e) {
      debugPrint('Error creating FCM Notification Channel: $e');
    }
  }

  // 2. Retrieve FCM Token and sync with Firestore
  Future<void> _setupToken() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      _fcmToken = await _fcm.getToken();
      debugPrint('FCM Device Token: $_fcmToken');

      if (_fcmToken != null) {
        // Sync token with user document in Firestore
        await _firestore.collection('users').doc(user.uid).set({
          'fcmToken': _fcmToken,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // Automatically subscribe the device to FCM topics based on user role
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists && userDoc.data() != null) {
          final role = (userDoc.data()?['role'] ?? 'employee').toString().toLowerCase().trim();

          // Subscribe all devices to the broad 'all' topic
          await _fcm.subscribeToTopic('all');

          if (role == 'admin') {
            await _fcm.subscribeToTopic('admin');
            try {
              await _fcm.unsubscribeFromTopic('employee');
            } catch (_) {}
          } else {
            await _fcm.subscribeToTopic('employee');
            try {
              await _fcm.unsubscribeFromTopic('admin');
            } catch (_) {}
          }
          debugPrint('Successfully synced FCM topic subscriptions for role: $role');
        }
      }
    } catch (e) {
      debugPrint('Error setting up FCM token and subscriptions: $e');
    }
  }

  // Sync token on login
  Future<void> syncUserToken() async {
    await _setupToken();
  }

  // 3. Listen to foreground FCM messages
  void _setupForegroundListeners() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a FCM message in the foreground!');
      debugPrint('Message data: ${message.data}');

      if (message.notification != null) {
        debugPrint('Message also contained a notification: ${message.notification}');
        _showInAppAlert(
          title: message.notification!.title ?? 'Notification',
          body: message.notification!.body ?? '',
          type: message.data['type'] ?? 'general',
          route: message.data['route'] as String?,
        );
      }
    });
  }

  // 4. Listen to background and terminated push notification click events
  void _setupBackgroundAndClickListeners() {
    // Background click
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('FCM background message clicked!');
      final route = message.data['route'] as String?;
      if (route != null && route.isNotEmpty) {
        Get.toNamed(route);
      } else {
        Get.toNamed('/notifications');
      }
    });

    // Terminated app launch via push
    _fcm.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        debugPrint('FCM initial message clicked!');
        final route = message.data['route'] as String?;
        // Small delay to ensure navigation is loaded
        Future.delayed(const Duration(milliseconds: 500), () {
          if (route != null && route.isNotEmpty) {
            Get.toNamed(route);
          } else {
            Get.toNamed('/notifications');
          }
        });
      }
    });
  }

  // 5. Listen to Firestore real-time /notifications collection (zero-FCM-config fallback)
  void _setupFirestoreRealtimeListener() {
    _auth.authStateChanges().listen((user) {
      if (user == null) {
        _birthdayCheckDone = false;
        return;
      }

      // Query the user's role first
      _firestore.collection('users').doc(user.uid).snapshots().listen((doc) {
        if (!doc.exists || doc.data() == null) return;
        final String role = doc.data()?['role'] ?? 'employee';

        // Realtime listener for incoming updates
        _firestore
            .collection('notifications')
            .orderBy('createdAt', descending: true)
            .snapshots()
            .listen((snapshot) {
          for (var change in snapshot.docChanges) {
            if (change.type == DocumentChangeType.added) {
              final data = change.doc.data();
              final docId = change.doc.id;
              if (data != null && !_notifiedDocIds.contains(docId)) {
                final targetUid = data['targetUid'] as String?;
                final targetRole = data['targetRole'] as String?;
                final title = data['title'] as String? ?? 'Notification';
                final body = data['body'] as String? ?? '';
                final type = data['type'] as String? ?? 'general';

                // Check if notification is meant for this user
                bool isTarget = false;
                if (targetUid == user.uid) {
                  isTarget = true;
                } else if (targetRole == 'all') {
                  isTarget = true;
                } else if (targetRole == role) {
                  isTarget = true;
                }

                if (isTarget) {
                  _notifiedDocIds.add(docId);

                  // Evaluate if we should show foreground popup
                  final Timestamp? createdAt = data['createdAt'] as Timestamp?;
                  if (createdAt != null) {
                    final createdTime = createdAt.toDate();
                    // Show popup alert ONLY if it was created after this service started (avoid duplicate alerts on historical load)
                    if (createdTime.isAfter(_serviceStartTime.subtract(const Duration(seconds: 10)))) {
                      _showInAppAlert(
                        title: title,
                        body: body,
                        type: type,
                        route: data['route'] as String?,
                      );
                    }
                  }

                  // If it's a personalized notification, mark it as read in the DB so it is cleared
                  if (targetUid == user.uid && data['read'] == false) {
                    _firestore.collection('notifications').doc(docId).update({'read': true});
                  }
                }
              }
            }
          }
        });
      });
    });
  }

  // Show premium customized in-app notification banner
  void _showInAppAlert({
    required String title,
    required String body,
    required String type,
    String? route,
  }) {
    IconData iconData = Icons.notifications;
    Color iconColor = const Color(0xFF9061FF);
    Color startColor = const Color(0xFF1E1E2F);

    if (type == 'leave_request') {
      iconData = Icons.time_to_leave_rounded;
      iconColor = const Color(0xFF60A5FA);
    } else if (type == 'leave_approved') {
      iconData = Icons.check_circle_rounded;
      iconColor = const Color(0xFF34D399);
    } else if (type == 'leave_rejected') {
      iconData = Icons.cancel_rounded;
      iconColor = const Color(0xFFF87171);
    } else if (type == 'regularization_request') {
      iconData = Icons.fact_check_rounded;
      iconColor = const Color(0xFFF59E0B);
    } else if (type == 'regularization_approved') {
      iconData = Icons.check_circle_rounded;
      iconColor = const Color(0xFF34D399);
    } else if (type == 'regularization_rejected') {
      iconData = Icons.cancel_rounded;
      iconColor = const Color(0xFFF87171);
    } else if (type == 'broadcast') {
      iconData = Icons.campaign_rounded;
      iconColor = const Color(0xFFF59E0B);
    } else if (type == 'birthday') {
      iconData = Icons.cake_rounded;
      iconColor = const Color(0xFFEC4899);
    }

    Get.rawSnackbar(
      titleText: Text(
        title,
        style: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      messageText: Text(
        body,
        style: TextStyle(
          fontSize: 12.sp,
          color: Colors.white.withOpacity(0.8),
        ),
      ),
      icon: Icon(iconData, color: iconColor, size: 24.sp),
      backgroundColor: startColor.withOpacity(0.9),
      borderColor: Colors.white.withOpacity(0.12),
      borderWidth: 1.0,
      margin: EdgeInsets.all(16.w),
      borderRadius: 16.r,
      duration: const Duration(seconds: 5),
      snackPosition: SnackPosition.TOP,
      boxShadows: [
        BoxShadow(
          color: Colors.black.withOpacity(0.3),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
      onTap: (_) {
        if (route != null && route.isNotEmpty) {
          Get.toNamed(route);
        } else {
          Get.toNamed('/notifications');
        }
      },
    );
  }

  // 6. Send notifications to a specific user or role
  Future<void> sendNotification({
    String? targetUid,
    String? targetRole,
    required String title,
    required String body,
    required String type,
    String? route,
  }) async {
    try {
      // Write to Firestore notifications collection first (triggers realtime fallback listener)
      await _firestore.collection('notifications').add({
        'title': title,
        'body': body,
        'type': type,
        'targetUid': targetUid,
        'targetRole': targetRole,
        'read': false,
        'route': route,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Dispatch push notification through the hosted Vercel FCM Service
      final fcmApiUrl = dotenv.env['NOTIFICATION_API_URL'];
      if (fcmApiUrl != null && fcmApiUrl.isNotEmpty) {
        final url = Uri.parse('$fcmApiUrl/api/send');
        final response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'title': title,
            'body': body,
            'type': type,
            'route': route,
            if (targetUid != null) 'targetUid': targetUid,
            if (targetRole != null) 'targetRole': targetRole,
          }),
        );

        if (response.statusCode == 200) {
          debugPrint('Push Notification successfully routed through Vercel FCM Service.');
        } else {
          debugPrint('Failed to send push via Vercel: ${response.statusCode} - ${response.body}');
        }
      } else {
        debugPrint('NOTIFICATION_API_URL environment variable is not defined. Skipping push dispatch.');
      }
    } catch (e) {
      debugPrint('Error sending notification: $e');
    }
  }

  // 7. Automation: Check and send Birthday greeting notifications
  Future<void> checkAndSendBirthdays() async {
    if (_birthdayCheckDone) return;
    _birthdayCheckDone = true;

    try {
      final today = DateTime.now();
      final todayMonthDay = DateFormat('MM-dd').format(today); // e.g. "06-16"
      final currentYear = today.year.toString();

      // Query all users to check DOB
      final usersSnapshot = await _firestore.collection('users').get();
      
      for (var doc in usersSnapshot.docs) {
        final data = doc.data();
        final String? dob = data['dob'] as String?;
        final String? role = data['role'] as String?;
        if (dob == null || dob.trim().isEmpty || role == 'admin') continue;

        // dob format is expected to be YYYY-MM-DD
        try {
          final dobParts = dob.split('-');
          if (dobParts.length == 3) {
            final dobMonthDay = '${dobParts[1]}-${dobParts[2]}';
            if (dobMonthDay == todayMonthDay) {
              final employeeUid = doc.id;
              final employeeName = data['name'] ?? 'Employee';
              final greetingId = '${employeeUid}_$currentYear';

              // Check if greeting has already been sent today
              final greetingDoc = await _firestore
                  .collection('sent_birthday_greetings')
                  .doc(greetingId)
                  .get();

              if (!greetingDoc.exists) {
                // Save to prevent duplicate sends today
                await _firestore
                    .collection('sent_birthday_greetings')
                    .doc(greetingId)
                    .set({
                  'sentAt': FieldValue.serverTimestamp(),
                  'employeeName': employeeName,
                  'employeeUid': employeeUid,
                  'year': currentYear,
                });

                // Broadcast birthday wish to all employees and admins
                await sendNotification(
                  targetRole: 'all',
                  title: 'Birthday Celebration! 🎂🎈',
                  body: 'Wishing a very Happy Birthday to $employeeName! 🎉 Let\'s celebrate!',
                  type: 'birthday',
                );
              }
            }
          }
        } catch (e) {
          debugPrint('Error parsing DOB for user ${doc.id}: $e');
        }
      }
    } catch (e) {
      debugPrint('Error checking employee birthdays: $e');
    }
  }
}
