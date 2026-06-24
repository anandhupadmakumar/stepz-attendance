import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stepz_attendance/core/theme/premium_background.dart';

class MapPickerView extends StatefulWidget {
  const MapPickerView({super.key});

  @override
  State<MapPickerView> createState() => _MapPickerViewState();
}

class _MapPickerViewState extends State<MapPickerView> {
  // ── Map state ─────────────────────────────────────────────────────────────
  GoogleMapController? _mapController;
  late LatLng _currentPosition;
  bool _isMoving = false;
  bool _isLocating = false;

  @override
  void initState() {
    super.initState();
    final Map<String, dynamic>? args = Get.arguments as Map<String, dynamic>?;
    final double initialLat = args?['latitude'] ?? 20.5937;
    final double initialLng = args?['longitude'] ?? 78.9629;
    _currentPosition = LatLng(initialLat, initialLng);
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  // ── Location helpers ───────────────────────────────────────────────────────
  Future<void> _moveToCurrentLocation() async {
    setState(() => _isLocating = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        );
        final target = LatLng(position.latitude, position.longitude);
        _mapController?.animateCamera(
          CameraUpdate.newCameraPosition(CameraPosition(target: target, zoom: 17)),
        );
        setState(() => _currentPosition = target);
      } else {
        _showSnack('Permission Denied',
            'Location permission is required.', Colors.orange.shade700);
      }
    } catch (e) {
      _showSnack('Error', 'Could not fetch location: $e', Colors.red.shade700);
    } finally {
      setState(() => _isLocating = false);
    }
  }

  void _showSnack(String title, String message, Color color) {
    Get.rawSnackbar(
      title: title,
      message: message,
      backgroundColor: color,
      snackPosition: SnackPosition.BOTTOM,
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      borderRadius: 12,
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final double initialZoom =
        (_currentPosition.latitude == 20.5937) ? 5.0 : 16.0;

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
            'Pick Office Location',
            style: GoogleFonts.inter(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        body: Stack(
        children: [
          // ── Google Map ────────────────────────────────────────────────────
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _currentPosition,
              zoom: initialZoom,
            ),
            onMapCreated: (controller) => _mapController = controller,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            onCameraMoveStarted: () => setState(() => _isMoving = true),
            onCameraMove: (pos) =>
                setState(() => _currentPosition = pos.target),
            onCameraIdle: () => setState(() => _isMoving = false),
            onTap: (_) {},
          ),

          // ── Centre pin overlay (Uber-style) ───────────────────────────────
          Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 24.h),
              child: AnimatedTranslate(
                offset: _isMoving ? const Offset(0, -10) : const Offset(0, 0),
                duration: const Duration(milliseconds: 150),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6),
                        borderRadius: BorderRadius.circular(8.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        'Office Spot',
                        style: GoogleFonts.inter(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.location_on,
                      size: 44,
                      color: Color(0xFF3B82F6),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Centre dot
          Center(
            child: Container(
              width: 8.w,
              height: 8.w,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // ── FABs (GPS + Zoom) ─────────────────────────────────────────────
          Positioned(
            right: 16.w,
            bottom: 210.h,
            child: Column(
              children: [
                _MapFab(
                  heroTag: 'gps_fab',
                  onPressed: _isLocating ? null : _moveToCurrentLocation,
                  child: _isLocating
                      ? SizedBox(
                          width: 18.w,
                          height: 18.w,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.gps_fixed, color: Colors.white),
                ),
                SizedBox(height: 8.h),
                _MapFab(
                  heroTag: 'zoom_in',
                  onPressed: () => _mapController?.animateCamera(CameraUpdate.zoomIn()),
                  child: const Icon(Icons.add, color: Colors.white),
                ),
                SizedBox(height: 8.h),
                _MapFab(
                  heroTag: 'zoom_out',
                  onPressed: () => _mapController?.animateCamera(CameraUpdate.zoomOut()),
                  child: const Icon(Icons.remove, color: Colors.white),
                ),
              ],
            ),
          ),

          // ── Bottom confirm sheet ──────────────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A).withOpacity(0.65),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
                    border: Border(
                      top: BorderSide(
                        color: Colors.white.withOpacity(0.15),
                        width: 1.2,
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8.w),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: const Icon(Icons.pin_drop, color: Color(0xFF3B82F6), size: 20),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Selected Coordinates',
                                style: GoogleFonts.inter(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                'Drag the map to adjust the pin precisely',
                                style: GoogleFonts.inter(
                                  fontSize: 11.sp,
                                  color: const Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 14.h),
                    Row(
                      children: [
                        _CoordBox(
                            label: 'LATITUDE',
                            value: _currentPosition.latitude.toStringAsFixed(6)),
                        SizedBox(width: 12.w),
                        _CoordBox(
                            label: 'LONGITUDE',
                            value: _currentPosition.longitude.toStringAsFixed(6)),
                      ],
                    ),
                    SizedBox(height: 18.h),
                    Container(
                      height: 50.h,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0F52BA), Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12.r),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF3B82F6).withOpacity(0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () => Get.back(result: _currentPosition),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Confirm Location',
                          style: GoogleFonts.inter(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),),),
          ),
        ],
      ),
    ),);
  }
}

// ── Reusable FAB ───────────────────────────────────────────────────────────────
class _MapFab extends StatelessWidget {
  final String heroTag;
  final VoidCallback? onPressed;
  final Widget child;

  const _MapFab({
    required this.heroTag,
    required this.onPressed,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      width: 40.w,
      height: 40.w,
      child: FloatingActionButton(
        heroTag: heroTag,
        onPressed: onPressed,
        backgroundColor: const Color(0xFF0F172A).withOpacity(0.8),
        shape: const CircleBorder(),
        elevation: 3,
        child: child,
      ),
    );
  }
}

// ── Coordinate display box ─────────────────────────────────────────────────────
class _CoordBox extends StatelessWidget {
  final String label;
  final String value;

  const _CoordBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(10.w),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 9.sp,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF94A3B8),
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Animated translate helper ──────────────────────────────────────────────────
class AnimatedTranslate extends StatelessWidget {
  final Offset offset;
  final Duration duration;
  final Widget child;

  const AnimatedTranslate({
    super.key,
    required this.offset,
    required this.duration,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: duration,
      transform: Matrix4.translationValues(offset.dx, offset.dy, 0.0),
      child: child,
    );
  }
}
