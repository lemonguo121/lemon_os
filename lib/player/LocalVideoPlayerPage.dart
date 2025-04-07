import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:video_player/video_player.dart';

import 'MenuContainer.dart';
import 'SkipFeedbackPositoned.dart';
import 'VoiceAndLightFeedbackPositoned.dart';
import '../util/CommonUtil.dart';
import '../util/SPManager.dart';

class LocalVideoPlayerPage extends StatefulWidget {
  final AssetEntity video;

  LocalVideoPlayerPage({required this.video});

  @override
  _LocalVideoPlayerPageState createState() => _LocalVideoPlayerPageState();
}

class _LocalVideoPlayerPageState extends State<LocalVideoPlayerPage> {
  late VideoPlayerController _controller;
  bool isLoading = true;
  bool isScreenLocked = false; //是否锁住屏幕
  bool _isControllerVisible = true;
  bool _isPlaying = false;
  bool _isFullScreen = false;
  bool _showFeedback = false; //音量、亮度调节反馈开关
  bool _showSkipFeedback = false; //跳过、回退调节反馈开关
  String _playPositonTips = ""; //调节进度时候的文案
  double _currentBrightness = 0.5; // 默认亮度
  double _currentVolume = 0.5; // 默认音量
  bool _isAdjustingBrightness = true;
  bool _isBuffering = false; //是否在缓冲
  Duration headTime = Duration(milliseconds: 0);
  Duration tailTime = Duration(milliseconds: 0);
  bool isParesFail = false; //是否解析失败
  bool _isLoadVideoPlayed = false; // 新增的标志，确保下一集只跳转一次
  String videoId =""; // 新增的标志，确保下一集只跳转一次
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
    initializePlayer();
    autoCloseMenuTimer();
  }

  Future<void> initializePlayer() async {
    videoId = widget.video.id;
    final file = await widget.video.file;
    if (file != null) {
      _controller = VideoPlayerController.file(file)
        ..initialize().then((_) async {
          setState(() => isLoading = false);
          _controller.play();
          _isPlaying = true;
          _isLoadVideoPlayed = false; // 确保每次初始化时复位
          var isSkipTail = false;
          final savedPosition = await SPManager.getProgress(widget.video.id);
          videoId = widget.video.id;
          // 获取跳过时间
          headTime = await SPManager.getSkipHeadTimes(videoId);

          if (savedPosition > Duration.zero && savedPosition > headTime) {
            _controller.seekTo(savedPosition);
          }
          if (headTime > Duration.zero && headTime > savedPosition) {
            CommonUtil.showToast("自动跳过片头");
            _controller.seekTo(headTime);
          }

          tailTime = await SPManager.getSkipTailTimes(videoId);
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
            if (_controller.value.duration > Duration.zero && !_isLoadVideoPlayed) {
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
                  CommonUtil.showToast("已结束");
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
        });
    }
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

  @override
  void dispose() {
    _controller.removeListener(() {});
    _controller.dispose();
    _timer?.cancel();
    _saveProgressAndIndex();
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: SystemUiOverlay.values);
    super.dispose();
  }
  Future<void> _saveProgressAndIndex() async {
    await SPManager.saveProgress(widget.video.file.toString(), _controller.value.position);
  }

  void _playPreviousVideo() {
    autoCloseMenuTimer();
    CommonUtil.showToast("已经是第一集");
  }

  void _playNextVideo() {
    autoCloseMenuTimer();
    CommonUtil.showToast("已经是最后一集");
  }

  Future<void> _setSkipHead() async {
    autoCloseMenuTimer();
    headTime = _controller.value.position;
    await SPManager.saveSkipHeadTimes(widget.video.id, headTime);
    setState(() {});
  }

  Future<void> _cleanSkipHead() async {
    autoCloseMenuTimer();
    await SPManager.clearSkipHeadTimes(widget.video.id);
    setState(() {});
  }

  Future<void> _setSkipTail() async {
    autoCloseMenuTimer();
    tailTime = _controller.value.position;
    await SPManager.saveSkipTailTimes(
      widget.video.id,
      (await SPManager.getSkipTailTimes(widget.video.id)),
      tailTime,
    );
    setState(() {});
  }

  Future<void> _cleanSkipTail() async {
    autoCloseMenuTimer();
    await SPManager.clearSkipTailTimes(widget.video.id);
    setState(() {});
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

  void _seekToPosition(Duration position) {
    autoCloseMenuTimer();
    _controller.seekTo(position);
  }

  void _changePlaySpeed(double speed) {
    autoCloseMenuTimer();
    _controller.setPlaybackSpeed(speed);
    SPManager.savePlaySpeed(speed);
    setState(() {});
  }

  void _toggleScreenLock() {
    autoCloseMenuTimer();
    setState(() {
      isScreenLocked = !isScreenLocked;
    });
  }

  void _seekPlayProgress(int delta) {
    autoCloseMenuTimer();
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

  // 判断视频是横还是竖屏
  bool isVerticalVideo() {
    return _controller.value.aspectRatio < 1.0; // 宽高比小于1是竖屏
  }

  void _toggleFullScreen() {
    autoCloseMenuTimer();
    setState(() {
      _isFullScreen = !_isFullScreen;
      if (!isVerticalVideo()) {
        if (_isFullScreen) {
          SystemChrome.setPreferredOrientations([
            DeviceOrientation.landscapeRight,
            DeviceOrientation.landscapeLeft
          ]);
        } else {
            SystemChrome.setPreferredOrientations(
                [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
        }
      }
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
                  videoPlayerHeight: MediaQuery.of(context).size.height,
                ),
              if (_showSkipFeedback)
                SkipFeedbackPositoned(
                  text: _playPositonTips,
                  videoPlayerHeight: MediaQuery.of(context).size.height,
                ),
              if (_isControllerVisible)
                MenuContainer(
                  videoId: widget.video.id,
                  videoTitle: widget.video.title ?? "",
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
                  isAlsoShowTime: true,
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
}
