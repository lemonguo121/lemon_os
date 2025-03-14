import 'package:flutter/material.dart';
import 'package:lemon_tv/util/SubscriptionsUtil.dart';

import '../http/HttpService.dart';
import '../http/data/SubscripBean.dart';
import '../main.dart';
import '../util/SPManager.dart';

class AddSubscriptionPage extends StatefulWidget {
  @override
  _AddSubscriptionPageState createState() => _AddSubscriptionPageState();
}

class _AddSubscriptionPageState extends State<AddSubscriptionPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _domainController = TextEditingController();

  SubscriptionsUtil _subscriptionsUtil = SubscriptionsUtil();

  void _saveSubscription() async {
    String name = _nameController.text.trim();
    String domain = _domainController.text.trim();

    if (name.isNotEmpty && domain.isNotEmpty) {
      List<StorehouseBean> subscriptions = await SPManager.getSubscriptions();

      bool exists = subscriptions.any((sub) => sub.url == domain);
      if (exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("该站点已存在"), duration: Duration(seconds: 2)),
        );
        return;
      }
      List<StorehouseBean> sites = [];
      sites.add(StorehouseBean(name: name, url: domain));
      // _subscriptionsUtil.setCurrentSite(site);
      await SPManager.saveSubscription(sites);
      // await SPManager.saveCurrentStorehouse(name, domain, paresType);
      await _subscriptionsUtil.requestSubscription(name, domain);
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
        (route) => false,
      );
    }
  }

  /// **一键导入多个站点**
  void _onekeyAdd() async {
    // 获取当前存储的订阅列表
    List<StorehouseBean> subscriptions = await SPManager.getSubscriptions();
    var storehouseBean = StorehouseBean(
        name: "1122",
        url:
            "https://ghfast.top/https://raw.githubusercontent.com/lemonguo121/BoxRes/main/Myuse/cat.json");
    // int addedCount = 0;

    var map = await SubscriptionsUtil()
        .requestSubscription(storehouseBean.name, storehouseBean.url);

    // 检查是否仍然挂载，避免错误
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("操作成功"),
          duration: Duration(seconds: 2),
        ),
      );

      if (map.length > 0) {
        Navigator.pop(context);
        // Navigator.pushAndRemoveUntil(
        //   context,
        //   MaterialPageRoute(builder: (context) => HomePage()),
        //   (route) => false,
        // );
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
