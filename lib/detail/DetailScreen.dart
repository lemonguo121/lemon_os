import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../http/HttpService.dart';
import '../http/data/RealVideo.dart';
import '../player/SPManager.dart';
import '../player/VideoPlayerScreen.dart';
import '../util/CommonUtil.dart';
import 'CollapsibleText.dart';

class DetailScreen extends StatefulWidget {
  final int vodId;

  const DetailScreen({required this.vodId});

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
      Map<String, dynamic> jsonMap = await _httpService.get(
        "",
        params: {
          "ac": "detail",
          "ids": widget.vodId.toString(), // 使用传递的 vodId
        },
      );
      setState(() {
        responseData = RealResponseData.fromJson(jsonMap); // 更新状态
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
      final double screenWidth = MediaQuery.of(context).size.width;
      final double itemHeight = (screenWidth - 24) / 3 / 3.5;
      // 每行的条目数
      const int itemsPerRow = 3;
      // 计算需要滚动的位置
      final double scrollPosition = (index ~/ itemsPerRow) * itemHeight;

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
          ? const Center(child: CircularProgressIndicator()) // 加载中显示
          : (video == null || responseData.videos.isEmpty)
          ? const Center(child: Text("无法加载详情")) // 数据加载失败显示
          : _buildCustomScrollView(),
    );
  }

  Widget _buildCustomScrollView() {
    return Column(
      children: [
        // 播放器部分，固定在顶部
        SizedBox(
          height: _isFullScreen
              ? MediaQuery.of(context).size.height
              : 300, // 非全屏时固定高度
          child: VideoPlayerScreen(
            initialIndex: _selectedIndex,
            videoTitle: video.vodName,
            video: video,
            onFullScreenChanged: _onFullScreenChanged,
            onChangePlayPositon: _onChangePlayPositon,
            videoPlayerHeight:
            _isFullScreen ? MediaQuery.of(context).size.height : 300,
          ),
        ),

        // 视频信息和播放列表部分，使用 CustomScrollView 滑动
        Expanded(child: _buildVideoInfo()),
      ],
    );
  }

  Widget _buildVideoInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8.0),
        // 视频简介
        _buildVideoDetial(),
        const SizedBox(height: 8.0),
        // 播放列表网格
        _buildGrid(), // 调用修改后的播放列表网格
        const SizedBox(height: 16.0),
      ],
    );
  }

  Widget _buildVideoDetial() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "简介",
            style: TextStyle(
              fontSize: 14.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4.0),
          CollapsibleText(
            text: video.vodBlurb,
            style: const TextStyle(fontSize: 12.0),
          ),
          const SizedBox(height: 6.0),
          const Text(
            "备注",
            style: TextStyle(
              fontSize: 14.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            video.vodRemarks,
            style: const TextStyle(
              fontSize: 12.0,
              color: Colors.grey,
            ),
          ),
          const SizedBox(
            height: 4.0,
          ),
          const Text(
            "选集",
            style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    return Expanded(
      child: GridView.builder(
        padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 12.0),
        controller: _scrollController,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3, // 每行显示 3 个
          mainAxisSpacing: 8.0,
          crossAxisSpacing: 8.0,
          childAspectRatio: 3.5, // 宽高比例
        ),
        itemCount: CommonUtil.getPlayList(video).length,
        itemBuilder: (context, index) {
          return _buildGridItem(index);
        },
      ),
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