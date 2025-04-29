import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:lemon_tv/routes/routes.dart';
import 'package:lemon_tv/util/Injection.dart';
import 'package:lemon_tv/util/SPManager.dart';
import 'package:lemon_tv/util/ThemeController.dart';

import '../history/PlayHistory.dart';
import 'home/HomeScreen.dart';
import 'http/data/MyHttpOverrides.dart';
import 'mine/ProfileScreen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = MyHttpOverrides();
  await Injection.init();
  var isRealFun = SPManager.isRealFun();
  runApp(
    ScreenUtilInit(
      designSize: const Size(750, 1334),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return ElectronicsStoreApp(isRealFun: isRealFun);
      },
    ),
  );
}

class ElectronicsStoreApp extends StatelessWidget {
  final bool isRealFun;

  const ElectronicsStoreApp({super.key, required this.isRealFun});

  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.find();

    return Obx(() {
      return GetMaterialApp(
        initialRoute: '/',
        getPages: Routes.routePage,
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
        home: HomePage(),
        // home: (!isRealFun && Platform.isIOS) ? SecendHomePage() : HomePage(),
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
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Colors.blue,
                ),
                child: Text('菜单头部',
                    style: TextStyle(color: Colors.white, fontSize: 24)),
              ),
              ListTile(
                leading: Icon(Icons.home),
                title: Text('主页'),
                onTap: () {
                  Navigator.pop(context);
                  // 处理点击事件
                },
              ),
              ListTile(
                leading: Icon(Icons.settings),
                title: Text('设置'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
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
