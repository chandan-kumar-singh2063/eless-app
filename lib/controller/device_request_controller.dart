import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../model/device.dart';
import '../model/device_request.dart';
import '../service/remote_service/device_request_service.dart';
import '../component/custom_toast.dart';
import 'auth_controller.dart';

class DeviceRequestController extends GetxController {
  // Safe instance getter that doesn't throw error
  static DeviceRequestController get instance {
    if (Get.isRegistered<DeviceRequestController>()) {
      return Get.find<DeviceRequestController>();
    }
    return Get.put(DeviceRequestController());
  }

  final DeviceRequestService _deviceRequestService = DeviceRequestService();

  // Form controllers
  final nameController = TextEditingController();
  final contactController = TextEditingController();
  final rollNoController = TextEditingController();
  final quantityController = TextEditingController();
  final purposeController = TextEditingController();
  final returnDateController = TextEditingController();

  // Observable variables
  RxBool isLoading = false.obs;
  RxBool isSubmitting = false.obs;
  RxBool isCheckingAvailability = false.obs;

  Rx<DeviceAvailability?> deviceAvailability = Rx<DeviceAvailability?>(null);
  Rx<Device?> currentDevice = Rx<Device?>(null);
  Rx<DateTime?> selectedReturnDate = Rx<DateTime?>(null);

  // Form validation
  RxString nameError = ''.obs;
  RxString contactError = ''.obs;
  RxString rollNoError = ''.obs;
  RxString quantityError = ''.obs;
  RxString returnDateError = ''.obs;
  RxString purposeError = ''.obs;

  // Set device and check availability (called from screen)
  void setDevice(Device device) {
    if (currentDevice.value?.id != device.id) {
      currentDevice.value = device;
      checkDeviceAvailability();
    }
  }

  @override
  void onClose() {
    nameController.dispose();
    contactController.dispose();
    rollNoController.dispose();
    quantityController.dispose();
    purposeController.dispose();
    returnDateController.dispose();
    super.onClose();
  }

  Future<void> checkDeviceAvailability() async {
    if (currentDevice.value == null) {
      return;
    }

    // Prevent multiple simultaneous calls
    if (isCheckingAvailability.value == true) {
      return;
    }

    try {
      isCheckingAvailability(true);

      var availability = await _deviceRequestService.checkAvailability(
        deviceId: currentDevice.value!.id,
      );
      deviceAvailability.value = availability;
    } catch (e) {
      CustomToast.showError(CustomToast.getUserFriendlyError(e.toString()));
    } finally {
      isCheckingAvailability(false);
    }
  }

  void selectReturnDate(DateTime date) {
    selectedReturnDate.value = date;
    returnDateController.text = DateFormat('yyyy-MM-dd').format(date);
    validateReturnDate(returnDateController.text);
  }

  bool validateName(String value) {
    if (value.trim().isEmpty) {
      nameError.value = 'Name is required';
      return false;
    }
    nameError.value = '';
    return true;
  }

  bool validateContact(String value) {
    if (value.trim().isEmpty) {
      contactError.value = 'Contact number is required';
      return false;
    }

    // Simple phone number validation (10-15 digits)
    final phoneRegex = RegExp(r'^\d{10,15}$');
    if (!phoneRegex.hasMatch(value.replaceAll(RegExp(r'[\s\-\(\)]'), ''))) {
      contactError.value = 'Please enter a valid phone number';
      return false;
    }

    contactError.value = '';
    return true;
  }

  bool validateRollNo(String value) {
    if (value.trim().isEmpty) {
      rollNoError.value = 'Roll number is required';
      return false;
    }
    rollNoError.value = '';
    return true;
  }

  bool validateQuantity(String value) {
    if (value.trim().isEmpty) {
      quantityError.value = 'Quantity is required';
      return false;
    }

    final quantity = int.tryParse(value);
    if (quantity == null || quantity <= 0) {
      quantityError.value = 'Quantity must be a positive number';
      return false;
    }

    final maxQuantity = deviceAvailability.value?.availableQuantity ?? 0;
    if (quantity > maxQuantity) {
      quantityError.value = 'Maximum available quantity is $maxQuantity';
      return false;
    }

    quantityError.value = '';
    return true;
  }

  bool validateReturnDate(String value) {
    if (value.trim().isEmpty) {
      returnDateError.value = 'Return date is required';
      return false;
    }

    try {
      final returnDate = DateTime.parse(value);
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);

      if (returnDate.isBefore(todayStart) ||
          returnDate.isAtSameMomentAs(todayStart)) {
        returnDateError.value = 'Return date must be in the future';
        return false;
      }
    } catch (e) {
      returnDateError.value = 'Invalid date format';
      return false;
    }

    returnDateError.value = '';
    return true;
  }

  bool validatePurpose(String value) {
    if (value.trim().isEmpty) {
      purposeError.value = 'Purpose is required';
      return false;
    }
    if (value.trim().length < 10) {
      purposeError.value = 'Purpose must be at least 10 characters';
      return false;
    }
    purposeError.value = '';
    return true;
  }

  bool validateForm() {
    bool isValid = true;

    isValid &= validateName(nameController.text);
    isValid &= validateContact(contactController.text);
    isValid &= validateRollNo(rollNoController.text);
    isValid &= validateQuantity(quantityController.text);
    isValid &= validateReturnDate(returnDateController.text);
    isValid &= validatePurpose(purposeController.text);

    return isValid;
  }

  Future<void> submitRequest() async {
    if (!validateForm()) {
      CustomToast.showWarning('Please fix all validation errors');
      return;
    }

    if (currentDevice.value == null) {
      CustomToast.showError('Device information not found');
      return;
    }

    try {
      isSubmitting(true);

      // Get user's unique ID if logged in
      final authController = AuthController.instance;
      final userUniqueId = authController.isLoggedIn
          ? authController.user.value?.id
          : null;

      final request = DeviceRequest(
        deviceId: currentDevice.value!.id,
        name: nameController.text.trim(),
        contact: contactController.text.trim(),
        rollNo: rollNoController.text.trim(),
        quantity: int.parse(quantityController.text.trim()),
        returnDate: returnDateController.text.trim(),
        purpose: purposeController.text.trim(),
        userUniqueId: userUniqueId,
      );

      // Log request details for debugging

      final result = await _deviceRequestService.submitRequest(
        deviceId: currentDevice.value!.id,
        request: request,
      );


      if (result['success'] == true) {
        CustomToast.showSuccess('Device request submitted successfully!');
        clearForm();
        Get.back(); // Navigate back to previous screen
      } else {
        String errorMsg = CustomToast.getUserFriendlyError(
          result['message'] ?? 'Request failed',
        );
        CustomToast.showError(errorMsg);
      }
    } catch (e) {
      CustomToast.showError(CustomToast.getUserFriendlyError(e.toString()));
    } finally {
      isSubmitting(false);
    }
  }

  void clearForm() {
    nameController.clear();
    contactController.clear();
    rollNoController.clear();
    quantityController.clear();
    purposeController.clear();
    returnDateController.clear();
    selectedReturnDate.value = null;

    nameError.value = '';
    contactError.value = '';
    rollNoError.value = '';
    quantityError.value = '';
    returnDateError.value = '';
    purposeError.value = '';
  }
}
