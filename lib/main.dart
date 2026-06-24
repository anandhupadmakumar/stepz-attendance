import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'core/services/notification_service.dart';
import 'core/services/geofence_reminder_service.dart';
import 'features/splash/presentation/controllers/splash_controller.dart';
import 'features/splash/presentation/views/splash_view.dart';
import 'features/auth/presentation/controllers/login_controller.dart';
import 'features/auth/presentation/views/login_view.dart';
import 'features/auth/presentation/views/forgot_password_view.dart';
import 'features/admin/dashboard/presentation/controllers/admin_dashboard_controller.dart';
import 'features/admin/dashboard/presentation/controllers/add_employee_controller.dart';
import 'features/admin/dashboard/presentation/controllers/office_settings_controller.dart';
import 'features/admin/dashboard/presentation/views/admin_dashboard_view.dart';
import 'features/admin/dashboard/presentation/views/add_employee_view.dart';
import 'features/admin/dashboard/presentation/views/office_settings_view.dart';
import 'features/admin/dashboard/presentation/views/map_picker_view.dart';
import 'features/admin/dashboard/presentation/views/work_updates_view.dart';
import 'features/employee/presentation/controllers/employee_dashboard_controller.dart';
import 'features/employee/presentation/views/employee_dashboard_view.dart';
import 'features/employee/presentation/controllers/daily_task_update_controller.dart';
import 'features/employee/presentation/views/daily_task_update_view.dart';
import 'features/notifications/presentation/views/notifications_view.dart';
import 'features/attendance_regularization/presentation/controllers/attendance_regularization_controller.dart';
import 'features/attendance_regularization/presentation/views/attendance_regularization_request_view.dart';
import 'features/attendance_regularization/presentation/controllers/admin_attendance_requests_controller.dart';
import 'features/attendance_regularization/presentation/views/admin_attendance_requests_view.dart';
import 'features/attendance_regularization/presentation/views/admin_request_details_view.dart';

// Work Management Module Imports
import 'features/work_management/presentation/controllers/company_controller.dart';
import 'features/work_management/presentation/controllers/project_controller.dart';
import 'features/work_management/presentation/controllers/work_task_controller.dart';
import 'features/work_management/presentation/views/work_management_menu_view.dart';
import 'features/work_management/presentation/views/company_management_view.dart';
import 'features/work_management/presentation/views/project_management_view.dart';
import 'features/work_management/presentation/views/assign_work_view.dart';
import 'features/work_management/presentation/views/my_tasks_view.dart';
import 'features/work_management/presentation/views/task_details_view.dart';
import 'features/work_management/presentation/views/task_daily_update_view.dart';
import 'features/work_management/presentation/views/work_reports_view.dart';

// Holiday Calendar Module Imports
import 'features/holiday_calendar/presentation/controllers/holiday_calendar_controller.dart';
import 'features/holiday_calendar/presentation/views/admin_holiday_calendar_view.dart';
import 'features/holiday_calendar/presentation/views/employee_holiday_calendar_view.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientation (Portrait only for standard mobile layout consistency)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Load environment variables from .env file
  await dotenv.load(fileName: ".env");

  // Initialize Firebase with current platform options
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // Initialize Notification Service
    await Get.putAsync(() => NotificationService().init());
    // Initialize Geofence Reminder Service
    await Get.putAsync(() => GeofenceReminderService().init());
  } catch (e) {
    debugPrint("Firebase/Notification/Geofence initialization error: $e");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Standard Figma viewport reference design size is (390 x 844)
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return GetMaterialApp(
          title: 'STEPZ Attendance Pro',
          debugShowCheckedModeBanner: false,

          // Apply Global Themes
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.system, // Responsive based on system preferences

          initialBinding: BindingsBuilder(() {
            Get.put(ThemeController());
            if (Get.isRegistered<NotificationService>()) {
              Get.find<NotificationService>(); // resolve registered service
            }
            if (Get.isRegistered<GeofenceReminderService>()) {
              Get.find<GeofenceReminderService>();
            }
          }),

          // Define initial route
          initialRoute: '/',

          // Define GetX Route configurations with page binding registrations
          getPages: [
            GetPage(
              name: '/',
              page: () => const SplashView(),
              binding: BindingsBuilder(() {
                Get.put(SplashController());
              }),
            ),
            GetPage(
              name: '/login',
              page: () => const LoginView(),
              binding: BindingsBuilder(() {
                Get.put(LoginController());
              }),
              transition: Transition.fadeIn,
              transitionDuration: const Duration(milliseconds: 500),
            ),
            GetPage(
              name: '/forgot-password',
              page: () => const ForgotPasswordView(),
              // LoginController is shared/reused for recovery flow
              transition: Transition.rightToLeft,
              transitionDuration: const Duration(milliseconds: 300),
            ),
            GetPage(
              name: '/admin/dashboard',
              page: () => const AdminDashboardView(),
              binding: BindingsBuilder(() {
                Get.put(AdminDashboardController());
              }),
              transition: Transition.fadeIn,
              transitionDuration: const Duration(milliseconds: 400),
            ),
            GetPage(
              name: '/admin/add-employee',
              page: () => const AddEmployeeView(),
              binding: BindingsBuilder(() {
                Get.put(AddEmployeeController());
              }),
              transition: Transition.rightToLeft,
              transitionDuration: const Duration(milliseconds: 300),
            ),
            GetPage(
              name: '/admin/office-settings',
              page: () => const OfficeSettingsView(),
              binding: BindingsBuilder(() {
                Get.put(OfficeSettingsController());
              }),
              transition: Transition.rightToLeft,
              transitionDuration: const Duration(milliseconds: 300),
            ),
            GetPage(
              name: '/admin/map-picker',
              page: () => const MapPickerView(),
              transition: Transition.rightToLeft,
              transitionDuration: const Duration(milliseconds: 300),
            ),
            GetPage(
              name: '/admin/work-updates',
              page: () => const WorkUpdatesView(),
              // Uses the existing AdminDashboardController (already put)
              transition: Transition.rightToLeft,
              transitionDuration: const Duration(milliseconds: 300),
            ),
            GetPage(
              name: '/employee/dashboard',
              page: () => const EmployeeDashboardView(),
              binding: BindingsBuilder(() {
                Get.put(EmployeeDashboardController());
              }),
              transition: Transition.fadeIn,
              transitionDuration: const Duration(milliseconds: 400),
            ),
            GetPage(
              name: '/employee/daily-task-update',
              page: () => const DailyTaskUpdateView(),
              binding: BindingsBuilder(() {
                Get.put(DailyTaskUpdateController());
              }),
              transition: Transition.rightToLeft,
              transitionDuration: const Duration(milliseconds: 300),
            ),
            GetPage(
              name: '/notifications',
              page: () => const NotificationsView(),
              transition: Transition.rightToLeft,
              transitionDuration: const Duration(milliseconds: 300),
            ),
            // Work Management Module Routes
            GetPage(
              name: '/work-management/menu',
              page: () => const WorkManagementMenuView(),
              transition: Transition.rightToLeft,
              transitionDuration: const Duration(milliseconds: 300),
            ),
            GetPage(
              name: '/admin/companies',
              page: () => const CompanyManagementView(),
              binding: BindingsBuilder(() {
                Get.put(CompanyController());
              }),
              transition: Transition.rightToLeft,
              transitionDuration: const Duration(milliseconds: 300),
            ),
            GetPage(
              name: '/admin/projects',
              page: () => const ProjectManagementView(),
              binding: BindingsBuilder(() {
                Get.put(ProjectController());
              }),
              transition: Transition.rightToLeft,
              transitionDuration: const Duration(milliseconds: 300),
            ),
            GetPage(
              name: '/admin/assign-work',
              page: () => const AssignWorkView(),
              binding: BindingsBuilder(() {
                Get.put(WorkTaskController());
              }),
              transition: Transition.rightToLeft,
              transitionDuration: const Duration(milliseconds: 300),
            ),
            GetPage(
              name: '/admin/work-reports',
              page: () => const WorkReportsView(),
              binding: BindingsBuilder(() {
                Get.put(WorkTaskController());
              }),
              transition: Transition.rightToLeft,
              transitionDuration: const Duration(milliseconds: 300),
            ),
            GetPage(
              name: '/employee/my-tasks',
              page: () => const MyTasksView(),
              binding: BindingsBuilder(() {
                Get.put(WorkTaskController());
              }),
              transition: Transition.rightToLeft,
              transitionDuration: const Duration(milliseconds: 300),
            ),
            GetPage(
              name: '/work-task/details',
              page: () => const TaskDetailsView(),
              binding: BindingsBuilder(() {
                Get.put(WorkTaskController());
              }),
              transition: Transition.rightToLeft,
              transitionDuration: const Duration(milliseconds: 300),
            ),
            GetPage(
              name: '/employee/task-daily-update',
              page: () => const TaskDailyUpdateView(),
              transition: Transition.rightToLeft,
              transitionDuration: const Duration(milliseconds: 300),
            ),
            GetPage(
              name: '/admin/holiday-calendar',
              page: () => const AdminHolidayCalendarView(),
              binding: BindingsBuilder(() {
                Get.put(HolidayCalendarController());
              }),
              transition: Transition.rightToLeft,
              transitionDuration: const Duration(milliseconds: 300),
            ),
            GetPage(
              name: '/employee/holiday-calendar',
              page: () => const EmployeeHolidayCalendarView(),
              binding: BindingsBuilder(() {
                Get.put(HolidayCalendarController());
              }),
              transition: Transition.rightToLeft,
              transitionDuration: const Duration(milliseconds: 300),
            ),
            GetPage(
              name: '/employee/attendance-regularization',
              page: () => const AttendanceRegularizationRequestView(),
              binding: BindingsBuilder(() {
                Get.put(AttendanceRegularizationController());
              }),
              transition: Transition.rightToLeft,
              transitionDuration: const Duration(milliseconds: 300),
            ),
            GetPage(
              name: '/admin/attendance-requests',
              page: () => const AdminAttendanceRequestsView(),
              binding: BindingsBuilder(() {
                Get.put(AdminAttendanceRequestsController());
              }),
              transition: Transition.rightToLeft,
              transitionDuration: const Duration(milliseconds: 300),
            ),
            GetPage(
              name: '/admin/attendance-requests/details',
              page: () => const AdminRequestDetailsView(),
              transition: Transition.rightToLeft,
              transitionDuration: const Duration(milliseconds: 300),
            ),
          ],
        );
      },
    );
  }
}
