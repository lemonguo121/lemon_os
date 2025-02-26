import 'package:flutter/material.dart';

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
                  backgroundImage: NetworkImage(
                      'https://via.placeholder.com/150'),
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
        ],
      ),
    );
  }
}