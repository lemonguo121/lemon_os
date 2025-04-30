import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart';
import 'package:lemon_tv/http/HttpService.dart';
import 'package:lemon_tv/music/data/PluginBean.dart';

import '../http/data/SubscripBean.dart';
import '../main.dart';
import '../music/music_home/music_home_page.dart';
import '../music/music_http/music_http_rquest.dart';
import '../music/music_utils/MusicSPManage.dart';
import '../mywidget/MyLoadingIndicator.dart';
import '../util/SubscriptionsUtil.dart';
import '../util/ThemeController.dart';

class PluginsPage extends StatefulWidget {
  const PluginsPage({super.key});

  @override
  State<PluginsPage> createState() => _PluginsPageState();
}

class _PluginsPageState extends State<PluginsPage> {
  List<StorehouseBean> _storehouses = [];
  int? _selectedIndex; // 记录选中的条目索引
  StorehouseBean? _currentstorehouse;
  SubscriptionsUtil _subscriptionsUtil = SubscriptionsUtil();
  bool isLoading = false;
  final ThemeController themeController = Get.find();
  // List<PluginInfo> plugins = [];

  @override
  void initState() {
    super.initState();
    loadSubscriptions();
  }

  loadSubscriptions() async {

    final subscriptions = MusicSPManage.getSubscriptions();
    final currentStorehouse = MusicSPManage.getCurrentSubscription();

    setState(() {
      if (currentStorehouse != null) {
        _selectedIndex = subscriptions.indexWhere((site) =>
        site.url == currentStorehouse.url ||
            site.name == currentStorehouse.name);
        _currentstorehouse = currentStorehouse;
      }
      _storehouses = subscriptions;
    });
  }

  void _deleteSubscription(String name) {
    MusicSPManage.removeSubscription(name);
    setState(() {
      _storehouses.removeWhere((item) => item.name == name);
      if (_selectedIndex != null && _selectedIndex! >= _storehouses.length) {
        _selectedIndex = null; // 重置选中项
        _currentstorehouse = null;
      }
    });
    loadSubscriptions();
  }

  void _onConfirm() async {
    if (_selectedIndex == null || _selectedIndex! >= _storehouses.length) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("请选择一个订阅"),
      ));
      return;
    }
    final selectedSite = _storehouses[_selectedIndex!];
    _storehouses.removeAt(_selectedIndex!);
    _storehouses.insert(0, selectedSite);
    MusicSPManage.saveSubscription(_storehouses);
    final selectedUrl = selectedSite.url;
    final selectedName = selectedSite.name;
    if (_currentstorehouse == null || _currentstorehouse!.url != selectedUrl) {
      var storehouse = StorehouseBean(name: selectedName, url: selectedUrl);
      MusicSPManage.saveCurrentSubscription(storehouse);
      NetworkManager().updateBaseUrl(storehouse.url);
      MusicSPManage.cleanCurrentSite();
      await Future.delayed(Duration(milliseconds: 300));
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => MusicHomePage()),
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
          title: Stack(
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: Text("添加订阅"),
              ),
              Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: () async {
                    var storehouseBean = StorehouseBean(
                      name: "1122",
                      url:
                          "https://gh-proxy.com/https://raw.githubusercontent.com/lemonguo121/BoxRes/refs/heads/main/Myuse/music_plugin.json",
                      // "https://gh-proxy.com/https://raw.githubusercontent.com/lemonguo121/BoxRes/main/Myuse/cat.json",
                    );
                    _nameController.text = storehouseBean.name;
                    _domainController.text = storehouseBean.url;
                    Navigator.pop(context);
                    await requestSubscription(
                        storehouseBean.name, storehouseBean.url);
                  },
                  child: Text(
                    "一键添加",
                    style: TextStyle(color: Colors.blue),
                  ),
                ),
              ),
            ],
          ),
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
                Navigator.pop(context);
                await requestSubscription(name, url);
              },
              child: Text("添加"),
            ),
          ],
        );
      },
    );
  }

  Future requestSubscription(String name, String url) async {
    try {
      setState(() {
        isLoading = true;
      });
      await _subscriptionsUtil.requestMusicSubscription(name, url);
      await loadSubscriptions(); // 重新加载订阅列表
    } catch (e) {
      print("requestSubscription   e = $e");
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
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
                  MusicSPManage.saveSubscription(_storehouses);
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
    return Obx(() => Scaffold(
          appBar: AppBar(
            iconTheme: IconThemeData(
                color: themeController.currentAppTheme.normalTextColor),
            title: Text(
              "订阅管理",
              style: TextStyle(
                  color: themeController.currentAppTheme.normalTextColor),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.add,
                    color: themeController.currentAppTheme.normalTextColor),
                onPressed: addSubscriptionDialog,
              ),
              IconButton(
                icon: Icon(Icons.check,
                    color: themeController.currentAppTheme.normalTextColor),
                onPressed: _onConfirm,
              ),
            ],
          ),
          body: isLoading
              ? Column(
                  children: [MyLoadingIndicator(isLoading: isLoading)],
                )
              : _storehouses.isEmpty
                  ? _buildNoSubscriptionView()
                  : ListView.builder(
                      itemCount: _storehouses.length,
                      itemBuilder: (context, index) {
                        final storehouseBean = _storehouses[index];
                        return ListTile(
                          leading: Radio<int>(
                            value: index,
                            groupValue: _selectedIndex,
                            activeColor:
                                themeController.currentAppTheme.iconColor,
                            focusColor: themeController
                                .currentAppTheme.unselectedTextColor,
                            onChanged: (int? value) {
                              setState(() {
                                _selectedIndex = value;
                              });
                            },
                          ),
                          title: Text(
                            storehouseBean.name ?? '',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color:
                                    themeController.currentAppTheme.titleColr),
                          ),
                          subtitle: Text(
                            storehouseBean.url ?? '',
                            style: TextStyle(
                                color: themeController
                                    .currentAppTheme.contentColor),
                          ),
                          trailing: IconButton(
                              icon: Icon(Icons.delete,
                                  color: themeController
                                      .currentAppTheme.normalTextColor),
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
        ));
  }

  Widget _buildNoSubscriptionView() {
    return Center(
      child: GestureDetector(
        onTap: () => addSubscriptionDialog(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add,
                size: 64,
                color: themeController.currentAppTheme.selectedTextColor),
            const SizedBox(height: 16),
            Text('暂无订阅，点击添加',
                style: TextStyle(
                    color: themeController.currentAppTheme.selectedTextColor,
                    fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
