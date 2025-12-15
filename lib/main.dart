import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';

import 'package:eless/auth_wrapper.dart';
import 'package:eless/route/app_page.dart';
import 'package:eless/theme/app_theme.dart';
import 'package:eless/service/app_initializer.dart';

/// ⚡ Clean Main Entry Point
/// All initialization logic moved to AppInitializer service
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configure EasyLoading UI
  _configureEasyLoading();

  // Initialize app (Firebase, Hive, Controllers, FCM, Connectivity)
  await AppInitializer.initialize();

  // Launch app
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      getPages: AppPage.list,
      home: const AuthWrapper(),
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      themeMode: ThemeMode.light,
      builder: EasyLoading.init(),
    );
  }
}

/// Configure EasyLoading styling
void _configureEasyLoading() {
  EasyLoading.instance
    ..displayDuration = const Duration(milliseconds: 2000)
    ..indicatorType = EasyLoadingIndicatorType.fadingCircle
    ..loadingStyle = EasyLoadingStyle.dark
    ..indicatorSize = 45.0
    ..radius = 10.0
    ..progressColor = Colors.white
    ..backgroundColor = Colors.green
    ..indicatorColor = Colors.white
    ..textColor = Colors.white
    ..userInteractions = false
    ..maskType = EasyLoadingMaskType.black
    ..dismissOnTap = true;
}
