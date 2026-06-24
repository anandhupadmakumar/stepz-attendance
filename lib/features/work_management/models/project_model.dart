import 'package:cloud_firestore/cloud_firestore.dart';

class ProjectModel {
  final String projectId;
  final String companyId;
  final String projectName;
  final String projectCode;
  final String clientName;
  final String description;
  final String status; // 'Active', 'Completed', 'On Hold'
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ProjectModel({
    required this.projectId,
    required this.companyId,
    required this.projectName,
    required this.projectCode,
    required this.clientName,
    required this.description,
    required this.status,
    this.startDate,
    this.endDate,
    this.createdAt,
    this.updatedAt,
  });

  factory ProjectModel.fromMap(Map<String, dynamic> map, String id) {
    return ProjectModel(
      projectId: id,
      companyId: map['companyId'] ?? '',
      projectName: map['projectName'] ?? '',
      projectCode: map['projectCode'] ?? '',
      clientName: map['clientName'] ?? '',
      description: map['description'] ?? '',
      status: map['status'] ?? 'Active',
      startDate: map['startDate'] is Timestamp
          ? (map['startDate'] as Timestamp).toDate()
          : map['startDate'] != null
          ? DateTime.tryParse(map['startDate'].toString())
          : null,
      endDate: map['endDate'] is Timestamp
          ? (map['endDate'] as Timestamp).toDate()
          : map['endDate'] != null
          ? DateTime.tryParse(map['endDate'].toString())
          : null,
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString())
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
      'projectName': projectName,
      'projectCode': projectCode,
      'clientName': clientName,
      'description': description,
      'status': status,
      'startDate': startDate != null ? Timestamp.fromDate(startDate!) : null,
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  ProjectModel copyWith({
    String? projectId,
    String? companyId,
    String? projectName,
    String? projectCode,
    String? clientName,
    String? description,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProjectModel(
      projectId: projectId ?? this.projectId,
      companyId: companyId ?? this.companyId,
      projectName: projectName ?? this.projectName,
      projectCode: projectCode ?? this.projectCode,
      clientName: clientName ?? this.clientName,
      description: description ?? this.description,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
