import 'package:get/get.dart';
import 'package:eless/route/app_route.dart';
import 'package:eless/view/dashboard/dashboard_binding.dart';
import 'package:eless/view/dashboard/dashboard_screen.dart';
import 'package:eless/view/event_details/ongoing_event_details_screen.dart';
import 'package:eless/view/event_details/upcoming_event_details_screen.dart';
import 'package:eless/view/event_details/past_event_details_screen.dart';
import 'package:eless/view/device_details/device_details_screen_new.dart';
import 'package:eless/view/device_request/device_request_screen.dart';
import 'package:eless/controller/device_request_controller.dart';
import 'package:eless/view/cart/cart_screen.dart';
import 'package:eless/view/notification/notification_screen.dart';
import 'package:eless/view/notification/notification_details_screen.dart';
import 'package:eless/view/account/auth/qr_login.dart';
import 'package:eless/view/about_us/about_us_screen.dart';
import 'package:eless/model/event.dart';
import 'package:eless/model/device.dart';
import 'package:eless/model/notification.dart';

class AppPage {
  static var list = [
    GetPage(
      name: AppRoute.dashboard,
      page: () => const DashboardScreen(),
      binding: DashboardBinding(),
    ),
    GetPage(
      name: AppRoute.ongoingEventDetails,
      page: () => OngoingEventDetailsScreen(event: Get.arguments as Event),
    ),
    GetPage(
      name: AppRoute.upcomingEventDetails,
      page: () => UpcomingEventDetailsScreen(event: Get.arguments as Event),
    ),
    GetPage(
      name: AppRoute.pastEventDetails,
      page: () => PastEventDetailsScreen(event: Get.arguments as Event),
    ),
    GetPage(
      name: AppRoute.deviceDetails,
      page: () => DeviceDetailsScreen(device: Get.arguments as Device),
    ),
    GetPage(
      name: AppRoute.deviceRequest,
      page: () => DeviceRequestScreen(device: Get.arguments as Device),
      binding: BindingsBuilder(() {
        Get.put(DeviceRequestController(), permanent: false);
      }),
    ),
    GetPage(name: AppRoute.cart, page: () => const CartScreen()),
    GetPage(
      name: AppRoute.notifications,
      page: () => const NotificationScreen(),
    ),
    GetPage(
      name: AppRoute.notificationDetails,
      page: () => NotificationDetailsScreen(
        notification: Get.arguments as NotificationModel,
      ),
    ),
    GetPage(name: AppRoute.qrLogin, page: () => const QRLoginScreen()),
    GetPage(name: AppRoute.aboutUs, page: () => const AboutUsScreen()),
  ];
}
