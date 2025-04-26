import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../history/HistoryController.dart';
import 'ThemeController.dart';

class Injection {
  static Future<void> init() async {
    // shared_preferences
    await Get.putAsync(() => SharedPreferences.getInstance());
    Get.lazyPut(() => HistoryController(),fenix: true);
    Get.lazyPut(() => ThemeController(),fenix: true);
    Get.lazyPut(() => ThemeController(),fenix: true);
  }
}