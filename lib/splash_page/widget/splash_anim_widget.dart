// import 'package:blog/common/utils/save/sp_util.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:lemon_tv/routes/routes.dart';

import '../../main.dart';
import '../splash_controller.dart';

/// @class : SplashAnimWidget
/// @date : 2021/08/17
/// @name : jhf
/// @description :动画Widget
class SplashAnimWidget extends GetView<SplashController> {
  const SplashAnimWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() => AnimatedOpacity(
        onEnd: () {
          if (controller.opacityLevel.value == 1.0) {
            Get.off(() => const HomePage());
          }
        },
        opacity: controller.opacityLevel.value,
        duration: const Duration(milliseconds: 2000),
        child: Container(
          margin: const EdgeInsets.only(top: 220),
          alignment: Alignment.center,
          child: Column(
            children: [
              Image.asset(
                "assets/app_icon.png",
                fit: BoxFit.fitWidth,
                width: 110,
                height: 110,
              ),
              Container(
                margin: const EdgeInsets.only(top: 16),
                child: Text(
                  "Lemon Player",
                ),
              ),
            ],
          ),
        )));
  }
}
