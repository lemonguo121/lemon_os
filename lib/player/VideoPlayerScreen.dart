import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:lemon_tv/history/HistoryController.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:video_player/video_player.dart';

import '../http/data/RealVideo.dart';
import '../player/MenuContainer.dart';
import '../util/CommonUtil.dart';
import '../util/SPManager.dart';
import 'SkipFeedbackPositoned.dart';
import 'VoiceAndLightFeedbackPositoned.dart';

class VideoPlayerScreen extends StatefulWidget {
  final int initialIndex;
  final int fromIndex;
  final RealVideo video;
  final ValueChanged<bool> onFullScreenChanged;
  final ValueChanged<int> onChangePlayPositon;
  final double videoPlayerHeight;
  static final GlobalKey<_VideoPlayerScreenState> _globalKey =
      GlobalKey<_VideoPlayerScreenState>();

  static _VideoPlayerScreenState? of(BuildContext context) {
    return _globalKey.currentState;
  }

  VideoPlayerScreen({
    required this.initialIndex,
    required this.fromIndex,
    required this.video,
    required this.onFullScreenChanged,
    required this.onChangePlayPositon,
    required this.videoPlayerHeight,
  }) : super(key: _globalKey);

  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late VideoPlayerController _controller;
  late int _currentIndex;
  late List<Map<String, String>> videoList; // 确保类型为 List<Map<String, String>>
  final HistoryController historyController = Get.put(HistoryController());
  String playUrl = ""; // 确保类型为 List<Map<String, String>>
  int videoId = 0;
  bool _isControllerVisible = true; //是否显示控制器菜单
  bool _isPlaying = false;
  bool _isFullScreen = false;
  bool _isLoadVideoPlayed = false; // 新增的标志，确保下一集只跳转一次
  double _currentBrightness = 0.5; // 默认亮度
  double _currentVolume = 0.5; // 默认音量
  bool _isAdjustingBrightness = true;
  bool _showFeedback = false; //音量、亮度调节反馈开关
  bool _showSkipFeedback = false; //跳过、回退调节反馈开关
  String _playPositonTips = ""; //调节进度时候的文案
  bool _isBuffering = false; //是否在缓冲
  bool lastIsVer = true; //进入全屏前记录手机是否是竖直的
  bool isScreenLocked = false; //是否锁住屏幕
  bool isParesFail = false; //是否解析失败
  Duration headTime = Duration(milliseconds: 0);
  Duration tailTime = Duration(milliseconds: 0);
  bool isLoading = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentIndex = widget.initialIndex;
    _initializeSystemSettings();
    _initializePlayer();
    autoCloseMenuTimer();
  }

  Future<void> _initializeSystemSettings() async {
    _currentBrightness = await ScreenBrightness().current; // 获取系统亮度
    _currentVolume = await SPManager.getCurrentVolume(); // 获取保存的音量
    setState(() {});
  }

  Future<void> _initializePlayer() async {
    setState(() {
      isParesFail = false;
      _isBuffering = true;
      isLoading = true;
    });
    videoList =
        CommonUtil.getPlayListAndForm(widget.video).playList[widget.fromIndex];
    playUrl = videoList[_currentIndex]['url'] ?? "";
    print("sourse play url = $playUrl");
    _controller = VideoPlayerController.network(playUrl);
    try {
      await _controller.initialize();
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print("play error = $e");
    }
    _isLoadVideoPlayed = false; // 确保每次初始化时复位
    var isSkipTail = false;
    final savedPosition = await SPManager.getProgress(playUrl);
    videoId = widget.video.vodId;
    await historyController.saveIndex(
        widget.video, _currentIndex, widget.fromIndex);
    // 获取跳过时间
    headTime = await SPManager.getSkipHeadTimes("$videoId");

    if (savedPosition > Duration.zero && savedPosition > headTime) {
      _controller.seekTo(savedPosition);
    }
    if (headTime > Duration.zero && headTime > savedPosition) {
      CommonUtil.showToast("自动跳过片头");
      _controller.seekTo(headTime);
    }

    tailTime = await SPManager.getSkipTailTimes("$videoId");
    var playSpeed = await SPManager.getPlaySpeed();
    _controller.setPlaybackSpeed(playSpeed);
    _controller.addListener(() {
      if (_controller.value.hasError) {
        setState(() {
          isLoading = false;
          isParesFail = true;
        });
        print("play error = ${_controller.value.errorDescription}");
      }
      var currentDuration = _controller.value.duration;
      if (currentDuration > Duration.zero && !_isLoadVideoPlayed) {
        var skipTime = const Duration(milliseconds: 0);
        if (tailTime >= const Duration(milliseconds: 1000)) {
          isSkipTail = true;
          skipTime = tailTime;
        } else {
          isSkipTail = false;
          skipTime = _controller.value.duration;
        }
        if (_controller.value.position >= skipTime) {
          if (isSkipTail) {
            CommonUtil.showToast("自动跳过片尾");
          } else {
            CommonUtil.showToast("下一集");
          }
          _playNextVideo();
        }
      }
      setState(() {
        var isPlaying = _controller.value.isPlaying;
        var bufferedProgress = _controller.value.buffered.isNotEmpty
            ? _controller.value.buffered.last.end.inMilliseconds.toDouble()
            : 0.0;
        var currentPosition =
            _controller.value.position.inMilliseconds.toDouble();
        _isBuffering = _controller.value.isBuffering &&
            (!isPlaying || currentPosition >= bufferedProgress);
      });
    });
    _toggleFullScreen;
    setState(() {});
    _controller.play();
    _isPlaying = true;
  }

  @override
  void dispose() {
    _controller.removeListener(() {});
    WidgetsBinding.instance.removeObserver(this);
    // 调用异步方法，不阻塞 dispose
    _saveProgressAndIndex();
    SystemChrome.setPreferredOrientations([]);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _saveProgressAndIndex() async {
    await SPManager.saveProgress(playUrl, _controller.value.position);
    await historyController.saveIndex(
        widget.video, _currentIndex, widget.fromIndex);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.paused) {
      // 应用退到后台，暂停播放
      if (_controller.value.isPlaying) {
        _controller.pause();
        setState(() {
          _isPlaying = false;
        });
      }
    } else if (state == AppLifecycleState.resumed) {
      // 应用回到前台，继续播放
      if (!_controller.value.isPlaying && !_isPlaying) {
        _controller.play();
        setState(() {
          _isPlaying = true;
        });
      }
    }
  }

  void _toggleFullScreen() {
    autoCloseMenuTimer();
    setState(() {
      _isFullScreen = !_isFullScreen;
      if (!isVerticalVideo()) {
        if (_isFullScreen) {
          lastIsVer = CommonUtil.isVertical(context);
          SystemChrome.setPreferredOrientations([
            DeviceOrientation.landscapeRight,
            DeviceOrientation.landscapeLeft
          ]);
        } else {
          if (lastIsVer) {
            SystemChrome.setPreferredOrientations(
                [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
          } else {
            SystemChrome.setPreferredOrientations([
              DeviceOrientation.landscapeRight,
              DeviceOrientation.landscapeLeft
            ]);
          }
          SystemChrome.setPreferredOrientations([]);
        }
      }
    });
    widget.onFullScreenChanged(_isFullScreen);
  }

  void _togglePlayPause() {
    autoCloseMenuTimer();
    if (isScreenLocked) {
      return;
    }
    setState(() {
      if (_isPlaying) {
        _controller.pause();
      } else {
        _controller.play();
      }
      _isPlaying = !_isPlaying;
    });
  }

  void _playPreviousVideo() {
    autoCloseMenuTimer();
    if (_currentIndex > 0) {
      setState(() async {
        await SPManager.saveProgress(playUrl, _controller.value.position);
        _currentIndex--;
        _isLoadVideoPlayed = true;
        await _controller.pause();
        await _controller.dispose();
        _initializePlayer();
        widget.onChangePlayPositon(_currentIndex);
      });
    }
  }

  void _playNextVideo() {
    autoCloseMenuTimer();
    if (_currentIndex < videoList.length - 1) {
      setState(() async {
        await SPManager.saveProgress(playUrl, _controller.value.position);
        _currentIndex++;
        _isLoadVideoPlayed = true;
        await _controller.pause();
        await _controller.dispose();
        _initializePlayer();
        widget.onChangePlayPositon(_currentIndex);
      });
    }
  }

  Future<void> _setSkipHead() async {
    autoCloseMenuTimer();
    headTime = _controller.value.position;
    await SPManager.saveSkipHeadTimes("$videoId", headTime);
    setState(() {});
  }

  Future<void> _cleanSkipHead() async {
    autoCloseMenuTimer();
    await SPManager.clearSkipHeadTimes("$videoId");
    setState(() {});
  }

  Future<void> _setSkipTail() async {
    autoCloseMenuTimer();
    tailTime = _controller.value.position;
    await SPManager.saveSkipTailTimes(
      "$videoId",
      (await SPManager.getSkipTailTimes("$videoId")),
      tailTime,
    );
    setState(() {});
  }

  Future<void> _cleanSkipTail() async {
    autoCloseMenuTimer();
    await SPManager.clearSkipTailTimes("$videoId");
    setState(() {});
  }

  // 判断视频是横还是竖屏
  bool isVerticalVideo() {
    return _controller.value.aspectRatio < 1.0; // 宽高比小于1是竖屏
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
                  _initializePlayer();
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
    if (!_controller.value.isInitialized || _isBuffering) {
      return Stack(
        children: [
          // 播放器，背景会显示黑色或其他你选择的背景色
          Center(
            child: AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: VideoPlayer(_controller),
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
        aspectRatio: _controller.value.aspectRatio,
        child: VideoPlayer(_controller),
      ),
    );
  }

  void _handleVerticalDrag(DragUpdateDetails details) {
    if (isScreenLocked) {
      return;
    }
    double delta = details.primaryDelta ?? 0;
    if (details.localPosition.dx < MediaQuery.of(context).size.width / 2) {
      // 左侧滑动 - 调节亮度
      if (delta.abs() > 1) {
        _adjustBrightness(delta / 2);
      }
    } else {
      // 右侧滑动 - 调节音量
      if (delta.abs() > 1) {
        _adjustVolume(delta / 2);
      }
    }
  }

  void _handleHorizontalDrag(DragUpdateDetails details) {
    if (isScreenLocked) {
      return;
    }
    double delta = details.primaryDelta ?? 0;
    if (delta.abs() > 1) {
      _seekPlayProgress((delta).toInt());
    }
  }

  void _seekPlayProgress(int delta) {
    Duration newPosition =
        _controller.value.position + Duration(seconds: delta);
    _playPositonTips =
        "${CommonUtil.formatDuration(newPosition)}/${CommonUtil.formatDuration(_controller.value.duration)}";
    _seekToPosition(newPosition);
    _showSkipFeedback = true;
  }

  void _adjustBrightness(double dy) async {
    _currentBrightness = (_currentBrightness - dy * 0.01).clamp(0.0, 1.0);
    await ScreenBrightness().setScreenBrightness(_currentBrightness);
    _showTemporaryFeedback(true);
  }

  void _adjustVolume(double dy) async {
    _currentVolume = (_currentVolume - dy * 0.01).clamp(0.0, 1.0);
    await _controller.setVolume(_currentVolume);
    await SPManager.saveVolume(_currentVolume);
    _showTemporaryFeedback(false);
  }

  void _showTemporaryFeedback(bool isBrightness) {
    setState(() {
      _showFeedback = true;
      _isAdjustingBrightness = isBrightness;
    });
  }

  void _cancelDrag(DragEndDetails details) {
    if (isScreenLocked) {
      return;
    }
    _cancelControll();
  }

  void _cancelControll() {
    Future.delayed(Duration(seconds: 1), () {
      setState(() {
        _showFeedback = false;
        _showSkipFeedback = false;
      });
    });
  }

  void autoCloseMenuTimer() {
    if (_isControllerVisible) {
      _timer?.cancel();
      // 重新启动 5 秒计时
      _timer = Timer(Duration(seconds: 5), () {
        setState(() {
          _isControllerVisible = false;
        });
      });
    }
  }

  void showSkipFeedback(bool showSkipFeedback) {
    setState(() {
      _showSkipFeedback = showSkipFeedback;
    });
  }

  void playPositonTips(String playPositonTips) {
    setState(() {
      _playPositonTips = playPositonTips;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
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
              _togglePlayPause(); // 空格键控制播放暂停
            } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
              _seekPlayProgress(5);
            } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
              _seekPlayProgress(-5);
            } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
              _adjustVolume(-1); // 上键增加音量
            } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
              _adjustVolume(1); // 下键降低音量
            }
          } else if (event is RawKeyUpEvent) {
            // 键盘抬起时的事件
            _cancelControll();
          }
        },
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isControllerVisible = !_isControllerVisible;
                    autoCloseMenuTimer();
                  });
                },
                // 监听双击事件
                onDoubleTap: _togglePlayPause,
                // 双击屏幕切换播放/暂停
                onVerticalDragUpdate: _handleVerticalDrag,
                onVerticalDragEnd: _cancelDrag,
                onHorizontalDragUpdate: _handleHorizontalDrag,
                onHorizontalDragEnd: _cancelDrag,
                child: _buildVideoPlayer(),
              ),
              if (_showFeedback)
                VoiceAndLightFeedbackPositoned(
                  isAdjustingBrightness: _isAdjustingBrightness,
                  text:
                      "${((_isAdjustingBrightness ? _currentBrightness : _currentVolume) * 100).toInt()}%",
                  videoPlayerHeight: widget.videoPlayerHeight,
                ),
              if (_showSkipFeedback)
                SkipFeedbackPositoned(
                  text: _playPositonTips,
                  videoPlayerHeight: widget.videoPlayerHeight,
                ),
              if (_isControllerVisible)
                MenuContainer(
                  videoId: "$videoId",
                  videoTitle:
                      "${widget.video.vodName} ${videoList[_currentIndex]['title']!}",
                  controller: _controller,
                  showSkipFeedback: showSkipFeedback,
                  playPositonTips: playPositonTips,
                  seekToPosition: _seekToPosition,
                  changePlaySpeed: _changePlaySpeed,
                  toggleScreenLock: _toggleScreenLock,
                  isPlaying: _isPlaying,
                  togglePlayPause: _togglePlayPause,
                  playPreviousVideo: _playPreviousVideo,
                  playNextVideo: _playNextVideo,
                  setSkipHead: _setSkipHead,
                  cleanSkipHead: _cleanSkipHead,
                  setSkipTail: _setSkipTail,
                  cleanSkipTail: _cleanSkipTail,
                  toggleFullScreen: _toggleFullScreen,
                  isFullScreen: _isFullScreen,
                  isScreenLocked: isScreenLocked,
                  isAlsoShowTime: false,
                ),
              if (!_isPlaying && _controller.value.isInitialized)
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
  }

  void _seekToPosition(Duration position) {
    _controller.seekTo(position);
    autoCloseMenuTimer();
  }

  void _changePlaySpeed(double speed) {
    _controller.setPlaybackSpeed(speed);
    SPManager.savePlaySpeed(speed);
    autoCloseMenuTimer();
    setState(() {});
  }

  void _toggleScreenLock() {
    autoCloseMenuTimer();
    setState(() {
      isScreenLocked = !isScreenLocked;
    });
  }

  // 更新视频并重新初始化播放器
  void playVideo(String url, int index) {
    // 找到要播放的视频索引
    if (index != -1) {
      setState(() async {
        await SPManager.saveProgress(playUrl, _controller.value.position);
        _currentIndex = index;
        _isLoadVideoPlayed = true;
        await _controller.pause();
        await _controller.dispose();
        _initializePlayer();
      });
    }
  }
}
