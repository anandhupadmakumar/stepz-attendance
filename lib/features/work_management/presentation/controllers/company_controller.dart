import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/company_model.dart';

class CompanyController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Form elements
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final codeController = TextEditingController();
  final contactController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();
  final descriptionController = TextEditingController();
  final RxString status = 'Active'.obs; // 'Active', 'Inactive'

  // Search & Filters
  final RxString searchQuery = ''.obs;
  final RxList<CompanyModel> allCompanies = <CompanyModel>[].obs;
  final RxList<CompanyModel> filteredCompanies = <CompanyModel>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchCompanies();
    debounce(
      searchQuery,
      (_) => applyFilters(),
      time: const Duration(milliseconds: 300),
    );
  }

  @override
  void onClose() {
    nameController.dispose();
    codeController.dispose();
    contactController.dispose();
    emailController.dispose();
    phoneController.dispose();
    addressController.dispose();
    descriptionController.dispose();
    super.onClose();
  }

  void clearForm() {
    nameController.clear();
    codeController.clear();
    contactController.clear();
    emailController.clear();
    phoneController.clear();
    addressController.clear();
    descriptionController.clear();
    status.value = 'Active';
  }

  void populateForm(CompanyModel company) {
    nameController.text = company.companyName;
    codeController.text = company.companyCode;
    contactController.text = company.contactPerson;
    emailController.text = company.email;
    phoneController.text = company.phone;
    addressController.text = company.address;
    descriptionController.text = company.description;
    status.value = company.status;
  }

  Future<void> fetchCompanies() async {
    isLoading.value = true;
    try {
      final snapshot = await _firestore
          .collection('companies')
          .orderBy('createdAt', descending: true)
          .get();

      final list = snapshot.docs
          .map((doc) => CompanyModel.fromMap(doc.data(), doc.id))
          .toList();

      allCompanies.assignAll(list);
      applyFilters();
    } catch (e) {
      Get.rawSnackbar(
        title: 'Error Fetching Companies',
        message: e.toString(),
        backgroundColor: Colors.red.shade700,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void applyFilters() {
    if (searchQuery.value.trim().isEmpty) {
      filteredCompanies.assignAll(allCompanies);
      return;
    }

    final query = searchQuery.value.toLowerCase().trim();
    final list = allCompanies.where((c) {
      return c.companyName.toLowerCase().contains(query) ||
          c.companyCode.toLowerCase().contains(query) ||
          c.contactPerson.toLowerCase().contains(query) ||
          c.email.toLowerCase().contains(query);
    }).toList();

    filteredCompanies.assignAll(list);
  }

  Future<void> addCompany() async {
    if (!formKey.currentState!.validate()) return;

    isLoading.value = true;
    try {
      final company = CompanyModel(
        companyId: '',
        companyName: nameController.text.trim(),
        companyCode: codeController.text.trim(),
        contactPerson: contactController.text.trim(),
        email: emailController.text.trim(),
        phone: phoneController.text.trim(),
        address: addressController.text.trim(),
        description: descriptionController.text.trim(),
        status: status.value,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final docRef = await _firestore
          .collection('companies')
          .add(company.toMap());
      final newCompany = company.copyWith(companyId: docRef.id);

      allCompanies.insert(0, newCompany);
      applyFilters();
      clearForm();
      Get.back();
      Get.rawSnackbar(
        title: 'Company Added',
        message: 'Successfully registered company ${newCompany.companyName}',
        backgroundColor: Colors.green.shade700,
      );
    } catch (e) {
      Get.rawSnackbar(
        title: 'Error Adding Company',
        message: e.toString(),
        backgroundColor: Colors.red.shade700,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> editCompany(String companyId) async {
    if (!formKey.currentState!.validate()) return;

    isLoading.value = true;
    try {
      final company = CompanyModel(
        companyId: companyId,
        companyName: nameController.text.trim(),
        companyCode: codeController.text.trim(),
        contactPerson: contactController.text.trim(),
        email: emailController.text.trim(),
        phone: phoneController.text.trim(),
        address: addressController.text.trim(),
        description: descriptionController.text.trim(),
        status: status.value,
      );

      await _firestore
          .collection('companies')
          .doc(companyId)
          .update(company.toMap());

      final index = allCompanies.indexWhere((c) => c.companyId == companyId);
      if (index != -1) {
        allCompanies[index] = company;
        applyFilters();
      }

      clearForm();
      Get.back();
      Get.rawSnackbar(
        title: 'Company Updated',
        message: 'Successfully updated company ${company.companyName}',
        backgroundColor: Colors.green.shade700,
      );
    } catch (e) {
      Get.rawSnackbar(
        title: 'Error Updating Company',
        message: e.toString(),
        backgroundColor: Colors.red.shade700,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteCompany(String companyId) async {
    try {
      await _firestore.collection('companies').doc(companyId).delete();
      allCompanies.removeWhere((c) => c.companyId == companyId);
      applyFilters();
      Get.rawSnackbar(
        title: 'Company Deleted',
        message: 'Successfully removed company record.',
        backgroundColor: Colors.orange.shade700,
      );
    } catch (e) {
      Get.rawSnackbar(
        title: 'Error Deleting Company',
        message: e.toString(),
        backgroundColor: Colors.red.shade700,
      );
    }
  }
}
