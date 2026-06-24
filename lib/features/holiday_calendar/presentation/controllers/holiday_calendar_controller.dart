import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../holiday_calendar/models/holiday_model.dart';

class HolidayCalendarController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // --- State ---
  final RxList<HolidayModel> holidays = <HolidayModel>[].obs;
  final Rx<DateTime> focusedDay = DateTime.now().obs;
  final Rx<DateTime?> selectedDay = Rx<DateTime?>(null);
  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;

  StreamSubscription<QuerySnapshot>? _holidayStream;

  // Form controllers for add-holiday bottom sheet
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final RxString selectedType = 'Public'.obs;

  static const List<String> holidayTypes = [
    'Public',
    'Optional',
    'Company Event',
  ];

  // ─── Indian Public Holidays 2025 & 2026 ───────────────────────────────────
  static final List<Map<String, dynamic>> _indianHolidays = [
    // 2025
    {'date': DateTime(2025, 1, 1), 'title': "New Year's Day", 'type': 'Public'},
    {'date': DateTime(2025, 1, 14), 'title': 'Pongal / Makar Sankranti', 'type': 'Public'},
    {'date': DateTime(2025, 1, 26), 'title': 'Republic Day', 'type': 'Public'},
    {'date': DateTime(2025, 2, 26), 'title': 'Maha Shivaratri', 'type': 'Public'},
    {'date': DateTime(2025, 3, 14), 'title': 'Holi', 'type': 'Public'},
    {'date': DateTime(2025, 3, 31), 'title': 'Id-ul-Fitr (Eid)', 'type': 'Public'},
    {'date': DateTime(2025, 4, 14), 'title': 'Dr. Ambedkar Jayanti / Vishu', 'type': 'Public'},
    {'date': DateTime(2025, 4, 18), 'title': 'Good Friday', 'type': 'Public'},
    {'date': DateTime(2025, 5, 12), 'title': 'Buddha Purnima', 'type': 'Public'},
    {'date': DateTime(2025, 6, 7), 'title': 'Id-ul-Zuha (Bakrid)', 'type': 'Public'},
    {'date': DateTime(2025, 7, 6), 'title': 'Muharram', 'type': 'Public'},
    {'date': DateTime(2025, 8, 15), 'title': 'Independence Day', 'type': 'Public'},
    {'date': DateTime(2025, 8, 16), 'title': 'Janmashtami', 'type': 'Public'},
    {'date': DateTime(2025, 9, 5), 'title': 'Milad-un-Nabi / Id-e-Milad', 'type': 'Public'},
    {'date': DateTime(2025, 10, 2), 'title': 'Gandhi Jayanti / Dussehra', 'type': 'Public'},
    {'date': DateTime(2025, 10, 20), 'title': 'Diwali (Deepavali)', 'type': 'Public'},
    {'date': DateTime(2025, 10, 22), 'title': 'Bhai Dooj', 'type': 'Optional'},
    {'date': DateTime(2025, 11, 5), 'title': 'Guru Nanak Jayanti', 'type': 'Public'},
    {'date': DateTime(2025, 12, 25), 'title': 'Christmas Day', 'type': 'Public'},
    // 2026
    {'date': DateTime(2026, 1, 1), 'title': "New Year's Day", 'type': 'Public'},
    {'date': DateTime(2026, 1, 14), 'title': 'Pongal / Makar Sankranti', 'type': 'Public'},
    {'date': DateTime(2026, 1, 26), 'title': 'Republic Day', 'type': 'Public'},
    {'date': DateTime(2026, 2, 15), 'title': 'Maha Shivaratri', 'type': 'Public'},
    {'date': DateTime(2026, 3, 3), 'title': 'Holi', 'type': 'Public'},
    {'date': DateTime(2026, 3, 20), 'title': 'Id-ul-Fitr (Eid)', 'type': 'Public'},
    {'date': DateTime(2026, 4, 3), 'title': 'Good Friday', 'type': 'Public'},
    {'date': DateTime(2026, 4, 14), 'title': 'Dr. Ambedkar Jayanti / Vishu', 'type': 'Public'},
    {'date': DateTime(2026, 5, 1), 'title': 'Labour Day', 'type': 'Public'},
    {'date': DateTime(2026, 5, 31), 'title': 'Buddha Purnima', 'type': 'Public'},
    {'date': DateTime(2026, 8, 15), 'title': 'Independence Day', 'type': 'Public'},
    {'date': DateTime(2026, 10, 2), 'title': 'Gandhi Jayanti', 'type': 'Public'},
    {'date': DateTime(2026, 10, 9), 'title': 'Dussehra', 'type': 'Public'},
    {'date': DateTime(2026, 11, 9), 'title': 'Diwali (Deepavali)', 'type': 'Public'},
    {'date': DateTime(2026, 11, 24), 'title': 'Guru Nanak Jayanti', 'type': 'Public'},
    {'date': DateTime(2026, 12, 25), 'title': 'Christmas Day', 'type': 'Public'},
  ];

  @override
  void onInit() {
    super.onInit();
    _listenToHolidays();
  }

  @override
  void onClose() {
    _holidayStream?.cancel();
    titleController.dispose();
    descriptionController.dispose();
    super.onClose();
  }

  // ─── Real-time Firestore stream ────────────────────────────────────────────
  void _listenToHolidays() {
    isLoading.value = true;
    _holidayStream = _firestore
        .collection('holidays')
        .orderBy('date')
        .snapshots()
        .listen(
      (snapshot) {
        holidays.value = snapshot.docs
            .map((doc) => HolidayModel.fromMap(doc.data(), doc.id))
            .toList();
        isLoading.value = false;
      },
      onError: (e) {
        debugPrint('Holiday stream error: $e');
        isLoading.value = false;
      },
    );
  }

  // ─── Seed Indian holidays (admin-triggered one-time action) ───────────────
  Future<void> seedIndianHolidays() async {
    isSaving.value = true;
    try {
      final user = _auth.currentUser;
      final batch = _firestore.batch();
      for (final h in _indianHolidays) {
        // Skip if already exists for that date
        final date = HolidayModel.normalize(h['date'] as DateTime);
        final existing = holidays.firstWhereOrNull((hm) => hm.isSameDay(date));
        if (existing != null) continue;

        final ref = _firestore.collection('holidays').doc();
        batch.set(ref, {
          'date': Timestamp.fromDate(date),
          'title': h['title'],
          'type': h['type'],
          'description': 'Indian Public Holiday',
          'createdBy': user?.uid ?? 'system',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
      Get.rawSnackbar(
        title: 'Holidays Seeded',
        message: 'Indian public holidays for 2025 & 2026 have been added.',
        backgroundColor: const Color(0xFF059669),
      );
    } catch (e) {
      debugPrint('Seed error: $e');
      Get.rawSnackbar(
        title: 'Error',
        message: 'Failed to seed holidays: $e',
        backgroundColor: const Color(0xFFDC2626),
      );
    } finally {
      isSaving.value = false;
    }
  }

  // ─── Add holiday ──────────────────────────────────────────────────────────
  Future<void> addHoliday({
    required DateTime date,
    required String title,
    required String type,
    String description = '',
  }) async {
    if (title.trim().isEmpty) {
      Get.rawSnackbar(
        title: 'Validation',
        message: 'Holiday title cannot be empty.',
        backgroundColor: const Color(0xFFDC2626),
      );
      return;
    }

    isSaving.value = true;
    try {
      final user = _auth.currentUser;
      await _firestore.collection('holidays').add({
        'date': Timestamp.fromDate(HolidayModel.normalize(date)),
        'title': title.trim(),
        'type': type,
        'description': description.trim(),
        'createdBy': user?.uid ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      });
      Get.rawSnackbar(
        title: 'Holiday Added',
        message: '"$title" marked as $type Holiday.',
        backgroundColor: const Color(0xFF059669),
      );
    } catch (e) {
      debugPrint('Add holiday error: $e');
      Get.rawSnackbar(
        title: 'Error',
        message: 'Failed to add holiday.',
        backgroundColor: const Color(0xFFDC2626),
      );
    } finally {
      isSaving.value = false;
    }
  }

  // ─── Delete holiday ───────────────────────────────────────────────────────
  Future<void> deleteHoliday(String holidayId) async {
    isSaving.value = true;
    try {
      await _firestore.collection('holidays').doc(holidayId).delete();
      Get.rawSnackbar(
        title: 'Holiday Removed',
        message: 'Holiday has been deleted.',
        backgroundColor: const Color(0xFF475569),
      );
    } catch (e) {
      Get.rawSnackbar(
        title: 'Error',
        message: 'Failed to delete holiday.',
        backgroundColor: const Color(0xFFDC2626),
      );
    } finally {
      isSaving.value = false;
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  /// Returns the HolidayModel for a date, or null if not a holiday
  HolidayModel? getHoliday(DateTime date) {
    return holidays.firstWhereOrNull((h) => h.isSameDay(date));
  }

  bool isHoliday(DateTime date) => getHoliday(date) != null;

  bool isPublicHoliday(DateTime date) =>
      getHoliday(date)?.type == 'Public';

  bool isOptionalHoliday(DateTime date) =>
      getHoliday(date)?.type == 'Optional';

  bool isCompanyEvent(DateTime date) =>
      getHoliday(date)?.type == 'Company Event';

  /// Returns all holidays in a specific month
  List<HolidayModel> getHolidaysForMonth(int year, int month) {
    return holidays
        .where((h) => h.date.year == year && h.date.month == month)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  /// Count stats for current focused month
  int get publicCount => getHolidaysForMonth(
        focusedDay.value.year,
        focusedDay.value.month,
      ).where((h) => h.type == 'Public').length;

  int get optionalCount => getHolidaysForMonth(
        focusedDay.value.year,
        focusedDay.value.month,
      ).where((h) => h.type == 'Optional').length;

  int get companyEventCount => getHolidaysForMonth(
        focusedDay.value.year,
        focusedDay.value.month,
      ).where((h) => h.type == 'Company Event').length;

  int get totalMonthHolidays =>
      getHolidaysForMonth(focusedDay.value.year, focusedDay.value.month).length;

  Color typeColor(String type) {
    switch (type) {
      case 'Public':
        return const Color(0xFFEF4444);
      case 'Optional':
        return const Color(0xFFF59E0B);
      case 'Company Event':
        return const Color(0xFF3B82F6);
      default:
        return const Color(0xFFEF4444);
    }
  }

  void clearForm() {
    titleController.clear();
    descriptionController.clear();
    selectedType.value = 'Public';
  }
}
