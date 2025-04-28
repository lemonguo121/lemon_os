import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:lemon_tv/music/libs/music_record.dart';

import '../../mine/SecendMinePage.dart';
import '../../util/ThemeController.dart';
import '../libs/music_mini_bar.dart';
import '../libs/music_mini_controller.dart';
import '../libs/music_play.dart';
import '../libs/music_search.dart';

class MusicHomePage extends StatefulWidget {
  const MusicHomePage({super.key});

  @override
  State<MusicHomePage> createState() => _MusicHomePageState();
}

class _MusicHomePageState extends State<MusicHomePage> {
  int _currentIndex = 0;
  final ThemeController themeController = Get.find();
  final MiniPlayerController miniController = Get.find();

  final List<Widget> _pages = [
    MusicSearchPage(),
    MusicRecord(),
    SecendMinePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 页面内容
          Positioned.fill(
            child: IndexedStack(
              index: _currentIndex,
              children: _pages,
            ),
          ),
          // Debug: 简单文本替代 MiniMusicPlayerBar，排查问题
          Obx(() {
            if (miniController.isVisible.value) {
              return Positioned(
                left: 0,
                right: 0,
                bottom: 0, // 留出 BottomNavigationBar 的高度
                child: MiniMusicPlayerBar(controller: miniController),
              );
            }
            return Center(
              child: SizedBox.shrink(),
            ); // 如果播放器不可见，返回空的占位
          }),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: themeController.currentAppTheme.backgroundColor,
        unselectedItemColor:
        themeController.currentAppTheme.unselectedTextColor,
        selectedItemColor: themeController.currentAppTheme.selectedTextColor,
        elevation: 1.0,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "首页"),
          BottomNavigationBarItem(icon: Icon(Icons.record_voice_over), label: "记录"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "我的"),
        ],
      ),
    );
  }
}