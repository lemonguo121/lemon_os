import 'package:flutter/material.dart';

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
      await SPManager.saveSubscription(name, domain);
      Navigator.pop(context, true);
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