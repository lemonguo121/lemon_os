import 'package:flutter/material.dart';

import '../http/HttpService.dart';
import '../main.dart';
import '../util/SPManager.dart';
import 'AddSubscriptionPage.dart';

class SubscriptionPage extends StatefulWidget {
  @override
  _SubscriptionPageState createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  List<Map<String, String>> _subscriptions = [];
  int? _selectedIndex; // 记录选中的条目索引
  Map<String, String>? _currentSubscription;

  @override
  void initState() {
    super.initState();
    _loadSubscriptions();
  }

  Future<void> _loadSubscriptions() async {
    List<Map<String, String>> subscriptions =
        await SPManager.getSubscriptions();
    _currentSubscription = await SPManager.getCurrentSubscription();

    if (_currentSubscription != null) {
      final selectedDomain = _currentSubscription!['domain'];
      _selectedIndex =
          subscriptions.indexWhere((site) => site['domain'] == selectedDomain);
    }

    setState(() {
      _subscriptions = subscriptions;
    });
  }

  void _deleteSubscription(String name) async {
    await SPManager.removeSubscription(name);
    _loadSubscriptions();
  }

  void _addSubscription() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddSubscriptionPage()),
    );
    if (result == true) {
      _loadSubscriptions();
    }
  }

  void _saveCurrentSubscription(Map<String, String> site) async {
    await SPManager.saveCurrentSubscription(
        site['name'] ?? '', site['domain'] ?? '', site['paresType'] ?? "");
  }

  void _onConfirm() async {
    if (_currentSubscription != null && _selectedIndex != null) {
      final selectedSite = _subscriptions[_selectedIndex!];
      final selectedDomain = selectedSite['domain'];

      if (_currentSubscription!['domain'] != selectedDomain) {
        await SPManager.saveCurrentSubscription(
            selectedSite['name'] ?? '', selectedSite['domain'] ?? '',selectedSite['paresType'] ?? '');

        HttpService.updateBaseUrl(selectedDomain ?? '');

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
          (route) => false,
        );
      } else {
        Navigator.pop(context);
      }
    }
  }

  /// 显示编辑站点弹窗
  void _editSubscription(Map<String, String> site) {
    TextEditingController nameController =
        TextEditingController(text: site['name']);
    TextEditingController domainController =
        TextEditingController(text: site['domain']);
    TextEditingController paresTypeController =
        TextEditingController(text: site['paresType']);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("编辑订阅"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: "站点名称"),
              ),
              TextField(
                controller: domainController,
                decoration: InputDecoration(labelText: "站点域名"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), // 取消
              child: Text("取消"),
            ),
            TextButton(
              onPressed: () async {
                String newName = nameController.text.trim();
                String newDomain = domainController.text.trim();
                String newParesType = paresTypeController.text.trim();
                if (newName.isNotEmpty && newDomain.isNotEmpty) {
                  await SPManager.updateSubscription(
                      site['name']!, newName, newDomain, newParesType);
                  await SPManager.updateCurrentSubscription(newName, newDomain);
                  _loadSubscriptions(); // 重新加载数据
                  Navigator.pop(context); // 关闭弹窗
                }
              },
              child: Text("保存"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("订阅管理"),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _addSubscription,
          ),
          IconButton(
            icon: Icon(Icons.check),
            onPressed: _onConfirm,
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _subscriptions.length,
        itemBuilder: (context, index) {
          final site = _subscriptions[index];
          return ListTile(
            leading: Radio<int>(
              value: index,
              groupValue: _selectedIndex,
              onChanged: (int? value) {
                setState(() {
                  _selectedIndex = value;
                  _saveCurrentSubscription(site);
                });
              },
            ),
            title: Text(site['name'] ?? ''),
            subtitle: Text(site['domain'] ?? ''),
            trailing: IconButton(
              icon: Icon(Icons.delete),
              onPressed: () => _deleteSubscription(site['name'] ?? ''),
            ),
            onTap: () {
              setState(() {
                _selectedIndex = index;
                _saveCurrentSubscription(site);
              });
            },
            onLongPress: () {
              _editSubscription(site); // 长按编辑
            },
          );
        },
      ),
    );
  }
}
