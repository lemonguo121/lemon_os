import 'package:get/get.dart';
import 'package:lemon_tv/download/DownloadController.dart';
import 'package:lemon_tv/util/SPManager.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../history/HistoryController.dart';
import '../music/music_home/music_home_controller.dart';
import '../music/player/music_controller.dart';
import '../music/playlist/PlayListController.dart';
import '../splash_page/splash_controller.dart';
import 'ThemeController.dart';
import 'package:video_player_media_kit/video_player_media_kit.dart';
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

    var downloadController = DownloadController();
    Get.lazyPut(() => downloadController, fenix: true);
    // 创建并注入 musicPlayerController
    var musicPlayerController = MusicPlayerController();
    Get.lazyPut(() => musicPlayerController, fenix: true);
    // 等待 musicPlayerController 的初始化完成
    await musicPlayerController.init();

    SPManager.getEnableKit();
    VideoPlayerMediaKit.ensureInitialized(
      android:  SPManager.getEnableKit(),          // default: false    -    dependency: media_kit_libs_android_video
      iOS:  SPManager.getEnableKit(),              // default: false    -    dependency: media_kit_libs_ios_video
      macOS:  SPManager.getEnableKit(),            // default: false    -    dependency: media_kit_libs_macos_video
      windows:  SPManager.getEnableKit(),          // default: false    -    dependency: media_kit_libs_windows_video
    );
  }
}
