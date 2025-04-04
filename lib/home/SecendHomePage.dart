import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../local/PareseScreen.dart';
import '../local/VideoGalleryPage.dart';
import '../mine/SecendMinePage.dart';
import '../util/ThemeController.dart';

class SecendHomePage extends StatefulWidget {
  const SecendHomePage({super.key});

  @override
  State<SecendHomePage> createState() => _SecendHomePageState();
}

class _SecendHomePageState extends State<SecendHomePage> {
  int _currentIndex = 0;
  final ThemeController themeController = Get.find();
  final List<Widget> _pages = [
    PareseScreen(),
    VideoGalleryPage(),
    SecendMinePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Scaffold(
        body: IndexedStack(
          index: _currentIndex, // 当前选中的页面
          children: _pages,
        ),
        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: themeController.currentAppTheme.backgroundColor,
          unselectedItemColor:
              themeController.currentAppTheme.selectedTextColor,
          selectedItemColor: Colors.green,
          elevation: 1.0,
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.public), label: "在线"),
            BottomNavigationBarItem(icon: Icon(Icons.folder), label: "本地"),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: "我的"),
          ],
        ),
      );
    });
  }
}
