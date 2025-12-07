import 'package:get/get.dart';
import 'package:eless/controller/auth_controller.dart';
import 'package:eless/controller/explore_controller.dart';
import 'package:eless/controller/dashboard_controller.dart';
import 'package:eless/controller/home_controller.dart';
import 'package:eless/controller/devices_controller.dart';
import 'package:eless/controller/event_controller.dart';
import 'package:eless/controller/notification_controller.dart';
import 'package:eless/controller/cart_controller.dart';

class DashboardBinding extends Bindings {
  @override
  void dependencies() {
    // Controllers are already initialized in main.dart
    // Just ensure they exist (no-op if already created)
    Get.find<DashboardController>();
    Get.find<HomeController>();
    Get.find<DevicesController>();
    Get.find<ExploreController>();
    Get.find<AuthController>();
    Get.find<EventController>();
    Get.find<NotificationController>();
    Get.find<CartController>();
  }
}
