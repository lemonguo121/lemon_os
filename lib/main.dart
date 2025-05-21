import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:lemon_tv/download/DownloadController.dart';
import 'package:lemon_tv/reader/home/ReaderHomePage.dart';
import 'package:lemon_tv/routes/routes.dart';
import 'package:lemon_tv/splash_page/splash_page.dart';
import 'package:lemon_tv/util/Injection.dart';
import 'package:lemon_tv/util/SPManager.dart';
import 'package:lemon_tv/util/ThemeController.dart';

import '../history/PlayHistory.dart';
import 'home/HomeScreen.dart';
import 'http/data/MyHttpOverrides.dart';
import 'mine/ProfileScreen.dart';
import 'music/music_home/MusicHomePage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = MyHttpOverrides();

  await Injection.init();
  var isRealFun = SPManager.isRealFun();
  initDownLoad();
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

void initDownLoad() {
  DownloadController downloadController = Get.find();
  downloadController.downloads.value = SPManager.getDownloads();
  downloadController.pauseAllTask();
  downloadController.startListening();
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
          useMaterial3: false,
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
        home: const SplashPage(),
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
    MovieHomeScreen(),
    PlayHistory(),
    MusicHomePage(),
    ReaderHomePage(),
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
          type: BottomNavigationBarType.fixed,
          backgroundColor: themeController.currentAppTheme.backgroundColor,
          unselectedItemColor: themeController.currentAppTheme.normalTextColor,
          fixedColor: themeController.currentAppTheme.selectedTextColor,
          elevation: 1.0,
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.movie), label: "影视"),
            BottomNavigationBarItem(icon: Icon(Icons.history), label: "记录"),
            BottomNavigationBarItem(
                icon: Icon(Icons.library_music), label: "音乐"),
            BottomNavigationBarItem(
                icon: Icon(Icons.menu_book), label: "小说"),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: "我的"),
          ],
        ),
      );
    });
  }
}
