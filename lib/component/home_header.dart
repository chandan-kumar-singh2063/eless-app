import 'package:badges/badges.dart';
import 'package:flutter/material.dart' hide Badge;
import 'package:get/get.dart';
import 'package:eless/controller/controllers.dart';
import 'package:eless/controller/cart_controller.dart';
import 'package:eless/view/notification/notification_screen.dart';
import 'package:eless/view/cart/cart_screen.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: <BoxShadow>[
          BoxShadow(color: Colors.grey.withOpacity(0.4), blurRadius: 10),
        ],
      ),
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          Expanded(
            child: Center(
              child: Text(
                'ELESS',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
          // Cart Button (only visible for logged-in users)
          Obx(() {
            // Only show cart for logged-in users
            if (!authController.isLoggedIn) {
              return const SizedBox.shrink();
            }

            final cartController = CartController.instance;
            final badgeCount = cartController.badgeCount;

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Badge(
                showBadge: badgeCount > 0,
                badgeContent: Text(
                  "$badgeCount",
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
                badgeStyle: BadgeStyle(
                  badgeColor: Theme.of(context).primaryColor,
                ),
                child: GestureDetector(
                  onTap: () {
                    Get.to(() => const CartScreen());
                  },
                  child: Container(
                    height: 46,
                    width: 46,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          // ignore: deprecated_member_use
                          color: Colors.grey.withOpacity(0.6),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(12),
                    child: const Icon(
                      Icons.shopping_cart_outlined,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
            );
          }),
          // Notification Button
          Obx(
            () => Badge(
              showBadge: notificationController.unreadCount.value > 0,
              badgeContent: Text(
                "${notificationController.unreadCount.value}",
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
              badgeStyle: BadgeStyle(
                badgeColor: Theme.of(context).primaryColor,
              ),
              child: GestureDetector(
                onTap: () {
                  Get.to(() => const NotificationScreen());
                },
                child: Container(
                  height: 46,
                  width: 46,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        // ignore: deprecated_member_use
                        color: Colors.grey.withOpacity(0.6),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(12),
                  child: const Icon(
                    Icons.notifications_none_outlined,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 5),
        ],
      ),
    );
  }
}
