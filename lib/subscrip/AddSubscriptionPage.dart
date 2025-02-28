import 'package:flutter/material.dart';

import '../http/HttpService.dart';
import '../main.dart';
import '../util/SPManager.dart';

class AddSubscriptionPage extends StatefulWidget {
  @override
  _AddSubscriptionPageState createState() => _AddSubscriptionPageState();
}

class _AddSubscriptionPageState extends State<AddSubscriptionPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _domainController = TextEditingController();

  void _saveSubscription() async {
    String name = _nameController.text.trim();
    String domain = _domainController.text.trim();

    if (name.isNotEmpty && domain.isNotEmpty) {
      // 获取当前所有已订阅的站点
      List<Map<String, String>> subscriptions = await SPManager.getSubscriptions();

      // 检查该 domain 是否已经存在
      bool exists = subscriptions.any((sub) => sub['domain'] == domain);

      if (exists) {
        // 显示提示
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("该站点已存在"),
            duration: Duration(seconds: 2),
          ),
        );
        return; // 终止后续逻辑
      }

      await SPManager.saveSubscription(name, domain);
      await SPManager.saveCurrentSubscription(name, domain);
      // 更新 HttpService 中的 baseUrl
      HttpService.updateBaseUrl(domain ?? '');

      // 关闭所有页面并重新启动，回到 HomeScreen
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => HomePage()), // 替换成你的 HomePage 页面
            (route) => false, // 这会移除所有页面，确保回到首页
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("添加订阅")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: "站点名称"),
            ),
            TextField(
              controller: _domainController,
              decoration: InputDecoration(labelText: "站点域名"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveSubscription,
              child: Text("保存"),
            ),
          ],
        ),
      ),
    );
  }
}
