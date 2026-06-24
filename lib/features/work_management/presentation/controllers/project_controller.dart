import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/project_model.dart';
import '../../models/company_model.dart';

class ProjectController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Form elements
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final codeController = TextEditingController();
  final clientController = TextEditingController();
  final descriptionController = TextEditingController();
  final RxString selectedCompanyId = ''.obs;
  final RxString status = 'Active'.obs; // 'Active', 'Completed', 'On Hold'
  final Rx<DateTime?> startDate = Rx<DateTime?>(null);
  final Rx<DateTime?> endDate = Rx<DateTime?>(null);

  // Lists & State
  final RxList<ProjectModel> allProjects = <ProjectModel>[].obs;
  final RxList<ProjectModel> filteredProjects = <ProjectModel>[].obs;
  final RxList<CompanyModel> activeCompanies = <CompanyModel>[].obs;
  final RxString searchQuery = ''.obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchProjects();
    fetchActiveCompanies();
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
    clientController.dispose();
    descriptionController.dispose();
    super.onClose();
  }

  void clearForm() {
    nameController.clear();
    codeController.clear();
    clientController.clear();
    descriptionController.clear();
    selectedCompanyId.value = activeCompanies.isNotEmpty
        ? activeCompanies.first.companyId
        : '';
    status.value = 'Active';
    startDate.value = null;
    endDate.value = null;
  }

  void populateForm(ProjectModel project) {
    nameController.text = project.projectName;
    codeController.text = project.projectCode;
    clientController.text = project.clientName;
    descriptionController.text = project.description;
    selectedCompanyId.value = project.companyId;
    status.value = project.status;
    startDate.value = project.startDate;
    endDate.value = project.endDate;
  }

  Future<void> fetchActiveCompanies() async {
    try {
      final snapshot = await _firestore
          .collection('companies')
          .where('status', isEqualTo: 'Active')
          .get();

      final list = snapshot.docs
          .map((doc) => CompanyModel.fromMap(doc.data(), doc.id))
          .toList();

      activeCompanies.assignAll(list);
      if (activeCompanies.isNotEmpty && selectedCompanyId.value.isEmpty) {
        selectedCompanyId.value = activeCompanies.first.companyId;
      }
    } catch (e) {
      debugPrint("Error fetching active companies for projects: $e");
    }
  }

  Future<void> fetchProjects() async {
    isLoading.value = true;
    try {
      final snapshot = await _firestore
          .collection('projects')
          .orderBy('createdAt', descending: true)
          .get();

      final list = snapshot.docs
          .map((doc) => ProjectModel.fromMap(doc.data(), doc.id))
          .toList();

      allProjects.assignAll(list);
      applyFilters();
    } catch (e) {
      Get.rawSnackbar(
        title: 'Error Fetching Projects',
        message: e.toString(),
        backgroundColor: Colors.red.shade700,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void applyFilters() {
    if (searchQuery.value.trim().isEmpty) {
      filteredProjects.assignAll(allProjects);
      return;
    }

    final query = searchQuery.value.toLowerCase().trim();
    final list = allProjects.where((p) {
      final compName = getCompanyName(p.companyId).toLowerCase();
      return p.projectName.toLowerCase().contains(query) ||
          p.projectCode.toLowerCase().contains(query) ||
          p.clientName.toLowerCase().contains(query) ||
          compName.contains(query);
    }).toList();

    filteredProjects.assignAll(list);
  }

  String getCompanyName(String companyId) {
    final comp = activeCompanies.firstWhereOrNull(
      (c) => c.companyId == companyId,
    );
    return comp?.companyName ?? 'Unknown Company';
  }

  Future<void> addProject() async {
    if (!formKey.currentState!.validate()) return;
    if (selectedCompanyId.value.isEmpty) {
      Get.rawSnackbar(
        title: 'Validation Error',
        message: 'Please select a company.',
        backgroundColor: Colors.red.shade700,
      );
      return;
    }

    isLoading.value = true;
    try {
      final project = ProjectModel(
        projectId: '',
        companyId: selectedCompanyId.value,
        projectName: nameController.text.trim(),
        projectCode: codeController.text.trim(),
        clientName: clientController.text.trim(),
        description: descriptionController.text.trim(),
        status: status.value,
        startDate: startDate.value,
        endDate: endDate.value,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final docRef = await _firestore
          .collection('projects')
          .add(project.toMap());
      final newProj = project.copyWith(projectId: docRef.id);

      allProjects.insert(0, newProj);
      applyFilters();
      clearForm();
      Get.back();
      Get.rawSnackbar(
        title: 'Project Added',
        message: 'Successfully registered project ${newProj.projectName}',
        backgroundColor: Colors.green.shade700,
      );
    } catch (e) {
      Get.rawSnackbar(
        title: 'Error Adding Project',
        message: e.toString(),
        backgroundColor: Colors.red.shade700,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> editProject(String projectId) async {
    if (!formKey.currentState!.validate()) return;

    isLoading.value = true;
    try {
      final project = ProjectModel(
        projectId: projectId,
        companyId: selectedCompanyId.value,
        projectName: nameController.text.trim(),
        projectCode: codeController.text.trim(),
        clientName: clientController.text.trim(),
        description: descriptionController.text.trim(),
        status: status.value,
        startDate: startDate.value,
        endDate: endDate.value,
      );

      await _firestore
          .collection('projects')
          .doc(projectId)
          .update(project.toMap());

      final index = allProjects.indexWhere((p) => p.projectId == projectId);
      if (index != -1) {
        allProjects[index] = project;
        applyFilters();
      }

      clearForm();
      Get.back();
      Get.rawSnackbar(
        title: 'Project Updated',
        message: 'Successfully updated project ${project.projectName}',
        backgroundColor: Colors.green.shade700,
      );
    } catch (e) {
      Get.rawSnackbar(
        title: 'Error Updating Project',
        message: e.toString(),
        backgroundColor: Colors.red.shade700,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteProject(String projectId) async {
    try {
      await _firestore.collection('projects').doc(projectId).delete();
      allProjects.removeWhere((p) => p.projectId == projectId);
      applyFilters();
      Get.rawSnackbar(
        title: 'Project Deleted',
        message: 'Successfully removed project record.',
        backgroundColor: Colors.orange.shade700,
      );
    } catch (e) {
      Get.rawSnackbar(
        title: 'Error Deleting Project',
        message: e.toString(),
        backgroundColor: Colors.red.shade700,
      );
    }
  }
}
