import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lemon_tv/mine/ThemeSettingsPage.dart';
import 'package:lemon_tv/util/ThemeController.dart';

import '../util/CacheUtil.dart';

class SecendMinePage extends StatefulWidget {
  const SecendMinePage({super.key});

  @override
  State<SecendMinePage> createState() => _SecendMinePageState();
}

class _SecendMinePageState extends State<SecendMinePage> {
  final ThemeController themeController = Get.find();
  double _cacheSize = 0;

  @override
  void initState() {
    super.initState();
    _updateCacheSize();
  }

  /// 更新缓存大小
  Future<void> _updateCacheSize() async {
    double size = await CacheUtil.getCacheSize();
    setState(() {
      _cacheSize = size;
    });
  }

  /// 清理缓存
  Future<void> _clearCache() async {
    await CacheUtil.clearCache();
    await _updateCacheSize(); // 清理后更新 UI
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("缓存已清理")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() => Scaffold(
          appBar: AppBar(
            iconTheme: IconThemeData(
                color: themeController.currentAppTheme.normalTextColor),
            title: Text(
              "我的",
              style: TextStyle(
                  color: themeController.currentAppTheme.normalTextColor),
            ),
          ),
          body: Obx(() => Column(
                children: [
                  ListTile(
                    leading: Icon(
                      Icons.settings,
                      color:
                          themeController.currentAppTheme.unselectedTextColor,
                    ),
                    title: Text(
                      "设置",
                      style: TextStyle(
                          color: themeController.currentAppTheme.titleColr),
                    ),
                    onTap: () {},
                  ),
                  ListTile(
                    leading: Icon(Icons.clear_all,
                        color: themeController
                            .currentAppTheme.unselectedTextColor),
                    // 清理缓存图标
                    title: Text("清理缓存",
                        style: TextStyle(
                            color: themeController.currentAppTheme.titleColr)),
                    trailing: Text("${_cacheSize.toStringAsFixed(2)} MB"),
                    // 显示缓存大小
                    onTap: _clearCache, // 点击清理缓存
                  ),
                  ListTile(
                    leading: Icon(Icons.palette,
                        color: themeController
                            .currentAppTheme.unselectedTextColor), // 清理缓存图标
                    title: Text("主题切换",
                        style: TextStyle(
                            color: themeController.currentAppTheme.titleColr)),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => ThemeSettingsPage()),
                      );
                    }, // 点击清理缓存
                  ),
                ],
              )),
        ));
  }
}
