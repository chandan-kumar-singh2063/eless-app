import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../controller/device_request_controller.dart';
import '../../../theme/app_theme.dart';

class RequestFormFields extends StatelessWidget {
  final DeviceRequestController controller;

  const RequestFormFields({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Request Information",
          style: TextStyle(
            color: AppTheme.lightTextColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),

        // Full Name field
        Obx(
          () => TextFormField(
            controller: controller.nameController,
            keyboardType: TextInputType.text,
            cursorColor: Colors.black,
            style: TextStyle(color: AppTheme.lightTextColor, fontSize: 14),
            decoration: InputDecoration(
              labelText: 'Full Name *',
              labelStyle: TextStyle(color: AppTheme.lightTextColor),
              floatingLabelStyle: const TextStyle(color: Colors.black),
              hintText: 'Enter your full name',
              hintStyle: TextStyle(color: Colors.grey[400]),
              errorText: controller.nameError.value.isEmpty
                  ? null
                  : controller.nameError.value,
              filled: true,
              fillColor: Colors.grey[50],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppTheme.lightPrimaryColor,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            onChanged: (value) => controller.validateName(value),
          ),
        ),

        const SizedBox(height: 16),

        // Contact Number field
        Obx(
          () => TextFormField(
            controller: controller.contactController,
            keyboardType: TextInputType.phone,
            cursorColor: Colors.black,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            style: TextStyle(color: AppTheme.lightTextColor, fontSize: 14),
            decoration: InputDecoration(
              labelText: 'Contact Number *',
              labelStyle: TextStyle(color: AppTheme.lightTextColor),
              floatingLabelStyle: const TextStyle(color: Colors.black),
              hintText: '98********',
              hintStyle: TextStyle(color: Colors.grey[400]),
              errorText: controller.contactError.value.isEmpty
                  ? null
                  : controller.contactError.value,
              filled: true,
              fillColor: Colors.grey[50],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppTheme.lightPrimaryColor,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            onChanged: (value) => controller.validateContact(value),
          ),
        ),

        const SizedBox(height: 16),

        // Roll Number field
        Obx(
          () => TextFormField(
            controller: controller.rollNoController,
            keyboardType: TextInputType.text,
            cursorColor: Colors.black,
            style: TextStyle(color: AppTheme.lightTextColor, fontSize: 14),
            decoration: InputDecoration(
              labelText: 'Roll Number *',
              labelStyle: TextStyle(color: AppTheme.lightTextColor),
              floatingLabelStyle: const TextStyle(color: Colors.black),
              hintText: '08*bel**',
              hintStyle: TextStyle(color: Colors.grey[400]),
              errorText: controller.rollNoError.value.isEmpty
                  ? null
                  : controller.rollNoError.value,
              filled: true,
              fillColor: Colors.grey[50],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppTheme.lightPrimaryColor,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            onChanged: (value) => controller.validateRollNo(value),
          ),
        ),

        const SizedBox(height: 16),

        // Requested Quantity field
        Obx(
          () => TextFormField(
            controller: controller.quantityController,
            keyboardType: TextInputType.number,
            cursorColor: Colors.black,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(2),
            ],
            style: TextStyle(color: AppTheme.lightTextColor, fontSize: 14),
            decoration: InputDecoration(
              labelText:
                  'Requested Quantity * (Max: ${controller.deviceAvailability.value?.availableQuantity ?? 20})',
              labelStyle: TextStyle(color: AppTheme.lightTextColor),
              floatingLabelStyle: const TextStyle(color: Colors.black),
              hintText: 'Enter quantity (Max 20)',
              hintStyle: TextStyle(color: Colors.grey[400]),
              errorText: controller.quantityError.value.isEmpty
                  ? null
                  : controller.quantityError.value,
              filled: true,
              fillColor: Colors.grey[50],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppTheme.lightPrimaryColor,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            onChanged: (value) => controller.validateQuantity(value),
          ),
        ),
      ],
    );
  }
}
