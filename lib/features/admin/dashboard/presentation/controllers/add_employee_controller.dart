import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'admin_dashboard_controller.dart';

class AddEmployeeController extends GetxController {
  final AdminDashboardController _dashboardController = Get.isRegistered<AdminDashboardController>()
      ? Get.find<AdminDashboardController>()
      : Get.put(AdminDashboardController());

  final formKey = GlobalKey<FormState>();

  // Text Controllers
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final idController = TextEditingController();
  final dobController = TextEditingController();

  // Reactive States
  final RxBool isPasswordObscured = true.obs;
  final RxBool isConfirmPasswordObscured = true.obs;
  final RxBool isLoading = false.obs;

  // Reactive Selected Dropdown values
  final RxString selectedDesignation = 'Software Engineer'.obs;
  final RxString selectedStatus = 'Present'.obs;
  final RxString selectedRole = 'Employee'.obs;

  @override
  void onInit() {
    super.onInit();
    updateGeneratedEmployeeId();
  }

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    idController.dispose();
    dobController.dispose();
    super.onClose();
  }

  void updateGeneratedEmployeeId() {
    idController.text = _dashboardController.getNextEmployeeId();
  }

  void togglePasswordObscured() {
    isPasswordObscured.value = !isPasswordObscured.value;
  }

  void toggleConfirmPasswordObscured() {
    isConfirmPasswordObscured.value = !isConfirmPasswordObscured.value;
  }

  Future<void> submitForm() async {
    if (!formKey.currentState!.validate()) return;

    if (passwordController.text != confirmPasswordController.text) {
      Get.rawSnackbar(
        title: 'Validation Error',
        message: 'Passwords do not match.',
        backgroundColor: Colors.red.shade700,
      );
      return;
    }

    if (dobController.text.trim().isEmpty) {
      Get.rawSnackbar(
        title: 'Validation Error',
        message: 'Please select a Date of Birth.',
        backgroundColor: Colors.red.shade700,
      );
      return;
    }

    isLoading.value = true;
    final success = await _dashboardController.saveEmployee(
      name: nameController.text.trim(),
      email: emailController.text.trim(),
      password: passwordController.text,
      employeeId: idController.text.trim(),
      designation: selectedDesignation.value,
      status: selectedStatus.value.toLowerCase(),
      role: selectedRole.value.toLowerCase(),
      dob: dobController.text.trim(),
    );
    isLoading.value = false;

    if (success) {
      // Clear all form inputs
      nameController.clear();
      emailController.clear();
      passwordController.clear();
      confirmPasswordController.clear();
      dobController.clear();

      // Reset dropdown values and fetch next sequential ID
      selectedDesignation.value = 'Software Engineer';
      selectedStatus.value = 'Present';
      selectedRole.value = 'Employee';
      updateGeneratedEmployeeId();
    }
  }
}
