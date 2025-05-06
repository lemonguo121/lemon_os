
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';


/// @class : SplashController
/// @date : 2021/08/15
/// @name : jhf
/// @description :启动页 控制器层
class SplashController extends GetxController {
  var opacityLevel = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    Future.delayed(const Duration(milliseconds: 100), () {
      opacityLevel.value = 1.0;
    });
  }

  lazyInitAnim() {
    Future.delayed(const Duration(milliseconds: 200), () {
      opacityLevel = opacityLevel;
      update();
    });
  }
}
