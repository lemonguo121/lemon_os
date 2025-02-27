import 'package:flutter/material.dart';

import '../util/SPManager.dart';
import 'AddSubscriptionPage.dart';

class SubscriptionPage extends StatefulWidget {
  @override
  _SubscriptionPageState createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  List<Map<String, String>> _subscriptions = [];

  @override
  void initState() {
    super.initState();
    _loadSubscriptions();
  }

  Future<void> _loadSubscriptions() async {
    List<Map<String, String>> subscriptions = await SPManager.getSubscriptions();
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
        ],
      ),
      body: ListView.builder(
        itemCount: _subscriptions.length,
        itemBuilder: (context, index) {
          final site = _subscriptions[index];
          return ListTile(
            title: Text(site['name'] ?? ''),
            subtitle: Text(site['domain'] ?? ''),
            trailing: IconButton(
              icon: Icon(Icons.delete),
              onPressed: () => _deleteSubscription(site['name'] ?? ''),
            ),
          );
        },
      ),
    );
  }
}
