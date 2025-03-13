import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lemon_tv/util/SubscriptionsUtil.dart';
import 'package:xml/xml.dart';

import '../category/CategoryFragment.dart';
import '../category/HomeFragment.dart';
import '../http/HttpService.dart';
import '../http/data/CategoryBean.dart';
import '../http/data/HomeCateforyData.dart';
import '../http/data/RealVideo.dart';
import '../http/data/Video.dart';
import '../http/data/storehouse_bean_entity.dart';
import '../main.dart';
import '../mywidget/MyLoadingIndicator.dart';
import '../search/SearchScreen.dart';
import '../subscrip/AddSubscriptionPage.dart';
import '../util/CommonUtil.dart';
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
  final SubscriptionsUtil _subscriptionsUtil = SubscriptionsUtil();
  List<CategoryBean> categories = [];
  bool isLoading = true;
  StorehouseBeanSites? currentSite;

  // String paresType = "1";

  // 缓存 Fragment 实例
  final Map<String, CategoryFragment> _cachedFragments = {};
  final Map<String, HomeFragment> _cachehomeFragment = {};
  int _selecteSitedIndex = 0; //
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
      var currentStorehouse = await SPManager.getCurrentSubscription();
      if (currentStorehouse == null) {
        setState(() {
          currentSite = null;
        });
        return;
      }
      var siteMap = await _subscriptionsUtil.requestSubscription(
          currentStorehouse?.name ?? "", currentStorehouse?.url ?? "");
      // "https://ghfast.top/https://raw.githubusercontent.com/lemonguo121/BoxRes/main/Myuse/cat.json");
      // await _getSubscripName();
      if (siteMap==null) {
        setState(() {
          currentSite = null;
        });
        return;
      }
      currentSite = await SPManager.getCurrentSite();
      if (currentSite==null) {
        setState(() {
          currentSite = null;
        });
        return;
      }
      var responseString;
      if (currentSite?.type == 1) {
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
            child: currentSite == null
                ? _buildNoSubscriptionView() // 如果 currentSite 为 null，显示 "没有订阅" 视图
                : categories.isEmpty
                    ? _buildNoDataView() // 如果 categories 为空，显示 "没有数据" 视图
                    : _buildCategorySelector(), // 否则，显示分类选择视图
          ),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    return Row(
      children: [
        const SizedBox(width: 12.0),
        GestureDetector(
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true, // 让弹窗自适应
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              builder: (context) {
                return Container(
                  padding: EdgeInsets.all(16),
                  height: 260, // 固定弹窗高度
                  width: 320,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("请选择首页数据源",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      SizedBox(height: 16),
                      // 将 GridView 放入 SingleChildScrollView 或 Expanded
                      Expanded(
                        child: GridView.builder(
                          shrinkWrap: true, // 防止 GridView 超出范围
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 8.0,
                            crossAxisSpacing: 8.0,
                            mainAxisExtent: 30,
                          ),
                          itemCount:
                              SubscriptionsUtil().selectStorehouse.length,
                          itemBuilder: (context, index) {
                            return _buildSiteGridItem(index);
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.public, size: 16, color: Colors.blue),
              const SizedBox(width: 4),
              SizedBox(
                width: 40,
                child: Text(
                  currentSite?.name ?? "未订阅",
                  style: const TextStyle(fontSize: 12, color: Colors.black87),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8.0),
        Expanded(
          child: InkWell(
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => SearchScreen(
                          query: "",
                        ))),
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

  Widget _buildSiteGridItem(int index) {
    var selectStorehouse = _subscriptionsUtil.selectStorehouse[index];
    var siteName = selectStorehouse.name;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selecteSitedIndex = index;
          SPManager.saveCurrentSite(selectStorehouse);
          // _subscriptionsUtil.currentSite = selectStorehouse;
        });
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
          (route) => false,
        );
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 4.0),
        alignment: Alignment.center,
        decoration: BoxDecoration(
            color: siteName == (currentSite?.name ?? "")
                ? Colors.blueAccent
                : Colors.transparent,
            border: Border.all(color: Colors.black45),
            borderRadius: BorderRadius.circular(30.0)),
        child: Text(
          siteName,
          style: TextStyle(
              color: siteName == (currentSite?.name ?? "")
                  ? Colors.white
                  : Colors.black,
              fontSize: 14.0,
              fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
