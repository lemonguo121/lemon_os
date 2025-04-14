import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:lemon_tv/util/SPManager.dart';
import 'package:lemon_tv/util/ThemeController.dart';

import '../history/PlayHistory.dart';
import 'home/HomeScreen.dart';
import 'home/SecendHomePage.dart';
import 'http/data/MyHttpOverrides.dart';
import 'mine/ProfileScreen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = MyHttpOverrides();
  var isRealFun = await SPManager.isRealFun();
  final ThemeController themeController =
      Get.put(ThemeController()); // 初始化主题控制器
  runApp(ScreenUtilInit(
    designSize: const Size(750, 1334), //物理设备的大小
    minTextAdapt: true, //是否根据宽度/高度中的最小值适配文字
    splitScreenMode: true, //支持分屏尺寸
    builder: (context, child) {
      return ElectronicsStoreApp(isRealFun: isRealFun);
    },
  ));
}

class ElectronicsStoreApp extends StatelessWidget {
  final bool isRealFun;

  const ElectronicsStoreApp({super.key, required this.isRealFun});

  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.find();

    return Obx(() {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          scaffoldBackgroundColor:
              themeController.currentAppTheme.backgroundColor,
          appBarTheme: AppBarTheme(
            backgroundColor: themeController.currentAppTheme.backgroundColor,
            elevation: 0,
          ),
          textTheme: TextTheme(
            bodyMedium: TextStyle(
                color: themeController.currentAppTheme.normalTextColor),
          ),
          iconTheme:
              IconThemeData(color: themeController.currentAppTheme.iconColor),
          primaryColor: themeController.currentAppTheme.buttonColor,
        ),
        home: (!isRealFun && Platform.isIOS) ? SecendHomePage() : HomePage(),
      );
    });
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  final ThemeController themeController = Get.find();
  final List<Widget> _pages = [
    HomeScreen(),
    PlayHistory(),
    ProfileScreen(key: UniqueKey()),
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
            BottomNavigationBarItem(icon: Icon(Icons.history), label: "记录"),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: "我的"),
          ],
        ),
      );
    });
  }
}
