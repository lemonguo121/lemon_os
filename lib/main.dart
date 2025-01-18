import 'dart:io';

import 'package:flutter/material.dart';
import '../category/CategoryFragment.dart';
import '../history/PlayHistory.dart';
import '../recommon/RecommendScreen.dart';

import 'home/HomeScreen.dart';
import 'http/data/MyHttpOverrides.dart';
import 'mine/ProfileScreen.dart';

void main() {
  HttpOverrides.global = MyHttpOverrides();
  runApp(ElectronicsStoreApp());
}

class ElectronicsStoreApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    HomeScreen(),
    PlayHistory(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex, // 当前选中的页面
        children: _pages,
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
