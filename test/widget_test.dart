import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:stepz_attendance/main.dart';
import 'package:stepz_attendance/core/theme/theme_controller.dart';
import 'package:stepz_attendance/features/admin/dashboard/presentation/controllers/admin_dashboard_controller.dart';
import 'package:stepz_attendance/features/admin/dashboard/presentation/controllers/add_employee_controller.dart';
import 'package:stepz_attendance/features/admin/dashboard/presentation/views/admin_dashboard_view.dart';
import 'package:stepz_attendance/features/admin/dashboard/presentation/views/add_employee_view.dart';
import 'package:stepz_attendance/features/employee/presentation/views/employee_dashboard_view.dart';
import 'package:stepz_attendance/features/employee/presentation/controllers/employee_dashboard_controller.dart';

void main() {
  setUp(() {
    // Reset GetX dependency injection container before each test
    Get.reset();
    Get.put(ThemeController(), permanent: true);
  });

  testWidgets('Splash Screen brand verification and transition to Login', (WidgetTester tester) async {
    // Set standard mobile screen viewport to prevent ScreenUtil scaling overflows in test environment
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // 1. Verify that Splash screen shows STEPZ brand name & tagline
    expect(find.text('STEPZ'), findsOneWidget);
    expect(find.text('Smart Attendance\nManagement'), findsOneWidget);

    // 2. Pump in steps to allow the sequential timer loop to run
    for (int i = 0; i < 55; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    
    // 3. Pump extra for transition duration
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();

    // 4. Verify that it transitioned to the Login Screen
    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Employee ID / Email'), findsOneWidget);
  });

  testWidgets('Admin Dashboard UI Rendering and Controller Verification', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    // Register controller binding manually
    Get.put(AdminDashboardController(isTesting: true));

    // Pump Dashboard View inside a GetMaterialApp for proper styling context
    await tester.pumpWidget(
      GetMaterialApp(
        initialBinding: BindingsBuilder(() {
          Get.put(ThemeController(), permanent: true);
        }),
        home: const AdminDashboardView(),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Verify titles and labels
    expect(find.text('Dashboard Overview'), findsOneWidget);
    expect(find.text("Welcome back, Admin. Here's what's happening today."), findsOneWidget);

    // 2. Verify Date and Export Buttons exist
    expect(find.text('Export PDF'), findsOneWidget);

    // 3. Verify Bento Grid content
    expect(find.text('TOTAL EMPLOYEES'), findsOneWidget);
    expect(find.text('PRESENT TODAY'), findsOneWidget);
    expect(find.text('ABSENT TODAY'), findsOneWidget);
    expect(find.text('WFH TODAY'), findsOneWidget);
    expect(find.text('1'), findsNWidgets(2));
    expect(find.text('0'), findsNWidgets(6));

    // 4. Verify Weekly Attendance Trend Chart legends and days
    expect(find.text('Weekly Attendance Trend'), findsOneWidget);
    expect(find.text('Office'), findsOneWidget);
    expect(find.text('WFH'), findsOneWidget);
    expect(find.text('Mon'), findsOneWidget);
    expect(find.text('Sun'), findsOneWidget);

    // 5. Verify Quick Actions Section
    expect(find.text('Quick Actions'), findsOneWidget);
    expect(find.text('Broadcast Message'), findsOneWidget);
    expect(find.text('Generate Report'), findsOneWidget);
    expect(find.text('Add New Staff'), findsOneWidget);

    // 6. Verify System Status Card
    expect(find.text('SYSTEM STATUS'), findsOneWidget);
    expect(find.text('Biometric Servers Online'), findsOneWidget);

    // 7. Verify Recent Clock-ins Table
    expect(find.text('Recent Clock-ins'), findsOneWidget);
    expect(find.text('Jane Doe'), findsOneWidget);
    expect(find.text('Mark Smith'), findsOneWidget);
    expect(find.text('Alex Kim'), findsOneWidget);
  });

  testWidgets('Admin Employee Directory Tab and Add Employee Sheet Flow Verification', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    // 1. Bind Admin Dashboard Controller
    final controller = Get.put(AdminDashboardController(isTesting: true));

    // 2. Pump Admin View inside GetMaterialApp with registered routes
    await tester.pumpWidget(
      GetMaterialApp(
        initialBinding: BindingsBuilder(() {
          Get.put(ThemeController(), permanent: true);
        }),
        initialRoute: '/admin/dashboard',
        getPages: [
          GetPage(
            name: '/admin/dashboard',
            page: () => const AdminDashboardView(),
          ),
          GetPage(
            name: '/admin/add-employee',
            page: () => const AddEmployeeView(),
            binding: BindingsBuilder(() {
              Get.put(AddEmployeeController());
            }),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    // 3. Navigate to tab 1 (Employees)
    controller.activeTabIndex.value = 1;
    await tester.pumpAndSettle();

    // 4. Verify Directory Headers render
    expect(find.text('Employee Directory'), findsOneWidget);
    expect(find.text('Search employees...'), findsOneWidget);

    // 5. Verify initial mock directory card list renders (Alex Rivers)
    expect(find.text('Alex Rivers'), findsOneWidget);
    expect(find.text('EMP-8291'), findsOneWidget);

    // 6. Verify "New Position" card exists
    expect(find.text('New Position'), findsOneWidget);

    // 7. Tap "New Position" to trigger the bottom sheet form
    await tester.tap(find.text('New Position'));
    await tester.pumpAndSettle();

    // 8. Verify the Add Employee View displays input fields
    expect(find.text('Onboard Employee'), findsOneWidget);
    expect(find.text('Full Name'), findsOneWidget);
    expect(find.text('Email Address'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Confirm Password'), findsOneWidget);
    expect(find.text('Employee ID (Auto-Generated)'), findsOneWidget);
    expect(find.text('Designation'), findsAtLeastNWidgets(1));
    expect(find.text('Save Employee'), findsOneWidget);
  });

  testWidgets('Employee Dashboard View UI Rendering Verification', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;

    // Register controller
    Get.put(EmployeeDashboardController(isTesting: true));

    addTearDown(() {
      Get.delete<EmployeeDashboardController>();
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    // Pump view
    await tester.pumpWidget(
      GetMaterialApp(
        initialBinding: BindingsBuilder(() {
          Get.put(ThemeController(), permanent: true);
        }),
        home: const EmployeeDashboardView(),
      ),
    );

    await tester.pumpAndSettle();

    // Verify main content
    expect(find.text('Attendance Center'), findsOneWidget);
    expect(find.text('Office Status'), findsOneWidget);
    expect(find.text('Daily Actions'), findsOneWidget);
    expect(find.text('HOURS TODAY'), findsOneWidget);
    expect(find.text('Recent Logs'), findsOneWidget);
  });
}
