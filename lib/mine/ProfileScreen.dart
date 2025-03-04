import 'package:flutter/material.dart';
import 'package:lemen_os/download/DownloadManagerScreen.dart';

import '../download/DownloadManagerScreen.dart';
import '../subscrip/SubscriptionPage.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

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
                  child: Icon(Icons.image),
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
            leading: Icon(Icons.file_download),
            title: Text("下载"),
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DownloadManagerScreen(),
                  ));
            },
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
        ],
      ),
    );
  }
}
