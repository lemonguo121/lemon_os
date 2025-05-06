
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:lemon_tv/splash_page/splash_controller.dart';
import 'package:lemon_tv/splash_page/widget/splash_anim_widget.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    removeSystemTransparent(context);
    Get.put(SplashController());

    ///预缓存背景图片
    // precacheImage(const AssetImage(R.assetsImagesLoginBackground), context);
    return const Scaffold(
        backgroundColor: Colors.white, body: SplashAnimWidget());
  }
  static removeSystemTransparent(BuildContext context) {
    /// android 平台
    if (Theme.of(context).platform == TargetPlatform.android) {
      SystemUiOverlayStyle _style = const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      );
      SystemChrome.setSystemUIOverlayStyle(_style);
    }
  }
}
