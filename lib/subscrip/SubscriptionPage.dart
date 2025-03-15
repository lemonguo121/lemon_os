import 'package:flutter/material.dart';
import 'package:lemon_tv/http/data/SubscripBean.dart';
import 'package:lemon_tv/mywidget/MyLoadingIndicator.dart';

import '../main.dart';
import '../util/SPManager.dart';
import '../util/SubscriptionsUtil.dart';

class SubscriptionPage extends StatefulWidget {
  @override
  _SubscriptionPageState createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  List<StorehouseBean> _storehouses = [];
  int? _selectedIndex; // 记录选中的条目索引
  StorehouseBean? _currentstorehouse;
  SubscriptionsUtil _subscriptionsUtil = SubscriptionsUtil();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    loadSubscriptions();
  }

  Future<void> loadSubscriptions() async {
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
    loadSubscriptions();
  }

  Future _saveCurrentSubscription(StorehouseBean storehouseBean) async {
    await SPManager.saveCurrentSubscription(storehouseBean);
    print("Saved successfully!");
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
      await Future.delayed(Duration(milliseconds: 300));
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
        (route) => false,
      );
    } else {
      Navigator.pop(context);
    }
  }

  void addSubscriptionDialog() {
    final TextEditingController _nameController = TextEditingController();
    final TextEditingController _domainController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("添加订阅"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: InputDecoration(labelText: "仓库名称"),
              ),
              TextField(
                controller: _domainController,
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
                String name = _nameController.text.trim();
                String url = _domainController.text.trim();
                await requestSubscription(name, url);
                Navigator.pop(context);
              },
              child: Text("添加"),
            ),
            TextButton(
                onPressed: () async {
                  var storehouseBean = StorehouseBean(
                      name: "1122",
                      url:
                          "https://ghfast.top/https://raw.githubusercontent.com/lemonguo121/BoxRes/main/Myuse/cat.json");
                  _nameController.text = storehouseBean.name;
                  _domainController.text = storehouseBean.url;
                  await requestSubscription(
                      storehouseBean.name, storehouseBean.url);
                  Navigator.pop(context);
                },
                child: Text("一键添加"))
          ],
        );
      },
    );
  }

  Future requestSubscription(String name, String url) async {
    setState(() {
      isLoading = true;
    });
    await _subscriptionsUtil.requestSubscription(name, url);
    await loadSubscriptions(); // 重新加载订阅列表
    if (mounted) {
      setState(() {
        isLoading = false;
      });
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
                  loadSubscriptions(); // 重新加载数据
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
            onPressed: addSubscriptionDialog,
          ),
          IconButton(
            icon: Icon(Icons.check),
            onPressed: _onConfirm,
          ),
        ],
      ),
      body: isLoading
          ? Column(
              children: [MyLoadingIndicator(isLoading: isLoading)],
            )
          : ListView.builder(
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
                      });
                    },
                  ),
                  title: Text(storehouseBean.name ?? ''),
                  subtitle: Text(storehouseBean.url ?? ''),
                  trailing: IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () =>
                        _deleteSubscription(storehouseBean.name ?? ''),
                  ),
                  onTap: () {
                    setState(() {
                      _selectedIndex = index;
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
