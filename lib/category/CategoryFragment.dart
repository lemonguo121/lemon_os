import 'dart:async';

import 'package:flutter/material.dart';

import '../home/HomeListItem.dart';
import '../http/HttpService.dart';
import '../http/data/AlClass.dart';
import '../http/data/RealVideo.dart';
import '../http/data/Video.dart';

class CategoryFragment extends StatefulWidget {
  final AlClass alClass;
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
      if (widget.alClass.typePid == -1 && widget.alClass.typeId == -1) {
        Map<String, dynamic> jsonMap = await _httpService.get("");
        var responseString = ResponseData.fromJson(jsonMap);
        List<int> ids = responseString.videos.map((e) => e.vodId).toList();
        String idsString = ids.join(',');
        newJsonMap = await _httpService.get(
          "",
          params: {"ac": "detail", "ids": idsString},
        );
      } else {
        newJsonMap = await _httpService.get(
          "",
          params: {
            "ac": "detail",
            "t": widget.alClass.typeId.toString(),
            "pg": currentPage.toString(),
            "f": ""
          },
        );
      }

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
}
