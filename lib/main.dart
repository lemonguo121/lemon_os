import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:permission_handler/permission_handler.dart';

import '../history/PlayHistory.dart';
import 'download/DownloadManager.dart';
import 'home/HomeScreen.dart';
import 'http/data/MyHttpOverrides.dart';
import 'mine/ProfileScreen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = MyHttpOverrides();
  // 请求存储权限
  await Permission.storage.request();
  // 初始化 FlutterDownloader
  await FlutterDownloader.initialize(debug: true);
  // 初始化下载管理器
  final downloadManager = DownloadManager();
  await downloadManager.initialize();
  // 加载先前的下载任务（如果有）
  await downloadManager.loadTasks();

  runApp(ElectronicsStoreApp());
}

class ElectronicsStoreApp extends StatelessWidget {
  const ElectronicsStoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    var color = Colors.white;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: color, // 统一设置整个 App 的背景颜色
          appBarTheme: AppBarTheme(
            backgroundColor: color, // 设置 AppBar 颜色
            elevation: 0, // 去除阴影
          )
      ),
      home: HomePage(),
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
    PlayHistory(key: UniqueKey()),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex, // 当前选中的页面
        children: [
          HomeScreen(),
          PlayHistory(key: UniqueKey()),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
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
