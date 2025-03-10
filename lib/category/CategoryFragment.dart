import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lemon_os/http/data/CategoryBean.dart';
import 'package:lemon_os/mywidget/MyEmptyDataView.dart';
import 'package:lemon_os/mywidget/MyLoadingIndicator.dart';
import 'package:lemon_os/util/CommonUtil.dart';
import 'package:xml/xml.dart';

import '../home/HomeListItem.dart';
import '../http/HttpService.dart';
import '../http/data/CategoryChildBean.dart';
import '../http/data/RealVideo.dart';
import '../util/SPManager.dart';
import 'CategoryListItem.dart';

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
  bool isLoading = true;
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
        currentPage++;
        _getData();
      }
    });
  }

  Future<void> _refreshData() async {
    setState(() {
      currentPage = 1;
      hasMore = true;
      // isLoading = true;
    });
    await _getData();
  }

  Future<void> _getData() async {
    try {
      var _currentSubscription = await SPManager.getCurrentSubscription();
      if (_currentSubscription == null) {
        return;
      }
      var paresType = _currentSubscription['paresType'] ?? "1";

      var typeId = "";
      if (widget.alClass.categoryChildList.isNotEmpty) {
        typeId = widget
            .alClass.categoryChildList[selectedCategoryPosition].typeId
            .toString();
      } else {
        typeId = widget.alClass.typeId.toString();
      }
      var newData;
      if (paresType == "1") {
        Map<String, dynamic> newJsonMap = await _httpService.get(
          "",
          params: {
            "ac": "detail",
            "t": typeId,
            "pg": currentPage.toString(),
            "f": ""
          },
        );
        newData = RealResponseData.fromJson(newJsonMap, _currentSubscription);
      } else {
        XmlDocument newJsonMap = await _httpService.get(
          "",
          params: {
            "ac": "videolist",
            "t": typeId,
            "pg": currentPage.toString(),
            "f": ""
          },
        );
        newData = RealResponseData.fromXml(newJsonMap, _currentSubscription);
      }

      setState(() {
        hasMore = newData.videos.isNotEmpty;
        if (currentPage == 1) {
          responseData.videos.clear();
          responseData.videos.addAll(newData.videos);
        } else {
          responseData.videos.addAll(newData.videos);
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
    var isVertical = CommonUtil.isVertical(context);
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
          _buildListView(isVertical),
        ],
      ),
    );
  }

  Widget _buildListView(bool isVertical) {
    if (responseData.videos.isEmpty && !isLoading) {
      return Expanded(child: MyEmptyDataView(retry: _refreshData));
    }

    return isLoading
        ? MyLoadingIndicator(
            isLoading: isLoading && responseData.videos.isEmpty)
        : Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshData,
              child: GridView.builder(
                padding: const EdgeInsets.all(8.0),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isVertical ? 2 : 4, //
                  crossAxisSpacing: 8.0, // 水平方向间距
                  mainAxisSpacing: 8.0, // 垂直方向间距
                  childAspectRatio: 1.3, // 调整宽高比
                ),
                key: _pageStorageKey,
                // 使用 PageStorageKey
                controller: _scrollController,
                itemCount: responseData.videos.length,
                itemBuilder: (context, index) {
                  return CategoryListItem(
                      realVideo: responseData.videos[
                          index]);
                },
              ),
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
      height: ((subCategories.length / 5).ceil() * 30).toDouble(), // 动态高度
      child: GridView.builder(
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        // 禁止网格单独滚动
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5, // 每行显示5个标签
          mainAxisSpacing: 5.0, // 垂直间距
          crossAxisSpacing: 5.0, // 水平间距
          mainAxisExtent: 25, // 🔥 固定子项高度为50
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
