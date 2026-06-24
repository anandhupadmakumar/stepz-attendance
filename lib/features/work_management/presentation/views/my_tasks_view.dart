import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:stepz_attendance/core/theme/premium_background.dart';
import '../controllers/work_task_controller.dart';
import '../../models/task_model.dart';

class MyTasksView extends StatefulWidget {
  const MyTasksView({super.key});

  @override
  State<MyTasksView> createState() => _MyTasksViewState();
}

class _MyTasksViewState extends State<MyTasksView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final WorkTaskController controller = Get.put(WorkTaskController());
  final RxString localSearchQuery = ''.obs;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    controller.fetchTasks();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<TaskModel> _filterTasksByStatus(List<TaskModel> tasks, String tabName) {
    // Apply local search query first
    var filtered = tasks;
    if (localSearchQuery.value.trim().isNotEmpty) {
      final query = localSearchQuery.value.toLowerCase().trim();
      filtered = tasks.where((t) {
        final compName = controller.getCompanyName(t.companyId).toLowerCase();
        final projName = controller.getProjectName(t.projectId).toLowerCase();
        return t.taskTitle.toLowerCase().contains(query) ||
            t.taskType.toLowerCase().contains(query) ||
            compName.contains(query) ||
            projName.contains(query);
      }).toList();
    }

    switch (tabName) {
      case 'Pending':
        return filtered.where((t) => t.status == 'Pending').toList();
      case 'In Progress':
        return filtered.where((t) => t.status == 'In Progress').toList();
      case 'Completed':
        return filtered.where((t) => t.status == 'Completed').toList();
      default:
        return filtered; // 'All'
    }
  }

  @override
  Widget build(BuildContext context) {
    const textColor = Colors.white;
    const subTextColor = Color(0xFF94A3B8);
    final borderColor = Colors.white.withOpacity(0.12);

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
            'My Tasks',
            style: GoogleFonts.outfit(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.refresh_rounded, color: textColor),
              onPressed: () => controller.fetchTasks(),
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            isScrollable: false,
            indicatorColor: const Color(0xFF3B82F6),
            labelColor: const Color(0xFF3B82F6),
            unselectedLabelColor: subTextColor,
            labelStyle: GoogleFonts.inter(
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
            ),
            tabs: const [
              Tab(text: 'All'),
              Tab(text: 'Pending'),
              Tab(text: 'Active'),
              Tab(text: 'Done'),
            ],
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Local Search Input
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                child: Container(
                  height: 40.h,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(color: borderColor),
                  ),
                  child: TextField(
                    onChanged: (val) => localSearchQuery.value = val,
                    style: GoogleFonts.inter(fontSize: 13.sp, color: textColor),
                    decoration: InputDecoration(
                      hintText: 'Search tasks...',
                      hintStyle: GoogleFonts.inter(
                        color: subTextColor.withOpacity(0.6),
                        fontSize: 12.sp,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: subTextColor,
                        size: 16.sp,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 8.h),
                    ),
                  ),
                ),
              ),

              // Tasks View TabBarView
              Expanded(
                child: Obx(() {
                  if (controller.isLoadingTasks.value) {
                    return const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF3B82F6),
                        ),
                      ),
                    );
                  }

                  final allTasks = controller.myTasks;

                  return TabBarView(
                    controller: _tabController,
                    children: [
                      _buildTaskList(allTasks, 'All'),
                      _buildTaskList(allTasks, 'Pending'),
                      _buildTaskList(allTasks, 'In Progress'),
                      _buildTaskList(allTasks, 'Completed'),
                    ],
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaskList(List<TaskModel> tasks, String tabName) {
    final filtered = _filterTasksByStatus(tasks, tabName);
    const subTextColor = Color(0xFF94A3B8);
    const textColor = Colors.white;

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.checklist_rounded,
              size: 48.sp,
              color: subTextColor.withOpacity(0.3),
            ),
            SizedBox(height: 12.h),
            Text(
              'No tasks in this category',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 32.h),
      physics: const BouncingScrollPhysics(),
      itemCount: filtered.length,
      separatorBuilder: (_, __) => SizedBox(height: 12.h),
      itemBuilder: (context, index) {
        final task = filtered[index];
        return _buildTaskCard(task);
      },
    );
  }

  Widget _buildTaskCard(TaskModel task) {
    final glassColor = Colors.white.withOpacity(0.08);
    final borderColor = Colors.white.withOpacity(0.12);
    const textColor = Colors.white;
    const subTextColor = Color(0xFF94A3B8);

    final priorityColor = _getPriorityColor(task.priority);
    final statusColor = _getStatusColor(task.status);
    final compName = controller.getCompanyName(task.companyId);
    final projName = controller.getProjectName(task.projectId);

    final dateFormat = DateFormat('MMM dd, yyyy');
    final dueStr = task.dueDate != null
        ? dateFormat.format(task.dueDate!)
        : 'N/A';

    return Container(
      decoration: BoxDecoration(
        color: glassColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16.r),
          onTap: () => Get.toNamed('/work-task/details', arguments: task),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Priority & Type badges
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 6.w,
                        vertical: 3.h,
                      ),
                      decoration: BoxDecoration(
                        color: priorityColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Text(
                        '${task.priority} Priority',
                        style: GoogleFonts.inter(
                          fontSize: 9.sp,
                          fontWeight: FontWeight.bold,
                          color: priorityColor,
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 6.w,
                        vertical: 3.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Text(
                        task.taskType,
                        style: GoogleFonts.inter(
                          fontSize: 9.sp,
                          color: Colors.blue.shade400,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(
                        task.status,
                        style: GoogleFonts.inter(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10.h),

                // Task Title
                Text(
                  task.taskTitle,
                  style: GoogleFonts.inter(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                SizedBox(height: 2.h),

                // Project Association
                Text(
                  '$projName ($compName)',
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    color: subTextColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 10.h),

                // Progress Indicator Bar
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4.r),
                        child: LinearProgressIndicator(
                          value: task.progress / 100.0,
                          backgroundColor: Colors.white12,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            statusColor,
                          ),
                          minHeight: 6.h,
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      '${task.progress.toInt()}%',
                      style: GoogleFonts.inter(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ],
                ),

                const Divider(height: 20, color: Colors.white10),

                // Dates & Work allocation
                Row(
                  children: [
                    Icon(
                      Icons.calendar_month_outlined,
                      size: 14.sp,
                      color: subTextColor,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      'Due: $dueStr',
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        color: subTextColor,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.hourglass_empty_rounded,
                      size: 14.sp,
                      color: subTextColor,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      'Est: ${task.estimatedHours}h',
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        color: subTextColor,
                      ),
                    ),
                  ],
                ),

                // Action Buttons for fast flow
                if (task.status != 'Completed') ...[
                  const Divider(height: 20, color: Colors.white10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (task.status == 'Pending')
                        ElevatedButton.icon(
                          onPressed: () => controller.updateTaskStatus(
                            task.taskId,
                            'In Progress',
                          ),
                          icon: Icon(Icons.play_arrow_rounded, size: 16.sp),
                          label: const Text('Start Work'),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12.w,
                              vertical: 6.h,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                          ),
                        ),
                      if (task.status == 'In Progress') ...[
                        OutlinedButton.icon(
                          onPressed: () => _openProgressUpdateDialog(task),
                          icon: Icon(Icons.trending_up, size: 16.sp),
                          label: const Text('Update %'),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10.w,
                              vertical: 6.h,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        ElevatedButton.icon(
                          onPressed: () => Get.toNamed(
                            '/employee/daily-task-update',
                            arguments: task.taskId,
                          ),
                          icon: Icon(Icons.keyboard_voice_rounded, size: 16.sp),
                          label: const Text('Daily Update'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEC4899),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              horizontal: 10.w,
                              vertical: 6.h,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
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

  void _openProgressUpdateDialog(TaskModel task) {
    const textColor = Colors.white;

    final progressVal = task.progress.obs;
    final hoursController = TextEditingController();
    final summaryController = TextEditingController();

    final dialogInputDecoration = InputDecoration(
      filled: true,
      fillColor: Colors.white.withOpacity(0.04),
      labelStyle: GoogleFonts.inter(color: Colors.white60, fontSize: 13.sp),
      floatingLabelStyle: GoogleFonts.inter(color: const Color(0xFF3B82F6), fontSize: 13.sp),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.white.withOpacity(0.12), width: 1),
        borderRadius: BorderRadius.circular(8.r),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
        borderRadius: BorderRadius.circular(8.r),
      ),
      errorBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.red.shade400, width: 1),
        borderRadius: BorderRadius.circular(8.r),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
        borderRadius: BorderRadius.circular(8.r),
      ),
    );

    Get.defaultDialog(
      title: 'Update Progress',
      titleStyle: GoogleFonts.inter(
        fontWeight: FontWeight.bold,
        color: textColor,
      ),
      backgroundColor: const Color(0xFF0F172A),
      contentPadding: EdgeInsets.all(16.w),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Obx(
              () => Text(
                'Progress: ${progressVal.value.toInt()}%',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  color: textColor,
                  fontSize: 14.sp,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Obx(
              () => Slider(
                value: progressVal.value,
                min: 0,
                max: 100,
                divisions: 20,
                onChanged: (val) {
                  progressVal.value = val;
                },
              ),
            ),
            SizedBox(height: 10.h),
            TextFormField(
              controller: hoursController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: GoogleFonts.inter(color: textColor),
              decoration: dialogInputDecoration.copyWith(
                labelText: 'Hours Spent on Task Today',
                hintText: 'e.g. 3.5',
                hintStyle: GoogleFonts.inter(color: Colors.white30, fontSize: 13.sp),
              ),
            ),
            SizedBox(height: 10.h),
            TextFormField(
              controller: summaryController,
              maxLines: 2,
              style: GoogleFonts.inter(color: textColor),
              decoration: dialogInputDecoration.copyWith(
                labelText: 'Work Summary',
                hintText: 'What details did you work on?',
                hintStyle: GoogleFonts.inter(color: Colors.white30, fontSize: 13.sp),
              ),
            ),
          ],
        ),
      ),
      textConfirm: 'SAVE',
      textCancel: 'CANCEL',
      confirmTextColor: Colors.white,
      cancelTextColor: Colors.grey,
      buttonColor: const Color(0xFF3B82F6),
      onConfirm: () {
        final hours = double.tryParse(hoursController.text) ?? 0.0;
        controller.saveProgressUpdate(
          task.taskId,
          progressVal.value,
          summaryController.text.trim(),
          hours,
        );
      },
    );
  }
}
