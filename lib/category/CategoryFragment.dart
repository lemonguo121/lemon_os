import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lemon_os/http/data/CategoryBean.dart';

import '../home/HomeListItem.dart';
import '../http/HttpService.dart';
import '../http/data/CategoryChildBean.dart';
import '../http/data/RealVideo.dart';
import '../util/SPManager.dart';

class CategoryFragment extends StatefulWidget {
  final CategoryBean alClass;
  final RealResponseData? cachedData; // 缓存数据
  final Function(RealResponseData)? onDataLoaded; // 数据加载完成回调

  const CategoryFragment({
    super.key,
    required this.alClass,
    this.cachedData,
    this.onDataLoaded,
  });

  @override
  _CategoryState createState() => _CategoryState();
}

class _CategoryState extends State<CategoryFragment>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();
  final PageStorageKey _pageStorageKey =
      PageStorageKey('CategoryFragment_${UniqueKey()}'); // 唯一标识
  @override
  bool get wantKeepAlive => true; // 保持页面状态
  final HttpService _httpService = HttpService();
  RealResponseData responseData = RealResponseData(
    code: 0,
    msg: '',
    videos: [],
  );
  bool isLoading = false;
  bool hasMore = true;
  int currentPage = 1;
  int selectedCategoryPosition = 0; // 默认没有选中的分类
  @override
  void initState() {
    super.initState();

    // 如果有缓存数据，直接使用
    if (widget.cachedData != null) {
      responseData = widget.cachedData!;
    } else {
      _getData();
    }

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 100 &&
          !isLoading &&
          hasMore) {
        _getData();
      }
    });
  }

  Future<void> _refreshData() async {
    setState(() {
      responseData.videos.clear();
      currentPage = 1;
      hasMore = true;
    });
    await _getData();
  }

  Future<void> _getData() async {
    try {
      if (isLoading) return;
      setState(() {
        isLoading = true;
      });

      Map<String, dynamic> newJsonMap;
      var typeId = "";
      if (widget.alClass.categoryChildList.isNotEmpty) {
         typeId = widget
            .alClass.categoryChildList[selectedCategoryPosition].typeId
            .toString();
      } else {
        typeId = widget
            .alClass.typeId.toString();
      }

      print("typeId = $typeId");
      newJsonMap = await _httpService.get(
        "",
        params: {
          "ac": "detail",
          "t": typeId,
          "pg": currentPage.toString(),
          "f": ""
        },
      );
      var subscriptionDomain =  '';
      var _currentSubscription  = await SPManager.getCurrentSubscription();
      if (_currentSubscription!=null) {
        subscriptionDomain = _currentSubscription['domain']??"";
      }

      final newData = RealResponseData.fromJson(newJsonMap,subscriptionDomain);
      setState(() {
        if (newData.videos.isEmpty) {
          hasMore = false;
        } else {
          responseData.videos.addAll(newData.videos);
          currentPage++;
        }
      });

      // 通知父组件数据已加载
      if (widget.onDataLoaded != null) {
        widget.onDataLoaded!(responseData);
      }
    } catch (e) {
      print("Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('加载失败，请重试')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          //二级分类
          // SizedBox(
          //   height: 6,
          // ),
          _buildSecendCategory(),
          // 视频列表
          _buildListView(),
        ],
      ),
    );
  }

  Widget _buildListView() {
    if (responseData.videos.isEmpty && !isLoading) {
      return Expanded(child: _buildPlaceholder());
    }

    return Expanded(
      child: RefreshIndicator(
        onRefresh: _refreshData,
        child: ListView.builder(
          key: _pageStorageKey,
          // 使用 PageStorageKey
          padding: EdgeInsets.zero,
          controller: _scrollController,
          itemCount: responseData.videos.length + 1,
          itemBuilder: (context, index) {
            if (index < responseData.videos.length) {
              return HomeListItem(video: responseData.videos[index]);
            } else {
              return _buildLoadingIndicator();
            }
          },
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.videocam_off, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            '暂无视频内容',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    if (!isLoading) return const SizedBox.shrink();
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16.0),
      child: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildSecendCategory() {
    // 获取二级分类列表
    List<CategoryChildBean> subCategories = widget.alClass.categoryChildList;

    if (subCategories.isEmpty) {
      return SizedBox.shrink(); // 如果没有二级分类，返回空视图
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.0),
      height: ((subCategories.length / 5).ceil() * 35).toDouble(), // 动态高度
      child: GridView.builder(
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        // 禁止网格单独滚动
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5, // 每行显示5个标签
          mainAxisSpacing: 5.0, // 垂直间距
          crossAxisSpacing: 5.0, // 水平间距
          mainAxisExtent: 30, // 🔥 固定子项高度为50
        ),
        itemCount: subCategories.length,
        itemBuilder: (context, index) {
          CategoryChildBean category = subCategories[index];
          bool isSelected = selectedCategoryPosition == index;

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              setState(() {
                selectedCategoryPosition = index;
                responseData.videos.clear();
                currentPage = 1;
                hasMore = true;
                widget.alClass.typeId = category.typeId;
              });
              _getData();
            },
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? Colors.blueAccent : Colors.grey[300],
                borderRadius: BorderRadius.circular(6.0),
                border: Border.all(
                  color: isSelected ? Colors.blue : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Text(
                category.typeName,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black,
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
