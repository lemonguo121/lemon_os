import 'package:flutter/material.dart';

import '../subscrip/SubscriptionPage.dart';
import '../util/CacheUtil.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  double _cacheSize = 0;

  @override
  void initState() {
    super.initState();
    _updateCacheSize();
  }

  /// 更新缓存大小
  Future<void> _updateCacheSize() async {
    double size = await CacheUtil.getCacheSize();
    setState(() {
      print("size $size");
      _cacheSize = size;
    });
  }

  /// 清理缓存
  Future<void> _clearCache() async {
    await CacheUtil.clearCache();
    await _updateCacheSize(); // 清理后更新 UI
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("缓存已清理")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("我的"),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.blue,
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  // backgroundImage:
                  //     NetworkImage(''),
                ),
                SizedBox(width: 16),
                Text(
                  "用户名",
                  style: TextStyle(color: Colors.white, fontSize: 20),
                ),
              ],
            ),
          ),
          ListTile(
            leading: Icon(Icons.settings),
            title: Text("设置"),
            onTap: () {},
          ),
          ListTile(
            leading: Icon(Icons.login),
            title: Text("登录"),
            onTap: () {},
          ),
          ListTile(
            leading: Icon(Icons.subscriptions),
            title: Text("订阅管理"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SubscriptionPage()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.clear_all), // 清理缓存图标
            title: Text("清理缓存"),
            trailing: Text("${_cacheSize.toStringAsFixed(2)} MB"), // 显示缓存大小
            onTap: _clearCache, // 点击清理缓存
          ),
        ],
      ),
    );
  }
}
