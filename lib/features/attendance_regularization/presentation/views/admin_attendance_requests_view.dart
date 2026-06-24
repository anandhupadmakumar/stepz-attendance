import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stepz_attendance/core/theme/premium_background.dart';
import '../controllers/admin_attendance_requests_controller.dart';

class AdminAttendanceRequestsView extends GetView<AdminAttendanceRequestsController> {
  const AdminAttendanceRequestsView({super.key});

  @override
  Widget build(BuildContext context) {
    return PremiumBackground(
      child: DefaultTabController(
        length: 3,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => Get.back(),
            ),
            title: Text(
              'Attendance Regularization Requests',
              style: GoogleFonts.outfit(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            bottom: TabBar(
              indicatorColor: const Color(0xFF3B82F6),
              labelColor: Colors.white,
              unselectedLabelColor: const Color(0xFF94A3B8),
              labelStyle: GoogleFonts.inter(
                fontSize: 13.sp,
                fontWeight: FontWeight.bold,
              ),
              unselectedLabelStyle: GoogleFonts.inter(
                fontSize: 13.sp,
                fontWeight: FontWeight.normal,
              ),
              tabs: const [
                Tab(text: 'Pending'),
                Tab(text: 'Approved'),
                Tab(text: 'Rejected'),
              ],
            ),
          ),
          body: Column(
            children: [
              _buildStatsBanner(),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildRequestsList(controller.pendingRequests),
                    _buildRequestsList(controller.approvedRequests),
                    _buildRequestsList(controller.rejectedRequests),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsBanner() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Obx(() => Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem('Pending', '${controller.pendingCount.value}', const Color(0xFFF97316)),
              _buildStatItem('Approved Today', '${controller.approvedTodayCount.value}', const Color(0xFF10B981)),
              _buildStatItem('Rejected Today', '${controller.rejectedTodayCount.value}', const Color(0xFFEF4444)),
            ],
          )),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10.sp,
            color: const Color(0xFF94A3B8),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildRequestsList(RxList<Map<String, dynamic>> requestsList) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
          ),
        );
      }

      if (requestsList.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.fact_check_rounded,
                color: Color(0xFF475569),
                size: 56,
              ),
              SizedBox(height: 12.h),
              Text(
                'No requests found',
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
        itemCount: requestsList.length,
        itemBuilder: (context, index) {
          final req = requestsList[index];
          return _buildRequestCard(req);
        },
      );
    });
  }

  Widget _buildRequestCard(Map<String, dynamic> req) {
    final name = req['employeeName'] as String? ?? 'Employee';
    final date = req['attendanceDateFormatted'] as String? ?? 'Unknown Date';
    final checkIn = req['checkIn'] as String? ?? '--';
    final requestedCheckOut = req['requestedCheckOut'] as String? ?? '--';
    final reason = req['reason'] as String? ?? '';
    final status = req['status'] as String? ?? 'pending';

    Color statusColor;
    switch (status) {
      case 'approved':
        statusColor = const Color(0xFF10B981);
        break;
      case 'rejected':
        statusColor = const Color(0xFFEF4444);
        break;
      default:
        statusColor = const Color(0xFFF97316);
    }

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.inter(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      req['designation'] as String? ?? 'Staff',
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        color: const Color(0xFF94A3B8),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color: statusColor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 9.sp,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          Divider(height: 20, color: Colors.white.withOpacity(0.08)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Shift Date:',
                style: GoogleFonts.inter(fontSize: 12.sp, color: const Color(0xFF94A3B8)),
              ),
              Text(
                date,
                style: GoogleFonts.inter(fontSize: 12.sp, color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Original Check-In:',
                style: GoogleFonts.inter(fontSize: 12.sp, color: const Color(0xFF94A3B8)),
              ),
              Text(
                checkIn,
                style: GoogleFonts.inter(fontSize: 12.sp, color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Requested Check-Out:',
                style: GoogleFonts.inter(fontSize: 12.sp, color: const Color(0xFF94A3B8)),
              ),
              Text(
                requestedCheckOut,
                style: GoogleFonts.inter(fontSize: 12.sp, color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Text(
            'Reason: $reason',
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              color: const Color(0xFFCBD5E1),
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 12.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: status == 'pending' ? const Color(0xFF3B82F6) : Colors.white.withOpacity(0.08),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
                padding: EdgeInsets.symmetric(vertical: 10.h),
                elevation: 0,
              ),
              onPressed: () {
                Get.toNamed('/admin/attendance-requests/details', arguments: req);
              },
              child: Text(
                status == 'pending' ? 'REVIEW REQUEST' : 'VIEW DETAILS',
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
