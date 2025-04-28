import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lemon_tv/util/ThemeController.dart';

import '../music/music_home/music_home_page.dart';
import '../routes/routes.dart';
import '../subscrip/SubscriptionPage.dart';
import '../util/CacheUtil.dart';
import 'ThemeSettingsPage.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:adaptive_action_sheet/adaptive_action_sheet.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  double _cacheSize = 0;
  final ThemeController themeController = Get.find();
  String _version = '';

  @override
  void initState() {
    super.initState();
    _updateCacheSize();
    _initPackageInfo();
  }

  Future<void> _initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _version = info.version;
    });
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
            title: Text("我的",
                style: TextStyle(
                    color: themeController.currentAppTheme.normalTextColor)),
          ),
          body: Column(
            children: [
              ListTile(
                leading: Icon(Icons.settings,
                    color: themeController.currentAppTheme.unselectedTextColor),
                title: Text("设置",
                    style: TextStyle(
                        color: themeController.currentAppTheme.titleColr)),
                onTap: () {
                  Routes.goSettingPage();
                },
              ),
              ListTile(
                leading: Icon(Icons.subscriptions,
                    color: themeController.currentAppTheme.unselectedTextColor),
                title: Text("影视订阅管理",
                    style: TextStyle(
                        color: themeController.currentAppTheme.titleColr)),
                onTap: () {
                  Routes.goSubscripPage();
                },
              ),
              ListTile(
                leading: Icon(Icons.extension,
                    color: themeController.currentAppTheme.unselectedTextColor),
                title: Text("音乐插件管理",
                    style: TextStyle(
                        color: themeController.currentAppTheme.titleColr)),
                onTap: () {
                  Routes.goPluginPage();
                },
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
              ListTile(
                leading: Icon(Icons.clear_all,
                    color: themeController.currentAppTheme.unselectedTextColor),
                // 清理缓存图标
                title: Text("清理缓存",
                    style: TextStyle(
                        color: themeController.currentAppTheme.titleColr)),
                trailing: Text("${_cacheSize.toStringAsFixed(2)} MB",
                    style: TextStyle(
                        color: themeController.currentAppTheme.titleColr)),
                // 显示缓存大小
                onTap: _clearCache, // 点击清理缓存
              ),
              ListTile(
                leading: Icon(Icons.info_outline,
                    color: themeController.currentAppTheme.unselectedTextColor),
                // 清理缓存图标
                title: Text("版本号",
                    style: TextStyle(
                        color: themeController.currentAppTheme.titleColr)),
                trailing: Text("v $_version",
                    style: TextStyle(
                        color: themeController.currentAppTheme.titleColr)),
              ),
              ListTile(
                leading: Icon(Icons.change_history,
                    color: themeController
                        .currentAppTheme.unselectedTextColor),
                // 清理缓存图标
                title: Text(
                  "功能切换",
                  style: TextStyle(
                      color: themeController.currentAppTheme.titleColr),
                ),
                onTap: () {
                  showAdaptiveActionSheet(
                    context: context,
                    actions: <BottomSheetAction>[
                      BottomSheetAction(
                        leading: Icon(Icons.music_note_rounded),
                        title: const Text('享音乐'),
                        onPressed: (_) {
                          Get.off(MusicHomePage());
                        },
                      ),
                      BottomSheetAction(
                        leading: Icon(Icons.book_online),
                        title: const Text('看小说'),
                        onPressed: (_) {},
                      ),
                    ],
                    cancelAction: CancelAction(title: const Text('Cancel')),
                  );
                },
              ),
            ],
          ),
        ));
  }
}
