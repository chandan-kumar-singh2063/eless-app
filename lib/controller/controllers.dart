import 'package:get/get.dart';
import 'package:eless/controller/auth_controller.dart';
import 'package:eless/controller/explore_controller.dart';
import 'package:eless/controller/home_controller.dart';
import 'package:eless/controller/devices_controller.dart';
import 'package:eless/controller/event_controller.dart';
import 'package:eless/controller/notification_controller.dart';
import 'package:eless/controller/cart_controller.dart';

import 'dashboard_controller.dart';

HomeController get homeController => Get.find<HomeController>();
DevicesController get devicesController => Get.find<DevicesController>();
DashboardController get dashboardController => Get.find<DashboardController>();
ExploreController get categoryController => Get.find<ExploreController>();
AuthController get authController => Get.find<AuthController>();
EventController get eventController => Get.find<EventController>();
NotificationController get notificationController =>
    Get.find<NotificationController>();
CartController get cartController => Get.find<CartController>();
