import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:lemon_tv/home/VideoInfoWidget.dart';
import 'package:lemon_tv/player/controller/VideoPlayerGetController.dart';
import 'package:xml/xml.dart';

import '../download/DownloadController.dart';
import '../download/DownloadItem.dart';
import '../download/showSleepWarningIfNeeded.dart';
import '../history/HistoryController.dart';
import '../http/HttpService.dart';
import '../http/data/RealVideo.dart';
import '../http/data/storehouse_bean_entity.dart';
import '../music/player/music_controller.dart';
import '../mywidget/MyLoadingIndicator.dart';

// import '../player/VideoPlayerScreen.dart';
import '../player/widget/VideoPlayerPage.dart';
import '../util/CommonUtil.dart';
import '../util/SPManager.dart';

class DetailScreen extends StatefulWidget {
  @override
  _DetailScreenState createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen>
    with TickerProviderStateMixin {
  VideoPlayerGetController controller = Get.find();
  String vodId = '';
  int playIndex = -1;

  late StorehouseBeanSites site;
  MusicPlayerController musicPlayController = Get.find();
  final HistoryController historyController =
      Get.put(HistoryController()); // 依赖注入
  final HttpService _httpService = HttpService();

  // late RealVideo video; // 存储详情数据
  RealResponseData responseData = RealResponseData(
    code: 0,
    msg: '',
    videos: [],
  );
  bool isLoading = true; // 用于显示加载状态
  // int currentIndex = 0; // 用于跟踪当前选中的播放项
  // int _selectedPlayFromIndex = 0; // 用于跟踪当前选中播放的播放源
  // bool _isFullScreen = false; // 存储全屏状态
  final ScrollController _scrollController = ScrollController();
  final downloadController = Get.find<DownloadController>();
  int _selectFromIndex = 0; // 用于跟踪当前选中查看的播放源
  late AnimationController _iconController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  // var videoPlayer = VideoPlayerPage();
  late final Widget videoPlayer;

  @override
  void initState() {
    super.initState();
    print('******  initState2222');
    final args = Get.arguments;
    vodId = args['vodId'];
    site = args['site'];
    playIndex = args['playIndex'];
    _fetchDetail(); // 请求详情数据
    videoPlayer = const VideoPlayerPage(
      key:  ValueKey('video_player'),
    );
    if (musicPlayController.player.playing) {
      musicPlayController.player.pause();
    }
    initAnimation();
  }

  // 异步加载视频进度
  _loadProgress() {
    int progress = 0;
    if (playIndex == -1) {
      progress = SPManager.getIndex(vodId) ?? 0;
    } else {
      progress = playIndex;
    }

    int? fromIndex = SPManager.getFromIndex(vodId) ?? 0;

    setState(() {
      controller.currentIndex.value = progress;
      controller.fromIndex.value = fromIndex;
      _selectFromIndex = fromIndex;
    });
  }

  Future<void> _fetchDetail() async {
    try {
      await _loadProgress();
      var paresType = site.type ?? 1;
      var subscription = site.api ?? "";
      if (paresType == 1) {
        Map<String, dynamic> jsonMap = await _httpService.getBySubscription(
          subscription,
          paresType,
          "",
          params: {
            "ac": "detail",
            "ids": vodId.toString(), // 使用传递的 vodId
          },
        );
        responseData = RealResponseData.fromJson(jsonMap, site); // 更新状态
      } else {
        XmlDocument jsonMap = await _httpService.getBySubscription(
          subscription,
          paresType,
          "",
          params: {
            "ac": "videolist",
            "ids": vodId.toString(), // 使用传递的 vodId
          },
        );
        responseData = RealResponseData.fromXml(jsonMap, site); // 更新状态
      }
      setState(() {
        var videos = responseData.videos;
        controller.video.value = videos[0];
        isLoading = false; // 数据加载完成
        _scrollToSelectedItem(controller.currentIndex.value);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          // 此时 scrollController 已经绑定可用了
          _scrollToSelectedItem(controller.currentIndex.value);
        });
        historyController.saveHistory(controller.video.value);
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
    _iconController.dispose();
    super.dispose();
  }

  // 处理全屏状态回调
  void _onFullScreenChanged() {
    if (controller.isFullScreen.value) {
      // 全屏时隐藏状态栏和禁用滚动
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    } else {
      // 退出全屏时恢复状态栏和启用滚动
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    // setState(() {});
  }

  void _onChangePlayPositon(int currentPosition) {
    historyController.saveHistory(controller.video.value);
    setState(() {
      controller.currentIndex.value = currentPosition;
      controller.fromIndex.value = _selectFromIndex;
    });
    _scrollToSelectedItem(currentPosition);
  }

  void _changePlayPosition(int index) async {
    if (index == controller.currentIndex.value &&
        controller.fromIndex.value == _selectFromIndex) {
      return;
    }
    _onChangePlayPositon(index);
    final playItem = CommonUtil.getPlayListAndForm(controller.video.value)
        .playList[controller.fromIndex.value][index];
    historyController.saveIndex(
        controller.video.value, index, controller.fromIndex.value);
    controller.playVideo(playItem["url"] ?? "", controller.currentIndex.value);
  }

  void changeFromPosition(int index) {
    setState(() {
      _selectFromIndex = index;
    });
  }

  void _scrollToSelectedItem(int index) {
    // 延迟一点时间，确保列表尺寸和 maxScrollExtent 是准确的
    Future.delayed(Duration(milliseconds: 20), () {
      print(
          '_scrollToSelectedItem  _scrollController.hasClients = ${_scrollController.hasClients} ');
      if (!_scrollController.hasClients) return;
      final double itemHeight = 38;
      const int itemsPerRow = 3;
      final double scrollPosition = (index ~/ itemsPerRow) * itemHeight;
      final double maxScrollExtent = _scrollController.position.maxScrollExtent;
      final double targetScroll = scrollPosition.clamp(0.0, maxScrollExtent);
      print(
          '_scrollToSelectedItem  scrollPosition = $scrollPosition   maxScrollExtent = $maxScrollExtent  targetScroll  = $targetScroll');
      _scrollController.animateTo(
        targetScroll,
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
              : Obx(() => Stack(
                    children: [
                      Positioned.fill(
                        child: CachedNetworkImage(
                          imageUrl: controller.video.value.vodPic,
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
                  )),
    );
  }

  Widget _buildCustomScrollView() {
    var isVertical = CommonUtil.isVertical();
    return isVertical || controller.isFullScreen.value
        ? _buildVerContent()
        : _buildHorContent();
  }

  Widget _buildVerContent() {
    var playerHeight = MediaQuery.of(context).size.height / 9 * 4;

    controller.videoPlayerHeight.value = controller.isFullScreen.value
        ? MediaQuery.of(context).size.height
        : playerHeight;
    return Column(
      children: [
        // 播放器部分，固定在顶部
        SizedBox(
          height: controller.isFullScreen.value
              ? MediaQuery.of(context).size.height
              : playerHeight, // 非全屏时固定高度
          child: videoPlayer,
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
    controller.videoPlayerHeight.value = controller.isFullScreen.value
        ? MediaQuery.of(context).size.height
        : playerHeight;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 播放器部分，固定在顶部
        SizedBox(
          width: playerWidth,
          height: controller.isFullScreen.value
              ? MediaQuery.of(context).size.height
              : screenHeight, // 非全屏时固定高度
          child: videoPlayer,
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
    var videoPlayData = CommonUtil.getPlayListAndForm(controller.video.value);
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
                controller.video.value.vodBlurb,
                softWrap: true,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
              expanded: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    controller.video.value.vodBlurb,
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  const SizedBox(height: 6.0),
                  Videoinfowidget(
                      title: "导演", content: controller.video.value.vodDirector),
                  const SizedBox(
                    height: 6.0,
                  ),
                  Videoinfowidget(
                      title: "主演", content: controller.video.value.vodActor),
                  const SizedBox(height: 6.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Videoinfowidget(
                          title: "年份", content: controller.video.value.vodYear),
                      const SizedBox(width: 6.0),
                      Videoinfowidget(
                          title: "地区", content: controller.video.value.vodArea),
                      const SizedBox(width: 6.0),
                      Videoinfowidget(
                          title: "类型",
                          content: controller.video.value.typeName),
                    ],
                  ),
                  const SizedBox(height: 6.0),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "播放地址（长按链接复制）",
                        style: TextStyle(
                            fontSize: 14.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                      const SizedBox(
                        height: 2.0,
                      ),
                      GestureDetector(
                        onLongPress: () {
                          Clipboard.setData(
                              ClipboardData(text: '播放地址（长按链接复制）'));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("文本已复制")),
                          );
                        },
                        child: Text(
                            playList[controller.fromIndex.value]
                                    [controller.currentIndex.value]['url'] ??
                                "",
                            style: const TextStyle(
                                fontSize: 12.0, color: Colors.white)),
                      ),
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
                color: Colors.white),
          ),
          Text(
            controller.video.value.vodRemarks.isNotEmpty
                ? controller.video.value.vodRemarks
                : "暂无更新",
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
    var playList =
        CommonUtil.getPlayListAndForm(controller.video.value).playList;
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
      itemCount: CommonUtil.getPlayListAndForm(controller.video.value)
          .playList[controller.fromIndex.value]
          .length,
      itemBuilder: (context, index) {
        return _buildGridItem(index, playList);
      },
    );
  }

  Widget _buildGridItem(int index, List<List<Map<String, String>>> playList) {
    final playItem = playList[_selectFromIndex][index];
    final title = playItem['title']!;
    final url = playItem['url']!;

    // 找到是否存在下载任务
    final item =
        downloadController.downloads.firstWhereOrNull((e) => e.url == url);

    Widget? prefixIcon;
    if (item != null) {
      if (item.status.value == DownloadStatus.downloading ||
          item.status.value == DownloadStatus.paused ||
          item.status.value == DownloadStatus.conversioning) {
        prefixIcon = SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Icon(Icons.download, size: 14, color: Colors.white),
          ),
        );
      } else if (item.status.value == DownloadStatus.completed) {
        prefixIcon = Icon(Icons.check_circle, size: 14, color: Colors.green);
      }
    }

    return GestureDetector(
      onTap: () {
        _changePlayPosition(index);
      },
      onLongPress: () {
        showSleepWarningIfNeeded(context);
        if (downloadController.startDownload(
            url, title, index, controller.video.value)) {
          CommonUtil.showToast('添加成功');
        } else {
          CommonUtil.showToast('任务已存在');
        }
      },
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: controller.currentIndex.value == index &&
                  controller.fromIndex.value == _selectFromIndex
              ? Colors.blueAccent
              : Colors.transparent,
          border: Border.all(
            color: Colors.white,
            width: controller.currentIndex.value == index &&
                    controller.fromIndex.value == _selectFromIndex
                ? 0
                : 1,
          ),
          borderRadius: BorderRadius.circular(3.0),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (prefixIcon != null) ...[
              prefixIcon,
              SizedBox(width: 4),
            ],
            Flexible(
              child: Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10.0,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
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

  void initAnimation() {
    _iconController = AnimationController(
      duration: const Duration(milliseconds: 1100),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, -0.1),
      end: Offset(0, 0.2),
    ).animate(CurvedAnimation(
      parent: _iconController,
      curve: Curves.linear,
    ));

    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _iconController,
      curve: Curves.linear,
    ));

    // 循环播放，从上到下，然后跳回上面重新开始
    _iconController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _iconController.forward(from: 0); // 重新从头开始，而不是倒播
      }
    });

    _iconController.forward(); // 启动动画
  }
}
