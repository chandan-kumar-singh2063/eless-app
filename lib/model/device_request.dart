class DeviceRequest {
  late String deviceId;
  late String name;
  late String contact;
  late String rollNo;
  late int quantity;
  late String returnDate; // YYYY-MM-DD format
  late String purpose;
  String? userUniqueId; // Optional - for logged in users

  DeviceRequest({
    required this.deviceId,
    required this.name,
    required this.contact,
    required this.rollNo,
    required this.quantity,
    required this.returnDate,
    required this.purpose,
    this.userUniqueId,
  });

  Map<String, dynamic> toJson() {
    final json = {
      'name': name,
      'contact': contact,
      'roll_no': rollNo,
      'quantity': quantity,
      'return_date': returnDate,
      'purpose': purpose,
    };

    // Include user_unique_id if available (logged in user)
    if (userUniqueId != null && userUniqueId!.isNotEmpty) {
      json['user_unique_id'] = userUniqueId!;
    }

    return json;
  }

  DeviceRequest.fromJson(Map<String, dynamic> json) {
    deviceId = json['device_id'].toString();
    name = json['name'] ?? '';
    contact = json['contact'] ?? '';
    rollNo = json['roll_no'] ?? '';
    quantity = json['quantity'] ?? 0;
    returnDate = json['return_date'] ?? '';
    purpose = json['purpose'] ?? '';
    userUniqueId = json['user_unique_id'];
  }
}

class DeviceAvailability {
  late bool isAvailable;
  late int availableQuantity;
  late int totalQuantity;
  late String message;

  DeviceAvailability({
    required this.isAvailable,
    required this.availableQuantity,
    required this.totalQuantity,
    required this.message,
  });

  DeviceAvailability.fromJson(Map<String, dynamic> json) {
    isAvailable = json['is_available'] ?? false;
    availableQuantity = json['available_quantity'] ?? 0;
    totalQuantity = json['total_quantity'] ?? 0;
    message = json['message'] ?? '';
  }
}
