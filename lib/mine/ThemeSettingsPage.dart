import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../util/ThemeController.dart';

class ThemeSettingsPage extends StatelessWidget {
  ThemeSettingsPage({super.key});

  final ThemeController themeController = Get.find();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          iconTheme: IconThemeData(color: themeController.currentAppTheme.normalTextColor),
          title: Text("主题设置",
              style: TextStyle(
                  color: themeController.currentAppTheme.normalTextColor))),
      body: ListView(
        children: themeController.themes.keys.map((themeKey) {
          return ListTile(
            title: Text(
              themeKey,
              style: TextStyle(
                  color: themeController.currentAppTheme.selectedTextColor),
            ),
            trailing: Obx(() => themeController.currentTheme.value == themeKey
                ? Icon(Icons.check,
                    color: themeController.currentAppTheme.selectedTextColor)
                : const Icon(Icons.check, color: Colors.transparent)),
            onTap: () => themeController.changeTheme(themeKey),
          );
        }).toList(),
      ),
    );
  }
}
