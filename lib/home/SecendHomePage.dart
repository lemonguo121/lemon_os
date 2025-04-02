import 'package:flutter/material.dart';

import '../local/PareseScreen.dart';
import '../local/VideoGalleryPage.dart';
import '../util/AppColors.dart';

class SecendHomePage extends StatefulWidget {
  const SecendHomePage({super.key});

  @override
  State<SecendHomePage> createState() => _SecendHomePageState();
}

class _SecendHomePageState extends State<SecendHomePage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    PareseScreen(),
    VideoGalleryPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex, // 当前选中的页面
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: AppColors.themeColor,
        unselectedItemColor: AppColors.selectColor,
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
        ],
      ),
    );
  }
}
