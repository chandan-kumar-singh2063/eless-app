import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';
import '../../../controller/device_request_controller.dart';
import '../../../theme/app_theme.dart';

class DateAndPurposeFields extends StatelessWidget {
  final DeviceRequestController controller;

  const DateAndPurposeFields({super.key, required this.controller});

  void _showDatePicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Select Return Date',
          style: TextStyle(
            color: AppTheme.lightTextColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        contentPadding: const EdgeInsets.all(20),
        content: SizedBox(
          width: 320,
          height: 380,
          child: SfDateRangePicker(
            onSelectionChanged: (DateRangePickerSelectionChangedArgs args) {
              if (args.value is DateTime) {
                controller.selectReturnDate(args.value);
                Navigator.of(context).pop();
              }
            },
            selectionMode: DateRangePickerSelectionMode.single,
            initialSelectedDate: controller.selectedReturnDate.value,
            minDate: DateTime.now().add(const Duration(days: 1)),
            maxDate: DateTime.now().add(const Duration(days: 365)),
            view: DateRangePickerView.month,
            monthViewSettings: const DateRangePickerMonthViewSettings(
              firstDayOfWeek: 1,
            ),
            headerStyle: DateRangePickerHeaderStyle(
              backgroundColor: AppTheme.lightPrimaryColor,
              textStyle: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            selectionColor: AppTheme.lightPrimaryColor,
            todayHighlightColor: AppTheme.lightPrimaryColor.withOpacity(0.3),
            rangeSelectionColor: AppTheme.lightPrimaryColor.withOpacity(0.1),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: AppTheme.lightPrimaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),

        // Expected Return Date field
        InkWell(
          onTap: () => _showDatePicker(context),
          child: IgnorePointer(
            child: Obx(
              () => TextFormField(
                controller: controller.returnDateController,
                cursorColor: Colors.black,
                style: TextStyle(color: AppTheme.lightTextColor, fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Expected Return Date *',
                  labelStyle: TextStyle(color: AppTheme.lightTextColor),
                  floatingLabelStyle: const TextStyle(color: Colors.black),
                  hintText: 'Select return date',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  errorText: controller.returnDateError.value.isEmpty
                      ? null
                      : controller.returnDateError.value,
                  prefixIcon: Icon(
                    Icons.calendar_today,
                    color: AppTheme.lightPrimaryColor,
                    size: 20,
                  ),
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
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Purpose field (now compulsory)
        Obx(
          () => TextFormField(
            controller: controller.purposeController,
            keyboardType: TextInputType.multiline,
            maxLines: 4,
            cursorColor: Colors.black,
            style: TextStyle(color: AppTheme.lightTextColor, fontSize: 14),
            decoration: InputDecoration(
              labelText: 'Purpose *',
              labelStyle: TextStyle(color: AppTheme.lightTextColor),
              floatingLabelStyle: const TextStyle(color: Colors.black),
              hintText: 'Describe the purpose of your request',
              hintStyle: TextStyle(color: Colors.grey[400]),
              errorText: controller.purposeError.value.isEmpty
                  ? null
                  : controller.purposeError.value,
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
              alignLabelWithHint: true,
            ),
            onChanged: (value) => controller.validatePurpose(value),
          ),
        ),

        const SizedBox(height: 32),

        // Submit button
        Obx(
          () => SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: controller.isSubmitting.value
                  ? null
                  : () => controller.submitRequest(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.lightPrimaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
                disabledBackgroundColor: Colors.grey[300],
              ),
              child: controller.isSubmitting.value
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Text(
                      "Submit Request",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
            ),
          ),
        ),

        const SizedBox(height: 32),
      ],
    );
  }
}
