import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lemon_tv/util/SubscriptionsUtil.dart';
import 'package:xml/xml.dart';

import '../util/ThemeController.dart';
import 'HomeCateforyListItem.dart';
import '../http/HttpService.dart';
import '../http/data/CategoryBean.dart';
import '../http/data/HomeCateforyData.dart';
import '../http/data/RealVideo.dart';
import '../http/data/Video.dart';
import '../mywidget/MyEmptyDataView.dart';
import '../mywidget/MyLoadingIndicator.dart';
import '../util/SPManager.dart';

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
  final ThemeController themeController = Get.find();

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
      var currentSite = await SPManager.getCurrentSite();
      if (currentSite == null) {
        return;
      }
      var paresType = currentSite.type ?? 1;
      var responseString;
      if (paresType == 1) {
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
      if (paresType == 1) {
        Map<String, dynamic> newJsonMap = await _httpService.get(
          "",
          params: {"ac": "detail", "ids": idsString},
        );
        newData = RealResponseData.fromJson(newJsonMap, currentSite);
      } else {
        XmlDocument xmlDoc = await _httpService.get(
          "",
          params: {"ac": "videolist", "ids": idsString},
        );

        newData = RealResponseData.fromXml(xmlDoc, currentSite);
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
        Column(
          children: [
            MyLoadingIndicator(isLoading: isLoading && homeCategoryList.isEmpty)
          ],
        )
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
    return Obx((){
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 12,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
            child: Text(
              _getTypeContent(typePid),
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: themeController.currentAppTheme.titleColr),
            ),
          ),
          Container(
            margin: EdgeInsets.only(
              top: 8.0,
              left: 8.0,
            ),
            padding: const EdgeInsets.only(top: 10.0),
            width: double.infinity,
            decoration: BoxDecoration(
              // color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12), // 圆角半径
            ),
            child: IntrinsicHeight(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(left: 8.0),
                scrollDirection: Axis.horizontal,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: videos
                      .map((video) => SizedBox(
                    child: Homecateforylistitem(realVideo: video.video),
                  ))
                      .toList(),
                ),
              ),
            ),
          ),
        ],
      );
    });

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
