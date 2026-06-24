import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:stepz_attendance/core/theme/premium_background.dart';
import '../controllers/project_controller.dart';
import '../../models/project_model.dart';

class ProjectManagementView extends GetView<ProjectController> {
  const ProjectManagementView({super.key});

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
            'Projects',
            style: GoogleFonts.outfit(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.refresh_rounded, color: textColor),
              onPressed: () {
                controller.fetchActiveCompanies();
                controller.fetchProjects();
              },
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Search & Add Header
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 44.h,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(color: borderColor),
                        ),
                        child: TextField(
                          onChanged: (val) =>
                              controller.searchQuery.value = val,
                          style: GoogleFonts.inter(
                            fontSize: 14.sp,
                            color: textColor,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Search projects...',
                            hintStyle: GoogleFonts.inter(
                              color: subTextColor.withOpacity(0.6),
                              fontSize: 13.sp,
                            ),
                            prefixIcon: Icon(
                              Icons.search,
                              color: subTextColor,
                              size: 18.sp,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              vertical: 10.h,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    GestureDetector(
                      onTap: () => _openProjectDialog(context, null),
                      child: Container(
                        height: 44.h,
                        width: 44.h,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF3B82F6), Color(0xFF1E3A8A)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: const Icon(Icons.add, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),

              // Projects List
              Expanded(
                child: Obx(() {
                  if (controller.isLoading.value) {
                    return const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF3B82F6),
                        ),
                      ),
                    );
                  }

                  if (controller.filteredProjects.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.account_tree_rounded,
                            size: 64.sp,
                            color: subTextColor.withOpacity(0.3),
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            'No projects found',
                            style: GoogleFonts.inter(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            'Tap the "+" button to add your first project.',
                            style: GoogleFonts.inter(
                              fontSize: 13.sp,
                              color: subTextColor,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 32.h),
                    physics: const BouncingScrollPhysics(),
                    itemCount: controller.filteredProjects.length,
                    separatorBuilder: (_, __) => SizedBox(height: 12.h),
                    itemBuilder: (context, index) {
                      final project = controller.filteredProjects[index];
                      return _buildProjectCard(context, project);
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProjectCard(BuildContext context, ProjectModel project) {
    final glassColor = Colors.white.withOpacity(0.08);
    final borderColor = Colors.white.withOpacity(0.12);
    const textColor = Colors.white;
    const subTextColor = Color(0xFF94A3B8);

    final statusColor = _getStatusColor(project.status);
    final companyName = controller.getCompanyName(project.companyId);

    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeline = (project.startDate != null)
        ? '${dateFormat.format(project.startDate!)} - ${project.endDate != null ? dateFormat.format(project.endDate!) : 'Ongoing'}'
        : 'Timeline not specified';

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: glassColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.account_tree_rounded,
                  color: statusColor,
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.projectName,
                      style: GoogleFonts.inter(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    Text(
                      'Client: ${project.clientName.isNotEmpty ? project.clientName : 'N/A'} ($companyName)',
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        color: subTextColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  project.status,
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),

          if (project.description.isNotEmpty) ...[
            SizedBox(height: 12.h),
            Text(
              project.description,
              style: GoogleFonts.inter(fontSize: 12.sp, color: subTextColor),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          const Divider(height: 24, color: Colors.white10),

          // Code & Timeline Row
          Row(
            children: [
              Icon(Icons.tag_rounded, size: 14.sp, color: subTextColor),
              SizedBox(width: 6.w),
              Text(
                project.projectCode.isNotEmpty
                    ? project.projectCode
                    : 'No Code',
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  color: textColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.calendar_month_outlined,
                size: 14.sp,
                color: subTextColor,
              ),
              SizedBox(width: 6.w),
              Text(
                timeline,
                style: GoogleFonts.inter(fontSize: 11.sp, color: subTextColor),
              ),
            ],
          ),

          const Divider(height: 24, color: Colors.white10),

          // Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: Icon(
                  Icons.info_outline_rounded,
                  size: 20.sp,
                  color: const Color(0xFF3B82F6),
                ),
                onPressed: () => _viewProjectDetails(context, project),
              ),
              IconButton(
                icon: Icon(
                  Icons.edit_outlined,
                  size: 20.sp,
                  color: Colors.amber,
                ),
                onPressed: () => _openProjectDialog(context, project),
              ),
              IconButton(
                icon: Icon(
                  Icons.delete_outline_rounded,
                  size: 20.sp,
                  color: Colors.red.shade400,
                ),
                onPressed: () {
                  Get.defaultDialog(
                    title: 'Delete Project?',
                    titleStyle: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                    middleText:
                        'Are you sure you want to delete this project? Tasks referencing this project might be affected.',
                    middleTextStyle: GoogleFonts.inter(color: subTextColor),
                    textConfirm: 'Delete',
                    textCancel: 'Cancel',
                    confirmTextColor: Colors.white,
                    cancelTextColor: textColor,
                    buttonColor: const Color(0xFFBA1A1A),
                    onConfirm: () {
                      controller.deleteProject(project.projectId);
                      Get.back();
                    },
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Active':
        return const Color(0xFF10B981);
      case 'Completed':
        return const Color(0xFF3B82F6);
      case 'On Hold':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF64748B);
    }
  }

  void _viewProjectDetails(BuildContext context, ProjectModel project) {
    const textColor = Colors.white;
    final companyName = controller.getCompanyName(project.companyId);
    final dateFormat = DateFormat('MMMM dd, yyyy');

    Get.bottomSheet(
      Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
        decoration: BoxDecoration(
          color: const Color(0xFF0F0F1A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          border: Border.all(color: Colors.white.withOpacity(0.12), width: 1.5),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  margin: EdgeInsets.only(bottom: 16.h),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
              ),
              Text(
                project.projectName,
                style: GoogleFonts.outfit(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                'Status: ${project.status}',
                style: GoogleFonts.inter(
                  fontSize: 13.sp,
                  color: _getStatusColor(project.status),
                ),
              ),
              const Divider(height: 24, color: Colors.white10),

              _detailRow('Project Code', project.projectCode),
              _detailRow('Company Client', companyName),
              _detailRow('Direct Client Name', project.clientName),
              _detailRow(
                'Start Date',
                project.startDate != null
                    ? dateFormat.format(project.startDate!)
                    : '--',
              ),
              _detailRow(
                'End Date',
                project.endDate != null
                    ? dateFormat.format(project.endDate!)
                    : '--',
              ),
              _detailRow('Description', project.description),

              SizedBox(height: 24.h),
              ElevatedButton(
                onPressed: () => Get.back(),
                child: const Text('Close Details'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 10.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white54,
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: 3.h),
          Text(
            value.isNotEmpty ? value : '--',
            style: GoogleFonts.inter(fontSize: 13.sp, color: Colors.white),
          ),
        ],
      ),
    );
  }

  void _openProjectDialog(BuildContext context, ProjectModel? project) {
    final isEdit = project != null;
    if (isEdit) {
      controller.populateForm(project);
    } else {
      controller.clearForm();
    }

    const textColor = Colors.white;
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
      title: isEdit ? 'Edit Project' : 'Add Project',
      titleStyle: GoogleFonts.inter(
        fontWeight: FontWeight.bold,
        color: textColor,
      ),
      backgroundColor: const Color(0xFF0F172A),
      contentPadding: EdgeInsets.all(16.w),
      content: SingleChildScrollView(
        child: Form(
          key: controller.formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: controller.nameController,
                style: GoogleFonts.inter(color: textColor),
                decoration: dialogInputDecoration.copyWith(labelText: 'Project Name *'),
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'Please enter project name'
                    : null,
              ),
              SizedBox(height: 10.h),
              TextFormField(
                controller: controller.codeController,
                style: GoogleFonts.inter(color: textColor),
                decoration: dialogInputDecoration.copyWith(labelText: 'Project Code'),
              ),
              SizedBox(height: 10.h),

              // Company Dropdown
              Obx(() {
                if (controller.activeCompanies.isEmpty) {
                  return const Text(
                    'No active companies registered. Please create an active company first.',
                    style: TextStyle(color: Colors.red),
                  );
                }
                return DropdownButtonFormField<String>(
                  value: controller.selectedCompanyId.value.isEmpty
                      ? null
                      : controller.selectedCompanyId.value,
                  dropdownColor: const Color(0xFF1E293B),
                  style: GoogleFonts.inter(color: textColor),
                  items: controller.activeCompanies.map((c) {
                    return DropdownMenuItem(
                      value: c.companyId,
                      child: Text(c.companyName),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) controller.selectedCompanyId.value = val;
                  },
                  decoration: dialogInputDecoration.copyWith(
                    labelText: 'Client Company *',
                  ),
                  validator: (val) => val == null || val.isEmpty
                      ? 'Please select a company'
                      : null,
                );
              }),
              SizedBox(height: 10.h),

              TextFormField(
                controller: controller.clientController,
                style: GoogleFonts.inter(color: textColor),
                decoration: dialogInputDecoration.copyWith(
                  labelText: 'Direct Client Name (Optional)',
                ),
              ),
              SizedBox(height: 10.h),
              TextFormField(
                controller: controller.descriptionController,
                maxLines: 2,
                style: GoogleFonts.inter(color: textColor),
                decoration: dialogInputDecoration.copyWith(labelText: 'Description'),
              ),
              SizedBox(height: 10.h),

              // Status Dropdown
              DropdownButtonFormField<String>(
                value: controller.status.value,
                dropdownColor: const Color(0xFF1E293B),
                style: GoogleFonts.inter(color: textColor),
                items: ['Active', 'Completed', 'On Hold'].map((s) {
                  return DropdownMenuItem(value: s, child: Text(s));
                }).toList(),
                onChanged: (val) {
                  if (val != null) controller.status.value = val;
                },
                decoration: dialogInputDecoration.copyWith(labelText: 'Status'),
              ),
              SizedBox(height: 12.h),

              // Start Date & End Date pickers
              Row(
                children: [
                  Expanded(
                    child: Obx(() {
                      final dateStr = controller.startDate.value != null
                          ? DateFormat(
                              'yyyy-MM-dd',
                            ).format(controller.startDate.value!)
                          : 'Select Date';
                      return InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate:
                                controller.startDate.value ?? DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            controller.startDate.value = picked;
                          }
                        },
                        child: InputDecorator(
                          decoration: dialogInputDecoration.copyWith(
                            labelText: 'Start Date',
                          ),
                          child: Text(
                            dateStr,
                            style: GoogleFonts.inter(
                              color: textColor,
                              fontSize: 13.sp,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Obx(() {
                      final dateStr = controller.endDate.value != null
                          ? DateFormat(
                              'yyyy-MM-dd',
                            ).format(controller.endDate.value!)
                          : 'Select Date';
                      return InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate:
                                controller.endDate.value ?? DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            controller.endDate.value = picked;
                          }
                        },
                        child: InputDecorator(
                          decoration: dialogInputDecoration.copyWith(
                            labelText: 'End Date',
                          ),
                          child: Text(
                            dateStr,
                            style: GoogleFonts.inter(
                              color: textColor,
                              fontSize: 13.sp,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      textConfirm: isEdit ? 'UPDATE' : 'SAVE',
      textCancel: 'CANCEL',
      confirmTextColor: Colors.white,
      cancelTextColor: Colors.grey,
      buttonColor: const Color(0xFF3B82F6),
      onConfirm: () {
        if (isEdit) {
          controller.editProject(project.projectId);
        } else {
          controller.addProject();
        }
      },
    );
  }
}
