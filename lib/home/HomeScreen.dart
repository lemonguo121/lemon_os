import 'dart:async';

import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../category/CategoryFragment.dart';
import '../http/HttpService.dart';
import '../http/data/CategoryBean.dart';
import '../http/data/RealVideo.dart';
import '../http/data/Video.dart';
import '../search/SearchScreen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  PageController _pageController = PageController();
  TabController? _tabController;
  final HttpService _httpService = HttpService();
  List<CategoryBean> categories = [];
  int selectedCategory = 0;
  bool isLoading = false;

  // 缓存 Fragment 实例
  final Map<String, CategoryFragment> _cachedFragments = {};

  // 缓存每个分类的数据
  final Map<String, RealResponseData> _cachedData = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        isLoading = true;
      });

      Map<String, dynamic> jsonMap = await _httpService.get("");
      var responseString = ResponseData.fromJson(jsonMap);

      setState(() {
        categories = responseString.alClass;
        categories.insert(0, CategoryBean(typeId: -1, typePid: -1, typeName: "首页",categoryChildList: []));
        _initializeTabController();
      });
    } catch (e) {
      print("Error: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _initializeTabController() {
    _tabController?.dispose();
    _tabController = TabController(length: categories.length, vsync: this);
  }

  // 获取或创建 CategoryFragment
  Widget _getCategoryFragment(CategoryBean alClass) {
    // 如果缓存中有对应的 Fragment，直接返回
    if (_cachedFragments.containsKey(alClass.typeName)) {
      return _cachedFragments[alClass.typeName]!;
    }

    // 否则创建新实例并存入缓存
    final fragment = CategoryFragment(
      alClass: alClass,
      cachedData: _cachedData[alClass.typeName],
      onDataLoaded: (data) {
        // 当数据加载完成后，更新缓存
        _cachedData[alClass.typeName] = data;
      },
    );
    _cachedFragments[alClass.typeName] = fragment;
    return fragment;
  }

  @override
  void dispose() {
    _pageController.dispose();
    _tabController?.dispose();
    super.dispose();
  }

  Widget _buildCategorySelector() {
    return Column(
      children: [
        TabBar(
          padding: EdgeInsets.zero,
          controller: _tabController,
          isScrollable: true,
          tabs:
              categories.map((alClass) => Tab(text: alClass.typeName)).toList(),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: categories
                .map((alClass) => _getCategoryFragment(alClass))
                .toList(),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (categories.isEmpty) {
      return const Center(
        child: Text('暂无数据'),
      );
    }

    return Scaffold(
      body: Column(
        children: [
          const SizedBox(height: 50.0),
          _buildSearch(),
          // const SizedBox(height: 12.0),
          // _buildBanner(),
          const SizedBox(height: 8),
          Expanded(child: _buildCategorySelector()),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    return Row(
      children: [
        const SizedBox(width: 12.0),
        Expanded(
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SearchScreen()),
              );
            },
            child: Container(
              height: 40,
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
                  Text(
                    "输入搜索内容",
                    style: TextStyle(fontSize: 16.0, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12.0),
      ],
    );
  }

  Widget _buildBanner() {
    return Stack(
      children: [
        Container(
          height: 200,
          child: PageView(
            controller: _pageController,
            children: [
              Image.network(
                'https://img.btstu.cn/api/images/5e6b56d608fb6.jpg',
                fit: BoxFit.cover,
              ),
              Image.network(
                'https://img.btstu.cn/api/images/5a7017f071b4f.jpg',
                fit: BoxFit.cover,
              ),
              Image.network(
                'https://img.btstu.cn/api/images/5a0a500eeb71e.jpg',
                fit: BoxFit.cover,
              ),
            ],
          ),
        ),
        Positioned(
          bottom: 10,
          left: 0,
          right: 0,
          child: Center(
            child: SmoothPageIndicator(
              controller: _pageController,
              count: 3,
              effect: WormEffect(
                dotHeight: 12,
                dotWidth: 12,
                activeDotColor: Colors.white,
                dotColor: Colors.grey,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
