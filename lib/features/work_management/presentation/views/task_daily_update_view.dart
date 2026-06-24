import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stepz_attendance/core/theme/premium_background.dart';
import '../controllers/task_daily_update_controller.dart';

class TaskDailyUpdateView extends StatefulWidget {
  const TaskDailyUpdateView({super.key});

  @override
  State<TaskDailyUpdateView> createState() => _TaskDailyUpdateViewState();
}

class _TaskDailyUpdateViewState extends State<TaskDailyUpdateView>
    with SingleTickerProviderStateMixin {
  late TaskDailyUpdateController controller;
  late String taskId;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    taskId = Get.arguments as String;
    // Instantiate or find the controller with the current taskId
    controller = Get.put(
      TaskDailyUpdateController(initialTaskId: taskId),
      tag: taskId,
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    // Delete the controller tag to free up resources when leaving the screen
    Get.delete<TaskDailyUpdateController>(tag: taskId);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const textColor = Colors.white;
    const subTextColor = Color(0xFF94A3B8);
    final borderColor = Colors.white.withOpacity(0.12);
    final glassColor = Colors.white.withOpacity(0.08);

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
            'Daily Task Update',
            style: GoogleFonts.outfit(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ),
        body: SafeArea(
          child: Obx(() {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header Instructions
                  Text(
                    'Speak in Malayalam',
                    style: GoogleFonts.inter(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'Tap the microphone below, speak your daily progress updates in Malayalam. Gemini AI will translate and rewrite it to professional standup points.',
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      color: subTextColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 20.h),

                  // Mic & Recording Pulse Widget
                  Center(child: _buildMicSection()),
                  SizedBox(height: 24.h),

                  // Progress Percentage Slider
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
                              'Task Completion progress',
                              style: GoogleFonts.inter(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${controller.progressPercentage.value.toInt()}%',
                              style: GoogleFonts.inter(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF3B82F6),
                              ),
                            ),
                          ],
                        ),
                        Slider(
                          value: controller.progressPercentage.value,
                          min: 0,
                          max: 100,
                          divisions: 20,
                          onChanged: (val) {
                            controller.progressPercentage.value = val;
                          },
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // Original Malayalam Text
                  _buildTextInputSection(
                    title: 'Original Malayalam Transcript (മലയാളം)',
                    controllerText: controller.originalMalayalamController,
                    hintText: 'Speak or type your update in Malayalam...',
                    textColor: textColor,
                    subTextColor: subTextColor,
                    borderColor: borderColor,
                    glassColor: glassColor,
                    isLoading: false,
                    onProcess: () => controller.processSpeechText(),
                    showProcessBtn: true,
                  ),
                  SizedBox(height: 16.h),

                  // English Translation
                  _buildTextInputSection(
                    title: 'English Translation',
                    controllerText: controller.englishTranslationController,
                    hintText: 'AI will translate Malayalam to English here...',
                    textColor: textColor,
                    subTextColor: subTextColor,
                    borderColor: borderColor,
                    glassColor: glassColor,
                    isLoading: controller.isTranslating.value,
                  ),
                  SizedBox(height: 16.h),

                  // Professional Summary (Standup)
                  _buildTextInputSection(
                    title: 'Gemini Standup Report (English Summary)',
                    controllerText: controller.updateTextController,
                    hintText:
                        'Professional summary points will be generated here...',
                    textColor: textColor,
                    subTextColor: subTextColor,
                    borderColor: borderColor,
                    glassColor: glassColor,
                    isLoading: controller.isGeneratingSummary.value,
                  ),
                  SizedBox(height: 28.h),

                  // Submit Daily Update Button
                  ElevatedButton(
                    onPressed: controller.isSaving.value
                        ? null
                        : () => controller.submitDailyUpdate(),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    child: controller.isSaving.value
                        ? SizedBox(
                            height: 20.h,
                            width: 20.h,
                            child: const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                              strokeWidth: 2.5,
                            ),
                          )
                        : Text(
                            'SUBMIT STANDUP UPDATE',
                            style: GoogleFonts.outfit(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                  ),
                  SizedBox(height: 40.h),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildMicSection() {
    final isRecording = controller.isRecording.value;
    final soundLevel = controller.soundLevel.value;

    // Pulse size calculations based on soundLevel activity
    final pulseScale = 1.0 + (soundLevel * 0.15);

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // Outer pulse circle
            if (isRecording)
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: pulseScale * (1.0 + (_pulseController.value * 0.2)),
                    child: Container(
                      width: 96.w,
                      height: 96.w,
                      decoration: BoxDecoration(
                        color: const Color(
                          0xFFEC4899,
                        ).withOpacity(0.15 * (1.0 - _pulseController.value)),
                        shape: BoxShape.circle,
                      ),
                    ),
                  );
                },
              ),
            // Middle pulse circle
            if (isRecording)
              Container(
                width: 84.w,
                height: 84.w,
                decoration: BoxDecoration(
                  color: const Color(0xFFEC4899).withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
              ),
            // Actual button
            GestureDetector(
              onTap: () => controller.toggleRecording(),
              child: Container(
                width: 68.w,
                height: 68.w,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isRecording
                        ? [const Color(0xFFEC4899), const Color(0xFFBE185D)]
                        : [const Color(0xFF3B82F6), const Color(0xFF1E3A8A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color:
                          (isRecording
                                  ? const Color(0xFFEC4899)
                                  : const Color(0xFF3B82F6))
                              .withOpacity(0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                  color: Colors.white,
                  size: 32.sp,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        Text(
          isRecording ? 'Listening... Speak now' : 'Tap to Start Recording',
          style: GoogleFonts.inter(
            fontSize: 12.sp,
            fontWeight: FontWeight.bold,
            color: isRecording ? const Color(0xFFEC4899) : Colors.white60,
          ),
        ),
      ],
    );
  }

  Widget _buildTextInputSection({
    required String title,
    required TextEditingController controllerText,
    required String hintText,
    required Color textColor,
    required Color subTextColor,
    required Color borderColor,
    required Color glassColor,
    required bool isLoading,
    VoidCallback? onProcess,
    bool showProcessBtn = false,
  }) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: glassColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
              if (showProcessBtn)
                TextButton.icon(
                  onPressed: onProcess,
                  icon: Icon(Icons.settings_suggest_rounded, size: 14.sp),
                  label: Text(
                    'Translate & Summarize',
                    style: GoogleFonts.inter(fontSize: 10.sp),
                  ),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
            ],
          ),
          const Divider(height: 16, color: Colors.white10),
          Stack(
            alignment: Alignment.center,
            children: [
              TextFormField(
                controller: controllerText,
                maxLines: 3,
                style: GoogleFonts.inter(fontSize: 13.sp, color: textColor),
                decoration: InputDecoration(
                  hintText: hintText,
                  hintStyle: GoogleFonts.inter(
                    fontSize: 12.sp,
                    color: subTextColor.withOpacity(0.5),
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              if (isLoading)
                Container(
                  height: 60.h,
                  color: Colors.black26,
                  child: const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF3B82F6),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
