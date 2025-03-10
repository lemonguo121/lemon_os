import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lemon_os/mywidget/MyLoadingIndicator.dart';
import 'package:lemon_os/subscrip/SubscriptionPage.dart';
import 'package:lemon_os/util/CommonUtil.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:xml/xml.dart';

import '../category/CategoryFragment.dart';
import '../category/HomeFragment.dart';
import '../http/HttpService.dart';
import '../http/data/CategoryBean.dart';
import '../http/data/HomeCateforyData.dart';
import '../http/data/RealVideo.dart';
import '../http/data/Video.dart';
import '../search/SearchScreen.dart';
import '../subscrip/AddSubscriptionPage.dart';
import '../util/SPManager.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  late TabController _tabController = TabController(length: 0, vsync: this);
  final HttpService _httpService = HttpService();
  List<CategoryBean> categories = [];
  bool isLoading = true;
  String scripName = "未订阅";
  String paresType = "1";

  // 缓存 Fragment 实例
  final Map<String, CategoryFragment> _cachedFragments = {};
  final Map<String, HomeFragment> _cachehomeFragment = {};

  // 缓存数据
  final Map<String, RealResponseData> _cachedData = {};
  final Map<String, Map<int, List<HomeCategoryData>>> _cachedHomeData = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    try {
      await _getSubscripName();
      var responseString;
      if (paresType == "1") {
        Map<String, dynamic> jsonMap = await _httpService.get("");
        responseString = ResponseData.fromJson(jsonMap);
      } else {
        XmlDocument xmlDoc = await _httpService.get("");
        responseString = ResponseData.fromXml(xmlDoc);
      }

      List<CategoryBean> loadedCategories = [
        CategoryBean(
            typeId: -1, typePid: -1, typeName: "首页", categoryChildList: [])
      ]..addAll(responseString.alClass);

      setState(() {
        categories = loadedCategories;
        _tabController = TabController(length: categories.length, vsync: this);
      });
    } catch (e) {
      print("Error lemon: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Widget _getCategoryFragment(CategoryBean alClass) {
    if (alClass.typeName == "首页") {
      return _cachehomeFragment.putIfAbsent(
        "首页",
        () => HomeFragment(
          alClass: alClass,
          cachedData: _cachedHomeData[alClass.typeName],
          categories: categories,
          onDataLoaded: (data) => _cachedHomeData[alClass.typeName] = data,
        ),
      );
    } else {
      return _cachedFragments.putIfAbsent(
        alClass.typeName,
        () => CategoryFragment(
          alClass: alClass,
          cachedData: _cachedData[alClass.typeName],
          onDataLoaded: (data) => _cachedData[alClass.typeName] = data,
        ),
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildCategorySelector() {
    return Column(
      children: [
        /// 使用 `PreferredSize` 让 `TabBar` 更稳定
        PreferredSize(
          preferredSize: const Size.fromHeight(30), // TabBar 高度
          child: TabBar(
            controller: _tabController,
            isScrollable: categories.length > 5,
            indicatorColor: Colors.transparent,
            indicatorSize: TabBarIndicatorSize.tab,
            dividerHeight: 0,
            indicatorPadding: EdgeInsets.zero,
            labelStyle:
                const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            unselectedLabelStyle: const TextStyle(fontSize: 16),
            dividerColor: Colors.transparent,
            // 去除底部黑线
            tabAlignment: TabAlignment.start,
            tabs: categories
                .map((alClass) => Tab(text: alClass.typeName))
                .toList(),
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            physics: const BouncingScrollPhysics(),
            children: categories.map(_getCategoryFragment).toList(),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Column(children: [MyLoadingIndicator(isLoading: isLoading)]);
    }
    var isVertical = CommonUtil.isVertical(context);
    return Scaffold(
      body: Column(
        children: [
          SizedBox(height: isVertical ? 55.0 : 40),
          _buildSearch(),
          Expanded(
              child: FutureBuilder(
            future: SPManager.getSubscriptions(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return _buildNoSubscriptionView();
              }
              return categories.isEmpty
                  ? _buildNoDataView()
                  : _buildCategorySelector();
            },
          )),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    return Row(
      children: [
        const SizedBox(width: 12.0),
        GestureDetector(
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (context) => SubscriptionPage())),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.public, size: 16, color: Colors.blue),
              const SizedBox(width: 4),
              SizedBox(
                width: 40,
                child: Text(scripName,
                    style: const TextStyle(fontSize: 12, color: Colors.black87),
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8.0),
        Expanded(
          child: InkWell(
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (context) => SearchScreen())),
            child: Container(
              height: 35,
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Colors.grey),
                  const SizedBox(width: 8.0),
                  Text("输入搜索内容",
                      style:
                          TextStyle(fontSize: 16.0, color: Colors.grey[600])),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12.0),
      ],
    );
  }

  Widget _buildNoSubscriptionView() {
    return Center(
      child: GestureDetector(
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (context) => AddSubscriptionPage())),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('暂无数据，点击添加',
                style: TextStyle(color: Colors.grey, fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildNoDataView() {
    return Center(
      child: GestureDetector(
        onTap: _loadData,
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.refresh, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('暂无数据，点击刷新',
                style: TextStyle(color: Colors.grey, fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Future<void> _getSubscripName() async {
    var _currentSubscription = await SPManager.getCurrentSubscription();
    if (_currentSubscription != null) {
      setState(() {
        scripName = _currentSubscription['name'] ?? "未订阅";
        paresType = _currentSubscription['paresType'] ?? "1";
      });
    } else {
      setState(() {
        scripName = "未订阅";
        paresType = "0";
      });
    }
  }
}
