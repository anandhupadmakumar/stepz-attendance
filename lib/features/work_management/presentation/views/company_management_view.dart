import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stepz_attendance/core/theme/premium_background.dart';
import '../controllers/company_controller.dart';
import '../../models/company_model.dart';

class CompanyManagementView extends GetView<CompanyController> {
  const CompanyManagementView({super.key});

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
            'Companies',
            style: GoogleFonts.outfit(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.refresh_rounded, color: textColor),
              onPressed: () => controller.fetchCompanies(),
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
                            hintText: 'Search companies...',
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
                      onTap: () => _openCompanyDialog(context, null),
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

              // Companies List
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

                  if (controller.filteredCompanies.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.business_rounded,
                            size: 64.sp,
                            color: subTextColor.withOpacity(0.3),
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            'No companies registered yet',
                            style: GoogleFonts.inter(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            'Tap the "+" button to add your first company.',
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
                    itemCount: controller.filteredCompanies.length,
                    separatorBuilder: (_, __) => SizedBox(height: 12.h),
                    itemBuilder: (context, index) {
                      final company = controller.filteredCompanies[index];
                      return _buildCompanyCard(context, company);
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

  Widget _buildCompanyCard(BuildContext context, CompanyModel company) {
    final glassColor = Colors.white.withOpacity(0.08);
    final borderColor = Colors.white.withOpacity(0.12);
    const textColor = Colors.white;
    const subTextColor = Color(0xFF94A3B8);

    final isActive = company.status == 'Active';

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
                  color:
                      (isActive
                              ? const Color(0xFF10B981)
                              : const Color(0xFF64748B))
                          .withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.business_rounded,
                  color: isActive
                      ? const Color(0xFF10B981)
                      : const Color(0xFF64748B),
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      company.companyName,
                      style: GoogleFonts.inter(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    if (company.companyCode.isNotEmpty)
                      Text(
                        'Code: ${company.companyCode}',
                        style: GoogleFonts.inter(
                          fontSize: 11.sp,
                          color: subTextColor,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color:
                      (isActive
                              ? const Color(0xFF10B981)
                              : const Color(0xFFEF4444))
                          .withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  company.status,
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                    color: isActive
                        ? const Color(0xFF34D399)
                        : const Color(0xFFF87171),
                  ),
                ),
              ),
            ],
          ),

          if (company.description.isNotEmpty) ...[
            SizedBox(height: 12.h),
            Text(
              company.description,
              style: GoogleFonts.inter(fontSize: 12.sp, color: subTextColor),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          const Divider(height: 24, color: Colors.white10),

          // Contact Details
          Row(
            children: [
              Icon(
                Icons.person_outline_rounded,
                size: 14.sp,
                color: subTextColor,
              ),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  company.contactPerson.isNotEmpty
                      ? company.contactPerson
                      : 'No Contact Person',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    color: textColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          if (company.email.isNotEmpty) ...[
            SizedBox(height: 6.h),
            Row(
              children: [
                Icon(Icons.email_outlined, size: 14.sp, color: subTextColor),
                SizedBox(width: 6.w),
                Expanded(
                  child: Text(
                    company.email,
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      color: subTextColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (company.phone.isNotEmpty) ...[
            SizedBox(height: 6.h),
            Row(
              children: [
                Icon(
                  Icons.phone_iphone_outlined,
                  size: 14.sp,
                  color: subTextColor,
                ),
                SizedBox(width: 6.w),
                Expanded(
                  child: Text(
                    company.phone,
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      color: subTextColor,
                    ),
                  ),
                ),
              ],
            ),
          ],

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
                onPressed: () => _viewCompanyDetails(context, company),
              ),
              IconButton(
                icon: Icon(
                  Icons.edit_outlined,
                  size: 20.sp,
                  color: Colors.amber,
                ),
                onPressed: () => _openCompanyDialog(context, company),
              ),
              IconButton(
                icon: Icon(
                  Icons.delete_outline_rounded,
                  size: 20.sp,
                  color: Colors.red.shade400,
                ),
                onPressed: () {
                  Get.defaultDialog(
                    title: 'Delete Company?',
                    titleStyle: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                    middleText:
                        'Are you sure you want to delete this company record? This action cannot be undone.',
                    middleTextStyle: GoogleFonts.inter(color: subTextColor),
                    textConfirm: 'Delete',
                    textCancel: 'Cancel',
                    confirmTextColor: Colors.white,
                    cancelTextColor: textColor,
                    buttonColor: const Color(0xFFBA1A1A),
                    onConfirm: () {
                      controller.deleteCompany(company.companyId);
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

  void _viewCompanyDetails(BuildContext context, CompanyModel company) {
    const textColor = Colors.white;

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
              // Drag handle
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
                company.companyName,
                style: GoogleFonts.outfit(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                'Status: ${company.status}',
                style: GoogleFonts.inter(
                  fontSize: 13.sp,
                  color: company.status == 'Active' ? Colors.green : Colors.red,
                ),
              ),
              const Divider(height: 24, color: Colors.white10),

              _detailRow('Company Code', company.companyCode),
              _detailRow('Contact Person', company.contactPerson),
              _detailRow('Email Address', company.email),
              _detailRow('Phone Number', company.phone),
              _detailRow('Physical Address', company.address),
              _detailRow('Description', company.description),

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

  void _openCompanyDialog(BuildContext context, CompanyModel? company) {
    final isEdit = company != null;
    if (isEdit) {
      controller.populateForm(company);
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
      title: isEdit ? 'Edit Company' : 'Add Company',
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
                decoration: dialogInputDecoration.copyWith(labelText: 'Company Name *'),
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'Please enter company name'
                    : null,
              ),
              SizedBox(height: 10.h),
              TextFormField(
                controller: controller.codeController,
                style: GoogleFonts.inter(color: textColor),
                decoration: dialogInputDecoration.copyWith(labelText: 'Company Code'),
              ),
              SizedBox(height: 10.h),
              TextFormField(
                controller: controller.contactController,
                style: GoogleFonts.inter(color: textColor),
                decoration: dialogInputDecoration.copyWith(labelText: 'Contact Person'),
              ),
              SizedBox(height: 10.h),
              TextFormField(
                controller: controller.emailController,
                style: GoogleFonts.inter(color: textColor),
                keyboardType: TextInputType.emailAddress,
                decoration: dialogInputDecoration.copyWith(labelText: 'Email Address'),
              ),
              SizedBox(height: 10.h),
              TextFormField(
                controller: controller.phoneController,
                style: GoogleFonts.inter(color: textColor),
                keyboardType: TextInputType.phone,
                decoration: dialogInputDecoration.copyWith(labelText: 'Phone Number'),
              ),
              SizedBox(height: 10.h),
              TextFormField(
                controller: controller.addressController,
                maxLines: 2,
                style: GoogleFonts.inter(color: textColor),
                decoration: dialogInputDecoration.copyWith(
                  labelText: 'Physical Address',
                ),
              ),
              SizedBox(height: 10.h),
              TextFormField(
                controller: controller.descriptionController,
                maxLines: 2,
                style: GoogleFonts.inter(color: textColor),
                decoration: dialogInputDecoration.copyWith(labelText: 'Description'),
              ),
              SizedBox(height: 12.h),
              DropdownButtonFormField<String>(
                value: controller.status.value,
                dropdownColor: const Color(0xFF1E293B),
                style: GoogleFonts.inter(color: textColor),
                items: ['Active', 'Inactive'].map((s) {
                  return DropdownMenuItem(value: s, child: Text(s));
                }).toList(),
                onChanged: (val) {
                  if (val != null) controller.status.value = val;
                },
                decoration: dialogInputDecoration.copyWith(labelText: 'Status'),
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
          controller.editCompany(company.companyId);
        } else {
          controller.addCompany();
        }
      },
    );
  }
}
