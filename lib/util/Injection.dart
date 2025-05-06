import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../history/HistoryController.dart';
import '../music/music_home/music_home_controller.dart';
import '../music/player/music_controller.dart';
import '../music/playlist/PlayListController.dart';
import '../splash_page/splash_controller.dart';
import 'ThemeController.dart';

class Injection {
  static Future<void> init() async {
    // 注入 SharedPreferences
    await Get.putAsync(() => SharedPreferences.getInstance());

    // 注入其他控制器
    Get.lazyPut(() => HistoryController(), fenix: true);
    Get.lazyPut(() => ThemeController(), fenix: true);

    Get.lazyPut(() => MusicHomeController(), fenix: true);
    Get.lazyPut(() => PlayListController(), fenix: true);
    Get.lazyPut(() => SplashController(), fenix: true);

    // 创建并注入 musicPlayerController
    var musicPlayerController = MusicPlayerController();
    Get.lazyPut(() => musicPlayerController, fenix: true);
    // 等待 musicPlayerController 的初始化完成
    await musicPlayerController.init();
  }
}
