import 'package:cloud_firestore/cloud_firestore.dart';

class TaskUpdateModel {
  final String updateId;
  final String taskId;
  final String employeeId;
  final String originalMalayalam;
  final String englishTranslation;
  final String professionalSummary;
  final double progressPercentage;
  final DateTime? createdAt;

  TaskUpdateModel({
    required this.updateId,
    required this.taskId,
    required this.employeeId,
    required this.originalMalayalam,
    required this.englishTranslation,
    required this.professionalSummary,
    required this.progressPercentage,
    this.createdAt,
  });

  factory TaskUpdateModel.fromMap(Map<String, dynamic> map, String id) {
    return TaskUpdateModel(
      updateId: id,
      taskId: map['taskId'] ?? '',
      employeeId: map['employeeId'] ?? '',
      originalMalayalam: map['originalMalayalam'] ?? '',
      englishTranslation: map['englishTranslation'] ?? '',
      professionalSummary: map['professionalSummary'] ?? '',
      progressPercentage: (map['progressPercentage'] ?? 0.0).toDouble(),
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'taskId': taskId,
      'employeeId': employeeId,
      'originalMalayalam': originalMalayalam,
      'englishTranslation': englishTranslation,
      'professionalSummary': professionalSummary,
      'progressPercentage': progressPercentage,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }
}
