class CartItem {
  late String id;
  late String deviceId;
  late String deviceName;
  late String deviceImage;
  late int requestedQuantity;
  late int approvedQuantity;
  late String adminAction; // 'pending', 'approved', 'rejected'
  late String status; // 'on_service', 'returned', 'overdue' (only for approved)
  String? statusDisplay; // Human-readable: 'Returned', 'On Service', 'Overdue'
  String?
  overallStatus; // Combined: 'pending', 'approved', 'returned', 'overdue', 'rejected'
  late bool isOverdue; // Backend calculated
  late String returnDate;
  late String requestDate;
  late String? updatedAt;
  late String? rejectionReason;

  CartItem({
    required this.id,
    required this.deviceId,
    required this.deviceName,
    required this.deviceImage,
    required this.requestedQuantity,
    required this.approvedQuantity,
    required this.adminAction,
    required this.status,
    this.statusDisplay,
    this.overallStatus,
    this.isOverdue = false,
    required this.returnDate,
    required this.requestDate,
    this.updatedAt,
    this.rejectionReason,
  });

  CartItem.fromJson(Map<String, dynamic> json) {
    id = json['id']?.toString() ?? '';
    deviceId = json['device_id']?.toString() ?? '';
    deviceName = json['device_name'] ?? '';
    deviceImage = json['device_image'] ?? '';
    requestedQuantity = json['requested_quantity'] ?? 0;
    approvedQuantity = json['approved_quantity'] ?? 0;
    adminAction = json['admin_action'] ?? 'pending';
    status = json['status'] ?? '';
    statusDisplay = json['status_display'];
    overallStatus = json['overall_status'];
    isOverdue = json['is_overdue'] ?? false;
    returnDate = json['return_date']?.toString() ?? '';
    requestDate = json['request_date']?.toString() ?? '';
    updatedAt = json['updated_at']?.toString();
    rejectionReason = json['rejection_reason'];

    // Debug: Log if return_date is missing
    if (returnDate.isEmpty) {
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'device_id': deviceId,
      'device_name': deviceName,
      'device_image': deviceImage,
      'requested_quantity': requestedQuantity,
      'approved_quantity': approvedQuantity,
      'admin_action': adminAction,
      'status': status,
      'status_display': statusDisplay,
      'overall_status': overallStatus,
      'is_overdue': isOverdue,
      'return_date': returnDate,
      'request_date': requestDate,
      'updated_at': updatedAt,
      'rejection_reason': rejectionReason,
    };
  }

  // Helper getters - Use overall_status if available, otherwise fallback to admin_action/status
  bool get isPending {
    if (overallStatus != null && overallStatus!.isNotEmpty) {
      return overallStatus!.toLowerCase() == 'pending';
    }
    return adminAction.toLowerCase() == 'pending';
  }

  bool get isApproved {
    if (overallStatus != null && overallStatus!.isNotEmpty) {
      return overallStatus!.toLowerCase() == 'approved';
    }
    return adminAction.toLowerCase() == 'approved' &&
        !isReturned &&
        !isOverdueStatus;
  }

  bool get isRejected {
    if (overallStatus != null && overallStatus!.isNotEmpty) {
      return overallStatus!.toLowerCase() == 'rejected';
    }
    return adminAction.toLowerCase() == 'rejected';
  }

  // Status helpers
  bool get isOnService {
    if (overallStatus != null && overallStatus!.isNotEmpty) {
      return overallStatus!.toLowerCase() == 'approved';
    }
    return status.toLowerCase() == 'on_service';
  }

  bool get isReturned {
    if (overallStatus != null && overallStatus!.isNotEmpty) {
      return overallStatus!.toLowerCase() == 'returned';
    }
    return status.toLowerCase() == 'returned' ||
        adminAction.toLowerCase() == 'returned';
  }

  bool get isOverdueStatus {
    if (overallStatus != null && overallStatus!.isNotEmpty) {
      return overallStatus!.toLowerCase() == 'overdue';
    }
    return isOverdue || status.toLowerCase() == 'overdue';
  }

  // Get display text for status
  String get displayStatus {
    if (statusDisplay != null && statusDisplay!.isNotEmpty) {
      return statusDisplay!;
    }

    // Fallback to calculating from overall_status or status
    if (overallStatus != null && overallStatus!.isNotEmpty) {
      switch (overallStatus!.toLowerCase()) {
        case 'pending':
          return 'Pending';
        case 'approved':
          return 'On Service';
        case 'returned':
          return 'Returned';
        case 'overdue':
          return 'Overdue';
        case 'rejected':
          return 'Rejected';
      }
    }

    // Final fallback to status field
    if (status.isNotEmpty) {
      switch (status.toLowerCase()) {
        case 'on_service':
          return 'On Service';
        case 'returned':
          return 'Returned';
        case 'overdue':
          return 'Overdue';
      }
    }

    return 'Unknown';
  }
}
