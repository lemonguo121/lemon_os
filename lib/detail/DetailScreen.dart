import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:lemon_tv/home/VideoInfoWidget.dart';
import 'package:xml/xml.dart';

import '../http/HttpService.dart';
import '../http/data/RealVideo.dart';
import '../http/data/storehouse_bean_entity.dart';
import '../mywidget/MyLoadingIndicator.dart';
import '../player/VideoPlayerScreen.dart';
import '../util/CommonUtil.dart';
import '../history/HistoryController.dart';
import '../util/SPManager.dart';

class DetailScreen extends StatefulWidget {
  final int vodId;
  final StorehouseBeanSites site;

  const DetailScreen({super.key, required this.vodId, required this.site});

  @override
  _DetailScreenState createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  final HistoryController historyController =
      Get.put(HistoryController()); // 依赖注入
  final HttpService _httpService = HttpService();
  late RealVideo video; // 存储详情数据
  RealResponseData responseData = RealResponseData(
    code: 0,
    msg: '',
    videos: [],
  );
  bool isLoading = true; // 用于显示加载状态
  int _selectedIndex = 0; // 用于跟踪当前选中的播放项
  int _selectedPlayFromIndex = 0; // 用于跟踪当前选中播放的播放源
  bool _isFullScreen = false; // 存储全屏状态
  final ScrollController _scrollController = ScrollController();
  int _selectFromIndex = 0; // 用于跟踪当前选中查看的播放源

  @override
  void initState() {
    super.initState();
    _fetchDetail(); // 请求详情数据
  }

  // 异步加载视频进度
  Future<void> _loadProgress() async {
    int? progress = await SPManager.getIndex("${widget.vodId}") ?? 0;
    int? fromIndex = await SPManager.getFromIndex("${widget.vodId}") ?? 0;
    setState(() {
      _selectedIndex = progress;
      _selectedPlayFromIndex = fromIndex;
      _selectFromIndex = fromIndex;
    });
  }

  Future<void> _fetchDetail() async {
    try {
      await _loadProgress();
      var paresType = widget.site.type ?? 1;
      var subscription = widget.site.api ?? "";
      if (paresType == 1) {
        Map<String, dynamic> jsonMap = await _httpService.getBySubscription(
          subscription,
          paresType,
          "",
          params: {
            "ac": "detail",
            "ids": widget.vodId.toString(), // 使用传递的 vodId
          },
        );
        responseData = RealResponseData.fromJson(jsonMap, widget.site); // 更新状态
      } else {
        XmlDocument jsonMap = await _httpService.getBySubscription(
          subscription,
          paresType,
          "",
          params: {
            "ac": "videolist",
            "ids": widget.vodId.toString(), // 使用传递的 vodId
          },
        );
        responseData = RealResponseData.fromXml(jsonMap, widget.site); // 更新状态
      }
      setState(() {
        var videos = responseData.videos;
        video = videos[0];
        isLoading = false; // 数据加载完成
        _scrollToSelectedItem(_selectedIndex);
        historyController.saveHistory(video);

      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print("Error fetching detail: $e");
    }
  }

  @override
  void dispose() {
    // 在离开页面时恢复状态栏和导航栏
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _scrollController.dispose();
    VideoPlayerScreen.of(context)?.dispose();
    super.dispose();
  }

  // 处理全屏状态回调
  void _onFullScreenChanged(bool isFullScreen) {
    _isFullScreen = isFullScreen; // 更新全屏状态
    if (_isFullScreen) {
      // 全屏时隐藏状态栏和禁用滚动
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    } else {
      // 退出全屏时恢复状态栏和启用滚动
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    setState(() {});
  }

  void _onChangePlayPositon(int currentPosition) {
    historyController.saveHistory(video);
    setState(() {
      _selectedIndex = currentPosition;
      _selectedPlayFromIndex = _selectFromIndex;
    });
    _scrollToSelectedItem(currentPosition);
  }

  void _changePlayPosition(int index) async {
    if (index == _selectedIndex && _selectedPlayFromIndex == _selectFromIndex) {
      return;
    }
    _onChangePlayPositon(index);
    final playItem = CommonUtil.getPlayListAndForm(video)
        .playList[_selectedPlayFromIndex][index];
   await historyController.saveIndex(video, index,_selectedPlayFromIndex);
    VideoPlayerScreen.of(context)
        ?.playVideo(playItem["url"] ?? "", _selectedIndex);
  }

  void changeFromPosition(int index) {
    setState(() {
      _selectFromIndex = index;
    });
  }

  void _scrollToSelectedItem(int index) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 根据屏幕宽度和网格配置计算条目高度
      final double itemHeight = 38;
      // 每行的条目数
      const int itemsPerRow = 3;
      // 计算需要滚动的位置
      final double scrollPosition = (index ~/ itemsPerRow) * itemHeight;
      print("scrollPosition = $scrollPosition");
      // 滚动至计算的位置
      _scrollController.animateTo(
        scrollPosition,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? Column(
              children: [MyLoadingIndicator(isLoading: isLoading)]) // 加载中显示
          : (responseData.videos.isEmpty)
              ? const Center(child: Text("无法加载详情")) // 数据加载失败显示
              : Stack(
                  children: [
                    Positioned.fill(
                      child: CachedNetworkImage(
                        imageUrl: video.vodPic,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned.fill(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(
                            sigmaX: 40.0, sigmaY: 40.0), // 设置模糊程度
                        child: Container(
                          color: Colors.black.withOpacity(0.2), // 可以设置背景的透明度
                        ),
                      ),
                    ),
                    _buildCustomScrollView(), // 将页面内容放置在背景之上
                  ],
                ),
    );
  }

  Widget _buildCustomScrollView() {
    var isVertical = CommonUtil.isVertical(context);
    return isVertical || _isFullScreen
        ? _buildVerContent()
        : _buildHorContent();
  }

  Widget _buildVerContent() {
    var playerHeight = MediaQuery.of(context).size.height / 9 * 4;
    return Column(
      children: [
        // 播放器部分，固定在顶部
        SizedBox(
          height: _isFullScreen
              ? MediaQuery.of(context).size.height
              : playerHeight, // 非全屏时固定高度
          child: VideoPlayerScreen(
            initialIndex: _selectedIndex,
            fromIndex: _selectedPlayFromIndex,
            video: video,
            onFullScreenChanged: _onFullScreenChanged,
            onChangePlayPositon: _onChangePlayPositon,
            videoPlayerHeight: _isFullScreen
                ? MediaQuery.of(context).size.height
                : playerHeight,
          ),
        ),

        // 视频信息和播放列表部分，使用 CustomScrollView 滑动
        Expanded(child: _buildVideoInfo(true)),
      ],
    );
  }

  Widget _buildHorContent() {
    double screenWidth = CommonUtil.getScreenWidth(context);
    double screenHeight = CommonUtil.getScreenHeight(context);
    var playerWidth = screenWidth / 3 * 2;
    var playerHeight = playerWidth / 16 * 9;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 播放器部分，固定在顶部
        SizedBox(
          width: playerWidth,
          height: _isFullScreen
              ? MediaQuery.of(context).size.height
              : screenHeight, // 非全屏时固定高度
          child: VideoPlayerScreen(
            initialIndex: _selectedIndex,
            fromIndex: _selectedPlayFromIndex,
            video: video,
            onFullScreenChanged: _onFullScreenChanged,
            onChangePlayPositon: _onChangePlayPositon,
            videoPlayerHeight: _isFullScreen
                ? MediaQuery.of(context).size.height
                : playerHeight,
          ),
        ),

        // 视频信息和播放列表部分，使用 CustomScrollView 滑动
        Expanded(child: _buildVideoInfo(false)),
      ],
    );
  }

  Widget _buildVideoInfo(bool isVertical) {
    return SingleChildScrollView(
      controller: _scrollController,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: isVertical ? 10.0 : 50.0),
          // 视频简介
          _buildVideoDetial(),
          const SizedBox(height: 8.0),
          // 播放列表网格
          _buildGrid(), // 调用修改后的播放列表网格
          const SizedBox(height: 16.0),
        ],
      ),
    );
  }

  Widget _buildVideoDetial() {
    var videoPlayData = CommonUtil.getPlayListAndForm(video);
    var fromList = videoPlayData.fromList;
    var playList = videoPlayData.playList;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4.0),
          ExpandablePanel(
              theme: ExpandableThemeData(
                  headerAlignment: ExpandablePanelHeaderAlignment.center,
                  iconPadding: EdgeInsets.zero,
                  iconColor: Colors.white),
              header: Text("简介",
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              collapsed: Text(
                video.vodBlurb,
                softWrap: true,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
              expanded: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video.vodBlurb,
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  const SizedBox(height: 6.0),
                  Videoinfowidget(title: "导演", content: video.vodDirector),
                  const SizedBox(
                    height: 6.0,
                  ),
                  Videoinfowidget(title: "主演", content: video.vodActor),
                  const SizedBox(height: 6.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Videoinfowidget(title: "年份", content: video.vodYear),
                      const SizedBox(width: 6.0),
                      Videoinfowidget(title: "地区", content: video.vodArea),
                      const SizedBox(width: 6.0),
                      Videoinfowidget(title: "类型", content: video.typeName),
                    ],
                  ),
                  const SizedBox(height: 6.0),
                  Videoinfowidget(
                      title: "播放地址（长按链接复制）",
                      content: playList[_selectedPlayFromIndex][_selectedIndex]
                              ['url'] ??
                          ""),
                ],
              )),
          const SizedBox(height: 6.0),
          const Text(
            "更新",
            style: TextStyle(
                fontSize: 14.0,
                fontWeight: FontWeight.bold,
                color: Colors.white),
          ),
          Text(
            video.vodRemarks.isNotEmpty ? video.vodRemarks : "暂无更新",
            style: const TextStyle(fontSize: 12.0, color: Colors.white),
          ),
          const SizedBox(
            height: 6.0,
          ),
          const Text(
            "线路",
            style: TextStyle(
                fontSize: 14.0,
                fontWeight: FontWeight.bold,
                color: Colors.white),
          ),
          const SizedBox(
            height: 4.0,
          ),
          SizedBox(
            height: 20,
            child: _buildVodFromList(fromList),
          ),
          const SizedBox(
            height: 4.0,
          ),
          const Text(
            "选集",
            style: TextStyle(
                fontSize: 14.0,
                fontWeight: FontWeight.bold,
                color: Colors.white),
          ),
          const SizedBox(
            height: 4.0,
          ),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    var playList = CommonUtil.getPlayListAndForm(video).playList;
    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 12.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, // 每行显示 3 个
        mainAxisSpacing: 8.0,
        crossAxisSpacing: 8.0,
        mainAxisExtent: 30,
      ),
      itemCount: CommonUtil.getPlayListAndForm(video)
          .playList[_selectedPlayFromIndex]
          .length,
      itemBuilder: (context, index) {
        return _buildGridItem(index, playList);
      },
    );
  }

  Widget _buildGridItem(int index, List<List<Map<String, String>>> playList) {
    final playItem = playList[_selectFromIndex][index];
    final title = playItem['title']!; // 播放标题
    return GestureDetector(
      onTap: () {
        _changePlayPosition(index);
      },
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _selectedIndex == index &&
                  _selectedPlayFromIndex == _selectFromIndex
              ? Colors.blueAccent // 选中时改变背景色
              : Colors.transparent, // 未选中时背景透明
          border: Border.all(
            color: Colors.white,
            width: _selectedIndex == index &&
                    _selectedPlayFromIndex == _selectFromIndex
                ? 0
                : 1,
          ),
          borderRadius: BorderRadius.circular(3.0), // 圆角边框
        ),
        child: Text(
          title,
          style: TextStyle(
            color: _selectedIndex == index &&
                    _selectedPlayFromIndex == _selectFromIndex
                ? Colors.white // 选中时字体颜色
                : Colors.white,
            fontSize: 10.0,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis, // 超出显示省略号
        ),
      ),
    );
  }

  Widget _buildVodFromList(List<String> fromList) {
    return ListView.builder(
        shrinkWrap: true,
        scrollDirection: Axis.horizontal,
        itemCount: fromList.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              changeFromPosition(index);
            },
            child: Container(
              padding: EdgeInsets.only(right: 15),
              child: Text(
                fromList[index],
                style: TextStyle(
                    color:
                        _selectFromIndex == index ? Colors.blue : Colors.white,
                    fontSize: 13,
                    fontWeight: _selectFromIndex == index
                        ? FontWeight.bold
                        : FontWeight.normal),
              ),
            ),
          );
        });
  }
}
