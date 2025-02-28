import 'package:flutter/material.dart';
import '../home/HomeScreen.dart';
import '../main.dart';
import '../util/SPManager.dart';
import 'AddSubscriptionPage.dart';
import '../http/HttpService.dart';

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
    // 获取订阅列表和当前选中的站点
    List<Map<String, String>> subscriptions = await SPManager.getSubscriptions();
    _currentSubscription = await SPManager.getCurrentSubscription();

    // 设置选中状态，如果有当前选中的站点
    if (_currentSubscription != null) {
      final selectedDomain = _currentSubscription!['domain'];
      _selectedIndex = subscriptions.indexWhere((site) => site['domain'] == selectedDomain);
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
    // 保存当前选中的站点
    await SPManager.saveCurrentSubscription(site['name'] ?? '', site['domain'] ?? '');
  }

  void _onConfirm() async {
    if (_currentSubscription != null && _selectedIndex != null) {
      final selectedSite = _subscriptions[_selectedIndex!];
      final selectedDomain = selectedSite['domain'];

      // 如果当前选中的域名和之前保存的域名不同，更新baseUrl并刷新页面
      if (_currentSubscription!['domain'] != selectedDomain) {
        await SPManager.saveCurrentSubscription(
            selectedSite['name'] ?? '', selectedSite['domain'] ?? '');

        // 更新 HttpService 中的 baseUrl
        HttpService.updateBaseUrl(selectedDomain ?? '');

        // 关闭所有页面并重新启动，回到 HomeScreen
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => HomePage()), // 替换成你的 HomePage 页面
              (route) => false, // 这会移除所有页面，确保回到首页
        );
      } else {
        // 如果相同，则直接关闭当前页面
        Navigator.pop(context);
      }
    }
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
            onPressed: _onConfirm, // 点击确认按钮
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _subscriptions.length,
        itemBuilder: (context, index) {
          final site = _subscriptions[index];
          return ListTile(
            leading: Radio<int>(
              value: index, // 为每个条目分配一个唯一的值
              groupValue: _selectedIndex, // 绑定到当前选中的索引
              onChanged: (int? value) {
                setState(() {
                  _selectedIndex = value; // 设置选中的条目
                  _saveCurrentSubscription(site); // 保存选中的站点
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
                _selectedIndex = index; // 点击条目时选择该条目
                _saveCurrentSubscription(site); // 保存选中的站点
              });
            },
          );
        },
      ),
    );
  }
}