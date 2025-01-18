import 'dart:async';

import 'package:flutter/material.dart';


import '../home/HomeListItem.dart';
import '../http/HttpService.dart';
import '../http/data/AlClass.dart';
import '../http/data/RealVideo.dart';
import '../http/data/Video.dart';

class CategoryFragment extends StatefulWidget {
  final AlClass alClass;

  const CategoryFragment({required this.alClass});

  @override
  _CategoryState createState() => _CategoryState();
}

class _CategoryState extends State<CategoryFragment> {
  ScrollController _scrollController = ScrollController();
  final HttpService _httpService = HttpService();
  RealResponseData responseData = RealResponseData(
    code: 0,
    msg: '',
    videos: [],
  );
  bool isLoading = false; // 防止重复加载
  bool hasMore = true; // 判断是否还有更多数据
  int currentPage = 1;

  Future<void> _refreshData() async {
    setState(() {
      responseData.videos.clear();
    });
    await _getData();
  }

  @override
  void initState() {
    super.initState();
    _getData();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 100 &&
          !isLoading &&
          hasMore) {
        _getData(); // 加载更多数据
      }
    });
  }

  Future<void> _getData() async {
    try {
      if (isLoading) return;
      setState(() {
        isLoading = true;
      });

      Map<String, dynamic> newJsonMap;
      if (widget.alClass.typePid == -1 && widget.alClass.typeId == -1) {
        // 处理视频 ID 列表逻辑
        Map<String, dynamic> jsonMap = await _httpService.get("");
        var responseString = ResponseData.fromJson(jsonMap);
        List<int> ids = responseString.videos.map((e) => e.vodId).toList();
        String idsString = ids.join(',');
        newJsonMap = await _httpService.get(
          "",
          params: {"ac": "detail", "ids": idsString},
        );
      } else {
        // 普通分页加载逻辑
        var typeId = 0;
        typeId = widget.alClass.typeId;
        // https://json.heimuer.xyz/api.php/provide/vod/?ac=detail&t=8&pg=1&f=
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
      responseData = RealResponseData.fromJson(newJsonMap);
      setState(() {
        if (RealResponseData.fromJson(newJsonMap).videos.isEmpty) {
          hasMore = false; // 没有更多数据
        } else {
          responseData.videos.addAll(RealResponseData.fromJson(newJsonMap).videos);
          currentPage++; // 加载下一页
        }
      });
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
        child: ListView(
          padding: EdgeInsets.zero,
          controller: _scrollController,
          children: [
            ...responseData.videos.map((video) {
              return HomeListItem(video: video);
            }).toList(),
            _buildLoadingIndicator(),
          ],
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
