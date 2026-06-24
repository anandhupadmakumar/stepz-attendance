import 'package:cloud_firestore/cloud_firestore.dart';

class CompanyModel {
  final String companyId;
  final String companyName;
  final String companyCode;
  final String contactPerson;
  final String email;
  final String phone;
  final String address;
  final String description;
  final String status; // 'Active' or 'Inactive'
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CompanyModel({
    required this.companyId,
    required this.companyName,
    required this.companyCode,
    required this.contactPerson,
    required this.email,
    required this.phone,
    required this.address,
    required this.description,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory CompanyModel.fromMap(Map<String, dynamic> map, String id) {
    return CompanyModel(
      companyId: id,
      companyName: map['companyName'] ?? '',
      companyCode: map['companyCode'] ?? '',
      contactPerson: map['contactPerson'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      address: map['address'] ?? '',
      description: map['description'] ?? '',
      status: map['status'] ?? 'Active',
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
      'companyName': companyName,
      'companyCode': companyCode,
      'contactPerson': contactPerson,
      'email': email,
      'phone': phone,
      'address': address,
      'description': description,
      'status': status,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  CompanyModel copyWith({
    String? companyId,
    String? companyName,
    String? companyCode,
    String? contactPerson,
    String? email,
    String? phone,
    String? address,
    String? description,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CompanyModel(
      companyId: companyId ?? this.companyId,
      companyName: companyName ?? this.companyName,
      companyCode: companyCode ?? this.companyCode,
      contactPerson: contactPerson ?? this.contactPerson,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      description: description ?? this.description,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
