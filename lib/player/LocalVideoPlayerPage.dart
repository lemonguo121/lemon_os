import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:lemon_tv/download/DownloadController.dart';
import 'package:lemon_tv/player/controller/VideoPlayerGetController.dart';
import 'package:lemon_tv/player/widget/MenuContainerPage.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../download/DownloadItem.dart';
import '../http/LocalHttpServer.dart';
import '../http/data/VideoPlayerBean.dart';
import '../util/CommonUtil.dart';
import '../util/SPManager.dart';
import 'LongPressOnlyWidget.dart';
import 'SkipFeedbackPositoned.dart';
import 'VoiceAndLightFeedbackPositoned.dart';

class LocalVideoPlayerPage extends StatefulWidget {
  LocalVideoPlayerPage();

  @override
  _LocalVideoPlayerPageState createState() => _LocalVideoPlayerPageState();
}

class _LocalVideoPlayerPageState extends State<LocalVideoPlayerPage> {
  DownloadController downloadController = Get.find();
  VideoPlayerGetController controller = Get.find();
  bool isLoading = true;
  bool isScreenLocked = false; //是否锁住屏幕
  bool _isControllerVisible = true;
  bool _isPlaying = false;
  double _currentBrightness = 0.5; // 默认亮度
  double _currentVolume = 0.5; // 默认音量
  bool _isAdjustingBrightness = true;
  bool _isBuffering = false; //是否在缓冲
  Duration headTime = Duration(milliseconds: 0);
  Duration tailTime = Duration(milliseconds: 0);
  bool isParesFail = false; //是否解析失败
  String videoId = ""; // 新增的标志，确保下一集只跳转一次
  Timer? _timer;
  String? vodId;
  int? currentPlayIndex = 0; //这是剧集中的索引
  // int currentIndex = 0; //这是转换播放列表里面的索引，上下集切换是根据这个索引
  List<DownloadItem> playList = [];
  DownloadItem? video;
  bool isVertical = true;

  @override
  void initState() {
    super.initState();
    var arguments = Get.arguments;
    vodId = arguments['vodId'];
    currentPlayIndex = arguments['playIndex'];
    WakelockPlus.toggle(enable: true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      isVertical = CommonUtil.isVertical();
    });
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.landscapeRight, DeviceOrientation.landscapeLeft]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    initPlayList();
    initializePlayer();
    controller.autoCloseMenuTimer();
  }

  void initPlayList() {
    if (vodId?.isEmpty == true) {
      CommonUtil.showToast('无效视频');
      return;
    }
    playList = downloadController.getCurrentVodEpisodes(vodId!);
    controller.currentIndex.value =
        playList.indexWhere((e) => e.playIndex == currentPlayIndex);
  }

  Future<void> initializePlayer() async {
    if (playList.isEmpty) {
      CommonUtil.showToast('无效视频');
      return;
    }
    video = playList[controller.currentIndex.value];

    if (video != null) {
      if (!Platform.isAndroid) {
        final dir = await getApplicationDocumentsDirectory();
        final folder = p.join(dir.path);
        await LocalHttpServer.start(folder);
      }

      var videoPlayerList = playList.map((play) {
        var localPath = play.localPath??'';
        final m3u8FileName = p.basename(localPath); // 获取文件名，例如 video.m3u8
        var localUrl = Platform.isAndroid
            ? localPath
            : 'http://127.0.0.1:12345/${video?.vodName}/${video?.playTitle}/$m3u8FileName';

        return VideoPlayerBean(
            vodId: play.vodId,
            vodName: play.vodName,
            vodPlayUrl: localUrl,
            playTitle: play.playTitle);
      }).toList();
      controller.videoPlayerList.value = videoPlayerList;
      controller.initializePlayer();
    }
  }

  @override
  void dispose() {
    controller.controller.removeListener(() {});
    controller.controller.dispose();
    LocalHttpServer.stop();
    _timer?.cancel();
    _saveProgressAndIndex();

    if (isVertical) {
      SystemChrome.setPreferredOrientations(
          [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
    } else {
      SystemChrome.setPreferredOrientations(
          [DeviceOrientation.landscapeRight, DeviceOrientation.landscapeLeft]);
    }
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    Future.delayed(const Duration(milliseconds: 300), () {
      SystemChrome.setPreferredOrientations([]);
    });
    if (downloadController.checkTaskAllDone()) {
      WakelockPlus.toggle(enable: false);
    }
    super.dispose();
  }

  _saveProgressAndIndex() {
    SPManager.saveProgress(
        video?.localPath ?? '', controller.controller.value.position);
  }

  void _togglePlayPause() {
    controller.autoCloseMenuTimer();
    if (isScreenLocked) {
      return;
    }
    setState(() {
      if (_isPlaying) {
        controller.controller.pause();
      } else {
        controller.controller.play();
      }
      _isPlaying = !_isPlaying;
    });
  }

  void _handleVerticalDrag(DragUpdateDetails details) {
    if (isScreenLocked) {
      return;
    }
    double delta = details.primaryDelta ?? 0;
    if (details.localPosition.dx < MediaQuery.of(context).size.width / 2) {
      // 左侧滑动 - 调节亮度
      if (delta.abs() > 1) {
        controller.adjustBrightness(delta / 2);
      }
    } else {
      // 右侧滑动 - 调节音量
      if (delta.abs() > 1) {
        controller.adjustVolume(delta / 2);
      }
    }
  }

  void _handleHorizontalDrag(DragUpdateDetails details) {
    if (isScreenLocked) {
      return;
    }
    double delta = details.primaryDelta ?? 0;
    if (delta.abs() > 1) {
      controller.seekPlayProgress((delta).toInt());
    }
  }

  // 判断视频是横还是竖屏
  bool isVerticalVideo() {
    return controller.controller.value.aspectRatio < 1.0; // 宽高比小于1是竖屏
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return Stack(
          children: [
            Container(
              color: Colors.black, // 设置背景色为黑色
            ),
            // 悬浮在播放器上层的加载指示器
            const Center(
              child: CircularProgressIndicator(),
            ),
          ],
        );
      }
      return RawKeyboardListener(
          focusNode: FocusNode()..requestFocus(), // 自动获取焦点以监听按键
          autofocus: true,
          onKey: (RawKeyEvent event) {
            if (event is RawKeyDownEvent) {
              if (event.logicalKey == LogicalKeyboardKey.space) {
                controller.togglePlayPause(); // 空格键控制播放暂停
              } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
                controller.seekPlayProgress(5);
              } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                controller.seekPlayProgress(-5);
              } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                controller.adjustVolume(-1); // 上键增加音量
              } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                controller.adjustVolume(1); // 下键降低音量
              }
            } else if (event is RawKeyUpEvent) {
              // 键盘抬起时的事件
              controller.cancelControll();
            }
          },
          child: Scaffold(
            backgroundColor: Colors.black,
            body: Stack(
              children: [
                LongPressOnlyWidget(
                  onTap: () {
                    setState(() {
                      _isControllerVisible = !_isControllerVisible;
                      controller.autoCloseMenuTimer();
                    });
                  },
                  onDoubleTap: _togglePlayPause,
                  onVerticalDragUpdate: _handleVerticalDrag,
                  onVerticalDragEnd: controller.cancelDrag,
                  onHorizontalDragUpdate: _handleHorizontalDrag,
                  onHorizontalDragEnd: controller.cancelDrag,
                  onLongPressStart: () => controller.fastSpeedPlay(true),
                  onLongPressEnd: () => controller.fastSpeedPlay(false),
                  child: _buildVideoPlayer(),
                ),
                if (controller.showFeedback.value)
                  VoiceAndLightFeedbackPositoned(
                    isAdjustingBrightness: _isAdjustingBrightness,
                    text:
                        "${((_isAdjustingBrightness ? _currentBrightness : _currentVolume) * 100).toInt()}%",
                    videoPlayerHeight: MediaQuery.of(context).size.height,
                  ),
                if (controller.showSkipFeedback.value)
                  SkipFeedbackPositoned(
                    text: controller.playPositonTips.value,
                    videoPlayerHeight: MediaQuery.of(context).size.height,
                  ),
                if (_isControllerVisible) MenuContainerPage(),
                if (controller.isLongPressing.value)
                  Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                        padding: EdgeInsets.only(top: 95.h),
                        child: Text(
                          '${SPManager.getLongPressSpeed()}x 加速中',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            shadows: [
                              Shadow(color: Colors.black87, blurRadius: 4),
                            ],
                          ),
                        )),
                  ),
                if (!_isPlaying && controller.controller.value.isInitialized)
                  Center(
                    child: GestureDetector(
                      onTap: _togglePlayPause,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4), // 半透明黑色背景
                          shape: BoxShape.circle, // 圆形
                        ),
                        padding: const EdgeInsets.all(10), // 控制圆的大小
                        child: const Icon(
                          Icons.play_arrow,
                          size: 50,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ));
    });
  }

  Widget _buildVideoPlayer() {
    if (isParesFail) {
      return Center(
        child: Container(
          color: Colors.black.withOpacity(0.7), // 背景半透明遮罩
          padding: EdgeInsets.all(16), // 增加内边距
          child: Column(
            mainAxisSize: MainAxisSize.min, // 让内容居中
            children: [
              GestureDetector(
                onTap: () {
                  initializePlayer();
                },
                child: Column(
                  children: [
                    Icon(
                      Icons.refresh, // 重试图标
                      color: Colors.white,
                      size: 36,
                    ),
                    SizedBox(height: 8), // 间距
                    Text(
                      '视频解析失败',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (!controller.controller.value.isInitialized || _isBuffering) {
      return Stack(
        children: [
          // 播放器，背景会显示黑色或其他你选择的背景色
          Center(
            child: AspectRatio(
              aspectRatio: controller.controller.value.aspectRatio,
              child: VideoPlayer(controller.controller),
            ),
          ),
          // 悬浮在播放器上层的加载指示器
          const Center(
            child: CircularProgressIndicator(),
          ),
        ],
      );
    }
    return Center(
      child: AspectRatio(
        aspectRatio: controller.controller.value.aspectRatio,
        child: VideoPlayer(controller.controller),
      ),
    );
  }
}
