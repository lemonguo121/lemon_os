import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lemon_tv/mine/ThemeSettingsPage.dart';
import 'package:lemon_tv/music/music_home/music_home_page.dart';
import 'package:lemon_tv/util/ThemeController.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:adaptive_action_sheet/adaptive_action_sheet.dart';
import '../util/CacheUtil.dart';

class SecendMinePage extends StatefulWidget {
  const SecendMinePage({super.key});

  @override
  State<SecendMinePage> createState() => _SecendMinePageState();
}

class _SecendMinePageState extends State<SecendMinePage> {
  final ThemeController themeController = Get.find();
  double _cacheSize = 0;
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

  void _showSheet() {}

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
                  ListTile(
                    leading: Icon(Icons.info_outline,
                        color: themeController
                            .currentAppTheme.unselectedTextColor),
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
              )),
        ));
  }
}
