import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:stepz_attendance/core/theme/premium_background.dart';
import '../controllers/office_settings_controller.dart';

class OfficeSettingsView extends GetView<OfficeSettingsController> {
  const OfficeSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return PremiumBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.white),
            onPressed: () => Get.back(),
          ),
          title: Text(
            'Office Geofence',
            style: GoogleFonts.inter(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          centerTitle: false,
        ),
        body: Obx(() {
          if (controller.isLoading.value) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF3B82F6),
              ),
            );
          }
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
            child: Form(
              key: controller.formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Hero header card
                  _buildHeaderCard(),
                  SizedBox(height: 24.h),

                  // Section: Office Info
                  _buildSectionLabel('OFFICE DETAILS'),
                  SizedBox(height: 10.h),
                  _buildTextField(
                    label: 'Office Name',
                    hint: 'e.g. Main Office, HQ Tower',
                    controller: controller.officeNameController,
                    icon: Icons.business_outlined,
                    validator: controller.validateRequired,
                  ),
                  SizedBox(height: 16.h),

                  // Section: Coordinates
                  _buildSectionLabel('GPS COORDINATES'),
                  SizedBox(height: 8.h),
                  _buildCoordsHelperNote(),
                  SizedBox(height: 12.h),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: controller.isLocating.value
                              ? null
                              : controller.useCurrentLocation,
                          icon: controller.isLocating.value
                              ? SizedBox(
                                  width: 16.w,
                                  height: 16.w,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.gps_fixed, size: 16, color: Colors.white),
                          label: Text(
                            controller.isLocating.value ? 'Locating...' : 'Use My GPS',
                            style: GoogleFonts.inter(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E3A8A),
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.r),
                              side: BorderSide(color: Colors.white.withOpacity(0.12)),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: controller.openMapPicker,
                          icon: const Icon(Icons.map_outlined, size: 16, color: Color(0xFF3B82F6)),
                          label: Text(
                            'Select on Map',
                            style: GoogleFonts.inter(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF3B82F6),
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          label: 'Latitude',
                          hint: 'e.g. 37.7749',
                          controller: controller.latitudeController,
                          icon: Icons.explore_outlined,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true, signed: true),
                          validator: controller.validateLatitude,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: _buildTextField(
                          label: 'Longitude',
                          hint: 'e.g. -122.4194',
                          controller: controller.longitudeController,
                          icon: Icons.explore,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true, signed: true),
                          validator: controller.validateLongitude,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),

                  // Section: Radius
                  _buildSectionLabel('GEOFENCE RADIUS'),
                  SizedBox(height: 10.h),
                  _buildTextField(
                    label: 'Radius (in metres)',
                    hint: 'e.g. 200',
                    controller: controller.radiusController,
                    icon: Icons.radio_button_checked_outlined,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: controller.validateRadius,
                  ),
                  SizedBox(height: 16.h),

                  // Geofence Enable Toggle
                  Obx(() => _buildGeofenceToggle()),
                  SizedBox(height: 16.h),

                  // Section: Reminders
                  _buildSectionLabel('ATTENDANCE REMINDER TIMES'),
                  SizedBox(height: 10.h),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTimeField(
                          context: context,
                          label: 'Morning Reminder',
                          controller: controller.morningReminderTimeController,
                          icon: Icons.light_mode_outlined,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: _buildTimeField(
                          context: context,
                          label: 'Checkout Reminder',
                          controller: controller.checkoutReminderTimeController,
                          icon: Icons.dark_mode_outlined,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),

                  // Live Preview Card
                  _buildPreviewCard(),
                  SizedBox(height: 32.h),

                  // Save Button
                  Obx(() => _buildSaveButton()),
                  SizedBox(height: 16.h),

                  // Google Maps tip
                  _buildMapsTip(),
                  SizedBox(height: 32.h),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.white.withOpacity(0.12), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              color: const Color(0xFF1E3A8A),
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.4)),
            ),
            child: const Icon(Icons.my_location, color: Colors.white, size: 28),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Office Geofence',
                  style: GoogleFonts.inter(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Set your office location and check-in radius. Employees within range can punch in.',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF94A3B8),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 11.sp,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF94A3B8),
        letterSpacing: 1.0,
      ),
    );
  }

  Widget _buildCoordsHelperNote() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: const Color(0xFF3B82F6).withOpacity(0.15),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 14, color: Color(0xFF60A5FA)),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              'Open Google Maps → long-press your office location → copy the coordinates shown.',
              style: GoogleFonts.inter(
                fontSize: 11.sp,
                color: const Color(0xFF60A5FA),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: GoogleFonts.inter(
        fontSize: 14.sp,
        fontWeight: FontWeight.w500,
        color: Colors.white,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20, color: const Color(0xFF3B82F6)),
        labelStyle: GoogleFonts.inter(
          fontSize: 13.sp,
          color: const Color(0xFF94A3B8),
        ),
        hintStyle: GoogleFonts.inter(
          fontSize: 13.sp,
          color: const Color(0xFF64748B),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.08),
        contentPadding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 16.w),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.12), width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
        ),
      ),
    );
  }

  Widget _buildPreviewCard() {
    return Obx(() {
      final lat = controller.previewLatitude.value;
      final lng = controller.previewLongitude.value;
      final radiusKm = controller.radiusInKm;
      final hasCoords = lat != 0.0 || lng != 0.0;

      return Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: const Icon(Icons.radar, size: 18, color: Color(0xFF3B82F6)),
                ),
                SizedBox(width: 10.w),
                Text(
                  'Geofence Preview',
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),

            // Radar visual
            Center(
              child: SizedBox(
                width: 140.w,
                height: 140.w,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer ring
                    Container(
                      width: 140.w,
                      height: 140.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.1), width: 1.5),
                        color: const Color(0xFF3B82F6).withOpacity(0.02),
                      ),
                    ),
                    // Middle ring
                    Container(
                      width: 100.w,
                      height: 100.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.15), width: 1.5),
                        color: const Color(0xFF3B82F6).withOpacity(0.04),
                      ),
                    ),
                    // Inner ring (policy boundary)
                    Container(
                      width: 60.w,
                      height: 60.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.4), width: 2),
                        color: const Color(0xFF3B82F6).withOpacity(0.08),
                      ),
                    ),
                    // Office pin
                    Container(
                      width: 20.w,
                      height: 20.w,
                      decoration: const BoxDecoration(
                        color: Color(0xFF3B82F6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.business, size: 12, color: Colors.white),
                    ),
                    // Radius label
                    Positioned(
                      bottom: 22.h,
                      right: 16.w,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Text(
                          radiusKm,
                          style: GoogleFonts.inter(
                            fontSize: 9.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16.h),

            // Coordinate details
            Row(
              children: [
                _buildPreviewChip(
                  label: 'Latitude',
                  value: hasCoords ? lat.toStringAsFixed(5) : 'Not set',
                  icon: Icons.north,
                ),
                SizedBox(width: 8.w),
                _buildPreviewChip(
                  label: 'Longitude',
                  value: hasCoords ? lng.toStringAsFixed(5) : 'Not set',
                  icon: Icons.east,
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 14.w),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.2),
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline, size: 16, color: Color(0xFF34D399)),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'Employees within $radiusKm can check in.',
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF34D399),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildPreviewChip({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 10.w),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 12, color: const Color(0xFF94A3B8)),
                SizedBox(width: 4.w),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return GestureDetector(
      onTap: controller.isSaving.value ? null : controller.saveSettings,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 54.h,
        decoration: BoxDecoration(
          gradient: controller.isSaving.value
              ? null
              : const LinearGradient(
                  colors: [Color(0xFF0F52BA), Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
          color: controller.isSaving.value ? Colors.white.withOpacity(0.12) : null,
          borderRadius: BorderRadius.circular(14.r),
          border: controller.isSaving.value ? Border.all(color: Colors.white.withOpacity(0.12)) : null,
          boxShadow: controller.isSaving.value
              ? []
              : [
                  BoxShadow(
                    color: const Color(0xFF3B82F6).withOpacity(0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Center(
          child: controller.isSaving.value
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 20.w,
                      height: 20.w,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Text(
                      'Saving...',
                      style: GoogleFonts.inter(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.save_outlined, color: Colors.white, size: 20),
                    SizedBox(width: 10.w),
                    Text(
                      'Save Geofence Settings',
                      style: GoogleFonts.inter(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildMapsTip() {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.map_outlined, size: 16, color: Colors.white),
              SizedBox(width: 8.w),
              Text(
                'How to get coordinates from Google Maps',
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          _buildStep('1', 'Open Google Maps on your phone or computer.'),
          _buildStep('2', 'Long-press on your office building location.'),
          _buildStep('3', 'A red pin drops and coordinates appear at the bottom (e.g. 37.7749, -122.4194).'),
          _buildStep('4', 'Copy and paste those numbers into the fields above.'),
        ],
      ),
    );
  }

  Widget _buildStep(String num, String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 18.w,
            height: 18.w,
            decoration: const BoxDecoration(
              color: Color(0xFF3B82F6),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                num,
                style: GoogleFonts.inter(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                color: const Color(0xFF94A3B8),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeofenceToggle() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.white.withOpacity(0.12), width: 1.2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.location_on_outlined, color: const Color(0xFF3B82F6), size: 20.sp),
              SizedBox(width: 10.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Geofence Reminders Enabled',
                    style: GoogleFonts.inter(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'Notify staff when entering/exiting base',
                    style: GoogleFonts.inter(
                      fontSize: 10.sp,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Switch.adaptive(
            value: controller.geofenceEnabled.value,
            onChanged: (val) => controller.geofenceEnabled.value = val,
            activeColor: const Color(0xFF3B82F6),
            activeTrackColor: const Color(0xFF3B82F6).withOpacity(0.3),
            inactiveThumbColor: const Color(0xFF94A3B8),
            inactiveTrackColor: Colors.white.withOpacity(0.1),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeField({
    required BuildContext context,
    required String label,
    required TextEditingController controller,
    required IconData icon,
  }) {
    return GestureDetector(
      onTap: () async {
        final TimeOfDay? picked = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.now(),
          builder: (BuildContext context, Widget? child) {
            return Theme(
              data: ThemeData.dark().copyWith(
                colorScheme: const ColorScheme.dark(
                  primary: Color(0xFF3B82F6),
                  onPrimary: Colors.white,
                  surface: Color(0xFF0F172A),
                  onSurface: Colors.white,
                ),
                dialogBackgroundColor: const Color(0xFF0F172A),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) {
          final now = DateTime.now();
          final dt = DateTime(now.year, now.month, now.day, picked.hour, picked.minute);
          controller.text = DateFormat('hh:mm a').format(dt);
        }
      },
      child: AbsorbPointer(
        child: _buildTextField(
          label: label,
          hint: 'Select time',
          controller: controller,
          icon: icon,
        ),
      ),
    );
  }
}
