import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stepz_attendance/core/services/speech_service.dart';
import 'package:stepz_attendance/core/services/ai_service.dart';
import 'package:stepz_attendance/core/services/notification_service.dart';
import 'employee_dashboard_controller.dart';
import '../../../work_management/models/task_model.dart';
import '../../../work_management/presentation/controllers/work_task_controller.dart';

class DailyTaskUpdateController extends GetxController {
  // Services
  final SpeechService _speechService = SpeechService();
  final AIService _aiService = AIService();

  final RxBool isTranslating = false.obs;

  // Firestore & Auth
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Form Controllers
  final projectNameController = TextEditingController(); // Used for Custom Task Title
  final taskDetailsController = TextEditingController();

  // Assigned Tasks States
  final RxList<TaskModel> employeeTasks = <TaskModel>[].obs;
  final RxBool isLoadingTasks = false.obs;
  final RxnString selectedTaskId = RxnString(); // Holds selected taskId or 'other'

  // Time & Status States
  final Rx<TimeOfDay?> startTime = Rx<TimeOfDay?>(null);
  final Rx<TimeOfDay?> endTime = Rx<TimeOfDay?>(null);
  final RxString selectedStatus = 'In Progress'.obs;
  final RxDouble progressPercentage = 0.0.obs;

  // Multiple staged updates
  final RxList<Map<String, dynamic>> tempLogs = <Map<String, dynamic>>[].obs;

  // Generic States
  final RxString employeeId = 'EMP-000'.obs;
  final RxBool isRecording = false.obs;
  final RxDouble soundLevel = 0.0.obs;
  final RxBool isSaving = false.obs;
  final RxBool isOffline = false.obs;

  // Check-in time state
  final RxString checkInTime = '--'.obs;        // e.g. '09:32 AM'
  final RxBool isLoadingCheckIn = true.obs;     // shows shimmer until loaded
  final RxBool hasCheckedIn = false.obs;        // gate for submission

  // Timers
  Timer? _draftTimer;
  Timer? _translationDebounce;

  @override
  void onInit() {
    super.onInit();
    _loadEmployeeId();
    _loadTodayCheckIn();
    fetchEmployeeTasks();
    _checkConnectivity();

    _loadDraft().then((_) {
      // Check if a specific taskId was passed in route arguments
      final incomingTaskId = Get.arguments;
      if (incomingTaskId is String && incomingTaskId.isNotEmpty) {
        selectedTaskId.value = incomingTaskId;
        
        // If employeeTasks are already loaded, sync immediately
        final task = employeeTasks.firstWhereOrNull((t) => t.taskId == incomingTaskId);
        if (task != null) {
          progressPercentage.value = task.progress;
          selectedStatus.value = task.status;
        }
      }
      _startDraftAutosave();
    });

    // Listen to task changes to preset default progress
    selectedTaskId.listen((val) {
      if (val != null && val != 'other') {
        final task = employeeTasks.firstWhereOrNull((t) => t.taskId == val);
        if (task != null) {
          progressPercentage.value = task.progress;
          selectedStatus.value = task.status;
        }
      } else {
        progressPercentage.value = 0.0;
        selectedStatus.value = 'In Progress';
      }
    });
  }

  @override
  void onClose() {
    _draftTimer?.cancel();
    _translationDebounce?.cancel();
    _speechService.cancelListening();
    projectNameController.dispose();
    taskDetailsController.dispose();
    super.onClose();
  }

  // --- Fetch Employee Tasks ---
  Future<void> fetchEmployeeTasks() async {
    isLoadingTasks.value = true;
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final snapshot = await _firestore
          .collection('tasks')
          .where('employeeIds', arrayContains: user.uid)
          .get();

      final tasks = snapshot.docs.map((doc) {
        final data = doc.data();
        return TaskModel.fromMap(data, doc.id);
      }).toList();

      // Filter tasks not fully completed
      employeeTasks.value = tasks.where((t) => t.status != 'Completed').toList();

      // If we already have a selectedTaskId, update progress and status from the loaded task
      final val = selectedTaskId.value;
      if (val != null && val != 'other') {
        final task = employeeTasks.firstWhereOrNull((t) => t.taskId == val);
        if (task != null) {
          progressPercentage.value = task.progress;
          selectedStatus.value = task.status;
        }
      }
    } catch (e) {
      debugPrint("Error fetching employee tasks: $e");
    } finally {
      isLoadingTasks.value = false;
    }
  }

  // --- Fetch Employee Profile ID ---
  Future<void> _loadEmployeeId() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists && doc.data() != null) {
          employeeId.value = doc.data()?['employeeId'] as String? ?? 'EMP-000';
        }
      }
    } catch (e) {
      debugPrint('Error loading employee ID: $e');
    }
  }

  // --- Fetch today's check-in time ---
  Future<void> _loadTodayCheckIn() async {
    isLoadingCheckIn.value = true;
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final dateKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final snapshot = await _firestore
          .collection('attendance')
          .where('userId', isEqualTo: user.uid)
          .get();

      final todayDocs = snapshot.docs.where((doc) {
        return doc.data()['dateKey'] == dateKey;
      }).toList();

      if (todayDocs.isNotEmpty) {
        final data = todayDocs.first.data();
        final time = data['checkIn'] as String? ?? '--';
        checkInTime.value = time;
        hasCheckedIn.value = time.isNotEmpty && time != '--';
      } else {
        checkInTime.value = '--';
        hasCheckedIn.value = false;
      }
    } catch (e) {
      debugPrint('Error loading check-in time: $e');
      checkInTime.value = '--';
      hasCheckedIn.value = false;
    } finally {
      isLoadingCheckIn.value = false;
    }
  }

  // --- Draft Storage (Shared Preferences) ---
  Future<void> _loadDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      projectNameController.text = prefs.getString('draft_project_name') ?? '';
      taskDetailsController.text = prefs.getString('draft_task_details') ?? '';
      selectedStatus.value = prefs.getString('draft_task_status') ?? 'In Progress';
      selectedTaskId.value = prefs.getString('draft_selected_task_id');

      final String? logsJson = prefs.getString('draft_temp_logs');
      if (logsJson != null && logsJson.isNotEmpty) {
        final List<dynamic> decoded = json.decode(logsJson);
        tempLogs.value = decoded.map((item) => Map<String, dynamic>.from(item)).toList();
      }

      if (tempLogs.isNotEmpty || taskDetailsController.text.isNotEmpty) {
        Get.rawSnackbar(
          title: 'Draft Restored',
          message: 'Your unsaved progress has been loaded.',
          backgroundColor: const Color(0xFF1E293B),
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      debugPrint('Error loading draft: $e');
    }
  }

  Future<void> _saveDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('draft_project_name', projectNameController.text);
      await prefs.setString('draft_task_details', taskDetailsController.text);
      await prefs.setString('draft_task_status', selectedStatus.value);
      if (selectedTaskId.value != null) {
        await prefs.setString('draft_selected_task_id', selectedTaskId.value!);
      } else {
        await prefs.remove('draft_selected_task_id');
      }

      final String logsJson = json.encode(tempLogs.toList());
      await prefs.setString('draft_temp_logs', logsJson);
    } catch (e) {
      debugPrint('Error saving draft: $e');
    }
  }

  void _startDraftAutosave() {
    _draftTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (taskDetailsController.text.isNotEmpty || 
          projectNameController.text.isNotEmpty || 
          tempLogs.isNotEmpty) {
        _saveDraft();
      }
    });
  }

  Future<void> clearDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('draft_project_name');
      await prefs.remove('draft_task_details');
      await prefs.remove('draft_task_status');
      await prefs.remove('draft_selected_task_id');
      await prefs.remove('draft_temp_logs');

      projectNameController.clear();
      taskDetailsController.clear();
      selectedStatus.value = 'In Progress';
      selectedTaskId.value = null;
      startTime.value = null;
      endTime.value = null;
      tempLogs.clear();
      progressPercentage.value = 0.0;
    } catch (e) {
      debugPrint('Error clearing draft: $e');
    }
  }

  // --- Technical Term Sanitization ---
  String sanitizeMalayalamText(String text) {
    String output = text;
    final Map<String, String> technicalReplacements = {
      'ഫ്ലട്ടർ': 'Flutter',
      'ഫയർബേസ്': 'Firebase',
      'ഗെറ്റ്എക്സ്': 'GetX',
      'എപിഐ': 'API',
      'ഡാഷ്ബോർഡ്': 'Dashboard',
      'അറ്റൻഡൻസ്': 'Attendance',
      'ലോഗിൻ സ്ക്രീൻ': 'Login Screen',
      'ലോഗിൻ': 'Login',
      'ഫയർസ്റ്റോർ': 'Firestore',
      'ആൻഡ്രോയിഡ്': 'Android',
      'ഐഒഎസ്': 'iOS',
    };

    for (var entry in technicalReplacements.entries) {
      output = output.replaceAll(entry.key, entry.value);
    }
    return output;
  }

  // --- Speech to Text Controls ---
  void toggleRecording() async {
    if (isRecording.value) {
      await _speechService.stopListening();
      isRecording.value = false;
      soundLevel.value = 0.0;
      await translateSpeechToEnglish();
    } else {
      final initialized = await _speechService.initialize();
      if (!initialized) {
        Get.rawSnackbar(
          title: 'Microphone Unavailable',
          message: kIsWeb
              ? 'Allow microphone access in your browser and try again.'
              : 'Speech recognition is not available on this device.',
          backgroundColor: const Color(0xFFDC2626),
          duration: const Duration(seconds: 4),
        );
        return;
      }

      isRecording.value = true;
      await _speechService.startListening(
        onResult: (text, isFinal) async {
          final sanitized = sanitizeMalayalamText(text);
          taskDetailsController.text = sanitized;
          taskDetailsController.selection = TextSelection.fromPosition(
            TextPosition(offset: taskDetailsController.text.length),
          );
          if (isFinal) {
            isRecording.value = false;
            soundLevel.value = 0.0;
            await translateSpeechToEnglish();
          }
        },
        onSoundLevel: (level) {
          soundLevel.value = level;
        },
        onListeningStopped: () async {
          isRecording.value = false;
          soundLevel.value = 0.0;
          await translateSpeechToEnglish();
        },
        onError: (errorMsg) {
          isRecording.value = false;
          soundLevel.value = 0.0;
          Get.rawSnackbar(
            title: 'Speech Recognition Error',
            message: errorMsg,
            backgroundColor: const Color(0xFFDC2626),
            duration: const Duration(seconds: 4),
          );
        },
      );
    }
  }

  Future<void> translateSpeechToEnglish() async {
    final text = taskDetailsController.text.trim();
    if (text.isEmpty) return;

    if (!RegExp(r'[\u0D00-\u0D7F]').hasMatch(text)) {
      return;
    }

    isTranslating.value = true;
    try {
      final translation = await _aiService.translateMalayalamToEnglish(text);
      if (translation.isNotEmpty) {
        taskDetailsController.text = translation;
        taskDetailsController.selection = TextSelection.fromPosition(
          TextPosition(offset: taskDetailsController.text.length),
        );
      }
    } catch (e) {
      debugPrint('Speech translation failed: $e');
    } finally {
      isTranslating.value = false;
    }
  }

  // --- Pick time helper ---
  Future<void> pickTime(BuildContext context, bool isStart) async {
    final initial = isStart
        ? (startTime.value ?? TimeOfDay.now())
        : (endTime.value ?? TimeOfDay.now());

    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF3B82F6),
              onPrimary: Colors.white,
              surface: Color(0xFF1E293B),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      if (isStart) {
        startTime.value = picked;
      } else {
        endTime.value = picked;
      }
    }
  }

  // --- Staging Logs Operations ---
  void addLogToList() {
    if (selectedTaskId.value == null) {
      Get.rawSnackbar(
        title: 'Validation Error',
        message: 'Please select a task from the list.',
        backgroundColor: Colors.red.shade700,
      );
      return;
    }

    final isOther = selectedTaskId.value == 'other';
    final taskTitle = isOther
        ? projectNameController.text.trim()
        : employeeTasks.firstWhereOrNull((t) => t.taskId == selectedTaskId.value)?.taskTitle ?? '';

    if (isOther && taskTitle.isEmpty) {
      Get.rawSnackbar(
        title: 'Validation Error',
        message: 'Please enter a title for the unassigned task.',
        backgroundColor: Colors.red.shade700,
      );
      return;
    }

    if (startTime.value == null || endTime.value == null) {
      Get.rawSnackbar(
        title: 'Validation Error',
        message: 'Please select both Start and End times.',
        backgroundColor: Colors.red.shade700,
      );
      return;
    }

    final details = taskDetailsController.text.trim();
    if (details.isEmpty) {
      Get.rawSnackbar(
        title: 'Validation Error',
        message: 'Please enter the details of the task performed.',
        backgroundColor: Colors.red.shade700,
      );
      return;
    }

    // Add to staged list
    tempLogs.add({
      'taskId': isOther ? '' : selectedTaskId.value,
      'taskTitle': taskTitle,
      'projectName': isOther ? 'Other Task' : taskTitle,
      'startTime': formatTimeOfDay(startTime.value!),
      'endTime': formatTimeOfDay(endTime.value!),
      'taskDetails': details,
      'taskStatus': selectedStatus.value,
      'progressPercentage': progressPercentage.value,
    });

    // Reset inputs for next log
    selectedTaskId.value = null;
    projectNameController.clear();
    taskDetailsController.clear();
    startTime.value = null;
    endTime.value = null;
    selectedStatus.value = 'In Progress';
    progressPercentage.value = 0.0;

    _saveDraft();
  }

  void removeLogFromList(int index) {
    if (index >= 0 && index < tempLogs.length) {
      tempLogs.removeAt(index);
      _saveDraft();
    }
  }

  // --- Batch Submit Daily Update ---
  Future<void> submitDailyUpdate() async {
    if (!hasCheckedIn.value) {
      Get.rawSnackbar(
        title: 'Check-In Required',
        message: 'You must check in before submitting a task update.',
        backgroundColor: Colors.orange.shade700,
        duration: const Duration(seconds: 4),
      );
      return;
    }

    if (tempLogs.isEmpty) {
      Get.rawSnackbar(
        title: 'No Logs Added',
        message: 'Please add at least one work log entry.',
        backgroundColor: Colors.red.shade700,
      );
      return;
    }

    isSaving.value = true;
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final now = DateTime.now();
      final dateKey = DateFormat('yyyy-MM-dd').format(now);
      final displayDate = DateFormat('MMM dd, yyyy').format(now);

      // --- Batch Write 1: Individual daily_updates ---
      final batch = _firestore.batch();
      for (final log in tempLogs) {
        final ref = _firestore.collection('daily_updates').doc();
        batch.set(ref, {
          'employeeId': employeeId.value,
          'userId': user.uid,
          'projectName': log['projectName'],
          'taskTitle': log['taskTitle'],
          'taskDetails': log['taskDetails'],
          'taskStatus': log['taskStatus'],
          'startTime': log['startTime'],
          'endTime': log['endTime'],
          'taskId': log['taskId'],
          'progressPercentage': log['progressPercentage'],
          'createdAt': FieldValue.serverTimestamp(),
          'dateKey': dateKey,
        });
      }
      await batch.commit();

      // --- Batch Write 2: Update specific Tasks & Log activities ---
      final WorkTaskController activityController;
      if (Get.isRegistered<WorkTaskController>()) {
        activityController = Get.find<WorkTaskController>();
      } else {
        activityController = Get.put(WorkTaskController());
      }

      for (final log in tempLogs) {
        final String tId = log['taskId'] ?? '';
        if (tId.isNotEmpty) {
          final taskDoc = await _firestore.collection('tasks').doc(tId).get();
          if (taskDoc.exists) {
            final taskData = taskDoc.data()!;
            final currentStatus = taskData['status'] as String? ?? 'Pending';
            final double progress = (log['progressPercentage'] as num? ?? 0.0).toDouble();
            
            final newStatus = progress >= 100.0
                ? 'Completed'
                : (currentStatus == 'Pending' ? 'In Progress' : currentStatus);

            await _firestore.collection('tasks').doc(tId).update({
              'progress': progress,
              'status': newStatus,
              'updatedAt': FieldValue.serverTimestamp(),
            });

            // Log activity
            await activityController.logTaskActivity(
              tId,
              'Daily Update Submitted',
              'Staged Daily Update (${progress.toInt()}%): ${log['taskDetails']} (${log['startTime']} - ${log['endTime']})',
            );

            // Notify Assigning Admin
            final assignedBy = taskData['assignedBy'] as String?;
            if (assignedBy != null && assignedBy.isNotEmpty) {
              await Get.find<NotificationService>().sendNotification(
                targetUid: assignedBy,
                title: 'Daily Task Update Submitted 🔔',
                body: 'Employee submitted daily update for "${taskData['taskTitle']}"',
                type: 'daily_update_submitted',
              );
            }
          }
        }
      }

      // --- Batch Write 3: Compile into daily attendance record ---
      // Generate standard details for backward-compatibility display
      final firstLog = tempLogs.first;
      final overallProject = firstLog['projectName'] as String? ?? '--';
      final overallStatus = tempLogs.last['taskStatus'] as String? ?? 'In Progress';
      
      final StringBuffer detailsBuffer = StringBuffer();
      for (final log in tempLogs) {
        detailsBuffer.writeln('[${log['startTime']} - ${log['endTime']}] ${log['taskTitle']}: ${log['taskDetails']}');
      }

      // Structured array representation for modern grouped dashboard
      final List<Map<String, dynamic>> structuredUpdates = tempLogs.map((log) => {
        'projectName': log['projectName'] ?? 'Other Task',
        'taskTitle': log['taskTitle'] ?? '',
        'taskDetails': log['taskDetails'] ?? '',
        'taskStatus': log['taskStatus'] ?? 'In Progress',
        'startTime': log['startTime'] ?? '',
        'endTime': log['endTime'] ?? '',
        'taskId': log['taskId'] ?? '',
        'progressPercentage': log['progressPercentage'] ?? 0.0,
      }).toList();

      final attendanceSnapshot = await _firestore
          .collection('attendance')
          .where('userId', isEqualTo: user.uid)
          .get();

      final todayDocs = attendanceSnapshot.docs.where((doc) {
        return doc.data()['dateKey'] == dateKey;
      }).toList();

      if (todayDocs.isNotEmpty) {
        final docId = todayDocs.first.id;
        await _firestore.collection('attendance').doc(docId).update({
          'projectName': overallProject,
          'taskDetails': detailsBuffer.toString().trim(),
          'taskStatus': overallStatus,
          'workUpdates': structuredUpdates,
          'taskUpdatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        await _firestore.collection('attendance').add({
          'userId': user.uid,
          'employeeId': employeeId.value,
          'name': user.displayName ?? 'Employee',
          'dateKey': dateKey,
          'date': displayDate,
          'checkIn': '--',
          'checkOut': '--',
          'location': '--',
          'checkInTimestamp': null,
          'workedHours': '00h 00m 00s',
          'projectName': overallProject,
          'taskDetails': detailsBuffer.toString().trim(),
          'taskStatus': overallStatus,
          'workUpdates': structuredUpdates,
          'taskUpdatedAt': FieldValue.serverTimestamp(),
        });
      }

      // Synchronize variables in EmployeeDashboardController
      if (Get.isRegistered<EmployeeDashboardController>()) {
        final dashController = Get.find<EmployeeDashboardController>();
        dashController.projectNameController.text = overallProject;
        dashController.taskDetailsController.text = detailsBuffer.toString().trim();
        dashController.selectedTaskStatus.value = overallStatus;
        dashController.refreshData(); // Refresh logs grid
      }

      await clearDraft();

      Get.back(); // Return to dashboard
      Get.rawSnackbar(
        title: 'Task Updates Saved',
        message: 'Successfully submitted ${tempLogs.length} updates.',
        backgroundColor: Colors.green.shade700,
      );

    } catch (e) {
      debugPrint('Error saving daily task updates: $e');
      Get.rawSnackbar(
        title: 'Error',
        message: 'Failed to submit updates: ${e.toString()}',
        backgroundColor: Colors.red.shade700,
      );
    } finally {
      isSaving.value = false;
    }
  }

  void _checkConnectivity() {
    isOffline.value = false;
  }

  String formatTimeOfDay(TimeOfDay tod) {
    final hour = tod.hourOfPeriod == 0 ? 12 : tod.hourOfPeriod;
    final minute = tod.minute.toString().padLeft(2, '0');
    final period = tod.period == DayPeriod.am ? 'AM' : 'PM';
    return '${hour.toString().padLeft(2, '0')}:$minute $period';
  }
}
