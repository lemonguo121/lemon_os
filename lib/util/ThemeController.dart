import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lemon_tv/util/SPManager.dart';
import '../util/AppTheme.dart';

class ThemeController extends GetxController {
  var currentTheme = SPManager.getThemeData().obs; // 当前主题

  final Map<String, AppTheme> themes = {
    "浅色": AppTheme(
      backgroundColor: Colors.white,
      selectedTextColor: Colors.blue,
      unselectedTextColor: Color(0xFF88B9F3),
      normalTextColor: Colors.black,
      buttonColor: Color(0xFF88B9F3),
      iconColor: Colors.blue,
      titleColr: Colors.black,
      contentColor: Color(0xF05C5050),
    ),
    "深色": AppTheme(
      backgroundColor: Colors.black,
      selectedTextColor: Colors.blueAccent,
      unselectedTextColor: Colors.grey,
      normalTextColor: Colors.white,
      buttonColor: Colors.grey,
      iconColor: Colors.blueAccent,
      titleColr: Colors.white,
      contentColor:Color(0xFF989494),
    ),
    "樱桃红": AppTheme(
      backgroundColor: Colors.red.shade50,
      selectedTextColor: Colors.red,
      unselectedTextColor: Color(0xFFF4526F),
      normalTextColor: Colors.black,
      buttonColor: Colors.redAccent,
      iconColor: Colors.red,
      titleColr: Colors.black,
      contentColor: Color(0xF05C5050),
    ),
    "柠檬黄": AppTheme(
      backgroundColor: const Color(0xFFFFD414),
      // 金黄色
      selectedTextColor: Color(0xFF475C0F),
      unselectedTextColor: Color(0xFF47504B),
      normalTextColor: Colors.black,
      buttonColor: Color(0xFF47504B),
      iconColor: Colors.blueAccent,
      titleColr: Colors.black,
      contentColor: Color(0xF05C5050),
    ),
  };

  @override
  void onInit() {
    super.onInit();
    loadTheme(); // 读取存储的主题
  }

  // 从SP中加载主题
  Future<void> loadTheme() async {
    String savedTheme = await SPManager.getThemeData();
    currentTheme.value = savedTheme;
  }

  // 切换主题并存储
  Future<void> changeTheme(String themeKey) async {
    if (themes.containsKey(themeKey)) {
      currentTheme.value = themeKey;
      await SPManager.selectThemeData(themeKey);
    }
  }

  // 获取当前主题的配色
  AppTheme get currentAppTheme => themes[currentTheme.value]!;
}
