import 'package:flutter/material.dart';
import 'package:lemon_tv/http/data/SubscripBean.dart';

import '../http/HttpService.dart';
import '../main.dart';
import '../util/SPManager.dart';
import 'AddSubscriptionPage.dart';

class SubscriptionPage extends StatefulWidget {
  @override
  _SubscriptionPageState createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  List<StorehouseBean> _storehouses = [];
  int? _selectedIndex; // 记录选中的条目索引
  StorehouseBean? _currentstorehouse;

  @override
  void initState() {
    super.initState();
    _loadSubscriptions();
  }

  Future<void> _loadSubscriptions() async {
    final subscriptionsFuture = SPManager.getSubscriptions();
    final currentStorehouseFuture = SPManager.getCurrentSubscription();

    final subscriptions = await subscriptionsFuture;
    final currentStorehouse = await currentStorehouseFuture;

    setState(() {
      if (currentStorehouse != null) {
        print(
            "_currentstorehouse ${currentStorehouse.name}   ${currentStorehouse.url}");
        _selectedIndex = subscriptions.indexWhere((site) =>
            site.url == currentStorehouse.url ||
            site.name == currentStorehouse.name);
        _currentstorehouse = currentStorehouse;

      }
      _storehouses = subscriptions;
    });
  }

  void _deleteSubscription(String name) async {
    await SPManager.removeSubscription(name);
    setState(() {
      _storehouses.removeWhere((item) => item.name == name);
      if (_selectedIndex != null && _selectedIndex! >= _storehouses.length) {
        _selectedIndex = null; // 重置选中项
        _currentstorehouse = null;
      }
    });
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

  Future _saveCurrentSubscription(StorehouseBean storehouseBean) async {
    await SPManager.saveCurrentSubscription(storehouseBean);
  }

  void _onConfirm() async {
    if (_selectedIndex == null || _selectedIndex! >= _storehouses.length) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("请选择一个订阅"),
      ));
      return;
    }
    final selectedSite = _storehouses[_selectedIndex!];
    final selectedUrl = selectedSite.url;
    final selectedName = selectedSite.name;
    if (_currentstorehouse == null || _currentstorehouse!.url != selectedUrl) {
      var storehouse = StorehouseBean(name: selectedName, url: selectedUrl);
      await _saveCurrentSubscription(storehouse);

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
        (route) => false,
      );
    } else {
      Navigator.pop(context);
    }
  }

  /// 显示编辑站点弹窗
  void _editSubscription(int index) {
    var storehouse = _storehouses[index];
    TextEditingController nameController =
        TextEditingController(text: storehouse.name);
    TextEditingController domainController =
        TextEditingController(text: storehouse.url);

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
                decoration: InputDecoration(labelText: "仓库名称"),
              ),
              TextField(
                controller: domainController,
                decoration: InputDecoration(labelText: "仓库域名"),
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
                String newRul = domainController.text.trim();
                if (newName.isNotEmpty && newRul.isNotEmpty) {
                  _storehouses[index] =
                      StorehouseBean(url: newRul, name: newName);
                  await SPManager.saveSubscription(_storehouses);
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
        itemCount: _storehouses.length,
        itemBuilder: (context, index) {
          final storehouseBean = _storehouses[index];
          return ListTile(
            leading: Radio<int>(
              value: index,
              groupValue: _selectedIndex,
              onChanged: (int? value) {
                setState(() {
                  _selectedIndex = value;
                  // _selectCurrentstorehouse = storehouseBean;
                });
              },
            ),
            title: Text(storehouseBean.name ?? ''),
            subtitle: Text(storehouseBean.url ?? ''),
            trailing: IconButton(
              icon: Icon(Icons.delete),
              onPressed: () => _deleteSubscription(storehouseBean.name ?? ''),
            ),
            onTap: () {
              setState(() {
                _selectedIndex = index;
                _currentstorehouse = storehouseBean;
              });
            },
            onLongPress: () {
              _editSubscription(index); // 长按编辑
            },
          );
        },
      ),
    );
  }
}
