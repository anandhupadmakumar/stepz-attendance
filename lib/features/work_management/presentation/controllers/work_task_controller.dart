import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/task_model.dart';
import '../../models/company_model.dart';
import '../../models/project_model.dart';
import '../../../../core/services/notification_service.dart';

class WorkTaskController extends GetxController {
  final bool isTesting;
  late final FirebaseFirestore _firestore;
  late final FirebaseAuth _auth;

  WorkTaskController({this.isTesting = false}) {
    if (!isTesting) {
      _firestore = FirebaseFirestore.instance;
      _auth = FirebaseAuth.instance;
    }
  }

  // --- ASSIGN WORK FORM STATES ---
  final assignFormKey = GlobalKey<FormState>();
  final taskTitleController = TextEditingController();
  final taskDetailsController = TextEditingController();
  final acceptanceCriteriaController = TextEditingController();
  final estimatedHoursController = TextEditingController();
  final remarksController = TextEditingController();

  final RxString selectedCompanyId = ''.obs;
  final RxString selectedProjectId = ''.obs;
  final RxList<String> selectedEmployeeUids = <String>[].obs;
  final RxString selectedTaskType = 'Feature Development'.obs;
  final RxString selectedPriority = 'Medium'.obs;
  final RxString selectedDependency = 'None'.obs;
  final RxString selectedStatus = 'Pending'.obs;
  final Rx<DateTime?> startDate = Rx<DateTime?>(null);
  final Rx<DateTime?> dueDate = Rx<DateTime?>(null);
  final RxList<String> attachmentNames =
      <String>[].obs; // local simulated attachments

  // Dropdown lists
  final RxList<CompanyModel> companies = <CompanyModel>[].obs;
  final RxList<ProjectModel> allProjects = <ProjectModel>[].obs;
  final RxList<ProjectModel> filteredProjects = <ProjectModel>[].obs;
  final RxList<Map<String, dynamic>> employeesList =
      <Map<String, dynamic>>[].obs; // {uid, name, employeeId}

  // --- EMPLOYEE MY TASKS STATES ---
  final RxList<TaskModel> myTasks = <TaskModel>[].obs;
  final RxList<TaskModel> allAdminTasks = <TaskModel>[].obs;
  final RxBool isLoadingTasks = false.obs;

  // --- DETAIL VIEW STATES ---
  final commentController = TextEditingController();
  final RxList<Map<String, dynamic>> taskComments =
      <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> taskActivity =
      <Map<String, dynamic>>[].obs;
  final RxBool isLoadingComments = false.obs;

  // --- REPORTS & FILTER STATES ---
  final RxString selectedReportRange =
      'Month'.obs; // Today, Weekly, Monthly, Custom
  final Rx<DateTimeRange?> reportCustomDateRange = Rx<DateTimeRange?>(null);
  final RxInt reportAssigned = 0.obs;
  final RxInt reportCompleted = 0.obs;
  final RxInt reportPending = 0.obs;
  final RxInt reportOverdue = 0.obs;
  final RxList<Map<String, dynamic>> employeeProductivity =
      <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> projectProgress =
      <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> companyDistribution =
      <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    if (!isTesting) {
      _loadInitialData();
      _loadDraft();
    }
  }

  @override
  void onClose() {
    taskTitleController.dispose();
    taskDetailsController.dispose();
    acceptanceCriteriaController.dispose();
    estimatedHoursController.dispose();
    remarksController.dispose();
    commentController.dispose();
    super.onClose();
  }

  // --- INITIAL LOADING ---
  Future<void> _loadInitialData() async {
    isLoadingTasks.value = true;
    try {
      await fetchDropdownData();
      await fetchTasks();
      updateReportMetrics();
    } catch (e) {
      debugPrint("Error loading work task initial data: $e");
    } finally {
      isLoadingTasks.value = false;
    }
  }

  Future<void> fetchDropdownData() async {
    try {
      // 1. Fetch Companies
      final compSnap = await _firestore
          .collection('companies')
          .where('status', isEqualTo: 'Active')
          .get();
      companies.assignAll(
        compSnap.docs
            .map((doc) => CompanyModel.fromMap(doc.data(), doc.id))
            .toList(),
      );

      // 2. Fetch Projects
      final projSnap = await _firestore
          .collection('projects')
          .where('status', isEqualTo: 'Active')
          .get();
      allProjects.assignAll(
        projSnap.docs
            .map((doc) => ProjectModel.fromMap(doc.data(), doc.id))
            .toList(),
      );

      // 3. Fetch Employees (Users collection)
      final userSnap = await _firestore.collection('users').get();
      final List<Map<String, dynamic>> emps = [];
      for (var doc in userSnap.docs) {
        final data = doc.data();
        if (data['role'] != 'admin') {
          emps.add({
            'uid': doc.id,
            'name': data['name'] ?? data['email']?.split('@')[0] ?? 'Employee',
            'employeeId': data['employeeId'] ?? 'EMP-000',
          });
        }
      }
      employeesList.assignAll(emps);

      // Setup company selection bindings
      if (companies.isNotEmpty) {
        selectedCompanyId.value = companies.first.companyId;
        filterProjectsByCompany(selectedCompanyId.value);
      }
    } catch (e) {
      debugPrint("Error loading dropdown data: $e");
    }
  }

  void filterProjectsByCompany(String companyId) {
    selectedCompanyId.value = companyId;
    final list = allProjects.where((p) => p.companyId == companyId).toList();
    filteredProjects.assignAll(list);
    if (filteredProjects.isNotEmpty) {
      selectedProjectId.value = filteredProjects.first.projectId;
    } else {
      selectedProjectId.value = '';
    }
  }

  // --- AUTOSAVE DRAFT ---
  Future<void> _loadDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      taskTitleController.text = prefs.getString('draft_task_title') ?? '';
      taskDetailsController.text = prefs.getString('draft_task_details') ?? '';
      acceptanceCriteriaController.text =
          prefs.getString('draft_acceptance') ?? '';
      estimatedHoursController.text = prefs.getString('draft_hours') ?? '';
      remarksController.text = prefs.getString('draft_remarks') ?? '';
    } catch (e) {
      debugPrint("Error loading task draft: $e");
    }
  }

  Future<void> saveDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('draft_task_title', taskTitleController.text);
      await prefs.setString('draft_task_details', taskDetailsController.text);
      await prefs.setString(
        'draft_acceptance',
        acceptanceCriteriaController.text,
      );
      await prefs.setString('draft_hours', estimatedHoursController.text);
      await prefs.setString('draft_remarks', remarksController.text);

      Get.rawSnackbar(
        title: 'Draft Saved',
        message: 'Your task assignment details have been autosaved.',
        backgroundColor: const Color(0xFF1E293B),
      );
    } catch (e) {
      debugPrint("Error saving task draft: $e");
    }
  }

  Future<void> clearDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('draft_task_title');
      await prefs.remove('draft_task_details');
      await prefs.remove('draft_acceptance');
      await prefs.remove('draft_hours');
      await prefs.remove('draft_remarks');

      taskTitleController.clear();
      taskDetailsController.clear();
      acceptanceCriteriaController.clear();
      estimatedHoursController.clear();
      remarksController.clear();
      selectedEmployeeUids.clear();
      startDate.value = null;
      dueDate.value = null;
      attachmentNames.clear();
    } catch (e) {
      debugPrint("Error clearing draft: $e");
    }
  }

  // --- FETCH TASKS ---
  Future<void> fetchTasks() async {
    isLoadingTasks.value = true;
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // 1. Determine user role
      final doc = await _firestore.collection('users').doc(user.uid).get();
      final String role = doc.data()?['role'] ?? 'employee';

      // 2. Fetch Tasks
      final snapshot = await _firestore
          .collection('tasks')
          .orderBy('assignedAt', descending: true)
          .get();
      final list = snapshot.docs
          .map((doc) => TaskModel.fromMap(doc.data(), doc.id))
          .toList();

      allAdminTasks.assignAll(list);

      if (role == 'admin') {
        // Admins see all tasks
        myTasks.assignAll(list);
      } else {
        // Employees see only tasks assigned to them
        final employeeTasks = list
            .where((t) => t.employeeIds.contains(user.uid))
            .toList();
        myTasks.assignAll(employeeTasks);
      }
    } catch (e) {
      debugPrint("Error fetching tasks: $e");
    } finally {
      isLoadingTasks.value = false;
    }
  }

  // --- CREATE/ASSIGN TASK ---
  Future<void> assignTask() async {
    if (!assignFormKey.currentState!.validate()) return;
    if (selectedCompanyId.value.isEmpty || selectedProjectId.value.isEmpty) {
      Get.rawSnackbar(
        title: 'Validation Error',
        message: 'Company and Project are required.',
        backgroundColor: Colors.red.shade700,
      );
      return;
    }
    if (selectedEmployeeUids.isEmpty) {
      Get.rawSnackbar(
        title: 'Validation Error',
        message: 'Assign at least one employee.',
        backgroundColor: Colors.red.shade700,
      );
      return;
    }
    if (startDate.value == null || dueDate.value == null) {
      Get.rawSnackbar(
        title: 'Validation Error',
        message: 'Start Date and Due Date are required.',
        backgroundColor: Colors.red.shade700,
      );
      return;
    }

    isLoadingTasks.value = true;
    try {
      final user = _auth.currentUser;
      final assignedBy = user?.uid ?? 'Admin';

      final task = TaskModel(
        taskId: '',
        companyId: selectedCompanyId.value,
        projectId: selectedProjectId.value,
        employeeIds: selectedEmployeeUids.toList(),
        taskType: selectedTaskType.value,
        priority: selectedPriority.value,
        taskTitle: taskTitleController.text.trim(),
        taskDetails: taskDetailsController.text.trim(),
        acceptanceCriteria: acceptanceCriteriaController.text.trim(),
        dependencies: selectedDependency.value,
        estimatedHours: double.tryParse(estimatedHoursController.text) ?? 0.0,
        progress: 0.0,
        status: 'Pending',
        remarks: remarksController.text.trim(),
        attachmentUrls: attachmentNames
            .toList(), // simulated file attachment paths
        startDate: startDate.value,
        dueDate: dueDate.value,
        assignedBy: assignedBy,
        assignedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final docRef = await _firestore.collection('tasks').add(task.toMap());
      final newId = docRef.id;

      // Log activity
      await logTaskActivity(
        newId,
        'Task Created',
        'Task assigned by administrator.',
      );

      // Notify employees
      for (var empUid in selectedEmployeeUids) {
        await Get.find<NotificationService>().sendNotification(
          targetUid: empUid,
          title: 'New Task Assigned 🚀',
          body: 'You have been assigned to: ${task.taskTitle}',
          type: 'task_assigned',
        );
      }

      await clearDraft();
      await fetchTasks();
      updateReportMetrics();
      Get.back();
      Get.rawSnackbar(
        title: 'Task Assigned',
        message: 'Successfully assigned task "${task.taskTitle}"',
        backgroundColor: Colors.green.shade700,
      );
    } catch (e) {
      Get.rawSnackbar(
        title: 'Error Assigning Task',
        message: e.toString(),
        backgroundColor: Colors.red.shade700,
      );
    } finally {
      isLoadingTasks.value = false;
    }
  }

  // --- UPDATE TASK STATE (EMPLOYEE) ---
  Future<void> updateTaskStatus(String taskId, String newStatus) async {
    try {
      final taskDoc = await _firestore.collection('tasks').doc(taskId).get();
      if (!taskDoc.exists) return;

      final data = taskDoc.data()!;
      final double progress = newStatus == 'Completed'
          ? 100.0
          : (data['progress'] ?? 0.0).toDouble();

      await _firestore.collection('tasks').doc(taskId).update({
        'status': newStatus,
        'progress': progress,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await logTaskActivity(
        taskId,
        'Status Changed',
        'Task status updated to $newStatus.',
      );

      // Send notifications to assigner/admin
      final assignedBy = data['assignedBy'] as String?;
      if (assignedBy != null && assignedBy.isNotEmpty) {
        await Get.find<NotificationService>().sendNotification(
          targetUid: assignedBy,
          title: 'Task Update: $newStatus',
          body: 'Task "${data['taskTitle']}" status is now $newStatus.',
          type: 'task_updated',
        );
      }

      await fetchTasks();
      updateReportMetrics();
      Get.rawSnackbar(
        title: 'Task Status Updated',
        message: 'Status set to $newStatus successfully.',
        backgroundColor: Colors.green.shade700,
      );
    } catch (e) {
      debugPrint("Error updating task status: $e");
    }
  }

  Future<void> saveProgressUpdate(
    String taskId,
    double progressPercent,
    String summary,
    double hours,
  ) async {
    try {
      final taskDoc = await _firestore.collection('tasks').doc(taskId).get();
      if (!taskDoc.exists) return;

      final data = taskDoc.data()!;
      final newStatus = progressPercent >= 100.0 ? 'Completed' : 'In Progress';

      await _firestore.collection('tasks').doc(taskId).update({
        'progress': progressPercent,
        'status': newStatus,
        'remarks': summary,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Write to activity log
      await logTaskActivity(
        taskId,
        'Progress Update',
        'Updated progress to ${progressPercent.toInt()}% ($hours hrs worked): $summary',
      );

      // Add as comment
      if (summary.trim().isNotEmpty) {
        await addTaskComment(
          taskId,
          'Progress Update (${progressPercent.toInt()}%): $summary',
        );
      }

      final assignedBy = data['assignedBy'] as String?;
      if (assignedBy != null) {
        await Get.find<NotificationService>().sendNotification(
          targetUid: assignedBy,
          title: 'Task Progress: ${progressPercent.toInt()}%',
          body: 'Task "${data['taskTitle']}" updated: $summary',
          type: 'task_updated',
        );
      }

      await fetchTasks();
      updateReportMetrics();
      Get.back();
      Get.rawSnackbar(
        title: 'Progress Saved',
        message: 'Task progress updated successfully.',
        backgroundColor: Colors.green.shade700,
      );
    } catch (e) {
      debugPrint("Error saving progress: $e");
    }
  }

  // --- REAL-TIME COMMENTS ---
  Future<void> fetchComments(String taskId) async {
    isLoadingComments.value = true;
    try {
      // 1. Fetch Comments
      final commentsSnap = await _firestore
          .collection('task_comments')
          .where('taskId', isEqualTo: taskId)
          .orderBy('createdAt', descending: false)
          .get();

      final listComments = commentsSnap.docs.map((doc) => doc.data()).toList();
      taskComments.assignAll(listComments);

      // 2. Fetch Activity Timeline
      final activitySnap = await _firestore
          .collection('task_activity')
          .where('taskId', isEqualTo: taskId)
          .orderBy('createdAt', descending: true)
          .get();

      final listActivity = activitySnap.docs.map((doc) => doc.data()).toList();
      taskActivity.assignAll(listActivity);
    } catch (e) {
      debugPrint("Error loading comments: $e");
    } finally {
      isLoadingComments.value = false;
    }
  }

  Future<void> addTaskComment(String taskId, String commentText) async {
    if (commentText.trim().isEmpty) return;

    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userName =
          userDoc.data()?['name'] ?? user.email?.split('@')[0] ?? 'User';

      final comment = {
        'taskId': taskId,
        'userId': user.uid,
        'userName': userName,
        'commentText': commentText.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('task_comments').add(comment);

      commentController.clear();
      await fetchComments(taskId);
    } catch (e) {
      debugPrint("Error adding comment: $e");
    }
  }

  Future<void> logTaskActivity(
    String taskId,
    String action,
    String description,
  ) async {
    try {
      final activity = {
        'taskId': taskId,
        'action': action,
        'description': description,
        'createdAt': FieldValue.serverTimestamp(),
      };
      await _firestore.collection('task_activity').add(activity);
    } catch (e) {
      debugPrint("Error writing activity log: $e");
    }
  }

  // --- ADMIN REPORTS METRICS ---
  void updateReportMetrics() {
    final now = DateTime.now();

    // Filter tasks based on selected range
    List<TaskModel> list = allAdminTasks.toList();
    if (selectedReportRange.value != 'All') {
      DateTime limitDate;
      if (selectedReportRange.value == 'Today') {
        limitDate = DateTime(now.year, now.month, now.day);
      } else if (selectedReportRange.value == 'Weekly') {
        limitDate = now.subtract(const Duration(days: 7));
      } else if (selectedReportRange.value == 'Monthly') {
        limitDate = DateTime(now.year, now.month - 1, now.day);
      } else {
        // Custom
        limitDate =
            reportCustomDateRange.value?.start ??
            now.subtract(const Duration(days: 30));
      }

      list = list.where((t) {
        if (t.startDate == null) return false;
        if (selectedReportRange.value == 'Custom' &&
            reportCustomDateRange.value != null) {
          return t.startDate!.isAfter(reportCustomDateRange.value!.start) &&
              t.startDate!.isBefore(reportCustomDateRange.value!.end);
        }
        return t.startDate!.isAfter(limitDate);
      }).toList();
    }

    // Calculations
    reportAssigned.value = list.length;
    reportCompleted.value = list.where((t) => t.status == 'Completed').length;
    reportPending.value = list
        .where(
          (t) =>
              t.status == 'Pending' ||
              t.status == 'In Progress' ||
              t.status == 'Review',
        )
        .length;

    // Overdue checks
    reportOverdue.value = list.where((t) {
      if (t.status == 'Completed' || t.dueDate == null) return false;
      return t.dueDate!.isBefore(now);
    }).length;

    // Company-wise report distribution
    final Map<String, int> compMap = {};
    for (var task in list) {
      compMap[task.companyId] = (compMap[task.companyId] ?? 0) + 1;
    }
    companyDistribution.assignAll(
      compMap.entries
          .map(
            (entry) => {
              'companyName': getCompanyName(entry.key),
              'count': entry.value,
            },
          )
          .toList(),
    );

    // Project progress calculations
    final Map<String, List<double>> projMap = {};
    for (var task in list) {
      projMap.putIfAbsent(task.projectId, () => []).add(task.progress);
    }
    projectProgress.assignAll(
      projMap.entries.map((entry) {
        final sum = entry.value.reduce((a, b) => a + b);
        final avg = sum / entry.value.length;
        final proj = allProjects.firstWhereOrNull(
          (p) => p.projectId == entry.key,
        );
        return {
          'projectName': proj?.projectName ?? 'Unknown Project',
          'progress': avg,
          'taskCount': entry.value.length,
        };
      }).toList(),
    );

    // Employee performance metric (completed / total assigned tasks)
    final Map<String, Map<String, int>> empMap =
        {}; // uid -> {'total': 0, 'completed': 0}
    for (var task in list) {
      for (var empUid in task.employeeIds) {
        empMap.putIfAbsent(empUid, () => {'total': 0, 'completed': 0});
        empMap[empUid]!['total'] = empMap[empUid]!['total']! + 1;
        if (task.status == 'Completed') {
          empMap[empUid]!['completed'] = empMap[empUid]!['completed']! + 1;
        }
      }
    }
    employeeProductivity.assignAll(
      empMap.entries.map((entry) {
        final empInfo = employeesList.firstWhereOrNull(
          (e) => e['uid'] == entry.key,
        );
        final total = entry.value['total'] ?? 1;
        final completed = entry.value['completed'] ?? 0;
        final rate = (completed / total) * 100.0;
        return {
          'name': empInfo?['name'] ?? 'Unknown Employee',
          'employeeId': empInfo?['employeeId'] ?? 'EMP-000',
          'totalTasks': total,
          'completedTasks': completed,
          'rate': rate,
        };
      }).toList(),
    );
  }

  String getCompanyName(String companyId) {
    final comp = companies.firstWhereOrNull((c) => c.companyId == companyId);
    return comp?.companyName ?? 'Unknown Company';
  }

  String getProjectName(String projectId) {
    final proj = allProjects.firstWhereOrNull((p) => p.projectId == projectId);
    return proj?.projectName ?? 'Unknown Project';
  }
}
