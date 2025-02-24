import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lemen_os/http/data/CategoryBean.dart';

import '../home/HomeListItem.dart';
import '../http/HttpService.dart';
import '../http/data/AlClass.dart';
import '../http/data/CategoryChildBean.dart';
import '../http/data/RealVideo.dart';
import '../http/data/Video.dart';

class CategoryFragment extends StatefulWidget {
  final CategoryBean alClass;
  final RealResponseData? cachedData; // 缓存数据
  final Function(RealResponseData)? onDataLoaded; // 数据加载完成回调

  const CategoryFragment({
    required this.alClass,
    this.cachedData,
    this.onDataLoaded,
  });

  @override
  _CategoryState createState() => _CategoryState();
}

class _CategoryState extends State<CategoryFragment>
    with AutomaticKeepAliveClientMixin {
  ScrollController _scrollController = ScrollController();
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

        var typeId = widget.alClass.categoryChildList[selectedCategoryPosition].typeId.toString();
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

      final newData = RealResponseData.fromJson(newJsonMap);
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
    return Scaffold(
      body: Column(
        children: [
          //二级分类
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
      padding: EdgeInsets.symmetric(vertical: 4.0, horizontal: 4.0),
      child: Wrap(
        spacing: 6.0, // 子元素间的水平间距
        runSpacing: 8.0, // 子元素间的垂直间距
        children: List.generate(subCategories.length, (index) {
          CategoryChildBean category = subCategories[index];
          bool isSelected = selectedCategoryPosition == index; // 是否被选中

          return GestureDetector(
            onTap: () {
              setState(() {
                selectedCategoryPosition = index; // 更新选中状态
                responseData.videos.clear();
                currentPage = 1;
                hasMore = true;
                widget.alClass.typeId = category.typeId; // 切换到点击的子分类
              });
              _getData(); // 重新加载数据
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 5.0, vertical: 1.0),
              decoration: BoxDecoration(
                color: isSelected ? Colors.blueAccent : Colors.grey[300],
                // 选中时变蓝色，未选中灰色
                borderRadius: BorderRadius.circular(20.0),
                border: Border.all(
                  color: isSelected ? Colors.blue : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Text(
                category.typeName,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black, // 选中白字，未选中黑字
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
