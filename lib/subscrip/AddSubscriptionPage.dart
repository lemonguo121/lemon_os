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
  final TextEditingController _paresController = TextEditingController();

  void _saveSubscription() async {
    String name = _nameController.text.trim();
    String domain = _domainController.text.trim();
    String paresType = _paresController.text.trim();

    if (name.isNotEmpty && domain.isNotEmpty) {
      List<Map<String, String>> subscriptions =
          await SPManager.getSubscriptions();

      bool exists = subscriptions.any((sub) => sub['domain'] == domain);
      if (exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("该站点已存在"), duration: Duration(seconds: 2)),
        );
        return;
      }

      await SPManager.saveSubscription(name, domain,paresType);
      await SPManager.saveCurrentSubscription(name, domain,paresType);
      HttpService.updateBaseUrl(domain);

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
        (route) => false,
      );
    }
  }

  /// **一键导入多个站点**
  void _onekeyAdd() async {
    List<Map<String, String>> defaultSubscriptions = [
      {
        "name": "黑木耳",
        "domain": "https://json02.heimuer.xyz/api.php/provide/vod/",
        "paresType": "1"
      },
      {
        "name": "爱看",
        "domain": "https://ikunzyapi.com/api.php/provide/vod/from/ikm3u8/",
        "paresType": "1"
      },
      {
        "name": "最大",
        "domain": "https://zuida001.com/api.php/provide/vod/at/xml/",
        "paresType": "0"
      },
      {
        "name": "乐播",
        "domain": "https://lbapi9.com/api.php/provide/vod/at/xml/",
        "paresType": "0"
      }
    ];

    // 获取当前存储的订阅列表
    List<Map<String, String>> subscriptions = await SPManager.getSubscriptions();

    int addedCount = 0;

    for (var sub in defaultSubscriptions) {
      bool exists = subscriptions.any((s) => s['domain'] == sub['domain']);
      if (!exists) {
        await SPManager.saveSubscription(sub['name']!, sub['domain']!, sub['paresType']!);
        addedCount++;
      }
    }

    if (addedCount > 0) {
      await SPManager.saveCurrentSubscription(
        defaultSubscriptions[0]['name']!,
        defaultSubscriptions[0]['domain']!,
        defaultSubscriptions[0]['paresType']!,
      );
      HttpService.updateBaseUrl(defaultSubscriptions[0]['domain']!);
    }

    // 检查是否仍然挂载，避免错误
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(addedCount > 0 ? "成功导入 $addedCount 个站点" : "所有站点已存在"),
          duration: Duration(seconds: 2),
        ),
      );

      if (addedCount > 0) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
              (route) => false,
        );
      }
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
            TextField(
              controller: _domainController,
              decoration: InputDecoration(labelText: "解析类型"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveSubscription,
              child: Text("保存"),
            ),
            ElevatedButton(
              onPressed: _onekeyAdd,
              child: Text("一键导入"),
            ),
          ],
        ),
      ),
    );
  }
}
