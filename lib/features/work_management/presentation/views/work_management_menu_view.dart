import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/theme/premium_background.dart';

class WorkManagementMenuView extends StatefulWidget {
  const WorkManagementMenuView({super.key});

  @override
  State<WorkManagementMenuView> createState() => _WorkManagementMenuViewState();
}

class _WorkManagementMenuViewState extends State<WorkManagementMenuView> {
  final RxString userRole = 'employee'.obs;
  final RxBool isLoading = true.obs;

  @override
  void initState() {
    super.initState();
    _checkUserRole();
  }

  Future<void> _checkUserRole() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists) {
          userRole.value = doc.data()?['role'] ?? 'employee';
        }
      }
    } catch (e) {
      debugPrint("Error checking user role for work menu: $e");
    } finally {
      isLoading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    const textColor = Colors.white;
    const subTextColor = Color(0xFF94A3B8);

    return PremiumBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor),
            onPressed: () => Get.back(),
          ),
          title: Text(
            'Work Management',
            style: GoogleFonts.outfit(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ),
        body: Obx(() {
          if (isLoading.value) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
              ),
            );
          }

          final isAdmin = userRole.value == 'admin';

          return SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Welcome Header
                  Text(
                    isAdmin ? 'Admin Console' : 'Work Space',
                    style: GoogleFonts.inter(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    isAdmin
                        ? 'Assign tasks, manage clients, and review performance.'
                        : 'Access your tasks and submit daily standup updates.',
                    style: GoogleFonts.inter(
                      fontSize: 13.sp,
                      color: subTextColor,
                    ),
                  ),
                  SizedBox(height: 24.h),

                  // Menu Grid
                  if (isAdmin) ...[
                    _buildMenuRow(
                      context,
                      title: 'Assign Work',
                      subtitle: 'Create & delegate new tasks to team members',
                      icon: Icons.assignment_turned_in_rounded,
                      color: const Color(0xFF3B82F6),
                      route: '/admin/assign-work',
                    ),
                    SizedBox(height: 12.h),
                    _buildMenuRow(
                      context,
                      title: 'Companies',
                      subtitle: 'Manage clients, directories, and contact info',
                      icon: Icons.business_rounded,
                      color: const Color(0xFF10B981),
                      route: '/admin/companies',
                    ),
                    SizedBox(height: 12.h),
                    _buildMenuRow(
                      context,
                      title: 'Projects',
                      subtitle: 'Track project milestones and configurations',
                      icon: Icons.account_tree_rounded,
                      color: const Color(0xFF8B5CF6),
                      route: '/admin/projects',
                    ),
                    SizedBox(height: 12.h),
                    _buildMenuRow(
                      context,
                      title: 'Work Reports',
                      subtitle: 'Analyze project progress & team productivity',
                      icon: Icons.insights_rounded,
                      color: const Color(0xFFF59E0B),
                      route: '/admin/work-reports',
                    ),
                    SizedBox(height: 12.h),
                    _buildMenuRow(
                      context,
                      title: 'Daily Updates',
                      subtitle: 'Review team standups and translation logs',
                      icon: Icons.history_edu_rounded,
                      color: const Color(0xFFEC4899),
                      route: '/admin/work-updates', // existing admin updates
                    ),
                  ] else ...[
                    _buildMenuRow(
                      context,
                      title: 'My Tasks',
                      subtitle: 'View your assigned work, progress & timeline',
                      icon: Icons.task_alt_rounded,
                      color: const Color(0xFF3B82F6),
                      route: '/employee/my-tasks',
                    ),
                    SizedBox(height: 12.h),
                    _buildMenuRow(
                      context,
                      title: 'Daily Updates',
                      subtitle: 'Submit daily task standups with voice reports',
                      icon: Icons.keyboard_voice_rounded,
                      color: const Color(0xFFEC4899),
                      route:
                          '/employee/my-tasks', // Will access via My Tasks or menu
                    ),
                  ],
                  SizedBox(height: 24.h),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildMenuRow(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String route,
  }) {
    final glassColor = Colors.white.withOpacity(0.08);
    final borderColor = Colors.white.withOpacity(0.12);
    const textColor = Colors.white;
    const subTextColor = Color(0xFF94A3B8);

    return Container(
      decoration: BoxDecoration(
        color: glassColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (title == 'Daily Updates' && userRole.value == 'employee') {
              // For daily updates, direct employees to their tasks so they choose which task to update
              Get.toNamed('/employee/my-tasks');
              Get.rawSnackbar(
                title: 'Select a Task',
                message:
                    'Please tap "Daily Update" on the specific task you worked on.',
                backgroundColor: const Color(0xFF3B82F6),
              );
            } else {
              Get.toNamed(route);
            }
          },
          borderRadius: BorderRadius.circular(16.r),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            child: Row(
              children: [
                // Icon bubble
                Container(
                  width: 48.w,
                  height: 48.h,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: color.withOpacity(0.3), width: 1),
                  ),
                  child: Icon(icon, color: color, size: 24.sp),
                ),
                SizedBox(width: 14.w),
                // Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 11.sp,
                          color: subTextColor,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: subTextColor.withOpacity(0.5),
                  size: 14.sp,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
