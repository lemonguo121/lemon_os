import 'package:flutter/material.dart';
import 'package:lemon_os/http/data/HomeCateforyData.dart';
import 'package:lemon_os/http/data/Video.dart';
import 'package:lemon_os/mywidget/MyEmptyDataView.dart';
import 'package:lemon_os/mywidget/MyLoadingIndicator.dart';
import 'package:lemon_os/util/SPManager.dart';
import 'package:xml/xml.dart';

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
  }

  Future<void> _refreshData() async {
    await _getData();
  }

  Future<void> _getData() async {
    try {
      if (isLoading) return;
      setState(() => isLoading = true);
      var _currentSubscription = await SPManager.getCurrentSubscription();
      if (_currentSubscription == null) {
        return;
      }
      var subscriptionDomain = '';
      var paresType = _currentSubscription['paresType'] ?? "1";
      subscriptionDomain = _currentSubscription['domain'] ?? "";
      var responseString;
      if (paresType == "1") {
        Map<String, dynamic> jsonMap = await _httpService.get("");
        responseString = ResponseData.fromJson(jsonMap);
      } else {
        XmlDocument xmlDoc = await _httpService.get("");
        responseString = ResponseData.fromXml(xmlDoc);
      }
      List<int> ids = (responseString.videos as List<Video>)
          .where((e) => e.vodId != null)
          .map((e) => e.vodId!)
          .toList();
      String idsString = ids.join(',');


      var newData;
      homeCategoryList.clear();
      if (paresType == "1") {
        Map<String, dynamic> newJsonMap = await _httpService.get(
          "",
          params: {"ac": "detail", "ids": idsString},
        );
        newData = RealResponseData.fromJson(newJsonMap, _currentSubscription);
      } else {
        XmlDocument xmlDoc = await _httpService.get(
          "",
          params: {"ac": "videolist", "ids": idsString},
        );

        newData = RealResponseData.fromXml(xmlDoc, _currentSubscription);
      }

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

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _refreshData, // 仅允许下拉刷新
          child: CustomScrollView(
            key: _pageStorageKey,
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(), // 允许下拉刷新
            slivers: [
              SliverToBoxAdapter(child: _buildCategoryListView()),
              // 当数据为空且不是加载状态时显示占位符
              if (homeCategoryList.isEmpty && !isLoading)
                SliverFillRemaining(
                  child: SizedBox.expand(
                    child: MyEmptyDataView(retry: _refreshData),
                  ),
                ),
            ],
          ),
        ),
        Column(children: [ MyLoadingIndicator(isLoading: isLoading && homeCategoryList.isEmpty)],)
      ],
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
