import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lemon_tv/util/AppColors.dart';
import 'package:lemon_tv/util/SPManager.dart';
import '../history/PlayHistory.dart';

import 'local/VideoGalleryPage.dart';
import 'home/HomeScreen.dart';
import 'http/data/MyHttpOverrides.dart';
import 'mine/ProfileScreen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = MyHttpOverrides();
  var isRealFun = await SPManager.isRealFun();
  runApp(ElectronicsStoreApp(isRealFun:isRealFun));
}

class ElectronicsStoreApp extends StatelessWidget {
  final bool isRealFun;

  const ElectronicsStoreApp({ super.key, required this.isRealFun});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
          scaffoldBackgroundColor: AppColors.themeColor, // 统一设置整个 App 的背景颜色
          appBarTheme: AppBarTheme(
            backgroundColor: AppColors.themeColor, // 设置 AppBar 颜色
            elevation: 0, // 去除阴影
          )),
      home: isRealFun ? HomePage() : VideoGalleryPage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    HomeScreen(),
    PlayHistory(),
    ProfileScreen(key: UniqueKey()),
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
        selectedItemColor: AppColors.selectColor,
        unselectedItemColor: Colors.green,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "首页"),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: "记录"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "我的"),
        ],
      ),
    );
  }
}
