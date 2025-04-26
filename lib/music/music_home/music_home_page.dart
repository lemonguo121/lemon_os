import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:lemon_tv/music/libs/music_record.dart';

import '../../mine/SecendMinePage.dart';
import '../../util/ThemeController.dart';
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
  final List<Widget> _pages = [
    MusicSearchPage(),
    MusicRecord(),
    SecendMinePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex, // 当前选中的页面
        children: _pages,
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
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "记录"),
          // BottomNavigationBarItem(icon: Icon(Icons.history), label: "记录"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "我的"),
        ],
      ),
    );
  }
}
