import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:stepz_attendance/core/theme/premium_background.dart';
import '../controllers/work_task_controller.dart';

class AssignWorkView extends GetView<WorkTaskController> {
  const AssignWorkView({super.key});

  @override
  Widget build(BuildContext context) {
    const textColor = Colors.white;
    const subTextColor = Color(0xFF94A3B8);
    final borderColor = Colors.white.withOpacity(0.12);
    final glassColor = Colors.white.withOpacity(0.08);

    final inputDecoration = InputDecoration(
      filled: true,
      fillColor: Colors.white.withOpacity(0.04),
      labelStyle: GoogleFonts.inter(color: Colors.white60, fontSize: 13.sp),
      floatingLabelStyle: GoogleFonts.inter(
        color: const Color(0xFF3B82F6),
        fontSize: 13.sp,
      ),
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
            'Assign Work',
            style: GoogleFonts.outfit(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          actions: [
            TextButton.icon(
              onPressed: () => controller.saveDraft(),
              icon: Icon(
                Icons.bookmark_added_rounded,
                color: const Color(0xFF3B82F6),
                size: 18.sp,
              ),
              label: Text(
                'Save Draft',
                style: GoogleFonts.inter(
                  color: const Color(0xFF3B82F6),
                  fontWeight: FontWeight.bold,
                  fontSize: 13.sp,
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            child: Form(
              key: controller.assignFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Client & Project Card
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
                          'Client & Project Association',
                          style: GoogleFonts.inter(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const Divider(height: 20, color: Colors.white10),

                        // Company Dropdown
                        Obx(() {
                          if (controller.companies.isEmpty) {
                            return const Text(
                              'No active companies registered. Go to Companies section first.',
                              style: TextStyle(color: Colors.red),
                            );
                          }
                          return DropdownButtonFormField<String>(
                            value: controller.selectedCompanyId.value.isEmpty
                                ? null
                                : controller.selectedCompanyId.value,
                            dropdownColor: const Color(0xFF1E293B),
                            style: GoogleFonts.inter(color: textColor),
                            items: controller.companies.map((c) {
                              return DropdownMenuItem(
                                value: c.companyId,
                                child: Text(c.companyName),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                controller.filterProjectsByCompany(val);
                              }
                            },
                            decoration: inputDecoration.copyWith(
                              labelText: 'Company Client *',
                            ),
                            validator: (val) => val == null || val.isEmpty
                                ? 'Please select a company'
                                : null,
                          );
                        }),
                        SizedBox(height: 12.h),

                        // Project Dropdown
                        Obx(() {
                          if (controller.filteredProjects.isEmpty) {
                            return Text(
                              'No active projects registered for this company.',
                              style: GoogleFonts.inter(
                                color: Colors.amber.shade700,
                                fontSize: 12.sp,
                              ),
                            );
                          }
                          return DropdownButtonFormField<String>(
                            value: controller.selectedProjectId.value.isEmpty
                                ? null
                                : controller.selectedProjectId.value,
                            dropdownColor: const Color(0xFF1E293B),
                            style: GoogleFonts.inter(color: textColor),
                            items: controller.filteredProjects.map((p) {
                              return DropdownMenuItem(
                                value: p.projectId,
                                child: Text(p.projectName),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                controller.selectedProjectId.value = val;
                              }
                            },
                            decoration: inputDecoration.copyWith(
                              labelText: 'Associated Project *',
                            ),
                            validator: (val) => val == null || val.isEmpty
                                ? 'Please select a project'
                                : null,
                          );
                        }),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // Task Metadata Card
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
                          'Task Configuration',
                          style: GoogleFonts.inter(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const Divider(height: 20, color: Colors.white10),

                        // Task Title
                        TextFormField(
                          controller: controller.taskTitleController,
                          style: GoogleFonts.inter(color: textColor),
                          decoration: inputDecoration.copyWith(
                            labelText: 'Task Title *',
                            hintText: 'Enter short descriptive title',
                            hintStyle: GoogleFonts.inter(
                              color: Colors.white30,
                              fontSize: 13.sp,
                            ),
                          ),
                          validator: (val) => val == null || val.trim().isEmpty
                              ? 'Please enter task title'
                              : null,
                        ),
                        SizedBox(height: 12.h),

                        // Task Type Dropdown
                        DropdownButtonFormField<String>(
                          value: controller.selectedTaskType.value,
                          dropdownColor: const Color(0xFF1E293B),
                          style: GoogleFonts.inter(color: textColor),
                          items:
                              [
                                'Feature Development',
                                'Bug Fix',
                                'Maintenance',
                                'Documentation',
                                'Design',
                                'Research',
                                'Testing',
                              ].map((t) {
                                return DropdownMenuItem(
                                  value: t,
                                  child: Text(t),
                                );
                              }).toList(),
                          onChanged: (val) {
                            if (val != null)
                              controller.selectedTaskType.value = val;
                          },
                          decoration: inputDecoration.copyWith(
                            labelText: 'Task Category',
                          ),
                        ),
                        SizedBox(height: 12.h),

                        // Priority & Dependency Row
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: controller.selectedPriority.value,
                                dropdownColor: const Color(0xFF1E293B),
                                style: GoogleFonts.inter(color: textColor),
                                items: ['Low', 'Medium', 'High', 'Critical']
                                    .map((p) {
                                      return DropdownMenuItem(
                                        value: p,
                                        child: Text(p),
                                      );
                                    })
                                    .toList(),
                                onChanged: (val) {
                                  if (val != null)
                                    controller.selectedPriority.value = val;
                                },
                                decoration: inputDecoration.copyWith(
                                  labelText: 'Priority',
                                ),
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: controller.selectedDependency.value,
                                dropdownColor: const Color(0xFF1E293B),
                                style: GoogleFonts.inter(color: textColor),
                                items:
                                    [
                                      'None',
                                      'Waiting for Design',
                                      'Waiting for Backend API',
                                      'Blocked by Third-Party',
                                      'Waiting on Client Info',
                                    ].map((d) {
                                      return DropdownMenuItem(
                                        value: d,
                                        child: Text(d),
                                      );
                                    }).toList(),
                                onChanged: (val) {
                                  if (val != null)
                                    controller.selectedDependency.value = val;
                                },
                                decoration: inputDecoration.copyWith(
                                  labelText: 'Dependencies',
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12.h),

                        // Estimated Hours
                        TextFormField(
                          controller: controller.estimatedHoursController,
                          style: GoogleFonts.inter(color: textColor),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: inputDecoration.copyWith(
                            labelText: 'Estimated Hours',
                            hintText: 'e.g. 12.5',
                            hintStyle: GoogleFonts.inter(
                              color: Colors.white30,
                              fontSize: 13.sp,
                            ),
                          ),
                          validator: (val) {
                            if (val != null && val.isNotEmpty) {
                              if (double.tryParse(val) == null) {
                                return 'Please enter a valid number';
                              }
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // Assignment & Schedule Card
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
                          'Team Allocation & Schedule',
                          style: GoogleFonts.inter(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const Divider(height: 20, color: Colors.white10),

                        // Select Employees Button and list of selected
                        Row(
                          children: [
                            Text(
                              'Assigned Members *',
                              style: GoogleFonts.inter(
                                fontSize: 13.sp,
                                color: subTextColor,
                              ),
                            ),
                            const Spacer(),
                            TextButton.icon(
                              onPressed: () =>
                                  _showEmployeeSelectionDialog(context),
                              icon: const Icon(
                                Icons.person_add_alt_rounded,
                                color: Colors.blue,
                              ),
                              label: Text(
                                'Add/Modify',
                                style: GoogleFonts.inter(color: Colors.blue),
                              ),
                            ),
                          ],
                        ),
                        Obx(() {
                          if (controller.selectedEmployeeUids.isEmpty) {
                            return Container(
                              padding: EdgeInsets.symmetric(
                                vertical: 12.h,
                                horizontal: 16.w,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(10.r),
                                border: Border.all(
                                  color: Colors.red.withOpacity(0.2),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  'No team members assigned yet',
                                  style: GoogleFonts.inter(
                                    color: Colors.red.shade400,
                                    fontSize: 12.sp,
                                  ),
                                ),
                              ),
                            );
                          }

                          return Wrap(
                            spacing: 8.w,
                            runSpacing: 8.h,
                            children: controller.selectedEmployeeUids.map((
                              uid,
                            ) {
                              final emp = controller.employeesList
                                  .firstWhereOrNull((e) => e['uid'] == uid);
                              final empName = emp?['name'] ?? 'Employee';
                              return Chip(
                                backgroundColor: Colors.white.withOpacity(0.1),
                                side: BorderSide(color: borderColor),
                                label: Text(
                                  empName,
                                  style: GoogleFonts.inter(
                                    color: Colors.black,
                                    fontSize: 12.sp,
                                  ),
                                ),
                                deleteIcon: Icon(
                                  Icons.close,
                                  size: 14.sp,
                                  color: Colors.red.shade400,
                                ),
                                onDeleted: () {
                                  controller.selectedEmployeeUids.remove(uid);
                                },
                              );
                            }).toList(),
                          );
                        }),
                        SizedBox(height: 16.h),

                        // Timeline Picker (Start Date & Due Date)
                        Row(
                          children: [
                            Expanded(
                              child: Obx(() {
                                final dateStr =
                                    controller.startDate.value != null
                                    ? DateFormat(
                                        'yyyy-MM-dd',
                                      ).format(controller.startDate.value!)
                                    : 'Select Date';
                                return InkWell(
                                  onTap: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate:
                                          controller.startDate.value ??
                                          DateTime.now(),
                                      firstDate: DateTime.now().subtract(
                                        const Duration(days: 30),
                                      ),
                                      lastDate: DateTime.now().add(
                                        const Duration(days: 365),
                                      ),
                                    );
                                    if (picked != null) {
                                      controller.startDate.value = picked;
                                    }
                                  },
                                  child: InputDecorator(
                                    decoration: inputDecoration.copyWith(
                                      labelText: 'Start Date *',
                                    ),
                                    child: Text(
                                      dateStr,
                                      style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontSize: 13.sp,
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Obx(() {
                                final dateStr = controller.dueDate.value != null
                                    ? DateFormat(
                                        'yyyy-MM-dd',
                                      ).format(controller.dueDate.value!)
                                    : 'Select Date';
                                return InkWell(
                                  onTap: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate:
                                          controller.dueDate.value ??
                                          DateTime.now().add(
                                            const Duration(days: 7),
                                          ),
                                      firstDate: DateTime.now().subtract(
                                        const Duration(days: 30),
                                      ),
                                      lastDate: DateTime.now().add(
                                        const Duration(days: 365),
                                      ),
                                    );
                                    if (picked != null) {
                                      controller.dueDate.value = picked;
                                    }
                                  },
                                  child: InputDecorator(
                                    decoration: inputDecoration.copyWith(
                                      labelText: 'Due Date *',
                                    ),
                                    child: Text(
                                      dateStr,
                                      style: GoogleFonts.inter(
                                        color: Colors.white,
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
                  SizedBox(height: 16.h),

                  // Detailed Documentation Card
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
                          'Task Description & Acceptance Criteria',
                          style: GoogleFonts.inter(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const Divider(height: 20, color: Colors.white10),

                        // Task Details
                        TextFormField(
                          controller: controller.taskDetailsController,
                          maxLines: 4,
                          style: GoogleFonts.inter(color: textColor),
                          decoration: inputDecoration.copyWith(
                            labelText: 'Task Details',
                            hintText:
                                'Enter comprehensive details about the task tasks, constraints, or links...',
                            hintStyle: GoogleFonts.inter(
                              color: Colors.white30,
                              fontSize: 13.sp,
                            ),
                          ),
                        ),
                        SizedBox(height: 12.h),

                        // Acceptance Criteria
                        TextFormField(
                          controller: controller.acceptanceCriteriaController,
                          maxLines: 3,
                          style: GoogleFonts.inter(color: textColor),
                          decoration: inputDecoration.copyWith(
                            labelText: 'Acceptance Criteria',
                            hintText:
                                'Definition of Done (e.g. 1. Code compiled without errors, 2. Unit tests pass)',
                            hintStyle: GoogleFonts.inter(
                              color: Colors.white30,
                              fontSize: 13.sp,
                            ),
                          ),
                        ),
                        SizedBox(height: 12.h),

                        // Remarks
                        TextFormField(
                          controller: controller.remarksController,
                          maxLines: 2,
                          style: GoogleFonts.inter(color: textColor),
                          decoration: inputDecoration.copyWith(
                            labelText: 'Remarks / Admin Notes',
                            hintText:
                                'Any specific instructions, deadlines, or client specific notifications',
                            hintStyle: GoogleFonts.inter(
                              color: Colors.white30,
                              fontSize: 13.sp,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // Mockup Attachments Section
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
                            Text(
                              'Attachments',
                              style: GoogleFonts.inter(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            const Spacer(),
                            TextButton.icon(
                              onPressed: () {
                                // Simulate adding attachment
                                final mockups = [
                                  'design_layout.png',
                                  'functional_requirements_v1.pdf',
                                  'database_schema.sql',
                                  'translation_instructions.txt',
                                ];
                                final randomMock = (mockups..shuffle()).first;
                                controller.attachmentNames.add(randomMock);
                                Get.rawSnackbar(
                                  title: 'Attachment Uploaded',
                                  message: 'Simulated uploading $randomMock',
                                  backgroundColor: Colors.blue.shade800,
                                );
                              },
                              icon: const Icon(Icons.attach_file_rounded),
                              label: const Text('Add Simulated File'),
                            ),
                          ],
                        ),
                        const Divider(height: 20, color: Colors.white10),

                        Obx(() {
                          if (controller.attachmentNames.isEmpty) {
                            return Text(
                              'No files attached.',
                              style: GoogleFonts.inter(
                                fontSize: 12.sp,
                                color: subTextColor,
                              ),
                            );
                          }
                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: controller.attachmentNames.length,
                            itemBuilder: (context, idx) {
                              final name = controller.attachmentNames[idx];
                              return Padding(
                                padding: EdgeInsets.only(bottom: 6.h),
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 10.w,
                                    vertical: 8.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.04),
                                    borderRadius: BorderRadius.circular(8.r),
                                    border: Border.all(color: borderColor),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.insert_drive_file_outlined,
                                        size: 16.sp,
                                        color: Colors.blue,
                                      ),
                                      SizedBox(width: 8.w),
                                      Expanded(
                                        child: Text(
                                          name,
                                          style: GoogleFonts.inter(
                                            fontSize: 12.sp,
                                            color: textColor,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          Icons.close,
                                          size: 16.sp,
                                          color: Colors.red.shade400,
                                        ),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        onPressed: () => controller
                                            .attachmentNames
                                            .removeAt(idx),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        }),
                      ],
                    ),
                  ),
                  SizedBox(height: 28.h),

                  // Save & Assign Button
                  ElevatedButton(
                    onPressed: () => controller.assignTask(),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    child: Text(
                      'ASSIGN TASK NOW',
                      style: GoogleFonts.outfit(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  SizedBox(height: 12.h),

                  // Reset/Clear Form Button
                  OutlinedButton(
                    onPressed: () {
                      Get.defaultDialog(
                        title: 'Clear Assignment Form?',
                        titleStyle: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                        middleText:
                            'Are you sure you want to reset all fields and discard the draft?',
                        middleTextStyle: GoogleFonts.inter(color: subTextColor),
                        textConfirm: 'Clear',
                        textCancel: 'Cancel',
                        confirmTextColor: Colors.white,
                        cancelTextColor: textColor,
                        buttonColor: const Color(0xFFBA1A1A),
                        onConfirm: () {
                          controller.clearDraft();
                          Get.back();
                        },
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      side: BorderSide(color: Colors.red.withOpacity(0.3)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    child: Text(
                      'DISCARD & RESET FORM',
                      style: GoogleFonts.inter(
                        fontSize: 13.sp,
                        color: Colors.red.shade400,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(height: 48.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showEmployeeSelectionDialog(BuildContext context) {
    const textColor = Colors.white;
    const subTextColor = Color(0xFF94A3B8);

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        backgroundColor: const Color(0xFF0F172A),
        child: Container(
          padding: EdgeInsets.all(16.w),
          height: 480.h,
          width: 320.w,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Assign Team Members',
                style: GoogleFonts.outfit(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                'Select one or more employees to work on this task.',
                style: GoogleFonts.inter(fontSize: 11.sp, color: subTextColor),
              ),
              const Divider(height: 20, color: Colors.white10),

              // Employees List
              Expanded(
                child: Obx(() {
                  if (controller.employeesList.isEmpty) {
                    return Center(
                      child: Text(
                        'No employees found.',
                        style: TextStyle(color: subTextColor),
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: controller.employeesList.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: Colors.white10),
                    itemBuilder: (context, index) {
                      final emp = controller.employeesList[index];
                      final uid = emp['uid'] as String;
                      final name = emp['name'] as String;
                      final empId = emp['employeeId'] as String;

                      return Obx(() {
                        final isSelected = controller.selectedEmployeeUids
                            .contains(uid);
                        return CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            name,
                            style: GoogleFonts.inter(
                              color: textColor,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            'ID: $empId',
                            style: GoogleFonts.inter(
                              color: subTextColor,
                              fontSize: 11.sp,
                            ),
                          ),
                          value: isSelected,
                          activeColor: const Color(0xFF3B82F6),
                          checkColor: Colors.white,
                          onChanged: (val) {
                            if (val == true) {
                              controller.selectedEmployeeUids.add(uid);
                            } else {
                              controller.selectedEmployeeUids.remove(uid);
                            }
                          },
                        );
                      });
                    },
                  );
                }),
              ),

              const Divider(height: 20, color: Colors.white10),
              ElevatedButton(
                onPressed: () => Get.back(),
                child: const Text('Confirm Selections'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
