import 'dart:ui';

import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lemon_tv/home/VideoInfoWidget.dart';
import 'package:xml/xml.dart';

import '../http/HttpService.dart';
import '../http/data/RealVideo.dart';
import '../http/data/storehouse_bean_entity.dart';
import '../mywidget/MyLoadingIndicator.dart';
import '../player/VideoPlayerScreen.dart';
import '../util/CommonUtil.dart';
import '../util/SPManager.dart';

class DetailScreen extends StatefulWidget {
  final int vodId;
  final StorehouseBeanSites site;

  const DetailScreen({super.key, required this.vodId, required this.site});

  @override
  _DetailScreenState createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  final HttpService _httpService = HttpService();
  late RealVideo video; // 存储详情数据
  RealResponseData responseData = RealResponseData(
    code: 0,
    msg: '',
    videos: [],
  );
  bool isLoading = true; // 用于显示加载状态
  int _selectedIndex = 0; // 用于跟踪当前选中的播放项
  bool _isFullScreen = false; // 存储全屏状态
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchDetail().then((value) => _loadProgress()); // 请求详情数据
  }

  // 异步加载视频进度
  Future<void> _loadProgress() async {
    int? progress = await SPManager.getIndex(widget.vodId);
    if (progress != null) {
      setState(() {
        _selectedIndex = progress;
      });
      _scrollToSelectedItem(progress);
    }
  }

  Future<void> _fetchDetail() async {
    try {
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
        SPManager.saveHistory(video);
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
    setState(() {
      _isFullScreen = isFullScreen; // 更新全屏状态
    });
    if (_isFullScreen) {
      // 全屏时隐藏状态栏和禁用滚动
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    } else {
      // 退出全屏时恢复状态栏和启用滚动
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  void _onChangePlayPositon(int currentPosition) {
    setState(() {
      _selectedIndex = currentPosition;
    });
    _scrollToSelectedItem(currentPosition);
  }

  void _changePlayPosition(int index) {
    _onChangePlayPositon(index);
    final videoId = widget.vodId;
    final playItem = CommonUtil.getPlayList(video)[index];
    SPManager.saveIndex(videoId, index);
    SPManager.saveHistory(video);
    VideoPlayerScreen.of(context)?.playVideo(playItem['url']!, _selectedIndex);
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
    var vodPic = video.vodPic;

    return Scaffold(
      body: isLoading
          ? Column(
              children: [MyLoadingIndicator(isLoading: isLoading)]) // 加载中显示
          : (responseData.videos.isEmpty)
              ? const Center(child: Text("无法加载详情")) // 数据加载失败显示
              : Stack(
                  children: [
                    Positioned.fill(
                      child: Image.network(
                        vodPic,
                        fit: BoxFit.cover, // 背景图片覆盖整个屏幕
                      ),
                    ),
                    Positioned.fill(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(
                            sigmaX: 50.0, sigmaY: 50.0), // 设置模糊程度
                        child: Container(
                          color: Colors.black.withOpacity(0), // 可以设置背景的透明度
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
              ),
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
                style: TextStyle(color: Colors.white),
              ),
              expanded: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(video.vodBlurb),
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
                  )
                ],
              )),
          const SizedBox(height: 6.0),
          const Text(
            "更新",
            style: TextStyle(
              fontSize: 14.0,
              fontWeight: FontWeight.bold,
                color: Colors.white
            ),
          ),
          Text(
            video.vodRemarks.isNotEmpty ? video.vodRemarks : "暂无更新",
            style: const TextStyle(
              fontSize: 12.0,
                color: Colors.white
            ),
          ),
          const SizedBox(
            height: 4.0,
          ),
          const Text(
            "选集",
            style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold,color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 12.0),
      controller: _scrollController,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, // 每行显示 3 个
        mainAxisSpacing: 8.0,
        crossAxisSpacing: 8.0,
        mainAxisExtent: 30,
      ),
      itemCount: CommonUtil.getPlayList(video).length,
      itemBuilder: (context, index) {
        return _buildGridItem(index);
      },
    );
  }

  Widget _buildGridItem(int index) {
    final playItem = CommonUtil.getPlayList(video)[index];
    final title = playItem['title']!; // 播放标题
    return GestureDetector(
      onTap: () {
        _changePlayPosition(index);
      },
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _selectedIndex == index
              ? Colors.blueAccent // 选中时改变背景色
              : Colors.transparent, // 未选中时背景透明
          border: Border.all(
            color: Colors.blueAccent,
            width: _selectedIndex == index ? 0 : 1,
          ),
          borderRadius: BorderRadius.circular(3.0), // 圆角边框
        ),
        child: Text(
          title,
          style: TextStyle(
            color: _selectedIndex == index
                ? Colors.white // 选中时字体颜色
                : Colors.blueAccent,
            fontSize: 10.0,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis, // 超出显示省略号
        ),
      ),
    );
  }
}
