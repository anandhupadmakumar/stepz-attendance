import 'package:cloud_firestore/cloud_firestore.dart';

class TaskModel {
  final String taskId;
  final String companyId;
  final String projectId;
  final List<String> employeeIds;
  final String taskType;
  final String priority; // 'Low', 'Medium', 'High', 'Critical'
  final String taskTitle;
  final String taskDetails;
  final String acceptanceCriteria;
  final String dependencies; // 'None', 'Waiting for Design', etc.
  final double estimatedHours;
  final double progress; // 0 to 100
  final String status; // 'Pending', 'In Progress', 'Review', 'Completed'
  final String remarks;
  final List<String> attachmentUrls;
  final DateTime? startDate;
  final DateTime? dueDate;
  final String assignedBy;
  final DateTime? assignedAt;
  final DateTime? updatedAt;

  TaskModel({
    required this.taskId,
    required this.companyId,
    required this.projectId,
    required this.employeeIds,
    required this.taskType,
    required this.priority,
    required this.taskTitle,
    required this.taskDetails,
    required this.acceptanceCriteria,
    required this.dependencies,
    required this.estimatedHours,
    required this.progress,
    required this.status,
    required this.remarks,
    required this.attachmentUrls,
    this.startDate,
    this.dueDate,
    required this.assignedBy,
    this.assignedAt,
    this.updatedAt,
  });

  factory TaskModel.fromMap(Map<String, dynamic> map, String id) {
    return TaskModel(
      taskId: id,
      companyId: map['companyId'] ?? '',
      projectId: map['projectId'] ?? '',
      employeeIds: List<String>.from(map['employeeIds'] ?? []),
      taskType: map['taskType'] ?? '',
      priority: map['priority'] ?? 'Medium',
      taskTitle: map['taskTitle'] ?? '',
      taskDetails: map['taskDetails'] ?? '',
      acceptanceCriteria: map['acceptanceCriteria'] ?? '',
      dependencies: map['dependencies'] ?? 'None',
      estimatedHours: (map['estimatedHours'] ?? 0.0).toDouble(),
      progress: (map['progress'] ?? 0.0).toDouble(),
      status: map['status'] ?? 'Pending',
      remarks: map['remarks'] ?? '',
      attachmentUrls: List<String>.from(map['attachmentUrls'] ?? []),
      startDate: map['startDate'] is Timestamp
          ? (map['startDate'] as Timestamp).toDate()
          : map['startDate'] != null
          ? DateTime.tryParse(map['startDate'].toString())
          : null,
      dueDate: map['dueDate'] is Timestamp
          ? (map['dueDate'] as Timestamp).toDate()
          : map['dueDate'] != null
          ? DateTime.tryParse(map['dueDate'].toString())
          : null,
      assignedBy: map['assignedBy'] ?? '',
      assignedAt: map['assignedAt'] is Timestamp
          ? (map['assignedAt'] as Timestamp).toDate()
          : map['assignedAt'] != null
          ? DateTime.tryParse(map['assignedAt'].toString())
          : null,
      updatedAt: map['updatedAt'] is Timestamp
          ? (map['updatedAt'] as Timestamp).toDate()
          : map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'companyId': companyId,
      'projectId': projectId,
      'employeeIds': employeeIds,
      'taskType': taskType,
      'priority': priority,
      'taskTitle': taskTitle,
      'taskDetails': taskDetails,
      'acceptanceCriteria': acceptanceCriteria,
      'dependencies': dependencies,
      'estimatedHours': estimatedHours,
      'progress': progress,
      'status': status,
      'remarks': remarks,
      'attachmentUrls': attachmentUrls,
      'startDate': startDate != null ? Timestamp.fromDate(startDate!) : null,
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'assignedBy': assignedBy,
      'assignedAt': assignedAt != null
          ? Timestamp.fromDate(assignedAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  TaskModel copyWith({
    String? companyId,
    String? projectId,
    List<String>? employeeIds,
    String? taskType,
    String? priority,
    String? taskTitle,
    String? taskDetails,
    String? acceptanceCriteria,
    String? dependencies,
    double? estimatedHours,
    double? progress,
    String? status,
    String? remarks,
    List<String>? attachmentUrls,
    DateTime? startDate,
    DateTime? dueDate,
    String? assignedBy,
    DateTime? assignedAt,
    DateTime? updatedAt,
  }) {
    return TaskModel(
      taskId: taskId,
      companyId: companyId ?? this.companyId,
      projectId: projectId ?? this.projectId,
      employeeIds: employeeIds ?? this.employeeIds,
      taskType: taskType ?? this.taskType,
      priority: priority ?? this.priority,
      taskTitle: taskTitle ?? this.taskTitle,
      taskDetails: taskDetails ?? this.taskDetails,
      acceptanceCriteria: acceptanceCriteria ?? this.acceptanceCriteria,
      dependencies: dependencies ?? this.dependencies,
      estimatedHours: estimatedHours ?? this.estimatedHours,
      progress: progress ?? this.progress,
      status: status ?? this.status,
      remarks: remarks ?? this.remarks,
      attachmentUrls: attachmentUrls ?? this.attachmentUrls,
      startDate: startDate ?? this.startDate,
      dueDate: dueDate ?? this.dueDate,
      assignedBy: assignedBy ?? this.assignedBy,
      assignedAt: assignedAt ?? this.assignedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
