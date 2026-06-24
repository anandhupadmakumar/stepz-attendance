import 'package:cloud_firestore/cloud_firestore.dart';

class HolidayModel {
  final String holidayId;
  final DateTime date;
  final String title;
  final String type; // "Public" | "Optional" | "Company Event"
  final String description;
  final String createdBy;
  final DateTime createdAt;

  HolidayModel({
    required this.holidayId,
    required this.date,
    required this.title,
    required this.type,
    this.description = '',
    this.createdBy = '',
    required this.createdAt,
  });

  /// Normalize a date to midnight (removes time component for comparisons)
  static DateTime normalize(DateTime d) =>
      DateTime(d.year, d.month, d.day);

  bool isSameDay(DateTime other) {
    final d = normalize(other);
    final s = normalize(date);
    return d.year == s.year && d.month == s.month && d.day == s.day;
  }

  factory HolidayModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime parseDate() {
      final raw = map['date'];
      if (raw is Timestamp) return raw.toDate();
      if (raw is DateTime) return raw;
      return DateTime.now();
    }

    DateTime parseCreatedAt() {
      final raw = map['createdAt'];
      if (raw is Timestamp) return raw.toDate();
      if (raw is DateTime) return raw;
      return DateTime.now();
    }

    return HolidayModel(
      holidayId: id,
      date: normalize(parseDate()),
      title: map['title'] as String? ?? '',
      type: map['type'] as String? ?? 'Public',
      description: map['description'] as String? ?? '',
      createdBy: map['createdBy'] as String? ?? '',
      createdAt: parseCreatedAt(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': Timestamp.fromDate(normalize(date)),
      'title': title,
      'type': type,
      'description': description,
      'createdBy': createdBy,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  HolidayModel copyWith({
    String? holidayId,
    DateTime? date,
    String? title,
    String? type,
    String? description,
    String? createdBy,
    DateTime? createdAt,
  }) {
    return HolidayModel(
      holidayId: holidayId ?? this.holidayId,
      date: date ?? this.date,
      title: title ?? this.title,
      type: type ?? this.type,
      description: description ?? this.description,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
