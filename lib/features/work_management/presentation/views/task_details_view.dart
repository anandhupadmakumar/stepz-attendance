import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stepz_attendance/core/theme/premium_background.dart';
import '../controllers/work_task_controller.dart';
import '../../models/task_model.dart';

class TaskDetailsView extends StatefulWidget {
  const TaskDetailsView({super.key});

  @override
  State<TaskDetailsView> createState() => _TaskDetailsViewState();
}

class _TaskDetailsViewState extends State<TaskDetailsView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final WorkTaskController controller = Get.find<WorkTaskController>();
  late TaskModel task;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    task = Get.arguments as TaskModel;
    controller.fetchComments(task.taskId);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
            'Task Details',
            style: GoogleFonts.outfit(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.refresh_rounded, color: textColor),
              onPressed: () => controller.fetchComments(task.taskId),
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: const Color(0xFF3B82F6),
            labelColor: const Color(0xFF3B82F6),
            unselectedLabelColor: subTextColor,
            labelStyle: GoogleFonts.inter(
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
            ),
            tabs: const [
              Tab(text: 'Overview'),
              Tab(text: 'Comments'),
              Tab(text: 'Activity Log'),
            ],
          ),
        ),
        body: SafeArea(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(),
              _buildCommentsTab(),
              _buildActivityTab(),
            ],
          ),
        ),
      ),
    );
  }

  // --- OVERVIEW TAB ---
  Widget _buildOverviewTab() {
    final glassColor = Colors.white.withOpacity(0.08);
    final borderColor = Colors.white.withOpacity(0.12);
    const textColor = Colors.white;
    const subTextColor = Color(0xFF94A3B8);

    final statusColor = _getStatusColor(task.status);
    final priorityColor = _getPriorityColor(task.priority);
    final dateFormat = DateFormat('MMMM dd, yyyy');

    final compName = controller.getCompanyName(task.companyId);
    final projName = controller.getProjectName(task.projectId);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Card (Title, Category, Status, Priority)
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: glassColor,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: borderColor, width: 1.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: priorityColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(
                        '${task.priority} Priority',
                        style: GoogleFonts.inter(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.bold,
                          color: priorityColor,
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(
                        task.taskType,
                        style: GoogleFonts.inter(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade400,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 5.h,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(
                        task.status,
                        style: GoogleFonts.inter(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 14.h),
                Text(
                  task.taskTitle,
                  style: GoogleFonts.inter(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Project: $projName ($compName)',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    color: subTextColor,
                  ),
                ),
                const Divider(height: 24, color: Colors.white10),

                // Progress
                Row(
                  children: [
                    Text(
                      'Completion Progress',
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        color: subTextColor,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${task.progress.toInt()}%',
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6.h),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4.r),
                  child: LinearProgressIndicator(
                    value: task.progress / 100.0,
                    backgroundColor: Colors.white12,
                    valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                    minHeight: 8.h,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),

          // Timeline & Allocation Info
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: glassColor,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: borderColor, width: 1.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoRow(
                  context,
                  Icons.calendar_today_rounded,
                  'Start Date',
                  task.startDate != null
                      ? dateFormat.format(task.startDate!)
                      : 'Not set',
                ),
                SizedBox(height: 12.h),
                _infoRow(
                  context,
                  Icons.event_busy_rounded,
                  'Due Date',
                  task.dueDate != null
                      ? dateFormat.format(task.dueDate!)
                      : 'Not set',
                ),
                SizedBox(height: 12.h),
                _infoRow(
                  context,
                  Icons.hourglass_empty_rounded,
                  'Estimated Effort',
                  '${task.estimatedHours} Hours',
                ),
                SizedBox(height: 12.h),
                _infoRow(
                  context,
                  Icons.link_rounded,
                  'Dependencies',
                  task.dependencies,
                ),
                SizedBox(height: 12.h),
                _infoRow(
                  context,
                  Icons.assignment_ind_outlined,
                  'Assigned By UID',
                  task.assignedBy,
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),

          // Task Details / Description
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: glassColor,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: borderColor, width: 1.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Task Description',
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  task.taskDetails.isNotEmpty
                      ? task.taskDetails
                      : 'No description provided.',
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    color: subTextColor,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),

          // Acceptance Criteria
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: glassColor,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: borderColor, width: 1.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Acceptance Criteria (Definition of Done)',
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  task.acceptanceCriteria.isNotEmpty
                      ? task.acceptanceCriteria
                      : 'Standard checklist applies.',
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    color: subTextColor,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),

          // Assigned Employees
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: glassColor,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: borderColor, width: 1.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Assigned Team Members',
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                SizedBox(height: 8.h),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: task.employeeIds.length,
                  itemBuilder: (context, index) {
                    final empUid = task.employeeIds[index];
                    final emp = controller.employeesList.firstWhereOrNull(
                      (e) => e['uid'] == empUid,
                    );
                    final name = emp?['name'] ?? 'Team Member';
                    final empId = emp?['employeeId'] ?? 'EMP-000';

                    return Padding(
                      padding: EdgeInsets.only(bottom: 6.h),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 14.r,
                            backgroundColor: Colors.blue.withOpacity(0.2),
                            child: Text(
                              name[0].toUpperCase(),
                              style: TextStyle(
                                fontSize: 10.sp,
                                color: Colors.blue.shade400,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: Text(
                              '$name ($empId)',
                              style: GoogleFonts.inter(
                                fontSize: 13.sp,
                                color: textColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),

          // Attachments
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: glassColor,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: borderColor, width: 1.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reference Documents & Files',
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                SizedBox(height: 8.h),
                if (task.attachmentUrls.isEmpty)
                  Text(
                    'No attachments present.',
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      color: subTextColor,
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: task.attachmentUrls.length,
                    itemBuilder: (context, idx) {
                      final url = task.attachmentUrls[idx];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        leading: const Icon(
                          Icons.insert_drive_file_outlined,
                          color: Colors.amber,
                        ),
                        title: Text(
                          url,
                          style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            color: textColor,
                          ),
                        ),
                        onTap: () {
                          Get.rawSnackbar(
                            title: 'Simulated File Download',
                            message: 'Downloading file: $url',
                            backgroundColor: Colors.blue.shade800,
                          );
                        },
                      );
                    },
                  ),
              ],
            ),
          ),

          if (task.remarks.isNotEmpty) ...[
            SizedBox(height: 16.h),
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.06),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: Colors.amber.withOpacity(0.2),
                  width: 1.2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Remarks & Notes',
                    style: GoogleFonts.inter(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber.shade400,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    task.remarks,
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      color: Colors.amber.shade200,
                    ),
                  ),
                ],
              ),
            ),
          ],

          SizedBox(height: 32.h),
        ],
      ),
    );
  }

  Widget _infoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    const textColor = Colors.white;
    const subTextColor = Color(0xFF94A3B8);

    return Row(
      children: [
        Icon(icon, size: 16.sp, color: subTextColor),
        SizedBox(width: 10.w),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 12.sp, color: subTextColor),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 12.sp,
            color: textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // --- COMMENTS/DISCUSSION TAB ---
  Widget _buildCommentsTab() {
    const textColor = Colors.white;
    const subTextColor = Color(0xFF94A3B8);
    final borderColor = Colors.white.withOpacity(0.12);

    final commentFormat = DateFormat('MMM dd, hh:mm a');

    return Column(
      children: [
        // Comments List
        Expanded(
          child: Obx(() {
            if (controller.isLoadingComments.value) {
              return const Center(child: CircularProgressIndicator());
            }

            if (controller.taskComments.isEmpty) {
              return Center(
                child: Text(
                  'No comments yet. Start the discussion!',
                  style: GoogleFonts.inter(
                    color: subTextColor,
                    fontSize: 13.sp,
                  ),
                ),
              );
            }

            return ListView.separated(
              padding: EdgeInsets.all(16.w),
              physics: const BouncingScrollPhysics(),
              itemCount: controller.taskComments.length,
              separatorBuilder: (_, __) => SizedBox(height: 12.h),
              itemBuilder: (context, idx) {
                final comment = controller.taskComments[idx];
                final userName = comment['userName'] ?? 'User';
                final text = comment['commentText'] ?? '';

                DateTime? time;
                if (comment['createdAt'] is Timestamp) {
                  time = (comment['createdAt'] as Timestamp).toDate();
                }

                return Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 10.r,
                            backgroundColor: Colors.blue.withOpacity(0.1),
                            child: Text(
                              userName[0].toUpperCase(),
                              style: TextStyle(fontSize: 8.sp),
                            ),
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            userName,
                            style: GoogleFonts.inter(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          const Spacer(),
                          if (time != null)
                            Text(
                              commentFormat.format(time),
                              style: GoogleFonts.inter(
                                fontSize: 9.sp,
                                color: subTextColor,
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        text,
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          }),
        ),

        // Comment Input Area
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: const Color(0xFF0F0F1A),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 40.h,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(color: borderColor),
                  ),
                  child: TextField(
                    controller: controller.commentController,
                    style: GoogleFonts.inter(fontSize: 13.sp, color: textColor),
                    decoration: InputDecoration(
                      hintText: 'Write a comment...',
                      hintStyle: GoogleFonts.inter(
                        color: subTextColor.withOpacity(0.6),
                        fontSize: 12.sp,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 8.h,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              IconButton(
                icon: const Icon(Icons.send_rounded, color: Color(0xFF3B82F6)),
                onPressed: () {
                  controller.addTaskComment(
                    task.taskId,
                    controller.commentController.text,
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- ACTIVITY TAB ---
  Widget _buildActivityTab() {
    const textColor = Colors.white;
    const subTextColor = Color(0xFF94A3B8);
    final borderColor = Colors.white.withOpacity(0.12);

    final activityFormat = DateFormat('MMM dd, hh:mm a');

    return Obx(() {
      if (controller.isLoadingComments.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.taskActivity.isEmpty) {
        return Center(
          child: Text(
            'No logged activity for this task yet.',
            style: GoogleFonts.inter(color: subTextColor, fontSize: 13.sp),
          ),
        );
      }

      return ListView.builder(
        padding: EdgeInsets.all(16.w),
        physics: const BouncingScrollPhysics(),
        itemCount: controller.taskActivity.length,
        itemBuilder: (context, idx) {
          final log = controller.taskActivity[idx];
          final action = log['action'] ?? 'Activity';
          final desc = log['description'] ?? '';

          DateTime? time;
          if (log['createdAt'] is Timestamp) {
            time = (log['createdAt'] as Timestamp).toDate();
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Timeline line and circle
              Column(
                children: [
                  Container(
                    width: 12.w,
                    height: 12.h,
                    decoration: BoxDecoration(
                      color: _getActivityColor(action),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                  if (idx != controller.taskActivity.length - 1)
                    Container(width: 2.w, height: 50.h, color: borderColor),
                ],
              ),
              SizedBox(width: 14.w),
              // Activity text
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: 24.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            action,
                            style: GoogleFonts.inter(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          const Spacer(),
                          if (time != null)
                            Text(
                              activityFormat.format(time),
                              style: GoogleFonts.inter(
                                fontSize: 9.sp,
                                color: subTextColor,
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 3.h),
                      Text(
                        desc,
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          color: subTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      );
    });
  }

  Color _getActivityColor(String action) {
    if (action.contains('Created')) {
      return Colors.green;
    } else if (action.contains('Status')) {
      return Colors.blue;
    } else if (action.contains('Progress')) {
      return Colors.purple;
    } else if (action.contains('Comment')) {
      return Colors.amber;
    }
    return Colors.grey;
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'Critical':
        return const Color(0xFFEF4444);
      case 'High':
        return const Color(0xFFF59E0B);
      case 'Medium':
        return const Color(0xFF3B82F6);
      default:
        return const Color(0xFF10B981);
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Completed':
        return const Color(0xFF10B981);
      case 'In Progress':
        return const Color(0xFF3B82F6);
      case 'Review':
        return const Color(0xFF8B5CF6);
      default:
        return const Color(0xFF64748B);
    }
  }
}
