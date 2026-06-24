import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/services/speech_service.dart';
import '../../../../core/services/ai_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../models/task_model.dart';
import 'work_task_controller.dart';

class TaskDailyUpdateController extends GetxController {
  final String? initialTaskId;
  TaskDailyUpdateController({this.initialTaskId});

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final SpeechService _speechService = SpeechService();
  final AIService _aiService = AIService();

  // Tasks list and selected ID
  final RxList<TaskModel> employeeTasks = <TaskModel>[].obs;
  final RxnString selectedTaskId = RxnString();

  // Start Time & End Time
  final Rx<TimeOfDay?> startTime = Rx<TimeOfDay?>(null);
  final Rx<TimeOfDay?> endTime = Rx<TimeOfDay?>(null);

  // Controllers for text editing
  final updateTextController = TextEditingController();
  final originalMalayalamController = TextEditingController();
  final englishTranslationController = TextEditingController();

  // Reactive states
  final RxBool isRecording = false.obs;
  final RxDouble soundLevel = 0.0.obs;
  final RxBool isTranslating = false.obs;
  final RxBool isGeneratingSummary = false.obs;
  final RxBool isSaving = false.obs;
  final RxBool isLoadingTasks = false.obs;
  final RxDouble progressPercentage = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    selectedTaskId.value = initialTaskId;
    
    // Set initial progress when selected task changes
    selectedTaskId.listen((val) {
      if (val != null) {
        final task = employeeTasks.firstWhereOrNull((t) => t.taskId == val);
        if (task != null) {
          progressPercentage.value = task.progress;
        }
      } else {
        progressPercentage.value = 0.0;
      }
    });

    fetchEmployeeTasks();
  }

  @override
  void onClose() {
    _speechService.cancelListening();
    updateTextController.dispose();
    originalMalayalamController.dispose();
    englishTranslationController.dispose();
    super.onClose();
  }

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

      // Show tasks that are not completed
      employeeTasks.value = tasks.where((t) => t.status != 'Completed').toList();

      if (selectedTaskId.value != null) {
        final selectedTask = employeeTasks.firstWhereOrNull((t) => t.taskId == selectedTaskId.value);
        if (selectedTask != null) {
          progressPercentage.value = selectedTask.progress;
        }
      }
    } catch (e) {
      debugPrint("Error fetching employee tasks: $e");
    } finally {
      isLoadingTasks.value = false;
    }
  }

  // --- Speech To Text Malayalam ---
  void toggleRecording() async {
    if (isRecording.value) {
      await _speechService.stopListening();
      isRecording.value = false;
      soundLevel.value = 0.0;
      await processSpeechText();
    } else {
      final initialized = await _speechService.initialize();
      if (!initialized) {
        Get.rawSnackbar(
          title: 'Microphone Unavailable',
          message:
              'Speech recognition is not available or microphone permission is denied.',
          backgroundColor: Colors.red.shade700,
        );
        return;
      }

      isRecording.value = true;
      originalMalayalamController.clear();
      englishTranslationController.clear();
      updateTextController.clear();

      await _speechService.startListening(
        localeId: 'ml_IN', // Malayalam
        onResult: (text, isFinal) async {
          originalMalayalamController.text = text;
          if (isFinal) {
            isRecording.value = false;
            soundLevel.value = 0.0;
            await processSpeechText();
          }
        },
        onSoundLevel: (level) {
          soundLevel.value = level;
        },
        onListeningStopped: () async {
          isRecording.value = false;
          soundLevel.value = 0.0;
          await processSpeechText();
        },
        onError: (err) {
          isRecording.value = false;
          soundLevel.value = 0.0;
          Get.rawSnackbar(
            title: 'Speech Recognition Error',
            message: err,
            backgroundColor: Colors.red.shade700,
          );
        },
      );
    }
  }

  Future<void> processSpeechText() async {
    final text = originalMalayalamController.text.trim();
    if (text.isEmpty) return;

    isTranslating.value = true;
    try {
      final translation = await _aiService.translateMalayalamToEnglish(text);
      englishTranslationController.text = translation;

      isGeneratingSummary.value = true;
      final summary = await _aiService.generateProfessionalSummary(
        text,
        translation,
      );
      updateTextController.text = summary;
      
      // Move cursor to end of text
      updateTextController.selection = TextSelection.fromPosition(
        TextPosition(offset: updateTextController.text.length),
      );
    } catch (e) {
      debugPrint("Error processing speech through Gemini AI: $e");
      updateTextController.text = text; // Fallback to raw transcribed text
    } finally {
      isTranslating.value = false;
      isGeneratingSummary.value = false;
    }
  }

  // --- SUBMIT WORK STATUS UPDATE ---
  Future<void> submitDailyUpdate() async {
    final taskId = selectedTaskId.value;
    if (taskId == null || taskId.isEmpty) {
      Get.rawSnackbar(
        title: 'Validation Error',
        message: 'Please select a task from the dropdown.',
        backgroundColor: Colors.red.shade700,
      );
      return;
    }

    if (startTime.value == null || endTime.value == null) {
      Get.rawSnackbar(
        title: 'Validation Error',
        message: 'Please enter both Start Time and End Time.',
        backgroundColor: Colors.red.shade700,
      );
      return;
    }

    final updateText = updateTextController.text.trim();
    if (updateText.isEmpty) {
      Get.rawSnackbar(
        title: 'Validation Error',
        message: 'Please enter details or speak using the microphone.',
        backgroundColor: Colors.red.shade700,
      );
      return;
    }

    isSaving.value = true;
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // 1. Fetch user employee ID
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final empId = userDoc.data()?['employeeId'] ?? 'EMP-000';

      final startStr = _formatTimeOfDay(startTime.value!);
      final endStr = _formatTimeOfDay(endTime.value!);

      // 2. Write to task_updates collection
      final updateData = {
        'taskId': taskId,
        'employeeId': empId,
        'originalMalayalam': originalMalayalamController.text.trim(),
        'englishTranslation': englishTranslationController.text.trim(),
        'professionalSummary': updateText,
        'progressPercentage': progressPercentage.value,
        'startTime': startStr,
        'endTime': endStr,
        'createdAt': FieldValue.serverTimestamp(),
      };
      await _firestore.collection('task_updates').add(updateData);

      // 3. Update Tasks collection with new progress percentage and status
      final taskDoc = await _firestore.collection('tasks').doc(taskId).get();
      if (taskDoc.exists) {
        final taskData = taskDoc.data()!;
        final currentStatus = taskData['status'] as String? ?? 'Pending';
        final newStatus = progressPercentage.value >= 100.0
            ? 'Completed'
            : (currentStatus == 'Pending' ? 'In Progress' : currentStatus);

        await _firestore.collection('tasks').doc(taskId).update({
          'progress': progressPercentage.value,
          'status': newStatus,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // 4. Log task timeline activity
        final activityController = Get.find<WorkTaskController>();
        await activityController.logTaskActivity(
          taskId,
          'Daily Update Submitted',
          'Submitted Daily Update (${progressPercentage.value.toInt()}%): $updateText ($startStr - $endStr)',
        );

        // 5. Notify the assigning Admin
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

      Get.rawSnackbar(
        title: 'Daily Update Saved',
        message: 'Your update has been saved successfully.',
        backgroundColor: Colors.green.shade700,
      );

      // 6. Clear form inputs for the next entry
      clearForm();
      
      // Refresh task list to fetch current progress of other tasks
      await fetchEmployeeTasks();

    } catch (e) {
      Get.rawSnackbar(
        title: 'Error Saving Update',
        message: e.toString(),
        backgroundColor: Colors.red.shade700,
      );
    } finally {
      isSaving.value = false;
    }
  }

  void clearForm() {
    selectedTaskId.value = null;
    startTime.value = null;
    endTime.value = null;
    updateTextController.clear();
    originalMalayalamController.clear();
    englishTranslationController.clear();
    progressPercentage.value = 0.0;
  }

  String _formatTimeOfDay(TimeOfDay tod) {
    final hour = tod.hourOfPeriod == 0 ? 12 : tod.hourOfPeriod;
    final minute = tod.minute.toString().padLeft(2, '0');
    final period = tod.period == DayPeriod.am ? 'AM' : 'PM';
    return '${hour.toString().padLeft(2, '0')}:$minute $period';
  }
}
