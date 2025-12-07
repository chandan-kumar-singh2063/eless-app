import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:eless/controller/controllers.dart';

import 'auth/sign_in_bottom_sheet.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          const SizedBox(height: 20),
          Obx(
            () => Row(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey.shade100,
                    border: Border.all(color: Colors.grey.shade300, width: 2),
                    image: DecorationImage(
                      image: AssetImage('images/eless_logo.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        authController.user.value != null
                            ? "Namaskar, ${authController.user.value!.fullName}"
                            : "Sign in your account",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 50),
          buildAccountCard(
            title: "Notification",
            onClick: () {
              Get.toNamed('/notifications');
            },
          ),
          buildAccountCard(
            title: "About Us",
            onClick: () {
              Get.toNamed('/about-us');
            },
          ),
          Obx(
            () => buildAccountCard(
              title: authController.user.value == null ? "Sign In" : "Sign Out",
              onClick: () async {
                if (authController.user.value != null) {
                  // User is logged in, sign them out
                  // AuthWrapper will automatically show sign-in sheet
                  await authController.signOut();
                } else {
                  // User is not logged in, show sign-in bottom sheet
                  SignInBottomSheet.show(context, canDismiss: true);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget buildAccountCard({
    required String title,
    required Function() onClick,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GestureDetector(
        onTap: () {
          onClick();
        },
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.all(Radius.circular(12)),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.4),
                spreadRadius: 0.1,
                blurRadius: 7,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 18,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(Icons.keyboard_arrow_right_outlined),
            ],
          ),
        ),
      ),
    );
  }
}
