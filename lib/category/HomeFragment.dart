import 'package:flutter/material.dart';
import 'package:lemon_os/http/data/HomeCateforyData.dart';
import 'package:lemon_os/http/data/Video.dart';
import 'package:lemon_os/util/SPManager.dart';

import '../home/HomeCateforyListItem.dart';
import '../http/HttpService.dart';
import '../http/data/CategoryBean.dart';
import '../http/data/RealVideo.dart';

class HomeFragment extends StatefulWidget {
  final CategoryBean alClass;
  final Map<int, List<HomeCategoryData>>? cachedData;
  final List<CategoryBean>? categories;
  final Function(Map<int, List<HomeCategoryData>> homeCategoryList)?
      onDataLoaded;

  const HomeFragment({
    super.key,
    required this.alClass,
    this.cachedData,
    this.categories,
    this.onDataLoaded,
  });

  @override
  State<HomeFragment> createState() => _HomeFragmentState();
}

class _HomeFragmentState extends State<HomeFragment>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();
  final HttpService _httpService = HttpService();
  final PageStorageKey _pageStorageKey =
      PageStorageKey('CategoryFragment_${UniqueKey()}');

  @override
  bool get wantKeepAlive => true;

  Map<int, List<HomeCategoryData>> homeCategoryList = {};
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.cachedData != null) {
      homeCategoryList = widget.cachedData!;
    } else {
      _getData();
    }
    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    if (_scrollController.position.pixels < 50 && !isLoading) {
      _getData();
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      // homeCategoryList.clear();
    });
    await _getData();
  }

  Future<void> _getData() async {
    try {
      if (isLoading) return;
      setState(() => isLoading = true);

      Map<String, dynamic> jsonMap = await _httpService.get("");
      var responseString = ResponseData.fromJson(jsonMap);
      List<int> ids = responseString.videos.map((e) => e.vodId).toList();
      String idsString = ids.join(',');

      Map<String, dynamic> newJsonMap = await _httpService.get(
        "",
        params: {"ac": "detail", "ids": idsString},
      );
      homeCategoryList.clear();
      var subscriptionDomain = '';
      var _currentSubscription = await SPManager.getCurrentSubscription();
      if (_currentSubscription != null) {
        subscriptionDomain = _currentSubscription['domain'] ?? "";
      }

      final newData = RealResponseData.fromJson(newJsonMap, subscriptionDomain);
      setState(() {
        if (newData.videos.isEmpty) {
        } else {
          for (var realVideo in newData.videos) {
            var typePid = realVideo.typePid;
            var categoryData =
                HomeCategoryData(type_pid: typePid, video: realVideo);
            homeCategoryList.putIfAbsent(typePid, () => []).add(categoryData);
          }
        }
      });

      widget.onDataLoaded?.call(homeCategoryList);
    } catch (e) {
      print("Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('加载失败，请重试')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildLoadingIndicator() {
    if (!isLoading) return const SizedBox.shrink();
    return const Expanded(
        child: Center(
      child: CircularProgressIndicator(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refreshData, // 仅允许下拉刷新
        child: isLoading&& homeCategoryList.isNotEmpty
            ? _buildLoadingIndicator()
            : CustomScrollView(
                key: _pageStorageKey,
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(), // 允许下拉刷新
                slivers: [
                  SliverToBoxAdapter(
                      child: homeCategoryList.isEmpty && !isLoading
                          ? _buildPlaceholder()
                          : _buildCategoryListView()),
                ],
              ),
      ),
    );
  }

  Widget _buildRefreshWrapper() {
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: homeCategoryList.isEmpty && !isLoading
          ? _buildPlaceholder()
          : _buildCategoryListView(),
    );
  }

  Widget _buildCategoryListView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: homeCategoryList.entries.map((entry) {
        return _buildCategorySection(entry.key, entry.value);
      }).toList(),
    );
  }

  Widget _buildCategorySection(int typePid, List<HomeCategoryData> videos) {
    return Container(
        margin: EdgeInsets.only(top: 12.0, left: 16.0, right: 16.0),
        // padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12), // 圆角半径
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 10,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              child: Text(
                _getTypeContent(typePid),
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            IntrinsicHeight(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(vertical: 2, horizontal: 10),
                scrollDirection: Axis.horizontal,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: videos
                      .map((video) => SizedBox(
                            child: Homecateforylistitem(video: video.video),
                          ))
                      .toList(),
                ),
              ),
            ),
          ],
        ));
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

  String _getTypeContent(int typePid) {
    final category = widget.categories?.firstWhere(
      (category) => category.typeId == typePid,
      orElse: () => CategoryBean(
        typeId: 0,
        typePid: 0,
        typeName: '',
        categoryChildList: [],
      ),
    );
    return "热门${category?.typeName ?? ''}";
  }
}
