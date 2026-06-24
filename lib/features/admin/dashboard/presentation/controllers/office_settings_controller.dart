import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class OfficeSettingsController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Form controllers
  final officeNameController = TextEditingController();
  final latitudeController = TextEditingController();
  final longitudeController = TextEditingController();
  final radiusController = TextEditingController();
  final morningReminderTimeController = TextEditingController();
  final checkoutReminderTimeController = TextEditingController();

  final formKey = GlobalKey<FormState>();

  // Geofence Switch
  final RxBool geofenceEnabled = true.obs;

  // Reactive state
  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;
  final RxBool settingsLoaded = false.obs;

  // Live preview computed values
  final RxDouble previewLatitude = 0.0.obs;
  final RxDouble previewLongitude = 0.0.obs;
  final RxDouble previewRadiusMetres = 200.0.obs;

  @override
  void onInit() {
    super.onInit();
    _loadSettings();
    _attachListeners();
  }

  @override
  void onClose() {
    officeNameController.dispose();
    latitudeController.dispose();
    longitudeController.dispose();
    radiusController.dispose();
    morningReminderTimeController.dispose();
    checkoutReminderTimeController.dispose();
    super.onClose();
  }

  void _attachListeners() {
    latitudeController.addListener(() {
      previewLatitude.value = double.tryParse(latitudeController.text) ?? 0.0;
    });
    longitudeController.addListener(() {
      previewLongitude.value = double.tryParse(longitudeController.text) ?? 0.0;
    });
    radiusController.addListener(() {
      previewRadiusMetres.value =
          double.tryParse(radiusController.text) ?? 200.0;
    });
  }

  Future<void> _loadSettings() async {
    isLoading.value = true;
    try {
      final doc = await _firestore
          .collection('settings')
          .doc('attendance_settings')
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        officeNameController.text = data['officeName'] ?? '';
        latitudeController.text =
            (data['officeLatitude'] as num?)?.toString() ?? '';
        longitudeController.text =
            (data['officeLongitude'] as num?)?.toString() ?? '';
        radiusController.text =
            (data['officeRadius'] as num?)?.toString() ?? '100';

        previewLatitude.value =
            (data['officeLatitude'] as num?)?.toDouble() ?? 0.0;
        previewLongitude.value =
            (data['officeLongitude'] as num?)?.toDouble() ?? 0.0;
        previewRadiusMetres.value =
            (data['officeRadius'] as num?)?.toDouble() ?? 100.0;

        morningReminderTimeController.text = data['morningReminderTime'] as String? ?? '09:15 AM';
        checkoutReminderTimeController.text = data['checkoutReminderTime'] as String? ?? '05:30 PM';
        geofenceEnabled.value = data['geofenceEnabled'] as bool? ?? true;

        settingsLoaded.value = true;
      } else {
        // Fallback to legacy office_location doc
        final legacyDoc = await _firestore
            .collection('settings')
            .doc('office_location')
            .get();

        if (legacyDoc.exists && legacyDoc.data() != null) {
          final data = legacyDoc.data()!;
          officeNameController.text = data['officeName'] ?? '';
          latitudeController.text =
              (data['latitude'] as num?)?.toString() ?? '';
          longitudeController.text =
              (data['longitude'] as num?)?.toString() ?? '';
          radiusController.text =
              (data['radius'] as num?)?.toString() ?? '100';

          previewLatitude.value =
              (data['latitude'] as num?)?.toDouble() ?? 0.0;
          previewLongitude.value =
              (data['longitude'] as num?)?.toDouble() ?? 0.0;
          previewRadiusMetres.value =
              (data['radius'] as num?)?.toDouble() ?? 100.0;
        } else {
          radiusController.text = '100';
          previewRadiusMetres.value = 100.0;
        }

        morningReminderTimeController.text = '09:15 AM';
        checkoutReminderTimeController.text = '05:30 PM';
        geofenceEnabled.value = true;
        settingsLoaded.value = true;
      }
    } catch (e) {
      debugPrint('Error loading office settings: $e');
      Get.rawSnackbar(
        title: 'Load Error',
        message: 'Could not load saved office settings.',
        backgroundColor: Colors.orange.shade700,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> saveSettings() async {
    if (!formKey.currentState!.validate()) {
      Get.rawSnackbar(
        title: 'Validation Error',
        message: 'Please correct the invalid fields in the form.',
        backgroundColor: Colors.red.shade700,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    isSaving.value = true;
    try {
      final double? lat = double.tryParse(latitudeController.text.trim());
      final double? lng = double.tryParse(longitudeController.text.trim());
      final double? radius = double.tryParse(radiusController.text.trim());

      if (lat == null || lat < -90 || lat > 90) {
        _showValidationError('Latitude must be between -90 and 90.');
        return;
      }
      if (lng == null || lng < -180 || lng > 180) {
        _showValidationError('Longitude must be between -180 and 180.');
        return;
      }
      if (radius == null || radius < 50 || radius > 50000) {
        _showValidationError('Radius must be between 50 and 50,000 metres.');
        return;
      }

      await _firestore.collection('settings').doc('attendance_settings').set({
        'officeName': officeNameController.text.trim(),
        'officeLatitude': lat,
        'officeLongitude': lng,
        'officeRadius': radius,
        'morningReminderTime': morningReminderTimeController.text.trim(),
        'checkoutReminderTime': checkoutReminderTimeController.text.trim(),
        'geofenceEnabled': geofenceEnabled.value,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      settingsLoaded.value = true;

      Get.rawSnackbar(
        title: '✓ Settings Saved',
        message:
            'Office geofence updated: ${officeNameController.text.trim()} — ${radius.toStringAsFixed(0)} m radius.',
        backgroundColor: const Color(0xFF16A34A),
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.rawSnackbar(
        title: 'Save Failed',
        message: 'Could not write settings to Firestore: $e',
        backgroundColor: Colors.red.shade700,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isSaving.value = false;
    }
  }

  void _showValidationError(String message) {
    isSaving.value = false;
    Get.rawSnackbar(
      title: 'Validation Error',
      message: message,
      backgroundColor: Colors.red.shade700,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  // Validators
  String? validateRequired(String? value) {
    if (value == null || value.trim().isEmpty) return 'This field is required.';
    return null;
  }

  String? validateLatitude(String? value) {
    if (value == null || value.trim().isEmpty) return 'Latitude is required.';
    final d = double.tryParse(value.trim());
    if (d == null) return 'Enter a valid decimal number (e.g. 37.7749).';
    if (d < -90 || d > 90) return 'Latitude must be between -90 and 90.';
    return null;
  }

  String? validateLongitude(String? value) {
    if (value == null || value.trim().isEmpty) return 'Longitude is required.';
    final d = double.tryParse(value.trim());
    if (d == null) return 'Enter a valid decimal number (e.g. -122.4194).';
    if (d < -180 || d > 180) return 'Longitude must be between -180 and 180.';
    return null;
  }

  String? validateRadius(String? value) {
    if (value == null || value.trim().isEmpty) return 'Radius is required.';
    final d = double.tryParse(value.trim());
    if (d == null) return 'Enter a valid number (e.g. 200).';
    if (d < 50) return 'Minimum radius is 50 metres.';
    if (d > 50000) return 'Maximum radius is 50,000 metres.';
    return null;
  }

  String get radiusInKm {
    final r = previewRadiusMetres.value;
    if (r >= 1000) {
      return '${(r / 1000).toStringAsFixed(2)} km';
    }
    return '${r.toStringAsFixed(0)} m';
  }

  final RxBool isLocating = false.obs;

  Future<void> useCurrentLocation() async {
    isLocating.value = true;
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        Get.rawSnackbar(
          title: 'Permission Denied',
          message: 'Location permission is required to get current location.',
          backgroundColor: Colors.orange.shade700,
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      latitudeController.text = position.latitude.toStringAsFixed(6);
      longitudeController.text = position.longitude.toStringAsFixed(6);

      Get.rawSnackbar(
        title: '📍 Location Fetched',
        message: 'Coordinates updated to your current position.',
        backgroundColor: const Color(0xFF16A34A),
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.rawSnackbar(
        title: 'Error',
        message: 'Could not fetch current coordinates: $e',
        backgroundColor: Colors.red.shade700,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLocating.value = false;
    }
  }

  Future<void> openMapPicker() async {
    final double? initLat = double.tryParse(latitudeController.text);
    final double? initLng = double.tryParse(longitudeController.text);

    final result = await Get.toNamed(
      '/admin/map-picker',
      arguments: {
        'latitude': initLat ?? 20.5937,
        'longitude': initLng ?? 78.9629,
      },
    );

    if (result != null && result is LatLng) {
      latitudeController.text = result.latitude.toStringAsFixed(6);
      longitudeController.text = result.longitude.toStringAsFixed(6);
      
      Get.rawSnackbar(
        title: '🗺️ Map Spot Picked',
        message: 'Coordinates updated from map selection.',
        backgroundColor: const Color(0xFF16A34A),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
