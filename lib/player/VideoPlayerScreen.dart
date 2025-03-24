import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
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
  VlcPlayerController? _controller;
  late int _currentIndex;
  late List<Map<String, String>> videoList; // 确保类型为 List<Map<String, String>>
  int videoId = 0;
  bool _isControllerVisible = true;
  bool _isPlaying = false;
  bool _isFullScreen = false;
  bool _isLoadVideoPlayed = false; // 新增的标志，确保下一集只跳转一次
  double _currentBrightness = 0.5; // 默认亮度
  int _currentVolume = 50; // 默认音量
  bool _isAdjustingBrightness = true;
  bool _showFeedback = false; //音量、亮度调节反馈开关
  bool _showSkipFeedback = false; //跳过、回退调节反馈开关
  String _playPositonTips = ""; //调节进度时候的文案
  bool _isBuffering = false; //是否在缓冲
  bool lastIsVer = true; //进入全屏前记录手机是否是竖直的
  double _progress = 0.0;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool isInitalized = false;

  @override
  void initState() {
    super.initState();
    initPlay();
  }

  Future<void> initPlay() async {
    WidgetsBinding.instance.addObserver(this);
    _currentIndex = widget.initialIndex;
    _initializePlayer();
    _initializeSystemSettings();
    if (isInitalized) {
      initPlayerConfig();
    }
  }

  Future<void> _initializeSystemSettings() async {
    _currentBrightness = await ScreenBrightness().current; // 获取系统亮度
    _currentVolume = await SPManager.getCurrentVolume(); // 获取保存的音量
    setState(() {});
  }

  Future<void> _initializePlayer() async {
    isInitalized = false;
    videoList = CommonUtil.getPlayList(widget.video);
    print("play url = ${videoList[_currentIndex]['url']}");
    _controller = VlcPlayerController.network(
      videoList[_currentIndex]['url']!,
      hwAcc: HwAcc.full, // 硬件加速
      autoPlay: true,
      options: VlcPlayerOptions(),
    );
    // 初始化播放器并处理错误
  }

  Future<void> initPlayerConfig() async {
    if (_controller == null) {
      return;
    }
    _isLoadVideoPlayed = false; // 确保每次初始化时复位
    var isSkipTail = false;
    final savedPosition =
        await SPManager.getProgress(videoList[_currentIndex]['url']!);
    videoId = widget.video.vodId;
    SPManager.saveIndex(videoId, _currentIndex);
    // 获取跳过时间
    final headTime = await SPManager.getSkipHeadTimes(videoId);

    if (savedPosition > Duration.zero && savedPosition > headTime) {
      _controller?.seekTo(savedPosition);
    }
    if (headTime > Duration.zero && headTime > savedPosition) {
      CommonUtil.showToast("自动跳过片头");
      _controller?.seekTo(headTime);
    }

    final tailTime = await SPManager.getSkipTailTimes(videoId);

    _controller!.addOnInitListener(() {
      setState(() {
        print("addOnInitListener ${_controller!.value.isInitialized}");
        isInitalized = _controller!.value.isInitialized;
      });
    });
    _controller?.addListener(() {
      if (_controller == null) {
        return;
      }
      if (_controller?.value.hasError == true) {
        CommonUtil.showToast("${_controller?.value.errorDescription}");
        print("play error = ${_controller?.value.errorDescription}");
      }
      _isPlaying = _controller!.value.isPlaying;
      if ((_controller?.value.duration ?? Duration.zero > Duration.zero) ==
              true &&
          !_isLoadVideoPlayed) {
        var skipTime = const Duration(milliseconds: 0);
        if (tailTime > const Duration(milliseconds: 1000)) {
          isSkipTail = true;
          skipTime = tailTime;
        } else {
          isSkipTail = false;
          skipTime = _controller?.value.duration ?? Duration.zero;
        }
        if (_controller!.value.position >= skipTime) {
          if (isSkipTail) {
            CommonUtil.showToast("自动跳过片尾");
          } else {
            CommonUtil.showToast("下一集");
          }
          _playNextVideo();
        }
      }

      setState(() {
        if (_controller != null) {
          _isBuffering = _controller!.value.isBuffering;
          _position = _controller!.value.position;
          _duration = _controller!.value.duration;
          _progress = _duration.inMilliseconds > 0
              ? _position.inMilliseconds / _duration.inMilliseconds
              : 0.0;
        }
      });
    });
    _toggleFullScreen;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_controller != null) {
      SPManager.saveProgress(
          videoList[_currentIndex]['url']!, _controller!.value.position);
      SPManager.saveIndex(videoId, _currentIndex);
      SPManager.saveHistory(widget.video);
      SystemChrome.setPreferredOrientations([]);
      if (_controller!.value.isInitialized) {
        _controller?.dispose();
      }
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (_controller == null) {
      return;
    }
    if (state == AppLifecycleState.paused) {
      // 应用退到后台，暂停播放
      if (_controller!.value.isInitialized) {
        _controller!.pause();
        setState(() {
          _isPlaying = false;
        });
      }
    } else if (state == AppLifecycleState.resumed) {
      // 应用回到前台，继续播放
      if (!_controller!.value.isPlaying && !_isPlaying) {
        _controller?.play();
        setState(() {
          _isPlaying = true;
        });
      }
    }
  }

  void _toggleFullScreen() {
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
    setState(() {
      if (isInitalized) {
        if (_isPlaying) {
          _controller?.pause();
        } else {
          _controller?.play();
        }
        _isPlaying = !_isPlaying;
      }
    });
  }

  void _playPreviousVideo() {
    if (_currentIndex > 0) {
      setState(() async {
        if (_controller == null) {
          return;
        }
        await SPManager.saveProgress(
            videoList[_currentIndex]['url']!, _controller!.value.position);
        _currentIndex--;
        _isLoadVideoPlayed = true;
        await _controller?.pause();
        await _controller?.dispose();
        _initializePlayer();
        widget.onChangePlayPositon(_currentIndex);
        SPManager.saveHistory(widget.video);
      });
    }
  }

  void _playNextVideo() {
    if (_currentIndex < videoList.length - 1) {
      setState(() async {
        if (_controller == null) {
          return;
        }
        await SPManager.saveProgress(
            videoList[_currentIndex]['url']!, _controller!.value.position);
        _currentIndex++;
        _isLoadVideoPlayed = true;
        await _controller?.pause();
        await _controller?.dispose();
        _initializePlayer();
        widget.onChangePlayPositon(_currentIndex);
      });
    }
  }

  // 判断视频是横还是竖屏
  bool isVerticalVideo() {
    if (_controller == null) {
      return false;
    }
    return _controller!.value.aspectRatio < 1.0; // 宽高比小于1是竖屏
  }

  Widget _buildVideoPlayer() {
    if (_controller==null||!_controller!.value.isInitialized || _isBuffering) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    return Center(
        child: VlcPlayer(
            controller: _controller!,
            aspectRatio: 16 / 9,
            placeholder: Center(child: CircularProgressIndicator())));
  }

  void _handleVerticalDrag(DragUpdateDetails details) {
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
    double delta = details.primaryDelta ?? 0;
    if (delta.abs() > 1) {
      _seekPlayProgress((delta).toInt());
    }
  }

  void _seekPlayProgress(int delta) {
    if (_controller == null) {
      return;
    }
    Duration newPosition =
        _controller!.value.position + Duration(seconds: delta);
    _playPositonTips =
        "${CommonUtil.formatDuration(newPosition)}/${CommonUtil.formatDuration(_controller!.value.duration)}";
    _seekToPosition(newPosition);
    _showSkipFeedback = true;
  }

  void _adjustBrightness(double dy) async {
    _currentBrightness = (_currentBrightness - dy * 0.01).clamp(0.0, 1.0);
    await ScreenBrightness().setScreenBrightness(_currentBrightness);
    _showTemporaryFeedback(true);
  }

  void _adjustVolume(double dy) async {
    _currentVolume =
        (_currentVolume * 100 - dy).clamp(0, 100).toInt(); // 0-100 的整数
    await _controller?.setVolume(_currentVolume);
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

  @override
  Widget build(BuildContext context) {
    print("_buildVideoPlayer isInitalized = $isInitalized  ");
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
                  videoPlayerHeight: widget.videoPlayerHeight,
                ),
              if (_showSkipFeedback)
                SkipFeedbackPositoned(
                  text: _playPositonTips,
                  videoPlayerHeight: widget.videoPlayerHeight,
                ),
              if (_isControllerVisible)
                MenuContainer(
                    videoId: videoId,
                    videoTitle:
                        "${widget.video.vodName} ${videoList[_currentIndex]['title']!}",
                    controller: _controller!,
                    onSetState: setState,
                    showSkipFeedback: showSkipFeedback,
                    playPositonTips: playPositonTips,
                    seekToPosition: _seekToPosition,
                    isPlaying: _isPlaying,
                    togglePlayPause: _togglePlayPause,
                    playPreviousVideo: _playPreviousVideo,
                    playNextVideo: _playNextVideo,
                    toggleFullScreen: _toggleFullScreen,
                    isFullScreen: _isFullScreen,
                    position: _position,
                    duration: _duration,
                    progress: _progress),
              if (!_isPlaying && isInitalized)
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
    _controller?.seekTo(position);
  }

  // 更新视频并重新初始化播放器
  void playVideo(String url, int index) {
    // 找到要播放的视频索引
    if (index != -1 && index != _currentIndex) {
      setState(() async {
        if (isInitalized) {
          if (_controller == null) {
            return;
          }
          await SPManager.saveProgress(
              videoList[_currentIndex]['url']!, _controller!.value.position);
          _currentIndex = index;
          _isLoadVideoPlayed = true;
          await _controller?.pause();
          await _controller?.dispose();
          _initializePlayer();
        }
      });
    }
  }
}
